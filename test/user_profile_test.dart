import 'package:flutter_test/flutter_test.dart';
import 'package:bonuses/models/user.dart';
import 'mocks/testable_app_provider.dart';
import 'mocks/mock_storage_service.dart';

void main() {
  group('User Profile Management Tests', () {
    late TestableAppProvider appProvider;

    setUp(() async {
      appProvider = TestableAppProvider();
      await appProvider.initialize();
    });

    tearDown(() async {
      await MockStorageService.clearAllData();
    });

    group('Admin Profile Editing', () {
      test('Admin can update their own profile information', () async {
        // Step 1: Login as admin
        final loginSuccess =
            await appProvider.login('admin@store.com', 'password123');
        expect(loginSuccess, isTrue);
        expect(appProvider.isAdmin, isTrue);

        // Step 2: Get current admin user
        final currentUser = appProvider.currentUser!;
        expect(currentUser.email, equals('admin@store.com'));

        // Step 3: Update name
        final updatedUser = currentUser.copyWith(name: 'Updated Admin Name');
        await appProvider.updateUser(updatedUser);

        // Step 4: Verify name was updated
        final userAfterNameUpdate = appProvider.currentUser!;
        expect(userAfterNameUpdate.name, equals('Updated Admin Name'));
        expect(userAfterNameUpdate.email,
            equals('admin@store.com')); // Email unchanged

        // Step 5: Update email
        final updatedUser2 =
            userAfterNameUpdate.copyWith(email: 'updated.admin@store.com');
        await appProvider.updateUser(updatedUser2);

        // Step 6: Verify email was updated
        final userAfterEmailUpdate = appProvider.currentUser!;
        expect(userAfterEmailUpdate.email, equals('updated.admin@store.com'));
        expect(userAfterEmailUpdate.name,
            equals('Updated Admin Name')); // Name unchanged

        // Step 7: Update phone number
        final updatedUser3 =
            userAfterEmailUpdate.copyWith(phoneNumber: '+1234567890');
        await appProvider.updateUser(updatedUser3);

        // Step 8: Verify phone number was updated
        final finalUser = appProvider.currentUser!;
        expect(finalUser.phoneNumber, equals('+1234567890'));
        expect(finalUser.name, equals('Updated Admin Name'));
        expect(finalUser.email, equals('updated.admin@store.com'));

        // Step 9: Verify user is still admin
        expect(finalUser.role, equals(UserRole.admin));
        expect(appProvider.isAdmin, isTrue);
      });

      test('Admin profile updates are persisted across login sessions',
          () async {
        // Step 1: Login as admin and update profile
        await appProvider.login('admin@store.com', 'password123');

        final currentUser = appProvider.currentUser!;
        final updatedUser = currentUser.copyWith(
          name: 'Persistent Admin Name',
          email: 'persistent.admin@store.com',
          phoneNumber: '+9876543210',
        );

        await appProvider.updateUser(updatedUser);

        // Step 2: Logout
        await appProvider.logout();
        expect(appProvider.currentUser, isNull);

        // Step 3: Login again
        final loginSuccess = await appProvider.login(
            'persistent.admin@store.com', 'password123');
        expect(loginSuccess, isTrue);

        // Step 4: Verify profile changes persisted
        final userAfterRelogin = appProvider.currentUser!;
        expect(userAfterRelogin.name, equals('Persistent Admin Name'));
        expect(userAfterRelogin.email, equals('persistent.admin@store.com'));
        expect(userAfterRelogin.phoneNumber, equals('+9876543210'));
      });

      test('Admin profile updates trigger UI state changes', () async {
        // Step 1: Login as admin
        await appProvider.login('admin@store.com', 'password123');

        final initialUser = appProvider.currentUser!;
        expect(initialUser.name, isNot(equals('Test UI Update')));

        // Step 2: Update profile
        final updatedUser = initialUser.copyWith(name: 'Test UI Update');
        await appProvider.updateUser(updatedUser);

        // Step 3: Verify current user reference was updated
        final currentUserAfterUpdate = appProvider.currentUser!;
        expect(currentUserAfterUpdate.name, equals('Test UI Update'));
        expect(currentUserAfterUpdate.id,
            equals(initialUser.id)); // Same user, different data
      });
    });

    group('Employee Profile Management', () {
      test('Admin can update employee profile information', () async {
        // Step 1: Login as admin
        await appProvider.login('admin@store.com', 'password123');

        // Step 2: Get an employee
        final users = await appProvider.getUsers();
        final testEmployee = users.firstWhere((u) => u.role.name == 'employee');
        final originalName = testEmployee.name;
        final originalEmail = testEmployee.email;

        // Step 3: Update employee profile
        final updatedEmployee = testEmployee.copyWith(
          name: 'Updated Employee Name',
          email: 'updated.employee@store.com',
          phoneNumber: '+1111111111',
        );

        await appProvider.updateUser(updatedEmployee);

        // Step 4: Verify changes were saved
        final updatedUsers = await appProvider.getUsers();
        final finalEmployee =
            updatedUsers.firstWhere((u) => u.id == testEmployee.id);

        expect(finalEmployee.name, equals('Updated Employee Name'));
        expect(finalEmployee.email, equals('updated.employee@store.com'));
        expect(finalEmployee.phoneNumber, equals('+1111111111'));
        expect(finalEmployee.role, equals(UserRole.employee)); // Role unchanged
        expect(finalEmployee.id, equals(testEmployee.id)); // ID unchanged

        // Step 5: Verify original values are different
        expect(finalEmployee.name, isNot(equals(originalName)));
        expect(finalEmployee.email, isNot(equals(originalEmail)));
      });

      test('Employee profile updates are persisted in database', () async {
        // Step 1: Login as admin
        await appProvider.login('admin@store.com', 'password123');

        // Step 2: Get an employee and update their profile
        final users = await appProvider.getUsers();
        final testEmployee = users.firstWhere((u) => u.role.name == 'employee');

        final updatedEmployee = testEmployee.copyWith(
          name: 'Database Persistence Test',
          email: 'db.test@store.com',
        );

        await appProvider.updateUser(updatedEmployee);

        // Step 3: Logout and login again
        await appProvider.logout();
        await appProvider.login('admin@store.com', 'password123');

        // Step 4: Verify changes persisted
        final updatedUsers = await appProvider.getUsers();
        final persistedEmployee =
            updatedUsers.firstWhere((u) => u.id == testEmployee.id);

        expect(persistedEmployee.name, equals('Database Persistence Test'));
        expect(persistedEmployee.email, equals('db.test@store.com'));
      });

      test('Multiple employee profile updates work correctly', () async {
        // Step 1: Login as admin
        await appProvider.login('admin@store.com', 'password123');

        // Step 2: Get multiple employees
        final users = await appProvider.getUsers();
        final employees =
            users.where((u) => u.role.name == 'employee').toList();

        expect(employees.length, greaterThanOrEqualTo(2));

        // Step 3: Update first employee
        final employee1 = employees[0];
        final updatedEmployee1 = employee1.copyWith(
          name: 'First Updated Employee',
          email: 'first.updated@store.com',
        );
        await appProvider.updateUser(updatedEmployee1);

        // Step 4: Update second employee
        final employee2 = employees[1];
        final updatedEmployee2 = employee2.copyWith(
          name: 'Second Updated Employee',
          email: 'second.updated@store.com',
        );
        await appProvider.updateUser(updatedEmployee2);

        // Step 5: Verify both updates were saved
        final finalUsers = await appProvider.getUsers();
        final finalEmployee1 =
            finalUsers.firstWhere((u) => u.id == employee1.id);
        final finalEmployee2 =
            finalUsers.firstWhere((u) => u.id == employee2.id);

        expect(finalEmployee1.name, equals('First Updated Employee'));
        expect(finalEmployee1.email, equals('first.updated@store.com'));
        expect(finalEmployee2.name, equals('Second Updated Employee'));
        expect(finalEmployee2.email, equals('second.updated@store.com'));
      });
    });

    group('Profile Validation and Error Handling', () {
      test('Profile updates with invalid data are handled gracefully',
          () async {
        // Step 1: Login as admin
        await appProvider.login('admin@store.com', 'password123');

        // Step 2: Get an employee
        final users = await appProvider.getUsers();
        final testEmployee = users.firstWhere((u) => u.role.name == 'employee');

        // Step 3: Try to update with empty name (should be handled by UI validation)
        final updatedEmployee = testEmployee.copyWith(name: '');
        await appProvider.updateUser(updatedEmployee);

        // Step 4: Verify the update was processed (empty string is technically valid)
        final updatedUsers = await appProvider.getUsers();
        final finalEmployee =
            updatedUsers.firstWhere((u) => u.id == testEmployee.id);
        expect(finalEmployee.name, equals(''));
      });

      test('Profile updates maintain data integrity', () async {
        // Step 1: Login as admin
        await appProvider.login('admin@store.com', 'password123');

        // Step 2: Get an employee
        final users = await appProvider.getUsers();
        final testEmployee = users.firstWhere((u) => u.role.name == 'employee');
        final originalId = testEmployee.id;
        final originalRole = testEmployee.role;
        final originalWorkplaceIds = testEmployee.workplaceIds;
        final originalTotalPoints = testEmployee.totalPoints;

        // Step 3: Update only specific fields
        final updatedEmployee = testEmployee.copyWith(
          name: 'Integrity Test Employee',
          email: 'integrity.test@store.com',
        );

        await appProvider.updateUser(updatedEmployee);

        // Step 4: Verify other fields were not changed
        final finalUsers = await appProvider.getUsers();
        final finalEmployee = finalUsers.firstWhere((u) => u.id == originalId);

        expect(finalEmployee.id, equals(originalId));
        expect(finalEmployee.role, equals(originalRole));
        expect(finalEmployee.workplaceIds, equals(originalWorkplaceIds));
        expect(finalEmployee.totalPoints, equals(originalTotalPoints));
        expect(finalEmployee.name, equals('Integrity Test Employee'));
        expect(finalEmployee.email, equals('integrity.test@store.com'));
      });
    });

    group('Profile Update Notifications', () {
      test('Profile updates trigger provider notifications', () async {
        // Step 1: Login as admin
        await appProvider.login('admin@store.com', 'password123');

        // Step 2: Set up a listener to track notifications
        int notificationCount = 0;
        appProvider.addListener(() {
          notificationCount++;
        });

        // Step 3: Update profile
        final currentUser = appProvider.currentUser!;
        final updatedUser = currentUser.copyWith(name: 'Notification Test');
        await appProvider.updateUser(updatedUser);

        // Step 4: Verify notification was triggered
        expect(notificationCount, greaterThan(0));
      });

      test('Multiple profile updates trigger multiple notifications', () async {
        // Step 1: Login as admin
        await appProvider.login('admin@store.com', 'password123');

        // Step 2: Set up a listener
        int notificationCount = 0;
        appProvider.addListener(() {
          notificationCount++;
        });

        // Step 3: Perform multiple updates
        final currentUser = appProvider.currentUser!;

        await appProvider
            .updateUser(currentUser.copyWith(name: 'First Update'));
        await appProvider
            .updateUser(currentUser.copyWith(email: 'second@update.com'));
        await appProvider
            .updateUser(currentUser.copyWith(phoneNumber: '+1234567890'));

        // Step 4: Verify multiple notifications were triggered
        expect(notificationCount, greaterThanOrEqualTo(3));
      });
    });

    group('Edge Cases', () {
      test('Updating non-existent user does not crash', () async {
        // Step 1: Login as admin
        await appProvider.login('admin@store.com', 'password123');

        // Step 2: Create a user object with non-existent ID
        final nonExistentUser = User(
          id: 'non_existent_id',
          name: 'Non Existent User',
          email: 'non.existent@store.com',
          role: UserRole.employee,
          createdAt: DateTime.now(),
        );

        // Step 3: Try to update non-existent user (should not crash)
        await appProvider.updateUser(nonExistentUser);

        // Step 4: Verify app is still functional
        expect(appProvider.currentUser, isNotNull);
        expect(appProvider.isAdmin, isTrue);
      });

      test('Profile updates work with special characters', () async {
        // Step 1: Login as admin
        await appProvider.login('admin@store.com', 'password123');

        // Step 2: Get an employee
        final users = await appProvider.getUsers();
        final testEmployee = users.firstWhere((u) => u.role.name == 'employee');

        // Step 3: Update with special characters
        final updatedEmployee = testEmployee.copyWith(
          name: 'José María O\'Connor-Smith',
          email: 'jose.maria+test@store.com',
          phoneNumber: '+1 (555) 123-4567',
        );

        await appProvider.updateUser(updatedEmployee);

        // Step 4: Verify special characters were preserved
        final finalUsers = await appProvider.getUsers();
        final finalEmployee =
            finalUsers.firstWhere((u) => u.id == testEmployee.id);

        expect(finalEmployee.name, equals('José María O\'Connor-Smith'));
        expect(finalEmployee.email, equals('jose.maria+test@store.com'));
        expect(finalEmployee.phoneNumber, equals('+1 (555) 123-4567'));
      });
    });
  });
}
