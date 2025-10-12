import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bonuses/providers/app_provider.dart';
import 'package:bonuses/models/user.dart';
import 'package:bonuses/models/sales_target.dart';
import 'package:bonuses/models/points_transaction.dart';
import 'package:bonuses/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CompanyId Guards Tests', () {
    late AppProvider appProvider;
    const String companyId = 'company_test';

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await StorageService.clearAllData();
      appProvider = AppProvider();
      await appProvider.initialize();
    });

    test('updateUserPoints recovers from null companyId using primaryCompanyId', () async {
      // Seed user with valid primaryCompanyId
      final users = [
        User(
          id: 'user1',
          name: 'Test User',
          email: 'test@test.com',
          role: UserRole.employee,
          primaryCompanyId: companyId,
          companyIds: [companyId],
          companyRoles: {companyId: 'employee'},
          createdAt: DateTime.now(),
        ),
      ];
      await StorageService.saveUsers(users);
      await appProvider.initialize();

      // Update points with null companyId - should recover
      await appProvider.updateUserPoints(
        'user1',
        10,
        'Test points',
        companyId: null,
      );

      // Verify points were awarded using recovered companyId
      final points = appProvider.getUserCompanyPoints('user1', companyId);
      expect(points, 10);

      // Verify transaction was created with recovered companyId
      final transactions = await StorageService.getPointsTransactions();
      final userTransactions = transactions.where((t) => t.userId == 'user1').toList();
      expect(userTransactions.isNotEmpty, true);
      expect(userTransactions.last.companyId, companyId);
    });

    test('updateUserPoints fails gracefully when companyId null and no primary company', () async {
      // Seed user without primaryCompanyId
      final users = [
        User(
          id: 'user1',
          name: 'Test User',
          email: 'test@test.com',
          role: UserRole.employee,
          primaryCompanyId: '',
          companyIds: [],
          companyRoles: {},
          createdAt: DateTime.now(),
        ),
      ];
      await StorageService.saveUsers(users);
      await appProvider.initialize();

      final beforeTransactions = await StorageService.getPointsTransactions();
      final beforeCount = beforeTransactions.where((t) => t.userId == 'user1').length;

      // Try to update points with null companyId - should fail gracefully
      await appProvider.updateUserPoints(
        'user1',
        10,
        'Test points',
        companyId: null,
      );

      // Verify no new transactions were created
      final afterTransactions = await StorageService.getPointsTransactions();
      final afterCount = afterTransactions.where((t) => t.userId == 'user1').length;
      expect(afterCount, beforeCount);
    });

    test('updateUserPoints recovers from empty string companyId', () async {
      // Seed user with valid primaryCompanyId
      final users = [
        User(
          id: 'user1',
          name: 'Test User',
          email: 'test@test.com',
          role: UserRole.employee,
          primaryCompanyId: companyId,
          companyIds: [companyId],
          companyRoles: {companyId: 'employee'},
          createdAt: DateTime.now(),
        ),
      ];
      await StorageService.saveUsers(users);
      await appProvider.initialize();

      // Update points with empty companyId - should recover
      await appProvider.updateUserPoints(
        'user1',
        15,
        'Test points',
        companyId: '',
      );

      // Verify points were awarded using recovered companyId
      final points = appProvider.getUserCompanyPoints('user1', companyId);
      expect(points, 15);
    });

    test('Target with valid companyId allows normal points flow', () async {
      // Seed users
      final users = [
        User(
          id: 'user1',
          name: 'User One',
          email: 'user1@test.com',
          role: UserRole.employee,
          primaryCompanyId: companyId,
          companyIds: [companyId],
          companyRoles: {companyId: 'employee'},
          createdAt: DateTime.now(),
        ),
        User(
          id: 'user2',
          name: 'User Two',
          email: 'user2@test.com',
          role: UserRole.employee,
          primaryCompanyId: companyId,
          companyIds: [companyId],
          companyRoles: {companyId: 'employee'},
          createdAt: DateTime.now(),
        ),
      ];
      await StorageService.saveUsers(users);

      // Create an approved target with valid companyId
      final target = SalesTarget(
        id: 'target_valid',
        targetAmount: 1000,
        actualAmount: 1100,
        date: DateTime.now(),
        companyId: companyId, // Valid companyId
        status: TargetStatus.approved,
        isSubmitted: true,
        isApproved: true,
        collaborativeEmployeeIds: ['user1', 'user2'],
        collaborativeEmployeeNames: ['User One', 'User Two'],
        pointsAwarded: 10,
        createdAt: DateTime.now(),
        createdBy: 'admin',
      );

      await StorageService.addSalesTarget(target);
      await appProvider.initialize();

      // Seed initial points
      await appProvider.updateUserPoints(
        'user1',
        50,
        'Initial balance',
        companyId: companyId,
      );
      await appProvider.updateUserPoints(
        'user2',
        50,
        'Initial balance',
        companyId: companyId,
      );

      // Remove user2 from target - should withdraw points
      final updatedTarget = target.copyWith(
        collaborativeEmployeeIds: ['user1'],
        collaborativeEmployeeNames: ['User One'],
      );
      await appProvider.updateSalesTarget(updatedTarget);

      // Verify points were withdrawn from user2
      final user2Points = appProvider.getUserCompanyPoints('user2', companyId);
      expect(user2Points, 40); // 50 - 10 = 40

      // Verify adjustment transaction was created with valid companyId
      final transactions = await StorageService.getPointsTransactions();
      final adjustments = transactions.where(
        (t) => t.type == PointsTransactionType.adjustment && t.userId == 'user2'
      ).toList();
      expect(adjustments.isNotEmpty, true);
      expect(adjustments.last.companyId, companyId);
    });

    test('CompanyId guard prevents data corruption in edge cases', () async {
      // This test verifies that even if someone manually creates a
      // target with null/empty companyId, the guards prevent point adjustments
      
      final users = [
        User(
          id: 'user1',
          name: 'User One',
          email: 'user1@test.com',
          role: UserRole.employee,
          primaryCompanyId: companyId,
          companyIds: [companyId],
          companyRoles: {companyId: 'employee'},
          createdAt: DateTime.now(),
        ),
      ];
      await StorageService.saveUsers(users);

      // Create target with empty companyId (simulating corrupted data)
      final target = SalesTarget(
        id: 'target_corrupt',
        targetAmount: 1000,
        actualAmount: 1100,
        date: DateTime.now(),
        companyId: '', // Corrupted/empty
        status: TargetStatus.approved,
        isSubmitted: true,
        isApproved: true,
        collaborativeEmployeeIds: ['user1'],
        collaborativeEmployeeNames: ['User One'],
        pointsAwarded: 10,
        createdAt: DateTime.now(),
        createdBy: 'admin',
      );

      await StorageService.addSalesTarget(target);
      await appProvider.initialize();

      final beforeTransactions = await StorageService.getPointsTransactions();
      final beforeCount = beforeTransactions.length;

      // Try to update target - guard should prevent point adjustments
      final updatedTarget = target.copyWith(
        actualAmount: 1200, // Change actual amount
      );
      await appProvider.updateSalesTarget(updatedTarget);

      // Verify no new transactions were created (guard prevented it)
      final afterTransactions = await StorageService.getPointsTransactions();
      expect(afterTransactions.length, beforeCount);
    });
  });
}
