enum SubscriptionStatus {
  trial, // Free trial period
  active, // Active paid subscription
  pastDue, // Payment failed, grace period
  suspended, // Suspended due to non-payment
  cancelled, // Cancelled by user
  expired, // Trial or subscription expired
}

enum PaymentMethod {
  creditCard,
  debitCard,
  paypal,
  bankTransfer,
  manual, // Manual payment (invoice)
  none, // Free tier
}

enum BillingInterval {
  monthly,
  yearly,
}

/// Company subscription information
class CompanySubscription {
  final String id;
  final String companyId;
  final String tierId;
  final DateTime startDate;
  final DateTime? endDate; // null for active subscriptions
  final SubscriptionStatus status;
  final PaymentMethod paymentMethod;
  final BillingInterval billingInterval;
  final DateTime nextBillingDate;
  final double currentPrice; // Current price (may differ from tier if grandfathered)
  final DateTime? trialEndsAt; // null if not in trial
  final int gracePeriodDays; // Days after payment failure before suspension
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? metadata; // Extra info (coupon codes, discounts, etc.)

  CompanySubscription({
    required this.id,
    required this.companyId,
    required this.tierId,
    required this.startDate,
    this.endDate,
    required this.status,
    required this.paymentMethod,
    required this.billingInterval,
    required this.nextBillingDate,
    required this.currentPrice,
    this.trialEndsAt,
    this.gracePeriodDays = 7,
    required this.createdAt,
    required this.updatedAt,
    this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'companyId': companyId,
      'tierId': tierId,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'status': status.name,
      'paymentMethod': paymentMethod.name,
      'billingInterval': billingInterval.name,
      'nextBillingDate': nextBillingDate.toIso8601String(),
      'currentPrice': currentPrice,
      'trialEndsAt': trialEndsAt?.toIso8601String(),
      'gracePeriodDays': gracePeriodDays,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'metadata': metadata,
    };
  }

  factory CompanySubscription.fromJson(Map<String, dynamic> json) {
    return CompanySubscription(
      id: json['id'] as String,
      companyId: json['companyId'] as String,
      tierId: json['tierId'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: json['endDate'] != null 
          ? DateTime.parse(json['endDate'] as String) 
          : null,
      status: SubscriptionStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => SubscriptionStatus.trial,
      ),
      paymentMethod: PaymentMethod.values.firstWhere(
        (e) => e.name == json['paymentMethod'],
        orElse: () => PaymentMethod.none,
      ),
      billingInterval: BillingInterval.values.firstWhere(
        (e) => e.name == json['billingInterval'],
        orElse: () => BillingInterval.monthly,
      ),
      nextBillingDate: DateTime.parse(json['nextBillingDate'] as String),
      currentPrice: (json['currentPrice'] as num).toDouble(),
      trialEndsAt: json['trialEndsAt'] != null 
          ? DateTime.parse(json['trialEndsAt'] as String) 
          : null,
      gracePeriodDays: json['gracePeriodDays'] as int? ?? 7,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  CompanySubscription copyWith({
    String? id,
    String? companyId,
    String? tierId,
    DateTime? startDate,
    DateTime? endDate,
    SubscriptionStatus? status,
    PaymentMethod? paymentMethod,
    BillingInterval? billingInterval,
    DateTime? nextBillingDate,
    double? currentPrice,
    DateTime? trialEndsAt,
    int? gracePeriodDays,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return CompanySubscription(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      tierId: tierId ?? this.tierId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      billingInterval: billingInterval ?? this.billingInterval,
      nextBillingDate: nextBillingDate ?? this.nextBillingDate,
      currentPrice: currentPrice ?? this.currentPrice,
      trialEndsAt: trialEndsAt ?? this.trialEndsAt,
      gracePeriodDays: gracePeriodDays ?? this.gracePeriodDays,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Check if subscription is in good standing
  bool get isActive => status == SubscriptionStatus.active || 
                       status == SubscriptionStatus.trial;

  /// Check if in trial period
  bool get isTrial => status == SubscriptionStatus.trial;

  /// Check if subscription needs attention
  bool get needsAttention => status == SubscriptionStatus.pastDue || 
                             status == SubscriptionStatus.suspended;

  /// Days until trial ends (negative if expired)
  int? get daysUntilTrialEnds {
    if (trialEndsAt == null) return null;
    return trialEndsAt!.difference(DateTime.now()).inDays;
  }

  /// Days until next billing
  int get daysUntilNextBilling {
    return nextBillingDate.difference(DateTime.now()).inDays;
  }
}

