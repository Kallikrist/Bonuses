enum CardType {
  visa,
  mastercard,
  americanExpress,
  discover,
  dinersClub,
  jcb,
  unionPay,
  unknown,
}

enum CardStatus {
  active,
  expired,
  blocked,
  pending,
  failed,
}

/// Payment card information for processing transactions
class PaymentCard {
  final String id;
  final String companyId;
  final String userId; // User who added the card
  final String lastFourDigits;
  final String brand; // Visa, Mastercard, etc.
  final CardType cardType;
  final int expiryMonth;
  final int expiryYear;
  final String? cardholderName;
  final CardStatus status;
  final DateTime createdAt;
  final DateTime? lastUsedAt;
  final bool isDefault; // Default card for this company
  final String? stripeCardId; // Stripe card ID for processing
  final String? fingerprint; // Card fingerprint for security
  final Map<String, dynamic>? metadata;

  PaymentCard({
    required this.id,
    required this.companyId,
    required this.userId,
    required this.lastFourDigits,
    required this.brand,
    required this.cardType,
    required this.expiryMonth,
    required this.expiryYear,
    this.cardholderName,
    this.status = CardStatus.active,
    required this.createdAt,
    this.lastUsedAt,
    this.isDefault = false,
    this.stripeCardId,
    this.fingerprint,
    this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'companyId': companyId,
      'userId': userId,
      'lastFourDigits': lastFourDigits,
      'brand': brand,
      'cardType': cardType.name,
      'expiryMonth': expiryMonth,
      'expiryYear': expiryYear,
      'cardholderName': cardholderName,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'lastUsedAt': lastUsedAt?.toIso8601String(),
      'isDefault': isDefault,
      'stripeCardId': stripeCardId,
      'fingerprint': fingerprint,
      'metadata': metadata,
    };
  }

  factory PaymentCard.fromJson(Map<String, dynamic> json) {
    return PaymentCard(
      id: json['id'] as String,
      companyId: json['companyId'] as String,
      userId: json['userId'] as String,
      lastFourDigits: json['lastFourDigits'] as String,
      brand: json['brand'] as String,
      cardType: CardType.values.firstWhere(
        (e) => e.name == json['cardType'],
        orElse: () => CardType.unknown,
      ),
      expiryMonth: json['expiryMonth'] as int,
      expiryYear: json['expiryYear'] as int,
      cardholderName: json['cardholderName'] as String?,
      status: CardStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => CardStatus.active,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastUsedAt: json['lastUsedAt'] != null 
          ? DateTime.parse(json['lastUsedAt'] as String) 
          : null,
      isDefault: json['isDefault'] as bool? ?? false,
      stripeCardId: json['stripeCardId'] as String?,
      fingerprint: json['fingerprint'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  PaymentCard copyWith({
    String? id,
    String? companyId,
    String? userId,
    String? lastFourDigits,
    String? brand,
    CardType? cardType,
    int? expiryMonth,
    int? expiryYear,
    String? cardholderName,
    CardStatus? status,
    DateTime? createdAt,
    DateTime? lastUsedAt,
    bool? isDefault,
    String? stripeCardId,
    String? fingerprint,
    Map<String, dynamic>? metadata,
  }) {
    return PaymentCard(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      userId: userId ?? this.userId,
      lastFourDigits: lastFourDigits ?? this.lastFourDigits,
      brand: brand ?? this.brand,
      cardType: cardType ?? this.cardType,
      expiryMonth: expiryMonth ?? this.expiryMonth,
      expiryYear: expiryYear ?? this.expiryYear,
      cardholderName: cardholderName ?? this.cardholderName,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      isDefault: isDefault ?? this.isDefault,
      stripeCardId: stripeCardId ?? this.stripeCardId,
      fingerprint: fingerprint ?? this.fingerprint,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Check if card is expired
  bool get isExpired {
    final now = DateTime.now();
    return expiryYear < now.year || 
           (expiryYear == now.year && expiryMonth < now.month);
  }

  /// Check if card is valid for use
  bool get isValid => status == CardStatus.active && !isExpired;

  /// Get masked card number for display
  String get maskedNumber => '**** **** **** $lastFourDigits';

  /// Get expiry date as string
  String get expiryDate => '${expiryMonth.toString().padLeft(2, '0')}/$expiryYear';

  /// Get card icon based on type
  String get cardIcon {
    switch (cardType) {
      case CardType.visa:
        return '💳';
      case CardType.mastercard:
        return '💳';
      case CardType.americanExpress:
        return '💳';
      case CardType.discover:
        return '💳';
      default:
        return '💳';
    }
  }
}
