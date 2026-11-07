import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

/// Singleton HTTP Client Wrapper powered by Dio
///
/// Features:
/// - Singleton instance ensures the exact same HTTP client & headers are shared everywhere.
/// - Automatically intercepts all outgoing HTTP requests and injects the `Authorization: Bearer <token>` header.
/// - Dynamically synchronizes with `ApiConfig.baseUrl` in case the user changes the backend server URL at runtime.
/// - Parses backend JSON error responses into clean, user-friendly messages for Flutter snackbars.
/// - Persists and restores the authentication token from `SharedPreferences`.
class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late Dio _dio;
  String? _token;

  static const String _prefTokenKey = 'auth_id_token';

  ApiClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Request & Response Interceptors
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Keep base URL in sync if updated
          options.baseUrl = ApiConfig.baseUrl;

          // Automatically inject Bearer authentication header if user is logged in
          if (_token != null && _token!.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $_token';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) {
          // Extract backend error message from standard { message: "..." } JSON response
          String errorMessage = 'An unexpected error occurred';
          if (e.response?.data != null) {
            if (e.response?.data is Map) {
              errorMessage = e.response?.data['message']?.toString() ??
                  e.response?.data['error']?.toString() ??
                  e.message ??
                  errorMessage;
            } else if (e.response?.data is String) {
              errorMessage = e.response!.data as String;
            }
          } else if (e.message != null) {
            errorMessage = e.message!;
          }

          final customError = DioException(
            requestOptions: e.requestOptions,
            response: e.response,
            type: e.type,
            error: errorMessage,
          );

          return handler.next(customError);
        },
      ),
    );
  }

  Dio get dio => _dio;
  String? get token => _token;

  /// Loads previously saved auth token from persistent storage during app boot
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_prefTokenKey);
  }

  /// Sets active authentication token and persists it to phone storage
  Future<void> setToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefTokenKey, token);
  }

  /// Clears token on logout
  Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefTokenKey);
  }
}
