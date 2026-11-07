import 'package:flutter/foundation.dart';
import '../models/fee_estimate_model.dart';
import '../models/transaction_model.dart';
import '../services/transaction_service.dart';

class TransactionProvider extends ChangeNotifier {
  final TransactionService _transactionService = TransactionService();

  List<TransactionModel> _transactions = [];
  bool _isLoading = false;
  String? _errorMessage;
  FeeEstimateModel? _feeEstimate;

  List<TransactionModel> get transactions => _transactions;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  FeeEstimateModel? get feeEstimate => _feeEstimate;

  /// Fetch user transactions
  Future<void> fetchTransactions() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _transactions = await _transactionService.getTransactions();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Estimate transfer gas fee
  Future<FeeEstimateModel?> estimateFee({
    required String walletId,
    required String destinationAddress,
    required double amount,
  }) async {
    try {
      _feeEstimate = await _transactionService.estimateFee(
        walletId: walletId,
        destinationAddress: destinationAddress,
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

  /// Execute Circle USDC transfer
  Future<TransactionModel> sendCircleTransfer({
    required String walletId,
    required String destinationAddress,
    required double amount,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final tx = await _transactionService.executeCircleTransfer(
        walletId: walletId,
        destinationAddress: destinationAddress,
        amount: amount,
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

  /// Simulate transfer
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

  void clear() {
    _transactions = [];
    _feeEstimate = null;
    _errorMessage = null;
    notifyListeners();
  }
}
