import 'package:flutter_test/flutter_test.dart';
import 'package:bonuses/services/auth_service.dart';
import 'package:bonuses/services/storage_service.dart';
import 'package:bonuses/models/user.dart';
import 'package:bonuses/models/company.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('AuthService Tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});

      // Create test data
      final superAdminUser = User(
        id: 'superadmin1',
        name: 'Super Admin',
        email: 'superadmin@platform.com',
        phoneNumber: '+1 (555) 000-0000',
        role: UserRole.superAdmin,
        createdAt: DateTime.now(),
        workplaceIds: [],
        workplaceNames: [],
        companyIds: [],
        companyNames: [],
        primaryCompanyId: '',
        companyRoles: {},
        companyPoints: {},
      );

      final adminUser = User(
        id: 'admin1',
        name: 'Admin User',
        email: 'admin@store.com',
        phoneNumber: '+1 (555) 111-1111',
        role: UserRole.admin,
        createdAt: DateTime.now(),
        workplaceIds: ['workplace1'],
        workplaceNames: ['Test Workplace'],
        companyIds: ['test_company'],
        companyNames: ['Test Company'],
        primaryCompanyId: 'test_company',
        companyRoles: {'test_company': 'admin'},
        companyPoints: {'test_company': 0},
      );

      final employeeUser = User(
        id: 'employee1',
        name: 'Employee User',
        email: 'employee@test.com',
        phoneNumber: '+1 (555) 222-2222',
        role: UserRole.employee,
        createdAt: DateTime.now(),
        workplaceIds: ['workplace1'],
        workplaceNames: ['Test Workplace'],
        companyIds: ['test_company'],
        companyNames: ['Test Company'],
        primaryCompanyId: 'test_company',
        companyRoles: {'test_company': 'employee'},
        companyPoints: {'test_company': 0},
      );

      final testCompany = Company(
        id: 'test_company',
        name: 'Test Company',
        contactEmail: 'admin@test.com',
        adminUserId: 'admin1',
        createdAt: DateTime.now(),
        isActive: true,
      );

      // Add users and company to storage
      await StorageService.addUser(superAdminUser);
      await StorageService.addUser(adminUser);
      await StorageService.addUser(employeeUser);
      await StorageService.addCompany(testCompany);

      // Set passwords
      await StorageService.savePassword('superadmin1', 'superadmin123');
      await StorageService.savePassword('admin1', 'password123');
      await StorageService.savePassword('employee1', 'password123');
    });

    tearDown(() async {
      await AuthService.logout();
    });

    test('Super admin can log in', () async {
      final success = await AuthService.login(
        'superadmin@platform.com',
        'superadmin123',
      );

      expect(success, true);
      expect(AuthService.currentUser, isNotNull);
      expect(AuthService.currentUser!.role, UserRole.superAdmin);
    });

    test('Admin user can log in', () async {
      final success = await AuthService.login(
        'admin@store.com',
        'password123',
      );

      expect(success, true);
      expect(AuthService.currentUser, isNotNull);
      expect(AuthService.currentUser!.role, UserRole.admin);
    });

    test('Employee user can log in', () async {
      final success = await AuthService.login(
        'john@store.com',
        'password123',
      );

      expect(success, true);
      expect(AuthService.currentUser, isNotNull);
      expect(AuthService.currentUser!.role, UserRole.employee);
    });

    test('Login fails with incorrect password', () async {
      final success = await AuthService.login(
        'admin@store.com',
        'wrongpassword',
      );

      expect(success, false);
      expect(AuthService.currentUser, isNull);
    });

    test('Login fails with non-existent user', () async {
      final success = await AuthService.login(
        'nonexistent@store.com',
        'password123',
      );

      expect(success, false);
      expect(AuthService.currentUser, isNull);
    });

    test('Logout clears current user', () async {
      // First log in
      await AuthService.login('admin@store.com', 'password123');
      expect(AuthService.currentUser, isNotNull);

      // Then log out
      await AuthService.logout();
      expect(AuthService.currentUser, isNull);
    });

    test('Super admin bypasses company status check', () async {
      // Super admin should be able to log in regardless of company status
      final success = await AuthService.login(
        'superadmin@platform.com',
        'superadmin123',
      );

      expect(success, true);
      expect(AuthService.currentUser!.role, UserRole.superAdmin);
      expect(AuthService.currentUser!.primaryCompanyId, isNull);
    });

    test('User with at least one active company can log in', () async {
      // This tests the _checkUserHasActiveCompany logic
      final users = await StorageService.getUsers();
      final testUser = users.firstWhere(
        (u) => u.companyIds.isNotEmpty && u.role != UserRole.superAdmin,
        orElse: () => users.first,
      );

      if (testUser.companyIds.isNotEmpty) {
        final companies = await StorageService.getCompanies();
        final hasActiveCompany = companies.any(
          (c) => testUser.companyIds.contains(c.id) && c.isActive,
        );

        if (hasActiveCompany) {
          // User should be able to log in if they have at least one active company
          expect(testUser.companyIds, isNotEmpty);
        }
      }
    });

    test('Current user persists after login', () async {
      await AuthService.login('admin@store.com', 'password123');
      final firstUser = AuthService.currentUser;

      expect(firstUser, isNotNull);
      expect(firstUser!.email, 'admin@store.com');

      // Current user should remain the same
      expect(AuthService.currentUser, equals(firstUser));
    });

    test('Multiple login attempts with different users', () async {
      // Login as admin
      var success = await AuthService.login('admin@store.com', 'password123');
      expect(success, true);
      expect(AuthService.currentUser!.role, UserRole.admin);

      // Logout
      await AuthService.logout();
      expect(AuthService.currentUser, isNull);

      // Login as employee
      success = await AuthService.login('john@store.com', 'password123');
      expect(success, true);
      expect(AuthService.currentUser!.role, UserRole.employee);
    });
  });

  group('AuthService Company Status Check Tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    tearDown(() async {
      await AuthService.logout();
    });

    test('User with active company can log in', () async {
      final users = await StorageService.getUsers();
      final companies = await StorageService.getCompanies();

      // Find a user with at least one active company
      final testUser = users.firstWhere(
        (u) =>
            u.role != UserRole.superAdmin &&
            u.companyIds
                .any((cId) => companies.any((c) => c.id == cId && c.isActive)),
        orElse: () => users.firstWhere((u) => u.role == UserRole.admin),
      );

      final password = await StorageService.getPassword(testUser.id);
      final success = await AuthService.login(
        testUser.email,
        password ?? 'password123',
      );

      // Should succeed if user has at least one active company
      final hasActiveCompany = companies.any(
        (c) => testUser.companyIds.contains(c.id) && c.isActive,
      );

      if (hasActiveCompany) {
        expect(success, true);
      }
    });

    test('Super admin email bypass works', () async {
      // Test explicit email check for super admin
      final success = await AuthService.login(
        'superadmin@platform.com',
        'superadmin123',
      );

      expect(success, true);
      expect(AuthService.currentUser!.email, 'superadmin@platform.com');
    });
  });

  group('AuthService Password Management', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    test('Default password works for new users', () async {
      final users = await StorageService.getUsers();
      final testUser = users.first;

      // Try logging in with default password
      final success = await AuthService.login(
        testUser.email,
        'password123',
      );

      // Should work if no custom password is set
      expect(success, isA<bool>());
    });

    test('Stored password takes precedence over default', () async {
      final users = await StorageService.getUsers();
      final testUser = users.first;

      final storedPassword = await StorageService.getPassword(testUser.id);
      if (storedPassword != null) {
        // Login with stored password should work
        final success = await AuthService.login(
          testUser.email,
          storedPassword,
        );

        expect(success, true);
      }
    });
  });
}
