import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bonuses/services/firebase_auth_service.dart';
import 'package:bonuses/models/user.dart' as models;
import 'package:bonuses/models/company.dart';
import 'package:bonuses/services/firebase_service.dart';
import 'package:bonuses/firebase_options.dart';

void main() {
  group('Firebase User Creation Tests', () {
    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      await FirebaseService.initialize();
    });

    tearDownAll(() async {
      // Clean up test users
      try {
        final auth = FirebaseAuth.instance;
        final users = [
          'kallikrist@test.is',
          'testuser1@example.com',
          'testuser2@example.com',
          'testuser3@example.com',
        ];

        for (final email in users) {
          try {
            final user = await auth.signInWithEmailAndPassword(
              email: email,
              password: 'demo123',
            );
            if (user.user != null) {
              await user.user!.delete();
              print('✅ Deleted test user: $email');
            }
          } catch (e) {
            print('⚠️ Could not delete user $email: $e');
          }
        }
      } catch (e) {
        print('⚠️ Cleanup failed: $e');
      }
    });

    test('Create test company for Firebase users', () async {
      final company = Company(
        id: 'test_company_1',
        name: 'TestCompany1',
        adminUserId: 'test_admin_1',
        createdAt: DateTime.now(),
        isActive: true,
      );

      await FirebaseService.createCompany(company);
      print('✅ Created test company: ${company.name}');
    });

    test('Create kallikrist@test.is user in Firebase', () async {
      final user = await FirebaseAuthService.createUserWithEmailAndPassword(
        email: 'kallikrist@test.is',
        password: 'demo123',
        name: 'Kalli Krist',
        role: models.UserRole.employee,
        companyId: 'test_company_1',
      );

      expect(user, isNotNull);
      expect(user!.email, equals('kallikrist@test.is'));
      expect(user.name, equals('Kalli Krist'));
      expect(user.role, equals(models.UserRole.employee));
      expect(user.companyIds, contains('test_company_1'));
      expect(user.primaryCompanyId, equals('test_company_1'));

      print('✅ Created user: ${user.email} with role: ${user.role}');
    });

    test('Create additional test users in Firebase', () async {
      final testUsers = [
        {
          'email': 'testuser1@example.com',
          'name': 'Test User 1',
          'role': models.UserRole.employee,
        },
        {
          'email': 'testuser2@example.com',
          'name': 'Test User 2',
          'role': models.UserRole.admin,
        },
        {
          'email': 'testuser3@example.com',
          'name': 'Test User 3',
          'role': models.UserRole.employee,
        },
      ];

      for (final userData in testUsers) {
        final user = await FirebaseAuthService.createUserWithEmailAndPassword(
          email: userData['email'] as String,
          password: 'demo123',
          name: userData['name'] as String,
          role: userData['role'] as models.UserRole,
          companyId: 'test_company_1',
        );

        expect(user, isNotNull);
        expect(user!.email, equals(userData['email']));
        expect(user.name, equals(userData['name']));
        expect(user.role, equals(userData['role']));

        print('✅ Created user: ${user.email} with role: ${user.role}');
      }
    });

    test('Verify users exist in Firebase Auth', () async {
      final auth = FirebaseAuth.instance;

      // Test signing in with kallikrist@test.is
      final result = await auth.signInWithEmailAndPassword(
        email: 'kallikrist@test.is',
        password: 'demo123',
      );

      expect(result.user, isNotNull);
      expect(result.user!.email, equals('kallikrist@test.is'));

      print('✅ Verified Firebase Auth login for kallikrist@test.is');

      // Sign out
      await auth.signOut();
    });

    test('Verify users exist in Firestore', () async {
      final firestore = FirebaseFirestore.instance;

      // Check if kallikrist@test.is exists in Firestore
      final userDoc = await firestore
          .collection('users')
          .where('email', isEqualTo: 'kallikrist@test.is')
          .get();

      expect(userDoc.docs, isNotEmpty);
      expect(userDoc.docs.first.data()['email'], equals('kallikrist@test.is'));
      expect(userDoc.docs.first.data()['name'], equals('Kalli Krist'));
      expect(userDoc.docs.first.data()['role'], equals('employee'));

      print('✅ Verified Firestore document for kallikrist@test.is');
    });

    test('Test Firebase authentication flow', () async {
      // Test login with Firebase Auth
      final user = await FirebaseAuthService.signInWithEmailAndPassword(
        email: 'kallikrist@test.is',
        password: 'demo123',
      );

      expect(user, isNotNull);
      expect(user!.email, equals('kallikrist@test.is'));
      expect(user.role, equals(models.UserRole.employee));

      print('✅ Firebase authentication flow successful');
    });
  });
}
