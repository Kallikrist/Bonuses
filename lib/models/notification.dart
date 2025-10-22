enum NotificationType {
  message,
  targetAssignment,
  targetApproval,
  targetRejection,
  pointsAwarded,
  pointsGift,
  bonusRedeemed,
  teamInvite,
  salesSubmitted,
  targetCompleted,
  companyUpdate,
}

class AppNotification {
  final String id;
  final String userId;
  final String companyId;
  final NotificationType type;
  final String title;
  final String message;
  final DateTime createdAt;
  final bool isRead;
  final String? relatedId; // ID of related message, target, etc.
  final Map<String, dynamic>? metadata; // Additional data

  AppNotification({
    required this.id,
    required this.userId,
    required this.companyId,
    required this.type,
    required this.title,
    required this.message,
    required this.createdAt,
    this.isRead = false,
    this.relatedId,
    this.metadata,
  });

  AppNotification copyWith({
    String? id,
    String? userId,
    String? companyId,
    NotificationType? type,
    String? title,
    String? message,
    DateTime? createdAt,
    bool? isRead,
    String? relatedId,
    Map<String, dynamic>? metadata,
  }) {
    return AppNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      companyId: companyId ?? this.companyId,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      relatedId: relatedId ?? this.relatedId,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'companyId': companyId,
      'type': type.toString().split('.').last,
      'title': title,
      'message': message,
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead,
      'relatedId': relatedId,
      'metadata': metadata,
    };
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      userId: json['userId'] as String,
      companyId: json['companyId'] as String,
      type: NotificationType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
      ),
      title: json['title'] as String,
      message: json['message'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isRead: json['isRead'] as bool? ?? false,
      relatedId: json['relatedId'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  // Helper method to determine if notification is time-sensitive
  bool get isUrgent {
    switch (type) {
      case NotificationType.targetAssignment:
      case NotificationType.targetApproval:
      case NotificationType.targetRejection:
      case NotificationType.teamInvite:
        return true;
      default:
        return false;
    }
  }

  // Helper method to get notification age in hours
  int get ageInHours {
    return DateTime.now().difference(createdAt).inHours;
  }

  // Helper method to check if notification is recent (less than 24 hours old)
  bool get isRecent {
    return ageInHours < 24;
  }

  // Helper method to get a user-friendly time string
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return '$minutes ${minutes == 1 ? 'minute' : 'minutes'} ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '$hours ${hours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return '$days ${days == 1 ? 'day' : 'days'} ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is AppNotification &&
        other.id == id &&
        other.userId == userId &&
        other.companyId == companyId &&
        other.type == type &&
        other.title == title &&
        other.message == message &&
        other.createdAt == createdAt &&
        other.isRead == isRead &&
        other.relatedId == relatedId;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        userId.hashCode ^
        companyId.hashCode ^
        type.hashCode ^
        title.hashCode ^
        message.hashCode ^
        createdAt.hashCode ^
        isRead.hashCode ^
        relatedId.hashCode;
  }
}

