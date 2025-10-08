import 'package:flutter_test/flutter_test.dart';
import 'package:bonuses/models/sales_target.dart';
import 'mocks/testable_app_provider.dart';
import 'mocks/mock_storage_service.dart';

void main() {
  group('Points System Tests', () {
    late TestableAppProvider appProvider;

    setUp(() async {
      appProvider = TestableAppProvider();
      await appProvider.initialize();
    });

    tearDown(() async {
      await MockStorageService.clearAllData();
    });

    group('Points Calculation Tests', () {
      test('getPointsForEffectivePercent calculates correctly for 100%',
          () async {
        await appProvider.login('admin@store.com', 'password123');

        // Test 100% achievement (exactly on target)
        final points100 = appProvider.getPointsForEffectivePercent(100.0);
        expect(points100, equals(10)); // Default rule for 100%
      });

      test('getPointsForEffectivePercent calculates correctly for 110%',
          () async {
        await appProvider.login('admin@store.com', 'password123');

        // Test 110% achievement (10% above target)
        final points110 = appProvider.getPointsForEffectivePercent(110.0);
        expect(points110, equals(15)); // Default rule for 110%
      });

      test('getPointsForEffectivePercent calculates correctly for 120%',
          () async {
        await appProvider.login('admin@store.com', 'password123');

        // Test 120% achievement (20% above target)
        final points120 = appProvider.getPointsForEffectivePercent(120.0);
        expect(points120, equals(20)); // Default rule for 120%
      });

      test('getPointsForEffectivePercent calculates correctly for 150%',
          () async {
        await appProvider.login('admin@store.com', 'password123');

        // Test 150% achievement (50% above target)
        final points150 = appProvider.getPointsForEffectivePercent(150.0);
        expect(points150, equals(30)); // Default rule for 150%
      });

      test('getPointsForEffectivePercent calculates correctly for 200%',
          () async {
        await appProvider.login('admin@store.com', 'password123');

        // Test 200% achievement (100% above target)
        final points200 = appProvider.getPointsForEffectivePercent(200.0);
        expect(points200, equals(50)); // Default rule for 200%
      });

      test('getPointsForEffectivePercent handles edge cases', () async {
        await appProvider.login('admin@store.com', 'password123');

        // Test 0% achievement
        final points0 = appProvider.getPointsForEffectivePercent(0.0);
        expect(points0, equals(0));

        // Test 50% achievement (below target)
        final points50 = appProvider.getPointsForEffectivePercent(50.0);
        expect(points50, equals(0));

        // Test very high percentage
        final points500 = appProvider.getPointsForEffectivePercent(500.0);
        expect(points500, equals(50)); // Should cap at maximum
      });
    });

    group('Points Validation Tests', () {
      test('updateUserPoints prevents negative points', () async {
        await appProvider.login('admin@store.com', 'password123');

        // Get a user to test with
        final users = await appProvider.getUsers();
        final testUser = users.firstWhere((u) => u.role.name == 'employee');

        // Try to remove more points than the user has
        final initialPoints = appProvider.getUserTotalPoints(testUser.id);
        print('DEBUG: Initial points for ${testUser.name}: $initialPoints');

        // Attempt to remove more points than available
        await appProvider.updateUserPoints(testUser.id, -(initialPoints + 100),
            'Test negative points prevention');

        // Points should remain unchanged
        final finalPoints = appProvider.getUserTotalPoints(testUser.id);
        expect(finalPoints, equals(initialPoints));
      });

      test('updateUserPoints allows valid positive changes', () async {
        await appProvider.login('admin@store.com', 'password123');

        // Get a user to test with
        final users = await appProvider.getUsers();
        final testUser = users.firstWhere((u) => u.role.name == 'employee');

        final initialPoints = appProvider.getUserTotalPoints(testUser.id);

        // Add 50 points
        await appProvider.updateUserPoints(
            testUser.id, 50, 'Test positive points addition');

        final finalPoints = appProvider.getUserTotalPoints(testUser.id);
        expect(finalPoints, equals(initialPoints + 50));
      });

      test('updateUserPoints allows valid negative changes within limits',
          () async {
        await appProvider.login('admin@store.com', 'password123');

        // Get a user to test with
        final users = await appProvider.getUsers();
        final testUser = users.firstWhere((u) => u.role.name == 'employee');

        // First add some points
        await appProvider.updateUserPoints(
            testUser.id, 100, 'Add points for testing');

        final pointsAfterAddition = appProvider.getUserTotalPoints(testUser.id);

        // Then remove some points (but not all)
        await appProvider.updateUserPoints(
            testUser.id, -30, 'Remove some points');

        final finalPoints = appProvider.getUserTotalPoints(testUser.id);
        expect(finalPoints, equals(pointsAfterAddition - 30));
      });
    });

    group('Points Transaction Tests', () {
      test('Points transactions are created correctly for earned points',
          () async {
        await appProvider.login('admin@store.com', 'password123');

        // Get a user to test with
        final users = await appProvider.getUsers();
        final testUser = users.firstWhere((u) => u.role.name == 'employee');

        // Add points
        await appProvider.updateUserPoints(
            testUser.id, 25, 'Test earned points transaction');

        // Check that transaction was created
        final transactions = appProvider.getUserPointsTransactions(testUser.id);
        final earnedTransaction = transactions.firstWhere(
            (t) => t.description == 'Test earned points transaction');

        expect(earnedTransaction.type.name, equals('earned'));
        expect(earnedTransaction.points, equals(25));
        expect(earnedTransaction.userId, equals(testUser.id));
      });

      test('Points transactions are created correctly for redeemed points',
          () async {
        await appProvider.login('admin@store.com', 'password123');

        // Get a user to test with
        final users = await appProvider.getUsers();
        final testUser = users.firstWhere((u) => u.role.name == 'employee');

        // First add some points
        await appProvider.updateUserPoints(
            testUser.id, 100, 'Add points for redemption test');

        // Then remove points
        await appProvider.updateUserPoints(
            testUser.id, -15, 'Test redeemed points transaction');

        // Check that transaction was created
        final transactions = appProvider.getUserPointsTransactions(testUser.id);
        final redeemedTransaction = transactions.firstWhere(
            (t) => t.description == 'Test redeemed points transaction');

        expect(redeemedTransaction.type.name, equals('redeemed'));
        expect(redeemedTransaction.points, equals(15));
        expect(redeemedTransaction.userId, equals(testUser.id));
      });

      test('getUserTotalPoints calculates correctly from transactions',
          () async {
        await appProvider.login('admin@store.com', 'password123');

        // Get a user to test with
        final users = await appProvider.getUsers();
        final testUser = users.firstWhere((u) => u.role.name == 'employee');

        // Clear any existing points by removing all
        final initialPoints = appProvider.getUserTotalPoints(testUser.id);
        if (initialPoints > 0) {
          await appProvider.updateUserPoints(
              testUser.id, -initialPoints, 'Clear existing points');
        }

        // Add multiple transactions
        await appProvider.updateUserPoints(testUser.id, 50, 'First addition');
        await appProvider.updateUserPoints(testUser.id, 30, 'Second addition');
        await appProvider.updateUserPoints(testUser.id, -20, 'First deduction');
        await appProvider.updateUserPoints(testUser.id, 10, 'Third addition');

        // Calculate expected total: 50 + 30 - 20 + 10 = 70
        const expectedTotal = 50 + 30 - 20 + 10;
        final actualTotal = appProvider.getUserTotalPoints(testUser.id);

        expect(actualTotal, equals(expectedTotal));
      });
    });

    group('Sales Target Points Integration Tests', () {
      test('Approving met target awards correct points', () async {
        await appProvider.login('admin@store.com', 'password123');

        // Get a user to test with
        final users = await appProvider.getUsers();
        final testUser = users.firstWhere((u) => u.role.name == 'employee');

        // Create a target that will be met
        final target = SalesTarget(
          id: 'test_target_${DateTime.now().millisecondsSinceEpoch}',
          date: DateTime.now(),
          targetAmount: 1000.0,
          actualAmount: 1200.0, // 120% of target
          createdAt: DateTime.now(),
          createdBy: 'admin1',
          assignedEmployeeId: testUser.id,
          assignedEmployeeName: testUser.name,
          assignedWorkplaceId: 'wp1',
          assignedWorkplaceName: 'Test Store',
          status: TargetStatus.submitted,
          isSubmitted: true,
        );

        // Add the target
        await appProvider.addSalesTarget(target);

        // Get initial points
        final initialPoints = appProvider.getUserTotalPoints(testUser.id);

        // Approve the target
        await appProvider.approveSalesTarget(target.id, 'admin1');

        // Check target status
        final approvedTarget =
            appProvider.salesTargets.firstWhere((t) => t.id == target.id);
        print(
            'DEBUG: Target isMet: ${approvedTarget.isMet}, pointsAwarded: ${approvedTarget.pointsAwarded}');

        // Check that points were awarded correctly
        final finalPoints = appProvider.getUserTotalPoints(testUser.id);
        final pointsAwarded = finalPoints - initialPoints;

        print(
            'DEBUG: Initial points: $initialPoints, Final points: $finalPoints, Points awarded: $pointsAwarded');

        // Should award 20 points for 120% achievement
        expect(pointsAwarded, equals(20));
      });

      test('Approving unmet target awards no points', () async {
        await appProvider.login('admin@store.com', 'password123');

        // Get a user to test with
        final users = await appProvider.getUsers();
        final testUser = users.firstWhere((u) => u.role.name == 'employee');

        // Create a target that will not be met
        final target = SalesTarget(
          id: 'test_target_unmet_${DateTime.now().millisecondsSinceEpoch}',
          date: DateTime.now(),
          targetAmount: 1000.0,
          actualAmount: 800.0, // 80% of target (not met)
          createdAt: DateTime.now(),
          createdBy: 'admin1',
          assignedEmployeeId: testUser.id,
          assignedEmployeeName: testUser.name,
          assignedWorkplaceId: 'wp1',
          assignedWorkplaceName: 'Test Store',
          status: TargetStatus.submitted,
          isSubmitted: true,
        );

        // Add the target
        await appProvider.addSalesTarget(target);

        // Get initial points
        final initialPoints = appProvider.getUserTotalPoints(testUser.id);

        // Approve the target
        await appProvider.approveSalesTarget(target.id, 'admin1');

        // Check that no points were awarded
        final finalPoints = appProvider.getUserTotalPoints(testUser.id);
        expect(finalPoints, equals(initialPoints));
      });
    });

    group('Edge Cases and Error Handling', () {
      test('Handles zero points correctly', () async {
        await appProvider.login('admin@store.com', 'password123');

        // Get a user to test with
        final users = await appProvider.getUsers();
        final testUser = users.firstWhere((u) => u.role.name == 'employee');

        // Try to remove exactly the amount the user has
        final initialPoints = appProvider.getUserTotalPoints(testUser.id);
        if (initialPoints > 0) {
          await appProvider.updateUserPoints(
              testUser.id, -initialPoints, 'Remove all points');

          final finalPoints = appProvider.getUserTotalPoints(testUser.id);
          expect(finalPoints, equals(0));
        }
      });

      test('Handles large point values correctly', () async {
        await appProvider.login('admin@store.com', 'password123');

        // Get a user to test with
        final users = await appProvider.getUsers();
        final testUser = users.firstWhere((u) => u.role.name == 'employee');

        // Add a large number of points
        const largeAmount = 10000;
        await appProvider.updateUserPoints(
            testUser.id, largeAmount, 'Add large amount of points');

        final finalPoints = appProvider.getUserTotalPoints(testUser.id);
        expect(finalPoints, greaterThanOrEqualTo(largeAmount));
      });
    });
  });
}
