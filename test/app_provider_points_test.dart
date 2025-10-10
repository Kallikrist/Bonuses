import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bonuses/providers/app_provider.dart';
import 'package:bonuses/models/user.dart';
import 'package:bonuses/models/sales_target.dart';
import 'package:bonuses/models/points_transaction.dart';
import 'package:bonuses/models/company.dart';
import 'package:bonuses/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppProvider points reconciliation', () {
    late AppProvider appProvider;
    const String companyId = 'company_test_1';
    const String johnId = 'user_john';
    const String karlId = 'user_karl';
    const String torunnId = 'user_torunn';

    Future<void> seedUsers() async {
      final users = <User>[
        User(
          id: johnId,
          name: 'john',
          email: 'john@example.com',
          totalPoints: 0,
          role: UserRole.employee,
          companyIds: const [companyId],
          primaryCompanyId: companyId,
          createdAt: DateTime.now(),
        ),
        User(
          id: karlId,
          name: 'karl',
          email: 'karl@example.com',
          totalPoints: 0,
          role: UserRole.employee,
          companyIds: const [companyId],
          primaryCompanyId: companyId,
          createdAt: DateTime.now(),
        ),
        User(
          id: torunnId,
          name: 'torunn',
          email: 'torunn@example.com',
          totalPoints: 0,
          role: UserRole.employee,
          companyIds: const [companyId],
          primaryCompanyId: companyId,
          createdAt: DateTime.now(),
        ),
      ];

      await StorageService.saveUsers(users);
    }

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      appProvider = AppProvider();
      await StorageService.saveCompanies([
        Company(
          id: companyId,
          name: 'Test Co',
          adminUserId: 'admin_test',
          createdAt: DateTime.now(),
        )
      ]);
      await seedUsers();
    });

    test('withdraws points from removed team member on approved target',
        () async {
      // Arrange: approved target with three members who already earned 50
      final target = SalesTarget(
        id: 'target_1',
        companyId: companyId,
        assignedEmployeeId: null,
        assignedEmployeeName: null,
        assignedWorkplaceId: 'work_1',
        assignedWorkplaceName: 'Lindir',
        targetAmount: 1000,
        actualAmount: 2000,
        date: DateTime.now(),
        createdAt: DateTime.now(),
        createdBy: 'admin_test',
        collaborativeEmployeeIds: const [karlId, johnId, torunnId],
        collaborativeEmployeeNames: const ['karl', 'john', 'torunn'],
        isSubmitted: true,
        isApproved: true,
        status: TargetStatus.approved,
        pointsAwarded: 50,
      );

      await StorageService.addSalesTarget(target);
      await appProvider.addSalesTarget(target);

      // Seed existing earned transactions for the original approval (one per member)
      for (final uid in [karlId, johnId, torunnId]) {
        await StorageService.addPointsTransaction(
          PointsTransaction(
            id: 'tx_earned_${uid}_t1',
            userId: uid,
            type: PointsTransactionType.earned,
            points: 50,
            description: 'Team target completed: \$1000',
            date: DateTime.now(),
            relatedTargetId: target.id,
            companyId: companyId,
          ),
        );
      }

      // Act: remove john from the team and update the target
      final updated = target.copyWith(
        collaborativeEmployeeIds: const [karlId, torunnId],
        collaborativeEmployeeNames: const ['karl', 'torunn'],
      );
      await appProvider.updateSalesTarget(updated);

      // Assert: negative adjustment transaction for john should exist for 50 points
      final allTx = await StorageService.getPointsTransactions();
      final johnTx = allTx
          .where((t) => t.userId == johnId && t.relatedTargetId == target.id)
          .toList();

      // Expect one negative adjustment (withdrawal)
      expect(
          johnTx.any((t) =>
              t.type == PointsTransactionType.adjustment && t.points == -50),
          isTrue);
    });

    test('adding member to approved target awards points once', () async {
      final target = SalesTarget(
        id: 'target_2',
        companyId: companyId,
        assignedEmployeeId: null,
        assignedEmployeeName: null,
        assignedWorkplaceId: 'work_1',
        assignedWorkplaceName: 'Lindir',
        targetAmount: 1000,
        actualAmount: 2000,
        date: DateTime.now(),
        createdAt: DateTime.now(),
        createdBy: 'admin_test',
        collaborativeEmployeeIds: const [karlId, torunnId],
        collaborativeEmployeeNames: const ['karl', 'torunn'],
        isSubmitted: true,
        isApproved: true,
        status: TargetStatus.approved,
        pointsAwarded: 50,
      );

      await StorageService.addSalesTarget(target);
      await appProvider.addSalesTarget(target);

      for (final uid in [karlId, torunnId]) {
        await StorageService.addPointsTransaction(
          PointsTransaction(
            id: 'tx_earned_${uid}_t2',
            userId: uid,
            type: PointsTransactionType.earned,
            points: 50,
            description: 'Team target completed: \$1000',
            date: DateTime.now(),
            relatedTargetId: target.id,
            companyId: companyId,
          ),
        );
      }

      final updated = target.copyWith(
        collaborativeEmployeeIds: const [karlId, torunnId, johnId],
        collaborativeEmployeeNames: const ['karl', 'torunn', 'john'],
      );
      await appProvider.updateSalesTarget(updated);
      await appProvider.updateSalesTarget(updated); // idempotent

      final allTx = await StorageService.getPointsTransactions();
      final johnTx = allTx
          .where((t) => t.userId == johnId && t.relatedTargetId == target.id)
          .toList();
      final earns = johnTx
              .where((t) =>
                  t.type == PointsTransactionType.adjustment && t.points == 50)
              .length +
          johnTx
              .where((t) =>
                  t.type == PointsTransactionType.earned && t.points == 50)
              .length;
      expect(earns, 1);
    });

    test('lowering effective percent withdraws correct delta from each member',
        () async {
      // Approved target at 200% → 50 points each
      final target = SalesTarget(
        id: 'target_adjust',
        companyId: companyId,
        assignedEmployeeId: null,
        assignedEmployeeName: null,
        assignedWorkplaceId: 'work_1',
        assignedWorkplaceName: 'Lindir',
        targetAmount: 1000,
        actualAmount: 2000,
        date: DateTime.now(),
        createdAt: DateTime.now(),
        createdBy: 'admin_test',
        collaborativeEmployeeIds: const [karlId, torunnId],
        collaborativeEmployeeNames: const ['karl', 'torunn'],
        isSubmitted: true,
        isApproved: true,
        status: TargetStatus.approved,
        pointsAwarded: 50,
      );

      await StorageService.addSalesTarget(target);
      await appProvider.addSalesTarget(target);

      // Seed earned 50 each (use provider so in-memory list updates too)
      for (final uid in [karlId, torunnId]) {
        await appProvider.addPointsTransaction(
          PointsTransaction(
            id: 'tx_earned_${uid}_t_adjust',
            userId: uid,
            type: PointsTransactionType.earned,
            points: 50,
            description: 'Team target completed: \$1000',
            date: DateTime.now(),
            relatedTargetId: target.id,
            companyId: companyId,
          ),
        );
      }

      // Change target amount so effective percent drops to 100% → 10 points
      await appProvider.recalculateAndAdjustPoints(target.id, 2000);

      final allTx = await StorageService.getPointsTransactions();
      for (final uid in [karlId, torunnId]) {
        final userTx = allTx
            .where((t) => t.userId == uid && t.relatedTargetId == target.id)
            .toList();
        final hasAdjustment = userTx.any((t) =>
            t.type == PointsTransactionType.adjustment && t.points == -40);
        final hasRedeemed = userTx.any(
            (t) => t.type == PointsTransactionType.redeemed && t.points == 40);
        expect(hasAdjustment || hasRedeemed, isTrue);
      }
    });

    test('removing assigned employee withdraws their points', () async {
      // Approved target with assigned employee and two collaborators (50 each)
      final target = SalesTarget(
        id: 'target_assigned_remove',
        companyId: companyId,
        assignedEmployeeId: johnId,
        assignedEmployeeName: 'john',
        assignedWorkplaceId: 'work_1',
        assignedWorkplaceName: 'Lindir',
        targetAmount: 1000,
        actualAmount: 2000,
        date: DateTime.now(),
        createdAt: DateTime.now(),
        createdBy: 'admin_test',
        collaborativeEmployeeIds: const [karlId, torunnId],
        collaborativeEmployeeNames: const ['karl', 'torunn'],
        isSubmitted: true,
        isApproved: true,
        status: TargetStatus.approved,
        pointsAwarded: 50,
      );

      await StorageService.addSalesTarget(target);
      await appProvider.addSalesTarget(target);

      // Seed earned for assigned and collaborators
      final seedIds = [johnId, karlId, torunnId];
      for (final uid in seedIds) {
        await StorageService.addPointsTransaction(
          PointsTransaction(
            id: 'tx_earned_${uid}_t_assigned',
            userId: uid,
            type: PointsTransactionType.earned,
            points: 50,
            description: uid == johnId
                ? 'Target completed: \$1000'
                : 'Team target completed: \$1000',
            date: DateTime.now(),
            relatedTargetId: target.id,
            companyId: companyId,
          ),
        );
      }

      // Remove assigned employee
      final updated = target.copyWith(
        assignedEmployeeId: null,
        assignedEmployeeName: null,
      );
      await appProvider.updateSalesTarget(updated);

      final allTx = await StorageService.getPointsTransactions();
      final johnTx = allTx
          .where((t) => t.userId == johnId && t.relatedTargetId == target.id)
          .toList();
      expect(
          johnTx.any((t) =>
              t.type == PointsTransactionType.adjustment && t.points == -50),
          isTrue);
    });
  });
}
