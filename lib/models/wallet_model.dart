class TokenBalance {
  final String symbol;
  final String name;
  final String amount;
  final int decimals;

  TokenBalance({
    required this.symbol,
    required this.name,
    required this.amount,
    this.decimals = 6,
  });

  factory TokenBalance.fromJson(Map<String, dynamic> json) {
    final token = json['token'] as Map<String, dynamic>?;
    return TokenBalance(
      symbol: token?['symbol']?.toString() ?? json['symbol']?.toString() ?? 'USDC',
      name: token?['name']?.toString() ?? json['name']?.toString() ?? 'USD Coin',
      amount: json['amount']?.toString() ?? '0.00',
      decimals: token?['decimals'] is int ? token!['decimals'] : 6,
    );
  }

  double get numericAmount => double.tryParse(amount) ?? 0.0;
}

class WalletModel {
  final String id;
  final String userId;
  final String provider;
  final String asset;
  final String network;
  final String blockchain;
  final String address;
  final String? circleWalletId;
  final String? circleAddress;
  final String accountType;
  final String status;
  final List<TokenBalance> balances;
  final String? usdcTokenId;

  WalletModel({
    required this.id,
    required this.userId,
    this.provider = 'circle',
    this.asset = 'USDC',
    this.network = 'MATIC-AMOY',
    this.blockchain = 'MATIC-AMOY',
    required this.address,
    this.circleWalletId,
    this.circleAddress,
    this.accountType = 'SCA',
    this.status = 'active',
    this.balances = const [],
    this.usdcTokenId,
  });

  String get effectiveAddress => (circleAddress != null && circleAddress!.isNotEmpty)
      ? circleAddress!
      : address;

  String get effectiveWalletId => (circleWalletId != null && circleWalletId!.isNotEmpty)
      ? circleWalletId!
      : id;

  double get usdcBalance {
    for (final b in balances) {
      if (b.symbol.toUpperCase() == 'USDC') {
        return b.numericAmount;
      }
    }
    return 0.0;
  }

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    return WalletModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      userId: json['user']?.toString() ?? '',
      provider: json['provider']?.toString() ?? 'circle',
      asset: json['asset']?.toString() ?? 'USDC',
      network: json['network']?.toString() ?? 'MATIC-AMOY',
      blockchain: json['blockchain']?.toString() ?? 'MATIC-AMOY',
      address: json['address']?.toString() ?? json['circleAddress']?.toString() ?? '',
      circleWalletId: json['circleWalletId']?.toString() ?? json['providerWalletId']?.toString(),
      circleAddress: json['circleAddress']?.toString(),
      accountType: json['accountType']?.toString() ?? 'SCA',
      status: json['status']?.toString() ?? 'active',
    );
  }

  WalletModel copyWith({
    List<TokenBalance>? balances,
    String? usdcTokenId,
  }) {
    return WalletModel(
      id: id,
      userId: userId,
      provider: provider,
      asset: asset,
      network: network,
      blockchain: blockchain,
      address: address,
      circleWalletId: circleWalletId,
      circleAddress: circleAddress,
      accountType: accountType,
      status: status,
      balances: balances ?? this.balances,
      usdcTokenId: usdcTokenId ?? this.usdcTokenId,
    );
  }
}

