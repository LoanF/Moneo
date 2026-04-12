import 'package:moneo/core/interceptor/api_client.dart';
import 'package:moneo/data/models/models.dart';

class BankAccountRepository {
  final ApiClient _api;

  BankAccountRepository(this._api);

  Future<List<BankAccount>> fetchAccounts() async {
    final response = await _api.dio.get('/bank-accounts');
    return (response.data as List).map((e) => BankAccount.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<BankAccount> createAccount({required String id, required String name, required double balance}) async {
    final response = await _api.dio.post('/bank-accounts', data: {'id': id, 'name': name, 'balance': balance});
    return BankAccount.fromJson(response.data as Map<String, dynamic>);
  }

  Future<BankAccount> updateAccount(String id, {String? name, double? balance}) async {
    final response = await _api.dio.patch('/bank-accounts/$id', data: {
      if (name != null) 'name': name,
      if (balance != null) 'balance': balance,
    });
    return BankAccount.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteAccount(String id) async {
    await _api.dio.delete('/bank-accounts/$id');
  }
}
