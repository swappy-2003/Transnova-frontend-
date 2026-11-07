class TransactionModel {
  final String id;
  final String reference;
  final String type; // payin, wallet_transfer, offramp
  final String asset;
  final double amount;
  final String status; // created, pending, processing, completed, failed, cancelled
  final String? circleTxHash;
  final String? circleStatus;
  final String? transakOrderId;
  final String? transakStatus;
  final String? crossmintOrderId;
  final String? crossmintStatus;
  final DateTime? createdAt;
  final Map<String, dynamic>? metadata;

  TransactionModel({
    required this.id,
    required this.reference,
    required this.type,
    required this.asset,
    required this.amount,
    required this.status,
    this.circleTxHash,
    this.circleStatus,
    this.transakOrderId,
    this.transakStatus,
    this.crossmintOrderId,
    this.crossmintStatus,
    this.createdAt,
    this.metadata,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    double parsedAmount = 0.0;
    if (json['amount'] != null) {
      if (json['amount'] is Map && json['amount']['\$numberDecimal'] != null) {
        parsedAmount = double.tryParse(json['amount']['\$numberDecimal'].toString()) ?? 0.0;
      } else {
        parsedAmount = double.tryParse(json['amount'].toString()) ?? 0.0;
      }
    }

    return TransactionModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      reference: json['reference']?.toString() ?? '',
      type: json['type']?.toString() ?? 'wallet_transfer',
      asset: json['asset']?.toString() ?? 'USDC',
      amount: parsedAmount,
      status: json['status']?.toString() ?? 'pending',
      circleTxHash: json['circleTxHash']?.toString(),
      circleStatus: json['circleStatus']?.toString(),
      transakOrderId: json['transakOrderId']?.toString(),
      transakStatus: json['transakStatus']?.toString(),
      crossmintOrderId: json['crossmintOrderId']?.toString(),
      crossmintStatus: json['crossmintStatus']?.toString(),
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
      metadata: json['metadata'] is Map<String, dynamic> ? json['metadata'] : null,
    );
  }

  bool get isCompleted => status == 'completed' || circleStatus == 'CONFIRMED' || transakStatus == 'COMPLETED';
  bool get isFailed => status == 'failed' || circleStatus == 'FAILED' || transakStatus == 'FAILED';
  bool get isPending => !isCompleted && !isFailed;

  String get description {
    if (metadata != null && metadata!['description'] != null) {
      return metadata!['description'].toString();
    }
    switch (type) {
      case 'payin':
        return 'USDC Deposit';
      case 'offramp':
        return 'ACH Cash Out';
      default:
        return 'Circle Transfer';
    }
  }

  String? get destinationAddress => metadata?['destinationAddress']?.toString();
  String get currency => asset;
  String? get circleId => circleTxHash;
}

