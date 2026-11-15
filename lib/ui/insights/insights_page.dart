import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/format.dart';
import '../../data/models.dart';
import '../../state/providers.dart';
import '../theme/theme.dart';
import '../widgets/common.dart';

/// Analyses : le mois en chiffres, la répartition des dépenses, la tendance et la prévision.
class InsightsPage extends ConsumerStatefulWidget {
  const InsightsPage({super.key});

  @override
  ConsumerState<InsightsPage> createState() => _InsightsPageState();
}

class _InsightsPageState extends ConsumerState<InsightsPage> {
  late DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  /// `true` : tous les comptes ; sinon seulement le compte affiché sur l'accueil.
  bool _allAccounts = true;

  bool get _isCurrentMonth =>
      _month.year == DateTime.now().year &&
      _month.month == DateTime.now().month;

  @override
  Widget build(BuildContext context) {
    final account = ref.watch(currentAccountProvider);
    final accountId = _allAccounts ? null : account?.id;
    final from = Fmt.iso(_month);
    final to = Fmt.iso(DateTime(_month.year, _month.month + 1, 0));
    final range = (from: from, to: to, accountId: accountId);
    final summary = ref.watch(summaryProvider(range));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analyses'),
        actions: [
          TextButton.icon(
            onPressed: () => context.push('/insights/pivot'),
            icon: const Icon(Icons.table_rows_rounded),
            label: const Text('Tableau croisé'),
          ),
          const SizedBox(width: Gap.sm),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.read(dataVersionProvider.notifier).bump(),
        child: ListView(
          padding: const EdgeInsets.only(bottom: Gap.xxl),
          children: [
            const OfflineBanner(),
            Padding(
              padding: const EdgeInsets.fromLTRB(Gap.sm, Gap.sm, Gap.sm, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => setState(
                      () => _month = DateTime(_month.year, _month.month - 1),
                    ),
                    icon: const Icon(Icons.chevron_left_rounded),
                    tooltip: 'Mois précédent',
                  ),
                  Expanded(
                    child: Semantics(
                      liveRegion: true,
                      child: Text(
                        Fmt.month(from),
                        textAlign: TextAlign.center,
                        style: context.text.titleLarge,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _isCurrentMonth
                        ? null
                        : () => setState(
                            () => _month = DateTime(
                              _month.year,
                              _month.month + 1,
                            ),
                          ),
                    icon: const Icon(Icons.chevron_right_rounded),
                    tooltip: 'Mois suivant',
                  ),
                ],
              ),
            ),
            if (account != null)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: Gap.page,
                  vertical: Gap.sm,
                ),
                child: PillTabs<bool>(
                  value: _allAccounts,
                  items: [
                    (value: true, label: 'Tous les comptes'),
                    (value: false, label: account.name),
                  ],
                  onChanged: (v) => setState(() => _allAccounts = v),
                ),
              ),
            summary.when(
              skipLoadingOnReload: true,
              loading: () => const Padding(
                padding: EdgeInsets.all(Gap.page),
                child: _SummarySkeleton(),
              ),
              error: (error, _) => ErrorState(
                error: error,
                onRetry: () => ref.invalidate(summaryProvider(range)),
              ),
              data: (s) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Totals(summary: s),
                  const SectionHeader('Dépenses par catégorie'),
                  if (s.expenses.isEmpty)
                    const EmptyState(
                      icon: Icons.donut_large_rounded,
                      title: 'Aucune dépense ce mois-ci',
                      message:
                          'La répartition apparaîtra dès la première dépense saisie sur cette période.',
                    )
                  else
                    _Breakdown(items: s.expenses, total: s.expense),
                  if (s.incomes.isNotEmpty) ...[
                    const SectionHeader('Revenus'),
                    for (final item in s.incomes)
                      _BreakdownRow(item: item, positive: true),
                  ],
                ],
              ),
            ),
            const SectionHeader('Douze derniers mois'),
            _MonthlyChart(accountId: accountId),
            const SectionHeader('Solde et prévision à 30 jours'),
            _BalanceChart(accountId: accountId),
          ],
        ),
      ),
    );
  }
}

class _SummarySkeleton extends StatelessWidget {
  const _SummarySkeleton();

  @override
  Widget build(BuildContext context) => const Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Skeleton(width: 180, height: 32),
      SizedBox(height: Gap.lg),
      Skeleton(height: 14),
      SizedBox(height: Gap.sm),
      Skeleton(width: 220, height: 14),
      SizedBox(height: Gap.xl),
      Skeleton(height: 160, radius: 14),
    ],
  );
}

/// Les trois chiffres du mois, en colonnes séparées par une perforation.
class _Totals extends StatelessWidget {
  const _Totals({required this.summary});
  final Summary summary;

  @override
  Widget build(BuildContext context) {
    final c = context.moneo;
    // Trois lignes alignées à droite : les montants se comparent d'un coup d'œil, à taille égale.
    Widget line(
      String label,
      double value, {
      Color? color,
      bool signed = false,
      bool strong = false,
    }) => Padding(
      padding: const EdgeInsets.symmetric(vertical: Gap.xs),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: strong
                  ? context.text.titleMedium
                  : context.text.bodyLarge?.copyWith(color: c.inkSoft),
            ),
          ),
          Amount(
            value,
            signed: signed,
            style: (strong ? context.text.titleLarge : context.text.titleMedium)
                ?.copyWith(color: color),
          ),
        ],
      ),
    );
    final rate = summary.savingsRate;

    return Padding(
      padding: const EdgeInsets.fromLTRB(Gap.page, Gap.md, Gap.page, 0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(Gap.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              line('Revenus', summary.income, color: c.income),
              line('Dépenses', summary.expense),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: Gap.sm),
                child: Perforation(),
              ),
              line(
                'Solde du mois',
                summary.net,
                signed: true,
                strong: true,
                color: summary.net < 0 ? context.scheme.error : null,
              ),
              const SizedBox(height: Gap.md),
              Text(
                [
                  '${summary.count} opération${summary.count > 1 ? 's' : ''}',
                  '${Fmt.money(summary.dailyExpense)} dépensés par jour en moyenne',
                  if (rate != null)
                    rate >= 0
                        ? '${rate.round()} % des revenus mis de côté'
                        : 'dépenses supérieures aux revenus',
                ].join(' · '),
                style: context.text.bodySmall?.copyWith(color: c.inkSoft),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Anneau de répartition et liste classée. La liste est l'équivalent textuel du graphique.
class _Breakdown extends StatefulWidget {
  const _Breakdown({required this.items, required this.total});
  final List<CategoryTotal> items;
  final double total;

  @override
  State<_Breakdown> createState() => _BreakdownState();
}

class _BreakdownState extends State<_Breakdown> {
  int? _touched;

  @override
  Widget build(BuildContext context) {
    final c = context.moneo;
    Color colorOf(CategoryTotal t) =>
        t.colorValue == null ? c.perforation : Color(t.colorValue!);
    final focus = _touched == null ? null : widget.items[_touched!];

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: Stack(
            alignment: Alignment.center,
            children: [
              ExcludeSemantics(
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 62,
                    startDegreeOffset: -90,
                    pieTouchData: PieTouchData(
                      touchCallback: (event, response) {
                        if (!event.isInterestedForInteractions) return;
                        final index =
                            response?.touchedSection?.touchedSectionIndex;
                        setState(
                          () => _touched = index == null || index < 0
                              ? null
                              : index,
                        );
                      },
                    ),
                    sections: [
                      for (var i = 0; i < widget.items.length; i++)
                        PieChartSectionData(
                          value: widget.items[i].total,
                          color: colorOf(widget.items[i]),
                          radius: _touched == i ? 30 : 24,
                          showTitle: false,
                        ),
                    ],
                  ),
                  duration: context.reduceMotion ? Duration.zero : Motion.slow,
                  curve: Motion.curve,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    focus?.name ?? 'Total',
                    style: context.text.labelMedium?.copyWith(color: c.inkSoft),
                    maxLines: 1,
                  ),
                  Amount(
                    focus?.total ?? widget.total,
                    style: context.text.titleLarge,
                  ),
                  if (focus != null)
                    Text(
                      '${focus.percent.round()} %',
                      style: context.text.bodySmall?.copyWith(color: c.inkSoft),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: Gap.sm),
        for (final item in widget.items) _BreakdownRow(item: item),
      ],
    );
  }
}

class _BreakdownRow extends StatefulWidget {
  const _BreakdownRow({required this.item, this.positive = false});
  final CategoryTotal item;
  final bool positive;

  @override
  State<_BreakdownRow> createState() => _BreakdownRowState();
}

class _BreakdownRowState extends State<_BreakdownRow> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final c = context.moneo;
    final item = widget.item;
    final color = item.colorValue == null
        ? c.perforation
        : Color(item.colorValue!);
    final expandable = item.subs.isNotEmpty;

    return Column(
      children: [
        InkWell(
          onTap: expandable ? () => setState(() => _open = !_open) : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Gap.page,
              vertical: Gap.sm,
            ),
            child: Row(
              children: [
                CategoryBadge(
                  icon: categoryIcon(item.iconCode),
                  color: color,
                  size: 36,
                ),
                const SizedBox(width: Gap.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.name,
                              style: context.text.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Amount(
                            item.total,
                            signed: widget.positive,
                            colored: widget.positive,
                            style: context.text.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: Gap.xs),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: BarProgress(
                                value: (item.percent / 100).clamp(0, 1),
                                color: color,
                                height: 6,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 52,
                            child: Text(
                              '${item.percent.round()} %',
                              textAlign: TextAlign.end,
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
                if (expandable)
                  Padding(
                    padding: const EdgeInsets.only(left: Gap.xs),
                    child: Icon(
                      _open
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                      color: c.inkSoft,
                      semanticLabel: _open ? 'Replier' : 'Voir le détail',
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (_open)
          for (final sub in item.subs)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Gap.page + 48,
                Gap.xs,
                Gap.page + 28,
                Gap.xs,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      sub.name,
                      style: context.text.bodyMedium?.copyWith(
                        color: c.inkSoft,
                      ),
                    ),
                  ),
                  Amount(sub.total, style: context.text.bodyMedium),
                ],
              ),
            ),
      ],
    );
  }
}

Widget _legend(
  BuildContext context,
  Color color,
  String label, {
  bool dashed = false,
}) => Row(
  mainAxisSize: MainAxisSize.min,
  children: [
    Container(
      width: 14,
      height: dashed ? 3 : 10,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    ),
    const SizedBox(width: Gap.xs + 2),
    Text(
      label,
      style: context.text.bodySmall?.copyWith(color: context.moneo.inkSoft),
    ),
  ],
);

/// Revenus et dépenses mois par mois.
class _MonthlyChart extends ConsumerWidget {
  const _MonthlyChart({required this.accountId});
  final String? accountId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.moneo;
    final months = ref.watch(monthlyProvider(accountId));
    return months.when(
      skipLoadingOnReload: true,
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(horizontal: Gap.page),
        child: Skeleton(height: 190, radius: 14),
      ),
      error: (error, _) => ErrorState(
        error: error,
        onRetry: () => ref.invalidate(monthlyProvider(accountId)),
      ),
      data: (items) {
        final max = items.fold<double>(
          0,
          (m, e) => [m, e.income, e.expense].reduce((a, b) => a > b ? a : b),
        );
        if (max == 0) {
          return const EmptyState(
            icon: Icons.bar_chart_rounded,
            title: 'Pas encore d’historique',
            message: 'Le graphique se remplira au fil des mois.',
          );
        }
        final best = items.reduce(
          (a, b) => (a.income - a.expense) >= (b.income - b.expense) ? a : b,
        );
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: Gap.page),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _legend(context, c.income, 'Revenus'),
                  const SizedBox(width: Gap.lg),
                  _legend(context, context.scheme.primary, 'Dépenses'),
                ],
              ),
              const SizedBox(height: Gap.md),
              Semantics(
                label:
                    'Revenus et dépenses sur douze mois. Meilleur mois : ${Fmt.month(best.period)}, '
                    'solde de ${Fmt.signed(best.income - best.expense)}.',
                child: ExcludeSemantics(
                  child: SizedBox(
                    height: 180,
                    child: BarChart(
                      BarChartData(
                        maxY: max * 1.1,
                        gridData: FlGridData(
                          drawVerticalLine: false,
                          horizontalInterval: max / 3,
                          getDrawingHorizontalLine: (_) =>
                              FlLine(color: c.line, strokeWidth: 1),
                        ),
                        borderData: FlBorderData(show: false),
                        barTouchData: BarTouchData(
                          touchTooltipData: BarTouchTooltipData(
                            getTooltipColor: (_) =>
                                context.scheme.inverseSurface,
                            getTooltipItem: (group, _, rod, rodIndex) =>
                                BarTooltipItem(
                                  '${Fmt.month(items[group.x].period)}\n${rodIndex == 0 ? 'Revenus' : 'Dépenses'} ${Fmt.money(rod.toY)}',
                                  TextStyle(
                                    color: context.scheme.onInverseSurface,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                          ),
                        ),
                        titlesData: FlTitlesData(
                          topTitles: const AxisTitles(),
                          rightTitles: const AxisTitles(),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 46,
                              interval: max / 3,
                              getTitlesWidget: (value, meta) =>
                                  value == meta.max
                                  ? const SizedBox.shrink()
                                  : Text(
                                      Fmt.compact(value),
                                      style: context.text.labelSmall?.copyWith(
                                        color: c.inkSoft,
                                      ),
                                    ),
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 24,
                              getTitlesWidget: (value, _) {
                                final i = value.toInt();
                                if (i < 0 || i >= items.length || i.isOdd) {
                                  return const SizedBox.shrink();
                                }
                                return Padding(
                                  padding: const EdgeInsets.only(top: Gap.xs),
                                  child: Text(
                                    Fmt.monthShort(items[i].period),
                                    style: context.text.labelSmall?.copyWith(
                                      color: c.inkSoft,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        barGroups: [
                          for (var i = 0; i < items.length; i++)
                            BarChartGroupData(
                              x: i,
                              barsSpace: 2,
                              barRods: [
                                BarChartRodData(
                                  toY: items[i].income,
                                  color: c.income,
                                  width: 7,
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(3),
                                  ),
                                ),
                                BarChartRodData(
                                  toY: items[i].expense,
                                  color: context.scheme.primary,
                                  width: 7,
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(3),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                      duration: context.reduceMotion
                          ? Duration.zero
                          : Motion.slow,
                      curve: Motion.curve,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Solde des 60 derniers jours, prolongé par la prévision (écritures futures et mensualités à venir).
class _BalanceChart extends ConsumerWidget {
  const _BalanceChart({required this.accountId});
  final String? accountId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.moneo;
    final now = DateTime.now();
    final range = (
      from: Fmt.iso(now.subtract(const Duration(days: 60))),
      to: Fmt.iso(now),
      accountId: accountId,
    );
    final history = ref.watch(balanceHistoryProvider(range));
    final forecast = ref.watch(forecastProvider(accountId));

    if (history.isLoading && !history.hasValue ||
        forecast.isLoading && !forecast.hasValue) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: Gap.page),
        child: Skeleton(height: 200, radius: 14),
      );
    }
    final error = history.error ?? forecast.error;
    if (error != null && (!history.hasValue || !forecast.hasValue)) {
      return ErrorState(
        error: error,
        onRetry: () {
          ref.invalidate(balanceHistoryProvider(range));
          ref.invalidate(forecastProvider(accountId));
        },
      );
    }
    final past = history.value!;
    final future = forecast.value!;
    final pastSpots = [
      for (var i = 0; i < past.length; i++)
        FlSpot(i.toDouble(), past[i].balance),
    ];
    final offset = past.length - 1;
    final futureSpots = [
      for (var i = 0; i < future.points.length; i++)
        FlSpot((offset + i).toDouble(), future.points[i].balance),
    ];
    final all = [...pastSpots, ...futureSpots].map((s) => s.y);
    final minY = all.reduce((a, b) => a < b ? a : b);
    final maxY = all.reduce((a, b) => a > b ? a : b);
    final pad = (maxY - minY).abs() < 1 ? 50.0 : (maxY - minY) * 0.12;
    final line = context.scheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Gap.page),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dans 30 jours',
                      style: context.text.labelMedium?.copyWith(
                        color: c.inkSoft,
                      ),
                    ),
                    Amount(
                      future.projected,
                      style: context.text.headlineSmall?.copyWith(
                        color: future.projected < 0
                            ? context.scheme.error
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Point bas le ${Fmt.shortDate(future.lowest.date)}',
                    style: context.text.labelMedium?.copyWith(color: c.inkSoft),
                  ),
                  Amount(
                    future.lowest.balance,
                    style: context.text.titleMedium?.copyWith(
                      color: future.lowest.balance < 0
                          ? context.scheme.error
                          : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: Gap.md),
          Semantics(
            label:
                'Courbe du solde. Aujourd’hui ${Fmt.money(future.current)}, prévu à ${Fmt.money(future.projected)} dans 30 jours, '
                'point bas de ${Fmt.money(future.lowest.balance)} le ${Fmt.longDate(future.lowest.date)}.',
            child: ExcludeSemantics(
              child: SizedBox(
                height: 180,
                child: LineChart(
                  LineChartData(
                    minY: minY - pad,
                    maxY: maxY + pad,
                    gridData: FlGridData(
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (_) =>
                          FlLine(color: c.line, strokeWidth: 1),
                    ),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(),
                      rightTitles: const AxisTitles(),
                      bottomTitles: const AxisTitles(),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 52,
                          getTitlesWidget: (value, meta) =>
                              value == meta.max || value == meta.min
                              ? const SizedBox.shrink()
                              : Text(
                                  Fmt.compact(value),
                                  style: context.text.labelSmall?.copyWith(
                                    color: c.inkSoft,
                                  ),
                                ),
                        ),
                      ),
                    ),
                    extraLinesData: ExtraLinesData(
                      verticalLines: [
                        VerticalLine(
                          x: offset.toDouble(),
                          color: c.perforation,
                          strokeWidth: 1.5,
                          dashArray: [2, 4],
                        ),
                      ],
                      horizontalLines: [
                        if (minY - pad < 0)
                          HorizontalLine(
                            y: 0,
                            color: context.scheme.error.withValues(alpha: 0.6),
                            strokeWidth: 1,
                          ),
                      ],
                    ),
                    lineTouchData: LineTouchData(
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipColor: (_) => context.scheme.inverseSurface,
                        getTooltipItems: (spots) => [
                          for (final spot in spots)
                            LineTooltipItem(
                              '${Fmt.shortDate(Fmt.iso(now.add(Duration(days: spot.x.toInt() - offset))))}\n${Fmt.money(spot.y)}',
                              TextStyle(
                                color: context.scheme.onInverseSurface,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: pastSpots,
                        color: line,
                        barWidth: 2.5,
                        isCurved: true,
                        preventCurveOverShooting: true,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: line.withValues(alpha: 0.10),
                        ),
                      ),
                      LineChartBarData(
                        spots: futureSpots,
                        color: line,
                        barWidth: 2.5,
                        dashArray: [5, 5],
                        dotData: const FlDotData(show: false),
                      ),
                    ],
                  ),
                  duration: context.reduceMotion ? Duration.zero : Motion.slow,
                  curve: Motion.curve,
                ),
              ),
            ),
          ),
          const SizedBox(height: Gap.sm),
          Row(
            children: [
              _legend(context, line, 'Solde'),
              const SizedBox(width: Gap.lg),
              _legend(context, line, 'Prévision (pointillés)', dashed: true),
            ],
          ),
          if (future.upcoming.isNotEmpty) ...[
            const SizedBox(height: Gap.lg),
            Text('À venir', style: context.text.titleSmall),
            for (final o in future.upcoming.take(6))
              Padding(
                padding: const EdgeInsets.only(top: Gap.sm),
                child: Row(
                  children: [
                    SizedBox(
                      width: 64,
                      child: Text(
                        Fmt.shortDate(o.date),
                        style: context.text.bodySmall?.copyWith(
                          color: c.inkSoft,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        o.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Amount(
                      o.amount,
                      signed: true,
                      colored: true,
                      style: context.text.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

// ── Tableau croisé ───────────────────────────────────────────────────────────

/// Tableau croisé du classeur : période → catégorie → sous-catégorie, débits et crédits.
class PivotPage extends ConsumerStatefulWidget {
  const PivotPage({super.key});

  @override
  ConsumerState<PivotPage> createState() => _PivotPageState();
}

class _PivotPageState extends ConsumerState<PivotPage> {
  String _granularity = 'month';
  int _year = DateTime.now().year;
  String? _accountId;
  final _open = <String>{};

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(appDataProvider).value;
    final c = context.moneo;
    final query = (
      from: '$_year-01-01',
      to: '$_year-12-31',
      granularity: _granularity,
      accountId: _accountId,
    );
    final pivot = ref.watch(pivotProvider(query));

    String rowLabel(String key) => switch (_granularity) {
      'day' => Fmt.dayLabel(key),
      'month' => Fmt.month(key),
      _ => key,
    };

    Widget amounts(double debit, double credit, TextStyle? style) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 92,
          child: Text(
            debit == 0 ? '' : Fmt.plain(debit),
            textAlign: TextAlign.end,
            style: style?.copyWith(fontFeatures: tabular),
          ),
        ),
        SizedBox(
          width: 92,
          child: Text(
            credit == 0 ? '' : Fmt.plain(credit),
            textAlign: TextAlign.end,
            style: style?.copyWith(fontFeatures: tabular, color: c.income),
          ),
        ),
      ],
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Tableau croisé')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Gap.sm),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => setState(() => _year--),
                  icon: const Icon(Icons.chevron_left_rounded),
                  tooltip: 'Année précédente',
                ),
                Text(
                  '$_year',
                  style: context.text.titleLarge?.copyWith(
                    fontFeatures: tabular,
                  ),
                ),
                IconButton(
                  onPressed: _year >= DateTime.now().year
                      ? null
                      : () => setState(() => _year++),
                  icon: const Icon(Icons.chevron_right_rounded),
                  tooltip: 'Année suivante',
                ),
                const Spacer(),
                PillTabs<String>(
                  value: _granularity,
                  items: [
                    (value: 'day', label: 'Jour'),
                    (value: 'month', label: 'Mois'),
                    (value: 'year', label: 'Année'),
                  ],
                  onChanged: (v) => setState(() {
                    _granularity = v;
                    _open.clear();
                  }),
                ),
                const SizedBox(width: Gap.sm),
              ],
            ),
          ),
          if (data != null && data.activeAccounts.length > 1)
            SizedBox(
              height: 52,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: Gap.page,
                  vertical: Gap.xs,
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: Gap.sm),
                    child: ChoicePill(
                      label: 'Tous les comptes',
                      selected: _accountId == null,
                      onTap: () => setState(() => _accountId = null),
                    ),
                  ),
                  for (final a in data.activeAccounts)
                    Padding(
                      padding: const EdgeInsets.only(right: Gap.sm),
                      child: ChoicePill(
                        label: a.name,
                        selected: _accountId == a.id,
                        onTap: () => setState(() => _accountId = a.id),
                      ),
                    ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Gap.page,
              Gap.sm,
              Gap.page,
              Gap.xs,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Période / catégorie',
                    style: context.text.labelMedium?.copyWith(color: c.inkSoft),
                  ),
                ),
                SizedBox(
                  width: 92,
                  child: Text(
                    'Débit',
                    textAlign: TextAlign.end,
                    style: context.text.labelMedium?.copyWith(color: c.inkSoft),
                  ),
                ),
                SizedBox(
                  width: 92,
                  child: Text(
                    'Crédit',
                    textAlign: TextAlign.end,
                    style: context.text.labelMedium?.copyWith(color: c.inkSoft),
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: Gap.page),
            child: Perforation(),
          ),
          Expanded(
            child: pivot.when(
              skipLoadingOnReload: true,
              loading: () =>
                  const SingleChildScrollView(child: SkeletonList(rows: 8)),
              error: (error, _) => Center(
                child: ErrorState(
                  error: error,
                  onRetry: () => ref.invalidate(pivotProvider(query)),
                ),
              ),
              data: (p) {
                if (p.rows.isEmpty) {
                  return const Center(
                    child: EmptyState(
                      icon: Icons.table_rows_rounded,
                      title: 'Aucune écriture',
                      message:
                          'Aucune opération sur cette année pour ce compte.',
                    ),
                  );
                }
                final tiles = <Widget>[];
                for (final row in p.rows) {
                  final rowOpen = _open.contains(row.name);
                  tiles.add(
                    InkWell(
                      onTap: () => setState(
                        () => rowOpen
                            ? _open.remove(row.name)
                            : _open.add(row.name),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Gap.page,
                          vertical: Gap.md,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              rowOpen
                                  ? Icons.expand_more_rounded
                                  : Icons.chevron_right_rounded,
                              size: 20,
                              color: c.inkSoft,
                              semanticLabel: rowOpen ? 'Replier' : 'Déplier',
                            ),
                            const SizedBox(width: Gap.xs),
                            Expanded(
                              child: Text(
                                rowLabel(row.name),
                                style: context.text.titleSmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            amounts(
                              row.debit,
                              row.credit,
                              context.text.titleSmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                  if (!rowOpen) continue;
                  for (final category in row.children) {
                    tiles.add(
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          Gap.page + 24,
                          Gap.xs,
                          Gap.page,
                          Gap.xs,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                category.name,
                                style: context.text.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            amounts(
                              category.debit,
                              category.credit,
                              context.text.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    );
                    for (final sub in category.children) {
                      tiles.add(
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            Gap.page + 40,
                            2,
                            Gap.page,
                            2,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  sub.name,
                                  style: context.text.bodySmall?.copyWith(
                                    color: c.inkSoft,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              amounts(
                                sub.debit,
                                sub.credit,
                                context.text.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                  }
                  tiles.add(const SizedBox(height: Gap.sm));
                }
                return ListView(children: tiles);
              },
            ),
          ),
          if (pivot.hasValue)
            SafeArea(
              top: false,
              child: Container(
                decoration: BoxDecoration(
                  color: context.scheme.surface,
                  border: Border(top: BorderSide(color: c.line)),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: Gap.page,
                  vertical: Gap.md,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Total $_year',
                        style: context.text.titleSmall,
                      ),
                    ),
                    amounts(
                      pivot.value!.debit,
                      pivot.value!.credit,
                      context.text.titleSmall,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
