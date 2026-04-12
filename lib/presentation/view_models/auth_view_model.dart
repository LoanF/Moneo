import 'dart:io';
import 'package:uuid/uuid.dart';
import '../../core/di.dart';
import '../../core/notifiers/auth_notifier.dart';
import '../../core/repositories/bank_account_repository.dart';
import '../../core/repositories/payment_method_repository.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/user_service.dart';
import '../../data/models/app_user_model.dart';
import 'common_view_model.dart';

class AuthViewModel extends CommonViewModel {
  final IAuthService _authService;
  final IAppUserService _appUserService = getIt<IAppUserService>();
  final BankAccountRepository _accountRepo = getIt<BankAccountRepository>();
  final PaymentMethodRepository _paymentMethodRepo = getIt<PaymentMethodRepository>();
  final _uuid = const Uuid();

  AuthViewModel(this._authService);

  AppUser? get currentUser => _authService.currentUser;

  Future<bool> login(String email, String password) async {
    isLoading = true;
    errorMessage = null;
    try {
      await _authService.signInWithEmail(email, password);
      isLoading = false;
      return true;
    } catch (e) {
      isLoading = false;
      errorMessage = e.toString();
      return false;
    }
  }

  Future<bool> loginWithGoogle() async {
    isLoading = true;
    errorMessage = null;
    try {
      await _authService.signInWithGoogle();
      isLoading = false;
      return true;
    } catch (e) {
      isLoading = false;
      errorMessage = "Erreur de connexion Google : $e";
      return false;
    }
  }

  Future<bool> register(String email, String password) async {
    isLoading = true;
    errorMessage = null;
    try {
      final username = email.split('@')[0];
      await _authService.register(username, email, password);
      isLoading = false;
      return true;
    } catch (e) {
      isLoading = false;
      errorMessage = e.toString();
      return false;
    }
  }

  Future<void> logout() async {
    await _authService.signOut();
  }

  Future<bool> forgotPassword(String email) async {
    isLoading = true;
    errorMessage = null;
    try {
      await _authService.forgotPassword(email);
      isLoading = false;
      return true;
    } catch (e) {
      isLoading = false;
      errorMessage = e.toString();
      return false;
    }
  }

  Future<bool> resetPassword(String email, String code, String newPassword) async {
    isLoading = true;
    errorMessage = null;
    try {
      await _authService.resetPassword(email, code, newPassword);
      isLoading = false;
      return true;
    } catch (e) {
      isLoading = false;
      errorMessage = e.toString();
      return false;
    }
  }

  Future<bool> verifyEmail(String code) async {
    isLoading = true;
    errorMessage = null;
    try {
      await _authService.verifyEmail(code);
      isLoading = false;
      return true;
    } catch (e) {
      isLoading = false;
      errorMessage = e.toString();
      return false;
    }
  }

  Future<bool> resendVerification() async {
    isLoading = true;
    errorMessage = null;
    try {
      await _authService.resendVerification();
      isLoading = false;
      return true;
    } catch (e) {
      isLoading = false;
      errorMessage = e.toString();
      return false;
    }
  }

  Future<bool> updateProfile({required String newName, File? newImageFile}) async {
    isLoading = true;
    errorMessage = null;
    try {
      final user = _authService.currentUser;
      if (user == null) throw Exception("Utilisateur non connecté");
      final updatedAppUser = user.copyWith(
        username: newName.isNotEmpty ? newName : user.username,
      );
      await _appUserService.updateUser(updatedAppUser);
      getIt<AuthNotifier>().refreshProfile(updatedAppUser);
      isLoading = false;
      return true;
    } catch (e) {
      isLoading = false;
      errorMessage = "Erreur mise à jour : $e";
      return false;
    }
  }

  Future<bool> completeSetup({
    required List<Map<String, dynamic>> accounts,
    required List<Map<String, dynamic>> paymentMethods,
  }) async {
    isLoading = true;
    errorMessage = null;
    try {
      final user = _authService.currentUser;
      if (user == null) throw Exception("Utilisateur non connecté");

      for (var data in accounts) {
        await _accountRepo.createAccount(
          id: _uuid.v4(),
          name: data['name'] as String,
          balance: (data['balance'] as num).toDouble(),
        );
      }

      for (var data in paymentMethods) {
        await _paymentMethodRepo.createPaymentMethod(
          id: _uuid.v4(),
          name: data['name'] as String,
          type: data['type'] as String? ?? 'debit',
        );
      }

      final updatedAppUser = user.copyWith(hasCompletedSetup: true);
      await _appUserService.updateUser(updatedAppUser);
      getIt<AuthNotifier>().refreshProfile(updatedAppUser);

      isLoading = false;
      return true;
    } catch (e) {
      isLoading = false;
      errorMessage = "Erreur lors de la configuration : $e";
      return false;
    }
  }
}
