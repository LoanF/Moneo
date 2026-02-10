import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/database/app_database.dart';
import '../../core/di.dart';
import '../../core/repositories/category_repository.dart';
import '../../core/services/user_service.dart';
import '../../core/themes/app_colors.dart';
import '../view_models/home_view_model.dart';

class AddTransactionSheet extends StatefulWidget {
  final String uid;
  final List<BankAccount> accounts;
  final BankAccount selectedAccount;
  final Transaction? transaction;

  const AddTransactionSheet({
    super.key,
    required this.uid,
    required this.accounts,
    required this.selectedAccount,
    this.transaction,
  });

  @override
  State<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<AddTransactionSheet> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _userService = getIt<IAppUserService>();

  bool _isExpense = true;
  bool _isTransfer = false;
  Category? _selectedParent;
  Category? _selectedSub;
  BankAccount? _targetAccount;
  DateTime _selectedDate = DateTime.now();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.transaction != null) {
      _titleController.text = widget.transaction!.note ?? "";
      _amountController.text = widget.transaction!.amount.abs().toStringAsFixed(2);
      _isExpense = widget.transaction!.amount < 0;
      _selectedDate = widget.transaction!.date;
      _isTransfer = widget.transaction!.categoryId == 'transfert';

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _setInitialCategory();
      });
    }
  }

  void _setInitialCategory() {
    if (widget.transaction?.categoryId == null || _isTransfer) return;

    final categories = context.read<HomeViewModel>().categories;
    final categoryId = widget.transaction!.categoryId!;

    try {
      if (categoryId.startsWith('other_')) {
        final parentId = categoryId.replaceFirst('other_', '');
        _selectedParent = categories.firstWhere((c) => c.id == parentId);
        _selectedSub = null;
      } else {
        final currentCat = categories.firstWhere((c) => c.id == categoryId);

        if (currentCat.parentId == null) {
          _selectedParent = currentCat;
          _selectedSub = null;
        } else {
          _selectedParent = categories.firstWhere((c) => c.id == currentCat.parentId);
          _selectedSub = currentCat;
        }
      }
      setState(() {});
    } catch (e) {
      // Catégorie non trouvée dans la liste, on ne fait rien
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.mainColor,
              onPrimary: Colors.white,
              surface: AppColors.secondaryBackground,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                "Montant de l'opération",
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.grey1, fontSize: 13, fontWeight: FontWeight.w500),
              ),
              TextField(
                controller: _amountController,
                autofocus: widget.transaction != null ? false : true,
                textAlign: TextAlign.center,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: TextStyle(
                  color: _isTransfer ? Colors.blueAccent : (_isExpense ? AppColors.mainColor : AppColors.primaryGreen),
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                ),
                decoration: const InputDecoration(
                  hintText: "0.00 €",
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: AppColors.thirdBackground),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.thirdBackground,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    _buildTypeButton("Débit", _isExpense && !_isTransfer, () {
                      setState(() { _isExpense = true; _isTransfer = false; });
                    }),
                    _buildTypeButton("Crédit", !_isExpense && !_isTransfer, () {
                      setState(() { _isExpense = false; _isTransfer = false; });
                    }),
                    _buildTypeButton("Transfert", _isTransfer, () {
                      setState(() { _isTransfer = true; _isExpense = true; });
                    }),
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
              InkWell(
                onTap: _selectDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.thirdBackground,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, color: AppColors.grey1, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        DateFormat.yMMMMd().format(_selectedDate),
                        style: const TextStyle(color: AppColors.mainText, fontWeight: FontWeight.w500),
                      ),
                      const Spacer(),
                      const Icon(Icons.edit_calendar_rounded, color: AppColors.mainColor, size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (_isTransfer) ...[
                const Text("Vers le compte", style: TextStyle(color: AppColors.secondaryText, fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 12),
                _buildAccountDropdown(),
              ] else ...[
                _buildCategorySection(),
              ],
              const SizedBox(height: 32),
              SizedBox(
                height: 60,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: _isTransfer ? Colors.blueAccent : (_isExpense ? AppColors.mainColor : AppColors.primaryGreen),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                  onPressed: _isSubmitting ? null : _submit,
                  child: _isSubmitting
                      ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                  ) : const Text("Valider l'opération", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
          decoration: BoxDecoration(
            color: isSelected ? AppColors.secondaryBackground : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? AppColors.mainText : AppColors.grey1,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAccountDropdown() {
    final others = widget.accounts.where((a) => a.id != widget.selectedAccount.id).toList();
    return DropdownButtonFormField<BankAccount>(
      dropdownColor: AppColors.secondaryBackground,
      initialValue: _targetAccount ?? (others.isNotEmpty ? others.first : null),
      items: others.map((a) => DropdownMenuItem(value: a, child: Text(a.name, style: const TextStyle(color: Colors.white)))).toList(),
      onChanged: (val) => setState(() => _targetAccount = val),
      decoration: InputDecoration(
        filled: true,
        fillColor: AppColors.thirdBackground,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildCategorySection() {
    return StreamBuilder<List<Category>>(
      stream: getIt<CategoryRepository>().watchCategories(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox(height: 150, child: Center(child: CircularProgressIndicator()));

        final allCats = snapshot.data!;
        final mainCats = allCats.where((c) => c.parentId == null).toList();
        List<Category> subCats = _selectedParent == null ? [] : allCats.where((c) => c.parentId == _selectedParent!.id).toList();

        if (_selectedParent != null && subCats.isNotEmpty) {
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

  Widget _buildHorizontalCategoryList(List<Category> categories, bool isParentList) {
    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, i) {
          final cat = categories[i];
          final isSelected = isParentList ? _selectedParent?.id == cat.id : _selectedSub?.id == cat.id;
          final color = Color(cat.colorValue);

          return GestureDetector(
            onTap: () {
              setState(() {
                if (isParentList) {
                  if (_selectedParent?.id == cat.id) {
                  } else {
                    _selectedParent = cat;
                    _selectedSub = null;
                  }
                } else {
                  if (_selectedSub?.id == cat.id) {
                    _selectedSub = null;
                  } else {
                    _selectedSub = cat;
                  }
                }
              });
            },
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
                  Icon(
                    IconData(cat.iconCode, fontFamily: 'MaterialIcons'),
                    color: isSelected ? color : AppColors.grey1,
                    size: 24,
                  ),
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      cat.name,
                      style: TextStyle(
                        fontSize: 10,
                        color: isSelected ? AppColors.mainText : AppColors.grey1,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _submit() async {
    if (_isSubmitting) return;
    
    final homeViewModel = context.read<HomeViewModel>();
    final amount = double.tryParse(_amountController.text.replaceAll(',', '.'))?.abs() ?? 0;

    if (amount <= 0) return;

    setState(() => _isSubmitting = true);

    try {
      if (_isTransfer) {
        if (_targetAccount != null) {
          await homeViewModel.addTransfer(
            sourceAccount: widget.selectedAccount,
            targetAccount: _targetAccount!,
            title: _titleController.text.isEmpty ? "Transfert" : _titleController.text,
            amount: amount,
          );
        }
      } else {
        final finalAmount = _isExpense ? -amount : amount;
        String? finalCategoryId;
        if (_selectedParent != null) {
          finalCategoryId = _selectedSub?.id ?? _selectedParent!.id;
        }

        if (widget.transaction != null) {
          await homeViewModel.updateTransaction(widget.transaction!.copyWith(
            amount: finalAmount,
            note: Value(_titleController.text),
            categoryId: Value(finalCategoryId),
            date: _selectedDate,
          ));
        } else {
          await homeViewModel.addTransaction(
            title: _titleController.text,
            amount: finalAmount,
            type: _isExpense ? 'expense' : 'income',
            categoryId: finalCategoryId,
            date: _selectedDate,
          );
        }
      }
      
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}