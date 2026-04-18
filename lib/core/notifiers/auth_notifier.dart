import 'package:flutter/material.dart';
import '../../core/services/auth_service.dart';
import '../../data/models/app_user_model.dart';

class AuthNotifier extends ChangeNotifier {
  final IAuthService _authService;
  AppUser? _appUser;
  bool _isLoadingProfile = true;

  AuthNotifier(this._authService) {
    _authService.authStateChanges.listen((user) async {
      _appUser = user;
      
      _isLoadingProfile = false;
      notifyListeners();
    });
  }

  bool get isAuthenticated => _appUser != null;
  bool get isLoadingProfile => _isLoadingProfile;
  AppUser? get appUser => _appUser;

  void refreshProfile(AppUser updatedUser) {
    _appUser = updatedUser;
    notifyListeners();
  }
}