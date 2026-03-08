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
      final String type = payload['type']; // 'CREATE', 'UPDATE', 'DELETE'
      final String model = payload['model'] ?? ''; // 'Transaction', 'BankAccount', 'MonthlyPayment'
      final data = payload['data'];

      if (model == 'Transaction') {
        if (type == 'CREATE' || type == 'UPDATE') {
          _db.into(_db.transactions).insertOnConflictUpdate(Transaction.fromJson(data));
        } else if (type == 'DELETE') {
          (_db.delete(_db.transactions)..where((t) => t.id.equals(data['id']))).go();
        }
      } else if (model == 'BankAccount') {
        if (type == 'CREATE' || type == 'UPDATE') {
          _db.into(_db.bankAccounts).insertOnConflictUpdate(BankAccount.fromJson(data));
        } else if (type == 'DELETE') {
          (_db.delete(_db.bankAccounts)..where((t) => t.id.equals(data['id']))).go();
        }
      } else if (model == 'MonthlyPayment') {
        if (type == 'CREATE' || type == 'UPDATE') {
          final mp = Map<String, dynamic>.from(data);
          mp['lastApplied'] = mp['lastProcessed'];
          _db.into(_db.monthlyPayments).insertOnConflictUpdate(MonthlyPayment.fromJson(mp));
        } else if (type == 'DELETE') {
          (_db.delete(_db.monthlyPayments)..where((t) => t.id.equals(data['id']))).go();
        }
      } else if (model == 'PaymentMethod') {
        if (type == 'CREATE' || type == 'UPDATE') {
          _db.into(_db.paymentMethods).insertOnConflictUpdate(PaymentMethod.fromJson(data));
        } else if (type == 'DELETE') {
          (_db.delete(_db.paymentMethods)..where((t) => t.id.equals(data['id']))).go();
        }
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
        api.dio.get('/payment-methods'),
      ]);

      await _db.batch((batch) {
        batch.insertAll(_db.bankAccounts, (responses[0].data as List).map((e) => BankAccount.fromJson(e)).toList(), mode: InsertMode.insertOrReplace);
        batch.insertAll(_db.categories, (responses[1].data as List).map((e) {
          final data = Map<String, dynamic>.from(e);
          if (data['colorValue'] is String) {
            data['colorValue'] = int.parse(data['colorValue']);
          }
          if (data['iconCode'] is String) {
            data['iconCode'] = int.parse(data['iconCode']);
          }
          return Category.fromJson(data);
        }).toList(), mode: InsertMode.insertOrReplace);
        batch.insertAll(_db.monthlyPayments, (responses[2].data as List).map((e) {
          final data = Map<String, dynamic>.from(e);
          data['lastApplied'] = data['lastProcessed'];
          return MonthlyPayment.fromJson(data);
        }).toList(), mode: InsertMode.insertOrReplace);
        batch.insertAll(_db.transactions, (responses[3].data as List).map((e) => Transaction.fromJson(e)).toList(), mode: InsertMode.insertOrReplace);
        batch.insertAll(_db.paymentMethods, (responses[4].data as List).map((e) => PaymentMethod.fromJson(e)).toList(), mode: InsertMode.insertOrReplace);
      });
    } catch (e) {
      if (kDebugMode) print('Erreur lors du bootstrap: $e');
    }
  }
}
