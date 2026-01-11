import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/routes/app_routes.dart';
import '../../core/themes/app_colors.dart';
import '../view_models/auth_view_model.dart';
import '../view_models/home_view_model.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AuthViewModel>();
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
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 16),

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
                            backgroundImage: _getProfileImage(user?.photoURL, user?.email),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user?.displayName ?? "Utilisateur",
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

            const SizedBox(height: 16),

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
            ]),

            _buildSectionHeader("Préférences"),
            _buildSettingsGroup([
              _buildNavigationItem(
                label: "Notifications",
                icon: Icons.notifications_active_rounded,
                iconColor: Colors.purple,
                onTap: () {},
              ),
              _buildNavigationItem(
                label: "Apparence",
                icon: Icons.dark_mode_rounded,
                iconColor: AppColors.grey2,
                onTap: () {},
              ),
            ]),

            _buildSectionHeader("Sécurité"),
            _buildSettingsGroup([
              _buildNavigationItem(
                label: "Se déconnecter",
                icon: Icons.power_settings_new_rounded,
                iconColor: AppColors.error,
                showArrow: false,
                onTap: () => _showLogoutDialog(context, viewModel),
              ),
            ]),

            const SizedBox(height: 40),
          ],
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

  ImageProvider _getProfileImage(String? url, String? email) {
    if (url != null && url.isNotEmpty) return NetworkImage(url);
    final String displayName = (email != null && email.isNotEmpty) ? email : "User";
    return NetworkImage(
      "https://ui-avatars.com/api/?name=$displayName&background=random",
    );
  }
}