import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../core/format.dart';
import '../data/models.dart';
import '../state/providers.dart';
import '../state/services.dart';
import 'settings/settings_pages.dart';
import 'theme/theme.dart';
import 'widgets/common.dart';

/// Coque de l'app : le contenu se place au-dessus de la barre de navigation flottante en verre.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.shell});
  final StatefulNavigationShell shell;

  static const _items = <DockItem>[
    (
      icon: Icons.account_balance_wallet_outlined,
      activeIcon: Icons.account_balance_wallet_rounded,
      label: 'Comptes',
    ),
    (
      icon: Icons.insights_outlined,
      activeIcon: Icons.insights_rounded,
      label: 'Analyses',
    ),
    (
      icon: Icons.event_repeat_outlined,
      activeIcon: Icons.event_repeat_rounded,
      label: 'Mensuel',
    ),
    (
      icon: Icons.savings_outlined,
      activeIcon: Icons.savings_rounded,
      label: 'Budgets',
    ),
    (
      icon: Icons.tune_outlined,
      activeIcon: Icons.tune_rounded,
      label: 'Réglages',
    ),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    // Le contenu s'arrête au-dessus de la barre : rien ne passe dessous.
    body: shell,
    bottomNavigationBar: FloatingDock(
      items: _items,
      index: shell.currentIndex,
      // Rappuyer sur l'onglet courant ramène à sa racine.
      onTap: (index) =>
          shell.goBranch(index, initialLocation: index == shell.currentIndex),
    ),
  );
}

/// Écran d'attente pendant la lecture de la session au lancement.
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: SvgPicture.asset(
        'assets/images/Moneo.svg',
        width: 96,
        height: 96,
        semanticsLabel: 'Moneo',
      ),
    ),
  );
}

/// Verrou biométrique. Affiché par-dessus toute l'app tant qu'elle n'est pas déverrouillée.
class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  bool _asking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _unlock());
  }

  Future<void> _unlock() async {
    if (_asking) return;
    setState(() => _asking = true);
    final ok = await ref.read(biometricsProvider).authenticate();
    if (!mounted) return;
    setState(() => _asking = false);
    if (ok) ref.read(lockProvider.notifier).unlock();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(Gap.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SvgPicture.asset(
              'assets/images/Moneo.svg',
              width: 80,
              height: 80,
              semanticsLabel: 'Moneo',
            ),
            const SizedBox(height: Gap.xl),
            Text(
              'Moneo est verrouillé',
              style: context.text.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Gap.sm),
            Text(
              'Déverrouillez pour consulter vos comptes.',
              style: context.text.bodyLarge?.copyWith(
                color: context.moneo.inkSoft,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Gap.xxl),
            SubmitButton(
              label: 'Déverrouiller',
              icon: Icons.lock_open_rounded,
              busy: _asking,
              onPressed: _unlock,
            ),
            TextButton(
              onPressed: () => ref.read(sessionProvider.notifier).logout(),
              child: const Text('Se déconnecter'),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Premier lancement : reprendre son classeur, ou créer un premier compte.
class SetupPage extends ConsumerStatefulWidget {
  const SetupPage({super.key});

  @override
  ConsumerState<SetupPage> createState() => _SetupPageState();
}

class _SetupPageState extends ConsumerState<SetupPage> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController(text: 'Compte courant');
  final _balance = TextEditingController();
  bool _busy = false;
  bool _importing = false;

  @override
  void dispose() {
    _name.dispose();
    _balance.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    final user = await ref.read(apiProvider).updateProfile({
      'hasCompletedSetup': true,
    });
    ref.read(sessionProvider.notifier).setUser(user);
  }

  Future<void> _create() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    await guard(context, () async {
      await ref
          .read(appDataProvider.notifier)
          .mutate(
            (api) => api.saveAccount(null, {
              'name': _name.text.trim(),
              'initialBalance': Fmt.parseAmount(_balance.text) ?? 0,
            }),
          );
      await _finish();
    });
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _import() async {
    setState(() => _importing = true);
    final report = await importWorkbook(context, ref, replace: true);
    if (!mounted) return;
    setState(() => _importing = false);
    if (report == null) return;
    await guard(context, _finish);
    if (mounted) {
      showMessage(context, '${report.transactions} opérations importées');
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = ref.watch(sessionProvider).value?.username ?? '';
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(Gap.page),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Bienvenue${name.isEmpty ? '' : ', $name'}',
                      style: context.text.headlineMedium,
                    ),
                    const SizedBox(height: Gap.sm),
                    Text(
                      'Commençons par votre premier compte. Indiquez son solde actuel : c’est de là que part votre suivi.',
                      style: context.text.bodyLarge?.copyWith(
                        color: context.moneo.inkSoft,
                      ),
                    ),
                    const SizedBox(height: Gap.xl),
                    TextFormField(
                      controller: _name,
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.next,
                      validator: (v) => (v?.trim().isEmpty ?? true)
                          ? 'Donnez un nom au compte'
                          : null,
                      decoration: const InputDecoration(
                        labelText: 'Nom du compte',
                      ),
                    ),
                    const SizedBox(height: Gap.md),
                    TextFormField(
                      controller: _balance,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _create(),
                      decoration: const InputDecoration(
                        labelText: 'Solde actuel',
                        hintText: '0,00',
                        suffixText: '€',
                        helperText:
                            'Vous pourrez le corriger plus tard dans les réglages.',
                      ),
                    ),
                    const SizedBox(height: Gap.xl),
                    SubmitButton(
                      label: 'Créer mon compte',
                      busy: _busy,
                      onPressed: _importing ? null : _create,
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: Gap.xl),
                      child: Perforation(),
                    ),
                    Text(
                      'Vous teniez vos comptes dans le classeur Excel ?',
                      style: context.text.titleMedium,
                    ),
                    const SizedBox(height: Gap.xs),
                    Text(
                      'Importez Comptes.xlsm : comptes, catégories, mensualités et tout l’historique sont repris, pointage compris.',
                      style: context.text.bodyMedium?.copyWith(
                        color: context.moneo.inkSoft,
                      ),
                    ),
                    const SizedBox(height: Gap.md),
                    OutlinedButton.icon(
                      onPressed: _busy || _importing ? null : _import,
                      icon: _importing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.upload_file_rounded),
                      label: Text(
                        _importing
                            ? 'Import en cours…'
                            : 'Importer mon classeur',
                      ),
                    ),
                    const SizedBox(height: Gap.lg),
                    TextButton(
                      onPressed: () =>
                          ref.read(sessionProvider.notifier).logout(),
                      child: const Text('Se déconnecter'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Centre de notifications.
class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
  @override
  void initState() {
    super.initState();
    // Ouvrir le centre vaut lecture : le compteur de l'accueil revient à zéro.
    Future.microtask(() async {
      try {
        await ref.read(apiProvider).markNotificationsRead();
        await ref.read(appDataProvider.notifier).refresh();
      } catch (_) {}
    });
  }

  static IconData _icon(String type) => switch (type) {
    'low_balance' => Icons.trending_down_rounded,
    'budget_alert' => Icons.savings_rounded,
    'upcoming_payment' ||
    'payment_applied' ||
    'recurring_pending' => Icons.event_repeat_rounded,
    'monthly_recap' => Icons.insights_rounded,
    _ => Icons.notifications_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final list = ref.watch(notificationsProvider);
    final items = list.value ?? const <AppNotification>[];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (items.isNotEmpty)
            TextButton(
              onPressed: () async {
                if (await guard(
                  context,
                  () => ref.read(apiProvider).clearNotifications(),
                )) {
                  ref.invalidate(notificationsProvider);
                }
              },
              child: const Text('Tout effacer'),
            ),
          const SizedBox(width: Gap.sm),
        ],
      ),
      body: list.when(
        skipLoadingOnReload: true,
        loading: () => const SkeletonList(),
        error: (error, _) => Center(
          child: ErrorState(
            error: error,
            onRetry: () => ref.invalidate(notificationsProvider),
          ),
        ),
        data: (items) => items.isEmpty
            ? const Center(
                child: EmptyState(
                  icon: Icons.notifications_none_rounded,
                  title: 'Rien à signaler',
                  message:
                      'Les alertes de solde, de budget et d’échéance apparaîtront ici.',
                ),
              )
            : ListView.separated(
                itemCount: items.length,
                separatorBuilder: (_, _) => const Divider(indent: 72),
                itemBuilder: (context, i) {
                  final n = items[i];
                  return GroupTile(
                    leading: Icon(
                      _icon(n.type),
                      color: n.read
                          ? context.moneo.inkSoft
                          : context.scheme.primary,
                    ),
                    title: n.title,
                    subtitle: '${n.body}\n${Fmt.relative(n.createdAt)}',
                    onTap: switch (n.type) {
                      'budget_alert' => () => context.go('/budgets'),
                      'upcoming_payment' ||
                      'payment_applied' ||
                      'recurring_pending' => () => context.go('/plan'),
                      'monthly_recap' => () => context.go('/insights'),
                      _ => () => context.go('/'),
                    },
                  );
                },
              ),
      ),
    );
  }
}
