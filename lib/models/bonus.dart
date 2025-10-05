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
      'name': name,
      'description': description,
      'pointsRequired': pointsRequired,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'redeemedAt': redeemedAt?.toIso8601String(),
      'redeemedBy': redeemedBy,
      'giftCardCode': giftCardCode,
      'secretCode': secretCode,
      'companyId': companyId,
    };
  }

  factory Bonus.fromJson(Map<String, dynamic> json) {
    return Bonus(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      pointsRequired: json['pointsRequired'],
      status: BonusStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => BonusStatus.available,
      ),
      createdAt: DateTime.parse(json['createdAt']),
      redeemedAt: json['redeemedAt'] != null
          ? DateTime.parse(json['redeemedAt'])
          : null,
      redeemedBy: json['redeemedBy'],
      giftCardCode: json['giftCardCode'],
      secretCode: json['secretCode'],
      companyId: json['companyId'],
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
