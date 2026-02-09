import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/themes/app_colors.dart';
import '../../core/database/app_database.dart';
import '../view_models/home_view_model.dart';
import '../widgets/account_form_sheet.dart';

class AccountsManagerPage extends StatelessWidget {
  const AccountsManagerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HomeViewModel>();

    return Scaffold(
      backgroundColor: AppColors.mainBackground,
      appBar: AppBar(
        title: const Text("Mes Comptes", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: vm.accounts.length,
        itemBuilder: (context, index) {
          final account = vm.accounts[index];
          return _buildAccountTile(context, account, vm);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAccountForm(context),
        backgroundColor: AppColors.mainColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildAccountTile(BuildContext context, BankAccount account, HomeViewModel vm) {
    return Card(
      color: AppColors.secondaryBackground,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        title: Text(account.name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        subtitle: Text("${account.balance.toStringAsFixed(2)} €", style: const TextStyle(color: AppColors.grey1)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: AppColors.grey1),
              onPressed: () => _showAccountForm(context, account: account),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.primaryRed),
              onPressed: () => _confirmDelete(context, account, vm),
            ),
          ],
        ),
      ),
    );
  }

  void _showAccountForm(BuildContext context, {BankAccount? account}) {
    final vm = context.read<HomeViewModel>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AccountFormSheet(
        account: account,
        onSave: (name, balance) {
          if (account == null) {
            vm.createAccount(name: name, balance: balance);
          } else {
            vm.updateAccount(account, name: name, balance: balance);
          }
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, BankAccount account, HomeViewModel vm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.secondaryBackground,
        title: const Text("Supprimer le compte ?", style: TextStyle(color: Colors.white)),
        content: Text("Toutes les transactions liées à '${account.name}' seront conservées ou supprimées selon votre API."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.primaryRed),
            onPressed: () {
              vm.deleteAccount(account);
              Navigator.pop(context);
            },
            child: const Text("Supprimer"),
          ),
        ],
      ),
    );
  }
}