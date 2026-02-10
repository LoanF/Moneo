import 'package:moneo/core/database/app_database.dart';
import 'package:moneo/core/interceptor/api_client.dart';
import 'package:drift/drift.dart';

class BankAccountRepository {
  final AppDatabase _db;
  final ApiClient _api;

  BankAccountRepository(this._db, this._api);

  Stream<List<BankAccount>> watchAccounts() {
    return _db.select(_db.bankAccounts).watch();
  }

  Future<void> createAccount(BankAccountsCompanion entry) async {
    await _db
        .into(_db.bankAccounts)
        .insert(entry, mode: InsertMode.insertOrReplace);

    try {
      final response = await _api.dio.post(
        '/accounts',
        data: {
          'id': entry.id.value,
          'name': entry.name.value,
          'balance': entry.balance.value,
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
      }
    } catch (e) {}
  }

  Future<void> updateAccount(String id, BankAccountsCompanion entry) async {
    await (_db.update(
      _db.bankAccounts,
    )..where((t) => t.id.equals(id))).write(entry);

    try {
      await _api.dio.patch(
        '/accounts/$id',
        data: {
          if (entry.name.present) 'name': entry.name.value,
          if (entry.balance.present) 'balance': entry.balance.value,
        },
      );
    } catch (_) {}
  }

  Future<void> deleteAccount(String id) async {
    await (_db.delete(_db.bankAccounts)..where((t) => t.id.equals(id))).go();

    try {
      await _api.dio.delete('/accounts/$id');
    } catch (_) {}
  }
}
