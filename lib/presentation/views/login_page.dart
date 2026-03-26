import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/routes/app_routes.dart';
import '../../core/themes/app_colors.dart';
import '../../data/constants/assets.dart';
import '../view_models/auth_view_model.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {},
                      child: const Text(
                        "Mot de passe oublié ?",
                        style: TextStyle(color: AppColors.linkAction, fontSize: 13),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: vm.isLoading ? null : () => _login(context, vm),
                    child: vm.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text("Se connecter"),
                  ),
                  const SizedBox(height: 12),
                  _buildDivider(),
                  const SizedBox(height: 12),
                  _buildGoogleButton(context, vm),
                  const SizedBox(height: 24),
                  _buildFooterLink(
                    context,
                    question: "Pas encore de compte ?",
                    action: "S'inscrire",
                    onTap: () => context.go(AppRoutes.register),
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
                "Bienvenue",
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 6),
              const Text(
                "Gérez vos finances en toute sérénité",
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
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.thirdBackground)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text("ou", style: TextStyle(color: AppColors.grey1, fontSize: 13)),
        ),
        const Expanded(child: Divider(color: AppColors.thirdBackground)),
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

  Future<void> _login(BuildContext context, AuthViewModel vm) async {
    FocusScope.of(context).unfocus();
    final success = await vm.login(_emailController.text, _passwordController.text);
    if (!context.mounted) return;
    if (!success) {
      _showError(context, vm.errorMessage ?? "Erreur de connexion");
      return;
    }
    _navigateAfterAuth(context, vm);
  }

  Future<void> _loginWithGoogle(BuildContext context, AuthViewModel vm) async {
    final success = await vm.loginWithGoogle();
    if (!context.mounted) return;
    if (!success) {
      _showError(context, vm.errorMessage ?? "Erreur");
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

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
