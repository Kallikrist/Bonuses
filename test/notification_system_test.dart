import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bonuses/services/storage_service.dart';
import 'package:bonuses/services/notification_service.dart';
import 'package:bonuses/models/notification.dart';
import 'package:bonuses/models/user.dart';
import 'package:bonuses/models/sales_target.dart';
import 'package:bonuses/models/message.dart';
import 'package:bonuses/models/company.dart';

void main() {
  group('Notification System Tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    group('Notification Model', () {
      test('Can create a notification', () {
        final notification = AppNotification(
          id: 'notif_1',
          userId: 'user_1',
          companyId: 'company_1',
          type: NotificationType.message,
          title: 'Test Notification',
          message: 'This is a test',
          createdAt: DateTime.now(),
        );

        expect(notification.id, 'notif_1');
        expect(notification.userId, 'user_1');
        expect(notification.type, NotificationType.message);
        expect(notification.isRead, false);
      });

      test('Can mark notification as read', () {
        final notification = AppNotification(
          id: 'notif_1',
          userId: 'user_1',
          companyId: 'company_1',
          type: NotificationType.message,
          title: 'Test',
          message: 'Test message',
          createdAt: DateTime.now(),
        );

        final updated = notification.copyWith(isRead: true);
        expect(updated.isRead, true);
        expect(updated.id, notification.id);
      });

      test('Notification JSON serialization works', () {
        final notification = AppNotification(
          id: 'notif_1',
          userId: 'user_1',
          companyId: 'company_1',
          type: NotificationType.pointsAwarded,
          title: 'Points Earned',
          message: 'You earned 10 points',
          createdAt: DateTime.now(),
          relatedId: 'target_1',
          metadata: {'points': 10},
        );

        final json = notification.toJson();
        final restored = AppNotification.fromJson(json);

        expect(restored.id, notification.id);
        expect(restored.userId, notification.userId);
        expect(restored.type, notification.type);
        expect(restored.title, notification.title);
        expect(restored.relatedId, notification.relatedId);
        expect(restored.metadata?['points'], 10);
      });

      test('Notification urgency detection works', () {
        final urgentNotif = AppNotification(
          id: 'notif_1',
          userId: 'user_1',
          companyId: 'company_1',
          type: NotificationType.targetAssignment,
          title: 'Urgent',
          message: 'Target assigned',
          createdAt: DateTime.now(),
        );

        final normalNotif = AppNotification(
          id: 'notif_2',
          userId: 'user_1',
          companyId: 'company_1',
          type: NotificationType.message,
          title: 'Normal',
          message: 'New message',
          createdAt: DateTime.now(),
        );

        expect(urgentNotif.isUrgent, true);
        expect(normalNotif.isUrgent, false);
      });

      test('Notification age calculation works', () {
        final now = DateTime.now();
        final oldNotif = AppNotification(
          id: 'notif_1',
          userId: 'user_1',
          companyId: 'company_1',
          type: NotificationType.message,
          title: 'Old',
          message: 'Old message',
          createdAt: now.subtract(const Duration(hours: 25)),
        );

        final recentNotif = AppNotification(
          id: 'notif_2',
          userId: 'user_1',
          companyId: 'company_1',
          type: NotificationType.message,
          title: 'Recent',
          message: 'Recent message',
          createdAt: now.subtract(const Duration(hours: 1)),
        );

        expect(oldNotif.isRecent, false);
        expect(recentNotif.isRecent, true);
        expect(recentNotif.ageInHours, 1);
      });
    });

    group('Notification Storage', () {
      test('Can save and retrieve notifications', () async {
        final notification = AppNotification(
          id: 'notif_1',
          userId: 'user_1',
          companyId: 'company_1',
          type: NotificationType.message,
          title: 'Test',
          message: 'Test message',
          createdAt: DateTime.now(),
        );

        await StorageService.addNotification(notification);
        final notifications = await StorageService.getNotifications();

        expect(notifications.length, 1);
        expect(notifications.first.id, 'notif_1');
      });

      test('Can update a notification', () async {
        final notification = AppNotification(
          id: 'notif_1',
          userId: 'user_1',
          companyId: 'company_1',
          type: NotificationType.message,
          title: 'Test',
          message: 'Test message',
          createdAt: DateTime.now(),
          isRead: false,
        );

        await StorageService.addNotification(notification);

        final updated = notification.copyWith(isRead: true);
        await StorageService.updateNotification(updated);

        final notifications = await StorageService.getNotifications();
        expect(notifications.first.isRead, true);
      });

      test('Can delete a notification', () async {
        final notification = AppNotification(
          id: 'notif_1',
          userId: 'user_1',
          companyId: 'company_1',
          type: NotificationType.message,
          title: 'Test',
          message: 'Test message',
          createdAt: DateTime.now(),
        );

        await StorageService.addNotification(notification);
        expect((await StorageService.getNotifications()).length, 1);

        await StorageService.deleteNotification('notif_1');
        expect((await StorageService.getNotifications()).length, 0);
      });

      test('Can get notifications by user ID', () async {
        final notif1 = AppNotification(
          id: 'notif_1',
          userId: 'user_1',
          companyId: 'company_1',
          type: NotificationType.message,
          title: 'Test 1',
          message: 'Message 1',
          createdAt: DateTime.now(),
        );

        final notif2 = AppNotification(
          id: 'notif_2',
          userId: 'user_2',
          companyId: 'company_1',
          type: NotificationType.message,
          title: 'Test 2',
          message: 'Message 2',
          createdAt: DateTime.now(),
        );

        await StorageService.addNotification(notif1);
        await StorageService.addNotification(notif2);

        final user1Notifs =
            await StorageService.getNotificationsByUserId('user_1');
        expect(user1Notifs.length, 1);
        expect(user1Notifs.first.userId, 'user_1');
      });

      test('Can get unread notifications', () async {
        final read = AppNotification(
          id: 'notif_1',
          userId: 'user_1',
          companyId: 'company_1',
          type: NotificationType.message,
          title: 'Read',
          message: 'Read message',
          createdAt: DateTime.now(),
          isRead: true,
        );

        final unread = AppNotification(
          id: 'notif_2',
          userId: 'user_1',
          companyId: 'company_1',
          type: NotificationType.message,
          title: 'Unread',
          message: 'Unread message',
          createdAt: DateTime.now(),
          isRead: false,
        );

        await StorageService.addNotification(read);
        await StorageService.addNotification(unread);

        final unreadNotifs =
            await StorageService.getUnreadNotificationsByUserId('user_1');
        expect(unreadNotifs.length, 1);
        expect(unreadNotifs.first.isRead, false);
      });

      test('Can get unread notification count', () async {
        for (int i = 0; i < 5; i++) {
          await StorageService.addNotification(AppNotification(
            id: 'notif_$i',
            userId: 'user_1',
            companyId: 'company_1',
            type: NotificationType.message,
            title: 'Test $i',
            message: 'Message $i',
            createdAt: DateTime.now(),
            isRead: i % 2 == 0, // Mark even ones as read
          ));
        }

        final count = await StorageService.getUnreadNotificationCount('user_1');
        expect(count, 2); // 3 unread (1, 3)
      });

      test('Can mark single notification as read', () async {
        final notification = AppNotification(
          id: 'notif_1',
          userId: 'user_1',
          companyId: 'company_1',
          type: NotificationType.message,
          title: 'Test',
          message: 'Test message',
          createdAt: DateTime.now(),
          isRead: false,
        );

        await StorageService.addNotification(notification);
        await StorageService.markNotificationAsRead('notif_1');

        final notifications = await StorageService.getNotifications();
        expect(notifications.first.isRead, true);
      });

      test('Can mark all notifications as read for a user', () async {
        for (int i = 0; i < 3; i++) {
          await StorageService.addNotification(AppNotification(
            id: 'notif_$i',
            userId: 'user_1',
            companyId: 'company_1',
            type: NotificationType.message,
            title: 'Test $i',
            message: 'Message $i',
            createdAt: DateTime.now(),
            isRead: false,
          ));
        }

        await StorageService.markAllNotificationsAsRead('user_1');

        final notifications =
            await StorageService.getNotificationsByUserId('user_1');
        expect(notifications.every((n) => n.isRead), true);
      });

      test('Can delete all notifications for a user', () async {
        await StorageService.addNotification(AppNotification(
          id: 'notif_1',
          userId: 'user_1',
          companyId: 'company_1',
          type: NotificationType.message,
          title: 'User 1',
          message: 'Message for user 1',
          createdAt: DateTime.now(),
        ));

        await StorageService.addNotification(AppNotification(
          id: 'notif_2',
          userId: 'user_2',
          companyId: 'company_1',
          type: NotificationType.message,
          title: 'User 2',
          message: 'Message for user 2',
          createdAt: DateTime.now(),
        ));

        await StorageService.deleteAllNotificationsForUser('user_1');

        final allNotifs = await StorageService.getNotifications();
        expect(allNotifs.length, 1);
        expect(allNotifs.first.userId, 'user_2');
      });

      test('Can delete old notifications', () async {
        final now = DateTime.now();

        await StorageService.addNotification(AppNotification(
          id: 'notif_old',
          userId: 'user_1',
          companyId: 'company_1',
          type: NotificationType.message,
          title: 'Old',
          message: 'Old message',
          createdAt: now.subtract(const Duration(days: 35)),
        ));

        await StorageService.addNotification(AppNotification(
          id: 'notif_recent',
          userId: 'user_1',
          companyId: 'company_1',
          type: NotificationType.message,
          title: 'Recent',
          message: 'Recent message',
          createdAt: now.subtract(const Duration(days: 5)),
        ));

        await StorageService.deleteOldNotifications(daysToKeep: 30);

        final notifications = await StorageService.getNotifications();
        expect(notifications.length, 1);
        expect(notifications.first.id, 'notif_recent');
      });
    });

    group('Notification Service - Message Notifications', () {
      test('Can create message notification', () async {
        final message = Message(
          id: 'msg_1',
          senderId: 'admin_1',
          recipientId: 'emp_1',
          content: 'Hello!',
          timestamp: DateTime.now(),
          isRead: false,
          companyId: 'company_1',
        );

        await NotificationService.notifyNewMessage(
          message: message,
          recipientId: 'emp_1',
          senderName: 'Admin User',
        );

        final notifications =
            await StorageService.getNotificationsByUserId('emp_1');
        expect(notifications.length, 1);
        expect(notifications.first.type, NotificationType.message);
        expect(notifications.first.title, 'New Message');
      });
    });

    group('Notification Service - Target Notifications', () {
      test('Can create target assignment notification', () async {
        final target = SalesTarget(
          id: 'target_1',
          date: DateTime.now(),
          targetAmount: 1000.0,
          actualAmount: 0.0,
          status: TargetStatus.pending,
          createdBy: 'admin_1',
          createdAt: DateTime.now(),
          assignedWorkplaceId: 'wp_1',
          assignedWorkplaceName: 'Store 1',
          companyId: 'company_1',
          collaborativeEmployeeIds: [],
          pointsAwarded: 0,
        );

        await NotificationService.notifyTargetAssignment(
          target: target,
          employeeId: 'emp_1',
          employeeName: 'John Doe',
          assignedBy: 'Admin User',
        );

        final notifications =
            await StorageService.getNotificationsByUserId('emp_1');
        expect(notifications.length, 1);
        expect(notifications.first.type, NotificationType.targetAssignment);
        expect(notifications.first.isUrgent, true);
      });

      test('Can create target approval notification', () async {
        final target = SalesTarget(
          id: 'target_1',
          date: DateTime.now(),
          targetAmount: 1000.0,
          actualAmount: 1200.0,
          status: TargetStatus.approved,
          createdBy: 'admin_1',
          createdAt: DateTime.now(),
          assignedWorkplaceId: 'wp_1',
          assignedWorkplaceName: 'Store 1',
          companyId: 'company_1',
          collaborativeEmployeeIds: ['emp_1'],
          collaborativeEmployeeNames: ['Employee 1'],
          pointsAwarded: 10,
        );

        await NotificationService.notifyTargetApproval(
          target: target,
          employeeId: 'emp_1',
          pointsAwarded: 10,
        );

        final notifications =
            await StorageService.getNotificationsByUserId('emp_1');
        expect(notifications.length, 1);
        expect(notifications.first.type, NotificationType.targetApproval);
        expect(notifications.first.message, contains('10 points'));
      });

      test('Can create target rejection notification', () async {
        final target = SalesTarget(
          id: 'target_1',
          date: DateTime.now(),
          targetAmount: 1000.0,
          actualAmount: 800.0,
          status: TargetStatus.pending,
          createdBy: 'admin_1',
          createdAt: DateTime.now(),
          assignedWorkplaceId: 'wp_1',
          assignedWorkplaceName: 'Store 1',
          companyId: 'company_1',
          collaborativeEmployeeIds: [],
          pointsAwarded: 0,
        );

        await NotificationService.notifyTargetRejection(
          target: target,
          employeeId: 'emp_1',
          reason: 'Sales amount needs verification',
        );

        final notifications =
            await StorageService.getNotificationsByUserId('emp_1');
        expect(notifications.length, 1);
        expect(notifications.first.type, NotificationType.targetRejection);
        expect(notifications.first.message, contains('verification'));
      });

      test('Can create target completed notification', () async {
        final target = SalesTarget(
          id: 'target_1',
          date: DateTime.now(),
          targetAmount: 1000.0,
          actualAmount: 1200.0,
          status: TargetStatus.approved,
          createdBy: 'admin_1',
          createdAt: DateTime.now(),
          assignedWorkplaceId: 'wp_1',
          assignedWorkplaceName: 'Store 1',
          companyId: 'company_1',
          collaborativeEmployeeIds: ['emp_1', 'emp_2'],
          collaborativeEmployeeNames: ['Employee 1', 'Employee 2'],
          pointsAwarded: 20,
        );

        await NotificationService.notifyTargetCompleted(
          target: target,
          teamMemberIds: ['emp_1', 'emp_2'],
        );

        final emp1Notifs =
            await StorageService.getNotificationsByUserId('emp_1');
        final emp2Notifs =
            await StorageService.getNotificationsByUserId('emp_2');

        expect(emp1Notifs.length, 1);
        expect(emp2Notifs.length, 1);
        expect(emp1Notifs.first.type, NotificationType.targetCompleted);
      });
    });

    group('Notification Service - Points Notifications', () {
      test('Can create points awarded notification', () async {
        await NotificationService.notifyPointsAwarded(
          userId: 'emp_1',
          companyId: 'company_1',
          points: 50,
          reason: 'Great performance!',
          relatedId: 'target_1',
        );

        final notifications =
            await StorageService.getNotificationsByUserId('emp_1');
        expect(notifications.length, 1);
        expect(notifications.first.type, NotificationType.pointsAwarded);
        expect(notifications.first.message, contains('50 points'));
      });

      test('Can create points gift notification', () async {
        await NotificationService.notifyPointsGift(
          recipientId: 'emp_1',
          companyId: 'company_1',
          points: 25,
          senderName: 'Admin User',
          message: 'Keep up the good work!',
        );

        final notifications =
            await StorageService.getNotificationsByUserId('emp_1');
        expect(notifications.length, 1);
        expect(notifications.first.type, NotificationType.pointsGift);
        expect(notifications.first.message, contains('25 points'));
        expect(notifications.first.message, contains('Keep up the good work'));
      });
    });

    group('Notification Service - Other Notifications', () {
      test('Can create bonus redeemed notification', () async {
        await NotificationService.notifyBonusRedeemed(
          userId: 'emp_1',
          companyId: 'company_1',
          bonusName: 'Free Coffee',
          pointsCost: 100,
          bonusId: 'bonus_1',
        );

        final notifications =
            await StorageService.getNotificationsByUserId('emp_1');
        expect(notifications.length, 1);
        expect(notifications.first.type, NotificationType.bonusRedeemed);
        expect(notifications.first.message, contains('Free Coffee'));
      });

      test('Can create team invite notification', () async {
        final target = SalesTarget(
          id: 'target_1',
          date: DateTime.now(),
          targetAmount: 1000.0,
          actualAmount: 0.0,
          status: TargetStatus.pending,
          createdBy: 'admin_1',
          createdAt: DateTime.now(),
          assignedWorkplaceId: 'wp_1',
          assignedWorkplaceName: 'Store 1',
          companyId: 'company_1',
          collaborativeEmployeeIds: [],
          pointsAwarded: 0,
        );

        await NotificationService.notifyTeamInvite(
          target: target,
          invitedEmployeeId: 'emp_2',
          invitedByName: 'John Doe',
        );

        final notifications =
            await StorageService.getNotificationsByUserId('emp_2');
        expect(notifications.length, 1);
        expect(notifications.first.type, NotificationType.teamInvite);
        expect(notifications.first.isUrgent, true);
      });

      test('Can create sales submitted notification', () async {
        final target = SalesTarget(
          id: 'target_1',
          date: DateTime.now(),
          targetAmount: 1000.0,
          actualAmount: 1200.0,
          status: TargetStatus.submitted,
          createdBy: 'admin_1',
          createdAt: DateTime.now(),
          assignedWorkplaceId: 'wp_1',
          assignedWorkplaceName: 'Store 1',
          companyId: 'company_1',
          collaborativeEmployeeIds: [],
          pointsAwarded: 0,
        );

        await NotificationService.notifySalesSubmitted(
          target: target,
          adminId: 'admin_1',
          employeeName: 'John Doe',
        );

        final notifications =
            await StorageService.getNotificationsByUserId('admin_1');
        expect(notifications.length, 1);
        expect(notifications.first.type, NotificationType.salesSubmitted);
      });

      test('Can create company update notification', () async {
        await NotificationService.notifyCompanyUpdate(
          companyId: 'company_1',
          userIds: ['emp_1', 'emp_2', 'admin_1'],
          title: 'Company Update',
          message: 'New bonus system launched!',
        );

        final emp1Notifs =
            await StorageService.getNotificationsByUserId('emp_1');
        final emp2Notifs =
            await StorageService.getNotificationsByUserId('emp_2');
        final adminNotifs =
            await StorageService.getNotificationsByUserId('admin_1');

        expect(emp1Notifs.length, 1);
        expect(emp2Notifs.length, 1);
        expect(adminNotifs.length, 1);
        expect(emp1Notifs.first.type, NotificationType.companyUpdate);
      });
    });

    group('Notification Service - Batch Operations', () {
      test('Can notify multiple users at once', () async {
        await NotificationService.notifyMultipleUsers(
          userIds: ['emp_1', 'emp_2', 'emp_3'],
          companyId: 'company_1',
          type: NotificationType.companyUpdate,
          title: 'Important Update',
          message: 'Please read this announcement',
        );

        final emp1Notifs =
            await StorageService.getNotificationsByUserId('emp_1');
        final emp2Notifs =
            await StorageService.getNotificationsByUserId('emp_2');
        final emp3Notifs =
            await StorageService.getNotificationsByUserId('emp_3');

        expect(emp1Notifs.length, 1);
        expect(emp2Notifs.length, 1);
        expect(emp3Notifs.length, 1);
      });
    });

    group('Notification Sorting', () {
      test('Notifications are sorted by date (most recent first)', () async {
        final now = DateTime.now();

        await StorageService.addNotification(AppNotification(
          id: 'notif_1',
          userId: 'user_1',
          companyId: 'company_1',
          type: NotificationType.message,
          title: 'Old',
          message: 'Old message',
          createdAt: now.subtract(const Duration(hours: 2)),
        ));

        await StorageService.addNotification(AppNotification(
          id: 'notif_2',
          userId: 'user_1',
          companyId: 'company_1',
          type: NotificationType.message,
          title: 'Recent',
          message: 'Recent message',
          createdAt: now,
        ));

        final notifications =
            await StorageService.getNotificationsByUserId('user_1');
        expect(notifications.first.id, 'notif_2'); // Most recent first
        expect(notifications.last.id, 'notif_1');
      });
    });

    group('Notification Icons', () {
      test('Each notification type has an icon', () {
        expect(
            NotificationService.getNotificationIcon(NotificationType.message),
            '💬');
        expect(
            NotificationService.getNotificationIcon(
                NotificationType.targetAssignment),
            '🎯');
        expect(
            NotificationService.getNotificationIcon(
                NotificationType.pointsAwarded),
            '⭐');
        expect(
            NotificationService.getNotificationIcon(
                NotificationType.pointsGift),
            '🎁');
        expect(
            NotificationService.getNotificationIcon(
                NotificationType.bonusRedeemed),
            '🎉');
        expect(
            NotificationService.getNotificationIcon(
                NotificationType.teamInvite),
            '👥');
        expect(
            NotificationService.getNotificationIcon(
                NotificationType.targetCompleted),
            '🏆');
      });
    });

    group('Notification Time Ago', () {
      test('Shows correct time ago format', () {
        final now = DateTime.now();

        final justNow = AppNotification(
          id: 'notif_1',
          userId: 'user_1',
          companyId: 'company_1',
          type: NotificationType.message,
          title: 'Test',
          message: 'Test',
          createdAt: now.subtract(const Duration(seconds: 30)),
        );

        final minutesAgo = AppNotification(
          id: 'notif_2',
          userId: 'user_1',
          companyId: 'company_1',
          type: NotificationType.message,
          title: 'Test',
          message: 'Test',
          createdAt: now.subtract(const Duration(minutes: 5)),
        );

        final hoursAgo = AppNotification(
          id: 'notif_3',
          userId: 'user_1',
          companyId: 'company_1',
          type: NotificationType.message,
          title: 'Test',
          message: 'Test',
          createdAt: now.subtract(const Duration(hours: 3)),
        );

        expect(justNow.timeAgo, 'Just now');
        expect(minutesAgo.timeAgo, contains('minute'));
        expect(hoursAgo.timeAgo, contains('hour'));
      });
    });
  });
}
