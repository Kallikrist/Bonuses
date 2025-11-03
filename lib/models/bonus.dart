enum BonusStatus {
  available,
  redeemed,
  expired,
}

class Bonus {
  final String id;
  final String name;
  final String description;
  final int pointsRequired;
  final BonusStatus status;
  final DateTime createdAt;
  final DateTime? redeemedAt;
  final String? redeemedBy;
  final String? giftCardCode;
  final String? secretCode;
  final String? companyId;

  Bonus({
    required this.id,
    required this.name,
    required this.description,
    required this.pointsRequired,
    this.status = BonusStatus.available,
    required this.createdAt,
    this.redeemedAt,
    this.redeemedBy,
    this.giftCardCode,
    this.secretCode,
    this.companyId,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': name,  // Map 'name' to 'title' for Supabase
      'description': description,
      'points_required': pointsRequired,  // Keep as int, Supabase will handle conversion
      'status': status.name,
      'created_at': createdAt.toIso8601String(),
      'redeemed_at': redeemedAt?.toIso8601String(),
      'redeemed_by': redeemedBy,
      'gift_card_code': giftCardCode,
      'secret_code': secretCode,
      'company_id': companyId,
    };
  }

  factory Bonus.fromJson(Map<String, dynamic> json) {
    return Bonus(
      id: json['id'],
      name: json['name'] ?? json['title'],  // Handle both 'name' and 'title'
      description: json['description'],
      pointsRequired: (json['pointsRequired'] ?? json['points_required'])?.toInt() ?? 0,
      status: BonusStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => BonusStatus.available,
      ),
      createdAt: DateTime.parse(json['createdAt'] ?? json['created_at']),
      redeemedAt: (json['redeemedAt'] ?? json['redeemed_at']) != null
          ? DateTime.parse(json['redeemedAt'] ?? json['redeemed_at'])
          : null,
      redeemedBy: json['redeemedBy'] ?? json['redeemed_by'],
      giftCardCode: json['giftCardCode'] ?? json['gift_card_code'],
      secretCode: json['secretCode'] ?? json['secret_code'],
      companyId: json['companyId'] ?? json['company_id'],
    );
  }

  Bonus copyWith({
    String? id,
    String? name,
    String? description,
    int? pointsRequired,
    BonusStatus? status,
    DateTime? createdAt,
    DateTime? redeemedAt,
    String? redeemedBy,
    String? giftCardCode,
    String? secretCode,
    String? companyId,
  }) {
    return Bonus(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      pointsRequired: pointsRequired ?? this.pointsRequired,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      redeemedAt: redeemedAt ?? this.redeemedAt,
      redeemedBy: redeemedBy ?? this.redeemedBy,
      giftCardCode: giftCardCode ?? this.giftCardCode,
      secretCode: secretCode ?? this.secretCode,
      companyId: companyId ?? this.companyId,
    );
  }
}
