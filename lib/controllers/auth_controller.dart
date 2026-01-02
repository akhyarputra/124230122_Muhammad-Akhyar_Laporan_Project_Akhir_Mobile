import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:plantify_app/service/auth/auth_service.dart';

/// AuthController: controller layer for authentication logic.
/// It wraps AuthService and exposes simple state for the UI (views).
class AuthController extends ChangeNotifier {
  final AuthService _authService;

  bool _isLoggedIn = false;
  bool get isLoggedIn => _isLoggedIn;

  String? _username;
  String? get username => _username;

  AuthController(this._authService);

  /// Initialize controller state from persisted storage.
  Future<void> init() async {
    _isLoggedIn = await _authService.isLoggedIn();
    if (_isLoggedIn) {
      final prefs = await SharedPreferences.getInstance();
      _username = prefs.getString('username');
    }
    notifyListeners();
  }

  /// Perform login using AuthService and update state.
  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    final result = await _authService.login(
      username: username,
      password: password,
    );
    final success = result['success'] == true;
    if (success) {
      _isLoggedIn = true;
      final prefs = await SharedPreferences.getInstance();
      _username = prefs.getString('username');
      notifyListeners();
    }
    return result;
  }

  /// Perform logout and update state.
  Future<void> logout() async {
    await _authService.logout();
    _isLoggedIn = false;
    _username = null;
    notifyListeners();
  }
}
