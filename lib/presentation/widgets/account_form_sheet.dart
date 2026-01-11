import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/themes/app_colors.dart';
import '../../data/models/account_model.dart';

class AccountFormSheet extends StatefulWidget {
  final Account? account;
  final Function(Account) onSave;

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
    _nameController = TextEditingController(text: widget.account?.name);
    _balanceController = TextEditingController(
        text: widget.account != null ? widget.account!.initialBalance.toStringAsFixed(2) : ""
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                      widget.account == null ? "Ajouter un compte" : "Modifier le compte",
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.mainText)
                  ),
                  IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: AppColors.grey1)
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _nameController,
                autofocus: true,
                style: const TextStyle(color: AppColors.mainText),
                decoration: InputDecoration(
                  labelText: "Nom du compte",
                  hintText: "ex: Compte Courant",
                  filled: true,
                  fillColor: AppColors.thirdBackground,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _balanceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
                  TextInputFormatter.withFunction((oldValue, newValue) {
                    final newText = newValue.text.replaceAll(',', '.');
                    if (RegExp(r'^\d*\.?\d{0,2}$').hasMatch(newText)) {
                      return newValue.copyWith(
                        text: newText,
                        selection: newValue.selection,
                      );
                    }

                    return oldValue;
                  }),
                ],
                style: const TextStyle(color: AppColors.mainText),
                decoration: InputDecoration(
                  labelText: "Solde de départ",
                  hintText: "0.00",
                  hintStyle: const TextStyle(color: AppColors.grey1),
                  suffixText: "€",
                  filled: true,
                  fillColor: AppColors.thirdBackground,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                      backgroundColor: AppColors.mainColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                  ),
                  onPressed: _submit,
                  child: const Text("Enregistrer", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (_nameController.text.isEmpty) return;

    final name = _nameController.text;
    final initialBalance = double.tryParse(_balanceController.text.replaceAll(',', '.')) ?? 0.0;

    Account account;
    if (widget.account == null) {
      final id = "${DateTime.now().millisecondsSinceEpoch}_$name";
      account = Account(
        id: id,
        name: name,
        initialBalance: initialBalance,
        currentBalance: initialBalance,
      );
    } else {
      final balanceDiff = initialBalance - widget.account!.initialBalance;
      account = Account(
        id: widget.account!.id,
        name: name,
        initialBalance: initialBalance,
        currentBalance: widget.account!.currentBalance + balanceDiff,
      );
    }

    widget.onSave(account);
    Navigator.pop(context);
  }
}