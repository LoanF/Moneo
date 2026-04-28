double _parseDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  if (value is num) return value.toDouble();
  return 0.0;
}

class Transaction {
  final String id;
  final double amount;
  final String type;
  final DateTime date;
  final String? note;
  final bool isChecked;
  final String accountId;
  final String? categoryId;
  final String? paymentMethodId;
  final bool isMonthly;

  const Transaction({
    required this.id,
    required this.amount,
    required this.type,
    required this.date,
    this.note,
    this.isChecked = false,
    required this.accountId,
    this.categoryId,
    this.paymentMethodId,
    this.isMonthly = false,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    final note = json['note'] as String?;
    return Transaction(
      id: json['id'] as String,
      amount: _parseDouble(json['amount']),
      type: json['type'] as String,
      date: DateTime.parse(json['date'] as String),
      note: note,
      isChecked: json['isChecked'] as bool? ?? false,
      accountId: json['accountId'] as String,
      categoryId: json['categoryId'] as String?,
      paymentMethodId: json['paymentMethodId'] as String?,
      isMonthly: note?.startsWith('[Auto]') ?? false,
    );
  }

  static const _keep = Object();

  Transaction copyWith({
    String? id,
    double? amount,
    String? type,
    DateTime? date,
    Object? note = _keep,
    bool? isChecked,
    String? accountId,
    Object? categoryId = _keep,
    Object? paymentMethodId = _keep,
  }) {
    return Transaction(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      date: date ?? this.date,
      note: note == _keep ? this.note : note as String?,
      isChecked: isChecked ?? this.isChecked,
      accountId: accountId ?? this.accountId,
      categoryId: categoryId == _keep ? this.categoryId : categoryId as String?,
      paymentMethodId: paymentMethodId == _keep ? this.paymentMethodId : paymentMethodId as String?,
      isMonthly: isMonthly,
    );
  }
}

class BankAccount {
  final String id;
  final String name;
  final double balance;
  final double pointedBalance;
  final int sortOrder;
  final String type;
  final String currency;

  const BankAccount({
    required this.id,
    required this.name,
    required this.balance,
    double? pointedBalance,
    this.sortOrder = 0,
    this.type = 'checking',
    this.currency = 'EUR',
  }) : pointedBalance = pointedBalance ?? balance;

  factory BankAccount.fromJson(Map<String, dynamic> json) {
    final balance = _parseDouble(json['balance']);
    return BankAccount(
      id: json['id'] as String,
      name: json['name'] as String,
      balance: balance,
      pointedBalance: json['pointedBalance'] != null ? _parseDouble(json['pointedBalance']) : balance,
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      type: json['type'] as String? ?? 'checking',
      currency: json['currency'] as String? ?? 'EUR',
    );
  }
}

class Category {
  final String id;
  final String name;
  final String iconCode;
  final int colorValue;
  final String userId;
  final String? parentId;

  const Category({
    required this.id,
    required this.name,
    required this.iconCode,
    required this.colorValue,
    required this.userId,
    this.parentId,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    final colorVal = json['colorValue'];
    return Category(
      id: json['id'] as String,
      name: json['name'] as String,
      iconCode: json['iconCode'].toString(),
      colorValue: colorVal is String ? int.parse(colorVal) : (colorVal as num).toInt(),
      userId: json['userId'] as String? ?? '',
      parentId: json['parentId'] as String?,
    );
  }
}

class MonthlyPayment {
  final String id;
  final String name;
  final double amount;
  final String type;
  final int dayOfMonth;
  final String accountId;
  final String? categoryId;
  final DateTime? lastApplied;

  const MonthlyPayment({
    required this.id,
    required this.name,
    required this.amount,
    required this.type,
    required this.dayOfMonth,
    required this.accountId,
    this.categoryId,
    this.lastApplied,
  });

  factory MonthlyPayment.fromJson(Map<String, dynamic> json) {
    final lastProcessed = json['lastProcessed'] ?? json['lastApplied'];
    return MonthlyPayment(
      id: json['id'] as String,
      name: json['name'] as String,
      amount: _parseDouble(json['amount']),
      type: json['type'] as String,
      dayOfMonth: (json['dayOfMonth'] as num).toInt(),
      accountId: json['accountId'] as String,
      categoryId: json['categoryId'] as String?,
      lastApplied: lastProcessed != null ? DateTime.tryParse(lastProcessed as String) : null,
    );
  }
}

class PaymentMethod {
  final String id;
  final String name;
  final String type;

  const PaymentMethod({
    required this.id,
    required this.name,
    this.type = 'debit',
  });

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String? ?? 'debit',
    );
  }
}
