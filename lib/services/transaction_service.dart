import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';
import '../config/api_config.dart';
import '../models/fee_estimate_model.dart';
import '../models/receipt_model.dart';
import '../models/transaction_model.dart';
import 'api_client.dart';

class TransactionService {
  final ApiClient _client = ApiClient();
  final Uuid _uuid = const Uuid();

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

      final idempotencyKey = _uuid.v4();
      final response = await _client.dio.post(
        ApiConfig.circleTransfer,
        data: payload,
        options: Options(
          headers: {
            'Idempotency-Key': idempotencyKey,
          },
        ),
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

  /// Fetch transaction activity history list
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

  /// Fetch immutable transaction receipt by ID
  Future<TransactionReceiptModel> getTransactionReceipt(String transactionId) async {
    try {
      final response = await _client.dio.get(ApiConfig.transactionReceipt(transactionId));
      final data = response.data as Map<String, dynamic>;
      final receiptJson = data['receipt'] as Map<String, dynamic>;
      return TransactionReceiptModel.fromJson(receiptJson);
    } on DioException catch (e) {
      throw e.error ?? 'Failed to fetch transaction receipt';
    }
  }

  /// Dev helper: Fund demo USDC into user wallet ledger
  Future<Map<String, dynamic>> fundDemoUsdc({
    required String walletId,
    required double amount,
  }) async {
    try {
      final response = await _client.dio.post(
        ApiConfig.devDemoFund,
        data: {
          'walletId': walletId,
          'amount': amount,
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw e.error ?? 'Failed to fund demo USDC';
    }
  }
}
