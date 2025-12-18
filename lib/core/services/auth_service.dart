import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../data/models/app_user_model.dart';
import 'user_service.dart';

abstract class IAuthService {
  Stream<User?> get authStateChanges;
  Future<void> signInWithEmail(String email, String password);
  Future<void> signInWithGoogle();
  Future<void> signOut();
  Future<void> createUserWithEmailAndPassword(String email, String password);
  User? get currentUser;
}

class AuthService implements IAuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final IAppUserService _appUserService;

  AuthService(this._appUserService);

  @override
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  @override
  Future<void> signInWithEmail(String email, String password) async {
    email = email.trim().toLowerCase();
    await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password.trim(),
    );
    _appUserService.updateUser(_appUserService.currentAppUser!);
  }

  @override
  Future<void> signInWithGoogle() async {
    await GoogleSignIn.instance.initialize();
    final GoogleSignInAccount googleUser = await GoogleSignIn.instance.authenticate();
    final GoogleSignInAuthentication googleAuth = googleUser.authentication;
    final credential = GoogleAuthProvider.credential(idToken: googleAuth.idToken);

    final UserCredential userCredential = await _firebaseAuth.signInWithCredential(credential);
    final User? user = userCredential.user;

    if (user != null) {
      final existingUser = await _appUserService.getUserById(user.uid);

      if (existingUser == null) {
        final newUser = AppUser(
          uid: user.uid,
          displayName: user.displayName ?? '',
          email: user.email ?? '',
          photoURL: user.photoURL ?? '',
          createdAt: Timestamp.now(),
          updatedAt: Timestamp.now(),
        );
        await _appUserService.createUser(newUser);
      } else {
        await _appUserService.updateUser(existingUser);
      }
    }
  }

  @override
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  @override
  Future<void> createUserWithEmailAndPassword(
      String email,
      String password,
      ) async {
    email = email.trim().toLowerCase();
    final UserCredential cred = await _firebaseAuth
        .createUserWithEmailAndPassword(
      email: email,
      password: password.trim(),
    );

    if (cred.user == null) return;
    final user = AppUser(
      uid: cred.user!.uid,
      displayName: cred.user!.displayName ?? '',
      email: email,
      photoURL: cred.user!.photoURL ?? '',
      createdAt: Timestamp.now(),
      updatedAt: Timestamp.now(),
    );
    _appUserService.createUser(user);
  }

  @override
  User? get currentUser => _firebaseAuth.currentUser;
}