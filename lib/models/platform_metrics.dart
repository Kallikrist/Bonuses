/// Revenue data for a specific month
class RevenueByMonth {
  final int year;
  final int month;
  final double revenue;
  final int paymentCount;

  RevenueByMonth({
    required this.year,
    required this.month,
    required this.revenue,
    required this.paymentCount,
  });

  Map<String, dynamic> toJson() {
    return {
      'year': year,
      'month': month,
      'revenue': revenue,
      'paymentCount': paymentCount,
    };
  }

  factory RevenueByMonth.fromJson(Map<String, dynamic> json) {
    return RevenueByMonth(
      year: json['year'] as int,
      month: json['month'] as int,
      revenue: (json['revenue'] as num).toDouble(),
      paymentCount: json['paymentCount'] as int,
    );
  }

  String get monthName {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }
}

/// Platform-wide metrics for super admin dashboard
class PlatformMetrics {
  final int totalCompanies;
  final int activeCompanies; // Companies with active subscriptions
  final int trialCompanies; // Companies in trial period
  final int suspendedCompanies; // Companies with suspended subscriptions
  final int totalEmployees; // Total employees across all companies
  final int totalAdmins; // Total company admins
  final double monthlyRecurringRevenue; // MRR
  final double totalRevenue; // All-time revenue
  final Map<String, int> companiesByTier; // {tierId: count}
  final List<RevenueByMonth> revenueHistory; // Last 12 months
  final DateTime calculatedAt;
  
  // Additional useful metrics
  final int newCompaniesThisMonth;
  final int churnedCompaniesThisMonth;
  final double averageRevenuePerCompany;
  final int totalTargetsCreated; // Platform-wide
  final int totalBonusesRedeemed; // Platform-wide
  final int totalPointsAwarded; // Platform-wide

  PlatformMetrics({
    required this.totalCompanies,
    required this.activeCompanies,
    required this.trialCompanies,
    required this.suspendedCompanies,
    required this.totalEmployees,
    required this.totalAdmins,
    required this.monthlyRecurringRevenue,
    required this.totalRevenue,
    required this.companiesByTier,
    required this.revenueHistory,
    required this.calculatedAt,
    required this.newCompaniesThisMonth,
    required this.churnedCompaniesThisMonth,
    required this.averageRevenuePerCompany,
    required this.totalTargetsCreated,
    required this.totalBonusesRedeemed,
    required this.totalPointsAwarded,
  });

  Map<String, dynamic> toJson() {
    return {
      'totalCompanies': totalCompanies,
      'activeCompanies': activeCompanies,
      'trialCompanies': trialCompanies,
      'suspendedCompanies': suspendedCompanies,
      'totalEmployees': totalEmployees,
      'totalAdmins': totalAdmins,
      'monthlyRecurringRevenue': monthlyRecurringRevenue,
      'totalRevenue': totalRevenue,
      'companiesByTier': companiesByTier,
      'revenueHistory': revenueHistory.map((r) => r.toJson()).toList(),
      'calculatedAt': calculatedAt.toIso8601String(),
      'newCompaniesThisMonth': newCompaniesThisMonth,
      'churnedCompaniesThisMonth': churnedCompaniesThisMonth,
      'averageRevenuePerCompany': averageRevenuePerCompany,
      'totalTargetsCreated': totalTargetsCreated,
      'totalBonusesRedeemed': totalBonusesRedeemed,
      'totalPointsAwarded': totalPointsAwarded,
    };
  }

  factory PlatformMetrics.fromJson(Map<String, dynamic> json) {
    return PlatformMetrics(
      totalCompanies: json['totalCompanies'] as int,
      activeCompanies: json['activeCompanies'] as int,
      trialCompanies: json['trialCompanies'] as int,
      suspendedCompanies: json['suspendedCompanies'] as int,
      totalEmployees: json['totalEmployees'] as int,
      totalAdmins: json['totalAdmins'] as int,
      monthlyRecurringRevenue: (json['monthlyRecurringRevenue'] as num).toDouble(),
      totalRevenue: (json['totalRevenue'] as num).toDouble(),
      companiesByTier: Map<String, int>.from(json['companiesByTier'] as Map),
      revenueHistory: (json['revenueHistory'] as List)
          .map((r) => RevenueByMonth.fromJson(r as Map<String, dynamic>))
          .toList(),
      calculatedAt: DateTime.parse(json['calculatedAt'] as String),
      newCompaniesThisMonth: json['newCompaniesThisMonth'] as int,
      churnedCompaniesThisMonth: json['churnedCompaniesThisMonth'] as int,
      averageRevenuePerCompany: (json['averageRevenuePerCompany'] as num).toDouble(),
      totalTargetsCreated: json['totalTargetsCreated'] as int,
      totalBonusesRedeemed: json['totalBonusesRedeemed'] as int,
      totalPointsAwarded: json['totalPointsAwarded'] as int,
    );
  }

  /// Calculate churn rate (%)
  double get churnRate {
    if (totalCompanies == 0) return 0.0;
    return (churnedCompaniesThisMonth / totalCompanies) * 100;
  }

  /// Calculate growth rate (%)
  double get growthRate {
    if (totalCompanies == 0) return 0.0;
    return (newCompaniesThisMonth / totalCompanies) * 100;
  }

  /// Calculate conversion rate (trial to paid)
  double get conversionRate {
    final paidCompanies = activeCompanies - trialCompanies;
    if (totalCompanies == 0) return 0.0;
    return (paidCompanies / totalCompanies) * 100;
  }
}

