import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/routes/app_routes.dart';
import '../../core/themes/app_colors.dart';
import '../../data/constants/assets.dart';
import '../view_models/auth_view_model.dart';
import 'payment_methods_manager_page.dart';

class SetupPage extends StatefulWidget {
  const SetupPage({super.key});

  @override
  State<SetupPage> createState() => _SetupPageState();
}

class _SetupPageState extends State<SetupPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _accounts = [];

  final List<Map<String, dynamic>> _paymentMethods = [
    {'name': 'Espèces', 'type': 'cash'},
    {'name': 'Carte Bancaire', 'type': 'debit'},
    {'name': 'Virement', 'type': 'transfer'},
    {'name': 'Chèque', 'type': 'cheque'},
    {'name': 'Crédit', 'type': 'credit'},
  ];

  void _completeSetup() async {
    final viewModel = context.read<AuthViewModel>();

    final bool success = await viewModel.completeSetup(
      accounts: _accounts,
      paymentMethods: _paymentMethods,
    );

    if (!mounted) return;

    if (success) {
      context.go(AppRoutes.home);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(viewModel.errorMessage ?? "Une erreur est survenue"),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: LinearProgressIndicator(
                value: (_currentPage + 1) / 3,
                backgroundColor: AppColors.secondaryBackground,
                color: AppColors.mainColor,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (int page) => setState(() => _currentPage = page),
                children: [
                  _buildWelcomeStep(),
                  _buildAccountsStep(),
                  _buildPaymentsStep(),
                ],
              ),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(AppAssets.logo, height: 180),
          const SizedBox(height: 48),
          Text(
            "Bienvenue sur Moneo",
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text(
            "Prenons un instant pour configurer vos comptes et vos habitudes de paiement.",
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.secondaryText, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text("Vos comptes", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text("Définissez vos comptes bancaires de départ.", style: TextStyle(color: AppColors.secondaryText)),
          const SizedBox(height: 24),

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _accounts.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) => Card(
              color: AppColors.secondaryBackground,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.mainColor,
                  child: Icon(Icons.wallet, color: AppColors.black),
                ),
                title: Text(_accounts[index]['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("${_accounts[index]['balance'].toStringAsFixed(2)} €"),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: AppColors.mainColor),
                      onPressed: () => _showAddAccountDialog(editIndex: index),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: AppColors.error),
                      onPressed: () => setState(() => _accounts.removeAt(index)),
                    ),
                  ],
                ),
              ),
            ),
          ),

          if (_accounts.isEmpty)
            _buildEmptyState(Icons.account_balance, "Aucun compte ajouté"),

          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => _showAddAccountDialog(),
            icon: const Icon(Icons.add),
            label: const Text("Ajouter un compte bancaire"),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text("Moyens de paiement", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text("Quels modes de paiement utilisez-vous par défaut ?", style: TextStyle(color: AppColors.secondaryText)),
          const SizedBox(height: 24),

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _paymentMethods.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final method = _paymentMethods[index];
              final type = method['type'] as String;
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.secondaryBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(paymentMethodTypeIcon(type), color: AppColors.mainColor, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(method['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text(paymentMethodTypeLabel(type), style: const TextStyle(fontSize: 12, color: AppColors.secondaryText)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => setState(() => _paymentMethods.removeAt(index)),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => showPaymentMethodFormSheet(
              context,
              null,
              onSaveLocal: (name, type) => setState(() => _paymentMethods.add({'name': name, 'type': type})),
            ),
            icon: const Icon(Icons.add_card),
            label: const Text("Nouveau moyen de paiement"),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(IconData icon, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: AppColors.secondaryBackground),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(color: AppColors.secondaryText)),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.secondaryBackground, width: 0.5)),
      ),
      child: Row(
        children: [
          if (_currentPage > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: () => _pageController.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut
                ),
                child: const Text("Précédent"),
              ),
            ),
          if (_currentPage > 0) const SizedBox(width: 16),
          Expanded(
            child: FilledButton(
              onPressed: () {
                if (_currentPage < 2) {
                  if (_currentPage == 1 && _accounts.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Veuillez ajouter au moins un compte"),
                        backgroundColor: AppColors.error,
                      ),
                    );
                    return;
                  }
                  _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                } else {
                  _completeSetup();
                }
              },
              child: Text(_currentPage == 2 ? "Finaliser" : "Continuer"),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddAccountDialog({int? editIndex}) {
    final existing = editIndex != null ? _accounts[editIndex] : null;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AccountFormSheet(
        initialName: existing?['name'] ?? '',
        initialBalance: existing != null ? (existing['balance'] as double).toStringAsFixed(2) : '',
        isEdit: editIndex != null,
        onSave: (name, balance) {
          setState(() {
            final data = {'name': name, 'balance': balance};
            if (editIndex != null) {
              _accounts[editIndex] = data;
            } else {
              _accounts.add(data);
            }
          });
        },
      ),
    );
  }
}

class _AccountFormSheet extends StatefulWidget {
  final String initialName;
  final String initialBalance;
  final bool isEdit;
  final void Function(String name, double balance) onSave;

  const _AccountFormSheet({
    required this.initialName,
    required this.initialBalance,
    required this.isEdit,
    required this.onSave,
  });

  @override
  State<_AccountFormSheet> createState() => _AccountFormSheetState();
}

class _AccountFormSheetState extends State<_AccountFormSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _balanceController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _balanceController = TextEditingController(text: widget.initialBalance);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    final balance = double.tryParse(_balanceController.text.replaceAll(',', '.')) ?? 0.0;
    widget.onSave(name, balance);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
        color: AppColors.secondaryBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: AppColors.thirdBackground,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                widget.isEdit ? "Modifier le compte" : "Ajouter un compte",
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.mainText),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _nameController,
                autofocus: true,
                maxLength: 30,
                style: const TextStyle(color: AppColors.mainText),
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  hintText: "Nom (ex: Compte Courant)",
                  prefixIcon: const Icon(Icons.account_balance_outlined, color: AppColors.grey1),
                  filled: true,
                  fillColor: AppColors.thirdBackground,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.mainColor, width: 1.5),
                  ),
                  counterText: '',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _balanceController,
                style: const TextStyle(color: AppColors.mainText),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
                  TextInputFormatter.withFunction((oldValue, newValue) {
                    final newText = newValue.text.replaceAll(',', '.');
                    if (RegExp(r'^\d*\.?\d{0,2}$').hasMatch(newText)) {
                      return newValue.copyWith(text: newText, selection: newValue.selection);
                    }
                    return oldValue;
                  }),
                ],
                decoration: InputDecoration(
                  hintText: "Solde initial",
                  prefixIcon: const Icon(Icons.euro_rounded, color: AppColors.grey1),
                  suffixText: "€",
                  filled: true,
                  fillColor: AppColors.thirdBackground,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.mainColor, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 56,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.mainColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _submit,
                  child: Text(
                    widget.isEdit ? "Enregistrer" : "Ajouter",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}