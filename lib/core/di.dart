import 'package:get_it/get_it.dart';
import 'package:moneo/core/repositories/bank_account_repository.dart';
import 'package:moneo/core/repositories/category_repository.dart';
import 'package:moneo/core/repositories/monthly_payment_repository.dart';
import 'package:moneo/core/repositories/payment_method_repository.dart';
import 'package:moneo/core/repositories/transaction_repository.dart';
import 'package:moneo/core/services/monthly_processor.dart';
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
  getIt.registerSingleton<AppDatabase>(AppDatabase());
  getIt.registerSingleton<ApiClient>(ApiClient());

  getIt.registerLazySingleton<IAppUserService>(() => AppUserService(getIt<AppDatabase>(), getIt<ApiClient>()));
  getIt.registerLazySingleton(() => TransactionRepository(getIt<AppDatabase>(), getIt<ApiClient>()));
  getIt.registerLazySingleton(() => BankAccountRepository(getIt<AppDatabase>(), getIt<ApiClient>()));
  getIt.registerLazySingleton(() => CategoryRepository(getIt<AppDatabase>(), getIt<ApiClient>()));
  getIt.registerLazySingleton(() => MonthlyPaymentRepository(getIt<AppDatabase>(), getIt<ApiClient>()));
  getIt.registerLazySingleton(() => PaymentMethodRepository(getIt<AppDatabase>(), getIt<ApiClient>()));
  getIt.registerLazySingleton(() => MonthlyProcessor(getIt<AppDatabase>(), getIt<TransactionRepository>()));

  getIt.registerLazySingleton<IAuthService>(() => AuthService(getIt<IAppUserService>()));

  getIt.registerSingleton<AuthViewModel>(AuthViewModel(getIt<IAuthService>()));
  getIt.registerSingleton<HomeViewModel>(HomeViewModel(
    getIt<TransactionRepository>(),
    getIt<BankAccountRepository>(),
    getIt<CategoryRepository>(),
    getIt<MonthlyPaymentRepository>(),
    getIt<MonthlyProcessor>(),
  ));
  
  getIt.registerSingleton<AuthNotifier>(AuthNotifier(getIt<IAuthService>()));
  getIt.registerLazySingleton(() => SyncService(getIt<AppDatabase>()));
}