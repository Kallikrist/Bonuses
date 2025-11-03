// Helper class to distinguish between null and undefined in copyWith
class _Undefined {
  const _Undefined();
}

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
  final DateTime? deletedAt; // When the target was deleted (soft delete)
  final String? deletedBy; // Admin ID who deleted the target

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
    this.deletedAt,
    this.deletedBy,
  });

  Map<String, dynamic> toJson() {
    // Use snake_case keys for Supabase compatibility. The database columns
    // are expected to be snake_case (e.g. target_amount, created_at, etc.).
    return {
      'id': id,
      'date': date.toIso8601String(),
      'target_amount': targetAmount,
      'actual_amount': actualAmount,
      'is_met': isMet,
      'status': status.name,
      'percentage_above_target': percentageAboveTarget,
      'points_awarded': pointsAwarded,
      'created_at': createdAt.toIso8601String(),
      'created_by': createdBy,
      'assigned_employee_id': assignedEmployeeId,
      'assigned_employee_name': assignedEmployeeName,
      'assigned_workplace_id': assignedWorkplaceId,
      'assigned_workplace_name': assignedWorkplaceName,
      'collaborative_employee_ids': collaborativeEmployeeIds,
      'collaborative_employee_names': collaborativeEmployeeNames,
      'is_submitted': isSubmitted,
      'is_approved': isApproved,
      'approved_by': approvedBy,
      'approved_at': approvedAt?.toIso8601String(),
      'company_id': companyId,
      'deleted_at': deletedAt?.toIso8601String(),
      'deleted_by': deletedBy,
    };
  }

  factory SalesTarget.fromJson(Map<String, dynamic> json) {
    // Accept both camelCase (local storage) and snake_case (Supabase)
    double _toDouble(dynamic v) => v == null
        ? 0.0
        : (v is int)
            ? v.toDouble()
            : (v as num).toDouble();

    return SalesTarget(
      id: json['id'],
      date: DateTime.parse(json['date']),
      targetAmount: _toDouble(json['targetAmount'] ?? json['target_amount']),
      actualAmount: _toDouble(json['actualAmount'] ?? json['actual_amount']),
      isMet: (json['isMet'] ?? json['is_met']) ?? false,
      status: (json['status'] != null)
          ? TargetStatus.values.firstWhere((e) => e.name == json['status'])
          : TargetStatus.pending,
      percentageAboveTarget: _toDouble(
          json['percentageAboveTarget'] ?? json['percentage_above_target']),
      pointsAwarded: (json['pointsAwarded'] ?? json['points_awarded']) ?? 0,
      createdAt: DateTime.parse(json['createdAt'] ?? json['created_at']),
      createdBy: json['createdBy'] ?? json['created_by'],
      assignedEmployeeId:
          json['assignedEmployeeId'] ?? json['assigned_employee_id'],
      assignedEmployeeName:
          json['assignedEmployeeName'] ?? json['assigned_employee_name'],
      assignedWorkplaceId:
          json['assignedWorkplaceId'] ?? json['assigned_workplace_id'],
      assignedWorkplaceName:
          json['assignedWorkplaceName'] ?? json['assigned_workplace_name'],
      collaborativeEmployeeIds: List<String>.from(
          json['collaborativeEmployeeIds'] ??
              json['collaborative_employee_ids'] ??
              []),
      collaborativeEmployeeNames: List<String>.from(
          json['collaborativeEmployeeNames'] ??
              json['collaborative_employee_names'] ??
              []),
      isSubmitted: (json['isSubmitted'] ?? json['is_submitted']) ?? false,
      isApproved: (json['isApproved'] ?? json['is_approved']) ?? false,
      approvedBy: json['approvedBy'] ?? json['approved_by'],
      approvedAt: (json['approvedAt'] ?? json['approved_at']) != null
          ? DateTime.parse(json['approvedAt'] ?? json['approved_at'])
          : null,
      companyId: json['companyId'] ?? json['company_id'],
      deletedAt: (json['deletedAt'] ?? json['deleted_at']) != null
          ? DateTime.parse(json['deletedAt'] ?? json['deleted_at'])
          : null,
      deletedBy: json['deletedBy'] ?? json['deleted_by'],
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
    Object? assignedEmployeeId = const _Undefined(),
    Object? assignedEmployeeName = const _Undefined(),
    Object? assignedWorkplaceId = const _Undefined(),
    Object? assignedWorkplaceName = const _Undefined(),
    List<String>? collaborativeEmployeeIds,
    List<String>? collaborativeEmployeeNames,
    bool? isSubmitted,
    bool? isApproved,
    String? approvedBy,
    DateTime? approvedAt,
    Object? companyId = const _Undefined(),
    DateTime? deletedAt,
    String? deletedBy,
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
      assignedEmployeeId: assignedEmployeeId is _Undefined
          ? this.assignedEmployeeId
          : assignedEmployeeId as String?,
      assignedEmployeeName: assignedEmployeeName is _Undefined
          ? this.assignedEmployeeName
          : assignedEmployeeName as String?,
      assignedWorkplaceId: assignedWorkplaceId is _Undefined
          ? this.assignedWorkplaceId
          : assignedWorkplaceId as String?,
      assignedWorkplaceName: assignedWorkplaceName is _Undefined
          ? this.assignedWorkplaceName
          : assignedWorkplaceName as String?,
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
      companyId:
          companyId is _Undefined ? this.companyId : companyId as String?,
      deletedAt: deletedAt ?? this.deletedAt,
      deletedBy: deletedBy ?? this.deletedBy,
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
    const points = 0; // Will be calculated by AppProvider

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
