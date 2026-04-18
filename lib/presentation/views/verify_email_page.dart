import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/routes/app_routes.dart';
import '../../core/themes/app_colors.dart';
import '../view_models/auth_view_model.dart';

class VerifyEmailPage extends StatefulWidget {
  const VerifyEmailPage({super.key});

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _verify(AuthViewModel vm) async {
    FocusScope.of(context).unfocus();
    final success = await vm.verifyEmail(_codeController.text.trim());
    if (!mounted) return;
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(vm.errorMessage ?? 'Code invalide'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    final user = vm.currentUser;
    if (user != null && !user.hasCompletedSetup) {
      context.go(AppRoutes.setup);
    } else {
      context.go(AppRoutes.home);
    }
  }

  Future<void> _resend(AuthViewModel vm) async {
    final success = await vm.resendVerification();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Code renvoyé' : (vm.errorMessage ?? 'Erreur lors du renvoi')),
        backgroundColor: success ? AppColors.success : AppColors.error,
      ),
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
          onPressed: () => context.go(AppRoutes.login),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.mark_email_unread_rounded, size: 56, color: AppColors.mainColor),
            const SizedBox(height: 20),
            const Text(
              'Vérifiez votre email',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.mainText),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Un code à 6 chiffres a été envoyé à ${vm.currentUser?.email ?? 'votre email'}',
              style: const TextStyle(fontSize: 14, color: AppColors.secondaryText),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              style: const TextStyle(color: AppColors.mainText),
              decoration: const InputDecoration(
                labelText: 'Code à 6 chiffres',
                counterText: '',
                prefixIcon: Icon(Icons.pin_rounded, color: AppColors.grey1, size: 20),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: vm.isLoading ? null : () => _verify(vm),
              child: vm.isLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Vérifier'),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: vm.isLoading ? null : () => _resend(vm),
              child: const Text('Renvoyer le code', style: TextStyle(color: AppColors.linkAction)),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () async {
                await context.read<AuthViewModel>().logout();
              },
              child: const Text('Se connecter avec un autre compte', style: TextStyle(color: AppColors.secondaryText, fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }
}
