class MonthlyOperationModel {
  final String id;
  final int dayOfMonth;
  final String accountId;
  final bool isExpense;
  final String title;
  final String categoryId;
  final List<double> amounts;
  final String? lastAppliedMonth;

  MonthlyOperationModel({
    required this.id,
    required this.dayOfMonth,
    required this.accountId,
    required this.isExpense,
    required this.title,
    required this.categoryId,
    required this.amounts,
    this.lastAppliedMonth,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'dayOfMonth': dayOfMonth,
    'accountId': accountId,
    'isExpense': isExpense,
    'title': title,
    'categoryId': categoryId,
    'amounts': amounts,
    'lastAppliedMonth': lastAppliedMonth,
  };

  factory MonthlyOperationModel.fromJson(Map<String, dynamic> json) => MonthlyOperationModel(
    id: json['id'],
    dayOfMonth: (json['dayOfMonth'] as num).toInt(),
    accountId: json['accountId'],
    isExpense: json['isExpense'],
    title: json['title'],
    categoryId: json['categoryId'],
    amounts: List<double>.from(json['amounts'].map((x) => (x as num).toDouble())),
    lastAppliedMonth: json['lastAppliedMonth'],
  );
}