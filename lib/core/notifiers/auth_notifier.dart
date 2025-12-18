import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/services/auth_service.dart';
import '../../data/models/app_user_model.dart';
import '../services/user_service.dart';

class AuthNotifier extends ChangeNotifier {
  final IAuthService _authService;
  final IAppUserService _userService;
  User? _user;
  AppUser? _appUser;
  bool _isLoadingProfile = true;

  AuthNotifier(this._authService, this._userService) {
    _authService.authStateChanges.listen((user) async {
      _user = user;
      if (user != null) {
        _isLoadingProfile = true;
        notifyListeners();

        _appUser = await _userService.getUserById(user.uid);
      } else {
        _appUser = null;
      }
      _isLoadingProfile = false;
      notifyListeners();
    });
  }

  bool get isAuthenticated => _user != null;
  bool get isLoadingProfile => _isLoadingProfile;
  AppUser? get appUser => _appUser;

  void refreshProfile(AppUser updatedUser) {
    _appUser = updatedUser;
    notifyListeners();
  }
}