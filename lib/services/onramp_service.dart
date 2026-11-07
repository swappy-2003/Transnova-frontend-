import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../models/onramp_order_model.dart';
import '../models/transaction_model.dart';
import 'api_client.dart';

class OnrampService {
  final ApiClient _client = ApiClient();

  /// Create Transak on-ramp widget URL
  Future<OnrampOrderModel> createWidgetUrl({
    required String walletId,
    required double fiatAmount,
    String fiatCurrency = 'USD',
  }) async {
    try {
      final response = await _client.dio.post(
        ApiConfig.onrampWidget,
        data: {
          'walletId': walletId,
          'fiatCurrency': fiatCurrency.toUpperCase(),
          'fiatAmount': fiatAmount,
        },
        options: Options(
          headers: {
            'Origin': 'http://localhost:3000',
          },
        ),
      );

      final data = response.data as Map<String, dynamic>;
      return OnrampOrderModel.fromJson(data);
    } on DioException catch (e) {
      throw e.error ?? 'Failed to initialize on-ramp session';
    }
  }

  /// Get status of specific on-ramp transaction
  Future<TransactionModel> getOnrampTransaction(String transactionId) async {
    try {
      final response = await _client.dio.get(ApiConfig.onrampTransaction(transactionId));
      final data = response.data as Map<String, dynamic>;
      return TransactionModel.fromJson(data['transaction'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw e.error ?? 'Failed to get on-ramp status';
    }
  }
}

