import '../models/notification.dart';
import '../models/user.dart';
import '../models/sales_target.dart';
import '../models/message.dart';
import 'storage_service.dart';

class NotificationService {
  // Create notification when a new message is received
  static Future<void> notifyNewMessage({
    required Message message,
    required String recipientId,
    required String senderName,
  }) async {
    final notification = AppNotification(
      id: 'notif_${DateTime.now().millisecondsSinceEpoch}_${recipientId}',
      userId: recipientId,
      companyId: message.companyId ?? 'unknown',
      type: NotificationType.message,
      title: 'New Message',
      message: 'You have a new message from $senderName',
      createdAt: DateTime.now(),
      relatedId: message.id,
      metadata: {
        'senderId': message.senderId,
        'senderName': senderName,
      },
    );

    await StorageService.addNotification(notification);
  }

  // Create notification when assigned to a target
  static Future<void> notifyTargetAssignment({
    required SalesTarget target,
    required String employeeId,
    required String employeeName,
    required String assignedBy,
  }) async {
    final notification = AppNotification(
      id: 'notif_${DateTime.now().millisecondsSinceEpoch}_target_${employeeId}',
      userId: employeeId,
      companyId: target.companyId ?? 'unknown',
      type: NotificationType.targetAssignment,
      title: 'New Target Assignment',
      message:
          'You have been assigned to a target of \$${target.targetAmount.toStringAsFixed(0)} for ${target.assignedWorkplaceName}',
      createdAt: DateTime.now(),
      relatedId: target.id,
      metadata: {
        'targetAmount': target.targetAmount,
        'workplaceName': target.assignedWorkplaceName,
        'assignedBy': assignedBy,
        'targetDate': target.date.toIso8601String(),
      },
    );

    await StorageService.addNotification(notification);
  }

  // Create notification when sales submission is approved
  static Future<void> notifyTargetApproval({
    required SalesTarget target,
    required String employeeId,
    required int pointsAwarded,
  }) async {
    final notification = AppNotification(
      id: 'notif_${DateTime.now().millisecondsSinceEpoch}_approved_$employeeId',
      userId: employeeId,
      companyId: target.companyId ?? 'unknown',
      type: NotificationType.targetApproval,
      title: 'Sales Approved!',
      message:
          'Your sales of \$${target.actualAmount.toStringAsFixed(0)} have been approved. You earned $pointsAwarded points!',
      createdAt: DateTime.now(),
      relatedId: target.id,
      metadata: {
        'targetId': target.id,
        'actualAmount': target.actualAmount,
        'pointsAwarded': pointsAwarded,
        'targetDate': target.date.toIso8601String(),
      },
    );

    await StorageService.addNotification(notification);
  }

  // Create notification when sales submission is rejected
  static Future<void> notifyTargetRejection({
    required SalesTarget target,
    required String employeeId,
    String? reason,
  }) async {
    final notification = AppNotification(
      id: 'notif_${DateTime.now().millisecondsSinceEpoch}_rejected_$employeeId',
      userId: employeeId,
      companyId: target.companyId ?? 'unknown',
      type: NotificationType.targetRejection,
      title: 'Sales Submission Needs Review',
      message: reason != null && reason.isNotEmpty
          ? 'Your sales submission requires revision: $reason'
          : 'Your sales submission requires revision. Please check with your admin.',
      createdAt: DateTime.now(),
      relatedId: target.id,
      metadata: {
        'targetId': target.id,
        'reason': reason,
        'targetDate': target.date.toIso8601String(),
      },
    );

    await StorageService.addNotification(notification);
  }

  // Create notification when points are awarded
  static Future<void> notifyPointsAwarded({
    required String userId,
    required String companyId,
    required int points,
    required String reason,
    String? relatedId,
  }) async {
    final notification = AppNotification(
      id: 'notif_${DateTime.now().millisecondsSinceEpoch}_points_$userId',
      userId: userId,
      companyId: companyId,
      type: NotificationType.pointsAwarded,
      title: 'Points Earned!',
      message: 'You earned $points points! $reason',
      createdAt: DateTime.now(),
      relatedId: relatedId,
      metadata: {
        'points': points,
        'reason': reason,
      },
    );

    await StorageService.addNotification(notification);
  }

  // Create notification when receiving a points gift
  static Future<void> notifyPointsGift({
    required String recipientId,
    required String companyId,
    required int points,
    required String senderName,
    String? message,
  }) async {
    final notification = AppNotification(
      id: 'notif_${DateTime.now().millisecondsSinceEpoch}_gift_$recipientId',
      userId: recipientId,
      companyId: companyId,
      type: NotificationType.pointsGift,
      title: 'Points Gift Received!',
      message: message != null && message.isNotEmpty
          ? '$senderName sent you $points points: "$message"'
          : '$senderName sent you $points points!',
      createdAt: DateTime.now(),
      metadata: {
        'points': points,
        'senderName': senderName,
        'giftMessage': message,
      },
    );

    await StorageService.addNotification(notification);
  }

  // Create notification when a bonus is redeemed
  static Future<void> notifyBonusRedeemed({
    required String userId,
    required String companyId,
    required String bonusName,
    required int pointsCost,
    String? bonusId,
  }) async {
    final notification = AppNotification(
      id: 'notif_${DateTime.now().millisecondsSinceEpoch}_bonus_$userId',
      userId: userId,
      companyId: companyId,
      type: NotificationType.bonusRedeemed,
      title: 'Bonus Redeemed!',
      message: 'You successfully redeemed "$bonusName" for $pointsCost points',
      createdAt: DateTime.now(),
      relatedId: bonusId,
      metadata: {
        'bonusName': bonusName,
        'pointsCost': pointsCost,
      },
    );

    await StorageService.addNotification(notification);
  }

  // Create notification for team invite
  static Future<void> notifyTeamInvite({
    required SalesTarget target,
    required String invitedEmployeeId,
    required String invitedByName,
  }) async {
    final notification = AppNotification(
      id: 'notif_${DateTime.now().millisecondsSinceEpoch}_invite_$invitedEmployeeId',
      userId: invitedEmployeeId,
      companyId: target.companyId ?? 'unknown',
      type: NotificationType.teamInvite,
      title: 'Team Invite',
      message:
          '$invitedByName invited you to join a target of \$${target.targetAmount.toStringAsFixed(0)}',
      createdAt: DateTime.now(),
      relatedId: target.id,
      metadata: {
        'targetId': target.id,
        'targetAmount': target.targetAmount,
        'invitedByName': invitedByName,
        'targetDate': target.date.toIso8601String(),
      },
    );

    await StorageService.addNotification(notification);
  }

  // Create notification when sales are submitted
  static Future<void> notifySalesSubmitted({
    required SalesTarget target,
    required String adminId,
    required String employeeName,
  }) async {
    final notification = AppNotification(
      id: 'notif_${DateTime.now().millisecondsSinceEpoch}_submitted_$adminId',
      userId: adminId,
      companyId: target.companyId ?? 'unknown',
      type: NotificationType.salesSubmitted,
      title: 'Sales Submission Pending',
      message:
          '$employeeName submitted sales of \$${target.actualAmount.toStringAsFixed(0)} for review',
      createdAt: DateTime.now(),
      relatedId: target.id,
      metadata: {
        'targetId': target.id,
        'employeeName': employeeName,
        'actualAmount': target.actualAmount,
        'targetDate': target.date.toIso8601String(),
      },
    );

    await StorageService.addNotification(notification);
  }

  // Create notification when target is completed
  static Future<void> notifyTargetCompleted({
    required SalesTarget target,
    required List<String> teamMemberIds,
  }) async {
    for (final memberId in teamMemberIds) {
      final notification = AppNotification(
        id: 'notif_${DateTime.now().millisecondsSinceEpoch}_completed_$memberId',
        userId: memberId,
        companyId: target.companyId ?? 'unknown',
        type: NotificationType.targetCompleted,
        title: 'Target Completed!',
        message:
            'Congratulations! Your team completed the target of \$${target.targetAmount.toStringAsFixed(0)}',
        createdAt: DateTime.now(),
        relatedId: target.id,
        metadata: {
          'targetId': target.id,
          'targetAmount': target.targetAmount,
          'actualAmount': target.actualAmount,
          'achievement': ((target.actualAmount / target.targetAmount) * 100)
              .toStringAsFixed(1),
          'targetDate': target.date.toIso8601String(),
        },
      );

      await StorageService.addNotification(notification);
    }
  }

  // Create notification for company updates
  static Future<void> notifyCompanyUpdate({
    required String companyId,
    required List<String> userIds,
    required String title,
    required String message,
  }) async {
    for (final userId in userIds) {
      final notification = AppNotification(
        id: 'notif_${DateTime.now().millisecondsSinceEpoch}_company_$userId',
        userId: userId,
        companyId: companyId,
        type: NotificationType.companyUpdate,
        title: title,
        message: message,
        createdAt: DateTime.now(),
      );

      await StorageService.addNotification(notification);
    }
  }

  // Batch create notifications for multiple users
  static Future<void> notifyMultipleUsers({
    required List<String> userIds,
    required String companyId,
    required NotificationType type,
    required String title,
    required String message,
    String? relatedId,
    Map<String, dynamic>? metadata,
  }) async {
    for (final userId in userIds) {
      final notification = AppNotification(
        id: 'notif_${DateTime.now().millisecondsSinceEpoch}_$userId',
        userId: userId,
        companyId: companyId,
        type: type,
        title: title,
        message: message,
        createdAt: DateTime.now(),
        relatedId: relatedId,
        metadata: metadata,
      );

      await StorageService.addNotification(notification);
    }
  }

  // Get notification icon based on type
  static String getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.message:
        return '💬';
      case NotificationType.targetAssignment:
        return '🎯';
      case NotificationType.targetApproval:
        return '✅';
      case NotificationType.targetRejection:
        return '❌';
      case NotificationType.pointsAwarded:
        return '⭐';
      case NotificationType.pointsGift:
        return '🎁';
      case NotificationType.bonusRedeemed:
        return '🎉';
      case NotificationType.teamInvite:
        return '👥';
      case NotificationType.salesSubmitted:
        return '📊';
      case NotificationType.targetCompleted:
        return '🏆';
      case NotificationType.companyUpdate:
        return '📢';
    }
  }

  // Clean up old notifications (call this periodically)
  static Future<void> cleanupOldNotifications({int daysToKeep = 30}) async {
    await StorageService.deleteOldNotifications(daysToKeep: daysToKeep);
  }
}
