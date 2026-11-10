import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../models/offramp_model.dart';
import 'api_client.dart';

class OfframpService {
  final ApiClient _client = ApiClient();

  /// Create Crossmint ACH payment method
  Future<OfframpPaymentMethod> createPaymentMethod({
    required Beneficiary beneficiary,
    required BankAccount bankAccount,
    String type = 'ach',
  }) async {
    try {
      final response = await _client.dio.post(
        ApiConfig.offrampPaymentMethods,
        data: {
          'type': type,
          'beneficiary': beneficiary.toJson(),
          'bankAccount': bankAccount.toJson(),
        },
      );

      final data = response.data as Map<String, dynamic>;
      return OfframpPaymentMethod.fromJson(data);
    } on DioException catch (e) {
      throw e.error ?? 'Failed to add bank account payment method';
    }
  }

  /// Fetch saved bank payment methods for the authenticated user
  Future<List<OfframpPaymentMethod>> getPaymentMethods() async {
    try {
      final response = await _client.dio.get(ApiConfig.offrampPaymentMethods);
      final data = response.data as Map<String, dynamic>;
      final list = data['paymentMethods'] as List<dynamic>? ?? [];
      return list
          .map((item) => OfframpPaymentMethod.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw e.error ?? 'Failed to fetch saved payment methods';
    }
  }

  /// Get live status and sync state for a Crossmint off-ramp order
  Future<Map<String, dynamic>> getOfframpOrderStatus(String orderId) async {
    try {
      final response = await _client.dio.get(ApiConfig.offrampOrderStatus(orderId));
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw e.error ?? 'Failed to get off-ramp order status';
    }
  }

  /// Create Crossmint off-ramp order (cashout to bank)
  Future<OfframpOrderResult> createOfframpOrder({
    required String payerAddress,
    required String paymentMethodId,
    required double amount,
    String chain = 'polygon-amoy',
    String currency = 'usdc',
  }) async {
    try {
      final response = await _client.dio.post(
        ApiConfig.offrampOrders,
        data: {
          'payerAddress': payerAddress.trim(),
          'paymentMethodId': paymentMethodId.trim(),
          'amount': amount,
          'chain': chain,
          'currency': currency,
        },
      );

      final data = response.data as Map<String, dynamic>;
      return OfframpOrderResult.fromJson(data);
    } on DioException catch (e) {
      throw e.error ?? 'Failed to create off-ramp order';
    }
  }
}

