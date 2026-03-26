import 'dart:async';
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

  StreamSubscription? _sseSubscription;
  bool _syncStopped = false;

  SyncService(this._db);

  void startSync() async {
    _syncStopped = false;
    final token = await _storage.read(key: 'accessToken');
    if (token == null) return;
    _listenToSSE(token);
  }

  /// Appelé au retour au premier plan (WidgetsBindingObserver).
  /// Re-bootstrap + relance le SSE si l'utilisateur est connecté.
  Future<void> resumeSync() async {
    if (_syncStopped) return;
    final token = await _storage.read(key: 'accessToken');
    if (token == null) return;
    await bootstrapData();
    _listenToSSE(token);
  }

  void stopSync() {
    _syncStopped = true;
    _sseSubscription?.cancel();
    _sseSubscription = null;
    SSEClient.unsubscribeFromSSE();
  }

  void _listenToSSE(String token) {
    if (_syncStopped) return;

    _sseSubscription?.cancel();
    _sseSubscription = SSEClient.subscribeToSSE(
      method: SSERequestType.GET,
      url: '${AppAssets.apiUrl}/realtime',
      header: {"Authorization": "Bearer $token", "Accept": "text/event-stream"},
    ).listen(
      (event) {
        if (event.data != null && event.data!.isNotEmpty) {
          _handleServerEvent(event);
        }
      },
      onError: (_) => _handleSseDisconnect(token),
      onDone: () => _handleSseDisconnect(token),
    );
  }

  void _handleSseDisconnect(String token) async {
    if (_syncStopped) return;
    await Future.delayed(const Duration(seconds: 5));
    if (_syncStopped) return;
    // Re-bootstrap pour rattraper les événements manqués (CREATE/UPDATE/DELETE)
    await bootstrapData();
    _listenToSSE(token);
  }

  void _handleServerEvent(SSEModel event) {
    try {
      if (event.data == null || event.data!.trim() == "heartbeat") {
        return;
      }

      final Map<String, dynamic> payload = jsonDecode(event.data!);
      final String type = payload['type']; // 'CREATE', 'UPDATE', 'DELETE'
      final String model = payload['model'] ?? '';
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

  Future<List<dynamic>> _fetchAllTransactions(ApiClient api) async {
    const pageSize = 500;
    int offset = 0;
    int total = 1;
    final List<dynamic> all = [];

    while (offset < total) {
      final response = await api.dio.get('/transactions', queryParameters: {
        'limit': pageSize.toString(),
        'offset': offset.toString(),
      });
      final items = response.data as List;
      all.addAll(items);
      total = int.tryParse(response.headers.value('x-total-count') ?? '0') ?? 0;
      offset += pageSize;
    }

    return all;
  }

  Future<void> bootstrapData() async {
    final api = getIt<ApiClient>();

    try {
      final transactionsFuture = _fetchAllTransactions(api);
      final responses = await Future.wait([
        api.dio.get('/bank-accounts'),
        api.dio.get('/categories'),
        api.dio.get('/monthly-payments'),
        api.dio.get('/payment-methods'),
      ]);
      final serverTransactions = await transactionsFuture;

      final serverAccounts = responses[0].data as List;
      final serverCategories = responses[1].data as List;
      final serverMonthlyPayments = responses[2].data as List;
      final serverPaymentMethods = responses[3].data as List;

      // Sets d'IDs présents sur le serveur
      final accountIds = serverAccounts.map((e) => e['id'] as String).toSet();
      final categoryIds = serverCategories.map((e) => e['id'] as String).toSet();
      final monthlyPaymentIds = serverMonthlyPayments.map((e) => e['id'] as String).toSet();
      final paymentMethodIds = serverPaymentMethods.map((e) => e['id'] as String).toSet();
      final transactionIds = serverTransactions.map((e) => e['id'] as String).toSet();

      await _db.transaction(() async {
        // Suppression des enregistrements locaux absents du serveur
        if (accountIds.isEmpty) {
          await _db.delete(_db.bankAccounts).go();
        } else {
          await (_db.delete(_db.bankAccounts)..where((t) => t.id.isNotIn(accountIds))).go();
        }

        if (categoryIds.isEmpty) {
          await _db.delete(_db.categories).go();
        } else {
          await (_db.delete(_db.categories)..where((t) => t.id.isNotIn(categoryIds))).go();
        }

        if (monthlyPaymentIds.isEmpty) {
          await _db.delete(_db.monthlyPayments).go();
        } else {
          await (_db.delete(_db.monthlyPayments)..where((t) => t.id.isNotIn(monthlyPaymentIds))).go();
        }

        if (paymentMethodIds.isEmpty) {
          await _db.delete(_db.paymentMethods).go();
        } else {
          await (_db.delete(_db.paymentMethods)..where((t) => t.id.isNotIn(paymentMethodIds))).go();
        }

        if (transactionIds.isEmpty) {
          await _db.delete(_db.transactions).go();
        } else {
          await (_db.delete(_db.transactions)..where((t) => t.id.isNotIn(transactionIds))).go();
        }

        // Upsert des données serveur
        await _db.batch((batch) {
          batch.insertAll(
            _db.bankAccounts,
            serverAccounts.map((e) => BankAccount.fromJson(e)).toList(),
            mode: InsertMode.insertOrReplace,
          );
          batch.insertAll(
            _db.categories,
            serverCategories.map((e) {
              final data = Map<String, dynamic>.from(e);
              if (data['colorValue'] is String) {
                data['colorValue'] = int.parse(data['colorValue']);
              }
              return Category.fromJson(data);
            }).toList(),
            mode: InsertMode.insertOrReplace,
          );
          batch.insertAll(
            _db.monthlyPayments,
            serverMonthlyPayments.map((e) {
              final data = Map<String, dynamic>.from(e);
              data['lastApplied'] = data['lastProcessed'];
              return MonthlyPayment.fromJson(data);
            }).toList(),
            mode: InsertMode.insertOrReplace,
          );
          batch.insertAll(
            _db.paymentMethods,
            serverPaymentMethods.map((e) => PaymentMethod.fromJson(e)).toList(),
            mode: InsertMode.insertOrReplace,
          );
          batch.insertAll(
            _db.transactions,
            serverTransactions.map((e) => Transaction.fromJson(e)).toList(),
            mode: InsertMode.insertOrReplace,
          );
        });
      });
    } catch (e) {
      if (kDebugMode) print('Erreur lors du bootstrap: $e');
    }
  }
}
