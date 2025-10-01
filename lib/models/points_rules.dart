class PointsRuleEntry {
  final double thresholdPercent; // e.g. 100, 110, 200
  final int points; // points when >= thresholdPercent

  const PointsRuleEntry({required this.thresholdPercent, required this.points});

  Map<String, dynamic> toJson() => {
        'thresholdPercent': thresholdPercent,
        'points': points,
      };

  factory PointsRuleEntry.fromJson(Map<String, dynamic> json) =>
      PointsRuleEntry(
        thresholdPercent: (json['thresholdPercent'] as num).toDouble(),
        points: (json['points'] as num).toInt(),
      );
}

class PointsRules {
  // Legacy fixed fields (kept for backward compatibility)
  final int pointsForMet; // exactly met (>= 100% and < 110%)
  final int pointsForTenPercentAbove; // >= 110% and < 200%
  final int pointsForDoubleTarget; // >= 200%

  // Preferred dynamic rules: evaluate by highest matching threshold
  final List<PointsRuleEntry> entries;
  
  // Currency value: how much 1 point is worth in local currency
  final double pointValue; // e.g., 100 ISK per point
  final String currencySymbol; // e.g., "ISK", "kr", "$"

  const PointsRules({
    required this.pointsForMet,
    required this.pointsForTenPercentAbove,
    required this.pointsForDoubleTarget,
    this.entries = const [],
    this.pointValue = 100.0,
    this.currencySymbol = 'ISK',
  });

  factory PointsRules.defaults() => const PointsRules(
        pointsForMet: 10,
        pointsForTenPercentAbove: 20,
        pointsForDoubleTarget: 50,
        entries: [
          PointsRuleEntry(thresholdPercent: 100, points: 10),
          PointsRuleEntry(thresholdPercent: 110, points: 20),
          PointsRuleEntry(thresholdPercent: 200, points: 50),
        ],
      );

  Map<String, dynamic> toJson() => {
        'pointsForMet': pointsForMet,
        'pointsForTenPercentAbove': pointsForTenPercentAbove,
        'pointsForDoubleTarget': pointsForDoubleTarget,
        'entries': entries.map((e) => e.toJson()).toList(),
        'pointValue': pointValue,
        'currencySymbol': currencySymbol,
      };

  factory PointsRules.fromJson(Map<String, dynamic> json) => PointsRules(
        pointsForMet: (json['pointsForMet'] ?? 0) as int,
        pointsForTenPercentAbove:
            (json['pointsForTenPercentAbove'] ?? 10) as int,
        pointsForDoubleTarget: (json['pointsForDoubleTarget'] ?? 50) as int,
        entries: (json['entries'] as List?)
                ?.map(
                    (e) => PointsRuleEntry.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        pointValue: (json['pointValue'] as num?)?.toDouble() ?? 100.0,
        currencySymbol: (json['currencySymbol'] as String?) ?? 'ISK',
      );

  PointsRules copyWith({
    int? pointsForMet,
    int? pointsForTenPercentAbove,
    int? pointsForDoubleTarget,
    List<PointsRuleEntry>? entries,
    double? pointValue,
    String? currencySymbol,
  }) {
    return PointsRules(
      pointsForMet: pointsForMet ?? this.pointsForMet,
      pointsForTenPercentAbove:
          pointsForTenPercentAbove ?? this.pointsForTenPercentAbove,
      pointsForDoubleTarget:
          pointsForDoubleTarget ?? this.pointsForDoubleTarget,
      entries: entries ?? this.entries,
      pointValue: pointValue ?? this.pointValue,
      currencySymbol: currencySymbol ?? this.currencySymbol,
    );
  }
}
