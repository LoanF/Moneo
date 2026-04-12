import 'package:flutter/material.dart' hide Category;
import 'package:provider/provider.dart';
import '../../core/themes/app_colors.dart';
import '../../data/models/models.dart';
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
        title: const Text("Mes comptes", style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.mainText)),
        centerTitle: false,
      ),
      body: vm.accounts.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              itemCount: vm.accounts.length,
              itemBuilder: (context, index) => _buildAccountTile(context, vm.accounts[index], vm),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(context),
        label: const Text("Ajouter", style: TextStyle(fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildAccountTile(BuildContext context, BankAccount account, HomeViewModel vm) {
    final isPositive = account.balance >= 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.secondaryBackground,
        borderRadius: BorderRadius.circular(20),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _showForm(context, account: account),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.mainColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.account_balance_wallet_rounded, color: AppColors.mainColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account.name,
                      style: const TextStyle(
                        color: AppColors.mainText,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      account.currency,
                      style: const TextStyle(color: AppColors.secondaryText, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "${isPositive ? '' : '-'}${account.balance.abs().toStringAsFixed(2)} €",
                    style: TextStyle(
                      color: isPositive ? AppColors.primaryGreen : AppColors.primaryRed,
                      fontWeight: FontWeight.w900,
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _actionIcon(
                        icon: Icons.edit_outlined,
                        color: AppColors.grey1,
                        onTap: () => _showForm(context, account: account),
                      ),
                      const SizedBox(width: 4),
                      _actionIcon(
                        icon: Icons.delete_outline_rounded,
                        color: AppColors.primaryRed,
                        onTap: () => _confirmDelete(context, account, vm),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionIcon({required IconData icon, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 16),
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
            decoration: BoxDecoration(
              color: AppColors.secondaryBackground,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.account_balance_wallet_outlined, size: 48, color: AppColors.grey1),
          ),
          const SizedBox(height: 20),
          const Text("Aucun compte", style: TextStyle(color: AppColors.mainText, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          const Text("Ajoutez votre premier compte bancaire", style: TextStyle(color: AppColors.secondaryText, fontSize: 13)),
        ],
      ),
    );
  }

  void _showForm(BuildContext context, {BankAccount? account}) {
    final vm = context.read<HomeViewModel>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AccountFormSheet(
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
      builder: (_) => AlertDialog(
        title: const Text("Supprimer le compte ?"),
        content: Text("Le compte « ${account.name} » sera supprimé définitivement."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.primaryRed, minimumSize: Size.zero),
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
