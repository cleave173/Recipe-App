import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/constants.dart';
import '../models/user.dart';
import 'api_service.dart';

class AuthResult {
  final bool success;
  final String? error;
  final User? user;
  final String? token;

  AuthResult({
    required this.success,
    this.error,
    this.user,
    this.token,
  });
}

class AuthService {
  final ApiService _api = ApiService();

  Future<AuthResult> register({
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _api.post('/auth/register', data: {
        'username': username,
        'email': email,
        'password': password,
      });

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final token = data['token'] as String;
        final user = User.fromJson(data['user'] as Map<String, dynamic>);
        
        await _api.setToken(token);
        await _saveUser(user);
        
        return AuthResult(success: true, user: user, token: token);
      }
      
      return AuthResult(
        success: false,
        error: 'Тіркеу сәтсіз аяқталды',
      );
    } catch (e) {
      return AuthResult(
        success: false,
        error: _parseError(e),
      );
    }
  }

  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _api.post('/auth/login', data: {
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final token = data['token'] as String;
        final user = User.fromJson(data['user'] as Map<String, dynamic>);
        
        await _api.setToken(token);
        await _saveUser(user);
        
        return AuthResult(success: true, user: user, token: token);
      }
      
      return AuthResult(
        success: false,
        error: 'Кіру сәтсіз аяқталды',
      );
    } catch (e) {
      return AuthResult(
        success: false,
        error: _parseError(e),
      );
    }
  }

  Future<void> logout() async {
    try {
      await _api.post('/auth/logout');
    } catch (_) {
      // Ignore logout errors
    }
    await _api.setToken(null);
    await _clearUser();
  }

  Future<User?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString(AppConstants.userDataKey);
    if (userData != null) {
      try {
        return User.fromJson(jsonDecode(userData) as Map<String, dynamic>);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  Future<void> _saveUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.userDataKey, jsonEncode(user.toJson()));
  }

  Future<void> _clearUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.userDataKey);
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.userTokenKey);
    return token != null;
  }

  String _parseError(dynamic error) {
    if (error is Exception) {
      return error.toString().replaceAll('Exception: ', '');
    }
    return 'Белгісіз қате орын алды';
  }
}
