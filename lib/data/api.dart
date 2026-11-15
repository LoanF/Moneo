import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import '../core/api_client.dart';
import 'models.dart';

/// Un changement signalé par le serveur (flux temps réel).
class ChangeEvent {
  const ChangeEvent(this.model, this.type, this.id);
  final String model, type;
  final String? id;
}

typedef AuthResult = ({AppUser user, String access, String refresh});

/// Tous les appels à l'API Moneo, typés.
class MoneoApi {
  MoneoApi(this.client);
  final ApiClient client;

  // ── Authentification ──────────────────────────────────────────────────────

  AuthResult _auth(Json j) => (
    user: AppUser.fromJson(j['user'] as Json),
    access: j['accessToken'] as String,
    refresh: j['refreshToken'] as String,
  );

  Future<AuthResult> login(String email, String password, Json device) async =>
      _auth(
        await client.post('/auth/login', {
          'email': email,
          'password': password,
          ...device,
        }),
      );

  Future<AuthResult> register(
    String username,
    String email,
    String password,
    Json device,
  ) async => _auth(
    await client.post('/auth/register', {
      'username': username,
      'email': email,
      'password': password,
      ...device,
    }),
  );

  Future<AuthResult> google(String idToken, Json device) async =>
      _auth(await client.post('/auth/google', {'idToken': idToken, ...device}));

  Future<void> forgotPassword(String email) =>
      client.post('/auth/forgot-password', {'email': email});
  Future<void> resetPassword(String email, String code, String password) =>
      client.post('/auth/reset-password', {
        'email': email,
        'code': code,
        'newPassword': password,
      });
  Future<AppUser> verifyEmail(String code) async =>
      AppUser.fromJson(await client.post('/auth/verify-email', {'code': code}));
  Future<void> resendVerification() => client.post('/auth/resend-verification');
  Future<void> logout() => client.post('/auth/logout');
  Future<void> logoutOthers() => client.post('/auth/logout-all');
  Future<void> changePassword(String? current, String next) => client.post(
    '/auth/change-password',
    {if (current != null) 'currentPassword': current, 'newPassword': next},
  );
  Future<void> deleteAccount({String? password, String? confirmEmail}) =>
      client.delete('/auth/me', {
        if (password != null) 'password': password,
        if (confirmEmail != null) 'confirmEmail': confirmEmail,
      });
  Future<AppUser> updateProfile(Json patch) async =>
      AppUser.fromJson(await client.patch('/auth/me', patch));
  Future<void> registerDevice(Json device) =>
      client.put('/auth/device', device);
  Future<List<DeviceSession>> sessions() async => [
    for (final s in await client.getList('/auth/sessions'))
      DeviceSession.fromJson(s as Json),
  ];
  Future<void> revokeSession(String id) => client.delete('/auth/sessions/$id');

  Future<AppUser> uploadAvatar(String path) async {
    final form = FormData.fromMap({
      'avatar': await MultipartFile.fromFile(path),
    });
    return AppUser.fromJson(await client.post('/auth/me/avatar', form));
  }

  // ── État de l'app ─────────────────────────────────────────────────────────

  Future<Json> bootstrapRaw() => client.getJson('/bootstrap');

  // ── Comptes et catalogue ──────────────────────────────────────────────────

  Future<void> saveAccount(String? id, Json body) => id == null
      ? client.post('/accounts', body)
      : client.patch('/accounts/$id', body);
  Future<void> deleteAccountById(String id) => client.delete('/accounts/$id');
  Future<void> reorderAccounts(List<String> ids) =>
      client.put('/accounts/order', {'ids': ids});

  Future<void> saveCategory(String? id, Json body) => id == null
      ? client.post('/categories', body)
      : client.patch('/categories/$id', body);
  Future<void> deleteCategory(String id) => client.delete('/categories/$id');

  Future<void> savePaymentMethod(String? id, Json body) => id == null
      ? client.post('/payment-methods', body)
      : client.patch('/payment-methods/$id', body);
  Future<void> deletePaymentMethod(String id) =>
      client.delete('/payment-methods/$id');

  Future<void> saveChequebook(String? id, Json body) => id == null
      ? client.post('/chequebooks', body)
      : client.patch('/chequebooks/$id', body);
  Future<void> deleteChequebook(String id) => client.delete('/chequebooks/$id');

  // ── Opérations ────────────────────────────────────────────────────────────

  Future<TxPage> transactions(
    TxFilter filter, {
    int limit = 100,
    int offset = 0,
    String? sort,
  }) async => TxPage.fromJson(
    await client.getJson(
      '/transactions',
      query: {
        ...filter.toQuery(),
        'limit': limit,
        'offset': offset,
        if (sort != null) 'sort': sort,
      },
    ),
  );

  Future<void> createTransaction(TxDraft draft) => draft.type == TxType.transfer
      ? client.post('/transactions/transfers', draft.toTransferJson())
      : client.post('/transactions', draft.toJson());

  Future<void> updateTransaction(String id, Json patch) =>
      client.patch('/transactions/$id', patch);
  Future<void> deleteTransaction(String id) =>
      client.delete('/transactions/$id');
  Future<void> setChecked(List<String> ids, bool checked) =>
      client.post('/transactions/check', {'ids': ids, 'isChecked': checked});

  /// Rejoue les créations faites hors-ligne. Renvoie les identifiants acceptés par le serveur.
  Future<Set<String>> replay(List<Json> drafts) async {
    final response = await client.post('/transactions/batch', {
      'transactions': drafts,
    });
    return {
      for (final r in response['results'] as List)
        if ((r as Json)['status'] != 'error' && r['id'] != null)
          r['id'] as String,
    };
  }

  Future<List<Suggestion>> suggestions(String query) async => [
    for (final s in await client.getList(
      '/transactions/suggestions',
      query: {'q': query},
    ))
      Suggestion.fromJson(s as Json),
  ];

  // ── Mensualités, budgets, notifications ───────────────────────────────────

  Future<void> saveRecurring(String? id, Json body) => id == null
      ? client.post('/recurring-payments', body)
      : client.patch('/recurring-payments/$id', body);
  Future<void> deleteRecurring(String id) =>
      client.delete('/recurring-payments/$id');
  Future<List<Occurrence>> pendingRecurring() async => [
    for (final o in await client.getList('/recurring-payments/pending'))
      Occurrence.fromPending(o as Json),
  ];
  Future<int> runRecurring() async =>
      ((await client.post('/recurring-payments/run'))['created'] as num)
          .toInt();

  Future<void> saveBudget(String? id, Json body) => id == null
      ? client.post('/budgets', body)
      : client.patch('/budgets/$id', body);
  Future<void> deleteBudget(String id) => client.delete('/budgets/$id');

  Future<List<AppNotification>> notifications() async => [
    for (final n in (await client.getJson('/notifications'))['items'] as List)
      AppNotification.fromJson(n as Json),
  ];
  Future<void> markNotificationsRead() => client.post('/notifications/read');
  Future<void> clearNotifications() => client.delete('/notifications');

  // ── Statistiques ──────────────────────────────────────────────────────────

  Json _range(String from, String to, String? accountId) => {
    'from': from,
    'to': to,
    if (accountId != null) 'accountId': accountId,
  };

  Future<Summary> summary(String from, String to, {String? accountId}) async =>
      Summary.fromJson(
        await client.getJson(
          '/stats/summary',
          query: _range(from, to, accountId),
        ),
      );

  Future<List<MonthTotal>> monthly({
    int months = 12,
    String? accountId,
  }) async => [
    for (final m in await client.getList(
      '/stats/monthly',
      query: {'months': months, if (accountId != null) 'accountId': accountId},
    ))
      MonthTotal.fromJson(m as Json),
  ];

  Future<List<BalancePoint>> balanceHistory(
    String from,
    String to, {
    String? accountId,
  }) async => [
    for (final p
        in (await client.getJson(
              '/stats/balance-history',
              query: _range(from, to, accountId),
            ))['points']
            as List)
      BalancePoint.fromJson(p as Json),
  ];

  Future<Forecast> forecast({int days = 30, String? accountId}) async =>
      Forecast.fromJson(
        await client.getJson(
          '/stats/forecast',
          query: {'days': days, if (accountId != null) 'accountId': accountId},
        ),
      );

  Future<Pivot> pivot(
    String from,
    String to,
    String granularity, {
    String? accountId,
  }) async => Pivot.fromJson(
    await client.getJson(
      '/stats/pivot',
      query: {..._range(from, to, accountId), 'granularity': granularity},
    ),
  );

  // ── Import / export ───────────────────────────────────────────────────────

  Future<ImportReport> importWorkbook(
    String path, {
    required bool replace,
  }) async {
    final form = FormData.fromMap({'file': await MultipartFile.fromFile(path)});
    return ImportReport.fromJson(
      await client.post('/data/import/comptes', form, {
        'mode': replace ? 'replace' : 'merge',
      }),
    );
  }

  Future<String> export(String format) async {
    try {
      final response = await client.dio.get<String>(
        '/data/export',
        queryParameters: {'format': format},
        options: Options(responseType: ResponseType.plain),
      );
      return response.data ?? '';
    } catch (error) {
      throw ApiException.from(error);
    }
  }

  // ── Temps réel ────────────────────────────────────────────────────────────

  /// Flux d'événements serveur. Se termine quand la connexion tombe : l'appelant relance.
  Stream<ChangeEvent> realtime(CancelToken cancel) async* {
    final response = await client.dio.get<ResponseBody>(
      '/realtime',
      cancelToken: cancel,
      options: Options(
        responseType: ResponseType.stream,
        receiveTimeout: Duration.zero,
        headers: {'Accept': 'text/event-stream'},
      ),
    );
    String? event;
    String? data;
    await for (final line
        in response.data!.stream
            .cast<List<int>>()
            .transform(utf8.decoder)
            .transform(const LineSplitter())) {
      if (line.startsWith('event:')) {
        event = line.substring(6).trim();
      } else if (line.startsWith('data:')) {
        data = line.substring(5).trim();
      } else if (line.isEmpty) {
        if (event == 'change' && data != null) {
          try {
            final json = jsonDecode(data) as Json;
            yield ChangeEvent(
              json['model'] as String,
              json['type'] as String,
              json['id'] as String?,
            );
          } catch (_) {
            /* événement illisible : ignoré */
          }
        }
        event = null;
        data = null;
      }
    }
  }
}
