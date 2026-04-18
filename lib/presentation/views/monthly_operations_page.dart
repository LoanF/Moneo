import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/models.dart';
import '../../core/helpers/icon_helper.dart';
import '../../core/notifiers/auth_notifier.dart';
import '../../core/themes/app_colors.dart';
import '../view_models/home_view_model.dart';
import '../widgets/monthly_operation_form_sheet.dart';

class MonthlyOperationsPage extends StatelessWidget {
  const MonthlyOperationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HomeViewModel>();
    final uid = context.read<AuthNotifier>().appUser?.uid ?? "";

    return Scaffold(
      backgroundColor: AppColors.mainBackground,
      appBar: AppBar(
        title: const Text("Mensualisations", style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.mainText)),
        centerTitle: false,
      ),
      body: vm.monthlyPayments.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              itemCount: vm.monthlyPayments.length,
              itemBuilder: (context, index) =>
                  _buildTile(context, vm.monthlyPayments[index], vm, uid),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(context, uid),
        label: const Text("Ajouter", style: TextStyle(fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTile(BuildContext context, MonthlyPayment op, HomeViewModel vm, String uid) {
    final isExpense = op.type == 'expense';
    final accentColor = isExpense ? AppColors.primaryRed : AppColors.primaryGreen;
    final account = vm.accounts.firstWhere(
      (a) => a.id == op.accountId,
      orElse: () => vm.accounts.isNotEmpty ? vm.accounts.first : throw StateError('no accounts'),
    );

    final cat = op.categoryId != null
        ? vm.categories.cast<Category?>().firstWhere(
            (c) => c?.id == op.categoryId,
            orElse: () => null,
          )
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.secondaryBackground,
        borderRadius: BorderRadius.circular(20),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _showForm(context, uid, operation: op),
        onLongPress: () => _confirmDelete(context, op, vm),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Day badge
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: cat != null
                    ? Icon(IconHelper.getIcon(cat.iconCode), color: accentColor, size: 22)
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "${op.dayOfMonth}",
                            style: TextStyle(color: accentColor, fontWeight: FontWeight.w900, fontSize: 16),
                          ),
                          Text("du mois", style: TextStyle(color: accentColor.withValues(alpha: 0.7), fontSize: 7, fontWeight: FontWeight.w600)),
                        ],
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      op.name,
                      style: const TextStyle(color: AppColors.mainText, fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.repeat_rounded, size: 12, color: AppColors.secondaryText),
                        const SizedBox(width: 4),
                        Text(
                          "Le ${op.dayOfMonth} · ${account.name}",
                          style: const TextStyle(color: AppColors.secondaryText, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "${isExpense ? '-' : '+'}${op.amount.abs().toStringAsFixed(2)} €",
                    style: TextStyle(color: accentColor, fontWeight: FontWeight.w900, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isExpense ? "Débit" : "Crédit",
                      style: TextStyle(color: accentColor, fontSize: 10, fontWeight: FontWeight.bold),
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: AppColors.secondaryBackground,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.calendar_month_outlined, size: 48, color: AppColors.grey1),
          ),
          const SizedBox(height: 20),
          const Text("Aucune mensualisation", style: TextStyle(color: AppColors.mainText, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          const Text("Loyer, abonnements, salaire…", style: TextStyle(color: AppColors.secondaryText, fontSize: 13)),
        ],
      ),
    );
  }

  void _showForm(BuildContext context, String uid, {MonthlyPayment? operation}) {
    final vm = context.read<HomeViewModel>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MonthlyOperationFormSheet(
        operation: operation,
        accounts: vm.accounts,
        categories: vm.categories,
        uid: uid,
        onSave: (name, amount, type, day, accId, catId) => vm.saveMonthlyPayment(
          id: operation?.id,
          name: name,
          amount: amount,
          type: type,
          dayOfMonth: day,
          accountId: accId,
          categoryId: catId,
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, MonthlyPayment op, HomeViewModel vm) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Supprimer ?"),
        content: Text("Voulez-vous supprimer « ${op.name} » ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.primaryRed, minimumSize: Size.zero),
            onPressed: () {
              vm.deleteMonthlyPayment(op.id);
              Navigator.pop(context);
            },
            child: const Text("Supprimer"),
          ),
        ],
      ),
    );
  }
}
