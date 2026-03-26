import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/routes/app_routes.dart';
import '../../core/themes/app_colors.dart';
import '../../data/constants/assets.dart';
import '../view_models/auth_view_model.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AuthViewModel>();

    return Scaffold(
      backgroundColor: AppColors.mainBackground,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildField(
                    controller: _emailController,
                    label: "Email",
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 12),
                  _buildField(
                    controller: _passwordController,
                    label: "Mot de passe",
                    icon: Icons.lock_outline_rounded,
                    obscure: _obscurePassword,
                    suffix: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: AppColors.grey1,
                        size: 20,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildField(
                    controller: _confirmController,
                    label: "Confirmer le mot de passe",
                    icon: Icons.lock_reset_outlined,
                    obscure: _obscureConfirm,
                    suffix: IconButton(
                      icon: Icon(
                        _obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: AppColors.grey1,
                        size: 20,
                      ),
                      onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: vm.isLoading ? null : () => _register(context, vm),
                    child: vm.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text("Créer mon compte"),
                  ),
                  const SizedBox(height: 12),
                  _buildDivider(),
                  const SizedBox(height: 12),
                  _buildGoogleButton(context, vm),
                  const SizedBox(height: 24),
                  _buildFooterLink(
                    context,
                    question: "Déjà un compte ?",
                    action: "Se connecter",
                    onTap: () => context.go(AppRoutes.login),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.secondaryBackground,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
          child: Column(
            children: [
              SvgPicture.asset(AppAssets.logo, height: 72),
              const SizedBox(height: 20),
              Text(
                "Créer un compte",
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 6),
              const Text(
                "Rejoignez Moneo et prenez le contrôle",
                style: TextStyle(color: AppColors.secondaryText, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscure = false,
    Widget? suffix,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      style: const TextStyle(color: AppColors.mainText),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.grey1, size: 20),
        suffixIcon: suffix,
      ),
    );
  }

  Widget _buildDivider() {
    return const Row(
      children: [
        Expanded(child: Divider(color: AppColors.thirdBackground)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text("ou", style: TextStyle(color: AppColors.grey1, fontSize: 13)),
        ),
        Expanded(child: Divider(color: AppColors.thirdBackground)),
      ],
    );
  }

  Widget _buildGoogleButton(BuildContext context, AuthViewModel vm) {
    return OutlinedButton(
      onPressed: vm.isLoading ? null : () => _loginWithGoogle(context, vm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            'assets/images/google_logo.svg',
            height: 18,
          ),
          const SizedBox(width: 10),
          const Text("Continuer avec Google"),
        ],
      ),
    );
  }

  Widget _buildFooterLink(
    BuildContext context, {
    required String question,
    required String action,
    required VoidCallback onTap,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(question, style: const TextStyle(color: AppColors.secondaryText)),
        TextButton(
          onPressed: onTap,
          child: Text(action, style: const TextStyle(color: AppColors.linkAction, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Future<void> _register(BuildContext context, AuthViewModel vm) async {
    FocusScope.of(context).unfocus();
    if (_passwordController.text != _confirmController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Les mots de passe ne correspondent pas.")),
      );
      return;
    }
    final success = await vm.register(_emailController.text, _passwordController.text);
    if (!context.mounted) return;
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(vm.errorMessage ?? "Erreur inconnue")),
      );
      return;
    }
    _navigateAfterAuth(context, vm);
  }

  Future<void> _loginWithGoogle(BuildContext context, AuthViewModel vm) async {
    final success = await vm.loginWithGoogle();
    if (!context.mounted) return;
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(vm.errorMessage ?? "Erreur")),
      );
      return;
    }
    _navigateAfterAuth(context, vm);
  }

  void _navigateAfterAuth(BuildContext context, AuthViewModel vm) {
    final user = vm.currentUser;
    if (user != null && !user.hasCompletedSetup) {
      context.go(AppRoutes.setup);
    } else {
      context.go(AppRoutes.home);
    }
  }
}
