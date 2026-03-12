import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:moneo/data/constants/assets.dart';

class ApiClient {
  final Dio dio = Dio(BaseOptions(baseUrl: AppAssets.apiUrl));
  final storage = const FlutterSecureStorage();

  ApiClient() {
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        String? token = await storage.read(key: 'accessToken');
        options.headers['Authorization'] = 'Bearer $token';

        options.headers['ngrok-skip-browser-warning'] = 'true'; // TODO: Supprimer plus tard
        
        return handler.next(options);
      },
      onError: (DioException e, handler) async {
        if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
          try {
            String? refreshToken = await storage.read(key: 'refreshToken');
            final response = await dio.post('/auth/refresh', data: {'token': refreshToken});
            final data = response.data;

            if (response.statusCode == 200 && data is Map) {
              await storage.write(key: 'accessToken', value: data['accessToken'] as String);
              await storage.write(key: 'refreshToken', value: data['refreshToken'] as String);

              return handler.resolve(await dio.fetch(e.requestOptions));
            }
          } catch (_) {
            // Refresh failed, propagate original error
          }
        }
        return handler.next(e);
      },
    ));

    dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
    ));
  }
}