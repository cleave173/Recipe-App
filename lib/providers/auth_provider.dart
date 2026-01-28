import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import '../models/user.dart';
import '../services/firebase_auth_service.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  final FirebaseAuthService _authService = FirebaseAuthService();
  
  AuthStatus _status = AuthStatus.initial;
  User? _user;
  String? _error;

  AuthStatus get status => _status;
  User? get user => _user;
  String? get error => _error;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isLoading => _status == AuthStatus.loading;
  String? get userId => _user?.uid;

  AuthProvider() {
    _init();
  }

  Future<void> _init() async {
    // Listen to auth state changes
    _authService.authStateChanges.listen((fb.User? firebaseUser) async {
      if (firebaseUser != null) {
        await _loadUserData();
      } else {
        _user = null;
        _status = AuthStatus.unauthenticated;
        notifyListeners();
      }
    });
  }

  Future<void> _loadUserData() async {
    try {
      _user = await _authService.getCurrentUser();
      _status = _user != null ? AuthStatus.authenticated : AuthStatus.unauthenticated;
    } catch (e) {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<void> checkAuthStatus() async {
    _status = AuthStatus.loading;
    notifyListeners();

    try {
      _user = await _authService.getCurrentUser();
      _status = _user != null ? AuthStatus.authenticated : AuthStatus.unauthenticated;
    } catch (e) {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> register({
    required String username,
    required String email,
    required String password,
  }) async {
    _status = AuthStatus.loading;
    _error = null;
    notifyListeners();

    try {
      _user = await _authService.register(
        username: username,
        email: email,
        password: password,
      );
      _status = _user != null ? AuthStatus.authenticated : AuthStatus.error;
      if (_user == null) {
        _error = 'Тіркелу кезінде қате орын алды';
      }
      notifyListeners();
      return _user != null;
    } catch (e) {
      _status = AuthStatus.error;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _status = AuthStatus.loading;
    _error = null;
    notifyListeners();

    try {
      _user = await _authService.login(email: email, password: password);
      _status = _user != null ? AuthStatus.authenticated : AuthStatus.error;
      if (_user == null) {
        _error = 'Email немесе құпия сөз қате';
      }
      notifyListeners();
      return _user != null;
    } catch (e) {
      _status = AuthStatus.error;
      // Улучшенная обработка ошибок
      final errorMessage = e.toString();
      if (errorMessage.contains('wrong-password') || errorMessage.contains('invalid-credential')) {
        _error = 'Құпия сөз қате. Қайтадан енгізіңіз';
      } else if (errorMessage.contains('user-not-found')) {
        _error = 'Бұл email тіркелмеген';
      } else if (errorMessage.contains('invalid-email')) {
        _error = 'Email форматы қате';
      } else if (errorMessage.contains('too-many-requests')) {
        _error = 'Тым көп әрекет. Кейінірек қайталаңыз';
      } else if (errorMessage.contains('network')) {
        _error = 'Интернет байланысын тексеріңіз';
      } else {
        _error = 'Кіру кезінде қате орын алды';
      }
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    _status = AuthStatus.unauthenticated;
    _error = null;
    notifyListeners();
  }

  Future<void> updateProfile({String? username, String? avatarUrl}) async {
    try {
      await _authService.updateProfile(
        username: username,
        avatarUrl: avatarUrl,
      );
      if (username != null) {
        _user = _user?.copyWith(username: username);
      }
      if (avatarUrl != null) {
        _user = _user?.copyWith(avatarUrl: avatarUrl);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating profile: $e');
    }
  }

  Future<void> changePassword(String newPassword) async {
    try {
      await _authService.changePassword(newPassword);
    } catch (e) {
      _error = 'Құпия сөзді өзгерту кезінде қате: $e';
      notifyListeners();
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _authService.resetPassword(email);
    } catch (e) {
      _error = 'Құпия сөзді қалпына келтіру қатесі: $e';
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
