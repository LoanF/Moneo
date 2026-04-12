import 'package:moneo/core/interceptor/api_client.dart';
import 'package:moneo/data/models/models.dart';

class PaymentMethodRepository {
  final ApiClient _api;

  PaymentMethodRepository(this._api);

  Future<List<PaymentMethod>> fetchPaymentMethods() async {
    final response = await _api.dio.get('/payment-methods');
    return (response.data as List).map((e) => PaymentMethod.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<PaymentMethod> createPaymentMethod({
    required String id,
    required String name,
    required String type,
  }) async {
    final response = await _api.dio.post('/payment-methods', data: {'id': id, 'name': name, 'type': type});
    return PaymentMethod.fromJson(response.data as Map<String, dynamic>);
  }

  Future<PaymentMethod> updatePaymentMethod(String id, {String? name, String? type}) async {
    final response = await _api.dio.patch('/payment-methods/$id', data: {
      if (name != null) 'name': name,
      if (type != null) 'type': type,
    });
    return PaymentMethod.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deletePaymentMethod(String id) async {
    await _api.dio.delete('/payment-methods/$id');
  }
}
