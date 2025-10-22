enum BankAccountType {
  checking,
  savings,
  business,
}

enum BankAccountStatus {
  active,
  pending,
  suspended,
  closed,
}

/// Bank account information for receiving payments
class BankAccount {
  final String id;
  final String accountHolderName;
  final String accountNumber;
  final String routingNumber;
  final String bankName;
  final BankAccountType accountType;
  final BankAccountStatus status;
  final String? swiftCode; // For international transfers
  final String? iban; // For international transfers
  final String? address; // Bank address
  final String? city;
  final String? state;
  final String? zipCode;
  final String? country;
  final DateTime createdAt;
  final DateTime? verifiedAt;
  final bool isDefault; // Default account for receiving payments
  final Map<String, dynamic>? metadata;

  BankAccount({
    required this.id,
    required this.accountHolderName,
    required this.accountNumber,
    required this.routingNumber,
    required this.bankName,
    required this.accountType,
    this.status = BankAccountStatus.pending,
    this.swiftCode,
    this.iban,
    this.address,
    this.city,
    this.state,
    this.zipCode,
    this.country,
    required this.createdAt,
    this.verifiedAt,
    this.isDefault = false,
    this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'accountHolderName': accountHolderName,
      'accountNumber': accountNumber,
      'routingNumber': routingNumber,
      'bankName': bankName,
      'accountType': accountType.name,
      'status': status.name,
      'swiftCode': swiftCode,
      'iban': iban,
      'address': address,
      'city': city,
      'state': state,
      'zipCode': zipCode,
      'country': country,
      'createdAt': createdAt.toIso8601String(),
      'verifiedAt': verifiedAt?.toIso8601String(),
      'isDefault': isDefault,
      'metadata': metadata,
    };
  }

  factory BankAccount.fromJson(Map<String, dynamic> json) {
    return BankAccount(
      id: json['id'] as String,
      accountHolderName: json['accountHolderName'] as String,
      accountNumber: json['accountNumber'] as String,
      routingNumber: json['routingNumber'] as String,
      bankName: json['bankName'] as String,
      accountType: BankAccountType.values.firstWhere(
        (e) => e.name == json['accountType'],
        orElse: () => BankAccountType.checking,
      ),
      status: BankAccountStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => BankAccountStatus.pending,
      ),
      swiftCode: json['swiftCode'] as String?,
      iban: json['iban'] as String?,
      address: json['address'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      zipCode: json['zipCode'] as String?,
      country: json['country'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      verifiedAt: json['verifiedAt'] != null
          ? DateTime.parse(json['verifiedAt'] as String)
          : null,
      isDefault: json['isDefault'] as bool? ?? false,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  BankAccount copyWith({
    String? id,
    String? accountHolderName,
    String? accountNumber,
    String? routingNumber,
    String? bankName,
    BankAccountType? accountType,
    BankAccountStatus? status,
    String? swiftCode,
    String? iban,
    String? address,
    String? city,
    String? state,
    String? zipCode,
    String? country,
    DateTime? createdAt,
    DateTime? verifiedAt,
    bool? isDefault,
    Map<String, dynamic>? metadata,
  }) {
    return BankAccount(
      id: id ?? this.id,
      accountHolderName: accountHolderName ?? this.accountHolderName,
      accountNumber: accountNumber ?? this.accountNumber,
      routingNumber: routingNumber ?? this.routingNumber,
      bankName: bankName ?? this.bankName,
      accountType: accountType ?? this.accountType,
      status: status ?? this.status,
      swiftCode: swiftCode ?? this.swiftCode,
      iban: iban ?? this.iban,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      zipCode: zipCode ?? this.zipCode,
      country: country ?? this.country,
      createdAt: createdAt ?? this.createdAt,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      isDefault: isDefault ?? this.isDefault,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Check if account is active and verified
  bool get isActive => status == BankAccountStatus.active;

  /// Check if account is verified
  bool get isVerified => verifiedAt != null;

  /// Get masked account number for display
  String get maskedAccountNumber {
    if (accountNumber.length <= 4) return accountNumber;
    return '****${accountNumber.substring(accountNumber.length - 4)}';
  }

  /// Get account type display name
  String get accountTypeDisplay {
    switch (accountType) {
      case BankAccountType.checking:
        return 'Checking Account';
      case BankAccountType.savings:
        return 'Savings Account';
      case BankAccountType.business:
        return 'Business Account';
    }
  }

  /// Get status display name
  String get statusDisplay {
    switch (status) {
      case BankAccountStatus.active:
        return 'Active';
      case BankAccountStatus.pending:
        return 'Pending Verification';
      case BankAccountStatus.suspended:
        return 'Suspended';
      case BankAccountStatus.closed:
        return 'Closed';
    }
  }

  /// Get account icon based on type
  String get accountIcon {
    switch (accountType) {
      case BankAccountType.checking:
        return '🏦';
      case BankAccountType.savings:
        return '💰';
      case BankAccountType.business:
        return '🏢';
    }
  }
}
