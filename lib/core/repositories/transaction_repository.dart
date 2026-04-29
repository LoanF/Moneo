import 'package:moneo/core/interceptor/api_client.dart';
import 'package:moneo/data/models/models.dart';

class TransactionRepository {
  final ApiClient _api;

  TransactionRepository(this._api);

  Future<List<Transaction>> fetchTransactions({String? accountId, int limit = 200, int offset = 0}) async {
    final response = await _api.dio.get('/transactions', queryParameters: {
      'limit': limit.toString(),
      'offset': offset.toString(),
      if (accountId != null) 'accountId': accountId,
    });
    return (response.data as List).map((e) => Transaction.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Transaction> addTransaction(Transaction t) async {
    final response = await _api.dio.post('/transactions', data: {
      'id': t.id,
      'amount': t.amount,
      'type': t.type,
      'accountId': t.accountId,
      'date': t.date.toIso8601String(),
      if (t.note != null) 'note': t.note,
      if (t.categoryId != null) 'categoryId': t.categoryId,
      if (t.paymentMethodId != null) 'paymentMethodId': t.paymentMethodId,
      if (t.chequeNumber != null) 'chequeNumber': t.chequeNumber,
    });
    return Transaction.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Transaction> updateTransaction(Transaction t) async {
    final response = await _api.dio.patch('/transactions/${t.id}', data: {
      'amount': t.amount,
      'type': t.type,
      'date': t.date.toIso8601String(),
      'isChecked': t.isChecked,
      if (t.note != null) 'note': t.note,
      if (t.categoryId != null) 'categoryId': t.categoryId,
      if (t.paymentMethodId != null) 'paymentMethodId': t.paymentMethodId,
      'chequeNumber': t.chequeNumber,
    });
    return Transaction.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> addTransfer({
    required String fromAccountId,
    required String toAccountId,
    required double amount,
    String? note,
    DateTime? date,
  }) async {
    await _api.dio.post('/transactions/transfer', data: {
      'fromAccountId': fromAccountId,
      'toAccountId': toAccountId,
      'amount': amount,
      if (note != null) 'note': note,
      if (date != null) 'date': date.toIso8601String(),
    });
  }

  Future<void> deleteTransaction(String id) async {
    await _api.dio.delete('/transactions/$id');
  }
}
