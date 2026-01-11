class Account {
  final String id;
  final String name;
  final double initialBalance;
  final double currentBalance;
  final int order;

  Account({
    required this.id,
    required this.name,
    required this.initialBalance,
    required this.currentBalance,
    this.order = 0,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'initialBalance': initialBalance,
    'currentBalance': currentBalance,
    'order': order,
  };

  factory Account.fromJson(Map<String, dynamic> json) => Account(
    id: json['id'],
    name: json['name'],
    initialBalance: (json['initialBalance'] as num).toDouble(),
    currentBalance: (json['currentBalance'] as num).toDouble(),
    order: json['order'] ?? 0,
  );

  Account copyWith({
    String? name,
    double? initialBalance,
    double? currentBalance,
    int? order,
  }) {
    return Account(
      id: id,
      name: name ?? this.name,
      initialBalance: initialBalance ?? this.initialBalance,
      currentBalance: currentBalance ?? this.currentBalance,
      order: order ?? this.order,
    );
  }
}