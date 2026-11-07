class FeeEstimateModel {
  final String? low;
  final String? medium;
  final String? high;
  final Map<String, dynamic> raw;

  FeeEstimateModel({
    this.low,
    this.medium,
    this.high,
    this.raw = const {},
  });

  factory FeeEstimateModel.fromJson(Map<String, dynamic> json) {
    String? extractFee(dynamic item) {
      if (item is Map) {
        return item['networkFee']?.toString() ??
            item['fee']?.toString() ??
            item['gasLimit']?.toString();
      }
      return item?.toString();
    }

    final low = extractFee(json['low']);
    final medium = extractFee(json['medium']);
    final high = extractFee(json['high']);

    return FeeEstimateModel(
      low: low,
      medium: medium,
      high: high,
      raw: json,
    );
  }

  String get displayFee => medium ?? low ?? '0.001 MATIC';
}

