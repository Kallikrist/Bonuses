enum PointsTransactionType {
  earned,
  redeemed,
  bonus,
  adjustment,
}

class PointsTransaction {
  final String id;
  final String userId;
  final PointsTransactionType type;
  final int points;
  final String description;
  final DateTime date;
  final String? relatedTargetId; // For earned points, link to sales target
  final String? companyId; // Company context for this transaction

  PointsTransaction({
    required this.id,
    required this.userId,
    required this.type,
    required this.points,
    required this.description,
    required this.date,
    this.relatedTargetId,
    this.companyId,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'type': type.name,
      'points': points,
      'description': description,
      'date': date.toIso8601String(),
      'relatedTargetId': relatedTargetId,
      'companyId': companyId,
    };
  }

  factory PointsTransaction.fromJson(Map<String, dynamic> json) {
    return PointsTransaction(
      id: json['id'],
      userId: json['userId'],
      type: PointsTransactionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => PointsTransactionType.earned,
      ),
      points: json['points'],
      description: json['description'],
      date: DateTime.parse(json['date']),
      relatedTargetId: json['relatedTargetId'],
      companyId: json['companyId'],
    );
  }

  PointsTransaction copyWith({
    String? id,
    String? userId,
    PointsTransactionType? type,
    int? points,
    String? description,
    DateTime? date,
    String? relatedTargetId,
    String? companyId,
  }) {
    return PointsTransaction(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      points: points ?? this.points,
      description: description ?? this.description,
      date: date ?? this.date,
      relatedTargetId: relatedTargetId ?? this.relatedTargetId,
      companyId: companyId ?? this.companyId,
    );
  }
}
