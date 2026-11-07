class OnrampOrderModel {
  final String widgetUrl;
  final String transactionId;
  final String reference;
  final String status;
  final double fiatAmount;
  final String fiatCurrency;

  OnrampOrderModel({
    required this.widgetUrl,
    required this.transactionId,
    required this.reference,
    required this.status,
    required this.fiatAmount,
    required this.fiatCurrency,
  });

  factory OnrampOrderModel.fromJson(Map<String, dynamic> json) {
    final tx = json['transaction'] as Map<String, dynamic>? ?? {};
    double parsedAmount = 0.0;
    if (tx['sourceAmount'] != null) {
      if (tx['sourceAmount'] is Map && tx['sourceAmount']['\$numberDecimal'] != null) {
        parsedAmount = double.tryParse(tx['sourceAmount']['\$numberDecimal'].toString()) ?? 0.0;
      } else {
        parsedAmount = double.tryParse(tx['sourceAmount'].toString()) ?? 0.0;
      }
    }

    return OnrampOrderModel(
      widgetUrl: json['widgetUrl']?.toString() ?? '',
      transactionId: tx['_id']?.toString() ?? tx['id']?.toString() ?? '',
      reference: tx['reference']?.toString() ?? '',
      status: tx['status']?.toString() ?? 'pending',
      fiatAmount: parsedAmount,
      fiatCurrency: tx['sourceCurrency']?.toString() ?? 'USD',
    );
  }
}

