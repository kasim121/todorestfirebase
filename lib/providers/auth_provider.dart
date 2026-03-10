import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  AuthStatus _status = AuthStatus.initial;
  User? _user;
  String? _errorMessage;

  AuthStatus get status => _status;
  User? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  AuthProvider() {
    _init();
  }

  void _init() {
    // Resolve immediately from currentUser so the splash screen is never stuck.
    // The stream will still handle subsequent sign-in / sign-out events.
    final currentUser = _authService.currentUser;
    _user = currentUser;
    _status = currentUser != null
        ? AuthStatus.authenticated
        : AuthStatus.unauthenticated;

    _authService.authStateChanges.listen((user) {
      _user = user;
      _status =
          user != null ? AuthStatus.authenticated : AuthStatus.unauthenticated;
      notifyListeners();
    });
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    _setLoading();
    try {
      await _authService.signUpWithEmail(
        email: email,
        password: password,
        displayName: displayName,
      );
      _errorMessage = null;
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(AuthService.getErrorMessage(e.code));
      return false;
    } catch (e) {
      _setError('An unexpected error occurred.');
      return false;
    }
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _setLoading();
    try {
      await _authService.signInWithEmail(email: email, password: password);
      _errorMessage = null;
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(AuthService.getErrorMessage(e.code));
      return false;
    } catch (e) {
      _setError('An unexpected error occurred.');
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    _setLoading();
    try {
      final result = await _authService.signInWithGoogle();
      if (result == null) {
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return false;
      }
      _errorMessage = null;
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(AuthService.getErrorMessage(e.code));
      return false;
    } catch (e) {
      _setError('Google sign-in failed. Please try again.');
      return false;
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
  }

  Future<void> sendPasswordReset(String email) async {
    await _authService.sendPasswordResetEmail(email);
  }

  Future<String?> getIdToken() async {
    return await _authService.getIdToken();
  }

  void _setLoading() {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();
  }

  void _setError(String message) {
    _status = AuthStatus.error;
    _errorMessage = message;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
