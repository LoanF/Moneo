import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/database/app_database.dart';
import '../../core/themes/app_colors.dart';

class AccountFormSheet extends StatefulWidget {
  final BankAccount? account;
  final Function(String name, double balance) onSave;

  const AccountFormSheet({super.key, this.account, required this.onSave});

  @override
  State<AccountFormSheet> createState() => _AccountFormSheetState();
}

class _AccountFormSheetState extends State<AccountFormSheet> {
  late TextEditingController _nameController;
  late TextEditingController _balanceController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.account?.name ?? "");
    _balanceController = TextEditingController(
      text: widget.account != null ? widget.account!.balance.toStringAsFixed(2) : "",
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.secondaryBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.thirdBackground,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.mainColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.account_balance_wallet_rounded, color: AppColors.mainColor, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    widget.account == null ? "Nouveau compte" : "Modifier le compte",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.mainText),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              TextField(
                controller: _nameController,
                autofocus: true,
                style: const TextStyle(color: AppColors.mainText),
                decoration: const InputDecoration(
                  labelText: "Nom du compte",
                  hintText: "ex : Compte courant",
                  prefixIcon: Icon(Icons.label_outline_rounded, color: AppColors.grey1, size: 20),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _balanceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
                  TextInputFormatter.withFunction((oldValue, newValue) {
                    final text = newValue.text.replaceAll(',', '.');
                    if (RegExp(r'^\d*\.?\d{0,2}$').hasMatch(text)) {
                      return newValue.copyWith(text: text, selection: newValue.selection);
                    }
                    return oldValue;
                  }),
                ],
                style: const TextStyle(color: AppColors.mainText),
                decoration: const InputDecoration(
                  labelText: "Solde de départ",
                  hintText: "0.00",
                  prefixIcon: Icon(Icons.euro_rounded, color: AppColors.grey1, size: 20),
                  suffixText: "€",
                ),
              ),
              const SizedBox(height: 28),
              FilledButton(
                onPressed: _submit,
                child: const Text("Enregistrer"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (_nameController.text.trim().isEmpty) return;
    widget.onSave(
      _nameController.text.trim(),
      double.tryParse(_balanceController.text.replaceAll(',', '.')) ?? 0.0,
    );
    Navigator.pop(context);
  }
}
