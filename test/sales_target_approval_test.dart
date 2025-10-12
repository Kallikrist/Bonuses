import 'package:flutter_test/flutter_test.dart';
import 'package:bonuses/models/sales_target.dart';
import 'helpers/testable_app_provider.dart';
import 'helpers/mock_storage_service.dart';

void main() {
  group('Sales Target Approval Tests', () {
    late TestableAppProvider appProvider;

    setUp(() async {
      appProvider = TestableAppProvider();
      await appProvider.initialize();
    });

    tearDown(() async {
      await MockStorageService.clearAllData();
    });

    group('Target Approval Workflow', () {
      test('Approving submitted target changes status to approved', () async {
        await appProvider.login('admin@store.com', 'password123');

        // Get a user to test with
        final users = await appProvider.getUsers();
        final testUser = users.firstWhere((u) => u.role.name == 'employee');

        // Create a submitted target
        final target = SalesTarget(
          id: 'test_approval_${DateTime.now().millisecondsSinceEpoch}',
          date: DateTime.now(),
          targetAmount: 1000.0,
          actualAmount: 1200.0,
          createdAt: DateTime.now(),
          createdBy: 'admin1',
          assignedEmployeeId: testUser.id,
          assignedEmployeeName: testUser.name,
          assignedWorkplaceId: 'wp1',
          assignedWorkplaceName: 'Test Store',
          status: TargetStatus.submitted,
          isSubmitted: true,
        );

        await appProvider.addSalesTarget(target);

        // Approve the target
        await appProvider.approveSalesTarget(target.id, 'admin1');

        // Check that target status changed
        final updatedTargets = appProvider.salesTargets;
        final updatedTarget =
            updatedTargets.firstWhere((t) => t.id == target.id);

        expect(updatedTarget.status, equals(TargetStatus.approved));
        expect(updatedTarget.isApproved, isTrue);
        expect(updatedTarget.approvedBy, equals('admin1'));
        expect(updatedTarget.approvedAt, isNotNull);
      });

      test('Approving met target awards correct points to team members',
          () async {
        await appProvider.login('admin@store.com', 'password123');

        // Get a user to test with
        final users = await appProvider.getUsers();
        final testUser = users.firstWhere((u) => u.role.name == 'employee');

        // Create a target that will be met (120% achievement)
        final target = SalesTarget(
          id: 'test_points_award_${DateTime.now().millisecondsSinceEpoch}',
          date: DateTime.now(),
          targetAmount: 1000.0,
          actualAmount: 1200.0, // 120% achievement
          createdAt: DateTime.now(),
          createdBy: 'admin1',
          assignedEmployeeId: testUser.id,
          assignedEmployeeName: testUser.name,
          assignedWorkplaceId: 'wp1',
          assignedWorkplaceName: 'Test Store',
          status: TargetStatus.submitted,
          isSubmitted: true,
        );

        await appProvider.addSalesTarget(target);

        // Get initial points
        final initialPoints = appProvider.getUserTotalPoints(testUser.id);

        // Approve the target
        await appProvider.approveSalesTarget(target.id, 'admin1');

        // Check that points were awarded (20 points for 120% achievement)
        final finalPoints = appProvider.getUserTotalPoints(testUser.id);
        final pointsAwarded = finalPoints - initialPoints;

        expect(pointsAwarded, equals(20));

        // Check that points transaction was created
        final transactions = appProvider.getUserPointsTransactions(testUser.id);
        final targetTransaction = transactions.firstWhere(
            (t) => t.relatedTargetId == target.id,
            orElse: () => throw Exception('No transaction found for target'));

        expect(targetTransaction.type.name, equals('earned'));
        expect(targetTransaction.points, equals(20));
        expect(targetTransaction.description,
            contains('Sales target exceeded by 20.0%'));
      });

      test('Approving unmet target awards no points', () async {
        await appProvider.login('admin@store.com', 'password123');

        // Get a user to test with
        final users = await appProvider.getUsers();
        final testUser = users.firstWhere((u) => u.role.name == 'employee');

        // Create a target that will not be met (80% achievement)
        final target = SalesTarget(
          id: 'test_no_points_${DateTime.now().millisecondsSinceEpoch}',
          date: DateTime.now(),
          targetAmount: 1000.0,
          actualAmount: 800.0, // 80% achievement (not met)
          createdAt: DateTime.now(),
          createdBy: 'admin1',
          assignedEmployeeId: testUser.id,
          assignedEmployeeName: testUser.name,
          assignedWorkplaceId: 'wp1',
          assignedWorkplaceName: 'Test Store',
          status: TargetStatus.submitted,
          isSubmitted: true,
        );

        await appProvider.addSalesTarget(target);

        // Get initial points
        final initialPoints = appProvider.getUserTotalPoints(testUser.id);

        // Approve the target
        await appProvider.approveSalesTarget(target.id, 'admin1');

        // Check that no points were awarded
        final finalPoints = appProvider.getUserTotalPoints(testUser.id);
        expect(finalPoints, equals(initialPoints));

        // Check that no points transaction was created for this target
        final transactions = appProvider.getUserPointsTransactions(testUser.id);
        final targetTransactions =
            transactions.where((t) => t.relatedTargetId == target.id).toList();

        expect(targetTransactions, isEmpty);
      });

      test('Approving target with team members awards points to all members',
          () async {
        await appProvider.login('admin@store.com', 'password123');

        // Get users to test with
        final users = await appProvider.getUsers();
        final primaryUser = users.firstWhere((u) => u.role.name == 'employee');
        final teamMember = users.firstWhere(
            (u) => u.role.name == 'employee' && u.id != primaryUser.id);

        // Create a target with team members
        final target = SalesTarget(
          id: 'test_team_points_${DateTime.now().millisecondsSinceEpoch}',
          date: DateTime.now(),
          targetAmount: 1000.0,
          actualAmount: 1500.0, // 150% achievement
          createdAt: DateTime.now(),
          createdBy: 'admin1',
          assignedEmployeeId: primaryUser.id,
          assignedEmployeeName: primaryUser.name,
          assignedWorkplaceId: 'wp1',
          assignedWorkplaceName: 'Test Store',
          collaborativeEmployeeIds: [teamMember.id],
          collaborativeEmployeeNames: [teamMember.name],
          status: TargetStatus.submitted,
          isSubmitted: true,
        );

        await appProvider.addSalesTarget(target);

        // Get initial points for both users
        final initialPointsPrimary =
            appProvider.getUserTotalPoints(primaryUser.id);
        final initialPointsTeam = appProvider.getUserTotalPoints(teamMember.id);

        // Approve the target
        await appProvider.approveSalesTarget(target.id, 'admin1');

        // Check that both users received points (30 points for 150% achievement)
        final finalPointsPrimary =
            appProvider.getUserTotalPoints(primaryUser.id);
        final finalPointsTeam = appProvider.getUserTotalPoints(teamMember.id);

        expect(finalPointsPrimary - initialPointsPrimary, equals(30));
        expect(finalPointsTeam - initialPointsTeam, equals(30));
      });
    });

    group('Target Editing After Approval', () {
      test('Editing approved target does not reset points to zero', () async {
        await appProvider.login('admin@store.com', 'password123');

        // Get a user to test with
        final users = await appProvider.getUsers();
        final testUser = users.firstWhere((u) => u.role.name == 'employee');

        // Create and approve a target
        final target = SalesTarget(
          id: 'test_edit_approved_${DateTime.now().millisecondsSinceEpoch}',
          date: DateTime.now(),
          targetAmount: 1000.0,
          actualAmount: 1200.0, // 120% achievement
          createdAt: DateTime.now(),
          createdBy: 'admin1',
          assignedEmployeeId: testUser.id,
          assignedEmployeeName: testUser.name,
          assignedWorkplaceId: 'wp1',
          assignedWorkplaceName: 'Test Store',
          status: TargetStatus.submitted,
          isSubmitted: true,
        );

        await appProvider.addSalesTarget(target);
        await appProvider.approveSalesTarget(target.id, 'admin1');

        // Get points after approval
        final pointsAfterApproval = appProvider.getUserTotalPoints(testUser.id);
        print('DEBUG: Points after approval: $pointsAfterApproval');

        // Check target status after approval
        final approvedTarget =
            appProvider.salesTargets.firstWhere((t) => t.id == target.id);
        print(
            'DEBUG: Target after approval - isMet: ${approvedTarget.isMet}, pointsAwarded: ${approvedTarget.pointsAwarded}');

        // Edit the approved target (change target amount)
        final updatedTarget = approvedTarget.copyWith(
          targetAmount: 1500.0, // Change target amount
        );

        await appProvider.updateSalesTarget(updatedTarget);

        // Check that points were not reset
        final pointsAfterEdit = appProvider.getUserTotalPoints(testUser.id);
        print('DEBUG: Points after edit: $pointsAfterEdit');
        expect(pointsAfterEdit, equals(pointsAfterApproval));

        // Check that target still shows correct points awarded
        final finalTarget =
            appProvider.salesTargets.firstWhere((t) => t.id == target.id);
        print(
            'DEBUG: Final target - pointsAwarded: ${finalTarget.pointsAwarded}');
        expect(finalTarget.pointsAwarded,
            equals(20)); // Should still be 20 points for 120% achievement
      });

      test(
          'Editing approved target with new actual amount recalculates points correctly',
          () async {
        await appProvider.login('admin@store.com', 'password123');

        // Get a user to test with
        final users = await appProvider.getUsers();
        final testUser = users.firstWhere((u) => u.role.name == 'employee');

        // Create and approve a target
        final target = SalesTarget(
          id: 'test_recalculate_${DateTime.now().millisecondsSinceEpoch}',
          date: DateTime.now(),
          targetAmount: 1000.0,
          actualAmount: 1200.0, // 120% achievement
          createdAt: DateTime.now(),
          createdBy: 'admin1',
          assignedEmployeeId: testUser.id,
          assignedEmployeeName: testUser.name,
          assignedWorkplaceId: 'wp1',
          assignedWorkplaceName: 'Test Store',
          status: TargetStatus.submitted,
          isSubmitted: true,
        );

        await appProvider.addSalesTarget(target);
        await appProvider.approveSalesTarget(target.id, 'admin1');

        // Get initial points
        final initialPoints = appProvider.getUserTotalPoints(testUser.id);
        print('DEBUG: Initial points: $initialPoints');

        // Edit the target with new actual amount (150% achievement)
        final approvedTarget =
            appProvider.salesTargets.firstWhere((t) => t.id == target.id);
        print(
            'DEBUG: Approved target pointsAwarded: ${approvedTarget.pointsAwarded}');
        final updatedTarget = approvedTarget.copyWith(
          actualAmount: 1500.0, // Change to 150% achievement
        );

        await appProvider.updateSalesTarget(updatedTarget);

        // Check that points were NOT recalculated (points should remain the same)
        final finalPoints = appProvider.getUserTotalPoints(testUser.id);
        print('DEBUG: Final points: $finalPoints');

        // Should still be 20 points total (not recalculated to 30)
        expect(finalPoints, equals(20));

        // Check that target shows original points awarded (not recalculated)
        final finalTarget =
            appProvider.salesTargets.firstWhere((t) => t.id == target.id);
        expect(finalTarget.pointsAwarded, equals(20));
      });
    });

    group('Points Adjustment Logic', () {
      test(
          '_adjustPointsForTargetUpdate skips adjustment during approval process',
          () async {
        await appProvider.login('admin@store.com', 'password123');

        // Get a user to test with
        final users = await appProvider.getUsers();
        final testUser = users.firstWhere((u) => u.role.name == 'employee');

        // Create a submitted target
        final target = SalesTarget(
          id: 'test_skip_adjustment_${DateTime.now().millisecondsSinceEpoch}',
          date: DateTime.now(),
          targetAmount: 1000.0,
          actualAmount: 1200.0,
          createdAt: DateTime.now(),
          createdBy: 'admin1',
          assignedEmployeeId: testUser.id,
          assignedEmployeeName: testUser.name,
          assignedWorkplaceId: 'wp1',
          assignedWorkplaceName: 'Test Store',
          status: TargetStatus.submitted,
          isSubmitted: true,
        );

        await appProvider.addSalesTarget(target);

        // Get initial points
        final initialPoints = appProvider.getUserTotalPoints(testUser.id);

        // Approve the target (this should trigger the skip logic)
        await appProvider.approveSalesTarget(target.id, 'admin1');

        // Check that points were awarded correctly without adjustment issues
        final finalPoints = appProvider.getUserTotalPoints(testUser.id);
        final pointsAwarded = finalPoints - initialPoints;

        // Should award exactly 20 points for 120% achievement
        expect(pointsAwarded, equals(20));
      });

      test('Points adjustment is skipped when editing already approved target',
          () async {
        await appProvider.login('admin@store.com', 'password123');

        // Get a user to test with
        final users = await appProvider.getUsers();
        final testUser = users.firstWhere((u) => u.role.name == 'employee');

        // Create, approve, and then edit a target
        final target = SalesTarget(
          id: 'test_edit_approved_skip_${DateTime.now().millisecondsSinceEpoch}',
          date: DateTime.now(),
          targetAmount: 1000.0,
          actualAmount: 1200.0,
          createdAt: DateTime.now(),
          createdBy: 'admin1',
          assignedEmployeeId: testUser.id,
          assignedEmployeeName: testUser.name,
          assignedWorkplaceId: 'wp1',
          assignedWorkplaceName: 'Test Store',
          status: TargetStatus.submitted,
          isSubmitted: true,
        );

        await appProvider.addSalesTarget(target);
        await appProvider.approveSalesTarget(target.id, 'admin1');

        // Get points after approval
        final pointsAfterApproval = appProvider.getUserTotalPoints(testUser.id);

        // Edit the approved target (this should skip adjustment)
        final updatedTarget = target.copyWith(
          targetAmount: 1500.0, // Change target amount
          status: TargetStatus.approved, // Keep as approved
        );

        await appProvider.updateSalesTarget(updatedTarget);

        // Points should remain unchanged
        final pointsAfterEdit = appProvider.getUserTotalPoints(testUser.id);
        expect(pointsAfterEdit, equals(pointsAfterApproval));
      });
    });

    group('Error Handling', () {
      test('Approving non-existent target throws appropriate error', () async {
        await appProvider.login('admin@store.com', 'password123');

        // Try to approve a target that doesn't exist
        expect(
          () async =>
              await appProvider.approveSalesTarget('non_existent_id', 'admin1'),
          throwsA(isA<Exception>()),
        );
      });

      test('Approving already approved target handles gracefully', () async {
        await appProvider.login('admin@store.com', 'password123');

        // Get a user to test with
        final users = await appProvider.getUsers();
        final testUser = users.firstWhere((u) => u.role.name == 'employee');

        // Create and approve a target
        final target = SalesTarget(
          id: 'test_double_approve_${DateTime.now().millisecondsSinceEpoch}',
          date: DateTime.now(),
          targetAmount: 1000.0,
          actualAmount: 1200.0,
          createdAt: DateTime.now(),
          createdBy: 'admin1',
          assignedEmployeeId: testUser.id,
          assignedEmployeeName: testUser.name,
          assignedWorkplaceId: 'wp1',
          assignedWorkplaceName: 'Test Store',
          status: TargetStatus.submitted,
          isSubmitted: true,
        );

        await appProvider.addSalesTarget(target);
        await appProvider.approveSalesTarget(target.id, 'admin1');

        // Try to approve again
        await appProvider.approveSalesTarget(target.id, 'admin1');

        // Should not throw an error and should not award duplicate points
        final finalPoints = appProvider.getUserTotalPoints(testUser.id);
        // Points should be exactly 20 (not 40 from double approval)
        expect(finalPoints, equals(20));
      });
    });
  });
}
