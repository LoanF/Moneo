import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/helpers/icon_helper.dart';
import '../../core/themes/app_colors.dart';
import '../view_models/stats_view_model.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StatsViewModel>().init();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<StatsViewModel>();
    return Scaffold(
      backgroundColor: AppColors.mainBackground,
      appBar: AppBar(
        backgroundColor: AppColors.mainBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Statistiques',
          style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.mainText),
        ),
        centerTitle: false,
      ),
      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator())
          : vm.errorMessage != null
              ? _buildError(vm)
              : _buildContent(vm),
    );
  }

  Widget _buildError(StatsViewModel vm) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.grey1),
            const SizedBox(height: 16),
            Text(
              vm.errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.secondaryText),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => vm.init(),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(StatsViewModel vm) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
        children: [
          _buildMonthSelector(vm),
          const SizedBox(height: 16),
          _buildSummaryCards(vm),
          const SizedBox(height: 12),
          _buildBarChart(vm),
          const SizedBox(height: 12),
          _buildSavingsRate(vm),
          if (vm.categoryBreakdown.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildCategoryBreakdown(vm),
          ],
          const SizedBox(height: 12),
          _buildQuickStats(vm),
        ],
      ),
    );
  }

  // ─── Month selector ──────────────────────────────────────────────────────────

  Widget _buildMonthSelector(StatsViewModel vm) {
    final raw = DateFormat('MMMM yyyy').format(vm.selectedMonth);
    final label = raw[0].toUpperCase() + raw.substring(1);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded, color: AppColors.mainText, size: 28),
            onPressed: vm.previousMonth,
          ),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.mainText,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.chevron_right_rounded,
              color: vm.canGoNext ? AppColors.mainText : AppColors.grey1,
              size: 28,
            ),
            onPressed: vm.canGoNext ? vm.nextMonth : null,
          ),
        ],
      ),
    );
  }

  // ─── KPI cards ───────────────────────────────────────────────────────────────

  Widget _buildSummaryCards(StatsViewModel vm) {
    final net = vm.netBalance;
    return Row(
      children: [
        Expanded(child: _kpiCard(
          label: 'Revenus',
          value: '+${vm.totalIncome.toStringAsFixed(0)} €',
          color: AppColors.primaryGreen,
          icon: Icons.south_rounded,
        )),
        const SizedBox(width: 8),
        Expanded(child: _kpiCard(
          label: 'Dépenses',
          value: '-${vm.totalExpense.toStringAsFixed(0)} €',
          color: AppColors.primaryRed,
          icon: Icons.north_rounded,
        )),
        const SizedBox(width: 8),
        Expanded(child: _kpiCard(
          label: 'Net',
          value: '${net >= 0 ? '+' : ''}${net.toStringAsFixed(0)} €',
          color: net >= 0 ? AppColors.primaryGreen : AppColors.primaryRed,
          icon: net >= 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded,
        )),
      ],
    );
  }

  Widget _kpiCard({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.secondaryBackground,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 14),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: AppColors.secondaryText, fontSize: 11)),
        ],
      ),
    );
  }

  // ─── 6-month bar chart ───────────────────────────────────────────────────────

  Widget _buildBarChart(StatsViewModel vm) {
    final stats = vm.last6MonthsStats;
    final maxVal = stats.fold(
      0.0,
      (m, s) => [m, s.income, s.expense].reduce((a, b) => a > b ? a : b),
    );

    return _buildCard(
      title: 'Évolution sur 6 mois',
      trailing: Row(
        children: [
          _legend(AppColors.primaryGreen, 'Revenus'),
          const SizedBox(width: 10),
          _legend(AppColors.primaryRed, 'Dépenses'),
        ],
      ),
      child: SizedBox(
        height: 140,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: stats.map((s) {
            final isCurrent = s.month.year == vm.selectedMonth.year &&
                s.month.month == vm.selectedMonth.month;
            return Expanded(child: _buildMonthBars(s, maxVal, isCurrent));
          }).toList(),
        ),
      ),
    );
  }

  Widget _legend(Color color, String label) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: AppColors.secondaryText, fontSize: 10)),
      ],
    );
  }

  Widget _buildMonthBars(MonthlyStats stats, double maxVal, bool isSelected) {
    const chartHeight = 100.0;
    final incomeH = maxVal > 0 ? (stats.income / maxVal * chartHeight).clamp(2.0, chartHeight) : 2.0;
    final expenseH = maxVal > 0 ? (stats.expense / maxVal * chartHeight).clamp(2.0, chartHeight) : 2.0;
    final label = DateFormat('MMM').format(stats.month);

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 11,
              height: incomeH,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryGreen
                    : AppColors.primaryGreen.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 3),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 11,
              height: expenseH,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryRed
                    : AppColors.primaryRed.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.mainText : AppColors.secondaryText,
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  // ─── Savings rate ─────────────────────────────────────────────────────────────

  Widget _buildSavingsRate(StatsViewModel vm) {
    final rate = vm.savingsRate;
    final hasIncome = vm.totalIncome > 0;
    final color = rate >= 20
        ? AppColors.primaryGreen
        : rate >= 10
            ? AppColors.warning
            : AppColors.primaryRed;

    return _buildCard(
      title: 'Taux d\'épargne',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                hasIncome ? '${rate.toStringAsFixed(1)} %' : '—',
                style: TextStyle(color: color, fontSize: 32, fontWeight: FontWeight.w900),
              ),
              const SizedBox(width: 10),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  _savingsLabel(rate, hasIncome),
                  style: TextStyle(color: color.withValues(alpha: 0.7), fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: hasIncome ? rate / 100 : 0,
              minHeight: 10,
              backgroundColor: AppColors.thirdBackground,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          if (hasIncome) ...[
            const SizedBox(height: 8),
            Text(
              'Épargné : ${vm.netBalance.toStringAsFixed(2)} € sur ${vm.totalIncome.toStringAsFixed(2)} € de revenus',
              style: const TextStyle(color: AppColors.secondaryText, fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }

  String _savingsLabel(double rate, bool hasIncome) {
    if (!hasIncome) return 'Aucun revenu';
    if (rate >= 30) return 'Excellent !';
    if (rate >= 20) return 'Très bien';
    if (rate >= 10) return 'Passable';
    if (rate > 0) return 'À améliorer';
    return 'Déficit';
  }

  // ─── Top categories ───────────────────────────────────────────────────────────

  Widget _buildCategoryBreakdown(StatsViewModel vm) {
    final breakdown = vm.categoryBreakdown;
    final total = breakdown.fold(0.0, (s, e) => s + e.value);

    return _buildCard(
      title: 'Top dépenses',
      child: Column(
        children: breakdown.asMap().entries.map((entry) {
          final index = entry.key;
          final cat = entry.value.key;
          final amount = entry.value.value;
          final ratio = total > 0 ? amount / total : 0.0;
          final color = Color(cat.colorValue);

          return Column(
            children: [
              if (index > 0) const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(IconHelper.getIcon(cat.iconCode), color: color, size: 16),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              cat.name,
                              style: const TextStyle(
                                color: AppColors.mainText,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${amount.toStringAsFixed(2)} €',
                              style: const TextStyle(
                                color: AppColors.mainText,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: ratio,
                            minHeight: 5,
                            backgroundColor: AppColors.thirdBackground,
                            valueColor: AlwaysStoppedAnimation<Color>(color),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${(ratio * 100).toStringAsFixed(0)} % des dépenses',
                          style: const TextStyle(color: AppColors.secondaryText, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  // ─── Quick stats ─────────────────────────────────────────────────────────────

  Widget _buildQuickStats(StatsViewModel vm) {
    final bigExpense = vm.biggestExpense;
    return _buildCard(
      title: 'En bref',
      child: Column(
        children: [
          _statRow(
            icon: Icons.receipt_long_rounded,
            label: 'Transactions ce mois',
            value: '${vm.transactionCount}',
          ),
          _divider(),
          _statRow(
            icon: Icons.calculate_rounded,
            label: 'Dépense moyenne',
            value: '${vm.avgExpense.toStringAsFixed(2)} €',
          ),
          _divider(),
          _statRow(
            icon: Icons.priority_high_rounded,
            iconColor: AppColors.primaryRed,
            label: 'Plus grande dépense',
            value: bigExpense != null
                ? '${bigExpense.amount.abs().toStringAsFixed(2)} €'
                : '—',
            subtitle: bigExpense?.note,
          ),
        ],
      ),
    );
  }

  Widget _divider() => const Divider(color: AppColors.thirdBackground, height: 20);

  Widget _statRow({
    required IconData icon,
    required String label,
    required String value,
    Color? iconColor,
    String? subtitle,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: iconColor ?? AppColors.grey1),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: AppColors.secondaryText, fontSize: 13)),
              if (subtitle != null)
                Text(
                  subtitle,
                  style: const TextStyle(color: AppColors.grey1, fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
        Text(
          value,
          style: const TextStyle(color: AppColors.mainText, fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  // ─── Card wrapper ─────────────────────────────────────────────────────────────

  Widget _buildCard({required String title, required Widget child, Widget? trailing}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.secondaryBackground,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                title.toUpperCase(),
                style: const TextStyle(
                  color: AppColors.mainColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
