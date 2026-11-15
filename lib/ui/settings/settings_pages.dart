import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/format.dart';
import '../../data/models.dart';
import '../../state/providers.dart';
import '../../state/services.dart';
import '../auth/auth_pages.dart';
import '../theme/theme.dart';
import '../widgets/common.dart';

/// Met à jour le profil côté serveur puis recharge l'état partagé.
Future<bool> _patchProfile(BuildContext context, WidgetRef ref, Json patch) =>
    guard(context, () async {
      final user = await ref.read(apiProvider).updateProfile(patch);
      ref.read(sessionProvider.notifier).setUser(user);
      await ref.read(appDataProvider.notifier).refresh();
    });

class _Avatar extends StatelessWidget {
  const _Avatar({required this.user, this.radius = 28});
  final AppUser user;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final initial = user.username.trim().isEmpty
        ? '?'
        : user.username.trim()[0].toUpperCase();
    return CircleAvatar(
      radius: radius,
      backgroundColor: context.scheme.primaryContainer,
      foregroundImage: user.photoUrl == null
          ? null
          : NetworkImage(user.photoUrl!),
      child: Text(
        initial,
        style: TextStyle(
          fontSize: radius * 0.8,
          fontWeight: FontWeight.w700,
          color: context.scheme.onPrimaryContainer,
        ),
      ),
    );
  }
}

// ── Réglages ─────────────────────────────────────────────────────────────────

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(sessionProvider).value;
    if (user == null) return const Scaffold();
    final c = context.moneo;

    Widget entry(
      IconData icon,
      Color color,
      String title,
      String subtitle,
      String route,
    ) => GroupTile(
      icon: icon,
      color: color,
      title: title,
      subtitle: subtitle,
      onTap: () => context.push(route),
    );

    return Scaffold(
      body: Stack(
        children: [
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: GlowBackdrop(height: 300),
          ),
          ListView(
            padding: EdgeInsets.only(
              top: MediaQuery.paddingOf(context).top + Gap.lg,
              bottom: Gap.dock,
            ),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  Gap.page,
                  0,
                  Gap.page,
                  Gap.lg,
                ),
                child: Semantics(
                  header: true,
                  child: Text('Réglages', style: context.text.headlineMedium),
                ),
              ),
              // Carte de profil : le compte connecté, en un coup d'œil.
              Pressable(
                onTap: () => context.push('/settings/profile'),
                scale: 0.985,
                child: MCard(
                  margin: const EdgeInsets.symmetric(horizontal: Gap.lg),
                  padding: const EdgeInsets.all(Gap.lg),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: c.brandGradient,
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: c.card,
                          ),
                          child: _Avatar(user: user, radius: 28),
                        ),
                      ),
                      const SizedBox(width: Gap.lg),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.username,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.text.titleLarge,
                            ),
                            Text(
                              user.email,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.text.bodySmall?.copyWith(
                                color: c.inkSoft,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded, color: c.inkSoft),
                    ],
                  ),
                ),
              ),
              const GroupLabel('Mes données'),
              GroupCard(
                children: [
                  entry(
                    Icons.account_balance_wallet_rounded,
                    const Color(0xFF3B82F6),
                    'Comptes',
                    'Soldes de départ, ordre, archivage',
                    '/settings/accounts',
                  ),
                  entry(
                    Icons.category_rounded,
                    const Color(0xFFA855F7),
                    'Catégories',
                    'Catégories et sous-catégories',
                    '/settings/categories',
                  ),
                  entry(
                    Icons.credit_card_rounded,
                    const Color(0xFF14B8A6),
                    'Moyens de paiement',
                    'Cartes, virements, chéquiers',
                    '/settings/payment-methods',
                  ),
                  entry(
                    Icons.import_export_rounded,
                    const Color(0xFFF97316),
                    'Import et export',
                    'Classeur Excel, sauvegarde, CSV',
                    '/settings/data',
                  ),
                ],
              ),
              const GroupLabel('Application'),
              GroupCard(
                children: [
                  entry(
                    Icons.tune_rounded,
                    const Color(0xFF6366F1),
                    'Préférences',
                    'Thème, saisie, mensualités',
                    '/settings/preferences',
                  ),
                  entry(
                    Icons.notifications_rounded,
                    const Color(0xFFEAB308),
                    'Notifications',
                    'Solde bas, budgets, échéances',
                    '/settings/notifications',
                  ),
                  entry(
                    Icons.lock_rounded,
                    const Color(0xFF22C55E),
                    'Sécurité',
                    'Verrouillage, mot de passe, appareils',
                    '/settings/security',
                  ),
                ],
              ),
              const GroupLabel('Compte'),
              GroupCard(
                children: [
                  GroupTile(
                    icon: Icons.logout_rounded,
                    danger: true,
                    title: 'Se déconnecter',
                    onTap: () async {
                      final waiting = ref.read(outboxProvider).length;
                      final sure = await confirm(
                        context,
                        title: 'Se déconnecter ?',
                        message: waiting > 0
                            ? '$waiting opération(s) saisie(s) hors ligne n’ont pas encore été envoyées et seront perdues.'
                            : 'Vos données restent sur le serveur ; vous les retrouverez en vous reconnectant.',
                        confirmLabel: 'Se déconnecter',
                        destructive: waiting > 0,
                      );
                      if (!sure) return;
                      await ref.read(googleAuthProvider).signOut();
                      await ref.read(sessionProvider.notifier).logout();
                    },
                  ),
                ],
              ),
              const _VersionTile(),
            ],
          ),
        ],
      ),
    );
  }
}

class _VersionTile extends StatelessWidget {
  const _VersionTile();

  @override
  Widget build(BuildContext context) => FutureBuilder<PackageInfo>(
    future: PackageInfo.fromPlatform(),
    builder: (context, snapshot) => Padding(
      padding: const EdgeInsets.all(Gap.page),
      child: Text(
        snapshot.hasData
            ? 'Moneo ${snapshot.data!.version} (${snapshot.data!.buildNumber})'
            : 'Moneo',
        style: context.text.bodySmall?.copyWith(color: context.moneo.inkSoft),
      ),
    ),
  );
}

// ── Profil ───────────────────────────────────────────────────────────────────

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  late final _name = TextEditingController(
    text: ref.read(sessionProvider).value?.username ?? '',
  );
  bool _uploading = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (file == null || !mounted) return;
    setState(() => _uploading = true);
    await guard(context, () async {
      final user = await ref.read(apiProvider).uploadAvatar(file.path);
      ref.read(sessionProvider.notifier).setUser(user);
    }, success: 'Photo mise à jour');
    if (mounted) setState(() => _uploading = false);
  }

  Future<void> _deleteAccount(AppUser user) async {
    final controller = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer mon compte ?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tous vos comptes, opérations, mensualités et budgets seront effacés définitivement. Cette action ne peut pas être annulée.',
            ),
            const SizedBox(height: Gap.lg),
            TextField(
              controller: controller,
              obscureText: user.hasPassword,
              autofillHints: user.hasPassword
                  ? const [AutofillHints.password]
                  : null,
              decoration: InputDecoration(
                labelText: user.hasPassword
                    ? 'Votre mot de passe'
                    : 'Votre adresse email, pour confirmer',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: context.scheme.error,
              foregroundColor: context.scheme.onError,
              minimumSize: const Size(64, 44),
            ),
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Supprimer définitivement'),
          ),
        ],
      ),
    );
    if (value == null || value.isEmpty || !mounted) return;
    await guard(
      context,
      () => ref
          .read(sessionProvider.notifier)
          .deleteAccount(
            password: user.hasPassword ? value : null,
            confirmEmail: user.hasPassword ? null : value,
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(sessionProvider).value;
    if (user == null) return const Scaffold();
    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: ListView(
        padding: const EdgeInsets.all(Gap.page),
        children: [
          Center(
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                _Avatar(user: user, radius: 48),
                IconButton.filled(
                  onPressed: _uploading ? null : _pickPhoto,
                  icon: _uploading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.photo_camera_rounded, size: 20),
                  tooltip: 'Changer la photo',
                ),
              ],
            ),
          ),
          const SizedBox(height: Gap.xl),
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Prénom'),
          ),
          const SizedBox(height: Gap.md),
          TextField(
            controller: TextEditingController(text: user.email),
            readOnly: true,
            decoration: InputDecoration(
              labelText: 'Adresse email',
              helperText: user.emailVerified
                  ? 'Adresse vérifiée'
                  : 'Adresse non vérifiée',
            ),
          ),
          const SizedBox(height: Gap.xl),
          SubmitButton(
            label: 'Enregistrer',
            onPressed: () async {
              if (_name.text.trim().length < 2) {
                return showMessage(
                  context,
                  'Le prénom doit contenir au moins 2 lettres.',
                );
              }
              if (await _patchProfile(context, ref, {
                    'username': _name.text.trim(),
                  }) &&
                  context.mounted) {
                showMessage(context, 'Profil mis à jour');
              }
            },
          ),
          const SizedBox(height: Gap.xxl),
          const Perforation(),
          const SizedBox(height: Gap.lg),
          Text(
            'Zone sensible',
            style: context.text.titleSmall?.copyWith(
              color: context.moneo.inkSoft,
            ),
          ),
          const SizedBox(height: Gap.sm),
          OutlinedButton.icon(
            onPressed: () => _deleteAccount(user),
            style: OutlinedButton.styleFrom(
              foregroundColor: context.scheme.error,
              side: BorderSide(color: context.scheme.error),
            ),
            icon: const Icon(Icons.delete_forever_rounded),
            label: const Text('Supprimer mon compte'),
          ),
        ],
      ),
    );
  }
}

// ── Préférences ──────────────────────────────────────────────────────────────

class PreferencesPage extends ConsumerWidget {
  const PreferencesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(appDataProvider).value;
    final prefs = ref.watch(devicePrefsProvider);
    if (data == null) return const Scaffold();
    final settings = data.user.settings;
    Future<void> set(Json patch) =>
        _patchProfile(context, ref, {'settings': patch});

    return Scaffold(
      appBar: AppBar(title: const Text('Préférences')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: Gap.xxl),
        children: [
          const SectionHeader('Apparence'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Gap.page),
            child: PillTabs<ThemeMode>(
              value: prefs.themeMode,
              items: [
                (value: ThemeMode.system, label: 'Système'),
                (value: ThemeMode.light, label: 'Clair'),
                (value: ThemeMode.dark, label: 'Sombre'),
              ],
              onChanged: (v) => ref
                  .read(devicePrefsProvider.notifier)
                  .update((p) => p.copyWith(themeMode: v)),
            ),
          ),
          SwitchTile(
            title: 'Masquer les montants',
            subtitle: 'Pour consulter l’app en public.',
            value: prefs.hideAmounts,
            onChanged: (v) => ref
                .read(devicePrefsProvider.notifier)
                .update((p) => p.copyWith(hideAmounts: v)),
          ),
          const SectionHeader('Saisie'),
          if (data.activeAccounts.length > 1)
            GroupTile(
              title: 'Compte par défaut',
              subtitle:
                  data.account(settings.defaultAccountId)?.name ??
                  'Le premier de la liste',
              onTap: () => showSheet<void>(
                context,
                SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SheetHeader('Compte par défaut'),
                      for (final a in data.activeAccounts)
                        ListTile(
                          title: Text(a.name),
                          trailing: a.id == settings.defaultAccountId
                              ? Icon(
                                  Icons.check_rounded,
                                  color: context.scheme.primary,
                                )
                              : null,
                          onTap: () {
                            Navigator.pop(context);
                            set({'defaultAccountId': a.id});
                          },
                        ),
                      const SizedBox(height: Gap.sm),
                    ],
                  ),
                ),
              ),
            ),
          SwitchTile(
            title: 'Sauter le libellé',
            subtitle:
                'Après le montant, le clavier se ferme au lieu de passer au libellé.',
            value: settings.skipNote,
            onChanged: (v) => set({'skipNote': v}),
          ),
          GroupTile(
            title: 'Début du suivi',
            subtitle: settings.trackingStartDate == null
                ? 'Non défini'
                : 'Le ${Fmt.longDate(settings.trackingStartDate!)} · une date antérieure demande confirmation',
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: settings.trackingStartDate == null
                    ? DateTime.now()
                    : Fmt.parse(settings.trackingStartDate!),
                firstDate: DateTime(2000),
                lastDate: DateTime.now(),
                helpText: 'Début du suivi',
              );
              if (picked != null) {
                await set({'trackingStartDate': Fmt.iso(picked)});
              }
            },
          ),
          const SectionHeader('Mensualités'),
          RadioGroup<RecurringMode>(
            groupValue: settings.recurringMode,
            onChanged: (mode) {
              if (mode != null) set({'recurringMode': mode.wire});
            },
            child: Column(
              children: [
                for (final mode in RecurringMode.values)
                  RadioListTile<RecurringMode>(
                    value: mode,
                    title: Text(mode.label),
                    subtitle: Text(mode.help),
                  ),
              ],
            ),
          ),
          const SectionHeader('Budgets et alertes'),
          GroupTile(
            title: 'Premier jour du mois budgétaire',
            subtitle: settings.monthStartDay == 1
                ? 'Le 1er'
                : 'Le ${settings.monthStartDay} (jour de paie, par exemple)',
            onTap: () async {
              final day = await _askNumber(
                context,
                title: 'Premier jour du mois budgétaire',
                label: 'Jour (1 à 28)',
                initial: '${settings.monthStartDay}',
                min: 1,
                max: 28,
              );
              if (day != null) await set({'monthStartDay': day.round()});
            },
          ),
          GroupTile(
            title: 'Seuil de solde bas',
            subtitle: settings.lowBalanceThreshold == null
                ? 'Aucune alerte'
                : 'Alerte sous ${Fmt.money(settings.lowBalanceThreshold!)}',
            onTap: () async {
              final value = await _askNumber(
                context,
                title: 'Seuil de solde bas',
                label: 'Montant en euros (vide = aucune alerte)',
                initial: settings.lowBalanceThreshold == null
                    ? ''
                    : Fmt.plain(settings.lowBalanceThreshold!),
                allowEmpty: true,
              );
              if (value != null) {
                await set({'lowBalanceThreshold': value.isNaN ? null : value});
              }
            },
          ),
        ],
      ),
    );
  }
}

/// Demande un nombre. Renvoie `NaN` si le champ est laissé vide et que c'est permis.
Future<double?> _askNumber(
  BuildContext context, {
  required String title,
  required String label,
  required String initial,
  double? min,
  double? max,
  bool allowEmpty = false,
}) {
  final controller = TextEditingController(
    text: initial.replaceAll(RegExp(r'[\s  ]'), ''),
  );
  String? error;
  return showDialog<double>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: label, errorText: error),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              if (allowEmpty && controller.text.trim().isEmpty) {
                return Navigator.pop(context, double.nan);
              }
              final value = Fmt.parseAmount(controller.text);
              if (value == null ||
                  (min != null && value < min) ||
                  (max != null && value > max)) {
                setState(
                  () => error = min != null && max != null
                      ? 'Entre ${min.round()} et ${max.round()}'
                      : 'Valeur invalide',
                );
                return;
              }
              Navigator.pop(context, value);
            },
            child: const Text('Valider'),
          ),
        ],
      ),
    ),
  );
}

// ── Notifications ────────────────────────────────────────────────────────────

class NotificationSettingsPage extends ConsumerStatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  ConsumerState<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState
    extends ConsumerState<NotificationSettingsPage> {
  PushStatus? _push;

  @override
  void initState() {
    super.initState();
    ref.read(pushServiceProvider).status().then((s) {
      if (mounted) setState(() => _push = s);
    });
  }

  Future<void> _pickTime(String key, String? current) async {
    final parts = (current ?? '22:00').split(':');
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      ),
    );
    if (time == null || !mounted) return;
    final value =
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    await _patchProfile(context, ref, {
      'notificationPrefs': {key: value},
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(sessionProvider).value;
    if (user == null) return const Scaffold();
    final p = user.notificationPrefs;
    Future<void> set(String key, Object? value) => _patchProfile(context, ref, {
      'notificationPrefs': {key: value},
    });
    Widget toggle(String key, bool value, String title, String subtitle) =>
        SwitchTile(
          title: title,
          subtitle: subtitle,
          value: value,
          onChanged: (v) => set(key, v),
        );
    final quiet = p.quietHoursStart != null && p.quietHoursEnd != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: Gap.xxl),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(Gap.page, Gap.sm, Gap.page, 0),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(Gap.lg),
                child: switch (_push) {
                  null => const Skeleton(height: 40),
                  PushStatus.enabled => Row(
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        color: context.moneo.income,
                      ),
                      const SizedBox(width: Gap.md),
                      const Expanded(
                        child: Text(
                          'Les notifications arrivent sur cet appareil.',
                        ),
                      ),
                    ],
                  ),
                  PushStatus.unavailable => const Text(
                    'Les notifications push ne sont pas disponibles sur cette version. Vos alertes restent visibles dans l’app, via la cloche de l’accueil.',
                  ),
                  PushStatus.denied => const Text(
                    'Les notifications sont bloquées pour Moneo. Autorisez-les dans les réglages du téléphone pour les recevoir ici.',
                  ),
                  PushStatus.notAsked => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Recevez vos alertes sur cet appareil, même quand l’app est fermée.',
                      ),
                      const SizedBox(height: Gap.md),
                      FilledButton.tonal(
                        onPressed: () async {
                          final status = await ref
                              .read(pushServiceProvider)
                              .enable();
                          if (mounted) setState(() => _push = status);
                        },
                        child: const Text('Activer sur cet appareil'),
                      ),
                    ],
                  ),
                },
              ),
            ),
          ),
          const SectionHeader('M’avertir'),
          toggle(
            'lowBalance',
            p.lowBalance,
            'Solde bas',
            'Quand un compte passe sous son seuil.',
          ),
          toggle(
            'budgetAlert',
            p.budgetAlert,
            'Budgets',
            'À l’approche du plafond, puis au dépassement.',
          ),
          toggle(
            'upcomingPayment',
            p.upcomingPayment,
            'Échéances',
            'La veille d’un prélèvement mensuel.',
          ),
          toggle(
            'paymentApplied',
            p.paymentApplied,
            'Mensualités',
            'Quand les opérations du mois sont ajoutées, ou à mettre en place.',
          ),
          toggle(
            'monthlyRecap',
            p.monthlyRecap,
            'Bilan du mois',
            'Le 1er, revenus et dépenses du mois écoulé.',
          ),
          toggle(
            'activityReminder',
            p.activityReminder,
            'Rappel de saisie',
            'Après 5 jours sans nouvelle opération.',
          ),
          const SectionHeader('Heures calmes'),
          SwitchTile(
            title: 'Ne pas déranger la nuit',
            subtitle:
                'Pas de notification sur le téléphone ; elles restent visibles dans l’app.',
            value: quiet,
            onChanged: (v) => _patchProfile(context, ref, {
              'notificationPrefs': {
                'quietHoursStart': v ? '22:00' : null,
                'quietHoursEnd': v ? '07:00' : null,
              },
            }),
          ),
          if (quiet) ...[
            GroupTile(
              title: 'Début',
              trailing: Text(
                p.quietHoursStart!,
                style: context.text.titleMedium,
              ),
              onTap: () => _pickTime('quietHoursStart', p.quietHoursStart),
            ),
            GroupTile(
              title: 'Fin',
              trailing: Text(p.quietHoursEnd!, style: context.text.titleMedium),
              onTap: () => _pickTime('quietHoursEnd', p.quietHoursEnd),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Sécurité ─────────────────────────────────────────────────────────────────

class SecurityPage extends ConsumerWidget {
  const SecurityPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(sessionProvider).value;
    final prefs = ref.watch(devicePrefsProvider);
    final sessions = ref.watch(sessionsProvider);
    if (user == null) return const Scaffold();

    return Scaffold(
      appBar: AppBar(title: const Text('Sécurité')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: Gap.xxl),
        children: [
          const SectionHeader('Verrouillage'),
          SwitchTile(
            title: 'Verrouiller Moneo',
            subtitle: 'Empreinte, visage ou code du téléphone à l’ouverture.',
            value: prefs.biometricLock,
            onChanged: (v) async {
              final bio = ref.read(biometricsProvider);
              if (v && !await bio.available) {
                if (context.mounted) {
                  showMessage(
                    context,
                    'Aucun verrouillage (empreinte, visage ou code) n’est configuré sur ce téléphone.',
                  );
                }
                return;
              }
              // On vérifie que l'utilisateur sait se déverrouiller avant d'activer.
              if (v && !await bio.authenticate()) return;
              ref
                  .read(devicePrefsProvider.notifier)
                  .update((p) => p.copyWith(biometricLock: v));
            },
          ),
          if (prefs.biometricLock)
            GroupTile(
              title: 'Verrouiller après',
              trailing: DropdownButton<int>(
                value: prefs.autoLockMinutes,
                underline: const SizedBox.shrink(),
                items: const [
                  DropdownMenuItem(value: 0, child: Text('Immédiatement')),
                  DropdownMenuItem(value: 1, child: Text('1 minute')),
                  DropdownMenuItem(value: 5, child: Text('5 minutes')),
                  DropdownMenuItem(value: 15, child: Text('15 minutes')),
                ],
                onChanged: (v) => ref
                    .read(devicePrefsProvider.notifier)
                    .update((p) => p.copyWith(autoLockMinutes: v)),
              ),
            ),
          const SectionHeader('Mot de passe'),
          GroupTile(
            icon: Icons.password_rounded,
            title: user.hasPassword
                ? 'Changer le mot de passe'
                : 'Définir un mot de passe',
            subtitle: user.hasPassword
                ? 'Les autres appareils seront déconnectés.'
                : 'Pour vous connecter aussi sans Google.',
            onTap: () => showSheet<void>(context, _PasswordSheet(user: user)),
          ),
          const SectionHeader('Appareils connectés'),
          ...sessions.when(
            loading: () => [const SkeletonList(rows: 2)],
            error: (error, _) => [
              ErrorState(
                error: error,
                onRetry: () => ref.invalidate(sessionsProvider),
              ),
            ],
            data: (items) => [
              for (final s in items)
                GroupTile(
                  icon: s.platform == 'ios'
                      ? Icons.phone_iphone_rounded
                      : (s.platform == 'android'
                            ? Icons.phone_android_rounded
                            : Icons.devices_rounded),
                  title: s.deviceName ?? 'Appareil',
                  subtitle: s.current
                      ? 'Cet appareil'
                      : 'Dernière activité : ${Fmt.relative(s.lastUsedAt).toLowerCase()}',
                  trailing: s.current
                      ? null
                      : TextButton(
                          onPressed: () async {
                            if (await guard(
                              context,
                              () => ref.read(apiProvider).revokeSession(s.id),
                              success: 'Appareil déconnecté',
                            )) {
                              ref.invalidate(sessionsProvider);
                            }
                          },
                          child: const Text('Déconnecter'),
                        ),
                ),
              if (items.length > 1)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Gap.page,
                    vertical: Gap.sm,
                  ),
                  child: OutlinedButton(
                    onPressed: () async {
                      if (await guard(
                        context,
                        () => ref.read(apiProvider).logoutOthers(),
                        success: 'Les autres appareils sont déconnectés',
                      )) {
                        ref.invalidate(sessionsProvider);
                      }
                    },
                    child: const Text('Déconnecter tous les autres appareils'),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PasswordSheet extends ConsumerStatefulWidget {
  const _PasswordSheet({required this.user});
  final AppUser user;

  @override
  ConsumerState<_PasswordSheet> createState() => _PasswordSheetState();
}

class _PasswordSheetState extends ConsumerState<_PasswordSheet> {
  final _form = GlobalKey<FormState>();
  late final _email = TextEditingController(text: widget.user.email);
  final _current = TextEditingController();
  final _next = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _current.dispose();
    _next.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    final ok = await guard(
      context,
      () => ref
          .read(apiProvider)
          .changePassword(
            widget.user.hasPassword ? _current.text : null,
            _next.text,
          ),
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (!ok) return;
    // Le gestionnaire de mots de passe peut mettre à jour son entrée.
    TextInput.finishAutofillContext();
    await ref.read(appDataProvider.notifier).refresh();
    if (mounted) {
      Navigator.pop(context);
      showMessage(context, 'Mot de passe mis à jour');
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Form(
      key: _form,
      child: AutofillGroup(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SheetHeader(
              widget.user.hasPassword
                  ? 'Changer le mot de passe'
                  : 'Définir un mot de passe',
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(Gap.page, 0, Gap.page, Gap.md),
              child: Column(
                children: [
                  // Identifiant en lecture seule : il dit au gestionnaire quelle entrée mettre à jour.
                  EmailField(controller: _email, readOnly: true),
                  if (widget.user.hasPassword) ...[
                    const SizedBox(height: Gap.md),
                    PasswordField(
                      controller: _current,
                      label: 'Mot de passe actuel',
                    ),
                  ],
                  const SizedBox(height: Gap.md),
                  PasswordField(
                    controller: _next,
                    label: 'Nouveau mot de passe',
                    isNew: true,
                    onSubmitted: _save,
                  ),
                  const SizedBox(height: Gap.xl),
                  SubmitButton(
                    label: 'Enregistrer',
                    busy: _busy,
                    onPressed: _save,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// ── Import et export ─────────────────────────────────────────────────────────

/// Choisit un classeur et l'envoie à l'API. Partagé avec l'écran de démarrage.
Future<ImportReport?> importWorkbook(
  BuildContext context,
  WidgetRef ref, {
  required bool replace,
}) async {
  final picked = await FilePicker.pickFiles(
    type: FileType.custom,
    allowedExtensions: const ['xlsm', 'xlsx'],
  );
  final path = picked.isEmpty ? null : picked.first.path;
  if (path == null || !context.mounted) return null;
  try {
    return await ref
        .read(appDataProvider.notifier)
        .mutate((api) => api.importWorkbook(path, replace: replace));
  } catch (error) {
    if (context.mounted) showError(context, error);
    return null;
  }
}

void showImportReport(BuildContext context, ImportReport report) {
  showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Import terminé'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${report.transactions} opérations\n${report.accounts} comptes\n${report.categories} catégories\n${report.recurring} mensualités',
            ),
            if (report.warnings.isNotEmpty) ...[
              const SizedBox(height: Gap.lg),
              Text('À vérifier', style: context.text.titleSmall),
              const SizedBox(height: Gap.xs),
              for (final w in report.warnings.take(8))
                Text('• $w', style: context.text.bodySmall),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Fermer'),
        ),
      ],
    ),
  );
}

class DataPage extends ConsumerStatefulWidget {
  const DataPage({super.key});

  @override
  ConsumerState<DataPage> createState() => _DataPageState();
}

class _DataPageState extends ConsumerState<DataPage> {
  String? _busy;

  Future<void> _import({required bool replace}) async {
    if (replace) {
      final sure = await confirm(
        context,
        title: 'Remplacer toutes mes données ?',
        message:
            'Vos comptes, opérations, catégories, mensualités et budgets actuels seront effacés, puis remplacés par le contenu du classeur.',
        confirmLabel: 'Remplacer',
      );
      if (!sure || !mounted) return;
    }
    setState(() => _busy = replace ? 'replace' : 'merge');
    final report = await importWorkbook(context, ref, replace: replace);
    if (!mounted) return;
    setState(() => _busy = null);
    if (report != null) showImportReport(context, report);
  }

  Future<void> _export(String format) async {
    setState(() => _busy = format);
    await guard(context, () async {
      final content = await ref.read(apiProvider).export(format);
      final file = File(
        '${(await getTemporaryDirectory()).path}/moneo-${Fmt.today()}.$format',
      );
      await file.writeAsString(content);
      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)], subject: 'Export Moneo'),
      );
    });
    if (mounted) setState(() => _busy = null);
  }

  @override
  Widget build(BuildContext context) {
    Widget action(
      String id,
      IconData icon,
      String title,
      String subtitle,
      VoidCallback onTap,
    ) => GroupTile(
      leading: _busy == id
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            )
          : Icon(icon),
      title: title,
      subtitle: subtitle,
      onTap: (_busy == null) ? onTap : null,
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Import et export')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: Gap.xxl),
        children: [
          const SectionHeader('Importer le classeur Comptes'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Gap.page),
            child: Text(
              'Moneo lit le fichier Comptes.xlsm : comptes et soldes de départ, catégories, modes de paiement, mensualités et toutes les écritures, pointage compris.',
              style: context.text.bodyMedium?.copyWith(
                color: context.moneo.inkSoft,
              ),
            ),
          ),
          action(
            'merge',
            Icons.merge_rounded,
            'Ajouter à mes données',
            'Les comptes et catégories existants sont réutilisés.',
            () => _import(replace: false),
          ),
          action(
            'replace',
            Icons.restart_alt_rounded,
            'Remplacer mes données',
            'Repart du classeur : tout le reste est effacé.',
            () => _import(replace: true),
          ),
          const SectionHeader('Exporter'),
          action(
            'csv',
            Icons.table_chart_rounded,
            'Écritures au format CSV',
            'S’ouvre dans Excel, mêmes colonnes que le classeur.',
            () => _export('csv'),
          ),
          action(
            'json',
            Icons.backup_rounded,
            'Sauvegarde complète',
            'Fichier JSON avec toutes vos données.',
            () => _export('json'),
          ),
        ],
      ),
    );
  }
}
