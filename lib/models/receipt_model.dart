/// Transaction Receipt Model
/// Represents an immutable receipt generated for an on-chain Circle transfer or sandbox ledger transfer.
class TransactionReceiptModel {
  final String transactionId;
  final String reference;
  final String type;
  final String status;
  final String asset;
  final String amount;
  final String? senderWalletAddress;
  final String? destinationAddress;
  final String? network;
  final String? provider;
  final String? providerTransactionId;
  final String? transactionHash;
  final DateTime createdAt;
  final DateTime updatedAt;

  TransactionReceiptModel({
    required this.transactionId,
    required this.reference,
    required this.type,
    required this.status,
    required this.asset,
    required this.amount,
    this.senderWalletAddress,
    this.destinationAddress,
    this.network,
    this.provider,
    this.providerTransactionId,
    this.transactionHash,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TransactionReceiptModel.fromJson(Map<String, dynamic> json) {
    return TransactionReceiptModel(
      transactionId: json['transactionId']?.toString() ?? '',
      reference: json['reference']?.toString() ?? '',
      type: json['type']?.toString() ?? 'wallet_transfer',
      status: json['status']?.toString() ?? 'completed',
      asset: json['asset']?.toString() ?? 'USDC',
      amount: json['amount']?.toString() ?? '0',
      senderWalletAddress: json['senderWalletAddress']?.toString(),
      destinationAddress: json['destinationAddress']?.toString(),
      network: json['network']?.toString() ?? 'MATIC-AMOY',
      provider: json['provider']?.toString(),
      providerTransactionId: json['providerTransactionId']?.toString(),
      transactionHash: json['transactionHash']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

/// Razorpay Payment Receipt Model
/// Represents a verified checkout receipt for INR deposits and card/UPI top-ups.
class RazorpayReceiptModel {
  final String orderId;
  final String? paymentId;
  final String status;
  final dynamic amountPaise;
  final double amountInr;
  final String currency;
  final bool signatureVerified;
  final DateTime createdAt;
  final DateTime updatedAt;

  RazorpayReceiptModel({
    required this.orderId,
    this.paymentId,
    required this.status,
    required this.amountPaise,
    required this.amountInr,
    required this.currency,
    required this.signatureVerified,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RazorpayReceiptModel.fromJson(Map<String, dynamic> json) {
    return RazorpayReceiptModel(
      orderId: json['orderId']?.toString() ?? '',
      paymentId: json['paymentId']?.toString(),
      status: json['status']?.toString() ?? 'captured',
      amountPaise: json['amountPaise'],
      amountInr: (json['amountInr'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency']?.toString() ?? 'INR',
      signatureVerified: json['signatureVerified'] == true,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
