import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bonuses/services/storage_service.dart';
import 'package:bonuses/models/user.dart';

void main() {
  group('Calendar Date Persistence Tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    group('Date Storage', () {
      test('Can save selected date for a user', () async {
        final userId = 'user_1';
        final selectedDate = DateTime(2024, 10, 15);

        await StorageService.setSelectedDate(userId, selectedDate);

        final retrieved = await StorageService.getSelectedDate(userId);
        expect(retrieved, isNotNull);
        expect(retrieved!.year, selectedDate.year);
        expect(retrieved.month, selectedDate.month);
        expect(retrieved.day, selectedDate.day);
      });

      test('Returns null for user with no saved date', () async {
        final retrieved =
            await StorageService.getSelectedDate('non_existent_user');
        expect(retrieved, isNull);
      });

      test('Can update selected date for a user', () async {
        final userId = 'user_1';
        final firstDate = DateTime(2024, 10, 15);
        final secondDate = DateTime(2024, 10, 20);

        await StorageService.setSelectedDate(userId, firstDate);
        var retrieved = await StorageService.getSelectedDate(userId);
        expect(retrieved!.day, 15);

        await StorageService.setSelectedDate(userId, secondDate);
        retrieved = await StorageService.getSelectedDate(userId);
        expect(retrieved!.day, 20);
      });

      test('Can clear selected date for a user', () async {
        final userId = 'user_1';
        final selectedDate = DateTime(2024, 10, 15);

        await StorageService.setSelectedDate(userId, selectedDate);
        expect(await StorageService.getSelectedDate(userId), isNotNull);

        await StorageService.clearSelectedDate(userId);
        expect(await StorageService.getSelectedDate(userId), isNull);
      });
    });

    group('Multiple Users', () {
      test('Different users have independent selected dates', () async {
        final user1Id = 'user_1';
        final user2Id = 'user_2';
        final date1 = DateTime(2024, 10, 15);
        final date2 = DateTime(2024, 11, 20);

        await StorageService.setSelectedDate(user1Id, date1);
        await StorageService.setSelectedDate(user2Id, date2);

        final retrieved1 = await StorageService.getSelectedDate(user1Id);
        final retrieved2 = await StorageService.getSelectedDate(user2Id);

        expect(retrieved1!.day, 15);
        expect(retrieved1.month, 10);
        expect(retrieved2!.day, 20);
        expect(retrieved2.month, 11);
      });

      test('Clearing one user date does not affect others', () async {
        final user1Id = 'user_1';
        final user2Id = 'user_2';
        final date = DateTime(2024, 10, 15);

        await StorageService.setSelectedDate(user1Id, date);
        await StorageService.setSelectedDate(user2Id, date);

        await StorageService.clearSelectedDate(user1Id);

        expect(await StorageService.getSelectedDate(user1Id), isNull);
        expect(await StorageService.getSelectedDate(user2Id), isNotNull);
      });
    });

    group('Date Persistence Scenarios', () {
      test('Persists date across app sessions', () async {
        final userId = 'admin_1';
        final selectedDate = DateTime(2024, 10, 15, 14, 30);

        // Simulate first session: save date
        await StorageService.setSelectedDate(userId, selectedDate);

        // Simulate app restart by creating new SharedPreferences instance
        // (In this test, we just verify the date is still there)
        final retrieved = await StorageService.getSelectedDate(userId);

        expect(retrieved, isNotNull);
        expect(retrieved!.year, selectedDate.year);
        expect(retrieved.month, selectedDate.month);
        expect(retrieved.day, selectedDate.day);
      });

      test('Handles date from previous month', () async {
        final userId = 'user_1';
        final lastMonth = DateTime.now().subtract(const Duration(days: 35));

        await StorageService.setSelectedDate(userId, lastMonth);

        final retrieved = await StorageService.getSelectedDate(userId);
        expect(retrieved, isNotNull);
        expect(retrieved!.isBefore(DateTime.now()), true);
      });

      test('Handles date from future', () async {
        final userId = 'user_1';
        final futureDate = DateTime.now().add(const Duration(days: 30));

        await StorageService.setSelectedDate(userId, futureDate);

        final retrieved = await StorageService.getSelectedDate(userId);
        expect(retrieved, isNotNull);
        expect(retrieved!.isAfter(DateTime.now()), true);
      });

      test('Handles dates with different times on same day', () async {
        final userId = 'user_1';
        final morning = DateTime(2024, 10, 15, 9, 0);
        final evening = DateTime(2024, 10, 15, 18, 30);

        await StorageService.setSelectedDate(userId, morning);
        var retrieved = await StorageService.getSelectedDate(userId);
        expect(retrieved!.hour, 9);

        await StorageService.setSelectedDate(userId, evening);
        retrieved = await StorageService.getSelectedDate(userId);
        expect(retrieved!.hour, 18);
      });
    });

    group('Edge Cases', () {
      test('Handles leap year dates', () async {
        final userId = 'user_1';
        final leapDay = DateTime(2024, 2, 29); // 2024 is a leap year

        await StorageService.setSelectedDate(userId, leapDay);

        final retrieved = await StorageService.getSelectedDate(userId);
        expect(retrieved, isNotNull);
        expect(retrieved!.month, 2);
        expect(retrieved.day, 29);
      });

      test('Handles end of year date', () async {
        final userId = 'user_1';
        final newYearsEve = DateTime(2024, 12, 31);

        await StorageService.setSelectedDate(userId, newYearsEve);

        final retrieved = await StorageService.getSelectedDate(userId);
        expect(retrieved, isNotNull);
        expect(retrieved!.month, 12);
        expect(retrieved.day, 31);
      });

      test('Handles start of year date', () async {
        final userId = 'user_1';
        final newYearsDay = DateTime(2024, 1, 1);

        await StorageService.setSelectedDate(userId, newYearsDay);

        final retrieved = await StorageService.getSelectedDate(userId);
        expect(retrieved, isNotNull);
        expect(retrieved!.month, 1);
        expect(retrieved.day, 1);
      });

      test('Handles invalid date string gracefully', () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('selected_date_user_1', 'invalid_date');

        final retrieved = await StorageService.getSelectedDate('user_1');
        expect(retrieved, isNull); // Should return null for invalid date
      });
    });

    group('Date Format', () {
      test('Date preserves time information', () async {
        final userId = 'user_1';
        final dateWithTime = DateTime(2024, 10, 15, 14, 30, 45);

        await StorageService.setSelectedDate(userId, dateWithTime);

        final retrieved = await StorageService.getSelectedDate(userId);
        expect(retrieved!.hour, 14);
        expect(retrieved.minute, 30);
        expect(retrieved.second, 45);
      });

      test('Date is stored as ISO8601 string', () async {
        final userId = 'user_1';
        final date = DateTime(2024, 10, 15);

        await StorageService.setSelectedDate(userId, date);

        final prefs = await SharedPreferences.getInstance();
        final storedString = prefs.getString('selected_date_user_1');

        expect(storedString, isNotNull);
        expect(storedString, contains('2024'));
        expect(storedString, contains('10'));
        expect(storedString, contains('15'));
      });
    });

    group('Integration with User Management', () {
      test('Selected date persists for admin user', () async {
        final admin = User(
          id: 'admin_1',
          name: 'Admin User',
          email: 'admin@test.com',
          phoneNumber: '+1 (555) 111-1111',
          role: UserRole.admin,
          createdAt: DateTime.now(),
          workplaceIds: ['wp1'],
          workplaceNames: ['Workplace 1'],
          companyIds: ['company_1'],
          companyNames: ['Company 1'],
          primaryCompanyId: 'company_1',
          companyRoles: {'company_1': 'admin'},
          companyPoints: {'company_1': 0},
        );

        await StorageService.addUser(admin);

        final selectedDate = DateTime(2024, 10, 15);
        await StorageService.setSelectedDate(admin.id, selectedDate);

        final retrieved = await StorageService.getSelectedDate(admin.id);
        expect(retrieved, isNotNull);
        expect(retrieved!.day, 15);
      });

      test('Selected date persists for employee user', () async {
        final employee = User(
          id: 'emp_1',
          name: 'Employee User',
          email: 'employee@test.com',
          phoneNumber: '+1 (555) 222-2222',
          role: UserRole.employee,
          createdAt: DateTime.now(),
          workplaceIds: ['wp1'],
          workplaceNames: ['Workplace 1'],
          companyIds: ['company_1'],
          companyNames: ['Company 1'],
          primaryCompanyId: 'company_1',
          companyRoles: {'company_1': 'employee'},
          companyPoints: {'company_1': 100},
        );

        await StorageService.addUser(employee);

        final selectedDate = DateTime(2024, 11, 20);
        await StorageService.setSelectedDate(employee.id, selectedDate);

        final retrieved = await StorageService.getSelectedDate(employee.id);
        expect(retrieved, isNotNull);
        expect(retrieved!.day, 20);
      });

      test('Each user role can have different selected dates', () async {
        final admin = User(
          id: 'admin_1',
          name: 'Admin',
          email: 'admin@test.com',
          phoneNumber: '+1 (555) 111-1111',
          role: UserRole.admin,
          createdAt: DateTime.now(),
          workplaceIds: [],
          workplaceNames: [],
          companyIds: ['company_1'],
          companyNames: ['Company 1'],
          primaryCompanyId: 'company_1',
          companyRoles: {},
          companyPoints: {},
        );

        final employee = User(
          id: 'emp_1',
          name: 'Employee',
          email: 'employee@test.com',
          phoneNumber: '+1 (555) 222-2222',
          role: UserRole.employee,
          createdAt: DateTime.now(),
          workplaceIds: [],
          workplaceNames: [],
          companyIds: ['company_1'],
          companyNames: ['Company 1'],
          primaryCompanyId: 'company_1',
          companyRoles: {},
          companyPoints: {},
        );

        await StorageService.addUser(admin);
        await StorageService.addUser(employee);

        final adminDate = DateTime(2024, 10, 15);
        final employeeDate = DateTime(2024, 11, 20);

        await StorageService.setSelectedDate(admin.id, adminDate);
        await StorageService.setSelectedDate(employee.id, employeeDate);

        final retrievedAdminDate =
            await StorageService.getSelectedDate(admin.id);
        final retrievedEmployeeDate =
            await StorageService.getSelectedDate(employee.id);

        expect(retrievedAdminDate!.month, 10);
        expect(retrievedEmployeeDate!.month, 11);
      });
    });

    group('Date Navigation', () {
      test('Can navigate backward by one day', () async {
        final userId = 'user_1';
        final currentDate = DateTime(2024, 10, 15);

        await StorageService.setSelectedDate(userId, currentDate);

        final previousDate = currentDate.subtract(const Duration(days: 1));
        await StorageService.setSelectedDate(userId, previousDate);

        final retrieved = await StorageService.getSelectedDate(userId);
        expect(retrieved!.day, 14);
      });

      test('Can navigate forward by one day', () async {
        final userId = 'user_1';
        final currentDate = DateTime(2024, 10, 15);

        await StorageService.setSelectedDate(userId, currentDate);

        final nextDate = currentDate.add(const Duration(days: 1));
        await StorageService.setSelectedDate(userId, nextDate);

        final retrieved = await StorageService.getSelectedDate(userId);
        expect(retrieved!.day, 16);
      });

      test('Can reset to today', () async {
        final userId = 'user_1';
        final pastDate = DateTime(2024, 9, 1);

        await StorageService.setSelectedDate(userId, pastDate);

        final today = DateTime.now();
        await StorageService.setSelectedDate(userId, today);

        final retrieved = await StorageService.getSelectedDate(userId);
        expect(retrieved!.year, today.year);
        expect(retrieved.month, today.month);
        expect(retrieved.day, today.day);
      });

      test('Navigation across month boundary', () async {
        final userId = 'user_1';
        final endOfMonth = DateTime(2024, 10, 31);

        await StorageService.setSelectedDate(userId, endOfMonth);

        final nextDay = endOfMonth.add(const Duration(days: 1));
        await StorageService.setSelectedDate(userId, nextDay);

        final retrieved = await StorageService.getSelectedDate(userId);
        expect(retrieved!.month, 11);
        expect(retrieved.day, 1);
      });

      test('Navigation across year boundary', () async {
        final userId = 'user_1';
        final endOfYear = DateTime(2024, 12, 31);

        await StorageService.setSelectedDate(userId, endOfYear);

        final nextDay = endOfYear.add(const Duration(days: 1));
        await StorageService.setSelectedDate(userId, nextDay);

        final retrieved = await StorageService.getSelectedDate(userId);
        expect(retrieved!.year, 2025);
        expect(retrieved.month, 1);
        expect(retrieved.day, 1);
      });
    });

    group('Performance', () {
      test('Can handle many date updates efficiently', () async {
        final userId = 'user_1';
        var currentDate = DateTime(2024, 1, 1);

        // Update date 100 times
        for (int i = 0; i < 100; i++) {
          currentDate = currentDate.add(const Duration(days: 1));
          await StorageService.setSelectedDate(userId, currentDate);
        }

        final retrieved = await StorageService.getSelectedDate(userId);
        expect(retrieved, isNotNull);
        // After 100 days from Jan 1, should be around April 10
        expect(retrieved!.month, greaterThanOrEqualTo(3));
      });

      test('Multiple users can update dates simultaneously', () async {
        final users = List.generate(
          10,
          (index) => 'user_$index',
        );

        final dates = List.generate(
          10,
          (index) => DateTime(2024, index + 1, 15),
        );

        // Save dates for all users
        for (int i = 0; i < users.length; i++) {
          await StorageService.setSelectedDate(users[i], dates[i]);
        }

        // Verify all dates were saved correctly
        for (int i = 0; i < users.length; i++) {
          final retrieved = await StorageService.getSelectedDate(users[i]);
          expect(retrieved!.month, i + 1);
        }
      });
    });

    group('Dashboard Context', () {
      test('Date persists when switching between tabs', () async {
        final userId = 'admin_1';
        final selectedDate = DateTime(2024, 10, 15);

        // User selects a date in Dashboard tab
        await StorageService.setSelectedDate(userId, selectedDate);

        // User navigates to Bonuses tab (date should still be saved)
        final retrieved1 = await StorageService.getSelectedDate(userId);
        expect(retrieved1, isNotNull);

        // User returns to Dashboard tab (date should be restored)
        final retrieved2 = await StorageService.getSelectedDate(userId);
        expect(retrieved2!.day, 15);
      });

      test('Date persists when navigating to other screens', () async {
        final userId = 'employee_1';
        final selectedDate = DateTime(2024, 10, 15);

        // Select date
        await StorageService.setSelectedDate(userId, selectedDate);

        // Navigate to target details, messages, profile, etc.
        // Date should still be saved
        final retrieved = await StorageService.getSelectedDate(userId);
        expect(retrieved!.day, 15);
      });

      test('Date persists across logout/login (for same user)', () async {
        final user = User(
          id: 'user_1',
          name: 'Test User',
          email: 'test@example.com',
          phoneNumber: '+1 (555) 123-4567',
          role: UserRole.admin,
          createdAt: DateTime.now(),
          workplaceIds: [],
          workplaceNames: [],
          companyIds: ['company_1'],
          companyNames: ['Company 1'],
          primaryCompanyId: 'company_1',
          companyRoles: {},
          companyPoints: {},
        );

        await StorageService.addUser(user);

        final selectedDate = DateTime(2024, 10, 15);
        await StorageService.setSelectedDate(user.id, selectedDate);

        // Simulate logout (date should still be saved)
        await StorageService.clearCurrentUser();

        // Simulate login (date should still be there)
        await StorageService.setCurrentUser(user);

        final retrieved = await StorageService.getSelectedDate(user.id);
        expect(retrieved!.day, 15);
      });
    });

    group('Date Validation', () {
      test('Stores dates far in the past', () async {
        final userId = 'user_1';
        final pastDate = DateTime(2020, 1, 1);

        await StorageService.setSelectedDate(userId, pastDate);

        final retrieved = await StorageService.getSelectedDate(userId);
        expect(retrieved!.year, 2020);
      });

      test('Stores dates far in the future', () async {
        final userId = 'user_1';
        final futureDate = DateTime(2030, 12, 31);

        await StorageService.setSelectedDate(userId, futureDate);

        final retrieved = await StorageService.getSelectedDate(userId);
        expect(retrieved!.year, 2030);
      });

      test('Handles same date saved multiple times', () async {
        final userId = 'user_1';
        final date = DateTime(2024, 10, 15);

        await StorageService.setSelectedDate(userId, date);
        await StorageService.setSelectedDate(userId, date);
        await StorageService.setSelectedDate(userId, date);

        final retrieved = await StorageService.getSelectedDate(userId);
        expect(retrieved!.day, 15);
      });
    });
  });
}
