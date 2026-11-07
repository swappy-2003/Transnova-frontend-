import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../models/wallet_model.dart';
import 'api_client.dart';

class WalletService {
  final ApiClient _client = ApiClient();

  /// Create or get existing Circle developer-controlled wallet
  Future<WalletModel> createOrGetCircleWallet({
    String blockchain = 'MATIC-AMOY',
    String accountType = 'SCA',
  }) async {
    try {
      final response = await _client.dio.post(
        ApiConfig.circleWallet,
        data: {
          'blockchain': blockchain,
          'accountType': accountType,
        },
      );

      final walletJson = response.data['wallet'] as Map<String, dynamic>;
      return WalletModel.fromJson(walletJson);
    } on DioException catch (e) {
      throw e.error ?? 'Failed to provision Circle wallet';
    }
  }

  /// Get wallet token balance from Circle
  Future<Map<String, dynamic>> getWalletBalance(String walletId) async {
    try {
      final response = await _client.dio.get(ApiConfig.walletBalance(walletId));
      final data = response.data as Map<String, dynamic>;

      final rawBalances = data['balances'] as List<dynamic>? ?? [];
      final balances = rawBalances
          .map((item) => TokenBalance.fromJson(item as Map<String, dynamic>))
          .toList();

      return {
        'walletId': data['walletId']?.toString() ?? walletId,
        'balances': balances,
        'usdcTokenId': data['usdcTokenId']?.toString(),
      };
    } on DioException catch (e) {
      throw e.error ?? 'Failed to get wallet balance';
    }
  }

  /// Validate destination address on blockchain
  Future<bool> validateAddress(String address, {String blockchain = 'MATIC-AMOY'}) async {
    try {
      final response = await _client.dio.post(
        ApiConfig.validateAddress,
        data: {
          'address': address.trim(),
          'blockchain': blockchain,
        },
      );

      return response.data['isValid'] == true;
    } on DioException catch (e) {
      throw e.error ?? 'Address validation failed';
    }
  }
}

