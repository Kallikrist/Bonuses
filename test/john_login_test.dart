import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bonuses/services/storage_service.dart';
import 'package:bonuses/services/auth_service.dart';
import 'package:bonuses/providers/app_provider.dart';
import 'package:bonuses/models/user.dart';
import 'package:bonuses/models/company.dart';

void main() {
  group('John Login Test', () {
    setUp(() async {
      // Initialize mock SharedPreferences
      SharedPreferences.setMockInitialValues({});
    });

    test('John should be able to log in after company activation', () async {
      // Create test data
      final johnUser = User(
        id: 'john1',
        name: 'John Doe',
        email: 'john@store.com',
        phoneNumber: '+1 (555) 123-4567',
        role: UserRole.employee,
        createdAt: DateTime.now(),
        workplaceIds: ['workplace1'],
        workplaceNames: ['Main Store'],
        companyIds: ['company_1759849693535'],
        companyNames: ['Dominos'],
        primaryCompanyId: 'company_1759849693535',
        companyRoles: {'company_1759849693535': 'employee'},
        companyPoints: {'company_1759849693535': 0},
      );

      final dominosCompany = Company(
        id: 'company_1759849693535',
        name: 'Dominos',
        contactEmail: 'admin@dominos.com',
        adminUserId: 'admin1', // Required field
        createdAt: DateTime.now(),
        isActive: false, // Initially suspended
      );

      // Add test data
      await StorageService.addUser(johnUser);
      await StorageService.addCompany(dominosCompany);
      await StorageService.savePassword('john1', 'password123');

      // Test 1: John should NOT be able to log in when company is suspended
      print('=== Test 1: John login with suspended company ===');
      final loginResult1 =
          await AuthService.login('john@store.com', 'password123');
      expect(loginResult1, false,
          reason: 'John should not be able to log in with suspended company');
      print('✓ John correctly blocked from logging in with suspended company');

      // Test 2: Activate the company
      print('\n=== Test 2: Activating Dominos company ===');
      final appProvider = AppProvider();
      await appProvider.activateCompany('company_1759849693535');
      print('✓ Company activated');

      // Test 3: John should now be able to log in
      print('\n=== Test 3: John login after company activation ===');
      final loginResult2 =
          await AuthService.login('john@store.com', 'password123');
      expect(loginResult2, true,
          reason: 'John should be able to log in after company activation');
      print('✓ John successfully logged in after company activation');

      // Verify current user is John
      final currentUser = AuthService.currentUser;
      expect(currentUser, isNotNull);
      expect(currentUser!.email, 'john@store.com');
      expect(currentUser.name, 'John Doe');
      print('✓ Current user is John Doe');

      print('\n🎉 All tests passed! John can log in after company activation.');
    });

    test('Super admin should be able to log in regardless of company status',
        () async {
      // Create super admin user
      final superAdminUser = User(
        id: 'superadmin1',
        name: 'Platform Administrator',
        email: 'superadmin@platform.com',
        phoneNumber: '+1 (555) 000-0000',
        role: UserRole.superAdmin,
        createdAt: DateTime.now(),
        workplaceIds: [],
        workplaceNames: [],
        companyIds: [],
        companyNames: [],
        primaryCompanyId: null,
        companyRoles: {},
        companyPoints: {},
      );

      // Add super admin
      await StorageService.addUser(superAdminUser);
      await StorageService.savePassword('superadmin1', 'superadmin123');

      // Test: Super admin should be able to log in
      print('=== Test: Super admin login ===');
      final loginResult =
          await AuthService.login('superadmin@platform.com', 'superadmin123');
      expect(loginResult, true, reason: 'Super admin should be able to log in');
      print('✓ Super admin successfully logged in');

      // Verify current user is super admin
      final currentUser = AuthService.currentUser;
      expect(currentUser, isNotNull);
      expect(currentUser!.email, 'superadmin@platform.com');
      expect(currentUser.role, UserRole.superAdmin);
      print('✓ Current user is super admin');

      print('\n🎉 Super admin login test passed!');
    });
  });
}
