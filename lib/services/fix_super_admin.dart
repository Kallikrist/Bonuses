import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FixSuperAdmin {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Force update super admin to have no company association
  static Future<void> forceFixSuperAdmin() async {
    try {
      print('🔧 Force fixing super admin company association...');
      
      // Get the super admin user from Firebase Auth
      final currentUser = _auth.currentUser;
      if (currentUser != null && currentUser.email == 'superadmin@platform.com') {
        // Update the user document in Firestore
        await _firestore.collection('users').doc(currentUser.uid).update({
          'companyIds': [],
          'companyNames': [],
          'primaryCompanyId': null,
        });
        print('✅ Super admin company association fixed in Firestore');
      } else {
        // Find super admin by email
        final usersSnapshot = await _firestore
            .collection('users')
            .where('email', isEqualTo: 'superadmin@platform.com')
            .get();
            
        if (usersSnapshot.docs.isNotEmpty) {
          final doc = usersSnapshot.docs.first;
          await _firestore.collection('users').doc(doc.id).update({
            'companyIds': [],
            'companyNames': [],
            'primaryCompanyId': null,
          });
          print('✅ Super admin company association fixed in Firestore');
        } else {
          print('❌ Super admin user not found in Firestore');
        }
      }
    } catch (e) {
      print('❌ Failed to fix super admin: $e');
    }
  }
  
  // Delete and recreate super admin user
  static Future<void> recreateSuperAdmin() async {
    try {
      print('🔄 Recreating super admin user...');
      
      // Find and delete existing super admin
      final usersSnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: 'superadmin@platform.com')
          .get();
          
      for (final doc in usersSnapshot.docs) {
        await _firestore.collection('users').doc(doc.id).delete();
        print('🗑️ Deleted existing super admin user');
      }
      
      // Create new super admin user
      final credential = await _auth.createUserWithEmailAndPassword(
        email: 'superadmin@platform.com',
        password: 'password123',
      );
      
      if (credential.user != null) {
        // Create user document with no company association
        await _firestore.collection('users').doc(credential.user!.uid).set({
          'id': credential.user!.uid,
          'name': 'Super Admin',
          'email': 'superadmin@platform.com',
          'role': 'superAdmin',
          'createdAt': DateTime.now().toIso8601String(),
          'workplaceIds': [],
          'workplaceNames': [],
          'companyIds': [],
          'companyNames': [],
          'primaryCompanyId': null,
          'totalPoints': 0,
          'companyPoints': {},
          'companyRoles': {},
        });
        print('✅ Super admin user recreated successfully');
      }
    } catch (e) {
      print('❌ Failed to recreate super admin: $e');
    }
  }
}
