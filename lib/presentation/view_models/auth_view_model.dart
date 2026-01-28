import 'dart:io';

import '../../core/di.dart';
import '../../core/notifiers/auth_notifier.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/user_service.dart';
import '../../data/enums/auth_exception_code_enum.dart';
import '../../data/enums/storage_child_enum.dart';
import '../../data/models/account_model.dart';
import '../../data/models/app_user_model.dart';
import 'common_view_model.dart';

class AuthViewModel extends CommonViewModel {
  final IAuthService _auth = getIt<IAuthService>();
  final IAppUserService _appUserService = getIt<IAppUserService>();

  AppUser? get currentUser => _auth.currentUser;

  Future<bool> login(String email, String password) async {
    isLoading = true;
    errorMessage = null;

    try {
      await _auth.signInWithEmail(email, password);
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
      await _auth.signInWithGoogle();
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
      await _auth.register(username, email, password);
      isLoading = false;
      return true;
    } catch (e) {
      isLoading = false;
      errorMessage = e.toString();
      return false;
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  Future<bool> updateProfile({
    required String newName,
    File? newImageFile,
  }) async {
    isLoading = true;
    errorMessage = null;

    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception("Utilisateur non connecté");

      String? photoUrl;

      // TODO: Implémenter l'upload de l'image de profil
      // if (newImageFile != null) {
      //   // Supposons que votre UserService possède une méthode pour uploader l'image sur votre serveur
      //   photoUrl = await _appUserService.uploadProfileImage(newImageFile);
      // }

      final updatedAppUser = user.copyWith(
        displayName: newName.isNotEmpty ? newName : user.displayName,
        photoURL: photoUrl ?? user.photoURL,
      );

      if (updatedAppUser == null) throw Exception("Profil introuvable");
      
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
      final uid = currentUser?.uid;
      if (uid == null) throw Exception("Utilisateur non connecté");

      for (var data in accounts) {
        final String accountId = "${DateTime.now().millisecondsSinceEpoch}_${data['name']}";

        final account = Account(
          id: accountId,
          name: data['name'],
          initialBalance: (data['balance'] as num).toDouble(),
          currentBalance: (data['balance'] as num).toDouble(),
        );

        await _appUserService.createAccount(uid, account);
      }

      final currentUserProfile = _appUserService.currentAppUser;
      if (currentUserProfile == null) throw Exception("Profil introuvable");

      final updatedAppUser = currentUserProfile.copyWith(
        hasCompletedSetup: true,
        paymentMethods: paymentMethods,
      );
      
      if (updatedAppUser == null) throw Exception("Profil introuvable");

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