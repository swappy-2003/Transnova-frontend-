import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../models/recipient_model.dart';
import 'api_client.dart';

/// User Service
/// Handles user-related API interactions such as recipient public wallet resolution.
class UserService {
  final ApiClient _client = ApiClient();

  /// Resolve a recipient's public Polygon Amoy wallet address by email
  Future<RecipientModel> resolveRecipientByEmail(String email) async {
    try {
      final response = await _client.dio.get(
        ApiConfig.userRecipient(email.trim().toLowerCase()),
      );
      final data = response.data as Map<String, dynamic>;
      final recipientJson = data['recipient'] as Map<String, dynamic>;
      return RecipientModel.fromJson(recipientJson);
    } on DioException catch (e) {
      throw e.error ?? 'Recipient not found';
    }
  }
}
