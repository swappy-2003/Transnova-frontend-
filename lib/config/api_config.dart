import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Centralized API Configuration & Endpoints Registry
///
/// This class handles:
/// 1. Determining the correct base backend URL according to platform (Android emulator vs Web/macOS).
/// 2. Persisting custom user-defined base URLs via SharedPreferences so you can switch backend targets easily.
/// 3. Providing a single source of truth for all REST API endpoint paths.
class ApiConfig {
  // 10.0.2.2 is Android emulator's special loopback IP to reach the host computer's localhost.
  static const String _defaultLocalAndroid = 'http://10.0.2.2:5001';

  // Standard localhost for Flutter Web, macOS Desktop, iOS Simulator, and local testing.
  static const String _defaultLocalOther = 'http://localhost:5001';

  // Key used to store custom URL in local phone storage.
  static const String _prefKeyBaseUrl = 'custom_base_url';

  static String _baseUrl = '';

  /// Loads the saved base URL from SharedPreferences or picks the appropriate default.
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

  /// Returns the current active backend base URL.
  static String get baseUrl => _baseUrl;

  /// Updates and persists the backend base URL at runtime.
  static Future<void> setBaseUrl(String url) async {
    _baseUrl = url.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKeyBaseUrl, _baseUrl);
  }

  // ==========================================
  // SYSTEM HEALTH
  // ==========================================
  /// Backend server health check endpoint
  static const String health = '/health';

  // ==========================================
  // AUTHENTICATION & DEV ENDPOINTS
  // ==========================================
  /// Dev helper: Register a new Firebase Auth test user
  static const String devSignup = '/api/v1/dev/firebase-signup';

  /// Dev helper: Sign in and receive a Firebase Auth ID token
  static const String devToken = '/api/v1/dev/firebase-token';

  /// Synchronize Firebase authenticated user profile with MongoDB backend
  static const String authSync = '/api/v1/auth/sync';

  /// Fetch currently authenticated user profile
  static const String authMe = '/api/v1/auth/me';

  // ==========================================
  // CIRCLE DEVELOPER-CONTROLLED WALLETS
  // ==========================================
  /// Auto-provision a Circle Polygon Amoy Smart Contract Account (SCA)
  static const String circleWallet = '/api/v1/wallets/circle';

  /// Fetch authenticated user's primary Circle wallet and constant QR code
  static const String walletMe = '/api/v1/wallets/me';

  /// Fetch permanent QR code for a specific wallet
  static String walletQr(String walletId) => '/api/v1/wallets/$walletId/qr';

  /// Fetch real-time USDC token balance for a specific wallet ID
  static String walletBalance(String walletId) => '/api/v1/wallets/$walletId/balance';

  /// Validate Polygon blockchain address format before sending
  static const String validateAddress = '/api/v1/wallets/validate-address';

  // ==========================================
  // USDC TRANSFERS & TRANSACTIONS
  // ==========================================
  /// Fetch transaction activity history list
  static const String transactions = '/api/v1/transactions';

  /// Estimate Circle Polygon Amoy transfer gas fee (low, medium, high)
  static const String estimateFee = '/api/v1/transactions/estimate-fee';

  /// Execute real on-chain USDC transfer via Circle SDK
  static const String circleTransfer = '/api/v1/transactions/circle-transfer';

  /// Poll on-chain Circle transaction status (PENDING, CONFIRMED, FAILED)
  static String circleStatus(String circleId) => '/api/v1/transactions/circle/$circleId';

  /// Instant sandbox transaction simulation (used for testing without real gas)
  static const String simulateTransaction = '/api/v1/transactions/simulate';

  // ==========================================
  // TRANSAK ON-RAMP (BUY USDC WITH FIAT)
  // ==========================================
  /// Generate a signed Transak on-ramp checkout session URL
  static const String onrampWidget = '/api/v1/onramp/widget-url';

  /// Poll status of a specific Transak deposit order
  static String onrampTransaction(String txId) => '/api/v1/onramp/transactions/$txId';

  // ==========================================
  // CROSSMINT OFF-RAMP (CASH OUT TO US BANK)
  // ==========================================
  /// Link ACH beneficiary bank account (routing & account number)
  static const String offrampPaymentMethods = '/api/v1/offramp/payment-methods';

  /// Create cashout payout order from Polygon USDC to US bank account
  static const String offrampOrders = '/api/v1/offramp/orders';

  /// Poll and sync Crossmint off-ramp order status
  static String offrampOrderStatus(String orderId) => '/api/v1/offramp/orders/$orderId';

  // ==========================================
  // CROSS-BORDER REMITTANCE PIPELINE
  // (On-ramp INR -> USDC Transfer -> Off-ramp USD)
  // ==========================================
  /// Initiate end-to-end multi-hop remittance
  static const String remittanceInitiate = '/api/v1/remittance/initiate';

  /// List user's remittance history
  static const String remittanceList = '/api/v1/remittance';

  /// Get status and pipeline timeline of a specific remittance
  static String remittanceStatus(String id) => '/api/v1/remittance/$id';

  // ==========================================
  // RAZORPAY INSTANT PAYMENT GATEWAY (INR / UPI / CARDS)
  // ==========================================
  /// Create a Razorpay payment order for fiat deposit / INR top-up
  static const String razorpayCreateOrder = '/api/v1/razorpay/create-order';

  /// Verify Razorpay payment signature after successful checkout
  static const String razorpayVerifyPayment = '/api/v1/razorpay/verify-payment';

  /// Fetch history of Razorpay top-ups and payments
  static const String razorpayHistory = '/api/v1/razorpay/history';

  /// Fetch a specific Razorpay payment by order ID
  static String razorpayPayment(String orderId) => '/api/v1/razorpay/payment/$orderId';
}
