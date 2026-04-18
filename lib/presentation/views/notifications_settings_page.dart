import 'package:flutter/material.dart';

import '../../core/di.dart';
import '../../core/services/user_service.dart';
import '../../core/themes/app_colors.dart';

class NotificationsSettingsPage extends StatefulWidget {
  const NotificationsSettingsPage({super.key});

  @override
  State<NotificationsSettingsPage> createState() => _NotificationsSettingsPageState();
}

class _NotificationsSettingsPageState extends State<NotificationsSettingsPage> {
  late Map<String, bool> _prefs;
  bool _saving = false;

  static const _items = [
    (
      key: 'paymentApplied',
      label: 'Paiement mensuel',
      subtitle: 'Quand un paiement récurrent est appliqué automatiquement',
      icon: Icons.repeat_rounded,
      color: Colors.green,
    ),
    (
      key: 'lowBalance',
      label: 'Solde bas',
      subtitle: 'Quand le solde d\'un compte passe sous 100 €',
      icon: Icons.account_balance_wallet_rounded,
      color: Colors.orange,
    ),
    (
      key: 'monthlyRecap',
      label: 'Récap mensuel',
      subtitle: 'Le 1er de chaque mois avec un résumé du mois écoulé',
      icon: Icons.bar_chart_rounded,
      color: Colors.blue,
    ),
    (
      key: 'activityReminder',
      label: 'Rappel de saisie',
      subtitle: 'Si aucune transaction n\'a été saisie depuis 5 jours',
      icon: Icons.notifications_active_rounded,
      color: Colors.purple,
    ),
  ];

  @override
  void initState() {
    super.initState();
    final user = getIt<IAppUserService>().currentAppUser;
    _prefs = Map<String, bool>.from(
      user?.notificationPrefs ?? {
        'paymentApplied': true,
        'lowBalance': true,
        'monthlyRecap': true,
        'activityReminder': true,
      },
    );
  }

  Future<void> _toggle(String key, bool value) async {
    final previous = Map<String, bool>.from(_prefs);
    setState(() {
      _prefs[key] = value;
      _saving = true;
    });
    try {
      await getIt<IAppUserService>().updateNotificationPrefs(Map<String, bool>.from(_prefs));
    } catch (_) {
      if (mounted) {
        setState(() => _prefs = previous);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible de sauvegarder la préférence'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mainBackground,
      appBar: AppBar(
        backgroundColor: AppColors.mainBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Notifications',
          style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.mainText),
        ),
        centerTitle: false,
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.mainColor),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.secondaryBackground,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: _items.map((item) {
                final isLast = item == _items.last;
                return Column(
                  children: [
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: item.color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(item.icon, color: item.color, size: 22),
                      ),
                      title: Text(
                        item.label,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.mainText,
                        ),
                      ),
                      subtitle: Text(
                        item.subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.secondaryText,
                        ),
                      ),
                      trailing: Switch(
                        value: _prefs[item.key] ?? true,
                        onChanged: _saving ? null : (v) => _toggle(item.key, v),
                        activeTrackColor: AppColors.mainColor,
                      ),
                    ),
                    if (!isLast)
                      const Divider(
                        height: 1,
                        indent: 64,
                        endIndent: 20,
                        color: AppColors.thirdBackground,
                      ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
