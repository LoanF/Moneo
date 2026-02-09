import 'package:get_it/get_it.dart';
import 'package:moneo/core/repositories/bank_account_repository.dart';
import 'package:moneo/core/repositories/transaction_repository.dart';
import 'package:moneo/core/services/sync_service.dart';
import '../core/services/user_service.dart';
import '../presentation/view_models/home_view_model.dart';
import '../presentation/view_models/auth_view_model.dart';
import 'database/app_database.dart';
import 'interceptor/api_client.dart';
import 'notifiers/auth_notifier.dart';
import 'services/auth_service.dart';

final getIt = GetIt.instance;

void configureDependencies() {
  getIt.registerLazySingleton<IAppUserService>(() => AppUserService());
  getIt.registerLazySingleton<IAuthService>(() => AuthService(getIt<IAppUserService>()));
  getIt.registerSingleton<AuthViewModel>(AuthViewModel());
  getIt.registerSingleton<HomeViewModel>(HomeViewModel(getIt<IAppUserService>()));
  getIt.registerSingleton<AuthNotifier>(AuthNotifier(getIt<IAuthService>()));
  getIt.registerSingleton<ApiClient>(ApiClient());
  getIt.registerLazySingleton(() => TransactionRepository(getIt<AppDatabase>(), getIt<ApiClient>()));
  getIt.registerLazySingleton(() => BankAccountRepository(getIt<AppDatabase>(), getIt<ApiClient>()));
  getIt.registerLazySingleton(() => SyncService(getIt<AppDatabase>()));
}