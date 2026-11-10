/// Razorpay Payment Model
///
/// Represents an instant fiat INR top-up or payment order processed via Razorpay.
class RazorpayOrderResponse {
  final String keyId;
  final String orderId;
  final double amount; // in INR
  final String currency;
  final RazorpayPaymentModel payment;

  RazorpayOrderResponse({
    required this.keyId,
    required this.orderId,
    required this.amount,
    this.currency = 'INR',
    required this.payment,
  });

  factory RazorpayOrderResponse.fromJson(Map<String, dynamic> json) {
    return RazorpayOrderResponse(
      keyId: json['keyId']?.toString() ?? '',
      orderId: json['orderId']?.toString() ?? '',
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      currency: json['currency']?.toString() ?? 'INR',
      payment: RazorpayPaymentModel.fromJson(
        json['payment'] as Map<String, dynamic>? ?? json,
      ),
    );
  }
}

class RazorpayPaymentModel {
  final String id;
  final String razorpayOrderId;
  final String? razorpayPaymentId;
  final String? receipt;
  final double amount; // in rupees
  final String currency;
  final String status;
  final bool signatureVerified;
  final String? failureReason;
  final DateTime createdAt;

  RazorpayPaymentModel({
    required this.id,
    required this.razorpayOrderId,
    this.razorpayPaymentId,
    this.receipt,
    required this.amount,
    this.currency = 'INR',
    this.status = 'created',
    this.signatureVerified = false,
    this.failureReason,
    required this.createdAt,
  });

  bool get isCaptured => status == 'captured';
  bool get isFailed => status == 'failed';
  bool get isCreated => status == 'created';

  /// Amount in display rupees
  String get formattedAmount => '₹${amount.toStringAsFixed(2)}';

  factory RazorpayPaymentModel.fromJson(Map<String, dynamic> json) {
    // If backend returns paise, normalize; otherwise keep raw number
    final rawAmount = double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0;
    // Backend creates with input.amount (e.g. 100), but stores paise in DB (10000)
    final normalizedAmount = rawAmount > 5000 && (json['providerPayload'] != null || json['receipt'] != null)
        ? rawAmount / 100
        : rawAmount;

    return RazorpayPaymentModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      razorpayOrderId: json['razorpayOrderId']?.toString() ?? json['orderId']?.toString() ?? '',
      razorpayPaymentId: json['razorpayPaymentId']?.toString() ?? json['paymentId']?.toString(),
      receipt: json['receipt']?.toString(),
      amount: normalizedAmount,
      currency: json['currency']?.toString() ?? 'INR',
      status: json['status']?.toString() ?? 'created',
      signatureVerified: json['signatureVerified'] == true,
      failureReason: json['failureReason']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

