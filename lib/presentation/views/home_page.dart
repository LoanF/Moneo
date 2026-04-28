import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import '../../core/di.dart';
import '../../core/services/tutorial_service.dart';
import '../../data/models/models.dart';
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

  final _balanceKey = GlobalKey();
  final _accountSelectorKey = GlobalKey();
  final _fabKey = GlobalKey();
  final _visibilityKey = GlobalKey();
  final _statsKey = GlobalKey();
  final _settingsKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    getIt<TutorialService>().showNow.addListener(_onShowNow);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<HomeViewModel>().init();
      _maybeShowTutorial();
    });
  }

  void _onShowNow() {
    final service = getIt<TutorialService>();
    if (!service.showNow.value) return;
    service.showNow.value = false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _showTutorial();
    });
  }

  Future<void> _maybeShowTutorial() async {
    final tutorialService = getIt<TutorialService>();
    if (!await tutorialService.shouldShowTutorial()) return;
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _showTutorial();
    });
  }

  Future<void> _showTutorial() async {
    if (_scrollController.hasClients && _scrollController.offset > 0) {
      await _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
      );
    }
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    TutorialCoachMark(
      targets: _buildTargets(),
      colorShadow: Colors.black,
      opacityShadow: 0.85,
      textSkip: "Passer",
      alignSkip: Alignment.bottomLeft,
      paddingFocus: 8,
      onFinish: () => getIt<TutorialService>().markTutorialSeen(),
      onSkip: () {
        getIt<TutorialService>().markTutorialSeen();
        return true;
      },
    ).show(context: context);
  }

  TargetPosition? _renderBoxPosition(GlobalKey key) {
    final rb = key.currentContext?.findRenderObject() as RenderBox?;
    if (rb == null) return null;
    return TargetPosition(rb.size, rb.localToGlobal(Offset.zero));
  }

  List<TargetFocus> _buildTargets() {
    return [
      TargetFocus(
        identify: "balance",
        targetPosition: _renderBoxPosition(_balanceKey),
        shape: ShapeLightFocus.RRect,
        radius: 20,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: _TutorialCard(
              step: "1 / 6",
              title: "Solde global",
              description:
                  "La somme de tous vos comptes en un coup d'œil.\n\nLe solde « pointé » correspond aux transactions que vous avez vérifiées, utile pour rapprocher votre relevé bancaire.",
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: "accounts",
        keyTarget: _accountSelectorKey,
        shape: ShapeLightFocus.RRect,
        radius: 24,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: _TutorialCard(
              step: "2 / 6",
              title: "Vos comptes",
              description:
                  "Appuyez sur un compte pour filtrer ses transactions.\n\nMaintenez enfoncé et glissez pour réorganiser l'ordre des cartes.",
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: "fab",
        keyTarget: _fabKey,
        shape: ShapeLightFocus.RRect,
        radius: 20,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: _TutorialCard(
              step: "3 / 6",
              title: "Nouvelle opération",
              description:
                  "Ajoutez une dépense, un revenu ou un transfert entre comptes.\n\nVous pouvez choisir une catégorie, un moyen de paiement et modifier la date.",
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: "visibility",
        keyTarget: _visibilityKey,
        shape: ShapeLightFocus.Circle,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: _TutorialCard(
              step: "4 / 6",
              title: "Pointage",
              description:
                  "Glissez une transaction vers la droite pour la pointer (marquée comme vérifiée).\n\nGlissez vers la gauche pour la supprimer.\n\nCe bouton masque ou affiche les transactions déjà pointées.",
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: "stats",
        keyTarget: _statsKey,
        shape: ShapeLightFocus.Circle,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: _TutorialCard(
              step: "5 / 6",
              title: "Statistiques",
              description:
                  "Visualisez vos dépenses et revenus par catégorie.\n\nSuivez l'évolution mensuelle de votre budget avec des graphiques détaillés.",
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: "settings",
        keyTarget: _settingsKey,
        shape: ShapeLightFocus.Circle,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: _TutorialCard(
              step: "6 / 6",
              title: "Paramètres",
              description:
                  "Gérez vos mensualisations (loyer, abonnements...) ajoutées automatiquement chaque mois, ainsi que vos catégories, moyens de paiement et comptes.",
            ),
          ),
        ],
      ),
    ];
  }

  @override
  void dispose() {
    getIt<TutorialService>().showNow.removeListener(_onShowNow);
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
          _buildGlobalBalanceHeader(context, homeViewModel.totalBalance, homeViewModel.totalPointedBalance),
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
                    key: _visibilityKey,
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
        key: _fabKey,
        onPressed: () => _showAddTransactionModal(context),
        backgroundColor: AppColors.mainColor,
        elevation: 4,
        label: const Text("Opération", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildGlobalBalanceHeader(BuildContext context, double balance, double pointedBalance) {
    final showPointed = (balance - pointedBalance).abs() > 0.005;
    return SliverAppBar(
      expandedHeight: showPointed ? 185 : 160,
      backgroundColor: AppColors.mainBackground,
      pinned: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      actions: [
        IconButton(
          key: _statsKey,
          icon: const Icon(Icons.bar_chart_rounded, color: AppColors.mainText),
          onPressed: () => context.push(AppRoutes.stats),
        ),
        IconButton(
          key: _settingsKey,
          icon: const Icon(Icons.settings_outlined, color: AppColors.mainText),
          onPressed: () => context.push(AppRoutes.settings),
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          key: _balanceKey,
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
              if (showPointed) ...[
                const SizedBox(height: 6),
                Text(
                  "Dont pointé : ${pointedBalance.toStringAsFixed(2)} €",
                  style: const TextStyle(color: AppColors.secondaryText, fontSize: 13),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccountSelector(HomeViewModel vm) {
    return SliverToBoxAdapter(
      child: SizedBox(
        key: _accountSelectorKey,
        height: 125,
        child: ReorderableListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          buildDefaultDragHandles: false,
          onReorder: vm.reorderAccounts,
          children: vm.accounts.asMap().entries.map((entry) {
            final account = entry.value;
            final isSelected = vm.selectedAccount?.id == account.id;
            return ReorderableDelayedDragStartListener(
              key: ValueKey(account.id),
              index: entry.key,
              child: GestureDetector(
                onTap: () => vm.selectAccount(account),
                child: _buildAccountCard(account, isSelected),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildAccountCard(BankAccount account, bool isSelected) {
    final showPointed = (account.balance - account.pointedBalance).abs() > 0.005;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 170,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      padding: const EdgeInsets.all(16),
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
          if (showPointed) ...[
            const SizedBox(height: 3),
            Text(
              "Pointé : ${account.pointedBalance.toStringAsFixed(2)} €",
              style: TextStyle(
                color: isSelected ? Colors.white.withValues(alpha: 0.65) : AppColors.grey1,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTransactionList(HomeViewModel vm, List<Category> categories) {
    final transactions = vm.filteredTransactions;

    if (vm.isLoading && transactions.isEmpty) {
      return const SliverFillRemaining(child: Center(child: CircularProgressIndicator()));
    }

    if (vm.errorMessage != null && transactions.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.grey1),
                const SizedBox(height: 16),
                Text(
                  vm.errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.secondaryText),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () => vm.init(),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Réessayer'),
                ),
              ],
            ),
          ),
        ),
      );
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

class _TutorialCard extends StatelessWidget {
  final String step;
  final String title;
  final String description;

  const _TutorialCard({
    required this.step,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.secondaryBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.mainColor.withValues(alpha: 0.4), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(color: AppColors.mainText, fontSize: 17, fontWeight: FontWeight.bold),
              ),
              Text(
                step,
                style: const TextStyle(color: AppColors.grey1, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: const TextStyle(color: AppColors.secondaryText, fontSize: 14, height: 1.5),
          ),
        ],
      ),
    );
  }
}
