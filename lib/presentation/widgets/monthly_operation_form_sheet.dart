import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/di.dart';
import '../../core/services/user_service.dart';
import '../../core/themes/app_colors.dart';
import '../../data/models/account_model.dart';
import '../../data/models/category_model.dart';
import '../../data/models/monthly_operation_model.dart';

class MonthlyOperationFormSheet extends StatefulWidget {
  final String uid;
  final List<Account> accounts;
  final MonthlyOperationModel? operation;
  final Function(MonthlyOperationModel) onSave;

  const MonthlyOperationFormSheet({
    super.key,
    required this.uid,
    required this.accounts,
    this.operation,
    required this.onSave,
  });

  @override
  State<MonthlyOperationFormSheet> createState() => _MonthlyOperationFormSheetState();
}

class _MonthlyOperationFormSheetState extends State<MonthlyOperationFormSheet> {
  final _titleController = TextEditingController();
  final List<TextEditingController> _amountControllers = List.generate(12, (_) => TextEditingController());
  final _userService = getIt<IAppUserService>();

  bool _isExpense = true;
  int _dayOfMonth = 1;
  Account? _selectedAccount;
  CategoryModel? _selectedParent;
  CategoryModel? _selectedSub;
  bool _isSubmitting = false;

  final List<String> _months = ["Janv.", "Févr.", "Mars", "Avril", "Mai", "Juin", "Juil.", "Août", "Sept.", "Oct.", "Nov.", "Déc."];

  @override
  void initState() {
    super.initState();
    if (widget.operation != null) {
      _titleController.text = widget.operation!.title;
      _dayOfMonth = widget.operation!.dayOfMonth;
      _isExpense = widget.operation!.isExpense;
      _selectedAccount = widget.accounts.any((a) => a.id == widget.operation!.accountId)
          ? widget.accounts.firstWhere((a) => a.id == widget.operation!.accountId)
          : widget.accounts.isNotEmpty ? widget.accounts.first : null;
      for (int i = 0; i < 12; i++) {
        _amountControllers[i].text = widget.operation!.amounts[i].toStringAsFixed(2);
      }
      _loadInitialCategories();
    } else {
      if (widget.accounts.isNotEmpty) _selectedAccount = widget.accounts.first;
    }
  }

  void _loadInitialCategories() async {
    if (widget.operation == null) return;
    final cats = await _userService.getCategoriesStream(widget.uid).first;
    final current = cats.firstWhere((c) => c.id == widget.operation!.categoryId, orElse: () => cats.first);
    setState(() {
      if (current.parentId == null) {
        _selectedParent = current;
      } else {
        _selectedParent = cats.firstWhere((c) => c.id == current.parentId);
        _selectedSub = current;
      }
    });
  }

  void _applyToAll() {
    final firstAmount = _amountControllers[0].text;
    setState(() {
      for (var controller in _amountControllers) {
        controller.text = firstAmount;
      }
    });
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
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text("Nouvelle Mensualisation", textAlign: TextAlign.center, style: TextStyle(color: AppColors.mainText, fontSize: 18, fontWeight: FontWeight.bold)),
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
                      value: _dayOfMonth,
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
                    child: DropdownButtonFormField<Account>(
                      value: _selectedAccount,
                      isExpanded: true,
                      dropdownColor: AppColors.secondaryBackground,
                      items: widget.accounts.map((a) => DropdownMenuItem(
                          value: a,
                          child: Text(
                            a.name,
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          )
                      )).toList(),
                      onChanged: (val) => setState(() => _selectedAccount = val),
                      decoration: InputDecoration(filled: true, fillColor: AppColors.thirdBackground, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildCategorySection(),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Montants par mois", style: TextStyle(color: AppColors.secondaryText, fontWeight: FontWeight.bold, fontSize: 13)),
                  TextButton.icon(
                    onPressed: _applyToAll,
                    icon: const Icon(Icons.copy_all_rounded, size: 18),
                    label: const Text("Appliquer Janv. partout", style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, childAspectRatio: 1.6, mainAxisSpacing: 10, crossAxisSpacing: 10),
                itemCount: 12,
                itemBuilder: (context, i) => TextField(
                  controller: _amountControllers[i],
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
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.mainText, fontSize: 13, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    labelText: _months[i],
                    hintText: "0.00",
                    hintStyle: const TextStyle(color: AppColors.thirdBackground, fontSize: 12),
                    labelStyle: const TextStyle(color: AppColors.grey1, fontSize: 10),
                    filled: true,
                    fillColor: AppColors.thirdBackground,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                ),
              ),
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
                      : const Text("Enregistrer la mensualisation", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
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

  Widget _buildCategorySection() {
    return StreamBuilder<List<CategoryModel>>(
      stream: _userService.getCategoriesStream(widget.uid),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()));
        final allCats = snapshot.data!;
        final mainCats = allCats.where((c) => c.parentId == null).toList();
        List<CategoryModel> subCats = _selectedParent == null ? [] : allCats.where((c) => c.parentId == _selectedParent!.id).toList();

        if (_selectedParent != null && subCats.isNotEmpty) {
          subCats.add(CategoryModel(
            id: "other_${_selectedParent!.id}",
            name: "Autre",
            parentId: _selectedParent!.id,
            iconCode: _selectedParent!.iconCode,
            colorValue: _selectedParent!.colorValue,
          ));
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Catégorie principale", style: TextStyle(color: AppColors.secondaryText, fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 12),
            _buildHorizontalCategoryList(mainCats, true),
            if (subCats.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Text("Sous-catégorie", style: TextStyle(color: AppColors.secondaryText, fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 12),
              _buildHorizontalCategoryList(subCats, false),
            ],
          ],
        );
      },
    );
  }

  Widget _buildHorizontalCategoryList(List<CategoryModel> categories, bool isParentList) {
    return SizedBox(
      height: 85,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, i) {
          final cat = categories[i];
          final isSelected = isParentList ? _selectedParent?.id == cat.id : _selectedSub?.id == cat.id;
          final color = Color(cat.colorValue);

          return GestureDetector(
            onTap: () => setState(() {
              if (isParentList) {
                if (_selectedParent?.id != cat.id) {
                  _selectedParent = cat;
                  _selectedSub = null;
                }
              } else {
                _selectedSub = (_selectedSub?.id == cat.id) ? null : cat;
              }
            }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 85,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: isSelected ? color.withValues(alpha: 0.15) : AppColors.thirdBackground,
                borderRadius: BorderRadius.circular(20),
                border: isSelected ? Border.all(color: color, width: 2) : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(IconData(cat.iconCode, fontFamily: 'MaterialIcons'), color: isSelected ? color : AppColors.grey1, size: 24),
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(cat.name, style: TextStyle(fontSize: 10, color: isSelected ? AppColors.mainText : AppColors.grey1, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _submit() {
    if (_titleController.text.isEmpty || _selectedAccount == null) return;
    setState(() => _isSubmitting = true);

    final amounts = _amountControllers.map((c) => double.tryParse(c.text.replaceAll(',', '.')) ?? 0.0).toList();
    final op = MonthlyOperationModel(
      id: widget.operation?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      dayOfMonth: _dayOfMonth,
      accountId: _selectedAccount!.id,
      isExpense: _isExpense,
      title: _titleController.text,
      categoryId: _selectedSub?.id ?? _selectedParent?.id ?? "autre",
      amounts: amounts,
    );

    widget.onSave(op);
    Navigator.pop(context);
  }
}