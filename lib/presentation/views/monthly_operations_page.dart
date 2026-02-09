import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/database/app_database.dart';
import '../../core/notifiers/auth_notifier.dart';
import '../../core/themes/app_colors.dart';
import '../view_models/home_view_model.dart';
import '../widgets/monthly_operation_form_sheet.dart';

class MonthlyOperationsPage extends StatelessWidget {
  const MonthlyOperationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HomeViewModel>();
    final auth = context.read<AuthNotifier>();
    final uid = auth.appUser?.uid ?? "";
    final operations = vm.monthlyPayments;

    return Scaffold(
      backgroundColor: AppColors.mainBackground,
      appBar: AppBar(
        title: const Text("Mensualisations", style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: AppColors.mainBackground,
        scrolledUnderElevation: 0,
      ),
      body: operations.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
        padding: const EdgeInsets.only(bottom: 100, top: 16),
        itemCount: operations.length,
        itemBuilder: (context, index) => _buildOperationCard(context, operations[index], vm, uid),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.mainColor,
        onPressed: () => _showForm(context, uid),
        label: const Text("Ajouter", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        icon: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildOperationCard(BuildContext context, MonthlyPayment op, HomeViewModel vm, String uid) {
    final account = vm.accounts.firstWhere(
            (a) => a.id == op.accountId,
        orElse: () => vm.accounts.first
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Card(
        color: AppColors.secondaryBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          title: Text(op.name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text("Le ${op.dayOfMonth} du mois • ${account.name}", style: const TextStyle(color: AppColors.grey1)),
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "${op.amount > 0 ? '+' : ''}${op.amount.toStringAsFixed(2)} €",
                style: TextStyle(
                  color: op.amount < 0 ? AppColors.primaryRed : AppColors.primaryGreen,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
              const Text("Récurrent", style: TextStyle(fontSize: 10, color: AppColors.grey1)),
            ],
          ),
          onTap: () => _showForm(context, uid, operation: op),
          onLongPress: () => _confirmDelete(context, op, vm),
        ),
      ),
    );
  }

  void _showForm(BuildContext context, String uid, {MonthlyPayment? operation}) {
    final vm = context.read<HomeViewModel>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MonthlyOperationFormSheet(
        operation: operation,
        accounts: vm.accounts,
        categories: vm.categories,
        onSave: (name, amount, type, day, accId, catId) {
          vm.saveMonthlyPayment(
            id: operation?.id,
            name: name,
            amount: amount,
            type: type,
            dayOfMonth: day,
            accountId: accId,
            categoryId: catId,
          );
        },
        uid: uid,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_month_outlined, size: 64, color: AppColors.grey1.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          const Text("Aucune mensualisation configurée", style: TextStyle(color: AppColors.grey1)),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, MonthlyPayment op, HomeViewModel vm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.secondaryBackground,
        title: const Text("Supprimer ?", style: TextStyle(color: Colors.white)),
        content: Text("Voulez-vous supprimer la mensualité '${op.name}' ?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.primaryRed),
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