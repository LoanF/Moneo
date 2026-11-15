import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'state/providers.dart';
import 'state/services.dart';
import 'ui/auth/auth_pages.dart';
import 'ui/home/home_page.dart';
import 'ui/home/search_page.dart';
import 'ui/insights/insights_page.dart';
import 'ui/plan/plan_pages.dart';
import 'ui/settings/catalog_pages.dart';
import 'ui/settings/settings_pages.dart';
import 'ui/shell.dart';
import 'ui/theme/theme.dart';

const _publicRoutes = {'/login', '/register', '/forgot-password'};

/// Routes de l'app. La redirection suit l'état de la session : connexion, vérification
/// de l'adresse, premier lancement, puis l'app elle-même.
final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier(0);
  ref.listen(sessionProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: refresh,
    redirect: (context, state) {
      final session = ref.read(sessionProvider);
      final path = state.matchedLocation;
      if (session.isLoading && !session.hasValue) {
        return path == '/splash' ? null : '/splash';
      }
      final user = session.value;
      if (user == null) return _publicRoutes.contains(path) ? null : '/login';
      if (!user.emailVerified) {
        return path == '/verify-email' ? null : '/verify-email';
      }
      if (!user.hasCompletedSetup) return path == '/setup' ? null : '/setup';
      if (_publicRoutes.contains(path) ||
          path == '/splash' ||
          path == '/verify-email' ||
          path == '/setup') {
        return '/';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, _) => const SplashPage()),
      GoRoute(path: '/login', builder: (_, _) => const LoginPage()),
      GoRoute(path: '/register', builder: (_, _) => const RegisterPage()),
      GoRoute(
        path: '/forgot-password',
        builder: (_, state) =>
            ForgotPasswordPage(initialEmail: state.extra as String? ?? ''),
      ),
      GoRoute(
        path: '/verify-email',
        builder: (_, _) => const VerifyEmailPage(),
      ),
      GoRoute(path: '/setup', builder: (_, _) => const SetupPage()),
      GoRoute(
        path: '/search',
        builder: (_, state) => SearchPage(accountId: state.extra as String?),
      ),
      GoRoute(
        path: '/notifications',
        builder: (_, _) => const NotificationsPage(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => AppShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [GoRoute(path: '/', builder: (_, _) => const HomePage())],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/insights',
                builder: (_, _) => const InsightsPage(),
                routes: [
                  GoRoute(path: 'pivot', builder: (_, _) => const PivotPage()),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/plan', builder: (_, _) => const RecurringPage()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/budgets', builder: (_, _) => const BudgetsPage()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (_, _) => const SettingsPage(),
                routes: [
                  GoRoute(
                    path: 'profile',
                    builder: (_, _) => const ProfilePage(),
                  ),
                  GoRoute(
                    path: 'accounts',
                    builder: (_, _) => const AccountsPage(),
                  ),
                  GoRoute(
                    path: 'categories',
                    builder: (_, _) => const CategoriesPage(),
                  ),
                  GoRoute(
                    path: 'payment-methods',
                    builder: (_, _) => const PaymentMethodsPage(),
                  ),
                  GoRoute(path: 'data', builder: (_, _) => const DataPage()),
                  GoRoute(
                    path: 'preferences',
                    builder: (_, _) => const PreferencesPage(),
                  ),
                  GoRoute(
                    path: 'notifications',
                    builder: (_, _) => const NotificationSettingsPage(),
                  ),
                  GoRoute(
                    path: 'security',
                    builder: (_, _) => const SecurityPage(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

class MoneoApp extends ConsumerStatefulWidget {
  const MoneoApp({super.key});

  @override
  ConsumerState<MoneoApp> createState() => _MoneoAppState();
}

class _MoneoAppState extends ConsumerState<MoneoApp>
    with WidgetsBindingObserver {
  DateTime? _backgroundedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _backgroundedAt = DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      final prefs = ref.read(devicePrefsProvider);
      final away = _backgroundedAt == null
          ? Duration.zero
          : DateTime.now().difference(_backgroundedAt!);
      if (prefs.biometricLock &&
          _backgroundedAt != null &&
          away.inMinutes >= prefs.autoLockMinutes) {
        ref.read(lockProvider.notifier).lock();
      }
      _backgroundedAt = null;
      // Au retour au premier plan, on rattrape ce qui a changé ailleurs.
      if (ref.read(sessionProvider).value != null) {
        unawaited(ref.read(appDataProvider.notifier).refresh());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // À chaque ouverture de session, l'appareil transmet son jeton push s'il est déjà autorisé.
    ref.listen(sessionProvider.select((s) => s.value?.id), (previous, next) {
      if (next != null && next != previous) {
        unawaited(ref.read(pushServiceProvider).sync());
      }
    });
    final prefs = ref.watch(devicePrefsProvider);
    final locked = ref.watch(lockProvider);
    final signedIn = ref.watch(sessionProvider.select((s) => s.value != null));

    return MaterialApp.router(
      title: 'Moneo',
      debugShowCheckedModeBanner: false,
      routerConfig: ref.watch(routerProvider),
      theme: MoneoTheme.light(),
      darkTheme: MoneoTheme.dark(),
      themeMode: prefs.themeMode,
      locale: const Locale('fr', 'FR'),
      supportedLocales: const [Locale('fr', 'FR')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      // go_router et fl_chart importent encore l'ancien `package:flutter/material.dart` : le pont leur
      // transmet le thème et les traductions. À retirer quand ces paquets auront migré.
      // ignore: deprecated_member_use
      builder: (context, child) => MaterialUiCompatibilityBridge(
        // Les textes suivent la taille choisie dans le système, sans dépasser un facteur
        // au-delà duquel les lignes d'opérations ne tiennent plus.
        child: MediaQuery.withClampedTextScaling(
          maxScaleFactor: 1.6,
          child: locked && signedIn && prefs.biometricLock
              ? const LockScreen()
              : child!,
        ),
      ),
    );
  }
}
