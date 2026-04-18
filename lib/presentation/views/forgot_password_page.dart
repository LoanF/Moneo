import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/routes/app_routes.dart';
import '../../core/themes/app_colors.dart';
import '../view_models/auth_view_model.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _step2 = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String _email = '';

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _sendCode(AuthViewModel vm) async {
    FocusScope.of(context).unfocus();
    final email = _emailController.text.trim();
    if (email.isEmpty) return;

    final success = await vm.forgotPassword(email);
    if (!mounted) return;
    if (!success) {
      _showError(vm.errorMessage ?? 'Erreur lors de l\'envoi');
      return;
    }
    setState(() {
      _email = email;
      _step2 = true;
    });
  }

  Future<void> _resetPassword(AuthViewModel vm) async {
    FocusScope.of(context).unfocus();
    if (_passwordController.text != _confirmController.text) {
      _showError('Les mots de passe ne correspondent pas');
      return;
    }
    final success = await vm.resetPassword(
      _email,
      _codeController.text.trim(),
      _passwordController.text,
    );
    if (!mounted) return;
    if (!success) {
      _showError(vm.errorMessage ?? 'Code invalide ou expiré');
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Mot de passe réinitialisé avec succès'),
        backgroundColor: AppColors.success,
      ),
    );
    context.go(AppRoutes.login);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AuthViewModel>();

    return Scaffold(
      backgroundColor: AppColors.mainBackground,
      appBar: AppBar(
        backgroundColor: AppColors.mainBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.mainText),
          onPressed: () {
            if (_step2) {
              setState(() => _step2 = false);
            } else {
              context.pop();
            }
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: _step2 ? _buildStep2(vm) : _buildStep1(vm),
      ),
    );
  }

  Widget _buildStep1(AuthViewModel vm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.lock_reset_rounded, size: 56, color: AppColors.mainColor),
        const SizedBox(height: 20),
        const Text(
          'Mot de passe oublié',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.mainText),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        const Text(
          'Entrez votre email et nous vous enverrons un code de réinitialisation.',
          style: TextStyle(fontSize: 14, color: AppColors.secondaryText),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        _buildField(
          controller: _emailController,
          label: 'Email',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: vm.isLoading ? null : () => _sendCode(vm),
          child: vm.isLoading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Envoyer le code'),
        ),
      ],
    );
  }

  Widget _buildStep2(AuthViewModel vm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.mark_email_read_rounded, size: 56, color: AppColors.mainColor),
        const SizedBox(height: 20),
        const Text(
          'Vérification',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.mainText),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Un code à 6 chiffres a été envoyé à $_email',
          style: const TextStyle(fontSize: 14, color: AppColors.secondaryText),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        _buildField(
          controller: _codeController,
          label: 'Code à 6 chiffres',
          icon: Icons.pin_rounded,
          keyboardType: TextInputType.number,
          maxLength: 6,
        ),
        const SizedBox(height: 16),
        _buildField(
          controller: _passwordController,
          label: 'Nouveau mot de passe',
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
          label: 'Confirmer le mot de passe',
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
          onPressed: vm.isLoading ? null : () => _resetPassword(vm),
          child: vm.isLoading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Réinitialiser le mot de passe'),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: vm.isLoading ? null : () => _sendCode(vm),
          child: const Text('Renvoyer le code', style: TextStyle(color: AppColors.linkAction)),
        ),
      ],
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscure = false,
    Widget? suffix,
    int? maxLength,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      maxLength: maxLength,
      style: const TextStyle(color: AppColors.mainText),
      decoration: InputDecoration(
        labelText: label,
        counterText: '',
        prefixIcon: Icon(icon, color: AppColors.grey1, size: 20),
        suffixIcon: suffix,
      ),
    );
  }
}
