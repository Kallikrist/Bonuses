enum TransactionType {
  subscription, // Subscription payment
  bonus, // Bonus redemption
  refund, // Refund transaction
  adjustment, // Manual adjustment
  gift, // Gift card purchase
  points, // Points purchase
  other, // Other transaction
}

enum TransactionStatus {
  pending, // Transaction initiated
  processing, // Being processed
  completed, // Successfully completed
  failed, // Failed to process
  cancelled, // Cancelled by user
  refunded, // Refunded
  partiallyRefunded, // Partially refunded
}

enum TransactionCategory {
  subscription, // Platform subscription
  bonus, // Bonus redemption
  gift, // Gift card
  points, // Points purchase
  refund, // Refund
  adjustment, // Manual adjustment
  other, // Other
}

/// Financial transaction for actual money transactions
class FinancialTransaction {
  final String id;
  final String companyId;
  final String userId; // User who initiated the transaction
  final TransactionType type;
  final TransactionStatus status;
  final TransactionCategory category;
  final double amount;
  final String currency;
  final String description;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? paymentCardId; // Card used for payment
  final String? subscriptionId; // Related subscription
  final String? bonusId; // Related bonus redemption
  final String? invoiceId; // Invoice ID
  final String? transactionId; // External transaction ID
  final String? paymentGateway; // Stripe, PayPal, etc.
  final String? failureReason;
  final double? refundedAmount;
  final DateTime? refundedAt;
  final String? receiptUrl;
  final Map<String, dynamic>? metadata;

  FinancialTransaction({
    required this.id,
    required this.companyId,
    required this.userId,
    required this.type,
    required this.status,
    required this.category,
    required this.amount,
    this.currency = 'USD',
    required this.description,
    required this.createdAt,
    this.completedAt,
    this.paymentCardId,
    this.subscriptionId,
    this.bonusId,
    this.invoiceId,
    this.transactionId,
    this.paymentGateway,
    this.failureReason,
    this.refundedAmount,
    this.refundedAt,
    this.receiptUrl,
    this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'companyId': companyId,
      'userId': userId,
      'type': type.name,
      'status': status.name,
      'category': category.name,
      'amount': amount,
      'currency': currency,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'paymentCardId': paymentCardId,
      'subscriptionId': subscriptionId,
      'bonusId': bonusId,
      'invoiceId': invoiceId,
      'transactionId': transactionId,
      'paymentGateway': paymentGateway,
      'failureReason': failureReason,
      'refundedAmount': refundedAmount,
      'refundedAt': refundedAt?.toIso8601String(),
      'receiptUrl': receiptUrl,
      'metadata': metadata,
    };
  }

  factory FinancialTransaction.fromJson(Map<String, dynamic> json) {
    return FinancialTransaction(
      id: json['id'] as String,
      companyId: json['companyId'] as String,
      userId: json['userId'] as String,
      type: TransactionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => TransactionType.other,
      ),
      status: TransactionStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => TransactionStatus.pending,
      ),
      category: TransactionCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => TransactionCategory.other,
      ),
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'USD',
      description: json['description'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      completedAt: json['completedAt'] != null 
          ? DateTime.parse(json['completedAt'] as String) 
          : null,
      paymentCardId: json['paymentCardId'] as String?,
      subscriptionId: json['subscriptionId'] as String?,
      bonusId: json['bonusId'] as String?,
      invoiceId: json['invoiceId'] as String?,
      transactionId: json['transactionId'] as String?,
      paymentGateway: json['paymentGateway'] as String?,
      failureReason: json['failureReason'] as String?,
      refundedAmount: json['refundedAmount'] != null 
          ? (json['refundedAmount'] as num).toDouble() 
          : null,
      refundedAt: json['refundedAt'] != null 
          ? DateTime.parse(json['refundedAt'] as String) 
          : null,
      receiptUrl: json['receiptUrl'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  FinancialTransaction copyWith({
    String? id,
    String? companyId,
    String? userId,
    TransactionType? type,
    TransactionStatus? status,
    TransactionCategory? category,
    double? amount,
    String? currency,
    String? description,
    DateTime? createdAt,
    DateTime? completedAt,
    String? paymentCardId,
    String? subscriptionId,
    String? bonusId,
    String? invoiceId,
    String? transactionId,
    String? paymentGateway,
    String? failureReason,
    double? refundedAmount,
    DateTime? refundedAt,
    String? receiptUrl,
    Map<String, dynamic>? metadata,
  }) {
    return FinancialTransaction(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      status: status ?? this.status,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      paymentCardId: paymentCardId ?? this.paymentCardId,
      subscriptionId: subscriptionId ?? this.subscriptionId,
      bonusId: bonusId ?? this.bonusId,
      invoiceId: invoiceId ?? this.invoiceId,
      transactionId: transactionId ?? this.transactionId,
      paymentGateway: paymentGateway ?? this.paymentGateway,
      failureReason: failureReason ?? this.failureReason,
      refundedAmount: refundedAmount ?? this.refundedAmount,
      refundedAt: refundedAt ?? this.refundedAt,
      receiptUrl: receiptUrl ?? this.receiptUrl,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Check if transaction was successful
  bool get isSuccessful => status == TransactionStatus.completed || 
                          status == TransactionStatus.refunded || 
                          status == TransactionStatus.partiallyRefunded;

  /// Check if transaction failed
  bool get isFailed => status == TransactionStatus.failed || 
                       status == TransactionStatus.cancelled;

  /// Check if transaction was refunded
  bool get isRefunded => status == TransactionStatus.refunded || 
                         status == TransactionStatus.partiallyRefunded;

  /// Get effective amount (after refunds)
  double get effectiveAmount {
    if (refundedAmount != null) {
      return amount - refundedAmount!;
    }
    return amount;
  }

  /// Get formatted amount with currency
  String get formattedAmount {
    return '\$${amount.toStringAsFixed(2)} $currency';
  }

  /// Get transaction icon based on type
  String get transactionIcon {
    switch (type) {
      case TransactionType.subscription:
        return '💳';
      case TransactionType.bonus:
        return '🎁';
      case TransactionType.refund:
        return '↩️';
      case TransactionType.adjustment:
        return '⚖️';
      case TransactionType.gift:
        return '🎁';
      case TransactionType.points:
        return '⭐';
      default:
        return '💰';
    }
  }
}
