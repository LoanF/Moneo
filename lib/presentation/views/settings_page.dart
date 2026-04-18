import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/notifiers/lock_notifier.dart';
import '../../core/routes/app_routes.dart';
import '../../core/themes/app_colors.dart';
import '../view_models/auth_view_model.dart';
import '../view_models/home_view_model.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AuthViewModel>();
    final lockNotifier = context.watch<LockNotifier>();
    final user = viewModel.currentUser;

    return Scaffold(
      backgroundColor: AppColors.mainBackground,
      appBar: AppBar(
        title: const Text(
            "Paramètres",
            style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.mainText)
        ),
        centerTitle: false,
        backgroundColor: AppColors.mainBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.secondaryBackground,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(24),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => context.push(AppRoutes.profile),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 35,
                              backgroundColor: AppColors.mainColor.withValues(alpha: 0.1),
                              backgroundImage: _getProfileImage(user?.photoUrl, user?.email),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user?.username ?? "Utilisateur",
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.mainText
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    user?.email ?? "",
                                    style: const TextStyle(
                                        color: AppColors.secondaryText,
                                        fontSize: 13
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                                color: AppColors.grey1
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              _buildSectionHeader("Configuration"),
              _buildSettingsGroup([
                _buildNavigationItem(
                  label: "Gérer les catégories",
                  icon: Icons.category_rounded,
                  iconColor: Colors.orange,
                  onTap: () => context.push(AppRoutes.categoriesManager),
                ),
                _buildNavigationItem(
                  label: "Comptes bancaires",
                  icon: Icons.account_balance_wallet_rounded,
                  iconColor: Colors.blue,
                  onTap: () => context.push(AppRoutes.accountsManager),
                ),
                _buildNavigationItem(
                  label: "Moyens de paiement",
                  icon: Icons.credit_card_rounded,
                  iconColor: Colors.teal,
                  onTap: () => context.push(AppRoutes.paymentMethodsManager),
                ),
                _buildNavigationItem(
                  label: "Mensualisations",
                  icon: Icons.calendar_month_rounded,
                  iconColor: Colors.green,
                  onTap: () => context.push(AppRoutes.monthlyOperations),
                ),
              ]),

              _buildSectionHeader("Préférences"),
              _buildSettingsGroup([
                _buildNavigationItem(
                  label: "Notifications",
                  icon: Icons.notifications_active_rounded,
                  iconColor: Colors.purple,
                  onTap: () => context.push(AppRoutes.notificationsSettings),
                ),
              ]),

              _buildSectionHeader("Sécurité"),
              _buildSettingsGroup([
                _buildSwitchItem(
                  label: "Déverrouillage biométrique",
                  icon: Icons.fingerprint_rounded,
                  iconColor: Colors.indigo,
                  value: lockNotifier.biometricEnabled,
                  onChanged: (value) => _toggleBiometric(context, lockNotifier, value),
                ),
                if (lockNotifier.biometricEnabled)
                  _buildNavigationItem(
                    label: "Verrouillage auto : ${_formatTimeout(lockNotifier.autoLockMinutes)}",
                    icon: Icons.timer_rounded,
                    iconColor: Colors.blueGrey,
                    onTap: () => _showTimeoutPicker(context, lockNotifier),
                  ),
                _buildNavigationItem(
                  label: "Se déconnecter",
                  icon: Icons.power_settings_new_rounded,
                  iconColor: AppColors.error,
                  showArrow: false,
                  onTap: () => _showLogoutDialog(context, viewModel),
                ),
                _buildNavigationItem(
                  label: "Supprimer le compte",
                  icon: Icons.delete_forever_rounded,
                  iconColor: AppColors.error,
                  showArrow: false,
                  onTap: () => _showDeleteAccountDialog(context, viewModel),
                ),
              ]),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 32, bottom: 8, top: 16),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title.toUpperCase(),
          style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: AppColors.mainColor
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsGroup(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.secondaryBackground,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: Column(children: children),
      ),
    );
  }

  Widget _buildSwitchItem({
    required String label,
    required IconData icon,
    required Color iconColor,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(
        label,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppColors.mainText,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeTrackColor: AppColors.mainColor,
      ),
    );
  }

  Widget _buildNavigationItem({
    required String label,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
    bool showArrow = true,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(
          label,
          style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.mainText
          )
      ),
      trailing: showArrow
          ? const Icon(Icons.chevron_right, size: 20, color: AppColors.grey1)
          : null,
    );
  }

  String _formatTimeout(int minutes) {
    if (minutes == 0) return 'Jamais';
    if (minutes == 1) return '1 minute';
    return '$minutes minutes';
  }

  Future<void> _toggleBiometric(BuildContext context, LockNotifier lockNotifier, bool value) async {
    final success = await lockNotifier.setBiometricEnabled(value);
    if (!success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(value
              ? 'Biométrie non disponible ou authentification refusée'
              : 'Impossible de désactiver la biométrie'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _showTimeoutPicker(BuildContext context, LockNotifier lockNotifier) {
    const options = [0, 1, 5, 15, 30];
    showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.secondaryBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Verrouillage automatique', style: TextStyle(color: AppColors.mainText)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: options.map((minutes) {
            final selected = lockNotifier.autoLockMinutes == minutes;
            return ListTile(
              title: Text(
                _formatTimeout(minutes),
                style: TextStyle(
                  color: selected ? AppColors.mainColor : AppColors.mainText,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
                ),
              ),
              trailing: selected ? const Icon(Icons.check_rounded, color: AppColors.mainColor) : null,
              onTap: () => Navigator.pop(ctx, minutes),
            );
          }).toList(),
        ),
      ),
    ).then((minutes) {
      if (minutes != null) lockNotifier.setAutoLockMinutes(minutes);
    });
  }

  void _showLogoutDialog(BuildContext context, AuthViewModel viewModel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.secondaryBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text("Déconnexion", style: TextStyle(color: AppColors.mainText)),
        content: const Text(
            "Voulez-vous vraiment quitter Moneo ?",
            style: TextStyle(color: AppColors.secondaryText)
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Rester", style: TextStyle(color: AppColors.mainText))
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(context);
              context.read<HomeViewModel>().clear();
              await viewModel.logout();
              if (context.mounted) context.go(AppRoutes.login);
            },
            child: const Text("Se déconnecter"),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context, AuthViewModel viewModel) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.secondaryBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text("Supprimer le compte ?", style: TextStyle(color: AppColors.mainText)),
        content: const Text(
          "Cette action est irréversible. Toutes vos données (comptes, transactions, catégories) seront définitivement supprimées.",
          style: TextStyle(color: AppColors.secondaryText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Annuler", style: TextStyle(color: AppColors.mainText)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(ctx);
              context.read<HomeViewModel>().clear();
              final success = await viewModel.deleteAccount();
              if (context.mounted) {
                if (success) {
                  context.go(AppRoutes.login);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(viewModel.errorMessage ?? "Erreur lors de la suppression"),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            child: const Text("Supprimer définitivement"),
          ),
        ],
      ),
    );
  }

  ImageProvider _getProfileImage(String? url, String? email) {
    if (url != null && url.isNotEmpty) return NetworkImage(url);
    final String displayName = (email != null && email.isNotEmpty) ? email : "User";
    return NetworkImage(
      "https://ui-avatars.com/api/?name=$displayName&background=random",
    );
  }
}
