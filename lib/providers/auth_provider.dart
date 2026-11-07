import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final ApiClient _apiClient = ApiClient();

  UserModel? _user;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get user => _user;
  bool get isAuthenticated => _user != null && _apiClient.token != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Check existing session on app startup
  Future<bool> checkSession() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (_apiClient.token != null && _apiClient.token!.isNotEmpty) {
        try {
          _user = await _authService.getMe();
        } catch (_) {
          _user = await _authService.syncUser();
        }
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (_) {
      // If MongoDB is offline, keep logged in if token exists
      if (_apiClient.token != null && _apiClient.token!.isNotEmpty) {
        _user = UserModel(
          id: 'dev_user',
          firebaseUid: 'dev_uid',
          email: 'demo@transnova.com',
          displayName: 'Demo User',
        );
        _isLoading = false;
        notifyListeners();
        return true;
      }
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  /// Sign In with Email & Password
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final tokenData = await _authService.login(email: email, password: password);
      try {
        _user = await _authService.syncUser();
      } catch (dbErr) {
        debugPrint('MongoDB sync timed out or offline, using Firebase profile: $dbErr');
        _user = UserModel(
          id: tokenData['uid']?.toString() ?? 'demo_user',
          firebaseUid: tokenData['uid']?.toString() ?? '',
          email: tokenData['email']?.toString() ?? email,
          displayName: 'Demo User',
        );
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Register new User
  Future<bool> register({
    required String email,
    required String password,
    String? displayName,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final regData = await _authService.register(
        email: email,
        password: password,
        displayName: displayName,
      );
      try {
        _user = await _authService.syncUser(displayName: displayName);
      } catch (dbErr) {
        debugPrint('MongoDB sync timed out or offline: $dbErr');
        _user = UserModel(
          id: regData['uid']?.toString() ?? 'demo_user',
          firebaseUid: regData['uid']?.toString() ?? '',
          email: regData['email']?.toString() ?? email,
          displayName: displayName ?? 'Transnova User',
        );
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Logout
  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    notifyListeners();
  }
}
