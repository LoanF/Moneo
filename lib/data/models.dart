/// Modèles de l'API Moneo v2. Immuables, sans génération de code.
library;

typedef Json = Map<String, dynamic>;

double _d(Object? v) => v == null ? 0 : (v as num).toDouble();
double? _dn(Object? v) => v == null ? null : (v as num).toDouble();
int _i(Object? v) => v == null ? 0 : (v as num).toInt();

// ── Utilisateur ──────────────────────────────────────────────────────────────

enum RecurringMode {
  monthStart(
    'month_start',
    'Tout le mois d’un coup',
    'Les opérations du mois sont ajoutées dès le 1er, comme dans le classeur.',
  ),
  dueDate(
    'due_date',
    'À l’échéance',
    'Chaque opération est ajoutée le jour prévu.',
  ),
  manual(
    'manual',
    'À la main',
    'Rien n’est ajouté sans votre accord ; un rappel vous prévient.',
  );

  const RecurringMode(this.wire, this.label, this.help);
  final String wire;
  final String label;
  final String help;
  static RecurringMode parse(Object? v) =>
      values.firstWhere((m) => m.wire == v, orElse: () => monthStart);
}

class UserSettings {
  const UserSettings({
    this.currency = 'EUR',
    this.monthStartDay = 1,
    this.defaultAccountId,
    this.skipNote = false,
    this.trackingStartDate,
    this.recurringMode = RecurringMode.monthStart,
    this.lowBalanceThreshold,
  });

  final String currency;
  final int monthStartDay;
  final String? defaultAccountId;
  final bool skipNote;
  final String? trackingStartDate;
  final RecurringMode recurringMode;
  final double? lowBalanceThreshold;

  factory UserSettings.fromJson(Json j) => UserSettings(
    currency: j['currency'] as String? ?? 'EUR',
    monthStartDay: _i(j['monthStartDay'] ?? 1),
    defaultAccountId: j['defaultAccountId'] as String?,
    skipNote: j['skipNote'] as bool? ?? false,
    trackingStartDate: j['trackingStartDate'] as String?,
    recurringMode: RecurringMode.parse(j['recurringMode']),
    lowBalanceThreshold: _dn(j['lowBalanceThreshold']),
  );
}

class NotificationPrefs {
  const NotificationPrefs({
    this.paymentApplied = true,
    this.lowBalance = true,
    this.monthlyRecap = true,
    this.activityReminder = true,
    this.budgetAlert = true,
    this.upcomingPayment = true,
    this.quietHoursStart,
    this.quietHoursEnd,
  });

  final bool paymentApplied,
      lowBalance,
      monthlyRecap,
      activityReminder,
      budgetAlert,
      upcomingPayment;
  final String? quietHoursStart, quietHoursEnd;

  factory NotificationPrefs.fromJson(Json j) => NotificationPrefs(
    paymentApplied: j['paymentApplied'] as bool? ?? true,
    lowBalance: j['lowBalance'] as bool? ?? true,
    monthlyRecap: j['monthlyRecap'] as bool? ?? true,
    activityReminder: j['activityReminder'] as bool? ?? true,
    budgetAlert: j['budgetAlert'] as bool? ?? true,
    upcomingPayment: j['upcomingPayment'] as bool? ?? true,
    quietHoursStart: j['quietHoursStart'] as String?,
    quietHoursEnd: j['quietHoursEnd'] as String?,
  );
}

class AppUser {
  const AppUser({
    required this.id,
    required this.username,
    required this.email,
    this.photoUrl,
    required this.hasCompletedSetup,
    required this.emailVerified,
    required this.hasPassword,
    required this.settings,
    required this.notificationPrefs,
  });

  final String id, username, email;
  final String? photoUrl;
  final bool hasCompletedSetup, emailVerified, hasPassword;
  final UserSettings settings;
  final NotificationPrefs notificationPrefs;

  factory AppUser.fromJson(Json j) => AppUser(
    id: j['id'] as String,
    username: j['username'] as String? ?? '',
    email: j['email'] as String? ?? '',
    photoUrl: j['photoUrl'] as String?,
    hasCompletedSetup: j['hasCompletedSetup'] as bool? ?? false,
    emailVerified: j['emailVerified'] as bool? ?? false,
    hasPassword: j['hasPassword'] as bool? ?? true,
    settings: UserSettings.fromJson((j['settings'] as Json?) ?? const {}),
    notificationPrefs: NotificationPrefs.fromJson(
      (j['notificationPrefs'] as Json?) ?? const {},
    ),
  );
}

class DeviceSession {
  const DeviceSession({
    required this.id,
    this.deviceName,
    this.platform,
    required this.lastUsedAt,
    required this.current,
  });
  final String id;
  final String? deviceName, platform;
  final DateTime lastUsedAt;
  final bool current;

  factory DeviceSession.fromJson(Json j) => DeviceSession(
    id: j['id'] as String,
    deviceName: j['deviceName'] as String?,
    platform: j['platform'] as String?,
    lastUsedAt: DateTime.parse(j['lastUsedAt'] as String).toLocal(),
    current: j['current'] as bool? ?? false,
  );
}

// ── Comptes et catalogue ─────────────────────────────────────────────────────

class Account {
  const Account({
    required this.id,
    required this.name,
    required this.type,
    required this.initialBalance,
    required this.sortOrder,
    this.lowBalanceThreshold,
    required this.includeInTotal,
    required this.archived,
    required this.balance,
    required this.pointedBalance,
    required this.todayBalance,
    required this.uncheckedCredit,
    required this.uncheckedDebit,
    required this.uncheckedCount,
    required this.transactionCount,
  });

  final String id, name, type;
  final double initialBalance;
  final int sortOrder;
  final double? lowBalanceThreshold;
  final bool includeInTotal, archived;

  /// Solde restant : toutes les écritures, y compris celles à venir.
  final double balance;

  /// Solde pointé : uniquement les écritures rapprochées du relevé.
  final double pointedBalance;

  /// Solde à ce jour : sans les écritures datées dans le futur.
  final double todayBalance;
  final double uncheckedCredit, uncheckedDebit;
  final int uncheckedCount, transactionCount;

  factory Account.fromJson(Json j) => Account(
    id: j['id'] as String,
    name: j['name'] as String,
    type: j['type'] as String? ?? 'checking',
    initialBalance: _d(j['initialBalance']),
    sortOrder: _i(j['sortOrder']),
    lowBalanceThreshold: _dn(j['lowBalanceThreshold']),
    includeInTotal: j['includeInTotal'] as bool? ?? true,
    archived: j['archived'] as bool? ?? false,
    balance: _d(j['balance']),
    pointedBalance: _d(j['pointedBalance']),
    todayBalance: _d(j['todayBalance']),
    uncheckedCredit: _d(j['uncheckedCredit']),
    uncheckedDebit: _d(j['uncheckedDebit']),
    uncheckedCount: _i(j['uncheckedCount']),
    transactionCount: _i(j['transactionCount']),
  );
}

const accountTypeLabels = {
  'checking': 'Compte courant',
  'savings': 'Épargne',
  'cash': 'Espèces',
  'investment': 'Placement',
  'other': 'Autre',
};

class Category {
  const Category({
    required this.id,
    required this.name,
    required this.iconCode,
    required this.colorValue,
    this.parentId,
    required this.sortOrder,
  });
  final String id, name, iconCode;
  final int colorValue;
  final String? parentId;
  final int sortOrder;

  factory Category.fromJson(Json j) => Category(
    id: j['id'] as String,
    name: j['name'] as String,
    iconCode: j['iconCode'] as String? ?? 'category',
    colorValue: _i(j['colorValue'] ?? 0xFF607D8B),
    parentId: j['parentId'] as String?,
    sortOrder: _i(j['sortOrder']),
  );
}

enum PaymentKind {
  card('card', 'Carte'),
  cheque('cheque', 'Chèque'),
  directDebit('direct_debit', 'Prélèvement'),
  transfer('transfer', 'Virement'),
  cash('cash', 'Espèces'),
  other('other', 'Autre');

  const PaymentKind(this.wire, this.label);
  final String wire, label;
  static PaymentKind parse(Object? v) =>
      values.firstWhere((k) => k.wire == v, orElse: () => other);
}

class PaymentMethod {
  const PaymentMethod({
    required this.id,
    required this.name,
    required this.kind,
    required this.defaultIncome,
  });
  final String id, name;
  final PaymentKind kind;

  /// Sens présélectionné à la saisie : `true` = revenu.
  final bool defaultIncome;

  factory PaymentMethod.fromJson(Json j) => PaymentMethod(
    id: j['id'] as String,
    name: j['name'] as String,
    kind: PaymentKind.parse(j['kind']),
    defaultIncome: j['defaultDirection'] == 'income',
  );
}

class Chequebook {
  const Chequebook({
    required this.id,
    required this.name,
    this.accountId,
    required this.nextNumber,
    required this.isActive,
  });
  final String id, name;
  final String? accountId;
  final int nextNumber;
  final bool isActive;

  factory Chequebook.fromJson(Json j) => Chequebook(
    id: j['id'] as String,
    name: j['name'] as String,
    accountId: j['accountId'] as String?,
    nextNumber: _i(j['nextNumber'] ?? 1),
    isActive: j['isActive'] as bool? ?? true,
  );
}

// ── Opérations ───────────────────────────────────────────────────────────────

enum TxType {
  expense('expense', 'Dépense'),
  income('income', 'Revenu'),
  transfer('transfer', 'Transfert');

  const TxType(this.wire, this.label);
  final String wire, label;
  static TxType parse(Object? v) =>
      values.firstWhere((t) => t.wire == v, orElse: () => expense);
}

class Tx {
  const Tx({
    required this.id,
    required this.accountId,
    this.categoryId,
    this.paymentMethodId,
    this.chequeNumber,
    required this.amount,
    required this.type,
    required this.date,
    this.note,
    required this.isChecked,
    this.transferId,
    this.counterparty,
    this.recurringPaymentId,
    this.deleted = false,
    this.pending = false,
  });

  final String id, accountId;
  final String? categoryId, paymentMethodId, chequeNumber;

  /// Montant signé : négatif = sortie du compte.
  final double amount;
  final TxType type;

  /// Date au format `AAAA-MM-JJ`.
  final String date;
  final String? note;
  final bool isChecked;
  final String? transferId, counterparty, recurringPaymentId;
  final bool deleted;

  /// Créée hors-ligne, pas encore envoyée au serveur.
  final bool pending;

  factory Tx.fromJson(Json j) => Tx(
    id: j['id'] as String,
    accountId: j['accountId'] as String,
    categoryId: j['categoryId'] as String?,
    paymentMethodId: j['paymentMethodId'] as String?,
    chequeNumber: j['chequeNumber'] as String?,
    amount: _d(j['amount']),
    type: TxType.parse(j['type']),
    date: j['date'] as String,
    note: j['note'] as String?,
    isChecked: j['isChecked'] as bool? ?? false,
    transferId: j['transferId'] as String?,
    counterparty: j['counterparty'] as String?,
    recurringPaymentId: j['recurringPaymentId'] as String?,
    deleted: j['deletedAt'] != null,
    pending: j['pending'] as bool? ?? false,
  );

  Json toJson() => {
    'id': id,
    'accountId': accountId,
    'categoryId': categoryId,
    'paymentMethodId': paymentMethodId,
    'chequeNumber': chequeNumber,
    'amount': amount,
    'type': type.wire,
    'date': date,
    'note': note,
    'isChecked': isChecked,
    'transferId': transferId,
    'counterparty': counterparty,
    'recurringPaymentId': recurringPaymentId,
    'pending': pending,
  };

  Tx copyWith({bool? isChecked, bool? pending}) => Tx(
    id: id,
    accountId: accountId,
    categoryId: categoryId,
    paymentMethodId: paymentMethodId,
    chequeNumber: chequeNumber,
    amount: amount,
    type: type,
    date: date,
    note: note,
    isChecked: isChecked ?? this.isChecked,
    transferId: transferId,
    counterparty: counterparty,
    recurringPaymentId: recurringPaymentId,
    deleted: deleted,
    pending: pending ?? this.pending,
  );
}

/// Brouillon envoyé à l'API pour créer ou modifier une opération.
class TxDraft {
  const TxDraft({
    this.id,
    required this.accountId,
    required this.type,
    required this.amount,
    required this.date,
    this.note,
    this.categoryId,
    this.paymentMethodId,
    this.chequeNumber,
    this.isChecked = false,
    this.toAccountId,
    this.counterparty,
  });

  final String? id;
  final String accountId;
  final TxType type;
  final double amount;
  final String date;
  final String? note, categoryId, paymentMethodId, chequeNumber;
  final bool isChecked;
  final String? toAccountId, counterparty;

  Json toJson() => {
    if (id != null) 'id': id,
    'accountId': accountId,
    'type': type.wire,
    'amount': amount,
    'date': date,
    'note': note,
    'categoryId': categoryId,
    'paymentMethodId': paymentMethodId,
    if (chequeNumber != null && chequeNumber!.isNotEmpty)
      'chequeNumber': chequeNumber,
    'isChecked': isChecked,
  };

  Json toTransferJson() => {
    if (id != null) 'id': id,
    'fromAccountId': accountId,
    if (toAccountId != null) 'toAccountId': toAccountId,
    if (toAccountId == null) 'counterparty': counterparty,
    'amount': amount.abs(),
    'date': date,
    'note': note,
    'isChecked': isChecked,
  };
}

class TxPage {
  const TxPage({
    required this.items,
    required this.total,
    required this.sumCredit,
    required this.sumDebit,
  });
  final List<Tx> items;
  final int total;
  final double sumCredit, sumDebit;

  factory TxPage.fromJson(Json j) => TxPage(
    items: [for (final t in j['items'] as List) Tx.fromJson(t as Json)],
    total: _i(j['total']),
    sumCredit: _d(j['sumCredit']),
    sumDebit: _d(j['sumDebit']),
  );
}

class TxFilter {
  const TxFilter({
    this.accountId,
    this.categoryId,
    this.paymentMethodId,
    this.type,
    this.isChecked,
    this.from,
    this.to,
    this.query,
    this.minAmount,
    this.maxAmount,
  });
  final String? accountId, categoryId, paymentMethodId, from, to, query;
  final TxType? type;
  final bool? isChecked;
  final double? minAmount, maxAmount;

  /// Nombre de critères actifs en plus du compte (pour le badge du bouton Filtres).
  int get activeCount => [
    categoryId,
    paymentMethodId,
    type,
    from,
    to,
    minAmount,
    maxAmount,
  ].where((v) => v != null).length;

  Map<String, dynamic> toQuery() => {
    if (accountId != null) 'accountId': accountId,
    if (categoryId != null) 'categoryId': categoryId,
    if (paymentMethodId != null) 'paymentMethodId': paymentMethodId,
    if (type != null) 'type': type!.wire,
    if (isChecked != null) 'isChecked': '$isChecked',
    if (from != null) 'from': from,
    if (to != null) 'to': to,
    if (query != null && query!.trim().isNotEmpty) 'q': query!.trim(),
    if (minAmount != null) 'minAmount': minAmount,
    if (maxAmount != null) 'maxAmount': maxAmount,
  };

  TxFilter copyWith({
    String? accountId,
    Object? categoryId = _keep,
    Object? paymentMethodId = _keep,
    Object? type = _keep,
    Object? isChecked = _keep,
    Object? from = _keep,
    Object? to = _keep,
    Object? query = _keep,
    Object? minAmount = _keep,
    Object? maxAmount = _keep,
  }) => TxFilter(
    accountId: accountId ?? this.accountId,
    categoryId: categoryId == _keep ? this.categoryId : categoryId as String?,
    paymentMethodId: paymentMethodId == _keep
        ? this.paymentMethodId
        : paymentMethodId as String?,
    type: type == _keep ? this.type : type as TxType?,
    isChecked: isChecked == _keep ? this.isChecked : isChecked as bool?,
    from: from == _keep ? this.from : from as String?,
    to: to == _keep ? this.to : to as String?,
    query: query == _keep ? this.query : query as String?,
    minAmount: minAmount == _keep ? this.minAmount : minAmount as double?,
    maxAmount: maxAmount == _keep ? this.maxAmount : maxAmount as double?,
  );

  @override
  bool operator ==(Object other) =>
      other is TxFilter &&
      other.accountId == accountId &&
      other.categoryId == categoryId &&
      other.paymentMethodId == paymentMethodId &&
      other.type == type &&
      other.isChecked == isChecked &&
      other.from == from &&
      other.to == to &&
      other.query == query &&
      other.minAmount == minAmount &&
      other.maxAmount == maxAmount;

  @override
  int get hashCode => Object.hash(
    accountId,
    categoryId,
    paymentMethodId,
    type,
    isChecked,
    from,
    to,
    query,
    minAmount,
    maxAmount,
  );
}

const _keep = Object();

class Suggestion {
  const Suggestion({
    required this.note,
    this.categoryId,
    this.paymentMethodId,
    required this.type,
    required this.amount,
  });
  final String note;
  final String? categoryId, paymentMethodId;
  final TxType type;
  final double amount;

  factory Suggestion.fromJson(Json j) => Suggestion(
    note: j['note'] as String,
    categoryId: j['categoryId'] as String?,
    paymentMethodId: j['paymentMethodId'] as String?,
    type: TxType.parse(j['type']),
    amount: _d(j['amount']),
  );
}

// ── Mensualités, budgets, notifications ──────────────────────────────────────

class Recurring {
  const Recurring({
    required this.id,
    required this.accountId,
    this.categoryId,
    this.paymentMethodId,
    required this.name,
    required this.amount,
    required this.isIncome,
    required this.dayOfMonth,
    required this.monthlyAmounts,
    required this.isActive,
    this.lastGeneratedPeriod,
  });

  final String id, accountId, name;
  final String? categoryId, paymentMethodId, lastGeneratedPeriod;
  final double amount;
  final bool isIncome, isActive;
  final int dayOfMonth;

  /// Exceptions par mois (clé 1 à 12). Une valeur 0 saute le mois.
  final Map<int, double> monthlyAmounts;

  double amountForMonth(int month) => monthlyAmounts[month] ?? amount;
  double get yearlyTotal => [
    for (var m = 1; m <= 12; m++) amountForMonth(m),
  ].fold(0, (a, b) => a + b);

  factory Recurring.fromJson(Json j) => Recurring(
    id: j['id'] as String,
    accountId: j['accountId'] as String,
    categoryId: j['categoryId'] as String?,
    paymentMethodId: j['paymentMethodId'] as String?,
    name: j['name'] as String,
    amount: _d(j['amount']),
    isIncome: j['type'] == 'income',
    dayOfMonth: _i(j['dayOfMonth'] ?? 1),
    monthlyAmounts: {
      for (final e in ((j['monthlyAmounts'] as Json?) ?? const {}).entries)
        int.parse(e.key): _d(e.value),
    },
    isActive: j['isActive'] as bool? ?? true,
    lastGeneratedPeriod: j['lastGeneratedPeriod'] as String?,
  );
}

class Occurrence {
  const Occurrence({
    required this.name,
    required this.date,
    required this.amount,
    required this.accountId,
  });
  final String name, date, accountId;

  /// Montant signé.
  final double amount;

  factory Occurrence.fromPending(Json j) => Occurrence(
    name: j['name'] as String,
    date: j['date'] as String,
    amount: j['type'] == 'income' ? _d(j['amount']) : -_d(j['amount']),
    accountId: j['accountId'] as String,
  );

  factory Occurrence.fromForecast(Json j) => Occurrence(
    name: j['name'] as String,
    date: j['date'] as String,
    amount: _d(j['amount']),
    accountId: j['accountId'] as String,
  );
}

class Budget {
  const Budget({
    required this.id,
    this.categoryId,
    required this.amount,
    required this.alertThreshold,
    required this.periodFrom,
    required this.periodTo,
    required this.spent,
    required this.remaining,
    required this.percent,
    required this.projected,
  });

  final String id;
  final String? categoryId;
  final double amount, spent, remaining, percent, projected;
  final int alertThreshold;
  final String periodFrom, periodTo;

  bool get isOver => spent > amount;
  bool get isNear => !isOver && percent >= alertThreshold;

  factory Budget.fromJson(Json j) => Budget(
    id: j['id'] as String,
    categoryId: j['categoryId'] as String?,
    amount: _d(j['amount']),
    alertThreshold: _i(j['alertThreshold'] ?? 80),
    periodFrom: j['periodFrom'] as String,
    periodTo: j['periodTo'] as String,
    spent: _d(j['spent']),
    remaining: _d(j['remaining']),
    percent: _d(j['percent']),
    projected: _d(j['projected']),
  );
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.read,
    required this.createdAt,
  });
  final String id, type, title, body;
  final bool read;
  final DateTime createdAt;

  factory AppNotification.fromJson(Json j) => AppNotification(
    id: j['id'] as String,
    type: j['type'] as String,
    title: j['title'] as String,
    body: j['body'] as String,
    read: j['read'] as bool? ?? false,
    createdAt: DateTime.parse(j['createdAt'] as String).toLocal(),
  );
}

// ── État de démarrage ────────────────────────────────────────────────────────

class Bootstrap {
  const Bootstrap({
    required this.user,
    required this.accounts,
    required this.categories,
    required this.paymentMethods,
    required this.chequebooks,
    required this.recurring,
    required this.budgets,
    required this.unreadNotifications,
    required this.pendingRecurring,
  });

  final AppUser user;
  final List<Account> accounts;
  final List<Category> categories;
  final List<PaymentMethod> paymentMethods;
  final List<Chequebook> chequebooks;
  final List<Recurring> recurring;
  final List<Budget> budgets;
  final int unreadNotifications, pendingRecurring;

  factory Bootstrap.fromJson(Json j) => Bootstrap(
    user: AppUser.fromJson(j['user'] as Json),
    accounts: [
      for (final a in j['accounts'] as List) Account.fromJson(a as Json),
    ],
    categories: [
      for (final c in j['categories'] as List) Category.fromJson(c as Json),
    ],
    paymentMethods: [
      for (final m in j['paymentMethods'] as List)
        PaymentMethod.fromJson(m as Json),
    ],
    chequebooks: [
      for (final b in j['chequebooks'] as List) Chequebook.fromJson(b as Json),
    ],
    recurring: [
      for (final r in j['recurringPayments'] as List)
        Recurring.fromJson(r as Json),
    ],
    budgets: [for (final b in j['budgets'] as List) Budget.fromJson(b as Json)],
    unreadNotifications: _i(j['unreadNotifications']),
    pendingRecurring: _i(j['pendingRecurring']),
  );

  Category? category(String? id) {
    if (id == null) return null;
    for (final c in categories) {
      if (c.id == id) return c;
    }
    return null;
  }

  Account? account(String? id) {
    if (id == null) return null;
    for (final a in accounts) {
      if (a.id == id) return a;
    }
    return null;
  }

  PaymentMethod? paymentMethod(String? id) {
    if (id == null) return null;
    for (final m in paymentMethods) {
      if (m.id == id) return m;
    }
    return null;
  }

  List<Category> get rootCategories =>
      categories.where((c) => c.parentId == null).toList();
  List<Category> childrenOf(String id) =>
      categories.where((c) => c.parentId == id).toList();
  List<Account> get activeAccounts =>
      accounts.where((a) => !a.archived).toList();

  /// « Restaurant · Fast-food » pour une sous-catégorie, « Restaurant » sinon.
  String categoryLabel(String? id) {
    final c = category(id);
    if (c == null) return 'Sans catégorie';
    final parent = category(c.parentId);
    return parent == null ? c.name : '${parent.name} · ${c.name}';
  }
}

// ── Statistiques ─────────────────────────────────────────────────────────────

class CategoryTotal {
  const CategoryTotal({
    this.categoryId,
    required this.name,
    this.colorValue,
    this.iconCode,
    required this.total,
    required this.count,
    required this.percent,
    required this.subs,
  });
  final String? categoryId, iconCode;
  final String name;
  final int? colorValue;
  final double total, percent;
  final int count;
  final List<({String name, double total})> subs;

  factory CategoryTotal.fromJson(Json j) => CategoryTotal(
    categoryId: j['categoryId'] as String?,
    name: j['name'] as String,
    colorValue: j['colorValue'] == null ? null : _i(j['colorValue']),
    iconCode: j['iconCode'] as String?,
    total: _d(j['total']),
    count: _i(j['count']),
    percent: _d(j['percent']),
    subs: [
      for (final s in (j['subcategories'] as List? ?? const []))
        (name: (s as Json)['name'] as String, total: _d(s['total'])),
    ],
  );
}

class Summary {
  const Summary({
    required this.income,
    required this.expense,
    required this.net,
    this.savingsRate,
    required this.count,
    required this.dailyExpense,
    required this.expenses,
    required this.incomes,
    required this.byMethod,
  });
  final double income, expense, net, dailyExpense;
  final double? savingsRate;
  final int count;
  final List<CategoryTotal> expenses, incomes;
  final List<({String name, double total})> byMethod;

  factory Summary.fromJson(Json j) => Summary(
    income: _d(j['income']),
    expense: _d(j['expense']),
    net: _d(j['net']),
    savingsRate: _dn(j['savingsRate']),
    count: _i(j['transactionCount']),
    dailyExpense: _d(j['averageDailyExpense']),
    expenses: [
      for (final c in j['expensesByCategory'] as List)
        CategoryTotal.fromJson(c as Json),
    ],
    incomes: [
      for (final c in j['incomeByCategory'] as List)
        CategoryTotal.fromJson(c as Json),
    ],
    byMethod: [
      for (final m in j['expensesByPaymentMethod'] as List)
        (name: (m as Json)['name'] as String, total: _d(m['total'])),
    ],
  );
}

class MonthTotal {
  const MonthTotal({
    required this.period,
    required this.income,
    required this.expense,
  });
  final String period;
  final double income, expense;
  factory MonthTotal.fromJson(Json j) => MonthTotal(
    period: j['period'] as String,
    income: _d(j['income']),
    expense: _d(j['expense']),
  );
}

class BalancePoint {
  const BalancePoint(this.date, this.balance);
  final String date;
  final double balance;
  factory BalancePoint.fromJson(Json j) =>
      BalancePoint(j['date'] as String, _d(j['balance']));
}

class Forecast {
  const Forecast({
    required this.current,
    required this.projected,
    required this.lowest,
    required this.points,
    required this.upcoming,
  });
  final double current, projected;
  final BalancePoint lowest;
  final List<BalancePoint> points;
  final List<Occurrence> upcoming;

  factory Forecast.fromJson(Json j) => Forecast(
    current: _d(j['currentBalance']),
    projected: _d(j['projectedBalance']),
    lowest: BalancePoint.fromJson(j['lowest'] as Json),
    points: [
      for (final p in j['points'] as List) BalancePoint.fromJson(p as Json),
    ],
    upcoming: [
      for (final o in j['upcoming'] as List) Occurrence.fromForecast(o as Json),
    ],
  );
}

class PivotCell {
  const PivotCell({
    required this.name,
    required this.debit,
    required this.credit,
    this.children = const [],
  });
  final String name;
  final double debit, credit;
  final List<PivotCell> children;

  factory PivotCell.fromJson(
    Json j, {
    String nameKey = 'name',
    String childrenKey = 'subcategories',
  }) => PivotCell(
    name: j[nameKey] as String,
    debit: _d(j['debit']),
    credit: _d(j['credit']),
    children: [
      for (final c in (j[childrenKey] as List? ?? const []))
        PivotCell.fromJson(c as Json),
    ],
  );
}

class Pivot {
  const Pivot({required this.rows, required this.debit, required this.credit});
  final List<PivotCell> rows;
  final double debit, credit;

  factory Pivot.fromJson(Json j) => Pivot(
    rows: [
      for (final r in j['rows'] as List)
        PivotCell.fromJson(
          r as Json,
          nameKey: 'key',
          childrenKey: 'categories',
        ),
    ],
    debit: _d((j['totals'] as Json)['debit']),
    credit: _d((j['totals'] as Json)['credit']),
  );
}

class ImportReport {
  const ImportReport({
    required this.accounts,
    required this.categories,
    required this.recurring,
    required this.transactions,
    required this.warnings,
  });
  final int accounts, categories, recurring, transactions;
  final List<String> warnings;

  factory ImportReport.fromJson(Json j) => ImportReport(
    accounts: _i(j['accounts']),
    categories: _i(j['categories']),
    recurring: _i(j['recurringPayments']),
    transactions: _i(j['transactions']),
    warnings: [
      for (final w in (j['warnings'] as List? ?? const [])) w as String,
    ],
  );
}
