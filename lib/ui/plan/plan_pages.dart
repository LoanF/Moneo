import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/format.dart';
import '../../data/models.dart';
import '../../state/providers.dart';
import '../editor/tx_editor.dart';
import '../theme/theme.dart';
import '../widgets/common.dart';

// ── Mensualités ──────────────────────────────────────────────────────────────

/// Les opérations qui reviennent chaque mois (la feuille « Mensualisation » du classeur).
class RecurringPage extends ConsumerWidget {
  const RecurringPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(appDataProvider);
    final c = context.moneo;

    return Scaffold(
      appBar: AppBar(title: const Text('Mensualités')),
      floatingActionButton: AddButton(
        label: 'Mensualité',
        icon: Icons.add_rounded,
        onPressed: () =>
            showSheet<void>(context, const RecurringEditor(), expand: true),
      ),
      body: data.when(
        skipLoadingOnReload: true,
        skipLoadingOnRefresh: true,
        loading: () => const SkeletonList(),
        error: (error, _) => Center(
          child: ErrorState(
            error: error,
            onRetry: () => ref.invalidate(appDataProvider),
          ),
        ),
        data: (bootstrap) {
          final items = [...bootstrap.recurring]
            ..sort((a, b) => a.dayOfMonth.compareTo(b.dayOfMonth));
          if (items.isEmpty) {
            return Center(
              child: EmptyState(
                icon: Icons.event_repeat_rounded,
                title: 'Aucune mensualité',
                message:
                    'Loyer, abonnements, salaire : déclarez-les une fois, Moneo les ajoute chaque mois.',
                actionLabel: 'Ajouter une mensualité',
                onAction: () => showSheet<void>(
                  context,
                  const RecurringEditor(),
                  expand: true,
                ),
              ),
            );
          }
          final month = DateTime.now().month;
          final active = items.where((r) => r.isActive);
          final out = active
              .where((r) => !r.isIncome)
              .fold<double>(0, (s, r) => s + r.amountForMonth(month));
          final income = active
              .where((r) => r.isIncome)
              .fold<double>(0, (s, r) => s + r.amountForMonth(month));
          final pending =
              ref.watch(pendingRecurringProvider).value ?? const <Occurrence>[];

          return RefreshIndicator(
            onRefresh: () => ref.read(appDataProvider.notifier).refresh(),
            child: ListView(
              padding: const EdgeInsets.only(bottom: Gap.dock),
              children: [
                const OfflineBanner(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    Gap.page,
                    Gap.md,
                    Gap.page,
                    0,
                  ),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(Gap.lg),
                      child: IntrinsicHeight(
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Charges de ${Fmt.monthNames[month - 1].toLowerCase()}',
                                    style: context.text.labelMedium?.copyWith(
                                      color: c.inkSoft,
                                    ),
                                  ),
                                  Amount(out, style: context.text.titleLarge),
                                ],
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: Gap.md),
                              child: Perforation(axis: Axis.vertical),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Revenus fixes',
                                    style: context.text.labelMedium?.copyWith(
                                      color: c.inkSoft,
                                    ),
                                  ),
                                  Amount(
                                    income,
                                    style: context.text.titleLarge?.copyWith(
                                      color: c.income,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                if (pending.isNotEmpty) _PendingCard(pending: pending),
                const SectionHeader('Chaque mois'),
                GroupCard(
                  children: [
                    for (final r in items)
                      _RecurringTile(item: r, data: bootstrap, month: month),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Échéances pas encore passées en écriture, avec le bouton qui les ajoute d'un coup.
class _PendingCard extends ConsumerStatefulWidget {
  const _PendingCard({required this.pending});
  final List<Occurrence> pending;

  @override
  ConsumerState<_PendingCard> createState() => _PendingCardState();
}

class _PendingCardState extends ConsumerState<_PendingCard> {
  bool _busy = false;

  Future<void> _run() async {
    setState(() => _busy = true);
    try {
      final created = await ref
          .read(appDataProvider.notifier)
          .mutate((api) => api.runRecurring());
      if (mounted) {
        showMessage(
          context,
          created == 0
              ? 'Rien à ajouter'
              : '$created opération${created > 1 ? 's' : ''} ajoutée${created > 1 ? 's' : ''}',
        );
      }
    } catch (error) {
      if (mounted) showError(context, error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.pending.fold<double>(0, (s, o) => s + o.amount);
    final count = widget.pending.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Gap.page, Gap.md, Gap.page, 0),
      child: Card(
        color: context.moneo.highlight,
        child: Padding(
          padding: const EdgeInsets.all(Gap.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$count opération${count > 1 ? 's' : ''} à mettre en place',
                style: context.text.titleMedium,
              ),
              const SizedBox(height: Gap.xs),
              Text(
                'Total ${Fmt.signed(total)}. Elles seront ajoutées à leur date, non pointées.',
                style: context.text.bodyMedium,
              ),
              const SizedBox(height: Gap.md),
              SubmitButton(
                label: 'Ajouter les opérations du mois',
                icon: Icons.playlist_add_check_rounded,
                busy: _busy,
                onPressed: _run,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecurringTile extends StatelessWidget {
  const _RecurringTile({
    required this.item,
    required this.data,
    required this.month,
  });
  final Recurring item;
  final Bootstrap data;
  final int month;

  @override
  Widget build(BuildContext context) {
    final c = context.moneo;
    final category = data.category(item.categoryId);
    final root = data.category(category?.parentId) ?? category;
    final amount = item.amountForMonth(month);
    final varies = item.monthlyAmounts.isNotEmpty;
    final details = [
      'Le ${item.dayOfMonth}',
      if (data.accounts.length > 1) data.account(item.accountId)?.name,
      data.paymentMethod(item.paymentMethodId)?.name,
      if (varies) 'montant variable',
      if (!item.isActive) 'en pause',
    ].whereType<String>().join(' · ');

    return Opacity(
      opacity: item.isActive ? 1 : 0.55,
      child: GroupTile(
        leading: CategoryBadge(
          icon: categoryIcon(root?.iconCode ?? 'category'),
          color: root == null ? c.perforation : Color(root.colorValue),
        ),
        title: item.name,
        subtitle: details,
        trailing: amount == 0
            ? Text(
                'Pas ce mois-ci',
                style: context.text.bodySmall?.copyWith(color: c.inkSoft),
              )
            : Amount(
                item.isIncome ? amount : -amount,
                signed: true,
                colored: true,
                style: context.text.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
        onTap: () => showSheet<void>(
          context,
          RecurringEditor(existing: item),
          expand: true,
        ),
      ),
    );
  }
}

/// Création et modification d'une mensualité, avec un montant différent par mois si besoin.
class RecurringEditor extends ConsumerStatefulWidget {
  const RecurringEditor({super.key, this.existing});
  final Recurring? existing;

  @override
  ConsumerState<RecurringEditor> createState() => _RecurringEditorState();
}

class _RecurringEditorState extends ConsumerState<RecurringEditor> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.existing?.name ?? '');
  late final _amount = TextEditingController(
    text: widget.existing == null ? '' : _plain(widget.existing!.amount),
  );
  late final _day = TextEditingController(
    text: '${widget.existing?.dayOfMonth ?? DateTime.now().day}',
  );
  late final List<TextEditingController> _months;
  late bool _income = widget.existing?.isIncome ?? false;
  late bool _active = widget.existing?.isActive ?? true;
  late bool _perMonth = widget.existing?.monthlyAmounts.isNotEmpty ?? false;
  late String _accountId;
  late String? _categoryId = widget.existing?.categoryId;
  late String? _methodId = widget.existing?.paymentMethodId;
  bool _busy = false;

  static String _plain(double v) =>
      Fmt.plain(v).replaceAll(RegExp(r'[\s  ]'), '');

  @override
  void initState() {
    super.initState();
    final data = ref.read(appDataProvider).value!;
    _accountId =
        widget.existing?.accountId ??
        ref.read(currentAccountProvider)?.id ??
        data.activeAccounts.first.id;
    _months = [
      for (var m = 1; m <= 12; m++)
        TextEditingController(
          text: widget.existing?.monthlyAmounts[m] == null
              ? ''
              : _plain(widget.existing!.monthlyAmounts[m]!),
        ),
    ];
  }

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    _day.dispose();
    for (final m in _months) {
      m.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final overrides = <String, double>{};
    if (_perMonth) {
      for (var m = 0; m < 12; m++) {
        final value = Fmt.parseAmount(_months[m].text);
        if (value != null) overrides['${m + 1}'] = value.abs();
      }
    }
    setState(() => _busy = true);
    final ok = await guard(
      context,
      () => ref
          .read(appDataProvider.notifier)
          .mutate(
            (api) => api.saveRecurring(widget.existing?.id, {
              'name': _name.text.trim(),
              'amount': Fmt.parseAmount(_amount.text)!.abs(),
              'type': _income ? 'income' : 'expense',
              'dayOfMonth': int.parse(_day.text),
              'accountId': _accountId,
              'categoryId': _categoryId,
              'paymentMethodId': _methodId,
              'monthlyAmounts': overrides,
              'isActive': _active,
            }),
          ),
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) Navigator.pop(context);
  }

  Future<void> _delete() async {
    final sure = await confirm(
      context,
      title: 'Supprimer cette mensualité ?',
      message:
          'Elle ne sera plus ajoutée chaque mois. Les opérations déjà créées sont conservées.',
      confirmLabel: 'Supprimer',
    );
    if (!sure || !mounted) return;
    final ok = await guard(
      context,
      () => ref
          .read(appDataProvider.notifier)
          .mutate((api) => api.deleteRecurring(widget.existing!.id)),
    );
    if (ok && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(appDataProvider).value;
    if (data == null) return const SizedBox.shrink();
    Widget label(String text) => Padding(
      padding: const EdgeInsets.only(top: Gap.lg, bottom: Gap.sm),
      child: Text(
        text,
        style: context.text.labelLarge?.copyWith(color: context.moneo.inkSoft),
      ),
    );

    return Column(
      children: [
        SheetHeader(
          widget.existing == null
              ? 'Nouvelle mensualité'
              : 'Modifier la mensualité',
          action: widget.existing == null
              ? null
              : IconButton(
                  onPressed: _delete,
                  icon: const Icon(Icons.delete_rounded),
                  tooltip: 'Supprimer la mensualité',
                ),
        ),
        Expanded(
          child: Form(
            key: _form,
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(Gap.page, 0, Gap.page, Gap.xl),
              children: [
                PillTabs<bool>(
                  value: _income,
                  items: [
                    (value: false, label: 'Dépense'),
                    (value: true, label: 'Revenu'),
                  ],
                  onChanged: (v) => setState(() => _income = v),
                ),
                const SizedBox(height: Gap.lg),
                TextFormField(
                  controller: _name,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.next,
                  validator: (v) => (v?.trim().isEmpty ?? true)
                      ? 'Donnez un nom à cette mensualité'
                      : null,
                  decoration: const InputDecoration(
                    labelText: 'Nom',
                    hintText: 'Loyer, Internet, Salaire…',
                  ),
                ),
                const SizedBox(height: Gap.md),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        controller: _amount,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        textInputAction: TextInputAction.next,
                        validator: (v) => (Fmt.parseAmount(v ?? '') ?? -1) >= 0
                            ? null
                            : 'Montant invalide',
                        decoration: InputDecoration(
                          labelText: _perMonth ? 'Montant habituel' : 'Montant',
                          suffixText: '€',
                        ),
                      ),
                    ),
                    const SizedBox(width: Gap.md),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _day,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(2),
                        ],
                        validator: (v) {
                          final day = int.tryParse(v ?? '');
                          return day != null && day >= 1 && day <= 31
                              ? null
                              : 'De 1 à 31';
                        },
                        decoration: const InputDecoration(
                          labelText: 'Jour du mois',
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(top: Gap.sm),
                  child: Text(
                    'Si le mois est plus court (le 31 en avril), l’opération passe le dernier jour du mois.',
                    style: context.text.bodySmall?.copyWith(
                      color: context.moneo.inkSoft,
                    ),
                  ),
                ),
                if (data.activeAccounts.length > 1) ...[
                  label('Compte'),
                  Wrap(
                    spacing: Gap.sm,
                    runSpacing: Gap.sm,
                    children: [
                      for (final a in data.activeAccounts)
                        ChoicePill(
                          label: a.name,
                          selected: a.id == _accountId,
                          onTap: () => setState(() => _accountId = a.id),
                        ),
                    ],
                  ),
                ],
                label('Catégorie'),
                OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showSheet<String>(
                      context,
                      CategoryPicker(selected: _categoryId),
                      expand: true,
                    );
                    if (picked != null) {
                      setState(
                        () => _categoryId = picked.isEmpty ? null : picked,
                      );
                    }
                  },
                  icon: const Icon(Icons.category_rounded),
                  label: Text(
                    _categoryId == null
                        ? 'Choisir une catégorie'
                        : data.categoryLabel(_categoryId),
                  ),
                ),
                if (data.paymentMethods.isNotEmpty) ...[
                  label('Moyen de paiement'),
                  Wrap(
                    spacing: Gap.sm,
                    runSpacing: Gap.sm,
                    children: [
                      for (final m in data.paymentMethods)
                        ChoicePill(
                          label: m.name,
                          selected: m.id == _methodId,
                          onTap: () => setState(
                            () => _methodId = _methodId == m.id ? null : m.id,
                          ),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: Gap.md),
                SwitchTile(
                  title: 'Montant différent selon le mois',
                  subtitle:
                      'Pour une échéance annuelle ajustée, ou un mois sans prélèvement.',
                  value: _perMonth,
                  onChanged: (v) => setState(() => _perMonth = v),
                ),
                if (_perMonth) ...[
                  Text(
                    'Laissez vide pour le montant habituel, saisissez 0 pour sauter un mois.',
                    style: context.text.bodySmall?.copyWith(
                      color: context.moneo.inkSoft,
                    ),
                  ),
                  const SizedBox(height: Gap.md),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: Gap.md,
                    crossAxisSpacing: Gap.md,
                    childAspectRatio: 2.9,
                    children: [
                      for (var m = 0; m < 12; m++)
                        TextField(
                          controller: _months[m],
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            labelText: Fmt.monthNames[m],
                            hintText: _amount.text,
                            suffixText: '€',
                          ),
                        ),
                    ],
                  ),
                ],
                SwitchTile(
                  title: 'Active',
                  subtitle: 'Désactivez pour mettre en pause sans supprimer.',
                  value: _active,
                  onChanged: (v) => setState(() => _active = v),
                ),
              ],
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              Gap.page,
              Gap.sm,
              Gap.page,
              Gap.md,
            ),
            child: SubmitButton(
              label: 'Enregistrer',
              icon: Icons.check_rounded,
              busy: _busy,
              onPressed: _save,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Budgets ──────────────────────────────────────────────────────────────────

class BudgetsPage extends ConsumerWidget {
  const BudgetsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(appDataProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Budgets')),
      floatingActionButton: AddButton(
        label: 'Budget',
        icon: Icons.add_rounded,
        onPressed: () => showSheet<void>(context, const BudgetEditor()),
      ),
      body: data.when(
        skipLoadingOnReload: true,
        skipLoadingOnRefresh: true,
        loading: () => const SkeletonList(),
        error: (error, _) => Center(
          child: ErrorState(
            error: error,
            onRetry: () => ref.invalidate(appDataProvider),
          ),
        ),
        data: (bootstrap) {
          if (bootstrap.budgets.isEmpty) {
            return Center(
              child: EmptyState(
                icon: Icons.savings_rounded,
                title: 'Aucun budget',
                message:
                    'Fixez un plafond mensuel pour une catégorie : Moneo vous prévient avant de le dépasser.',
                actionLabel: 'Créer un budget',
                onAction: () => showSheet<void>(context, const BudgetEditor()),
              ),
            );
          }
          final first = bootstrap.budgets.first;
          return RefreshIndicator(
            onRefresh: () => ref.read(appDataProvider.notifier).refresh(),
            child: ListView(
              padding: const EdgeInsets.only(bottom: Gap.dock),
              children: [
                const OfflineBanner(),
                SectionHeader(
                  'Du ${Fmt.shortDate(first.periodFrom)} au ${Fmt.shortDate(first.periodTo)}',
                ),
                for (final budget in bootstrap.budgets)
                  _BudgetTile(budget: budget, data: bootstrap),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _BudgetTile extends StatelessWidget {
  const _BudgetTile({required this.budget, required this.data});
  final Budget budget;
  final Bootstrap data;

  @override
  Widget build(BuildContext context) {
    final c = context.moneo;
    final category = data.category(budget.categoryId);
    final color = budget.isOver
        ? c.expense
        : (budget.isNear ? c.warning : c.income);
    // L'état est toujours écrit en toutes lettres : la couleur ne fait que le renforcer.
    final status = budget.isOver
        ? 'Dépassé de ${Fmt.money(-budget.remaining)}'
        : budget.isNear
        ? 'Bientôt atteint'
        : 'Dans les clous';
    final willExceed = !budget.isOver && budget.projected > budget.amount;

    return Padding(
      padding: const EdgeInsets.fromLTRB(Gap.lg, 0, Gap.lg, Gap.md),
      child: Pressable(
        onTap: () => showSheet<void>(context, BudgetEditor(existing: budget)),
        scale: 0.985,
        child: MCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  RingProgress(
                    value: budget.percent / 100,
                    color: color,
                    size: 64,
                    stroke: 7,
                    child: Text(
                      '${budget.percent.round()}%',
                      style: context.text.labelMedium?.copyWith(
                        fontFeatures: tabular,
                      ),
                    ),
                  ),
                  const SizedBox(width: Gap.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              category == null
                                  ? Icons.all_inclusive_rounded
                                  : categoryIcon(category.iconCode),
                              size: 18,
                              color: category == null
                                  ? c.inkSoft
                                  : Color(category.colorValue),
                            ),
                            const SizedBox(width: Gap.sm),
                            Expanded(
                              child: Text(
                                category?.name ?? 'Toutes les dépenses',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: context.text.titleMedium,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: Gap.xs),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Amount(
                                budget.spent,
                                style: context.text.headlineSmall,
                              ),
                              Text(
                                '  sur ${Fmt.money(budget.amount)}',
                                style: context.text.bodyMedium?.copyWith(
                                  color: c.inkSoft,
                                  fontFeatures: tabular,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Gap.lg),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: color.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          budget.isOver
                              ? Icons.error_rounded
                              : (budget.isNear
                                    ? Icons.warning_rounded
                                    : Icons.check_circle_rounded),
                          size: 15,
                          color: color,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          status,
                          style: context.text.labelMedium?.copyWith(
                            color: c.ink,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: Gap.sm),
                  Expanded(
                    child: Text(
                      budget.isOver
                          ? ''
                          : willExceed
                          ? 'À ce rythme : ${Fmt.money(budget.projected)}'
                          : 'Reste ${Fmt.money(budget.remaining)}',
                      textAlign: TextAlign.end,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.bodySmall?.copyWith(
                        color: c.inkSoft,
                        fontFeatures: tabular,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BudgetEditor extends ConsumerStatefulWidget {
  const BudgetEditor({super.key, this.existing});
  final Budget? existing;

  @override
  ConsumerState<BudgetEditor> createState() => _BudgetEditorState();
}

class _BudgetEditorState extends ConsumerState<BudgetEditor> {
  final _form = GlobalKey<FormState>();
  late final _amount = TextEditingController(
    text: widget.existing == null
        ? ''
        : Fmt.plain(widget.existing!.amount).replaceAll(RegExp(r'[\s  ]'), ''),
  );
  late String? _categoryId = widget.existing?.categoryId;
  late double _threshold = (widget.existing?.alertThreshold ?? 80).toDouble();
  bool _busy = false;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    final ok = await guard(
      context,
      () => ref
          .read(appDataProvider.notifier)
          .mutate(
            (api) => api.saveBudget(widget.existing?.id, {
              'amount': Fmt.parseAmount(_amount.text)!.abs(),
              'alertThreshold': _threshold.round(),
              if (widget.existing == null) 'categoryId': _categoryId,
            }),
          ),
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) Navigator.pop(context);
  }

  Future<void> _delete() async {
    final sure = await confirm(
      context,
      title: 'Supprimer ce budget ?',
      message: 'Vos opérations ne sont pas touchées.',
      confirmLabel: 'Supprimer',
    );
    if (!sure || !mounted) return;
    final ok = await guard(
      context,
      () => ref
          .read(appDataProvider.notifier)
          .mutate((api) => api.deleteBudget(widget.existing!.id)),
    );
    if (ok && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(appDataProvider).value;
    if (data == null) return const SizedBox.shrink();
    return SafeArea(
      child: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SheetHeader(
              widget.existing == null ? 'Nouveau budget' : 'Modifier le budget',
              action: widget.existing == null
                  ? null
                  : IconButton(
                      onPressed: _delete,
                      icon: const Icon(Icons.delete_rounded),
                      tooltip: 'Supprimer le budget',
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(Gap.page, 0, Gap.page, Gap.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (widget.existing == null)
                    OutlinedButton.icon(
                      onPressed: () async {
                        final picked = await showSheet<String>(
                          context,
                          CategoryPicker(
                            selected: _categoryId,
                            rootsOnly: true,
                          ),
                          expand: true,
                        );
                        if (picked != null) {
                          setState(
                            () => _categoryId = picked.isEmpty ? null : picked,
                          );
                        }
                      },
                      icon: const Icon(Icons.category_rounded),
                      label: Text(
                        _categoryId == null
                            ? 'Toutes les dépenses (budget global)'
                            : data.categoryLabel(_categoryId),
                      ),
                    )
                  else
                    Text(
                      data.category(_categoryId)?.name ?? 'Toutes les dépenses',
                      style: context.text.titleMedium,
                    ),
                  const SizedBox(height: Gap.lg),
                  TextFormField(
                    controller: _amount,
                    autofocus: widget.existing == null,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (v) => (Fmt.parseAmount(v ?? '') ?? 0) > 0
                        ? null
                        : 'Saisissez un plafond supérieur à zéro',
                    decoration: const InputDecoration(
                      labelText: 'Plafond par mois',
                      suffixText: '€',
                    ),
                  ),
                  const SizedBox(height: Gap.lg),
                  Text(
                    'M’alerter à ${_threshold.round()} % du plafond',
                    style: context.text.bodyMedium,
                  ),
                  Slider(
                    value: _threshold,
                    min: 50,
                    max: 100,
                    divisions: 10,
                    label: '${_threshold.round()} %',
                    onChanged: (v) => setState(() => _threshold = v),
                  ),
                  const SizedBox(height: Gap.sm),
                  SubmitButton(
                    label: 'Enregistrer',
                    icon: Icons.check_rounded,
                    busy: _busy,
                    onPressed: _save,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
