import 'package:flutter/foundation.dart';
import '../models/wallet_model.dart';
import '../services/wallet_service.dart';

class WalletProvider extends ChangeNotifier {
  final WalletService _walletService = WalletService();

  WalletModel? _wallet;
  bool _isLoading = false;
  String? _errorMessage;

  WalletModel? get wallet => _wallet;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  double get usdcBalance => _wallet?.usdcBalance ?? 0.0;
  String get address => _wallet?.effectiveAddress ?? '';
  String get walletId => _wallet?.effectiveWalletId ?? '';

  /// Provision or fetch existing Circle wallet
  Future<void> initWallet() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _wallet = await _walletService.createOrGetCircleWallet();
      await refreshBalance();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refresh token balances from Circle SDK
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

  /// Validate destination address
  Future<bool> validateAddress(String address) async {
    try {
      return await _walletService.validateAddress(address);
    } catch (_) {
      return false;
    }
  }

  void clear() {
    _wallet = null;
    _errorMessage = null;
    notifyListeners();
  }
}

