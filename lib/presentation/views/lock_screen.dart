import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/notifiers/lock_notifier.dart';
import '../../core/themes/app_colors.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _authenticate());
  }

  Future<void> _authenticate() async {
    if (!mounted) return;
    await context.read<LockNotifier>().authenticate();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mainBackground,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.mainColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.lock_rounded,
                  size: 40,
                  color: AppColors.mainColor,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Moneo',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.mainText,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Déverrouillez pour continuer',
                style: TextStyle(fontSize: 14, color: AppColors.secondaryText),
              ),
              const SizedBox(height: 48),
              FilledButton.icon(
                onPressed: _authenticate,
                icon: const Icon(Icons.fingerprint_rounded),
                label: const Text('Déverrouiller'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.mainColor,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
