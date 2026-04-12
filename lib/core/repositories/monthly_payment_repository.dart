import 'package:moneo/core/interceptor/api_client.dart';
import 'package:moneo/data/models/models.dart';

class MonthlyPaymentRepository {
  final ApiClient _api;

  MonthlyPaymentRepository(this._api);

  Future<List<MonthlyPayment>> fetchMonthlyPayments() async {
    final response = await _api.dio.get('/monthly-payments');
    return (response.data as List).map((e) => MonthlyPayment.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<MonthlyPayment> createMonthlyPayment({
    required String id,
    required String name,
    required double amount,
    required String type,
    required int dayOfMonth,
    required String accountId,
    String? categoryId,
  }) async {
    final response = await _api.dio.post('/monthly-payments', data: {
      'id': id,
      'name': name,
      'amount': amount,
      'type': type,
      'dayOfMonth': dayOfMonth,
      'accountId': accountId,
      'categoryId': categoryId,
    });
    return MonthlyPayment.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteMonthlyPayment(String id) async {
    await _api.dio.delete('/monthly-payments/$id');
  }
}
