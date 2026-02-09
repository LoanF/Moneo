import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_client_sse/constants/sse_request_type_enum.dart';
import 'package:flutter_client_sse/flutter_client_sse.dart';
import 'package:moneo/core/database/app_database.dart';
import 'package:moneo/data/constants/assets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SyncService {
  final AppDatabase _db;
  final _storage = const FlutterSecureStorage();

  SyncService(this._db);

  void startSync() async {
    final token = await _storage.read(key: 'accessToken');
    if (token == null) return;

    // Connexion au flux SSE de ton API Hono
    SSEClient.subscribeToSSE(
      method: SSERequestType.GET,
      url: '${AppAssets.apiUrl}/realtime',
      header: {
        "Authorization": "Bearer $token",
        "Accept": "text/event-stream",
      },
    ).listen((event) {
      if (event.data != null && event.data!.isNotEmpty) {
        _handleServerEvent(event);
      }
    });
  }

  void stopSync() {
    SSEClient.unsubscribeFromSSE();
  }

  void _handleServerEvent(SSEModel event) {
    try {
      final Map<String, dynamic> payload = jsonDecode(event.data!);
      final String type = payload['type']; // ex: 'TRANSACTION_CREATED'
      final data = payload['data'];

      switch (type) {
        case 'TRANSACTION_CREATED':
        case 'TRANSACTION_UPDATED':
          _db.into(_db.transactions).insertOnConflictUpdate(
            Transaction.fromJson(data),
          );
          break;
        case 'ACCOUNT_UPDATED':
          _db.into(_db.bankAccounts).insertOnConflictUpdate(
            BankAccount.fromJson(data),
          );
          break;
        case 'TRANSACTION_DELETED':
          (_db.delete(_db.transactions)..where((t) => t.id.equals(data['id']))).go();
          break;
      }
    } catch (e) {
        if (kDebugMode) {
          print('Erreur de synchro SSE: $e');
        }
      }
    }
  }
}