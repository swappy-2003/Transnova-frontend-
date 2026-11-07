import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';

/// Authentication State Provider
///
/// This provider is responsible for:
/// - Storing the current logged-in user profile (`UserModel`).
/// - Managing the user login and registration state.
/// - Providing a quick one-tap Demo Mode login that bypasses external Firebase latency.
/// - Validating existing login sessions when the app opens from the splash screen.
/// - Handling user logout and session cleanup.
class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final ApiClient _apiClient = ApiClient();

  UserModel? _user;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters to read auth state from UI screens
  UserModel? get user => _user;
  bool get isAuthenticated => _user != null && _apiClient.token != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Check if the user already has a saved token when launching the app.
  /// Runs on the Splash Screen before deciding to navigate to Home or Login.
  Future<bool> checkSession() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // If a Bearer auth token was previously saved to local storage
      if (_apiClient.token != null && _apiClient.token!.isNotEmpty) {
        try {
          // Attempt to fetch current user profile from /auth/me
          _user = await _authService.getMe();
        } catch (_) {
          // If /auth/me fails, try syncing profile via /auth/sync
          _user = await _authService.syncUser();
        }
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (_) {
      // Fallback: If backend DB is offline, preserve demo session so UI is not blocked
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
  /// Handles both Quick Demo accounts and real Firebase Auth users.
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. One-Click Demo Mode bypass for instant local testing
      if (email.trim().toLowerCase() == 'demo@transnova.com') {
        await _apiClient.setToken('demo_token');
        try {
          _user = await _authService.syncUser();
        } catch (_) {
          _user = UserModel(
            id: 'demo_user_uid',
            firebaseUid: 'demo_user_uid',
            email: 'demo@transnova.com',
            displayName: 'Demo User',
          );
        }
        _isLoading = false;
        notifyListeners();
        return true;
      }

      // 2. Real login through backend dev token REST API
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

  /// Register a brand new user account
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

  /// Log out user, remove authentication token from storage, and reset state.
  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    notifyListeners();
  }
}
