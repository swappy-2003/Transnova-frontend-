import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../models/wallet_model.dart';
import 'api_client.dart';

/// Circle Wallet Service
///
/// Communicates with backend endpoints to manage Circle Developer-Controlled
/// Smart Contract Accounts (SCA) deployed on Polygon Amoy.
class WalletService {
  final ApiClient _client = ApiClient();

  /// Creates a new Smart Contract Account (SCA) on Polygon Amoy for the user,
  /// or returns their existing wallet if one was already provisioned.
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

  /// Queries the Circle Developer-Controlled Wallets API for real-time USDC balances.
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

  /// Fetches the user's active primary Circle wallet and permanent QR code
  /// directly from GET /api/v1/wallets/me
  Future<Map<String, dynamic>> getPrimaryWallet() async {
    try {
      final response = await _client.dio.get(ApiConfig.walletMe);
      final data = response.data as Map<String, dynamic>;

      final walletJson = data['wallet'] as Map<String, dynamic>?;
      final qrJson = data['qr'] as Map<String, dynamic>?;

      WalletModel? wallet;
      if (walletJson != null) {
        wallet = WalletModel.fromJson(walletJson);
      }

      WalletQrModel? qr;
      if (qrJson != null) {
        qr = WalletQrModel.fromJson(qrJson);
      }

      return {
        'wallet': wallet,
        'qr': qr,
      };
    } on DioException catch (e) {
      throw e.error ?? 'Failed to get primary wallet';
    }
  }

  /// Generates or fetches the permanent QR code for a specific wallet
  Future<WalletQrModel> getWalletQr(String walletId) async {
    try {
      final response = await _client.dio.get(ApiConfig.walletQr(walletId));
      final data = response.data as Map<String, dynamic>;
      final qrJson = data['qr'] as Map<String, dynamic>;
      return WalletQrModel.fromJson(qrJson);
    } on DioException catch (e) {
      throw e.error ?? 'Failed to load wallet QR code';
    }
  }

  /// Checks if a given Ethereum/Polygon address string is valid on-chain.
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
    } on DioException {
      return false;
    }
  }
}
