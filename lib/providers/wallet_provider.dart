import 'package:flutter/foundation.dart';
import '../models/wallet_model.dart';
import '../services/wallet_service.dart';

/// Circle Wallet State Provider
///
/// This provider is responsible for:
/// - Auto-provisioning the user's Circle Developer-Controlled Smart Contract Account (SCA) on Polygon Amoy.
/// - Querying and updating real-time on-chain token balances (USDC).
/// - Validating blockchain destination addresses before initiating transfers.
/// - Providing fallback sandbox demo wallet state when offline so UI stays responsive.
class WalletProvider extends ChangeNotifier {
  final WalletService _walletService = WalletService();

  WalletModel? _wallet;
  WalletQrModel? _qr;
  bool _isLoading = false;
  String? _errorMessage;

  // Convenient getters for UI components
  WalletModel? get wallet => _wallet;
  WalletQrModel? get qr => _qr ?? _wallet?.qr;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Returns the current USDC balance or 0.00
  double get usdcBalance => _wallet?.usdcBalance ?? 0.0;

  /// Returns the user's Polygon Amoy Smart Contract Account (SCA) address
  String get address => _wallet?.effectiveAddress ?? '';

  /// Returns the internal Circle wallet UUID
  String get walletId => _wallet?.effectiveWalletId ?? '';

  /// Provision a new Circle developer-controlled wallet or fetch the user's existing wallet.
  Future<void> initWallet() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // First check GET /api/v1/wallets/me for active primary wallet & permanent QR
      try {
        final meData = await _walletService.getPrimaryWallet();
        if (meData['wallet'] != null) {
          _wallet = meData['wallet'] as WalletModel;
          _qr = meData['qr'] as WalletQrModel?;
        }
      } catch (_) {
        // Fallback to create/provision endpoint
      }

      // If no wallet yet, call POST /api/v1/wallets/circle
      _wallet ??= await _walletService.createOrGetCircleWallet();

      await refreshBalance();
    } catch (e) {
      debugPrint('Circle wallet initialization fallback: $e');
      // If Circle API is rate-limited or DB is offline, instantiate demo SCA wallet so user can test UI
      _wallet ??= WalletModel(
        id: 'circle_demo_sca_1',
        userId: 'demo_user_uid',
        circleWalletId: 'circle_wallet_amoy_demo_01',
        address: '0x71C83492864C62Fdf0159483B892aF829379e492',
        blockchain: 'MATIC-AMOY',
        accountType: 'SCA',
        balances: [
          TokenBalance(
            name: 'USD Coin',
            symbol: 'USDC',
            amount: '1250.00',
            decimals: 6,
          ),
        ],
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Polls Circle SDK via /api/v1/wallets/:id/balance for the latest USDC balance.
  Future<void> refreshBalance() async {
    if (_wallet == null) return;

    try {
      final balanceData = await _walletService.getWalletBalance(_wallet!.effectiveWalletId);
      final balances = balanceData['balances'] as List<TokenBalance>;
      final usdcTokenId = balanceData['usdcTokenId'] as String?;

      _wallet = _wallet!.copyWith(
        balances: balances,
        usdcTokenId: usdcTokenId,
      );
      notifyListeners();
    } catch (e) {
      // In development/testnets, if Circle balance check fails or rate-limits, don't crash UI
      debugPrint('Error fetching wallet balance: $e');
    }
  }

  /// Validates whether an address is a valid EVM/Polygon address using Circle SDK
  Future<bool> validateAddress(String address) async {
    try {
      return await _walletService.validateAddress(address);
    } catch (_) {
      return false;
    }
  }

  /// Reset wallet state on user logout
  void clear() {
    _wallet = null;
    _errorMessage = null;
    notifyListeners();
  }
}
