/// Recipient Model
/// Represents a verified Transnova recipient resolved by email.
class RecipientModel {
  final String displayName;
  final String walletAddress;
  final String blockchain;
  final String asset;

  RecipientModel({
    required this.displayName,
    required this.walletAddress,
    required this.blockchain,
    required this.asset,
  });

  factory RecipientModel.fromJson(Map<String, dynamic> json) {
    return RecipientModel(
      displayName: json['displayName']?.toString() ?? '',
      walletAddress: json['walletAddress']?.toString() ?? '',
      blockchain: json['blockchain']?.toString() ?? 'MATIC-AMOY',
      asset: json['asset']?.toString() ?? 'USDC',
    );
  }

  Map<String, dynamic> toJson() => {
    'displayName': displayName,
    'walletAddress': walletAddress,
    'blockchain': blockchain,
    'asset': asset,
  };
}
