class BeneficiaryAddress {
  final String street1;
  final String? street2;
  final String city;
  final String state;
  final String postalCode;
  final String country;

  BeneficiaryAddress({
    required this.street1,
    this.street2,
    required this.city,
    required this.state,
    required this.postalCode,
    this.country = 'US',
  });

  Map<String, dynamic> toJson() => {
    'street1': street1,
    if (street2 != null && street2!.isNotEmpty) 'street2': street2,
    'city': city,
    'state': state,
    'postalCode': postalCode,
    'country': country,
  };
}

class Beneficiary {
  final String name;
  final String email;
  final BeneficiaryAddress address;

  Beneficiary({
    required this.name,
    required this.email,
    required this.address,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'email': email,
    'address': address.toJson(),
  };
}

class BankAccount {
  final String accountType; // checking or savings
  final String routingNumber;
  final String accountNumber;
  final String? bankName;

  BankAccount({
    this.accountType = 'checking',
    required this.routingNumber,
    required this.accountNumber,
    this.bankName,
  });

  Map<String, dynamic> toJson() => {
    'accountType': accountType,
    'routingNumber': routingNumber,
    'accountNumber': accountNumber,
    if (bankName != null && bankName!.isNotEmpty) 'bankName': bankName,
  };
}

class OfframpPaymentMethod {
  final String paymentMethodId;
  final String type;
  final String status;

  OfframpPaymentMethod({
    required this.paymentMethodId,
    required this.type,
    required this.status,
  });

  factory OfframpPaymentMethod.fromJson(Map<String, dynamic> json) {
    return OfframpPaymentMethod(
      paymentMethodId: json['paymentMethodId']?.toString() ?? '',
      type: json['type']?.toString() ?? 'ach',
      status: json['status']?.toString() ?? 'active',
    );
  }
}

class OfframpOrderResult {
  final String orderId;
  final String status;
  final bool requiresKyc;
  final Map<String, dynamic>? transaction;

  OfframpOrderResult({
    required this.orderId,
    required this.status,
    required this.requiresKyc,
    this.transaction,
  });

  factory OfframpOrderResult.fromJson(Map<String, dynamic> json) {
    return OfframpOrderResult(
      orderId: json['orderId']?.toString() ?? '',
      status: json['status']?.toString() ?? 'created',
      requiresKyc: json['requiresKyc'] == true,
      transaction: json['transaction'] is Map<String, dynamic> ? json['transaction'] : null,
    );
  }
}

