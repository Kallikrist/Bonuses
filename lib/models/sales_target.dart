enum TargetStatus {
  pending,
  met,
  missed,
  submitted,
  approved,
}

class SalesTarget {
  final String id;
  final DateTime date;
  final double targetAmount;
  final double actualAmount;
  final bool isMet;
  final TargetStatus status;
  final double percentageAboveTarget;
  final int pointsAwarded;
  final DateTime createdAt;
  final String createdBy; // Admin ID who set the target
  final String? assignedEmployeeId; // Employee ID assigned to this target
  final String? assignedEmployeeName; // Employee name for display
  final String? assignedWorkplaceId; // Workplace ID assigned to this target
  final String? assignedWorkplaceName; // Workplace name for display
  final List<String>
      collaborativeEmployeeIds; // Employee IDs who worked on this target
  final List<String> collaborativeEmployeeNames; // Employee names for display
  final bool isSubmitted; // Whether employee has submitted their sales
  final bool isApproved; // Whether admin has approved the submission
  final String? approvedBy; // Admin ID who approved
  final DateTime? approvedAt; // When it was approved
  final String? companyId; // Company context for this target (from workplace)

  SalesTarget({
    required this.id,
    required this.date,
    required this.targetAmount,
    this.actualAmount = 0.0,
    this.isMet = false,
    this.status = TargetStatus.pending,
    this.percentageAboveTarget = 0.0,
    this.pointsAwarded = 0,
    required this.createdAt,
    required this.createdBy,
    this.assignedEmployeeId,
    this.assignedEmployeeName,
    this.assignedWorkplaceId,
    this.assignedWorkplaceName,
    this.collaborativeEmployeeIds = const [],
    this.collaborativeEmployeeNames = const [],
    this.isSubmitted = false,
    this.isApproved = false,
    this.companyId,
    this.approvedBy,
    this.approvedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'targetAmount': targetAmount,
      'actualAmount': actualAmount,
      'isMet': isMet,
      'status': status.name,
      'percentageAboveTarget': percentageAboveTarget,
      'pointsAwarded': pointsAwarded,
      'createdAt': createdAt.toIso8601String(),
      'createdBy': createdBy,
      'assignedEmployeeId': assignedEmployeeId,
      'assignedEmployeeName': assignedEmployeeName,
      'assignedWorkplaceId': assignedWorkplaceId,
      'assignedWorkplaceName': assignedWorkplaceName,
      'collaborativeEmployeeIds': collaborativeEmployeeIds,
      'collaborativeEmployeeNames': collaborativeEmployeeNames,
      'isSubmitted': isSubmitted,
      'isApproved': isApproved,
      'approvedBy': approvedBy,
      'approvedAt': approvedAt?.toIso8601String(),
      'companyId': companyId,
    };
  }

  factory SalesTarget.fromJson(Map<String, dynamic> json) {
    return SalesTarget(
      id: json['id'],
      date: DateTime.parse(json['date']),
      targetAmount: json['targetAmount'].toDouble(),
      actualAmount: json['actualAmount']?.toDouble() ?? 0.0,
      isMet: json['isMet'] ?? false,
      status: json['status'] != null
          ? TargetStatus.values.firstWhere((e) => e.name == json['status'])
          : TargetStatus.pending,
      percentageAboveTarget: json['percentageAboveTarget']?.toDouble() ?? 0.0,
      pointsAwarded: json['pointsAwarded'] ?? 0,
      createdAt: DateTime.parse(json['createdAt']),
      createdBy: json['createdBy'],
      assignedEmployeeId: json['assignedEmployeeId'],
      assignedEmployeeName: json['assignedEmployeeName'],
      assignedWorkplaceId: json['assignedWorkplaceId'],
      assignedWorkplaceName: json['assignedWorkplaceName'],
      collaborativeEmployeeIds:
          List<String>.from(json['collaborativeEmployeeIds'] ?? []),
      collaborativeEmployeeNames:
          List<String>.from(json['collaborativeEmployeeNames'] ?? []),
      isSubmitted: json['isSubmitted'] ?? false,
      isApproved: json['isApproved'] ?? false,
      approvedBy: json['approvedBy'],
      approvedAt: json['approvedAt'] != null
          ? DateTime.parse(json['approvedAt'])
          : null,
      companyId: json['companyId'],
    );
  }

  SalesTarget copyWith({
    String? id,
    DateTime? date,
    double? targetAmount,
    double? actualAmount,
    bool? isMet,
    TargetStatus? status,
    double? percentageAboveTarget,
    int? pointsAwarded,
    DateTime? createdAt,
    String? createdBy,
    String? assignedEmployeeId,
    String? assignedEmployeeName,
    String? assignedWorkplaceId,
    String? assignedWorkplaceName,
    List<String>? collaborativeEmployeeIds,
    List<String>? collaborativeEmployeeNames,
    bool? isSubmitted,
    bool? isApproved,
    String? approvedBy,
    DateTime? approvedAt,
    String? companyId,
  }) {
    return SalesTarget(
      id: id ?? this.id,
      date: date ?? this.date,
      targetAmount: targetAmount ?? this.targetAmount,
      actualAmount: actualAmount ?? this.actualAmount,
      isMet: isMet ?? this.isMet,
      status: status ?? this.status,
      percentageAboveTarget:
          percentageAboveTarget ?? this.percentageAboveTarget,
      pointsAwarded: pointsAwarded ?? this.pointsAwarded,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      assignedEmployeeId: assignedEmployeeId ?? this.assignedEmployeeId,
      assignedEmployeeName: assignedEmployeeName ?? this.assignedEmployeeName,
      assignedWorkplaceId: assignedWorkplaceId ?? this.assignedWorkplaceId,
      assignedWorkplaceName:
          assignedWorkplaceName ?? this.assignedWorkplaceName,
      collaborativeEmployeeIds: collaborativeEmployeeIds != null
          ? List<String>.from(collaborativeEmployeeIds)
          : this.collaborativeEmployeeIds,
      collaborativeEmployeeNames: collaborativeEmployeeNames != null
          ? List<String>.from(collaborativeEmployeeNames)
          : this.collaborativeEmployeeNames,
      isSubmitted: isSubmitted ?? this.isSubmitted,
      isApproved: isApproved ?? this.isApproved,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedAt: approvedAt ?? this.approvedAt,
      companyId: companyId ?? this.companyId,
    );
  }

  // Calculate if target is met and points to award
  SalesTarget calculateResults() {
    final isTargetMet = actualAmount >= targetAmount;
    final percentageAbove = isTargetMet
        ? ((actualAmount - targetAmount) / targetAmount) * 100
        : 0.0;

    // Use the new points calculation logic from AppProvider
    // This will be overridden by AppProvider when it calls _getPointsForEffectivePercent
    final points = 0; // Will be calculated by AppProvider

    // Determine status based on target completion
    final newStatus = isTargetMet ? TargetStatus.met : TargetStatus.missed;

    return copyWith(
      isMet: isTargetMet,
      status: newStatus,
      percentageAboveTarget: percentageAbove,
      pointsAwarded: points,
    );
  }
}
