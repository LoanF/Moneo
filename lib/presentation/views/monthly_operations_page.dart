import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/notifiers/auth_notifier.dart';
import '../../core/services/user_service.dart';
import '../../core/di.dart';
import '../../data/models/monthly_operation_model.dart';
import '../../core/themes/app_colors.dart';
import '../widgets/monthly_operation_form_sheet.dart';

class MonthlyOperationsPage extends StatefulWidget {
  const MonthlyOperationsPage({super.key});

  @override
  State<MonthlyOperationsPage> createState() => _MonthlyOperationsPageState();
}

class _MonthlyOperationsPageState extends State<MonthlyOperationsPage> {
  final _userService = getIt<IAppUserService>();

  @override
  Widget build(BuildContext context) {
    final uid = context.read<AuthNotifier>().appUser!.uid;

    return Scaffold(
      backgroundColor: AppColors.mainBackground,
      appBar: AppBar(
        title: const Text("Mensualisations", style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: AppColors.mainBackground,
        scrolledUnderElevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.mainColor,
        onPressed: () => _openForm(context, uid),
        label: const Text("Ajouter", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        icon: const Icon(Icons.add, color: Colors.white),
      ),
      body: StreamBuilder<List<MonthlyOperationModel>>(
        stream: _userService.getMonthlyOperationsStream(uid),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final operations = snapshot.data!;
          if (operations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_month_outlined, size: 80, color: AppColors.grey2.withValues(alpha: 0.5)),
                  const SizedBox(height: 16),
                  const Text("Aucune opération mensuelle", style: TextStyle(color: AppColors.secondaryText, fontSize: 16)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: operations.length,
            itemBuilder: (context, index) {
              final op = operations[index];
              return _buildOperationTile(context, uid, op);
            },
          );
        },
      ),
    );
  }

  Widget _buildOperationTile(BuildContext context, String uid, MonthlyOperationModel op) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.secondaryBackground,
        borderRadius: BorderRadius.circular(24),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: (op.isExpense ? AppColors.error : AppColors.mainColor).withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Text(
            op.dayOfMonth.toString(),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: op.isExpense ? AppColors.error : AppColors.mainColor,
            ),
          ),
        ),
        title: Text(op.title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.mainText)),
        subtitle: Text(
          "Moyenne : ${(op.amounts.reduce((a, b) => a + b) / 12).toStringAsFixed(2)} € / mois",
          style: const TextStyle(color: AppColors.grey2, fontSize: 13),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.more_vert_rounded, color: AppColors.grey2),
          onPressed: () => _showOptions(context, uid, op),
        ),
      ),
    );
  }

  void _showOptions(BuildContext context, String uid, MonthlyOperationModel op) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.secondaryBackground,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.edit_rounded, color: AppColors.mainText),
              title: const Text("Modifier", style: TextStyle(color: AppColors.mainText)),
              onTap: () {
                Navigator.pop(context);
                _openForm(context, uid, operation: op);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
              title: const Text("Supprimer", style: TextStyle(color: AppColors.error)),
              onTap: () {
                _userService.deleteMonthlyOperation(uid, op.id);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _openForm(BuildContext context, String uid, {MonthlyOperationModel? operation}) async {
    final accounts = await _userService.getAccountsStream(uid).first;
    final categories = await _userService.getCategoriesStream(uid).first;

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MonthlyOperationFormSheet(
        uid: uid,
        accounts: accounts,
        operation: operation,
        onSave: (op) => _userService.saveMonthlyOperation(uid, op),
      ),
    );
  }
}