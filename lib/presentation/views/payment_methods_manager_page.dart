import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/themes/app_colors.dart';
import '../../data/models/models.dart';
import '../view_models/home_view_model.dart';

class PaymentMethodsManagerPage extends StatelessWidget {
  const PaymentMethodsManagerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HomeViewModel>();

    return Scaffold(
      backgroundColor: AppColors.mainBackground,
      appBar: AppBar(
        title: const Text("Moyens de paiement", style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.mainText)),
        backgroundColor: AppColors.mainBackground,
        scrolledUnderElevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.mainColor,
        onPressed: () => showPaymentMethodFormSheet(context, null),
        label: const Text("Nouveau", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        icon: const Icon(Icons.add, color: Colors.white),
      ),
      body: vm.paymentMethods.isEmpty
          ? const Center(child: Text("Aucun moyen de paiement", style: TextStyle(color: AppColors.secondaryText)))
          : SafeArea(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                itemCount: vm.paymentMethods.length,
                itemBuilder: (context, index) =>
                    _buildTile(context, vm.paymentMethods[index], vm),
              ),
            ),
    );
  }

  Widget _buildTile(BuildContext context, PaymentMethod method, HomeViewModel vm) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.secondaryBackground,
        borderRadius: BorderRadius.circular(20),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.mainColor.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(paymentMethodTypeIcon(method.type), color: AppColors.mainColor, size: 22),
        ),
        title: Text(method.name, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.mainText)),
        subtitle: Text(paymentMethodTypeLabel(method.type), style: const TextStyle(color: AppColors.secondaryText, fontSize: 13)),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: AppColors.grey1),
          color: AppColors.secondaryBackground,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          onSelected: (value) {
            if (value == 'edit') showPaymentMethodFormSheet(context, method);
            if (value == 'delete') _confirmDelete(context, method, vm);
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'edit', child: Text("Modifier", style: TextStyle(color: Colors.white))),
            const PopupMenuItem(value: 'delete', child: Text("Supprimer", style: TextStyle(color: Colors.redAccent))),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, PaymentMethod method, HomeViewModel vm) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.secondaryBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text("Supprimer ?", style: TextStyle(color: AppColors.mainText)),
        content: Text(
          'Supprimer "${method.name}" ?',
          style: const TextStyle(color: AppColors.secondaryText),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Annuler")),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () { vm.deletePaymentMethod(method.id); Navigator.pop(ctx); },
            child: const Text("Supprimer"),
          ),
        ],
      ),
    );
  }
}

IconData paymentMethodTypeIcon(String type) {
  switch (type) {
    case 'credit': return Icons.credit_card_rounded;
    case 'cash': return Icons.payments_rounded;
    case 'transfer': return Icons.swap_horiz_rounded;
    default: return Icons.credit_card_rounded;
  }
}

String paymentMethodTypeLabel(String type) {
  switch (type) {
    case 'credit': return 'Crédit';
    case 'cash': return 'Espèces';
    case 'transfer': return 'Virement';
    default: return 'Débit';
  }
}

/// Ouvre le formulaire de méthode de paiement.
/// Si [onSaveLocal] est fourni, le résultat est retourné localement sans appel API
/// (utile pour le setup). Sinon, sauvegarde directement via [HomeViewModel].
void showPaymentMethodFormSheet(
  BuildContext context,
  PaymentMethod? method, {
  void Function(String name, String type)? onSaveLocal,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => PaymentMethodFormSheet(
      method: method,
      onSaveLocal: onSaveLocal,
    ),
  );
}

class PaymentMethodFormSheet extends StatefulWidget {
  final PaymentMethod? method;
  final void Function(String name, String type)? onSaveLocal;

  const PaymentMethodFormSheet({super.key, this.method, this.onSaveLocal});

  @override
  State<PaymentMethodFormSheet> createState() => _PaymentMethodFormSheetState();
}

class _PaymentMethodFormSheetState extends State<PaymentMethodFormSheet> {
  late final TextEditingController _nameController;
  String _selectedType = 'debit';
  bool _isSubmitting = false;

  static const _types = [
    ('debit', 'Débit'),
    ('credit', 'Crédit'),
    ('cash', 'Espèces'),
    ('transfer', 'Virement'),
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.method?.name ?? '');
    _selectedType = widget.method?.type ?? 'debit';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(bottom: bottomInset),
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
                  width: 36, height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(color: AppColors.thirdBackground, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              Text(
                widget.method != null ? "Modifier le moyen de paiement" : "Nouveau moyen de paiement",
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.mainText),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _nameController,
                autofocus: true,
                style: const TextStyle(color: AppColors.mainText),
                decoration: InputDecoration(
                  hintText: "Nom (ex: Carte Visa, Espèces...)",
                  prefixIcon: const Icon(Icons.label_outline_rounded, color: AppColors.grey1),
                  filled: true,
                  fillColor: AppColors.thirdBackground,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),
              const Text("Type", style: TextStyle(color: AppColors.secondaryText, fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: AppColors.thirdBackground, borderRadius: BorderRadius.circular(16)),
                child: Row(
                  children: _types.map((entry) {
                    final (value, label) = entry;
                    final isSelected = _selectedType == value;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedType = value),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.secondaryBackground : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            label,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: isSelected ? AppColors.mainText : AppColors.grey1,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
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
                  onPressed: _isSubmitting ? null : _submit,
                  child: _isSubmitting
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(widget.method != null ? "Enregistrer" : "Créer", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    if (widget.onSaveLocal != null) {
      widget.onSaveLocal!(name, _selectedType);
      if (mounted) Navigator.pop(context);
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await context.read<HomeViewModel>().savePaymentMethod(
        id: widget.method?.id,
        name: name,
        type: _selectedType,
      );
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}
