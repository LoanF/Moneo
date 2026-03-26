import 'package:moneo/core/database/app_database.dart';
import 'package:moneo/core/interceptor/api_client.dart';
import 'package:drift/drift.dart';

class MonthlyPaymentRepository {
  final AppDatabase _db;
  final ApiClient _api;

  MonthlyPaymentRepository(this._db, this._api);

  Stream<List<MonthlyPayment>> watchMonthlyPayments() {
    return _db.select(_db.monthlyPayments).watch();
  }

  Future<void> createMonthlyPayment(MonthlyPaymentsCompanion entry) async {
    await _db.into(_db.monthlyPayments).insert(entry, mode: InsertMode.insertOrReplace);
    try {
      await _api.dio.post('/monthly-payments', data: {
        'id': entry.id.value,
        'name': entry.name.value,
        'amount': entry.amount.value,
        'type': entry.type.value,
        'dayOfMonth': entry.dayOfMonth.value,
        'accountId': entry.accountId.value,
        'categoryId': entry.categoryId.value,
      });
    } catch (_) {}
  }

  Future<void> deleteMonthlyPayment(String id) async {
    await (_db.delete(_db.monthlyPayments)..where((t) => t.id.equals(id))).go();

    try {
      await _api.dio.delete('/monthly-payments/$id');
    } catch (_) {}
  }
}