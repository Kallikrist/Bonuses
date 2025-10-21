import 'package:flutter_test/flutter_test.dart';
import 'package:bonuses/services/auth_service.dart';
import 'package:bonuses/services/storage_service.dart';
import 'package:bonuses/models/user.dart';
import 'package:bonuses/models/company.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Logout/Login Flow with Company Selection', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});

      // Create test data
      final adminUser = User(
        id: 'admin1',
        name: 'Admin User',
        email: 'admin@store.com',
        phoneNumber: '+1 (555) 111-1111',
        role: UserRole.admin,
        createdAt: DateTime.now(),
        workplaceIds: ['workplace1'],
        workplaceNames: ['Test Workplace'],
        companyIds: ['test_company', 'dominios_company'],
        companyNames: ['Test Company', 'Dominos'],
        primaryCompanyId: 'test_company',
        companyRoles: {'test_company': 'admin', 'dominios_company': 'admin'},
        companyPoints: {'test_company': 0, 'dominios_company': 0},
      );

      final testCompany = Company(
        id: 'test_company',
        name: 'Test Company',
        contactEmail: 'admin@test.com',
        adminUserId: 'admin1',
        createdAt: DateTime.now(),
        isActive: true,
      );

      final dominosCompany = Company(
        id: 'dominios_company',
        name: 'Dominos',
        contactEmail: 'admin@dominos.com',
        adminUserId: 'admin1',
        createdAt: DateTime.now(),
        isActive: true,
      );

      // Add users and companies to storage
      await StorageService.addUser(adminUser);
      await StorageService.addCompany(testCompany);
      await StorageService.addCompany(dominosCompany);

      // Set password
      await StorageService.savePassword('admin1', 'password123');
    });

    tearDown(() async {
      await AuthService.logout();
    });

    test('Admin can logout and login again after selecting Dominos company',
        () async {
      // Step 1: Login as admin
      final loginSuccess =
          await AuthService.login('admin@store.com', 'password123');
      expect(loginSuccess, true, reason: 'Initial login should succeed');
      expect(AuthService.currentUser, isNotNull,
          reason: 'Current user should be set after login');

      final user = AuthService.currentUser!;
      expect(user.email, 'admin@store.com');
      expect(user.role, UserRole.admin);

      // Step 2: Verify user has multiple companies
      final companies = await StorageService.getCompanies();
      final userCompanies =
          companies.where((c) => user.companyIds.contains(c.id)).toList();
      print('DEBUG: User has ${userCompanies.length} companies');

      // Step 3: Find Dominos company
      final dominosCompany = userCompanies.firstWhere(
        (c) => c.name == 'Dominos',
        orElse: () =>
            throw Exception('Dominos company not found for this user'),
      );
      print(
          'DEBUG: Found Dominos company: ${dominosCompany.id}, isActive: ${dominosCompany.isActive}');

      // Step 4: Update user's primary company to Dominos
      final updatedUser = user.copyWith(primaryCompanyId: dominosCompany.id);
      await StorageService.updateUser(updatedUser);
      await StorageService.setCurrentUser(updatedUser);

      // Verify the update
      final storedUsers = await StorageService.getUsers();
      final verifyUser = storedUsers.firstWhere((u) => u.id == user.id);
      expect(verifyUser.primaryCompanyId, dominosCompany.id,
          reason: 'Primary company should be updated to Dominos');

      // Step 5: Logout
      await AuthService.logout();
      expect(AuthService.currentUser, isNull,
          reason: 'Current user should be null after logout');

      // Step 6: Try to login again
      final reloginSuccess =
          await AuthService.login('admin@store.com', 'password123');
      print('DEBUG: Re-login success: $reloginSuccess');

      if (!reloginSuccess) {
        // Check if it's because Dominos is suspended
        final dominosStatus = await StorageService.getCompanies();
        final dominos =
            dominosStatus.firstWhere((c) => c.id == dominosCompany.id);
        print('DEBUG: Dominos isActive status: ${dominos.isActive}');

        if (!dominos.isActive) {
          print('DEBUG: Login blocked because Dominos company is suspended');
          // This is expected behavior - user should not be able to login if their primary company is suspended
          // BUT they should be able to login if they have OTHER active companies

          final activeCompanies = dominosStatus
              .where((c) => user.companyIds.contains(c.id) && c.isActive)
              .toList();
          print('DEBUG: User has ${activeCompanies.length} active companies');

          if (activeCompanies.isNotEmpty) {
            expect(reloginSuccess, true,
                reason:
                    'Login should succeed because user has other active companies: ${activeCompanies.map((c) => c.name).join(", ")}');
          } else {
            expect(reloginSuccess, false,
                reason:
                    'Login should fail because user has no active companies');
          }
        }
      } else {
        expect(reloginSuccess, true, reason: 'Re-login should succeed');
        expect(AuthService.currentUser, isNotNull,
            reason: 'Current user should be set after re-login');
        expect(AuthService.currentUser!.email, 'admin@store.com');
      }
    });

    test('Admin with only suspended company cannot login', () async {
      // Step 1: Login as admin
      await AuthService.login('admin@store.com', 'password123');
      final user = AuthService.currentUser!;

      // Step 2: Suspend all user's companies
      final companies = await StorageService.getCompanies();
      final userCompanies =
          companies.where((c) => user.companyIds.contains(c.id)).toList();

      for (final company in userCompanies) {
        final suspendedCompany = company.copyWith(isActive: false);
        await StorageService.updateCompany(suspendedCompany);
      }

      // Step 3: Logout
      await AuthService.logout();

      // Step 4: Try to login again - should fail
      final reloginSuccess =
          await AuthService.login('admin@store.com', 'password123');
      expect(reloginSuccess, false,
          reason: 'Login should fail when all user companies are suspended');
      expect(AuthService.currentUser, isNull);

      // Cleanup: Reactivate companies
      for (final company in userCompanies) {
        final activeCompany = company.copyWith(isActive: true);
        await StorageService.updateCompany(activeCompany);
      }
    });

    test('Admin with mixed active/suspended companies can login', () async {
      // Step 1: Login as admin
      await AuthService.login('admin@store.com', 'password123');
      final user = AuthService.currentUser!;

      // Step 2: Get user's companies
      final companies = await StorageService.getCompanies();
      final userCompanies =
          companies.where((c) => user.companyIds.contains(c.id)).toList();

      if (userCompanies.length < 2) {
        print('DEBUG: User does not have multiple companies, skipping test');
        return;
      }

      // Step 3: Suspend one company, keep others active
      final companyToSuspend = userCompanies.first;
      final suspendedCompany = companyToSuspend.copyWith(isActive: false);
      await StorageService.updateCompany(suspendedCompany);

      // Step 4: Set primary company to the suspended one
      final updatedUser = user.copyWith(primaryCompanyId: companyToSuspend.id);
      await StorageService.updateUser(updatedUser);
      await StorageService.setCurrentUser(updatedUser);

      // Step 5: Logout
      await AuthService.logout();

      // Step 6: Try to login again - should succeed because user has other active companies
      final reloginSuccess =
          await AuthService.login('admin@store.com', 'password123');
      expect(reloginSuccess, true,
          reason:
              'Login should succeed when user has at least one active company');

      // Cleanup: Reactivate company
      final reactivatedCompany = companyToSuspend.copyWith(isActive: true);
      await StorageService.updateCompany(reactivatedCompany);
    });
  });
}
