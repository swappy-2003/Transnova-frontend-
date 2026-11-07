import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiConfig {
  static const String _defaultLocalAndroid = 'http://10.0.2.2:5001';
  static const String _defaultLocalOther = 'http://localhost:5001';
  static const String _prefKeyBaseUrl = 'custom_base_url';

  static String _baseUrl = '';

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefKeyBaseUrl);
    if (saved != null && saved.isNotEmpty) {
      _baseUrl = saved;
    } else {
      if (kIsWeb) {
        _baseUrl = _defaultLocalOther;
      } else {
        _baseUrl = (defaultTargetPlatform == TargetPlatform.android)
            ? _defaultLocalAndroid
            : _defaultLocalOther;
      }
    }
  }

  static String get baseUrl => _baseUrl;

  static Future<void> setBaseUrl(String url) async {
    _baseUrl = url.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKeyBaseUrl, _baseUrl);
  }

  // Endpoints
  static const String devSignup = '/api/v1/dev/firebase-signup';
  static const String devToken = '/api/v1/dev/firebase-token';
  static const String authSync = '/api/v1/auth/sync';
  static const String authMe = '/api/v1/auth/me';

  static const String circleWallet = '/api/v1/wallets/circle';
  static String walletBalance(String walletId) => '/api/v1/wallets/$walletId/balance';
  static const String validateAddress = '/api/v1/wallets/validate-address';

  static const String transactions = '/api/v1/transactions';
  static const String estimateFee = '/api/v1/transactions/estimate-fee';
  static const String circleTransfer = '/api/v1/transactions/circle-transfer';
  static String circleStatus(String circleId) => '/api/v1/transactions/circle/$circleId';
  static const String simulateTransaction = '/api/v1/transactions/simulate';

  static const String onrampWidget = '/api/v1/onramp/widget-url';
  static String onrampTransaction(String txId) => '/api/v1/onramp/transactions/$txId';

  static const String offrampPaymentMethods = '/api/v1/offramp/payment-methods';
  static const String offrampOrders = '/api/v1/offramp/orders';
}

