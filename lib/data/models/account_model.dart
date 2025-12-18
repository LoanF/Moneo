class Account {
  final String id;
  final String name;
  final double initialBalance;
  final double currentBalance;

  Account({
    required this.id,
    required this.name,
    required this.initialBalance,
    required this.currentBalance,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'initialBalance': initialBalance,
    'currentBalance': currentBalance,
  };

  factory Account.fromJson(Map<String, dynamic> json) => Account(
    id: json['id'],
    name: json['name'],
    initialBalance: (json['initialBalance'] as num).toDouble(),
    currentBalance: (json['currentBalance'] as num).toDouble(),
  );
}