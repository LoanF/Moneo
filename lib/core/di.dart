import 'package:get_it/get_it.dart';
import '../core/services/user_service.dart';
import '../presentation/view_models/home_view_model.dart';
import '../presentation/view_models/auth_view_model.dart';
import 'notifiers/auth_notifier.dart';
import 'services/auth_service.dart';

final getIt = GetIt.instance;

void configureDependencies() {
  getIt.registerLazySingleton<IAppUserService>(() => AppUserService());
  getIt.registerLazySingleton<IAuthService>(() => AuthService(getIt<IAppUserService>()));
  getIt.registerSingleton<AuthViewModel>(AuthViewModel());
  getIt.registerSingleton<HomeViewModel>(HomeViewModel());
  getIt.registerSingleton<AuthNotifier>(AuthNotifier(getIt<IAuthService>(), getIt<IAppUserService>()));
}