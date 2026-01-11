import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/notifiers/auth_notifier.dart';
import '../../core/services/user_service.dart';
import '../../core/di.dart';
import '../../data/models/account_model.dart';
import '../../core/themes/app_colors.dart';
import '../widgets/account_form_sheet.dart';

class AccountsManagerPage extends StatefulWidget {
  const AccountsManagerPage({super.key});

  @override
  State<AccountsManagerPage> createState() => _AccountsManagerPageState();
}

class _AccountsManagerPageState extends State<AccountsManagerPage> {
  final _userService = getIt<IAppUserService>();

  Widget _proxyDecorator(Widget child, int index, Animation<double> animation) {
    return AnimatedBuilder(
      animation: animation,
      builder: (BuildContext context, Widget? child) {
        final double animValue = Curves.easeInOut.transform(animation.value);
        final double elevation = lerpDouble(0, 6, animValue)!;
        final double scale = lerpDouble(1, 1.02, animValue)!;

        return Transform.scale(
          scale: scale,
          child: Material(
            elevation: elevation,
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(24),
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  double? lerpDouble(num? a, num? b, double t) {
    if (a == null && b == null) return null;
    a ??= 0.0;
    b ??= 0.0;
    return a + (b - a) * t;
  }

  @override
  Widget build(BuildContext context) {
    final uid = context.read<AuthNotifier>().appUser!.uid;

    return Scaffold(
      backgroundColor: AppColors.mainBackground,
      appBar: AppBar(
        title: const Text("Comptes bancaires", style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: AppColors.mainBackground,
        scrolledUnderElevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.mainColor,
        onPressed: () => _showAccountSheet(context, uid),
        label: const Text("Ajouter", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        icon: const Icon(Icons.add, color: Colors.white),
      ),
      body: StreamBuilder<List<Account>>(
        stream: _userService.getAccountsStream(uid),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final accounts = snapshot.data!;
          if (accounts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.account_balance_wallet_outlined, size: 80, color: AppColors.grey2.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  const Text("Aucun compte configuré", style: TextStyle(color: AppColors.secondaryText, fontSize: 16)),
                ],
              ),
            );
          }

          return ReorderableListView.builder(
            padding: const EdgeInsets.all(16),
            proxyDecorator: _proxyDecorator,
            itemCount: accounts.length,
            onReorder: (oldIndex, newIndex) {
              if (oldIndex < newIndex) newIndex -= 1;
              final List<Account> items = List.from(accounts);
              final item = items.removeAt(oldIndex);
              items.insert(newIndex, item);
              _userService.updateAccountsOrder(uid, items);
            },
            itemBuilder: (context, index) {
              final account = accounts[index];
              return Padding(
                key: ValueKey(account.id),
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.secondaryBackground,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    leading: const Icon(Icons.drag_indicator, color: AppColors.grey2),
                    title: Text(account.name, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.mainText)),
                    subtitle: Text("${account.currentBalance.toStringAsFixed(2)} €", style: const TextStyle(color: AppColors.mainColor)),
                    trailing: PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert_rounded, color: AppColors.grey2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      color: AppColors.secondaryBackground,
                      elevation: 8,
                      onSelected: (value) {
                        if (value == 'edit') {
                          _showAccountSheet(context, uid, account: account, currentCount: accounts.length);
                        } else if (value == 'delete') {
                          _showDeleteConfirmation(context, uid, account);
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_rounded, size: 20, color: AppColors.mainText.withOpacity(0.7)),
                              const SizedBox(width: 12),
                              const Text('Modifier', style: TextStyle(color: AppColors.mainText, fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.error),
                              SizedBox(width: 12),
                              Text('Supprimer', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showAccountSheet(BuildContext context, String uid, {Account? account, int currentCount = 0}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.secondaryBackground,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) => AccountFormSheet(
        account: account,
        onSave: (acc) {
          if (account == null) {
            _userService.createAccount(uid, acc.copyWith(order: currentCount));
          } else {
            _userService.updateAccount(uid, acc);
          }
        },
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, String uid, Account account) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.secondaryBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text("Supprimer le compte ?", style: TextStyle(color: AppColors.mainText)),
        content: const Text("Toutes les transactions liées à ce compte seront également inaccessibles."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler", style: TextStyle(color: AppColors.mainText)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              _userService.deleteAccount(uid, account.id);
              Navigator.pop(context);
            },
            child: const Text("Supprimer"),
          ),
        ],
      ),
    );
  }
}