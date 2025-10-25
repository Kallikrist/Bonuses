import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';
import '../models/company.dart';
import '../models/sales_target.dart';
import '../models/bonus.dart';
import '../models/workplace.dart';
import '../models/company_subscription.dart';
import 'storage_service.dart';
import 'firebase_auth_service.dart';

class FirebaseMigrationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Migrate all users from local storage to Firebase
  static Future<void> migrateUsersToFirebase() async {
    try {
      print('🔄 Starting user migration to Firebase...');

      final users = await StorageService.getUsers();
      print('📊 Found ${users.length} users to migrate');

      for (final user in users) {
        try {
          // Check if user already exists in Firebase
          final existingDoc =
              await _firestore.collection('users').doc(user.id).get();

          if (!existingDoc.exists) {
            // Create user in Firebase
            await _firestore
                .collection('users')
                .doc(user.id)
                .set(user.toJson());
            print('✅ Migrated user: ${user.email}');
          } else {
            print('⏭️ User already exists: ${user.email}');
          }
        } catch (e) {
          print('❌ Failed to migrate user ${user.email}: $e');
        }
      }

      print('🎉 User migration completed!');
    } catch (e) {
      print('❌ User migration failed: $e');
      rethrow;
    }
  }

  // Migrate all companies from local storage to Firebase
  static Future<void> migrateCompaniesToFirebase() async {
    try {
      print('🔄 Starting company migration to Firebase...');

      final companies = await StorageService.getCompanies();
      print('📊 Found ${companies.length} companies to migrate');

      for (final company in companies) {
        try {
          // Check if company already exists in Firebase
          final existingDoc =
              await _firestore.collection('companies').doc(company.id).get();

          if (!existingDoc.exists) {
            // Create company in Firebase
            await _firestore
                .collection('companies')
                .doc(company.id)
                .set(company.toJson());
            print('✅ Migrated company: ${company.name}');
          } else {
            print('⏭️ Company already exists: ${company.name}');
          }
        } catch (e) {
          print('❌ Failed to migrate company ${company.name}: $e');
        }
      }

      print('🎉 Company migration completed!');
    } catch (e) {
      print('❌ Company migration failed: $e');
      rethrow;
    }
  }

  // Migrate all data to Firebase
  static Future<void> migrateAllDataToFirebase() async {
    try {
      print('🚀 Starting full data migration to Firebase...');

      await migrateUsersToFirebase();
      await migrateCompaniesToFirebase();

      // You can add more migrations here for other data types
      // await migrateSalesTargetsToFirebase();
      // await migrateBonusesToFirebase();
      // await migrateWorkplacesToFirebase();
      // await migrateSubscriptionsToFirebase();

      print('🎉 Full data migration completed!');
    } catch (e) {
      print('❌ Full data migration failed: $e');
      rethrow;
    }
  }

  // Create Firebase users for existing local users
  static Future<void> createFirebaseUsersForLocalUsers() async {
    try {
      print('🔄 Creating Firebase users for local users...');

      final users = await StorageService.getUsers();
      print('📊 Found ${users.length} users to create in Firebase Auth');

      for (final user in users) {
        try {
          // Check if Firebase Auth user already exists
          final firebaseUser = await FirebaseAuthService.getUserById(user.id);

          if (firebaseUser == null) {
            // Create Firebase Auth user (this will require password)
            // For demo purposes, we'll use a default password
            final defaultPassword = 'password123';

            try {
              await FirebaseAuthService.createUserWithEmailAndPassword(
                email: user.email,
                password: defaultPassword,
                name: user.name,
                role: user.role,
                companyId: user.primaryCompanyId,
              );
              print('✅ Created Firebase Auth user: ${user.email}');
            } catch (e) {
              print('⚠️ Failed to create Firebase Auth user ${user.email}: $e');
              // Continue with other users
            }
          } else {
            print('⏭️ Firebase Auth user already exists: ${user.email}');
          }
        } catch (e) {
          print('❌ Failed to process user ${user.email}: $e');
        }
      }

      print('🎉 Firebase Auth user creation completed!');
    } catch (e) {
      print('❌ Firebase Auth user creation failed: $e');
      rethrow;
    }
  }
}
