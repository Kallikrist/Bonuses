
enum ApprovalRequestType {
  salesSubmission,
  teamChange,
}

enum ApprovalStatus {
  pending,
  approved,
  rejected,
}

class ApprovalRequest {
  final String id;
  final String targetId;
  final String submittedBy; // Team leader ID
  final String submittedByName; // Team leader name
  final ApprovalRequestType type;
  final ApprovalStatus status;
  final DateTime submittedAt;
  final DateTime? reviewedAt;
  final String? reviewedBy; // Admin ID who reviewed
  final String? reviewedByName; // Admin name who reviewed
  final String? rejectionReason;
  
  // Sales submission data
  final double? newActualAmount;
  final double? previousActualAmount;
  
  // Team change data
  final List<String>? newTeamMemberIds;
  final List<String>? newTeamMemberNames;
  final List<String>? previousTeamMemberIds;
  final List<String>? previousTeamMemberNames;

  ApprovalRequest({
    required this.id,
    required this.targetId,
    required this.submittedBy,
    required this.submittedByName,
    required this.type,
    required this.status,
    required this.submittedAt,
    this.reviewedAt,
    this.reviewedBy,
    this.reviewedByName,
    this.rejectionReason,
    this.newActualAmount,
    this.previousActualAmount,
    this.newTeamMemberIds,
    this.newTeamMemberNames,
    this.previousTeamMemberIds,
    this.previousTeamMemberNames,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'targetId': targetId,
      'submittedBy': submittedBy,
      'submittedByName': submittedByName,
      'type': type.name,
      'status': status.name,
      'submittedAt': submittedAt.toIso8601String(),
      'reviewedAt': reviewedAt?.toIso8601String(),
      'reviewedBy': reviewedBy,
      'reviewedByName': reviewedByName,
      'rejectionReason': rejectionReason,
      'newActualAmount': newActualAmount,
      'previousActualAmount': previousActualAmount,
      'newTeamMemberIds': newTeamMemberIds,
      'newTeamMemberNames': newTeamMemberNames,
      'previousTeamMemberIds': previousTeamMemberIds,
      'previousTeamMemberNames': previousTeamMemberNames,
    };
  }

  factory ApprovalRequest.fromJson(Map<String, dynamic> json) {
    return ApprovalRequest(
      id: json['id'],
      targetId: json['targetId'],
      submittedBy: json['submittedBy'],
      submittedByName: json['submittedByName'],
      type: ApprovalRequestType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ApprovalRequestType.salesSubmission,
      ),
      status: ApprovalStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ApprovalStatus.pending,
      ),
      submittedAt: DateTime.parse(json['submittedAt']),
      reviewedAt: json['reviewedAt'] != null ? DateTime.parse(json['reviewedAt']) : null,
      reviewedBy: json['reviewedBy'],
      reviewedByName: json['reviewedByName'],
      rejectionReason: json['rejectionReason'],
      newActualAmount: json['newActualAmount']?.toDouble(),
      previousActualAmount: json['previousActualAmount']?.toDouble(),
      newTeamMemberIds: json['newTeamMemberIds'] != null ? List<String>.from(json['newTeamMemberIds']) : null,
      newTeamMemberNames: json['newTeamMemberNames'] != null ? List<String>.from(json['newTeamMemberNames']) : null,
      previousTeamMemberIds: json['previousTeamMemberIds'] != null ? List<String>.from(json['previousTeamMemberIds']) : null,
      previousTeamMemberNames: json['previousTeamMemberNames'] != null ? List<String>.from(json['previousTeamMemberNames']) : null,
    );
  }

  ApprovalRequest copyWith({
    String? id,
    String? targetId,
    String? submittedBy,
    String? submittedByName,
    ApprovalRequestType? type,
    ApprovalStatus? status,
    DateTime? submittedAt,
    DateTime? reviewedAt,
    String? reviewedBy,
    String? reviewedByName,
    String? rejectionReason,
    double? newActualAmount,
    double? previousActualAmount,
    List<String>? newTeamMemberIds,
    List<String>? newTeamMemberNames,
    List<String>? previousTeamMemberIds,
    List<String>? previousTeamMemberNames,
  }) {
    return ApprovalRequest(
      id: id ?? this.id,
      targetId: targetId ?? this.targetId,
      submittedBy: submittedBy ?? this.submittedBy,
      submittedByName: submittedByName ?? this.submittedByName,
      type: type ?? this.type,
      status: status ?? this.status,
      submittedAt: submittedAt ?? this.submittedAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewedByName: reviewedByName ?? this.reviewedByName,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      newActualAmount: newActualAmount ?? this.newActualAmount,
      previousActualAmount: previousActualAmount ?? this.previousActualAmount,
      newTeamMemberIds: newTeamMemberIds ?? this.newTeamMemberIds,
      newTeamMemberNames: newTeamMemberNames ?? this.newTeamMemberNames,
      previousTeamMemberIds: previousTeamMemberIds ?? this.previousTeamMemberIds,
      previousTeamMemberNames: previousTeamMemberNames ?? this.previousTeamMemberNames,
    );
  }
}