import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart' as models;
import 'storage_service.dart';

class CreateFirebaseUsers {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create Firebase Auth users for existing local users
  static Future<void> createFirebaseUsersForDemo() async {
    try {
      print('🔄 Creating Firebase users for demo accounts...');
      print('🔄 Firebase Auth instance: ${_auth.app.name}');
      print('🔄 Firebase Firestore instance: ${_firestore.app.name}');

      // First, ensure test company exists in Firebase
      print('🔄 Creating test company in Firebase...');
      try {
        await _firestore.collection('companies').doc('test_company_1').set({
          'id': 'test_company_1',
          'name': 'TestCompany1',
          'address': 'Test Address, Test City',
          'contactEmail': 'admin@testcompany1.com',
          'contactPhone': '+1 (555) 999-9999',
          'adminUserId': 'test_admin_1',
          'createdAt': DateTime.now().millisecondsSinceEpoch,
          'employeeCount': '1-10',
          'isActive': true,
        });
        print('✅ Test company created in Firebase');
      } catch (e) {
        print('⚠️ Test company creation failed (may already exist): $e');
      }

      // Demo users with their passwords
      final demoUsers = [
        {
          'email': 'superadmin@platform.com',
          'password': 'password123',
          'name': 'Super Admin',
          'role': models.UserRole.superAdmin,
          'companyIds': [],
          'companyNames': [],
          'primaryCompanyId': null,
        },
        {
          'email': 'admin@utilif.com',
          'password': 'utilif123',
          'name': 'Admin Utilif',
          'role': models.UserRole.admin,
          'companyIds': ['demo_company_utilif'],
          'companyNames': ['Utilif'],
          'primaryCompanyId': 'demo_company_utilif',
        },
        {
          'email': 'employee@utilif.com',
          'password': 'password123',
          'name': 'Employee Utilif',
          'role': models.UserRole.employee,
          'companyIds': ['demo_company_utilif'],
          'companyNames': ['Utilif'],
          'primaryCompanyId': 'demo_company_utilif',
        },
        {
          'email': 'kallikrist@test.is',
          'password': 'demo123',
          'name': 'Kalli Krist',
          'role': models.UserRole.employee,
          'companyIds': ['test_company_1'],
          'companyNames': ['TestCompany1'],
          'primaryCompanyId': 'test_company_1',
        },
      ];

      for (int i = 0; i < demoUsers.length; i++) {
        final userData = demoUsers[i];
        try {
          print('🔄 Processing user ${i + 1}/${demoUsers.length}: ${userData['email']}');
          // Try to sign in first to check if user exists
          try {
            await _auth.signInWithEmailAndPassword(
              email: userData['email'] as String,
              password: userData['password'] as String,
            );
            print('⏭️ User already exists: ${userData['email']}');
            continue; // User already exists, skip creation
          } catch (e) {
            print('🔍 User doesn\'t exist, creating: ${userData['email']}');
            // User doesn't exist, proceed with creation
          }
          // Create Firebase Auth user
          final credential = await _auth.createUserWithEmailAndPassword(
            email: userData['email'] as String,
            password: userData['password'] as String,
          );

          if (credential.user != null) {
            print('✅ Firebase Auth user created: ${userData['email']}');
            // Create user document in Firestore
            final user = models.User(
              id: credential.user!.uid,
              name: userData['name'] as String,
              email: userData['email'] as String,
              role: userData['role'] as models.UserRole,
              createdAt: DateTime.now(),
              workplaceIds: [],
              workplaceNames: [],
              companyIds: userData['companyIds'] as List<String>? ??
                  (userData['email'] == 'admin@utilif.com'
                      ? ['demo_company_utilif']
                      : []),
              companyNames: userData['companyNames'] as List<String>? ??
                  (userData['email'] == 'admin@utilif.com' ? ['Utilif'] : []),
              primaryCompanyId: userData['primaryCompanyId'] as String? ??
                  (userData['email'] == 'admin@utilif.com'
                      ? 'demo_company_utilif'
                      : null),
            );
            print(
                '📝 User data prepared: ${user.email}, companies: ${user.companyIds}');

            await _firestore
                .collection('users')
                .doc(credential.user!.uid)
                .set(user.toJson());

            print('✅ Created Firebase user: ${userData['email']}');
          } else {
            print('❌ Failed to create Firebase Auth user: ${userData['email']}');
          }
        } catch (e) {
          print('❌ Failed to create user ${userData['email']}: $e');
          print('❌ Error details: ${e.toString()}');
          // Continue with next user instead of stopping
        }
      }

      print('🎉 Firebase user creation completed!');
    } catch (e) {
      print('❌ Firebase user creation failed: $e');
      print('❌ Error details: ${e.toString()}');
      // Don't rethrow, just log the error and continue
    }
  }

  // Fix super admin to have no company association
  static Future<void> fixSuperAdminCompanyAssociation() async {
    try {
      print('🔧 Fixing super admin company association...');

      // Get all users from Firestore
      final usersSnapshot = await _firestore.collection('users').get();

      for (final doc in usersSnapshot.docs) {
        final userData = doc.data();
        if (userData['email'] == 'superadmin@platform.com') {
          // Update super admin to have no company association
          await _firestore.collection('users').doc(doc.id).update({
            'companyIds': [],
            'companyNames': [],
            'primaryCompanyId': null,
          });
          print('✅ Fixed super admin company association');
          break;
        }
      }
    } catch (e) {
      print('❌ Failed to fix super admin: $e');
    }
  }
}
