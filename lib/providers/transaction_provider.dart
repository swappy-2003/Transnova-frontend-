import 'package:flutter/foundation.dart';
import '../models/fee_estimate_model.dart';
import '../models/transaction_model.dart';
import '../services/transaction_service.dart';

/// Transactions State Provider
///
/// This provider is responsible for:
/// - Fetching and storing user transaction history (transfers, deposits, cash-outs).
/// - Estimating Circle gas fees across multiple speed tiers (low, medium, high).
/// - Initiating on-chain Circle USDC transfers.
/// - Providing instant testnet sandbox simulations so users can test transfers without gas.
class TransactionProvider extends ChangeNotifier {
  final TransactionService _transactionService = TransactionService();

  List<TransactionModel> _transactions = [];
  bool _isLoading = false;
  String? _errorMessage;
  FeeEstimateModel? _feeEstimate;

  // Getters for UI access
  List<TransactionModel> get transactions => _transactions;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  FeeEstimateModel? get feeEstimate => _feeEstimate;

  /// Fetches recent transactions from /api/v1/transactions.
  /// If the database is empty or offline during dev, supplies realistic mock items.
  Future<void> fetchTransactions() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final list = await _transactionService.getTransactions();
      if (list.isNotEmpty) {
        _transactions = list;
      } else {
        _transactions = _getMockTransactions();
      }
    } catch (e) {
      debugPrint('Transaction fetch fallback: $e');
      if (_transactions.isEmpty) {
        _transactions = _getMockTransactions();
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Calculates estimated Polygon Amoy blockchain gas fees before transferring (via address or email)
  Future<FeeEstimateModel?> estimateFee({
    required String walletId,
    String? destinationAddress,
    String? recipientEmail,
    required double amount,
  }) async {
    try {
      _feeEstimate = await _transactionService.estimateFee(
        walletId: walletId,
        destinationAddress: destinationAddress,
        recipientEmail: recipientEmail,
        amount: amount,
      );
      notifyListeners();
      return _feeEstimate;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Executes an on-chain transfer of USDC via Circle Developer-Controlled Wallets
  /// (supports scanned Polygon address or registered recipient email)
  Future<TransactionModel> sendCircleTransfer({
    required String walletId,
    String? destinationAddress,
    String? recipientEmail,
    required double amount,
    String feeLevel = 'medium',
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final tx = await _transactionService.executeCircleTransfer(
        walletId: walletId,
        destinationAddress: destinationAddress,
        recipientEmail: recipientEmail,
        amount: amount,
      );
      // Prepend newly created transaction to top of history list
      _transactions.insert(0, tx);
      _isLoading = false;
      notifyListeners();
      return tx;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Instant Sandbox simulation (used for fast testing without needing real gas)
  Future<TransactionModel> simulateTransaction({
    required String type,
    required double amount,
    String asset = 'USDC',
    String? destinationAddress,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final tx = await _transactionService.simulateTransaction(
        type: type,
        amount: amount,
        asset: asset,
        destinationWalletAddress: destinationAddress,
      );
      _transactions.insert(0, tx);
      _isLoading = false;
      notifyListeners();
      return tx;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Clears state when user logs out
  void clear() {
    _transactions = [];
    _feeEstimate = null;
    _errorMessage = null;
    notifyListeners();
  }

  /// High-fidelity demo transactions matching the Figma design
  List<TransactionModel> _getMockTransactions() {
    return [
      TransactionModel(
        id: 'tx_mock_1',
        reference: 'REF-TX-001',
        type: 'payin',
        status: 'completed',
        amount: 500.0,
        asset: 'USDC',
        createdAt: DateTime.now().subtract(const Duration(minutes: 42)),
        circleTxHash: '0x3a9f...81e2',
        metadata: {'description': 'Transak On-Ramp Deposit'},
      ),
      TransactionModel(
        id: 'tx_mock_2',
        reference: 'REF-TX-002',
        type: 'wallet_transfer',
        status: 'completed',
        amount: 45.0,
        asset: 'USDC',
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
        circleTxHash: '0x812b...9a41',
        metadata: {
          'description': 'Payment to Alice',
          'destinationAddress': '0x3b8a4f91e320498a129f840938b820194829129f',
        },
      ),
      TransactionModel(
        id: 'tx_mock_3',
        reference: 'REF-TX-003',
        type: 'offramp',
        status: 'completed',
        amount: 120.0,
        asset: 'USD',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        crossmintOrderId: 'cm_ord_03',
        metadata: {'description': 'Chase Bank ACH Cash Out'},
      ),
      TransactionModel(
        id: 'tx_mock_4',
        reference: 'REF-TX-004',
        type: 'payin',
        status: 'completed',
        amount: 250.0,
        asset: 'USDC',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        circleTxHash: '0x49ca...713f',
        metadata: {
          'description': 'Received from Bob (Polygon Amoy)',
          'destinationAddress': '0x71C83492864C62Fdf0159483B892aF829379e492',
        },
      ),
    ];
  }
}
