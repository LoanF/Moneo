import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/routes/app_routes.dart';
import '../../core/themes/app_colors.dart';
import '../../data/constants/assets.dart';
import '../view_models/auth_view_model.dart';

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
    {'name': 'Espèces', 'type': 'Débit'},
    {'name': 'Carte Bancaire', 'type': 'Débit'},
    {'name': 'Virement', 'type': 'Débit'},
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
            separatorBuilder: (_, __) => const SizedBox(height: 12),
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
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppColors.error),
                  onPressed: () => setState(() => _accounts.removeAt(index)),
                ),
              ),
            ),
          ),

          if (_accounts.isEmpty)
            _buildEmptyState(Icons.account_balance, "Aucun compte ajouté"),

          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _showAddAccountDialog,
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
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final method = _paymentMethods[index];
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.secondaryBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      method['type'] == 'Débit' ? Icons.arrow_downward : Icons.credit_card,
                      color: method['type'] == 'Débit' ? Colors.green : Colors.orange,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(method['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text(method['type'], style: const TextStyle(fontSize: 12, color: AppColors.secondaryText)),
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
            onPressed: _showAddPaymentMethodDialog,
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

  void _showAddAccountDialog() {
    final nameController = TextEditingController();
    final balanceController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Ajouter un compte", style: TextStyle(fontSize: 20)),
        backgroundColor: AppColors.secondaryBackground,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Nom (ex: Compte Courant)", labelStyle: TextStyle(fontSize: 13)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: balanceController,
              decoration: const InputDecoration(labelText: "Solde initial (€)", suffixText: "€", labelStyle: TextStyle(fontSize: 13)),
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
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
          FilledButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                setState(() => _accounts.add({
                  'name': nameController.text,
                  'balance': double.tryParse(balanceController.text) ?? 0.0
                }));
                Navigator.pop(context);
              }
            },
            child: const Text("Ajouter"),
          ),
        ],
      ),
    );
  }

  void _showAddPaymentMethodDialog() {
    final nameController = TextEditingController();
    String selectedType = 'Débit';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Moyen de paiement", style: TextStyle(fontSize: 20)),
          backgroundColor: AppColors.secondaryBackground,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Nom du moyen (ex: AMEX)", labelStyle: TextStyle(fontSize: 13)),
              ),
              const SizedBox(height: 24),
              const Text("Type de prélèvement :", style: TextStyle(fontSize: 14, color: AppColors.secondaryText)),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'Débit', label: Text('Débit'), icon: Icon(Icons.arrow_downward)),
                  ButtonSegment(value: 'Crédit', label: Text('Crédit'), icon: Icon(Icons.credit_card)),
                ],
                selected: {selectedType},
                onSelectionChanged: (newSelection) {
                  setDialogState(() => selectedType = newSelection.first);
                },
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                    if (states.contains(WidgetState.selected)) {
                      return selectedType == 'Débit'
                          ? AppColors.primaryRed
                          : AppColors.primaryGreen;
                    }
                    return Colors.transparent;
                  }),
                  foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                    if (states.contains(WidgetState.selected)) {
                      return Colors.white;
                    }
                    return AppColors.secondaryText;
                  }),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
            FilledButton(
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  setState(() => _paymentMethods.add({
                    'name': nameController.text,
                    'type': selectedType
                  }));
                  Navigator.pop(context);
                }
              },
              child: const Text("Ajouter"),
            ),
          ],
        ),
      ),
    );
  }
}