import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/database/app_database.dart';
import '../../core/extensions/string_extensions.dart';
import '../../core/notifiers/auth_notifier.dart';
import '../../core/routes/app_routes.dart';
import '../../core/themes/app_colors.dart';
import '../view_models/home_view_model.dart';
import '../widgets/add_transaction_sheet.dart';
import '../widgets/transaction_tile.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeViewModel>().init();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final homeViewModel = context.watch<HomeViewModel>();
    final categories = homeViewModel.categories;

    return Scaffold(
      backgroundColor: AppColors.mainBackground,
      body: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildGlobalBalanceHeader(context, homeViewModel.totalBalance),
          const SliverToBoxAdapter(child: SizedBox(height: 12)),
          _buildAccountSelector(homeViewModel),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Transactions",
                    style: TextStyle(color: AppColors.mainText, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: () => homeViewModel.toggleHideChecked(),
                    icon: Icon(
                      homeViewModel.hideChecked ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                      color: homeViewModel.hideChecked ? AppColors.grey1 : AppColors.mainColor,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverSafeArea(
            top: false,
            sliver: _buildTransactionList(homeViewModel, categories),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTransactionModal(context),
        backgroundColor: AppColors.mainColor,
        elevation: 4,
        label: const Text("Opération", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildGlobalBalanceHeader(BuildContext context, double balance) {
    return SliverAppBar(
      expandedHeight: 160,
      backgroundColor: AppColors.mainBackground,
      pinned: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.bar_chart_rounded, color: AppColors.mainText),
          onPressed: () => context.push(AppRoutes.stats),
        ),
        IconButton(
          icon: const Icon(Icons.settings_outlined, color: AppColors.mainText),
          onPressed: () => context.push(AppRoutes.settings),
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            color: AppColors.secondaryBackground,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(40),
              bottomRight: Radius.circular(40),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              const Text("Solde total disponible", style: TextStyle(color: AppColors.secondaryText, fontSize: 14, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Text(
                "${balance.toStringAsFixed(2)} €",
                style: const TextStyle(color: AppColors.mainText, fontSize: 40, fontWeight: FontWeight.w900),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccountSelector(HomeViewModel vm) {
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 110,
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          scrollDirection: Axis.horizontal,
          itemCount: vm.accounts.length,
          itemBuilder: (context, index) {
            final account = vm.accounts[index];
            final isSelected = vm.selectedAccount?.id == account.id;
            return GestureDetector(
              onTap: () => vm.selectAccount(account),
              child: _buildAccountCard(account, isSelected),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAccountCard(BankAccount account, bool isSelected) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 170,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.mainColor : AppColors.secondaryBackground,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            account.name.capitalize(),
            style: TextStyle(color: isSelected ? Colors.white.withValues(alpha: 0.8) : AppColors.secondaryText, fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            "${account.balance.toStringAsFixed(2)} €",
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionList(HomeViewModel vm, List<Category> categories) {
    final transactions = vm.filteredTransactions;

    if (vm.isLoading && transactions.isEmpty) {
      return const SliverFillRemaining(child: Center(child: CircularProgressIndicator()));
    }

    if (transactions.isEmpty) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: Text("Aucune opération", style: TextStyle(color: AppColors.secondaryText))),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
            (context, index) {
          if (index >= transactions.length) return null;
          final trans = transactions[index];

          final categoryData = categories.firstWhere(
                (c) => c.id == trans.categoryId,
            orElse: () => Category(
              id: 'autre',
              name: 'Autre',
              iconCode: Icons.help_outline_rounded.codePoint.toString(),
              colorValue: AppColors.grey1.toARGB32(),
              userId: '',
            ),
          );

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Dismissible(
              key: Key(trans.id),
              background: _buildSwipeAction(Colors.green, Icons.check_circle, Alignment.centerLeft),
              secondaryBackground: _buildSwipeAction(AppColors.primaryRed, Icons.delete, Alignment.centerRight),
              confirmDismiss: (direction) async {
                if (direction == DismissDirection.startToEnd) {
                  await vm.toggleCheckTransaction(trans);
                  return false;
                }
                return await _showDeleteConfirmation(context);
              },
              onDismissed: (_) => vm.deleteTransaction(trans),
              child: InkWell(
                onTap: () => _showAddTransactionModal(context, transaction: trans),
                borderRadius: BorderRadius.circular(20),
                child: TransactionTile(
                  transaction: trans,
                  categoryIcon: categoryData.iconCode,
                  categoryColor: categoryData.colorValue,
                ),
              ),
            ),
          );
        },
        childCount: transactions.length,
      ),
    );
  }

  Widget _buildSwipeAction(Color color, IconData icon, Alignment alignment) {
    return Container(
      decoration: BoxDecoration(color: color.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Icon(icon, color: color),
    );
  }

  Future<bool?> _showDeleteConfirmation(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.secondaryBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text("Supprimer ?", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text("Cette action est irréversible."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Annuler")),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.primaryRed),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Supprimer"),
          ),
        ],
      ),
    );
  }

  void _showAddTransactionModal(BuildContext context, {Transaction? transaction}) {
    final homeViewModel = context.read<HomeViewModel>();
    final authNotifier = context.read<AuthNotifier>();

    if (homeViewModel.selectedAccount == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Sélectionnez un compte d'abord")));
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddTransactionSheet(
        uid: authNotifier.appUser!.uid,
        accounts: homeViewModel.accounts,
        selectedAccount: homeViewModel.selectedAccount!,
        transaction: transaction,
      ),
    );
  }
}