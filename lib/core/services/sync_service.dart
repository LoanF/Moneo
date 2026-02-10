import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter_client_sse/constants/sse_request_type_enum.dart';
import 'package:flutter_client_sse/flutter_client_sse.dart';
import 'package:moneo/core/database/app_database.dart';
import 'package:moneo/data/constants/assets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../di.dart';
import '../interceptor/api_client.dart';

class SyncService {
  final AppDatabase _db;
  final _storage = const FlutterSecureStorage();

  SyncService(this._db);

  void startSync() async {
    final token = await _storage.read(key: 'accessToken');
    if (token == null) return;

    SSEClient.subscribeToSSE(
      method: SSERequestType.GET,
      url: '${AppAssets.apiUrl}/realtime',
      header: {"Authorization": "Bearer $token", "Accept": "text/event-stream"},
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
      if (event.data == null || event.data!.trim() == "heartbeat") {
        return;
      }
      
      final Map<String, dynamic> payload = jsonDecode(event.data!);
      final String type = payload['type'];
      final data = payload['data'];

      switch (type) {
        case 'TRANSACTION_CREATED':
        case 'TRANSACTION_UPDATED':
          _db
              .into(_db.transactions)
              .insertOnConflictUpdate(Transaction.fromJson(data));
          break;
        case 'ACCOUNT_UPDATED':
          _db
              .into(_db.bankAccounts)
              .insertOnConflictUpdate(BankAccount.fromJson(data));
          break;
        case 'TRANSACTION_DELETED':
          (_db.delete(
            _db.transactions,
          )..where((t) => t.id.equals(data['id']))).go();
          break;
        case 'MONTHLY_PAYMENT_CREATED':
          _db.into(_db.monthlyPayments).insertOnConflictUpdate(MonthlyPayment.fromJson(data));
          break;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erreur de synchro SSE: $e');
      }
    }
  }

  Future<void> bootstrapData() async {
    final api = getIt<ApiClient>();

    try {
      final responses = await Future.wait([
        api.dio.get('/bank-accounts'),
        api.dio.get('/categories'),
        api.dio.get('/monthly-payments'),
        api.dio.get('/transactions?limit=100'),
      ]);

      await _db.batch((batch) {
        batch.insertAll(_db.bankAccounts, (responses[0].data as List).map((e) => BankAccount.fromJson(e)).toList(), mode: InsertMode.insertOrReplace);
        batch.insertAll(_db.categories, (responses[1].data as List).map((e) => Category.fromJson(e)).toList(), mode: InsertMode.insertOrReplace);
        batch.insertAll(_db.monthlyPayments, (responses[2].data as List).map((e) => MonthlyPayment.fromJson(e)).toList(), mode: InsertMode.insertOrReplace);
        batch.insertAll(_db.transactions, (responses[3].data as List).map((e) => Transaction.fromJson(e)).toList(), mode: InsertMode.insertOrReplace);
      });
    } catch (e) {
      if (kDebugMode) print('Erreur lors du bootstrap: $e');
    }
  }
}
