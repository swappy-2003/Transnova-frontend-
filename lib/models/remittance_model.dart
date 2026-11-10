/// Remittance Stage Timeline Event
class RemittanceTimelineEvent {
  final String stage;
  final String status;
  final DateTime timestamp;
  final dynamic details;

  RemittanceTimelineEvent({
    required this.stage,
    required this.status,
    required this.timestamp,
    this.details,
  });

  factory RemittanceTimelineEvent.fromJson(Map<String, dynamic> json) {
    return RemittanceTimelineEvent(
      stage: json['stage']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
      details: json['details'],
    );
  }
}

/// End-to-End Remittance Pipeline Model
///
/// Flow 1 (Multi-Hop Remittance):
/// Sender INR (Transak On-ramp) -> Polygon USDC -> Recipient USD (Crossmint Off-ramp ACH)
class RemittanceModel {
  final String id;
  final String reference;
  final String senderCurrency;
  final double senderAmount;
  final double? usdcAmount;
  final String recipientCurrency;
  final double? recipientAmount;
  final String recipientPaymentMethodId;
  final String status;
  final List<RemittanceTimelineEvent> timeline;
  final String? widgetUrl;
  final DateTime createdAt;

  RemittanceModel({
    required this.id,
    required this.reference,
    this.senderCurrency = 'INR',
    required this.senderAmount,
    this.usdcAmount,
    this.recipientCurrency = 'USD',
    this.recipientAmount,
    required this.recipientPaymentMethodId,
    required this.status,
    this.timeline = const [],
    this.widgetUrl,
    required this.createdAt,
  });

  bool get isCompleted => status == 'completed';
  bool get isFailed => status == 'failed' || status == 'cancelled';
  bool get isInProgress => !isCompleted && !isFailed;

  /// User friendly status label
  String get displayStatus {
    switch (status) {
      case 'onramp_pending':
        return 'Deposit Pending';
      case 'onramp_completed':
        return 'Deposit Received';
      case 'transfer_pending':
        return 'Transferring USDC';
      case 'transfer_completed':
        return 'USDC Transferred';
      case 'offramp_pending':
        return 'Bank Payout Pending';
      case 'completed':
        return 'Completed';
      case 'failed':
        return 'Failed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status.replaceAll('_', ' ').toUpperCase();
    }
  }

  factory RemittanceModel.fromJson(Map<String, dynamic> json) {
    final rawTimeline = json['timeline'] as List<dynamic>? ?? [];
    final timelineEvents = rawTimeline
        .map((e) => RemittanceTimelineEvent.fromJson(e as Map<String, dynamic>))
        .toList();

    return RemittanceModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      reference: json['reference']?.toString() ?? '',
      senderCurrency: json['senderCurrency']?.toString() ?? 'INR',
      senderAmount: double.tryParse(json['senderAmount']?.toString() ?? '0') ?? 0.0,
      usdcAmount: double.tryParse(json['usdcAmount']?.toString() ?? ''),
      recipientCurrency: json['recipientCurrency']?.toString() ?? 'USD',
      recipientAmount: double.tryParse(json['recipientAmount']?.toString() ?? ''),
      recipientPaymentMethodId: json['recipientPaymentMethodId']?.toString() ?? '',
      status: json['status']?.toString() ?? 'created',
      timeline: timelineEvents,
      widgetUrl: json['widgetUrl']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

