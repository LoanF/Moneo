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
        return handler.next(options);
      },
      onError: (DioException e, handler) async {
        if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
          String? refreshToken = await storage.read(key: 'refreshToken');
          final response = await dio.post('/auth/refresh', data: {'token': refreshToken});

          if (response.statusCode == 200) {
            await storage.write(key: 'accessToken', value: response.data['accessToken']);
            await storage.write(key: 'refreshToken', value: response.data['refreshToken']);

            return handler.resolve(await dio.fetch(e.requestOptions));
          }
        }
        return handler.next(e);
      },
    ));
  }
}