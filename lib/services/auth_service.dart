import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../models/user_model.dart';
import 'api_client.dart';

class AuthService {
  final ApiClient _client = ApiClient();

  /// Register via Dev signup or Firebase Auth REST API
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final response = await _client.dio.post(
        ApiConfig.devSignup,
        data: {
          'email': email.trim(),
          'password': password,
          if (displayName != null && displayName.isNotEmpty) 'displayName': displayName.trim(),
        },
      );

      final data = response.data as Map<String, dynamic>;
      final idToken = data['idToken']?.toString();
      if (idToken != null) {
        await _client.setToken(idToken);
      }
      return data;
    } on DioException catch (e) {
      throw e.error ?? 'Registration failed';
    }
  }

  /// Login via Dev token or Firebase Auth REST API
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.dio.post(
        ApiConfig.devToken,
        data: {
          'email': email.trim(),
          'password': password,
        },
      );

      final data = response.data as Map<String, dynamic>;
      final idToken = data['idToken']?.toString();
      if (idToken != null) {
        await _client.setToken(idToken);
      }
      return data;
    } on DioException catch (e) {
      throw e.error ?? 'Login failed';
    }
  }

  /// Sync user profile and ensure MongoDB User and default wallet exist
  Future<UserModel> syncUser({String? displayName}) async {
    try {
      final response = await _client.dio.post(
        ApiConfig.authSync,
        data: {
          if (displayName != null && displayName.isNotEmpty) 'displayName': displayName.trim(),
        },
      );

      final userJson = response.data['user'] as Map<String, dynamic>;
      return UserModel.fromJson(userJson);
    } on DioException catch (e) {
      throw e.error ?? 'Failed to sync user';
    }
  }

  /// Fetch current user profile
  Future<UserModel> getMe() async {
    try {
      final response = await _client.dio.get(ApiConfig.authMe);
      final userJson = response.data['user'] as Map<String, dynamic>;
      return UserModel.fromJson(userJson);
    } on DioException catch (e) {
      throw e.error ?? 'Failed to get user profile';
    }
  }

  Future<void> logout() async {
    await _client.clearToken();
  }
}

