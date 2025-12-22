import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/notifiers/auth_notifier.dart';
import '../../core/routes/app_routes.dart';
import '../../core/themes/app_colors.dart';
import '../../data/models/account_model.dart';
import '../view_models/home_view_model.dart';
import '../widgets/transaction_tile.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authNotifier = context.read<AuthNotifier>();
      final homeViewModel = context.read<HomeViewModel>();

      if (authNotifier.appUser != null) {
        homeViewModel.init(authNotifier.appUser!.uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final homeViewModel = context.watch<HomeViewModel>();
    final authNotifier = context.watch<AuthNotifier>();
    final uid = authNotifier.appUser?.uid ?? "";

    return Scaffold(
      backgroundColor: AppColors.mainBackground,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildGlobalBalanceHeader(context, homeViewModel.totalBalance),
          _buildAccountSelector(uid, homeViewModel),

          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(24, 12, 24, 12),
              child: Text(
                "Transactions récentes",
                style: TextStyle(color: AppColors.mainText, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),

          SliverSafeArea(
            top: false,
            sliver: _buildTransactionList(homeViewModel),
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: 80),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTransactionModal(context),
        backgroundColor: AppColors.mainColor,
        label: const Text(
          "Opération",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        icon: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildGlobalBalanceHeader(BuildContext context, double balance) {
    return SliverAppBar(
      expandedHeight: 150,
      backgroundColor: AppColors.mainBackground,
      floating: false,
      pinned: true,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppColors.mainText),
            onPressed: () {
              context.push(AppRoutes.settings);
            },
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: AppColors.secondaryBackground,
            borderRadius: BorderRadius.only(bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 15),
              const Text("Solde Global", style: TextStyle(color: AppColors.secondaryText, fontSize: 16)),
              const SizedBox(height: 8),
              Text(
                "${balance.toStringAsFixed(2)} €",
                style: const TextStyle(color: AppColors.mainText, fontSize: 36, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccountSelector(String uid, HomeViewModel vm) {
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 100,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: vm.accounts.length,
          itemBuilder: (context, index) {
            final account = vm.accounts[index];
            final isSelected = vm.selectedAccount?.id == account.id;
            return GestureDetector(
              onTap: () {
                final uid = context.read<AuthNotifier>().appUser?.uid;
                if (uid != null) {
                  vm.selectAccount(uid, account);
                }
              },
              child: _buildAccountCard(account.name, account.currentBalance, isSelected),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAccountCard(String name, double amount, bool isSelected) {
    return Container(
      width: 160,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: isSelected ? AppColors.mainColor : AppColors.thirdBackground, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(name, style: TextStyle(color: isSelected ? Colors.white : AppColors.secondaryText, fontSize: 12)),
          Text(
            "${amount.toStringAsFixed(2)} €",
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionList(HomeViewModel vm) {
    final authNotifier = context.read<AuthNotifier>();
    final uid = authNotifier.appUser?.uid ?? "";

    if (vm.transactions.isEmpty) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: Text("Aucune transaction", style: TextStyle(color: AppColors.secondaryText))),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
            (context, index) {
          final trans = vm.transactions[index];

          return Dismissible(
            key: Key(trans.id),
            background: Container(
              color: Colors.green.withValues(alpha: 0.8),
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: const Icon(Icons.check_circle_outline, color: Colors.white),
            ),
            secondaryBackground: Container(
              color: AppColors.primaryRed.withValues(alpha: 0.8),
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: const Icon(Icons.delete_outline, color: Colors.white),
            ),
            confirmDismiss: (direction) async {
              if (direction == DismissDirection.startToEnd) {
                await vm.toggleCheckTransaction(uid, vm.selectedAccount!.id, trans.id, trans.isChecked);
                return false;
              } else {
                return await _showDeleteConfirmation(context);
              }
            },
            onDismissed: (direction) {
              if (direction == DismissDirection.endToStart) {
                vm.deleteTransaction(uid, vm.selectedAccount!.id, trans);
              }
            },
            child: TransactionTile(transaction: trans),
          );
        },
        childCount: vm.transactions.length,
      ),
    );
  }

  Future<bool?> _showDeleteConfirmation(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.secondaryBackground,
        title: const Text("Supprimer ?", style: TextStyle(color: Colors.white)),
        content: const Text("Cette action est irréversible et mettra à jour votre solde."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Annuler")),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Supprimer", style: TextStyle(color: AppColors.primaryRed)),
          ),
        ],
      ),
    );
  }

  void _showAddTransactionModal(BuildContext context) {
    final homeViewModel = context.read<HomeViewModel>();
    final authNotifier = context.read<AuthNotifier>();

    final titleController = TextEditingController();
    final amountController = TextEditingController();

    final List<String> categories = ["Alimentation", "Loisirs", "Logement", "Transport", "Santé", "Salaire", "Cadeau", "Transfert", "Autre"];

    bool isExpense = true;
    String selectedCategory = categories.first;

    bool isTransfer = false;
    Account? targetAccount;

    if (homeViewModel.selectedAccount == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Veuillez sélectionner un compte d'abord")));
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.secondaryBackground,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => SafeArea(
        child: StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      "Nouvelle Opération",
                      style: TextStyle(color: AppColors.mainText, fontSize: 20, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),

                    TextField(
                      controller: titleController,
                      style: const TextStyle(color: AppColors.mainText),
                      decoration: InputDecoration(
                        labelText: "Libellé (ex: Courses, Salaire)",
                        labelStyle: const TextStyle(color: AppColors.secondaryText),
                        filled: true,
                        fillColor: AppColors.thirdBackground,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ChoiceChip(
                          label: const Text("Débit"),
                          selected: isExpense,
                          selectedColor: AppColors.primaryRed.withValues(alpha: 0.2),
                          labelStyle: TextStyle(color: isExpense ? AppColors.primaryRed : AppColors.secondaryText),
                          onSelected: (val) => setState(() => isExpense = true),
                        ),
                        const SizedBox(width: 16),
                        ChoiceChip(
                          label: const Text("Crédit"),
                          selected: !isExpense,
                          selectedColor: Colors.greenAccent.withValues(alpha: 0.2),
                          labelStyle: TextStyle(color: !isExpense ? Colors.greenAccent : AppColors.secondaryText),
                          onSelected: (val) => setState(() => isExpense = false),
                        ),
                        const SizedBox(width: 16),
                        ChoiceChip(
                          label: const Text("Transfert"),
                          selected: isTransfer,
                          selectedColor: Colors.blueAccent.withValues(alpha: 0.2),
                          labelStyle: TextStyle(color: isTransfer ? Colors.blueAccent : AppColors.secondaryText),
                          onSelected: (val) {
                            setState(() {
                              isTransfer = val;
                              if (val) {
                                isExpense = true;
                                selectedCategory = "Transfert";
                              }
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                    const SizedBox(height: 24),

                    if (isTransfer) ...[
                      const SizedBox(height: 16),
                      const Text("Vers le compte", style: TextStyle(color: AppColors.secondaryText, fontSize: 14)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<Account>(
                        dropdownColor: AppColors.secondaryBackground,
                        initialValue: targetAccount ?? homeViewModel.accounts.firstWhere((acc) => acc.id != homeViewModel.selectedAccount?.id),
                        items: homeViewModel.accounts
                            .where((acc) => acc.id != homeViewModel.selectedAccount?.id)
                            .map((acc) => DropdownMenuItem(value: acc, child: Text(acc.name, style: const TextStyle(color: Colors.white))))
                            .toList(),
                        onChanged: (val) => setState(() => targetAccount = val),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppColors.thirdBackground,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),

                    const Text("Catégorie", style: TextStyle(color: AppColors.secondaryText, fontSize: 14)),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 50,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: categories.length,
                        itemBuilder: (context, index) {
                          final cat = categories[index];
                          final isSelected = selectedCategory == cat;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(cat),
                              selected: isSelected,
                              onSelected: (val) => setState(() => selectedCategory = cat),
                              backgroundColor: AppColors.thirdBackground,
                              selectedColor: AppColors.mainColor,
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.white : AppColors.secondaryText,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                              checkmarkColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),

                    TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(color: AppColors.mainText),
                      decoration: InputDecoration(
                        labelText: "Montant (€)",
                        hintText: "0.00",
                        labelStyle: const TextStyle(color: AppColors.secondaryText),
                        filled: true,
                        fillColor: AppColors.thirdBackground,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 24),

                    ElevatedButton(
                      onPressed: () async {
                        final title = titleController.text.trim();
                        double amount = double.tryParse(amountController.text.replaceAll(',', '.'))?.abs() ?? 0;

                        if (amount <= 0) return;

                        if (isTransfer) {
                          if (targetAccount != null) {
                            await homeViewModel.addTransfer(
                              uid: authNotifier.appUser!.uid,
                              sourceAccountId: homeViewModel.selectedAccount!.id,
                              targetAccountId: targetAccount!.id,
                              title: title.isEmpty ? "Transfert" : title,
                              amount: amount,
                            );
                          }
                        } else {
                          if (isExpense) amount = -amount;
                          await homeViewModel.addTransaction(
                            uid: authNotifier.appUser!.uid,
                            accountId: homeViewModel.selectedAccount!.id,
                            title: title,
                            amount: amount,
                            category: selectedCategory,
                          );
                        }
                        if (context.mounted) Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.mainColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text(
                        "Ajouter la transaction",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
