import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Erreur présentable telle quelle à l'utilisateur.
class ApiException implements Exception {
  const ApiException(
    this.message, {
    this.code,
    this.status,
    this.offline = false,
  });
  final String message;
  final String? code;
  final int? status;

  /// Le serveur n'a pas pu être joint (pas de réseau, délai dépassé).
  final bool offline;

  @override
  String toString() => message;

  static ApiException from(Object error) {
    if (error is ApiException) return error;
    if (error is DioException) {
      if (error.error is ApiException) return error.error! as ApiException;
      final data = error.response?.data;
      final status = error.response?.statusCode;
      if (data is Map && data['error'] is String) {
        return ApiException(
          data['error'] as String,
          code: data['code'] as String?,
          status: status,
        );
      }
      if (error.response == null) {
        return const ApiException(
          'Connexion impossible. Vérifiez votre réseau et réessayez.',
          offline: true,
        );
      }
      if (status == 429) {
        return ApiException(
          'Trop de tentatives. Patientez un instant avant de réessayer.',
          status: status,
        );
      }
      return ApiException(
        'Le serveur a rencontré un problème. Réessayez dans un instant.',
        status: status,
      );
    }
    return const ApiException('Une erreur inattendue est survenue.');
  }
}

/// Jetons de session. Abstraction minimale pour pouvoir les remplacer dans les tests.
abstract class TokenStore {
  Future<({String? access, String? refresh})> read();
  Future<void> write({required String access, required String refresh});
  Future<void> clear();
}

class SecureTokenStore implements TokenStore {
  const SecureTokenStore([this._storage = const FlutterSecureStorage()]);
  final FlutterSecureStorage _storage;

  @override
  Future<({String? access, String? refresh})> read() async => (
    access: await _storage.read(key: 'accessToken'),
    refresh: await _storage.read(key: 'refreshToken'),
  );

  @override
  Future<void> write({required String access, required String refresh}) async {
    await _storage.write(key: 'accessToken', value: access);
    await _storage.write(key: 'refreshToken', value: refresh);
  }

  @override
  Future<void> clear() async {
    await _storage.delete(key: 'accessToken');
    await _storage.delete(key: 'refreshToken');
  }
}

/// Client HTTP de l'API : ajoute le jeton d'accès et le renouvelle au besoin.
///
/// Le renouvellement est **unique** : dix requêtes qui reçoivent un 401 en même temps
/// attendent le même appel à `/auth/refresh`. Sans cela, la rotation du refresh token
/// invaliderait les appels concurrents et déconnecterait l'utilisateur au hasard.
class ApiClient {
  ApiClient({
    required String baseUrl,
    required this.tokens,
    this.onSessionExpired,
    HttpClientAdapter? adapter,
  }) : dio = Dio(_options(baseUrl)),
       _refreshDio = Dio(_options(baseUrl)) {
    if (adapter != null) {
      dio.httpClientAdapter = adapter;
      _refreshDio.httpClientAdapter = adapter;
    }
    dio.interceptors.add(
      InterceptorsWrapper(onRequest: _attachToken, onError: _retryAfterRefresh),
    );
  }

  static BaseOptions _options(String baseUrl) => BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 10),
    sendTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
    headers: {'Accept': 'application/json'},
  );

  static const _public = {
    '/auth/login',
    '/auth/register',
    '/auth/google',
    '/auth/refresh',
    '/auth/forgot-password',
    '/auth/reset-password',
  };

  final Dio dio;
  final Dio _refreshDio;
  final TokenStore tokens;

  /// Appelé quand la session ne peut plus être renouvelée : l'app doit revenir à l'écran de connexion.
  void Function()? onSessionExpired;

  String? _access;
  Future<String?>? _refreshing;

  Future<String?> accessToken() async =>
      _access ??= (await tokens.read()).access;

  Future<void> setTokens({
    required String access,
    required String refresh,
  }) async {
    _access = access;
    await tokens.write(access: access, refresh: refresh);
  }

  Future<void> clearTokens() async {
    _access = null;
    await tokens.clear();
  }

  Future<void> _attachToken(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!_public.contains(options.path)) {
      final token = await accessToken();
      if (token != null) options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  Future<void> _retryAfterRefresh(
    DioException error,
    ErrorInterceptorHandler handler,
  ) async {
    final request = error.requestOptions;
    final expired =
        error.response?.statusCode == 401 &&
        !_public.contains(request.path) &&
        request.extra['retried'] != true;
    if (!expired) return handler.next(error);

    final token = await refresh();
    if (token == null) return handler.next(error);
    try {
      request.extra['retried'] = true;
      request.headers['Authorization'] = 'Bearer $token';
      handler.resolve(await dio.fetch<dynamic>(request));
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }

  /// Renouvelle les jetons. Renvoie le nouveau jeton d'accès, ou `null` si la session est perdue.
  Future<String?> refresh() =>
      _refreshing ??= _doRefresh().whenComplete(() => _refreshing = null);

  Future<String?> _doRefresh() async {
    final refreshToken = (await tokens.read()).refresh;
    if (refreshToken == null) return null;
    try {
      final response = await _refreshDio.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );
      final data = response.data!;
      await setTokens(
        access: data['accessToken'] as String,
        refresh: data['refreshToken'] as String,
      );
      return _access;
    } on DioException catch (error) {
      // Seul un refus explicite du serveur ferme la session ; une coupure réseau la laisse intacte.
      if (error.response?.statusCode == 401) {
        await clearTokens();
        onSessionExpired?.call();
      }
      return null;
    }
  }

  // ── Raccourcis typés ──────────────────────────────────────────────────────

  Future<T> _run<T>(
    Future<Response<dynamic>> Function() call,
    T Function(dynamic data) parse,
  ) async {
    try {
      return parse((await call()).data);
    } catch (error) {
      throw ApiException.from(error);
    }
  }

  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, dynamic>? query,
  }) => _run(
    () => dio.get<dynamic>(path, queryParameters: query),
    (d) => d as Map<String, dynamic>,
  );

  Future<List<dynamic>> getList(String path, {Map<String, dynamic>? query}) =>
      _run(
        () => dio.get<dynamic>(path, queryParameters: query),
        (d) => d as List<dynamic>,
      );

  Future<Map<String, dynamic>> post(
    String path, [
    Object? body,
    Map<String, dynamic>? query,
  ]) => _run(
    () => dio.post<dynamic>(
      path,
      data: body ?? const <String, dynamic>{},
      queryParameters: query,
    ),
    (d) => d as Map<String, dynamic>,
  );

  Future<Map<String, dynamic>> patch(String path, Object body) => _run(
    () => dio.patch<dynamic>(path, data: body),
    (d) => d as Map<String, dynamic>,
  );

  Future<dynamic> put(String path, Object body) =>
      _run(() => dio.put<dynamic>(path, data: body), (d) => d);

  Future<void> delete(String path, [Object? body]) =>
      _run(() => dio.delete<dynamic>(path, data: body), (_) {});
}
