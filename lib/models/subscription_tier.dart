/// Subscription tier defining pricing and limits
class SubscriptionTier {
  final String id;
  final String name;
  final String description;
  final double monthlyPrice;
  final double? yearlyPrice; // Optional annual pricing
  final int maxEmployees;
  final int maxWorkplaces;
  final int maxBonuses;
  final List<String> features;
  final bool isActive;

  const SubscriptionTier({
    required this.id,
    required this.name,
    required this.description,
    required this.monthlyPrice,
    this.yearlyPrice,
    required this.maxEmployees,
    required this.maxWorkplaces,
    required this.maxBonuses,
    required this.features,
    this.isActive = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'monthlyPrice': monthlyPrice,
      'yearlyPrice': yearlyPrice,
      'maxEmployees': maxEmployees,
      'maxWorkplaces': maxWorkplaces,
      'maxBonuses': maxBonuses,
      'features': features,
      'isActive': isActive,
    };
  }

  factory SubscriptionTier.fromJson(Map<String, dynamic> json) {
    return SubscriptionTier(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      monthlyPrice: (json['monthlyPrice'] as num).toDouble(),
      yearlyPrice: json['yearlyPrice'] != null 
          ? (json['yearlyPrice'] as num).toDouble() 
          : null,
      maxEmployees: json['maxEmployees'] as int,
      maxWorkplaces: json['maxWorkplaces'] as int,
      maxBonuses: json['maxBonuses'] as int,
      features: List<String>.from(json['features'] as List? ?? []),
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  SubscriptionTier copyWith({
    String? id,
    String? name,
    String? description,
    double? monthlyPrice,
    double? yearlyPrice,
    int? maxEmployees,
    int? maxWorkplaces,
    int? maxBonuses,
    List<String>? features,
    bool? isActive,
  }) {
    return SubscriptionTier(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      monthlyPrice: monthlyPrice ?? this.monthlyPrice,
      yearlyPrice: yearlyPrice ?? this.yearlyPrice,
      maxEmployees: maxEmployees ?? this.maxEmployees,
      maxWorkplaces: maxWorkplaces ?? this.maxWorkplaces,
      maxBonuses: maxBonuses ?? this.maxBonuses,
      features: features ?? this.features,
      isActive: isActive ?? this.isActive,
    );
  }

  // Default tier definitions
  static SubscriptionTier get free => const SubscriptionTier(
        id: 'tier_free',
        name: 'Free Trial',
        description: 'Perfect for testing the platform',
        monthlyPrice: 0,
        yearlyPrice: 0,
        maxEmployees: 5,
        maxWorkplaces: 1,
        maxBonuses: 10,
        features: [
          'Up to 5 employees',
          '1 workplace',
          '10 bonuses',
          'Basic analytics',
          '14-day trial',
        ],
      );

  static SubscriptionTier get starter => const SubscriptionTier(
        id: 'tier_starter',
        name: 'Starter',
        description: 'Great for small teams',
        monthlyPrice: 29,
        yearlyPrice: 290, // ~17% discount
        maxEmployees: 10,
        maxWorkplaces: 2,
        maxBonuses: 50,
        features: [
          'Up to 10 employees',
          '2 workplaces',
          '50 bonuses',
          'Basic analytics',
          'Email support',
        ],
      );

  static SubscriptionTier get professional => const SubscriptionTier(
        id: 'tier_professional',
        name: 'Professional',
        description: 'For growing businesses',
        monthlyPrice: 99,
        yearlyPrice: 990, // ~17% discount
        maxEmployees: 50,
        maxWorkplaces: 10,
        maxBonuses: -1, // -1 means unlimited
        features: [
          'Up to 50 employees',
          '10 workplaces',
          'Unlimited bonuses',
          'Advanced analytics',
          'Priority support',
          'Custom points rules',
        ],
      );

  static SubscriptionTier get enterprise => const SubscriptionTier(
        id: 'tier_enterprise',
        name: 'Enterprise',
        description: 'For large organizations',
        monthlyPrice: 299,
        yearlyPrice: 2990, // ~17% discount
        maxEmployees: -1, // unlimited
        maxWorkplaces: -1, // unlimited
        maxBonuses: -1, // unlimited
        features: [
          'Unlimited employees',
          'Unlimited workplaces',
          'Unlimited bonuses',
          'Advanced analytics',
          'Dedicated support',
          'Custom points rules',
          'API access',
          'White-label options',
          'Custom integrations',
        ],
      );

  static List<SubscriptionTier> get defaultTiers => [
        free,
        starter,
        professional,
        enterprise,
      ];
}

