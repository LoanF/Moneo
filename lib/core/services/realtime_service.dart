import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../data/constants/assets.dart';

class RealtimeEvent {
  final String type;
  final String model;
  final Map<String, dynamic> data;

  const RealtimeEvent({required this.type, required this.model, required this.data});

  factory RealtimeEvent.fromJson(Map<String, dynamic> json) {
    return RealtimeEvent(
      type: json['type'] as String,
      model: json['model'] as String,
      data: (json['data'] as Map<String, dynamic>?) ?? {},
    );
  }
}

class RealtimeService {
  final _controller = StreamController<RealtimeEvent>.broadcast();
  final _storage = const FlutterSecureStorage();
  CancelToken? _cancelToken;
  bool _disposed = false;

  Stream<RealtimeEvent> get events => _controller.stream;

  Future<void> connect() async {
    if (_disposed) return;
    _cancelToken?.cancel();
    _cancelToken = CancelToken();

    try {
      final token = await _storage.read(key: 'accessToken');
      if (token == null) return;

      final dio = Dio(BaseOptions(
        baseUrl: AppAssets.apiUrl,
        headers: {'Authorization': 'Bearer $token'},
        responseType: ResponseType.stream,
        receiveTimeout: Duration.zero,
      ));

      final response = await dio.get<ResponseBody>('/realtime', cancelToken: _cancelToken);
      final stream = response.data!.stream;

      String buffer = '';
      String? currentEvent;
      String? currentData;

      stream.listen(
        (bytes) {
          if (_disposed) return;
          buffer += utf8.decode(bytes);
          final lines = buffer.split('\n');
          buffer = lines.removeLast();

          for (final raw in lines) {
            final line = raw.trimRight();
            if (line.startsWith('event:')) {
              currentEvent = line.substring(6).trim();
            } else if (line.startsWith('data:')) {
              currentData = line.substring(5).trim();
            } else if (line.isEmpty) {
              if (currentEvent == 'message' && currentData != null) {
                try {
                  final json = jsonDecode(currentData!) as Map<String, dynamic>;
                  _controller.add(RealtimeEvent.fromJson(json));
                } catch (_) {}
              }
              currentEvent = null;
              currentData = null;
            }
          }
        },
        onError: (e) {
          if (!_disposed) _scheduleReconnect();
        },
        onDone: () {
          if (!_disposed) _scheduleReconnect();
        },
        cancelOnError: true,
      );
    } on DioException catch (e) {
      if (e.type != DioExceptionType.cancel && !_disposed) {
        _scheduleReconnect();
      }
    } catch (e) {
      if (!_disposed) _scheduleReconnect();
      if (kDebugMode) print('[SSE] connect error: $e');
    }
  }

  void _scheduleReconnect() {
    Future.delayed(const Duration(seconds: 5), () {
      if (!_disposed) connect();
    });
  }

  void disconnect() {
    _cancelToken?.cancel();
    _cancelToken = null;
  }

  void dispose() {
    _disposed = true;
    disconnect();
    _controller.close();
  }
}
