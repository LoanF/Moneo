import 'package:get_it/get_it.dart';
import 'package:moneo/core/repositories/bank_account_repository.dart';
import 'package:moneo/core/repositories/category_repository.dart';
import 'package:moneo/core/repositories/monthly_payment_repository.dart';
import 'package:moneo/core/repositories/payment_method_repository.dart';
import 'package:moneo/core/repositories/transaction_repository.dart';
import '../core/services/user_service.dart';
import '../presentation/view_models/home_view_model.dart';
import '../presentation/view_models/auth_view_model.dart';
import '../presentation/view_models/stats_view_model.dart';
import 'interceptor/api_client.dart';
import 'notifiers/auth_notifier.dart';
import 'notifiers/lock_notifier.dart';
import 'services/auth_service.dart';
import 'services/biometric_service.dart';
import 'services/realtime_service.dart';

final getIt = GetIt.instance;

void configureDependencies() {
  getIt.registerSingleton<ApiClient>(ApiClient());
  getIt.registerSingleton<BiometricService>(BiometricService());
  getIt.registerSingleton<LockNotifier>(LockNotifier(getIt<BiometricService>()));
  getIt.registerSingleton<RealtimeService>(RealtimeService());

  getIt.registerLazySingleton<IAppUserService>(() => AppUserService(getIt<ApiClient>()));
  getIt.registerLazySingleton(() => TransactionRepository(getIt<ApiClient>()));
  getIt.registerLazySingleton(() => BankAccountRepository(getIt<ApiClient>()));
  getIt.registerLazySingleton(() => CategoryRepository(getIt<ApiClient>()));
  getIt.registerLazySingleton(() => MonthlyPaymentRepository(getIt<ApiClient>()));
  getIt.registerLazySingleton(() => PaymentMethodRepository(getIt<ApiClient>()));

  getIt.registerLazySingleton<IAuthService>(() => AuthService(getIt<IAppUserService>()));

  getIt.registerSingleton<AuthViewModel>(AuthViewModel(getIt<IAuthService>()));
  getIt.registerSingleton<HomeViewModel>(HomeViewModel(
    getIt<TransactionRepository>(),
    getIt<BankAccountRepository>(),
    getIt<CategoryRepository>(),
    getIt<MonthlyPaymentRepository>(),
    getIt<PaymentMethodRepository>(),
    getIt<RealtimeService>(),
  ));

  getIt.registerSingleton<StatsViewModel>(StatsViewModel(getIt<TransactionRepository>(), getIt<CategoryRepository>(), getIt<RealtimeService>()));
  getIt.registerSingleton<AuthNotifier>(AuthNotifier(getIt<IAuthService>()));
}