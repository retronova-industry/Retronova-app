import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  StreamSubscription<User?>? _authStateSubscription;

  User? _user;
  bool _isLoading = true;
  String? _errorMessage;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;

  AuthProvider() {
    _initializeAuth();
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
  }

  void _initializeAuth() {
    try {
      _authStateSubscription = _authService.authStateChanges.listen(
        _onAuthStateChanged,
        onError: (error) {
          _setError("Erreur d'authentification: $error");
          _setLoading(false);
        },
      );
    } catch (e) {
      _setError("Erreur lors de l'initialisation: $e");
      _setLoading(false);
    }
  }

  void _onAuthStateChanged(User? user) {
    print("Auth state changed: ${user?.uid}");

    _user = user;
    _clearError();
    _setLoading(false);
    notifyListeners();
  }

  // ========== SIGN UP ==========
  Future<bool> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    return _performAuthAction(() async {
      await _authService.signUpWithEmailAndPassword(
        email: email,
        password: password,
        fullName: fullName,
      );

      // Attendre *vraiment* que Firebase connecte l'utilisateur
      await FirebaseAuth.instance.authStateChanges().firstWhere(
        (u) => u != null,
      );

      return true;
    });
  }

  // ========== SIGN IN ==========
  Future<bool> signIn({required String email, required String password}) async {
    return _performAuthAction(() async {
      // Déjà connecté ?
      final current = FirebaseAuth.instance.currentUser;
      if (current != null && current.email == email) return true;

      await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      await FirebaseAuth.instance.authStateChanges().firstWhere(
        (u) => u != null,
      );

      return true;
    });
  }

  // ========== SIGN OUT ==========
  Future<void> signOut() async {
    try {
      _setLoading(true);
      await _authService.signOut();
    } catch (e) {
      _setError("Erreur lors de la déconnexion: $e");
    } finally {
      _setLoading(false);
    }
  }

  // ========== RESET PASSWORD ==========
  Future<bool> resetPassword(String email) async {
    return _performAuthAction(() async {
      await _authService.resetPassword(email);
      return true;
    });
  }

  // ========== CORE ACTION HANDLER ==========
  Future<bool> _performAuthAction(Future<bool> Function() action) async {
    try {
      _setLoading(true);
      _clearError();

      return await action().timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw TimeoutException("Timeout"),
      );
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ========== HELPERS ==========
  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      print("Loading: $loading");
      notifyListeners();
    }
  }

  void _setError(String error) {
    _errorMessage = error;
    print("Auth Error: $error");
    notifyListeners();
  }

  void _clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  void clearError() => _clearError();

  void checkAuthState() =>
      _onAuthStateChanged(FirebaseAuth.instance.currentUser);
}
