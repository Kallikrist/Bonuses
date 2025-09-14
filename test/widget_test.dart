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
      final success = await appProvider.login('admin@store.com', 'wrongpassword');
      
      expect(success, isFalse);
      expect(appProvider.currentUser, isNull);
      expect(appProvider.isAdmin, isFalse);
    });

    test('Admin login with non-existent email fails', () async {
      // Test failed login with non-existent email
      final success = await appProvider.login('nonexistent@store.com', 'password123');
      
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
      final success = await appProvider.login('admin@store.com', 'wrongpassword');
      
      expect(success, isFalse);
      expect(appProvider.currentUser, isNull);
      expect(appProvider.isAdmin, isFalse);
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
}
