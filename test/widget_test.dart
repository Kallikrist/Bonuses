import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:bonuses/main.dart';
import 'mocks/testable_app_provider.dart';
import 'mocks/mock_storage_service.dart';
import 'package:bonuses/models/user.dart';

void main() {
  group('Admin Login Tests', () {
    late TestableAppProvider appProvider;

    setUp(() async {
      // Initialize the app provider for testing
      appProvider = TestableAppProvider();
      await appProvider.initialize();
    });

    tearDown(() async {
      // Clean up after each test
      await MockStorageService.clearAllData();
    });

    testWidgets('App loads without crashing', (WidgetTester tester) async {
      // Build our app and trigger a frame.
      await tester.pumpWidget(const BonusesApp());

      // Verify that the app loads
      expect(find.byType(BonusesApp), findsOneWidget);
    });

    test('Admin can log in successfully with correct credentials', () async {
      // Test successful admin login
      final success = await appProvider.login('admin@store.com', 'password123');

      expect(success, isTrue);
      expect(appProvider.currentUser, isNotNull);
      expect(appProvider.currentUser?.email, equals('admin@store.com'));
      expect(appProvider.isAdmin, isTrue);
      expect(appProvider.isEmployee, isFalse);
    });

    test('Admin login with invalid password fails', () async {
      // Test failed login with wrong password
      final success =
          await appProvider.login('admin@store.com', 'wrongpassword');

      expect(success, isFalse);
      expect(appProvider.currentUser, isNull);
      expect(appProvider.isAdmin, isFalse);
    });

    test('Admin login with non-existent email fails', () async {
      // Test failed login with non-existent email
      final success =
          await appProvider.login('nonexistent@store.com', 'password123');

      expect(success, isFalse);
      expect(appProvider.currentUser, isNull);
      expect(appProvider.isAdmin, isFalse);
    });

    test('AppProvider login method works correctly', () async {
      // Test successful admin login
      final success = await appProvider.login('admin@store.com', 'password123');

      expect(success, isTrue);
      expect(appProvider.currentUser, isNotNull);
      expect(appProvider.currentUser?.email, equals('admin@store.com'));
      expect(appProvider.isAdmin, isTrue);
      expect(appProvider.isEmployee, isFalse);
    });

    test('AppProvider login with invalid credentials fails', () async {
      // Test failed login
      final success =
          await appProvider.login('admin@store.com', 'wrongpassword');

      expect(success, isFalse);
      expect(appProvider.currentUser, isNull);
      expect(appProvider.isAdmin, isFalse);
    });

    test('Admin can logout successfully when logged in', () async {
      // First login successfully as admin
      final loginSuccess = await appProvider.login('admin@store.com', 'password123');
      expect(loginSuccess, isTrue);
      expect(appProvider.currentUser, isNotNull);
      expect(appProvider.currentUser?.email, equals('admin@store.com'));
      expect(appProvider.isAdmin, isTrue);
      expect(appProvider.isEmployee, isFalse);
      
      // Then logout
      await appProvider.logout();
      expect(appProvider.currentUser, isNull);
      expect(appProvider.isAdmin, isFalse);
      expect(appProvider.isEmployee, isFalse);
    });

    test('AppProvider logout works correctly', () async {
      // First login successfully
      await appProvider.login('admin@store.com', 'password123');
      expect(appProvider.currentUser, isNotNull);
      
      // Then logout
      await appProvider.logout();
      expect(appProvider.currentUser, isNull);
      expect(appProvider.isAdmin, isFalse);
    });
  });

  group('Employee Login Tests', () {
    late TestableAppProvider appProvider;

    setUp(() async {
      // Initialize the app provider for testing
      appProvider = TestableAppProvider();
      await appProvider.initialize();
    });

    tearDown(() async {
      // Clean up after each test
      await MockStorageService.clearAllData();
    });

    test('Employee can log in successfully with correct credentials', () async {
      // Test successful employee login
      final success = await appProvider.login('john@store.com', 'password123');

      expect(success, isTrue);
      expect(appProvider.currentUser, isNotNull);
      expect(appProvider.currentUser?.email, equals('john@store.com'));
      expect(appProvider.currentUser?.name, equals('John Doe'));
      expect(appProvider.isAdmin, isFalse);
      expect(appProvider.isEmployee, isTrue);
    });

    test('Employee can log in with different employee credentials', () async {
      // Test successful login with another employee
      final success = await appProvider.login('jane@store.com', 'password123');

      expect(success, isTrue);
      expect(appProvider.currentUser, isNotNull);
      expect(appProvider.currentUser?.email, equals('jane@store.com'));
      expect(appProvider.currentUser?.name, equals('Jane Smith'));
      expect(appProvider.isAdmin, isFalse);
      expect(appProvider.isEmployee, isTrue);
    });

    test('Employee login with invalid password fails', () async {
      // Test failed login with wrong password
      final success =
          await appProvider.login('john@store.com', 'wrongpassword');

      expect(success, isFalse);
      expect(appProvider.currentUser, isNull);
      expect(appProvider.isAdmin, isFalse);
      expect(appProvider.isEmployee, isFalse);
    });

    test('Employee login with non-existent email fails', () async {
      // Test failed login with non-existent email
      final success =
          await appProvider.login('nonexistent@store.com', 'password123');

      expect(success, isFalse);
      expect(appProvider.currentUser, isNull);
      expect(appProvider.isAdmin, isFalse);
      expect(appProvider.isEmployee, isFalse);
    });

    test('Employee can logout successfully', () async {
      // First login successfully
      final loginSuccess =
          await appProvider.login('john@store.com', 'password123');
      expect(loginSuccess, isTrue);
      expect(appProvider.currentUser, isNotNull);
      expect(appProvider.isEmployee, isTrue);

      // Then logout
      await appProvider.logout();
      expect(appProvider.currentUser, isNull);
      expect(appProvider.isAdmin, isFalse);
      expect(appProvider.isEmployee, isFalse);
    });

    test('Employee user has correct workplace information', () async {
      // Login as employee
      final success = await appProvider.login('john@store.com', 'password123');
      expect(success, isTrue);

      final user = appProvider.currentUser;
      expect(user, isNotNull);
      expect(user?.workplaceIds, isNotEmpty);
      expect(user?.workplaceNames, isNotEmpty);
      expect(user?.workplaceIds.first, equals('wp1'));
      expect(user?.workplaceNames.first, equals('Downtown Store'));
    });

    test('Multiple employees can login with different credentials', () async {
      // Login as first employee
      final success1 = await appProvider.login('john@store.com', 'password123');
      expect(success1, isTrue);
      expect(appProvider.currentUser?.email, equals('john@store.com'));

      // Logout
      await appProvider.logout();
      expect(appProvider.currentUser, isNull);

      // Login as second employee
      final success2 = await appProvider.login('jane@store.com', 'password123');
      expect(success2, isTrue);
      expect(appProvider.currentUser?.email, equals('jane@store.com'));
      expect(appProvider.currentUser?.name, equals('Jane Smith'));
    });
  });
}
