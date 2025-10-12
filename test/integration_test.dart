import 'package:flutter_test/flutter_test.dart';
import 'package:bonuses/models/sales_target.dart';
import 'helpers/testable_app_provider.dart';
import 'helpers/mock_storage_service.dart';

void main() {
  group('End-to-End Integration Tests', () {
    late TestableAppProvider appProvider;

    setUp(() async {
      appProvider = TestableAppProvider();
      await appProvider.initialize();
    });

    tearDown(() async {
      await MockStorageService.clearAllData();
    });

    group('Complete Sales Target Workflow', () {
      test('Full workflow: Create -> Submit -> Approve -> Award Points',
          () async {
        // Step 1: Login as admin
        final adminLoginSuccess =
            await appProvider.login('admin@store.com', 'password123');
        expect(adminLoginSuccess, isTrue);
        expect(appProvider.isAdmin, isTrue);

        // Step 2: Get a test employee
        final users = await appProvider.getUsers();
        final testEmployee = users.firstWhere((u) => u.role.name == 'employee');

        // Step 3: Create a sales target
        final target = SalesTarget(
          id: 'integration_test_${DateTime.now().millisecondsSinceEpoch}',
          date: DateTime.now(),
          targetAmount: 1000.0,
          actualAmount: 0.0, // Initially no actual amount
          createdAt: DateTime.now(),
          createdBy: 'admin1',
          assignedEmployeeId: testEmployee.id,
          assignedEmployeeName: testEmployee.name,
          assignedWorkplaceId: 'wp1',
          assignedWorkplaceName: 'Test Store',
          status: TargetStatus.pending,
        );

        await appProvider.addSalesTarget(target);
        expect(appProvider.salesTargets.any((t) => t.id == target.id), isTrue);

        // Step 4: Submit the target with actual amount (120% achievement)
        final submittedTarget = target.copyWith(
          actualAmount: 1200.0,
          status: TargetStatus.submitted,
          isSubmitted: true,
        );

        await appProvider.updateSalesTarget(submittedTarget);

        // Verify target is submitted
        final updatedTarget =
            appProvider.salesTargets.firstWhere((t) => t.id == target.id);
        expect(updatedTarget.status, equals(TargetStatus.submitted));
        expect(updatedTarget.isSubmitted, isTrue);

        // Step 5: Get initial points
        final initialPoints = appProvider.getUserTotalPoints(testEmployee.id);

        // Step 6: Approve the target
        await appProvider.approveSalesTarget(target.id, 'admin1');

        // Step 7: Verify target is approved and points are awarded
        final finalTarget =
            appProvider.salesTargets.firstWhere((t) => t.id == target.id);
        expect(finalTarget.status, equals(TargetStatus.approved));
        expect(finalTarget.isApproved, isTrue);
        expect(finalTarget.pointsAwarded,
            equals(20)); // 20 points for 120% achievement

        // Step 8: Verify points were awarded to employee
        final finalPoints = appProvider.getUserTotalPoints(testEmployee.id);
        expect(finalPoints - initialPoints, equals(20));

        // Step 9: Verify points transaction was created
        final transactions =
            appProvider.getUserPointsTransactions(testEmployee.id);
        final targetTransaction = transactions.firstWhere(
            (t) => t.relatedTargetId == target.id,
            orElse: () => throw Exception('No transaction found for target'));
        expect(targetTransaction.type.name, equals('earned'));
        expect(targetTransaction.points, equals(20));
      });

      test(
          'Team target workflow: Create -> Add team members -> Submit -> Approve',
          () async {
        // Step 1: Login as admin
        await appProvider.login('admin@store.com', 'password123');

        // Step 2: Get test employees
        final users = await appProvider.getUsers();
        final primaryEmployee =
            users.firstWhere((u) => u.role.name == 'employee');
        final teamMember = users.firstWhere(
            (u) => u.role.name == 'employee' && u.id != primaryEmployee.id);

        // Step 3: Create a team target
        final target = SalesTarget(
          id: 'team_integration_${DateTime.now().millisecondsSinceEpoch}',
          date: DateTime.now(),
          targetAmount: 2000.0,
          actualAmount: 0.0,
          createdAt: DateTime.now(),
          createdBy: 'admin1',
          assignedEmployeeId: primaryEmployee.id,
          assignedEmployeeName: primaryEmployee.name,
          assignedWorkplaceId: 'wp1',
          assignedWorkplaceName: 'Test Store',
          collaborativeEmployeeIds: [teamMember.id],
          collaborativeEmployeeNames: [teamMember.name],
          status: TargetStatus.pending,
        );

        await appProvider.addSalesTarget(target);

        // Step 4: Submit with actual amount (150% achievement)
        final submittedTarget = target.copyWith(
          actualAmount: 3000.0, // 150% achievement
          status: TargetStatus.submitted,
          isSubmitted: true,
        );

        await appProvider.updateSalesTarget(submittedTarget);

        // Step 5: Get initial points for both employees
        final initialPointsPrimary =
            appProvider.getUserTotalPoints(primaryEmployee.id);
        final initialPointsTeam = appProvider.getUserTotalPoints(teamMember.id);

        // Step 6: Approve the target
        await appProvider.approveSalesTarget(target.id, 'admin1');

        // Step 7: Verify both employees received points (30 points each for 150% achievement)
        final finalPointsPrimary =
            appProvider.getUserTotalPoints(primaryEmployee.id);
        final finalPointsTeam = appProvider.getUserTotalPoints(teamMember.id);

        expect(finalPointsPrimary - initialPointsPrimary, equals(30));
        expect(finalPointsTeam - initialPointsTeam, equals(30));

        // Step 8: Verify both employees have transactions
        final primaryTransactions =
            appProvider.getUserPointsTransactions(primaryEmployee.id);
        final teamTransactions =
            appProvider.getUserPointsTransactions(teamMember.id);

        expect(primaryTransactions.any((t) => t.relatedTargetId == target.id),
            isTrue);
        expect(teamTransactions.any((t) => t.relatedTargetId == target.id),
            isTrue);
      });
    });

    group('Admin Profile Management Workflow', () {
      test('Admin profile editing: Login -> Edit -> Save -> Verify', () async {
        // Step 1: Login as admin
        final loginSuccess =
            await appProvider.login('admin@store.com', 'password123');
        expect(loginSuccess, isTrue);

        // Step 2: Get current admin user
        final currentUser = appProvider.currentUser!;
        expect(currentUser.email, equals('admin@store.com'));

        // Step 3: Update admin profile
        final updatedUser = currentUser.copyWith(
          name: 'Updated Admin Name',
          email: 'updated.admin@store.com',
          phoneNumber: '+1234567890',
        );

        await appProvider.updateUser(updatedUser);

        // Step 4: Verify changes were saved
        final finalUser = appProvider.currentUser!;
        expect(finalUser.name, equals('Updated Admin Name'));
        expect(finalUser.email, equals('updated.admin@store.com'));
        expect(finalUser.phoneNumber, equals('+1234567890'));

        // Step 5: Verify user is still admin
        expect(finalUser.role.name, equals('admin'));
        expect(appProvider.isAdmin, isTrue);
      });

      test(
          'Employee profile management: Admin edits employee -> Verify changes',
          () async {
        // Step 1: Login as admin
        await appProvider.login('admin@store.com', 'password123');

        // Step 2: Get an employee
        final users = await appProvider.getUsers();
        final testEmployee = users.firstWhere((u) => u.role.name == 'employee');

        // Step 3: Update employee profile
        final updatedEmployee = testEmployee.copyWith(
          name: 'Updated Employee Name',
          email: 'updated.employee@store.com',
          phoneNumber: '+9876543210',
        );

        await appProvider.updateUser(updatedEmployee);

        // Step 4: Verify changes were saved
        final updatedUsers = await appProvider.getUsers();
        final finalEmployee =
            updatedUsers.firstWhere((u) => u.id == testEmployee.id);

        expect(finalEmployee.name, equals('Updated Employee Name'));
        expect(finalEmployee.email, equals('updated.employee@store.com'));
        expect(finalEmployee.phoneNumber, equals('+9876543210'));
      });
    });

    group('Points Management Workflow', () {
      test(
          'Admin points management: Add points -> Remove points -> Verify balance',
          () async {
        // Step 1: Login as admin
        await appProvider.login('admin@store.com', 'password123');

        // Step 2: Get an employee
        final users = await appProvider.getUsers();
        final testEmployee = users.firstWhere((u) => u.role.name == 'employee');

        // Step 3: Get initial points
        final initialPoints = appProvider.getUserTotalPoints(testEmployee.id);

        // Step 4: Add 100 points
        await appProvider.updateUserPoints(
            testEmployee.id, 100, 'Admin added points for testing');

        // Step 5: Verify points were added
        final pointsAfterAddition =
            appProvider.getUserTotalPoints(testEmployee.id);
        expect(pointsAfterAddition - initialPoints, equals(100));

        // Step 6: Remove 30 points
        await appProvider.updateUserPoints(
            testEmployee.id, -30, 'Admin removed points for testing');

        // Step 7: Verify final balance
        final finalPoints = appProvider.getUserTotalPoints(testEmployee.id);
        expect(finalPoints - initialPoints, equals(70)); // 100 - 30 = 70

        // Step 8: Verify transactions were created
        final transactions =
            appProvider.getUserPointsTransactions(testEmployee.id);
        expect(transactions.length, greaterThanOrEqualTo(2));

        final addTransaction = transactions.firstWhere(
            (t) => t.description == 'Admin added points for testing');
        expect(addTransaction.type.name, equals('earned'));
        expect(addTransaction.points, equals(100));

        final removeTransaction = transactions.firstWhere(
            (t) => t.description == 'Admin removed points for testing');
        expect(removeTransaction.type.name, equals('redeemed'));
        expect(removeTransaction.points, equals(30));
      });

      test('Points validation: Prevent negative points', () async {
        // Step 1: Login as admin
        await appProvider.login('admin@store.com', 'password123');

        // Step 2: Get an employee
        final users = await appProvider.getUsers();
        final testEmployee = users.firstWhere((u) => u.role.name == 'employee');

        // Step 3: Get initial points
        final initialPoints = appProvider.getUserTotalPoints(testEmployee.id);

        // Step 4: Try to remove more points than available
        await appProvider.updateUserPoints(testEmployee.id,
            -(initialPoints + 1000), 'Attempt to create negative points');

        // Step 5: Verify points were not changed
        final finalPoints = appProvider.getUserTotalPoints(testEmployee.id);
        expect(finalPoints, equals(initialPoints));
      });
    });

    group('Complex Multi-Step Workflows', () {
      test(
          'Complete employee day: Login -> View targets -> Submit -> Admin approves -> View points',
          () async {
        // Step 1: Login as employee
        final employeeLoginSuccess =
            await appProvider.login('john@store.com', 'password123');
        expect(employeeLoginSuccess, isTrue);
        expect(appProvider.isEmployee, isTrue);

        // Step 2: Create a target for the employee
        final target = SalesTarget(
          id: 'employee_day_${DateTime.now().millisecondsSinceEpoch}',
          date: DateTime.now(),
          targetAmount: 1000.0,
          actualAmount: 0.0,
          createdAt: DateTime.now(),
          createdBy: 'admin1',
          assignedEmployeeId: appProvider.currentUser!.id,
          assignedEmployeeName: appProvider.currentUser!.name,
          assignedWorkplaceId: 'wp1',
          assignedWorkplaceName: 'Test Store',
          status: TargetStatus.pending,
        );

        await appProvider.addSalesTarget(target);

        // Step 3: Employee submits target
        final submittedTarget = target.copyWith(
          actualAmount: 1300.0, // 130% achievement
          status: TargetStatus.submitted,
          isSubmitted: true,
        );

        await appProvider.updateSalesTarget(submittedTarget);

        // Step 4: Switch to admin
        await appProvider.logout();
        final adminLoginSuccess =
            await appProvider.login('admin@store.com', 'password123');
        expect(adminLoginSuccess, isTrue);

        // Step 5: Admin approves target
        await appProvider.approveSalesTarget(target.id, 'admin1');

        // Step 6: Switch back to employee
        await appProvider.logout();
        await appProvider.login('john@store.com', 'password123');

        // Step 7: Verify employee received points (20 points for 130% achievement)
        final employeePoints =
            appProvider.getUserTotalPoints(appProvider.currentUser!.id);
        expect(employeePoints, equals(20));

        // Step 8: Verify target is approved
        final finalTarget =
            appProvider.salesTargets.firstWhere((t) => t.id == target.id);
        expect(finalTarget.status, equals(TargetStatus.approved));
        expect(finalTarget.pointsAwarded, equals(20));
      });

      test(
          'Multiple targets workflow: Create multiple targets -> Approve all -> Verify total points',
          () async {
        // Step 1: Login as admin
        await appProvider.login('admin@store.com', 'password123');

        // Step 2: Get an employee
        final users = await appProvider.getUsers();
        final testEmployee = users.firstWhere((u) => u.role.name == 'employee');

        // Step 3: Create multiple targets
        final targets = [
          SalesTarget(
            id: 'multi_1_${DateTime.now().millisecondsSinceEpoch}',
            date: DateTime.now(),
            targetAmount: 1000.0,
            actualAmount: 1200.0, // 120% - 20 points
            createdAt: DateTime.now(),
            createdBy: 'admin1',
            assignedEmployeeId: testEmployee.id,
            assignedEmployeeName: testEmployee.name,
            assignedWorkplaceId: 'wp1',
            assignedWorkplaceName: 'Test Store',
            status: TargetStatus.submitted,
            isSubmitted: true,
          ),
          SalesTarget(
            id: 'multi_2_${DateTime.now().millisecondsSinceEpoch + 1}',
            date: DateTime.now(),
            targetAmount: 2000.0,
            actualAmount: 3000.0, // 150% - 30 points
            createdAt: DateTime.now(),
            createdBy: 'admin1',
            assignedEmployeeId: testEmployee.id,
            assignedEmployeeName: testEmployee.name,
            assignedWorkplaceId: 'wp1',
            assignedWorkplaceName: 'Test Store',
            status: TargetStatus.submitted,
            isSubmitted: true,
          ),
        ];

        for (final target in targets) {
          await appProvider.addSalesTarget(target);
        }

        // Step 4: Get initial points
        final initialPoints = appProvider.getUserTotalPoints(testEmployee.id);

        // Step 5: Approve all targets
        for (final target in targets) {
          await appProvider.approveSalesTarget(target.id, 'admin1');
        }

        // Step 6: Verify total points (20 + 30 = 50)
        final finalPoints = appProvider.getUserTotalPoints(testEmployee.id);
        expect(finalPoints - initialPoints, equals(50));

        // Step 7: Verify all targets are approved
        for (final target in targets) {
          final approvedTarget =
              appProvider.salesTargets.firstWhere((t) => t.id == target.id);
          expect(approvedTarget.status, equals(TargetStatus.approved));
        }
      });
    });
  });
}
