import 'package:go_router/go_router.dart';
import 'package:moneo/presentation/views/accounts_manager_page.dart';
import 'package:moneo/presentation/views/edit_profile_page.dart';
import 'package:moneo/presentation/views/home_page.dart';
import 'package:moneo/presentation/views/settings_page.dart';
import '../../presentation/views/categories_manager_page.dart';
import '../../presentation/views/login_page.dart';
import '../../presentation/views/register_page.dart';
import '../../presentation/views/setup_page.dart';
import '../di.dart';
import '../notifiers/auth_notifier.dart';
import 'app_routes.dart';

final List<String> unauthenticatedRoutes = [
  AppRoutes.login,
  AppRoutes.register,
];

final GoRouter appRouter = GoRouter(
  refreshListenable: getIt<AuthNotifier>(),
  initialLocation: AppRoutes.login,
  redirect: (context, state) async {
    final authNotifier = getIt<AuthNotifier>();
    final loggedIn = authNotifier.isAuthenticated;
    final user = authNotifier.appUser;

    if (!loggedIn) {
      return unauthenticatedRoutes.contains(state.matchedLocation) ? null : AppRoutes.login;
    }

    if (authNotifier.isLoadingProfile) return null;

    final appUser = authNotifier.appUser;

    if (appUser != null && !appUser.hasCompletedSetup) {
      if (state.matchedLocation != AppRoutes.setup) {
        return AppRoutes.setup;
      }
      return null;
    }

    if (user != null && user.hasCompletedSetup) {
      if (state.matchedLocation == AppRoutes.login || state.matchedLocation == AppRoutes.setup) {
        return AppRoutes.home;
      }
      return null;
    }

    final isGoingToAuthOrSetup = state.matchedLocation == AppRoutes.login ||
        state.matchedLocation == AppRoutes.register ||
        state.matchedLocation == AppRoutes.setup;

    if (isGoingToAuthOrSetup) {
      return AppRoutes.home;
    }

    return null;
  },
  routes: [
    GoRoute(
      path: AppRoutes.login,
      name: 'login',
      builder: (context, state) => LoginPage(),
    ),
    GoRoute(
      path: AppRoutes.register,
      name: 'register',
      builder: (context, state) => RegisterPage(),
    ),
    GoRoute(
      path: AppRoutes.home,
      name: 'home',
      builder: (context, state) => HomePage(),
    ),
    GoRoute(
      path: AppRoutes.settings,
      name: 'settings',
      builder: (context, state) => SettingsPage(),
    ),
    GoRoute(
      path: AppRoutes.setup,
      name: 'setup',
      builder: (context, state) => const SetupPage(),
    ),
    GoRoute(
      path: AppRoutes.categoriesManager,
      name: 'categoriesManager',
      builder: (context, state) => const CategoriesManagerPage(),
    ),
    GoRoute(
      path: AppRoutes.profile,
      name: 'profile',
      builder: (context, state) => const EditProfilePage(),
    ),
    GoRoute(
      path: AppRoutes.accountsManager,
      name: 'accountsManager',
      builder: (context, state) => const AccountsManagerPage(),
    ),
  ],
);