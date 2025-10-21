enum PaymentStatus {
  pending, // Payment initiated but not confirmed
  processing, // Being processed by payment gateway
  completed, // Successfully completed
  failed, // Failed to process
  refunded, // Refunded to customer
  partiallyRefunded, // Partially refunded
  cancelled, // Cancelled before processing
}

/// Payment record for subscription billing
class PaymentRecord {
  final String id;
  final String companyId;
  final String subscriptionId;
  final double amount;
  final String currency;
  final PaymentStatus status;
  final DateTime date;
  final String? invoiceId;
  final String? transactionId; // ID from payment gateway
  final String? paymentGateway; // stripe, paypal, etc.
  final String? failureReason;
  final DateTime? refundedAt;
  final double? refundedAmount;
  final String? receiptUrl; // URL to payment receipt
  final Map<String, dynamic>? metadata;

  PaymentRecord({
    required this.id,
    required this.companyId,
    required this.subscriptionId,
    required this.amount,
    this.currency = 'USD',
    required this.status,
    required this.date,
    this.invoiceId,
    this.transactionId,
    this.paymentGateway,
    this.failureReason,
    this.refundedAt,
    this.refundedAmount,
    this.receiptUrl,
    this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'companyId': companyId,
      'subscriptionId': subscriptionId,
      'amount': amount,
      'currency': currency,
      'status': status.name,
      'date': date.toIso8601String(),
      'invoiceId': invoiceId,
      'transactionId': transactionId,
      'paymentGateway': paymentGateway,
      'failureReason': failureReason,
      'refundedAt': refundedAt?.toIso8601String(),
      'refundedAmount': refundedAmount,
      'receiptUrl': receiptUrl,
      'metadata': metadata,
    };
  }

  factory PaymentRecord.fromJson(Map<String, dynamic> json) {
    return PaymentRecord(
      id: json['id'] as String,
      companyId: json['companyId'] as String,
      subscriptionId: json['subscriptionId'] as String,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'USD',
      status: PaymentStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => PaymentStatus.pending,
      ),
      date: DateTime.parse(json['date'] as String),
      invoiceId: json['invoiceId'] as String?,
      transactionId: json['transactionId'] as String?,
      paymentGateway: json['paymentGateway'] as String?,
      failureReason: json['failureReason'] as String?,
      refundedAt: json['refundedAt'] != null 
          ? DateTime.parse(json['refundedAt'] as String) 
          : null,
      refundedAmount: json['refundedAmount'] != null 
          ? (json['refundedAmount'] as num).toDouble() 
          : null,
      receiptUrl: json['receiptUrl'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  PaymentRecord copyWith({
    String? id,
    String? companyId,
    String? subscriptionId,
    double? amount,
    String? currency,
    PaymentStatus? status,
    DateTime? date,
    String? invoiceId,
    String? transactionId,
    String? paymentGateway,
    String? failureReason,
    DateTime? refundedAt,
    double? refundedAmount,
    String? receiptUrl,
    Map<String, dynamic>? metadata,
  }) {
    return PaymentRecord(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      subscriptionId: subscriptionId ?? this.subscriptionId,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      status: status ?? this.status,
      date: date ?? this.date,
      invoiceId: invoiceId ?? this.invoiceId,
      transactionId: transactionId ?? this.transactionId,
      paymentGateway: paymentGateway ?? this.paymentGateway,
      failureReason: failureReason ?? this.failureReason,
      refundedAt: refundedAt ?? this.refundedAt,
      refundedAmount: refundedAmount ?? this.refundedAmount,
      receiptUrl: receiptUrl ?? this.receiptUrl,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Check if payment was successful
  bool get isSuccessful => status == PaymentStatus.completed;

  /// Check if payment failed
  bool get isFailed => status == PaymentStatus.failed || 
                       status == PaymentStatus.cancelled;

  /// Check if payment was refunded (fully or partially)
  bool get isRefunded => status == PaymentStatus.refunded || 
                         status == PaymentStatus.partiallyRefunded;

  /// Get effective amount (after refunds)
  double get effectiveAmount {
    if (refundedAmount != null) {
      return amount - refundedAmount!;
    }
    return amount;
  }
}

