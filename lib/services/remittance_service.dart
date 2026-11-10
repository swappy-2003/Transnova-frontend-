import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../models/remittance_model.dart';
import 'api_client.dart';

/// Remittance Pipeline Service
///
/// Handles Flow 1 end-to-end multi-currency cross-border remittance:
/// 1. Sender deposits INR via Transak on-ramp
/// 2. Transak sends Polygon USDC to sender's Circle SCA
/// 3. Backend transfers USDC to recipient
/// 4. Crossmint off-ramps USDC directly into recipient's US bank account (ACH)
class RemittanceService {
  final ApiClient _client = ApiClient();

  /// Initiates end-to-end cross-border remittance
  Future<Map<String, dynamic>> initiateRemittance({
    required String walletId,
    required double senderAmount,
    String senderCurrency = 'INR',
    String recipientCurrency = 'USD',
    required String recipientPaymentMethodId,
  }) async {
    try {
      final response = await _client.dio.post(
        ApiConfig.remittanceInitiate,
        data: {
          'walletId': walletId.trim(),
          'senderAmount': senderAmount,
          'senderCurrency': senderCurrency.toUpperCase(),
          'recipientCurrency': recipientCurrency.toUpperCase(),
          'recipientPaymentMethodId': recipientPaymentMethodId.trim(),
        },
      );

      final data = response.data as Map<String, dynamic>;
      final remJson = data['remittance'] as Map<String, dynamic>;

      return {
        'message': data['message']?.toString() ?? 'Remittance initiated',
        'remittance': RemittanceModel.fromJson(remJson),
        'widgetUrl': data['widgetUrl']?.toString(),
      };
    } on DioException catch (e) {
      throw e.error ?? 'Failed to initiate remittance pipeline';
    }
  }

  /// Fetches live status and stage timeline for a specific remittance ID
  Future<RemittanceModel> getRemittanceStatus(String remittanceId) async {
    try {
      final response = await _client.dio.get(ApiConfig.remittanceStatus(remittanceId));
      final data = response.data as Map<String, dynamic>;
      final remJson = data['remittance'] as Map<String, dynamic>;
      return RemittanceModel.fromJson(remJson);
    } on DioException catch (e) {
      throw e.error ?? 'Failed to get remittance status';
    }
  }

  /// Lists all remittances for the authenticated user
  Future<List<RemittanceModel>> getUserRemittances() async {
    try {
      final response = await _client.dio.get(ApiConfig.remittanceList);
      final data = response.data as Map<String, dynamic>;
      final list = data['remittances'] as List<dynamic>? ?? [];

      return list
          .map((item) => RemittanceModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw e.error ?? 'Failed to fetch remittances';
    }
  }
}

