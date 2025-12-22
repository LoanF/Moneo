import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionModel {
  final String id;
  final String title;
  final double amount;
  final String accountId;
  final DateTime date;
  final String? category;
  bool isChecked = false;

  TransactionModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.accountId,
    required this.date,
    required this.category,
    this.isChecked = false,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] as String,
      title: json['title'] as String,
      amount: (json['amount'] as num).toDouble(),
      accountId: json['accountId'] as String,
      date: (json['date'] as Timestamp).toDate(),
      category: json['category'] as String?,
      isChecked: json['isChecked'] as bool? ?? false
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'accountId': accountId,
      'date': Timestamp.fromDate(date),
      'category': category,
      'isChecked': isChecked,
    };
  }

  bool get isExpense => amount < 0;
}