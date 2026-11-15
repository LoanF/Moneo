import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/format.dart';
import '../../data/models.dart';
import '../../state/providers.dart';
import '../editor/tx_editor.dart';
import '../theme/theme.dart';
import '../widgets/common.dart';
import 'tx_tile.dart';

/// Recherche et filtres combinables sur toutes les opérations (l'équivalent des filtres
/// de colonnes du classeur), avec le total des débits et crédits du résultat.
class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key, this.accountId});
  final String? accountId;

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  late TxFilter _filter = TxFilter(accountId: widget.accountId);
  final _query = TextEditingController();
  final _scroll = ScrollController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.extentAfter < 600) {
        ref.read(txListProvider(_filter).notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _onQuery(String value) {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 300),
      () => setState(
        () => _filter = _filter.copyWith(
          query: value.trim().isEmpty ? null : value.trim(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(appDataProvider).value;
    if (data == null) return const Scaffold();
    final list = ref.watch(txListProvider(_filter));
    final c = context.moneo;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          controller: _query,
          autofocus: true,
          onChanged: _onQuery,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'Libellé, montant, n° de chèque',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: _query.text.isEmpty
                ? null
                : IconButton(
                    onPressed: () {
                      _query.clear();
                      _onQuery('');
                    },
                    icon: const Icon(Icons.close_rounded),
                    tooltip: 'Effacer la recherche',
                  ),
          ),
        ),
        actions: [
          IconButton(
            onPressed: () async {
              final next = await showSheet<TxFilter>(
                context,
                _FilterSheet(filter: _filter),
                expand: true,
              );
              if (next != null) setState(() => _filter = next);
            },
            icon: Badge(
              isLabelVisible: _filter.activeCount > 0,
              label: Text('${_filter.activeCount}'),
              child: const Icon(Icons.tune_rounded),
            ),
            tooltip: _filter.activeCount > 0
                ? 'Filtres, ${_filter.activeCount} actifs'
                : 'Filtres',
          ),
          const SizedBox(width: Gap.sm),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 56,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: Gap.page,
                vertical: Gap.sm,
              ),
              children: [
                _chip(
                  'Tous les comptes',
                  _filter.accountId == null,
                  () => setState(
                    () => _filter = TxFilter(
                      categoryId: _filter.categoryId,
                      paymentMethodId: _filter.paymentMethodId,
                      type: _filter.type,
                      isChecked: _filter.isChecked,
                      from: _filter.from,
                      to: _filter.to,
                      query: _filter.query,
                      minAmount: _filter.minAmount,
                      maxAmount: _filter.maxAmount,
                    ),
                  ),
                ),
                for (final a in data.activeAccounts)
                  _chip(
                    a.name,
                    _filter.accountId == a.id,
                    () => setState(
                      () => _filter = _filter.copyWith(accountId: a.id),
                    ),
                  ),
                _chip(
                  'À pointer',
                  _filter.isChecked == false,
                  () => setState(
                    () => _filter = _filter.copyWith(
                      isChecked: _filter.isChecked == false ? null : false,
                    ),
                  ),
                ),
                _chip(
                  'Pointées',
                  _filter.isChecked == true,
                  () => setState(
                    () => _filter = _filter.copyWith(
                      isChecked: _filter.isChecked == true ? null : true,
                    ),
                  ),
                ),
              ],
            ),
          ),
          list.maybeWhen(
            skipLoadingOnReload: true,
            data: (state) => Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Gap.page,
                vertical: Gap.sm,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${state.total} opération${state.total > 1 ? 's' : ''}',
                      style: context.text.titleSmall,
                    ),
                  ),
                  if (!state.fromCache) ...[
                    Text(
                      'Débit ',
                      style: context.text.bodySmall?.copyWith(color: c.inkSoft),
                    ),
                    Amount(state.sumDebit, style: context.text.titleSmall),
                    const SizedBox(width: Gap.md),
                    Text(
                      'Crédit ',
                      style: context.text.bodySmall?.copyWith(color: c.inkSoft),
                    ),
                    Amount(
                      state.sumCredit,
                      style: context.text.titleSmall?.copyWith(color: c.income),
                    ),
                  ],
                ],
              ),
            ),
            orElse: () => const SizedBox(height: 36),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: Gap.page),
            child: Perforation(),
          ),
          Expanded(
            child: list.when(
              skipLoadingOnReload: true,
              loading: () =>
                  const SingleChildScrollView(child: SkeletonList(rows: 8)),
              error: (error, _) => Center(
                child: ErrorState(
                  error: error,
                  onRetry: () => ref.invalidate(txListProvider(_filter)),
                ),
              ),
              data: (state) => state.items.isEmpty
                  ? const Center(
                      child: EmptyState(
                        icon: Icons.search_off_rounded,
                        title: 'Aucun résultat',
                        message:
                            'Aucune opération ne correspond. Essayez un autre mot ou retirez un filtre.',
                      ),
                    )
                  : ListView.builder(
                      controller: _scroll,
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      itemCount:
                          state.items.length + (state.loadingMore ? 1 : 0),
                      itemBuilder: (_, i) => i >= state.items.length
                          ? const Padding(
                              padding: EdgeInsets.all(Gap.xl),
                              child: Center(child: CircularProgressIndicator()),
                            )
                          : TxTile(
                              tx: state.items[i],
                              filter: _filter,
                              showDate: true,
                              showAccount: _filter.accountId == null,
                            ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) => Padding(
    padding: const EdgeInsets.only(right: Gap.sm),
    child: ChoicePill(label: label, selected: selected, onTap: () => onTap()),
  );
}

class _FilterSheet extends ConsumerStatefulWidget {
  const _FilterSheet({required this.filter});
  final TxFilter filter;

  @override
  ConsumerState<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends ConsumerState<_FilterSheet> {
  late TxFilter _f = widget.filter;
  late final _min = TextEditingController(
    text: _f.minAmount == null ? '' : Fmt.plain(_f.minAmount!),
  );
  late final _max = TextEditingController(
    text: _f.maxAmount == null ? '' : Fmt.plain(_f.maxAmount!),
  );

  @override
  void dispose() {
    _min.dispose();
    _max.dispose();
    super.dispose();
  }

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: now.add(const Duration(days: 730)),
      initialDateRange: _f.from != null && _f.to != null
          ? DateTimeRange(start: Fmt.parse(_f.from!), end: Fmt.parse(_f.to!))
          : null,
      helpText: 'Période',
      saveText: 'Valider',
    );
    if (range != null) {
      setState(
        () => _f = _f.copyWith(
          from: Fmt.iso(range.start),
          to: Fmt.iso(range.end),
        ),
      );
    }
  }

  void _preset(DateTime from, DateTime to) =>
      setState(() => _f = _f.copyWith(from: Fmt.iso(from), to: Fmt.iso(to)));

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(appDataProvider).value!;
    final now = DateTime.now();
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
          'Filtres',
          action: TextButton(
            onPressed: () => setState(() {
              _f = TxFilter(
                accountId: _f.accountId,
                isChecked: _f.isChecked,
                query: _f.query,
              );
              _min.clear();
              _max.clear();
            }),
            child: const Text('Réinitialiser'),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(Gap.page, 0, Gap.page, Gap.xl),
            children: [
              label('Type'),
              Wrap(
                spacing: Gap.sm,
                children: [
                  for (final t in TxType.values)
                    ChoicePill(
                      label: t.label,
                      selected: _f.type == t,
                      onTap: () => setState(
                        () => _f = _f.copyWith(type: _f.type == t ? null : t),
                      ),
                    ),
                ],
              ),
              label('Période'),
              Wrap(
                spacing: Gap.sm,
                runSpacing: Gap.sm,
                children: [
                  ChoicePill(
                    label: 'Ce mois',
                    selected: false,
                    onTap: () => _preset(
                      DateTime(now.year, now.month),
                      DateTime(now.year, now.month + 1, 0),
                    ),
                  ),
                  ChoicePill(
                    label: 'Mois dernier',
                    selected: false,
                    onTap: () => _preset(
                      DateTime(now.year, now.month - 1),
                      DateTime(now.year, now.month, 0),
                    ),
                  ),
                  ChoicePill(
                    label: 'Cette année',
                    selected: false,
                    onTap: () =>
                        _preset(DateTime(now.year), DateTime(now.year, 12, 31)),
                  ),
                  InputChip(
                    avatar: const Icon(Icons.date_range_rounded, size: 18),
                    label: Text(
                      _f.from == null
                          ? 'Choisir des dates'
                          : '${Fmt.shortDate(_f.from!)} → ${Fmt.shortDate(_f.to ?? _f.from!)}',
                    ),
                    onPressed: _pickRange,
                    onDeleted: _f.from == null
                        ? null
                        : () => setState(
                            () => _f = _f.copyWith(from: null, to: null),
                          ),
                    deleteButtonTooltipMessage: 'Retirer la période',
                  ),
                ],
              ),
              label('Catégorie'),
              OutlinedButton.icon(
                onPressed: () async {
                  final picked = await showSheet<String>(
                    context,
                    CategoryPicker(selected: _f.categoryId),
                    expand: true,
                  );
                  if (picked != null) {
                    setState(
                      () => _f = _f.copyWith(
                        categoryId: picked.isEmpty ? null : picked,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.category_rounded),
                label: Text(
                  _f.categoryId == null
                      ? 'Toutes les catégories'
                      : data.categoryLabel(_f.categoryId),
                ),
              ),
              label('Moyen de paiement'),
              Wrap(
                spacing: Gap.sm,
                runSpacing: Gap.sm,
                children: [
                  for (final m in data.paymentMethods)
                    ChoicePill(
                      label: m.name,
                      selected: _f.paymentMethodId == m.id,
                      onTap: () => setState(
                        () => _f = _f.copyWith(
                          paymentMethodId: _f.paymentMethodId == m.id
                              ? null
                              : m.id,
                        ),
                      ),
                    ),
                ],
              ),
              label('Montant'),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _min,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Minimum',
                        suffixText: '€',
                      ),
                    ),
                  ),
                  const SizedBox(width: Gap.md),
                  Expanded(
                    child: TextField(
                      controller: _max,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Maximum',
                        suffixText: '€',
                      ),
                    ),
                  ),
                ],
              ),
            ],
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
              label: 'Afficher les résultats',
              onPressed: () => Navigator.pop(
                context,
                _f.copyWith(
                  minAmount: Fmt.parseAmount(_min.text)?.abs(),
                  maxAmount: Fmt.parseAmount(_max.text)?.abs(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
