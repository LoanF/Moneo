import 'package:moneo/core/database/app_database.dart';
import 'package:moneo/core/interceptor/api_client.dart';
import 'package:drift/drift.dart';

class TransactionRepository {
  final AppDatabase _db;
  final ApiClient _api;

  TransactionRepository(this._db, this._api);

  Stream<List<Transaction>> watchTransactions(String accountId) {
    return (_db.select(_db.transactions)
          ..where((t) => t.accountId.equals(accountId))
          ..orderBy([
            (t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc),
          ]))
        .watch();
  }

  Future<void> addTransaction(TransactionsCompanion entry) async {
    await _db.into(_db.transactions).insert(entry);

    try {
      await _api.dio.post(
        '/transactions',
        data: {
          'id': entry.id.value,
          'amount': entry.amount.value,
          'type': entry.type.value,
          'accountId': entry.accountId.value,
          'date': entry.date.value.toIso8601String(),
          'note': entry.note.value,
          'categoryId': entry.categoryId.value,
        },
      );
    } catch (e) {
      // Le SyncService ou un retry s'en occupera plus tard.
    }
  }

  Future<void> updateTransaction(String id, TransactionsCompanion entry) async {
    await (_db.update(_db.transactions)..where((t) => t.id.equals(id))).write(entry);

    try {
      await _api.dio.patch('/transactions/$id', data: {
        if (entry.amount.present) 'amount': entry.amount.value,
        if (entry.type.present) 'type': entry.type.value,
        if (entry.accountId.present) 'accountId': entry.accountId.value,
        if (entry.categoryId.present) 'categoryId': entry.categoryId.value,
        if (entry.date.present) 'date': entry.date.value.toIso8601String(),
        if (entry.note.present) 'note': entry.note.value,
        if (entry.isChecked.present) 'isChecked': entry.isChecked.value,
      });
    } catch (e) {
      // Le SyncService ou un retry s'en occupera plus tard.
    }
  }

  Future<void> deleteTransaction(String id) async {
    await (_db.delete(_db.transactions)..where((t) => t.id.equals(id))).go();
    try {
      await _api.dio.delete('/transactions/$id');
    } catch (_) {}
  }
}
