import 'package:go_router/go_router.dart';
import '../../presentation/views/login_page.dart';
import '../di.dart';
import '../notifiers/auth_notifier.dart';
import '../services/auth_service.dart';
import 'app_routes.dart';

final authNotifier = AuthNotifier(getIt<IAuthService>());

final List<String> unauthenticatedRoutes = [
  AppRoutes.login,
  AppRoutes.register,
];

final GoRouter appRouter = GoRouter(
  refreshListenable: authNotifier,
  initialLocation: AppRoutes.login,
  redirect: (context, state) async {
    final loggedIn = authNotifier.isAuthenticated;
    final loggingIn = state.matchedLocation == AppRoutes.login;

    if (!loggedIn) {
      if (!unauthenticatedRoutes.contains(state.matchedLocation)) {
        return AppRoutes.login;
      }
      return null;
    }

    if (loggingIn) {
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
  ],
);