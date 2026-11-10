import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../models/fee_estimate_model.dart';
import '../models/transaction_model.dart';
import 'api_client.dart';

class TransactionService {
  final ApiClient _client = ApiClient();

  /// Estimate Circle transfer gas/network fee (by wallet address or registered recipient email)
  Future<FeeEstimateModel> estimateFee({
    required String walletId,
    String? destinationAddress,
    String? recipientEmail,
    required double amount,
  }) async {
    try {
      final payload = <String, dynamic>{
        'walletId': walletId,
        'amount': amount,
      };
      if (destinationAddress != null && destinationAddress.trim().isNotEmpty) {
        payload['destinationAddress'] = destinationAddress.trim();
      }
      if (recipientEmail != null && recipientEmail.trim().isNotEmpty) {
        payload['recipientEmail'] = recipientEmail.trim();
      }

      final response = await _client.dio.post(
        ApiConfig.estimateFee,
        data: payload,
      );

      final data = response.data as Map<String, dynamic>;
      return FeeEstimateModel.fromJson(data);
    } on DioException catch (e) {
      throw e.error ?? 'Fee estimation failed';
    }
  }

  /// Execute Circle USDC transfer (supports either Polygon address or Transnova user email)
  Future<TransactionModel> executeCircleTransfer({
    required String walletId,
    String? destinationAddress,
    String? recipientEmail,
    required double amount,
  }) async {
    try {
      final payload = <String, dynamic>{
        'walletId': walletId,
        'amount': amount,
      };
      if (destinationAddress != null && destinationAddress.trim().isNotEmpty) {
        payload['destinationAddress'] = destinationAddress.trim();
      }
      if (recipientEmail != null && recipientEmail.trim().isNotEmpty) {
        payload['recipientEmail'] = recipientEmail.trim();
      }

      final response = await _client.dio.post(
        ApiConfig.circleTransfer,
        data: payload,
      );

      final data = response.data as Map<String, dynamic>;
      final txJson = data['transaction'] as Map<String, dynamic>;
      return TransactionModel.fromJson(txJson);
    } on DioException catch (e) {
      throw e.error ?? 'Circle transfer failed';
    }
  }

  /// Get status of Circle transfer
  Future<Map<String, dynamic>> getCircleStatus(String circleTxId) async {
    try {
      final response = await _client.dio.get(ApiConfig.circleStatus(circleTxId));
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw e.error ?? 'Failed to get Circle transaction status';
    }
  }

  /// Simulate a transaction (payin, transfer, offramp) for sandbox/demo
  Future<TransactionModel> simulateTransaction({
    required String type,
    required double amount,
    String asset = 'USDC',
    String? destinationWalletAddress,
  }) async {
    try {
      final response = await _client.dio.post(
        ApiConfig.simulateTransaction,
        data: {
          'type': type,
          'amount': amount,
          'asset': asset,
          ...?destinationWalletAddress != null ? {'destinationWalletAddress': destinationWalletAddress} : null,
        },
      );

      final data = response.data as Map<String, dynamic>;
      final txJson = data['transaction'] as Map<String, dynamic>;
      return TransactionModel.fromJson(txJson);
    } on DioException catch (e) {
      throw e.error ?? 'Simulation failed';
    }
  }

  /// Fetch all transactions for the authenticated user
  Future<List<TransactionModel>> getTransactions() async {
    try {
      final response = await _client.dio.get(ApiConfig.transactions);
      final data = response.data as Map<String, dynamic>;
      final list = data['transactions'] as List<dynamic>? ?? [];

      return list
          .map((item) => TransactionModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw e.error ?? 'Failed to fetch transactions';
    }
  }
}
