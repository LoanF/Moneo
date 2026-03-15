import 'package:flutter/material.dart';
import '../../core/database/app_database.dart';
import '../../core/helpers/icon_helper.dart';
import '../../core/themes/app_colors.dart';

class MonthlyOperationFormSheet extends StatefulWidget {
  final String uid;
  final MonthlyPayment? operation;
  final List<BankAccount> accounts;
  final List<Category> categories;
  final Function(String name, double amount, String type, int day, String accountId, String? categoryId) onSave;

  const MonthlyOperationFormSheet({
    super.key,
    required this.uid,
    this.operation,
    required this.accounts,
    required this.categories,
    required this.onSave,
  });

  @override
  State<MonthlyOperationFormSheet> createState() => _MonthlyOperationFormSheetState();
}

class _MonthlyOperationFormSheetState extends State<MonthlyOperationFormSheet> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();

  bool _isExpense = true;
  int _dayOfMonth = 1;
  BankAccount? _selectedAccount;
  Category? _selectedParent;
  Category? _selectedSub;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.operation != null) {
      _titleController.text = widget.operation!.name;
      _dayOfMonth = widget.operation!.dayOfMonth;
      _isExpense = widget.operation!.type == 'expense';
      _amountController.text = widget.operation!.amount.toStringAsFixed(2);

      _selectedAccount = widget.accounts.cast<BankAccount?>().firstWhere(
            (a) => a?.id == widget.operation!.accountId,
        orElse: () => widget.accounts.isNotEmpty ? widget.accounts.first : null,
      );

      _loadInitialCategories();
    } else {
      if (widget.accounts.isNotEmpty) _selectedAccount = widget.accounts.first;
    }
  }

  void _loadInitialCategories() {
    if (widget.operation?.categoryId == null) return;

    try {
      final current = widget.categories.firstWhere((c) => c.id == widget.operation!.categoryId);
      setState(() {
        if (current.parentId == null) {
          _selectedParent = current;
        } else {
          _selectedParent = widget.categories.firstWhere((c) => c.id == current.parentId);
          _selectedSub = current;
        }
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag handle
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
                  widget.operation == null ? "Nouvelle mensualisation" : "Modifier la mensualisation",
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.mainText, fontSize: 18, fontWeight: FontWeight.w800)
              ),
              const SizedBox(height: 24),

              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: AppColors.thirdBackground, borderRadius: BorderRadius.circular(16)),
                child: Row(
                  children: [
                    _buildTypeButton("Débit", _isExpense, () => setState(() => _isExpense = true)),
                    _buildTypeButton("Crédit", !_isExpense, () => setState(() => _isExpense = false)),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: _isExpense ? AppColors.mainColor : AppColors.primaryGreen,
                    fontSize: 32,
                    fontWeight: FontWeight.bold
                ),
                decoration: const InputDecoration(
                  hintText: "0.00 €",
                  border: InputBorder.none,
                ),
              ),

              const SizedBox(height: 16),
              TextField(
                controller: _titleController,
                style: const TextStyle(color: AppColors.mainText),
                decoration: InputDecoration(
                  hintText: "Libellé (ex: Loyer, Salaire...)",
                  prefixIcon: const Icon(Icons.edit_note_rounded, color: AppColors.grey1),
                  filled: true,
                  fillColor: AppColors.thirdBackground,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: DropdownButtonFormField<int>(
                      initialValue: _dayOfMonth,
                      isExpanded: true,
                      dropdownColor: AppColors.secondaryBackground,
                      items: List.generate(31, (i) => i + 1).map((d) => DropdownMenuItem(
                          value: d,
                          child: Text("Le $d", style: const TextStyle(color: Colors.white, fontSize: 14))
                      )).toList(),
                      onChanged: (val) => setState(() => _dayOfMonth = val!),
                      decoration: InputDecoration(filled: true, fillColor: AppColors.thirdBackground, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 6,
                    child: DropdownButtonFormField<BankAccount>(
                      initialValue: _selectedAccount,
                      isExpanded: true,
                      dropdownColor: AppColors.secondaryBackground,
                      items: widget.accounts.map((a) => DropdownMenuItem(
                          value: a,
                          child: Text(a.name, style: const TextStyle(color: Colors.white, fontSize: 14))
                      )).toList(),
                      onChanged: (val) => setState(() => _selectedAccount = val),
                      decoration: InputDecoration(filled: true, fillColor: AppColors.thirdBackground, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildCategorySection(),
              const SizedBox(height: 32),

              SizedBox(
                height: 60,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: _isExpense ? AppColors.mainColor : AppColors.primaryGreen,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                  onPressed: _isSubmitting ? null : _submit,
                  child: _isSubmitting
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text("Enregistrer", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySection() {
    final mainCats = widget.categories.where((c) => c.parentId == null).toList();
    List<Category> subCats = _selectedParent == null
        ? []
        : widget.categories.where((c) => c.parentId == _selectedParent!.id).toList();

    if (_selectedParent != null) {
      subCats.add(Category(
        id: "other_${_selectedParent!.id}",
        name: "Autre",
        parentId: _selectedParent!.id,
        iconCode: _selectedParent!.iconCode,
        colorValue: _selectedParent!.colorValue,
        userId: widget.uid,
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Catégorie", style: TextStyle(color: AppColors.secondaryText, fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 12),
        _buildHorizontalCategoryList(mainCats, true),
        if (subCats.isNotEmpty) ...[
          const SizedBox(height: 20),
          _buildHorizontalCategoryList(subCats, false),
        ],
      ],
    );
  }

  Widget _buildHorizontalCategoryList(List<Category> categories, bool isParentList) {
    return SizedBox(
      height: 85,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, i) {
          final cat = categories[i];
          final isSelected = isParentList ? _selectedParent?.id == cat.id : _selectedSub?.id == cat.id;
          return GestureDetector(
            onTap: () => setState(() {
              if (isParentList) {
                _selectedParent = cat;
                _selectedSub = null;
              } else {
                _selectedSub = (_selectedSub?.id == cat.id) ? null : cat;
              }
            }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 85,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: isSelected ? Color(cat.colorValue).withValues(alpha: 0.15) : AppColors.thirdBackground,
                borderRadius: BorderRadius.circular(20),
                border: isSelected ? Border.all(color: Color(cat.colorValue), width: 2) : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                      IconHelper.getIcon(cat.iconCode),
                      color: isSelected ? Color(cat.colorValue) : AppColors.grey1,
                      size: 24
                  ),
                  const SizedBox(height: 4),
                  Text(cat.name, style: const TextStyle(fontSize: 10), maxLines: 1),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTypeButton(String label, bool isSelected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(color: isSelected ? AppColors.secondaryBackground : Colors.transparent, borderRadius: BorderRadius.circular(12)),
          child: Text(label, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? AppColors.mainText : AppColors.grey1, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
        ),
      ),
    );
  }

  void _submit() {
    if (_titleController.text.isEmpty || _selectedAccount == null) return;
    setState(() => _isSubmitting = true);

    widget.onSave(
      _titleController.text,
      double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0.0,
      _isExpense ? 'expense' : 'income',
      _dayOfMonth,
      _selectedAccount!.id,
      _selectedSub?.id ?? _selectedParent?.id,
    );
  }
}