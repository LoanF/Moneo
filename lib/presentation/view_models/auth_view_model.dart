import 'dart:io';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../core/database/app_database.dart';
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

  Future<bool> updateProfile({
    required String newName,
    File? newImageFile,
  }) async {
    isLoading = true;
    errorMessage = null;

    try {
      final user = _authService.currentUser;
      if (user == null) throw Exception("Utilisateur non connecté");

      String? photoUrl;

      // TODO: Implémenter l'upload de l'image de profil
      // if (newImageFile != null) {
      //   // Supposons que votre UserService possède une méthode pour uploader l'image sur votre serveur
      //   photoUrl = await _appUserService.uploadProfileImage(newImageFile);
      // }

      final updatedAppUser = user.copyWith(
        username: newName.isNotEmpty ? newName : user.username,
        photoUrl: photoUrl ?? user.photoUrl,
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
        final id = _uuid.v4();

        await _accountRepo.createAccount(BankAccountsCompanion.insert(
          id: id,
          name: data['name'],
          balance: Value((data['balance'] as num).toDouble()),
        ));
      }

      for (var data in paymentMethods) {
        final id = _uuid.v4();
        await _paymentMethodRepo.createPaymentMethod(PaymentMethodsCompanion.insert(
          id: id,
          name: data['name'] as String,
          type: Value(data['type'] as String? ?? 'debit'),
        ));
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