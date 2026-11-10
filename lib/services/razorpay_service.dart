import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../models/razorpay_model.dart';
import 'api_client.dart';

/// Razorpay Payment Gateway Service
///
/// Handles instant INR deposits, UPI checkouts, and debit/credit card top-ups:
/// 1. Create order on backend (`/api/v1/razorpay/create-order`)
/// 2. Complete payment in checkout modal / webview
/// 3. Verify cryptographic HMAC signature on backend (`/api/v1/razorpay/verify-payment`)
/// 4. Query payment history (`/api/v1/razorpay/history`)
class RazorpayService {
  final ApiClient _client = ApiClient();

  /// Create a new Razorpay payment order for INR fiat deposit
  Future<RazorpayOrderResponse> createOrder(double amount) async {
    try {
      final response = await _client.dio.post(
        ApiConfig.razorpayCreateOrder,
        data: {
          'amount': amount,
        },
      );

      final data = response.data as Map<String, dynamic>;
      return RazorpayOrderResponse.fromJson(data);
    } on DioException catch (e) {
      throw e.error ?? 'Failed to initialize Razorpay order';
    }
  }

  /// Verify payment signature returned by Razorpay checkout
  Future<RazorpayPaymentModel> verifyPayment({
    required String orderId,
    required String paymentId,
    required String signature,
  }) async {
    try {
      final response = await _client.dio.post(
        ApiConfig.razorpayVerifyPayment,
        data: {
          'razorpay_order_id': orderId.trim(),
          'razorpay_payment_id': paymentId.trim(),
          'razorpay_signature': signature.trim(),
        },
      );

      final data = response.data as Map<String, dynamic>;
      final payJson = data['payment'] as Map<String, dynamic>;
      return RazorpayPaymentModel.fromJson(payJson);
    } on DioException catch (e) {
      throw e.error ?? 'Razorpay payment verification failed';
    }
  }

  /// Get status of a specific Razorpay payment
  Future<RazorpayPaymentModel> getPayment(String orderId) async {
    try {
      final response = await _client.dio.get(ApiConfig.razorpayPayment(orderId));
      final data = response.data as Map<String, dynamic>;
      final payJson = data['payment'] as Map<String, dynamic>;
      return RazorpayPaymentModel.fromJson(payJson);
    } on DioException catch (e) {
      throw e.error ?? 'Failed to get Razorpay payment';
    }
  }

  /// Fetch list of previous Razorpay payments for the authenticated user
  Future<List<RazorpayPaymentModel>> getPaymentHistory() async {
    try {
      final response = await _client.dio.get(ApiConfig.razorpayHistory);
      final data = response.data as Map<String, dynamic>;
      final list = data['payments'] as List<dynamic>? ?? [];

      return list
          .map((item) => RazorpayPaymentModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw e.error ?? 'Failed to fetch Razorpay history';
    }
  }
}

