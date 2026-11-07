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

