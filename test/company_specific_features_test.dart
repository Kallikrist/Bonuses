import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bonuses/models/user.dart';
import 'package:bonuses/models/company.dart';
import 'package:bonuses/models/bonus.dart';
import 'package:bonuses/models/points_rules.dart';
import 'package:bonuses/providers/app_provider.dart';
import 'package:bonuses/services/storage_service.dart';

void main() {
  group('Company-Specific Features Tests', () {
    late AppProvider appProvider;

    setUp(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
      await StorageService.clearAllData();
      appProvider = AppProvider();
      await appProvider.initialize();
    });

    group('Company-Specific Points Tests', () {
      test('Points are isolated between companies', () async {
        // Create two companies
        final company1 = Company(
          id: 'company1',
          name: 'Company One',
          address: '123 Test St',
          adminUserId: 'admin1',
          createdAt: DateTime.now(),
        );
        final company2 = Company(
          id: 'company2',
          name: 'Company Two',
          address: '456 Test Ave',
          adminUserId: 'admin2',
          createdAt: DateTime.now(),
        );

        await appProvider.addCompany(company1);
        await appProvider.addCompany(company2);

        // Create user in both companies
        final user = User(
          id: 'user1',
          name: 'Test User',
          email: 'test@example.com',
          phoneNumber: '1234567890',
          role: UserRole.employee,
          companyIds: [company1.id, company2.id],
          companyNames: [company1.name, company2.name],
          primaryCompanyId: company1.id,
          companyPoints: {},
          createdAt: DateTime.now(),
          companyRoles: {
            company1.id: 'employee',
            company2.id: 'employee',
          },
        );

        await appProvider.addUser(user);

        // Add 100 points to company1
        await appProvider.updateUserPoints(
          user.id,
          100,
          'Test points for company 1',
          companyId: company1.id,
        );

        // Add 200 points to company2
        await appProvider.updateUserPoints(
          user.id,
          200,
          'Test points for company 2',
          companyId: company2.id,
        );

        // Verify points are separate
        final company1Points =
            appProvider.getUserCompanyPoints(user.id, company1.id);
        final company2Points =
            appProvider.getUserCompanyPoints(user.id, company2.id);

        expect(company1Points, equals(100));
        expect(company2Points, equals(200));

        // Remove 50 points from company1
        await appProvider.updateUserPoints(
          user.id,
          -50,
          'Remove points from company 1',
          companyId: company1.id,
        );

        // Verify only company1 points changed
        final company1PointsAfter =
            appProvider.getUserCompanyPoints(user.id, company1.id);
        final company2PointsAfter =
            appProvider.getUserCompanyPoints(user.id, company2.id);

        expect(company1PointsAfter, equals(50));
        expect(company2PointsAfter, equals(200)); // Should remain unchanged
      });

      test('Bonus is associated with correct company', () async {
        final company = Company(
          id: 'test_company',
          name: 'Test Company',
          address: '123 Test St',
          adminUserId: 'admin1',
          createdAt: DateTime.now(),
        );

        await appProvider.addCompany(company);

        final bonus = Bonus(
          id: 'bonus1',
          name: 'Test Bonus',
          description: 'Test Description',
          pointsRequired: 50,
          status: BonusStatus.available,
          companyId: company.id,
          createdAt: DateTime.now(),
        );

        await appProvider.addBonus(bonus);

        // Verify bonus is associated with correct company
        final bonuses = appProvider.getAvailableBonuses(company.id);
        expect(bonuses.length, equals(1));
        expect(bonuses.first.companyId, equals(company.id));
        expect(bonuses.first.name, equals('Test Bonus'));
      });
    });

    group('Company-Specific Roles Tests', () {
      test('User can have different roles in different companies', () async {
        final company1 = Company(
          id: 'company1',
          name: 'Company One',
          address: '123 Test St',
          adminUserId: 'user1',
          createdAt: DateTime.now(),
        );
        final company2 = Company(
          id: 'company2',
          name: 'Company Two',
          address: '456 Test Ave',
          adminUserId: 'admin2',
          createdAt: DateTime.now(),
        );

        await appProvider.addCompany(company1);
        await appProvider.addCompany(company2);

        // Create user who is admin in company1, employee in company2
        final user = User(
          id: 'user1',
          name: 'Multi-Role User',
          email: 'multi@example.com',
          phoneNumber: '1234567890',
          role: UserRole.admin,
          companyIds: [company1.id, company2.id],
          companyNames: [company1.name, company2.name],
          primaryCompanyId: company1.id,
          companyPoints: {},
          createdAt: DateTime.now(),
          companyRoles: {
            company1.id: 'admin',
            company2.id: 'employee',
          },
        );

        await appProvider.addUser(user);
        await StorageService.setCurrentUser(user);
        await appProvider.initialize();

        // Verify role in company1
        expect(user.getRoleForCompany(company1.id), equals(UserRole.admin));
        expect(appProvider.isAdmin, isTrue);

        // Switch to company2
        final updatedUser = user.copyWith(primaryCompanyId: company2.id);
        await appProvider.updateUser(updatedUser);
        await StorageService.setCurrentUser(updatedUser);
        await appProvider.initialize();

        // Verify role in company2
        expect(updatedUser.getRoleForCompany(company2.id),
            equals(UserRole.employee));
        expect(appProvider.isAdmin, isFalse);
      });
    });

    group('Company-Specific Points Rules Tests', () {
      test('Points rules are isolated between companies', () async {
        final company1 = Company(
          id: 'company1',
          name: 'Company One',
          address: '123 Test St',
          adminUserId: 'admin1',
          createdAt: DateTime.now(),
        );
        final company2 = Company(
          id: 'company2',
          name: 'Company Two',
          address: '456 Test Ave',
          adminUserId: 'admin2',
          createdAt: DateTime.now(),
        );

        await appProvider.addCompany(company1);
        await appProvider.addCompany(company2);

        // Create different rules for each company
        final rules1 = PointsRules(
          pointsForMet: 10,
          pointsForTenPercentAbove: 15,
          pointsForDoubleTarget: 30,
          companyId: company1.id,
        );

        final rules2 = PointsRules(
          pointsForMet: 20,
          pointsForTenPercentAbove: 25,
          pointsForDoubleTarget: 50,
          companyId: company2.id,
        );

        await appProvider.updatePointsRules(rules1, company1.id);
        await appProvider.updatePointsRules(rules2, company2.id);

        // Verify rules are different
        final loadedRules1 = appProvider.getPointsRules(company1.id);
        final loadedRules2 = appProvider.getPointsRules(company2.id);

        expect(loadedRules1.pointsForMet, equals(10));
        expect(loadedRules2.pointsForMet, equals(20));

        // Verify points calculation uses correct rules
        final points1For100Percent =
            appProvider.getPointsForEffectivePercent(100.0, company1.id);
        final points2For100Percent =
            appProvider.getPointsForEffectivePercent(100.0, company2.id);

        expect(points1For100Percent, equals(10));
        expect(points2For100Percent, equals(20));
      });
    });

    group('Company-Specific Bonuses Tests', () {
      test('Available bonuses are filtered by company', () async {
        final company1 = Company(
          id: 'company1',
          name: 'Company One',
          address: '123 Test St',
          adminUserId: 'admin1',
          createdAt: DateTime.now(),
        );
        final company2 = Company(
          id: 'company2',
          name: 'Company Two',
          address: '456 Test Ave',
          adminUserId: 'admin2',
          createdAt: DateTime.now(),
        );

        await appProvider.addCompany(company1);
        await appProvider.addCompany(company2);

        // Create bonuses for different companies
        final bonus1 = Bonus(
          id: 'bonus1',
          name: 'Company 1 Bonus',
          description: 'For Company 1',
          pointsRequired: 50,
          status: BonusStatus.available,
          companyId: company1.id,
          createdAt: DateTime.now(),
        );

        final bonus2 = Bonus(
          id: 'bonus2',
          name: 'Company 2 Bonus',
          description: 'For Company 2',
          pointsRequired: 75,
          status: BonusStatus.available,
          companyId: company2.id,
          createdAt: DateTime.now(),
        );

        await appProvider.addBonus(bonus1);
        await appProvider.addBonus(bonus2);

        // Get available bonuses for company1
        final company1Bonuses = appProvider.getAvailableBonuses(company1.id);
        final company2Bonuses = appProvider.getAvailableBonuses(company2.id);

        // Verify filtering
        expect(company1Bonuses.length, equals(1));
        expect(company1Bonuses.first.name, equals('Company 1 Bonus'));

        expect(company2Bonuses.length, equals(1));
        expect(company2Bonuses.first.name, equals('Company 2 Bonus'));
      });

      test('Bonuses can be filtered by company or viewed globally', () async {
        final company1 = Company(
          id: 'company1',
          name: 'Company One',
          address: '123 Test St',
          adminUserId: 'admin1',
          createdAt: DateTime.now(),
        );
        final company2 = Company(
          id: 'company2',
          name: 'Company Two',
          address: '456 Test Ave',
          adminUserId: 'admin2',
          createdAt: DateTime.now(),
        );

        await appProvider.addCompany(company1);
        await appProvider.addCompany(company2);

        // Create bonuses for different companies
        final bonus1 = Bonus(
          id: 'bonus1',
          name: 'Company 1 Bonus',
          description: 'For Company 1',
          pointsRequired: 50,
          status: BonusStatus.redeemed,
          companyId: company1.id,
          createdAt: DateTime.now(),
          redeemedBy: 'user1',
        );

        final bonus2 = Bonus(
          id: 'bonus2',
          name: 'Company 2 Bonus',
          description: 'For Company 2',
          pointsRequired: 50,
          status: BonusStatus.redeemed,
          companyId: company2.id,
          createdAt: DateTime.now(),
          redeemedBy: 'user1',
        );

        await appProvider.addBonus(bonus1);
        await appProvider.addBonus(bonus2);

        // Get redeemed bonuses globally (no company filter)
        final allRedeemedBonuses =
            appProvider.getUserRedeemedBonuses('user1', null);

        // Should see both redeemed bonuses
        expect(allRedeemedBonuses.length, equals(2));

        // Get redeemed bonuses for company1 only
        final company1RedeemedBonuses =
            appProvider.getUserRedeemedBonuses('user1', company1.id);
        expect(company1RedeemedBonuses.length, equals(1));
        expect(company1RedeemedBonuses.first.name, equals('Company 1 Bonus'));

        // Get redeemed bonuses for company2 only
        final company2RedeemedBonuses =
            appProvider.getUserRedeemedBonuses('user1', company2.id);
        expect(company2RedeemedBonuses.length, equals(1));
        expect(company2RedeemedBonuses.first.name, equals('Company 2 Bonus'));
      });
    });

    group('Search and Filter Tests', () {
      test('Employee search filters by name', () async {
        final company = Company(
          id: 'test_company',
          name: 'Test Company',
          address: '123 Test St',
          adminUserId: 'admin1',
          createdAt: DateTime.now(),
        );

        await appProvider.addCompany(company);

        // Create multiple users
        final users = [
          User(
            id: 'user1',
            name: 'John Doe',
            email: 'john@example.com',
            phoneNumber: '1234567890',
            role: UserRole.employee,
            companyIds: [company.id],
            companyNames: [company.name],
            primaryCompanyId: company.id,
            companyPoints: {},
            createdAt: DateTime.now(),
            companyRoles: {company.id: 'employee'},
          ),
          User(
            id: 'user2',
            name: 'Jane Smith',
            email: 'jane@example.com',
            phoneNumber: '0987654321',
            role: UserRole.employee,
            companyIds: [company.id],
            companyNames: [company.name],
            primaryCompanyId: company.id,
            companyPoints: {},
            createdAt: DateTime.now(),
            companyRoles: {company.id: 'employee'},
          ),
          User(
            id: 'user3',
            name: 'Mike Johnson',
            email: 'mike@example.com',
            phoneNumber: '5555555555',
            role: UserRole.employee,
            companyIds: [company.id],
            companyNames: [company.name],
            primaryCompanyId: company.id,
            companyPoints: {},
            createdAt: DateTime.now(),
            companyRoles: {company.id: 'employee'},
          ),
        ];

        for (var user in users) {
          await appProvider.addUser(user);
        }

        // Get all users
        final allUsers = await appProvider.getUsers();
        final companyUsers =
            allUsers.where((u) => u.companyIds.contains(company.id)).toList();

        expect(companyUsers.length, equals(3));

        // Simulate search for "John"
        final searchResults = companyUsers
            .where((u) => u.name.toLowerCase().contains('john'.toLowerCase()))
            .toList();

        expect(searchResults.length, equals(2)); // John Doe and Mike Johnson
        expect(searchResults.any((u) => u.name == 'John Doe'), isTrue);
        expect(searchResults.any((u) => u.name == 'Mike Johnson'), isTrue);
      });

      test('Role filter separates admins and employees', () async {
        final company = Company(
          id: 'test_company',
          name: 'Test Company',
          address: '123 Test St',
          adminUserId: 'admin1',
          createdAt: DateTime.now(),
        );

        await appProvider.addCompany(company);

        // Create admin and employee users
        final admin = User(
          id: 'admin1',
          name: 'Admin User',
          email: 'admin@example.com',
          phoneNumber: '1111111111',
          role: UserRole.admin,
          companyIds: [company.id],
          companyNames: [company.name],
          primaryCompanyId: company.id,
          companyPoints: {},
          createdAt: DateTime.now(),
          companyRoles: {company.id: 'admin'},
        );

        final employee = User(
          id: 'employee1',
          name: 'Employee User',
          email: 'employee@example.com',
          phoneNumber: '2222222222',
          role: UserRole.employee,
          companyIds: [company.id],
          companyNames: [company.name],
          primaryCompanyId: company.id,
          companyPoints: {},
          createdAt: DateTime.now(),
          companyRoles: {company.id: 'employee'},
        );

        await appProvider.addUser(admin);
        await appProvider.addUser(employee);

        final allUsers = await appProvider.getUsers();
        final companyUsers =
            allUsers.where((u) => u.companyIds.contains(company.id)).toList();

        // Filter by admin role
        final admins = companyUsers
            .where((u) => u.getRoleForCompany(company.id) == UserRole.admin)
            .toList();

        // Filter by employee role
        final employees = companyUsers
            .where((u) => u.getRoleForCompany(company.id) == UserRole.employee)
            .toList();

        expect(admins.length, equals(1));
        expect(admins.first.name, equals('Admin User'));

        expect(employees.length, equals(1));
        expect(employees.first.name, equals('Employee User'));
      });
    });

    group('Import Employees Tests', () {
      test('Imported employees are assigned to correct company', () async {
        final company = Company(
          id: 'test_company',
          name: 'Test Company',
          address: '123 Test St',
          adminUserId: 'admin1',
          createdAt: DateTime.now(),
        );

        await appProvider.addCompany(company);

        final admin = User(
          id: 'admin1',
          name: 'Admin User',
          email: 'admin@example.com',
          phoneNumber: '1111111111',
          role: UserRole.admin,
          companyIds: [company.id],
          companyNames: [company.name],
          primaryCompanyId: company.id,
          companyPoints: {},
          createdAt: DateTime.now(),
          companyRoles: {company.id: 'admin'},
        );

        await appProvider.addUser(admin);

        // Simulate importing an employee
        final newEmployee = User(
          id: 'imported1',
          name: 'Imported Employee',
          email: 'imported@example.com',
          phoneNumber: '3333333333',
          role: UserRole.employee,
          companyIds: [company.id],
          companyNames: [company.name],
          primaryCompanyId: company.id,
          companyPoints: {company.id: 100}, // Initial points
          createdAt: DateTime.now(),
          companyRoles: {company.id: 'employee'},
        );

        await appProvider.addUser(newEmployee);

        // Verify employee is in company
        final users = await appProvider.getUsers();
        final importedUser = users.firstWhere((u) => u.id == 'imported1');

        expect(importedUser.companyIds.contains(company.id), isTrue);
        expect(importedUser.getRoleForCompany(company.id),
            equals(UserRole.employee));
        expect(importedUser.getCompanyPoints(company.id), equals(100));
      });

      test('Duplicate employees in same company are skipped', () async {
        final company = Company(
          id: 'test_company',
          name: 'Test Company',
          address: '123 Test St',
          adminUserId: 'admin1',
          createdAt: DateTime.now(),
        );

        await appProvider.addCompany(company);

        // Create existing employee
        final existingEmployee = User(
          id: 'user1',
          name: 'Existing User',
          email: 'existing@example.com',
          phoneNumber: '1234567890',
          role: UserRole.employee,
          companyIds: [company.id],
          companyNames: [company.name],
          primaryCompanyId: company.id,
          companyPoints: {},
          createdAt: DateTime.now(),
          companyRoles: {company.id: 'employee'},
        );

        await appProvider.addUser(existingEmployee);

        // Try to import same email to same company
        final users = await appProvider.getUsers();
        final duplicateCheck = users
            .where((u) =>
                u.email == 'existing@example.com' &&
                u.companyIds.contains(company.id))
            .toList();

        expect(duplicateCheck.length, equals(1)); // Should only have one
      });
    });

    group('Company Switching Tests', () {
      test('Switching companies preserves company memberships', () async {
        final company1 = Company(
          id: 'company1',
          name: 'Company One',
          address: '123 Test St',
          adminUserId: 'user1',
          createdAt: DateTime.now(),
        );
        final company2 = Company(
          id: 'company2',
          name: 'Company Two',
          address: '456 Test Ave',
          adminUserId: 'admin2',
          createdAt: DateTime.now(),
        );

        await appProvider.addCompany(company1);
        await appProvider.addCompany(company2);

        final user = User(
          id: 'user1',
          name: 'Test User',
          email: 'test@example.com',
          phoneNumber: '1234567890',
          role: UserRole.admin,
          companyIds: [company1.id, company2.id],
          companyNames: [company1.name, company2.name],
          primaryCompanyId: company1.id,
          companyPoints: {
            company1.id: 100,
            company2.id: 200,
          },
          createdAt: DateTime.now(),
          companyRoles: {
            company1.id: 'admin',
            company2.id: 'employee',
          },
        );

        await appProvider.addUser(user);
        await StorageService.setCurrentUser(user);
        await appProvider.initialize();

        // Switch to company2
        final updatedUser = user.copyWith(primaryCompanyId: company2.id);
        await appProvider.updateUser(updatedUser);

        // Verify all companies are still there
        final reloadedUser =
            (await appProvider.getUsers()).firstWhere((u) => u.id == user.id);
        expect(reloadedUser.companyIds.length, equals(2));
        expect(reloadedUser.companyIds.contains(company1.id), isTrue);
        expect(reloadedUser.companyIds.contains(company2.id), isTrue);

        // Verify points for both companies are preserved
        expect(reloadedUser.getCompanyPoints(company1.id), equals(100));
        expect(reloadedUser.getCompanyPoints(company2.id), equals(200));
      });
    });
  });
}
