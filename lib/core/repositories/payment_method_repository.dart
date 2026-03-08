import 'package:drift/drift.dart';
import 'package:moneo/core/database/app_database.dart';
import 'package:moneo/core/interceptor/api_client.dart';

class PaymentMethodRepository {
  final AppDatabase _db;
  final ApiClient _api;

  PaymentMethodRepository(this._db, this._api);

  Stream<List<PaymentMethod>> watchPaymentMethods() {
    return _db.select(_db.paymentMethods).watch();
  }

  Future<List<PaymentMethod>> getPaymentMethods() {
    return _db.select(_db.paymentMethods).get();
  }

  Future<void> createPaymentMethod(PaymentMethodsCompanion entry) async {
    await _db.into(_db.paymentMethods).insert(entry, mode: InsertMode.insertOrReplace);
    try {
      await _api.dio.post('/payment-methods', data: {
        'id': entry.id.value,
        'name': entry.name.value,
        'type': entry.type.value,
      });
    } catch (_) {}
  }

  Future<void> updatePaymentMethod(String id, PaymentMethodsCompanion entry) async {
    await (_db.update(_db.paymentMethods)..where((t) => t.id.equals(id))).write(entry);
    try {
      await _api.dio.patch('/payment-methods/$id', data: {
        if (entry.name.present) 'name': entry.name.value,
        if (entry.type.present) 'type': entry.type.value,
      });
    } catch (_) {}
  }

  Future<void> deletePaymentMethod(String id) async {
    await (_db.delete(_db.paymentMethods)..where((t) => t.id.equals(id))).go();
    try {
      await _api.dio.delete('/payment-methods/$id');
    } catch (_) {}
  }
}
