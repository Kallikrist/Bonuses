import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../lib/firebase_options.dart';

void main() {
  group('Firebase Connection Tests', () {
    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    });

    test('Firebase app should be initialized', () {
      expect(Firebase.apps.isNotEmpty, true);
      print('✅ Firebase app initialized successfully');
    });

    test('Firestore connection should work', () async {
      try {
        final firestore = FirebaseFirestore.instance;
        await firestore.collection('test').doc('connection_test').set({
          'test': 'value',
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        });
        print('✅ Firestore write successful');

        // Clean up
        await firestore.collection('test').doc('connection_test').delete();
        print('✅ Firestore cleanup successful');
      } catch (e) {
        print('❌ Firestore connection failed: $e');
        rethrow;
      }
    });

    test('Firebase Auth should be available', () {
      final auth = FirebaseAuth.instance;
      expect(auth, isNotNull);
      print('✅ Firebase Auth instance available');
    });

    test('Create test user in Firebase Auth', () async {
      try {
        final auth = FirebaseAuth.instance;

        // Try to create a test user
        final credential = await auth.createUserWithEmailAndPassword(
          email: 'test@example.com',
          password: 'testpassword123',
        );

        expect(credential.user, isNotNull);
        print('✅ Firebase Auth user creation successful');

        // Clean up - delete the test user
        await credential.user?.delete();
        print('✅ Firebase Auth user cleanup successful');
      } catch (e) {
        print('❌ Firebase Auth user creation failed: $e');
        rethrow;
      }
    });
  });
}
