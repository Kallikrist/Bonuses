import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/user.dart' as models;
import '../models/company.dart';
import '../models/sales_target.dart';
import '../models/bonus.dart';
import '../models/company_subscription.dart';
import '../models/payment_card.dart';
import '../models/financial_transaction.dart';
import '../models/bank_account.dart';
import '../models/notification.dart';

class FirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // Collections
  static const String _usersCollection = 'users';
  static const String _companiesCollection = 'companies';
  static const String _targetsCollection = 'targets';
  static const String _bonusesCollection = 'bonuses';
  static const String _subscriptionsCollection = 'subscriptions';
  static const String _paymentCardsCollection = 'payment_cards';
  static const String _transactionsCollection = 'transactions';
  static const String _bankAccountsCollection = 'bank_accounts';
  static const String _notificationsCollection = 'notifications';

  // Initialize Firebase
  static Future<void> initialize() async {
    try {
      await _messaging.requestPermission();
      print('Firebase initialized successfully');
    } catch (e) {
      print('Firebase initialization failed: $e');
      rethrow;
    }
  }

  // Authentication
  static Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user;
    } catch (e) {
      print('Sign in failed: $e');
      rethrow;
    }
  }

  static Future<User?> createUserWithEmailAndPassword(String email, String password) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user;
    } catch (e) {
      print('User creation failed: $e');
      rethrow;
    }
  }

  static Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('Sign out failed: $e');
      rethrow;
    }
  }

  static User? get currentUser => _auth.currentUser;

  // Users
  static Future<void> createUser(models.User user) async {
    try {
      await _firestore.collection(_usersCollection).doc(user.id).set(user.toJson());
    } catch (e) {
      print('Create user failed: $e');
      rethrow;
    }
  }

  static Future<models.User?> getUser(String userId) async {
    try {
      final doc = await _firestore.collection(_usersCollection).doc(userId).get();
      if (doc.exists) {
        return models.User.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Get user failed: $e');
      rethrow;
    }
  }

  static Future<List<models.User>> getUsersByCompany(String companyId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_usersCollection)
          .where('companyId', isEqualTo: companyId)
          .get();
      
      return querySnapshot.docs
          .map((doc) => models.User.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('Get users by company failed: $e');
      rethrow;
    }
  }

  static Future<void> updateUser(models.User user) async {
    try {
      await _firestore.collection(_usersCollection).doc(user.id).update(user.toJson());
    } catch (e) {
      print('Update user failed: $e');
      rethrow;
    }
  }

  // Companies
  static Future<void> createCompany(Company company) async {
    try {
      await _firestore.collection(_companiesCollection).doc(company.id).set(company.toJson());
    } catch (e) {
      print('Create company failed: $e');
      rethrow;
    }
  }

  static Future<Company?> getCompany(String companyId) async {
    try {
      final doc = await _firestore.collection(_companiesCollection).doc(companyId).get();
      if (doc.exists) {
        return Company.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Get company failed: $e');
      rethrow;
    }
  }

  static Future<List<Company>> getAllCompanies() async {
    try {
      final querySnapshot = await _firestore.collection(_companiesCollection).get();
      return querySnapshot.docs
          .map((doc) => Company.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('Get all companies failed: $e');
      rethrow;
    }
  }

  static Future<void> updateCompany(Company company) async {
    try {
      await _firestore.collection(_companiesCollection).doc(company.id).update(company.toJson());
    } catch (e) {
      print('Update company failed: $e');
      rethrow;
    }
  }

  // Sales Targets
  static Future<void> createTarget(SalesTarget target) async {
    try {
      await _firestore.collection(_targetsCollection).doc(target.id).set(target.toJson());
    } catch (e) {
      print('Create target failed: $e');
      rethrow;
    }
  }

  static Future<List<SalesTarget>> getTargetsByCompany(String companyId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_targetsCollection)
          .where('companyId', isEqualTo: companyId)
          .orderBy('createdAt', descending: true)
          .get();
      
      return querySnapshot.docs
          .map((doc) => SalesTarget.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('Get targets by company failed: $e');
      rethrow;
    }
  }

  static Future<void> updateTarget(SalesTarget target) async {
    try {
      await _firestore.collection(_targetsCollection).doc(target.id).update(target.toJson());
    } catch (e) {
      print('Update target failed: $e');
      rethrow;
    }
  }

  static Future<void> deleteTarget(String targetId) async {
    try {
      await _firestore.collection(_targetsCollection).doc(targetId).delete();
    } catch (e) {
      print('Delete target failed: $e');
      rethrow;
    }
  }

  // Bonuses
  static Future<void> createBonus(Bonus bonus) async {
    try {
      await _firestore.collection(_bonusesCollection).doc(bonus.id).set(bonus.toJson());
    } catch (e) {
      print('Create bonus failed: $e');
      rethrow;
    }
  }

  static Future<List<Bonus>> getBonusesByCompany(String companyId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_bonusesCollection)
          .where('companyId', isEqualTo: companyId)
          .orderBy('createdAt', descending: true)
          .get();
      
      return querySnapshot.docs
          .map((doc) => Bonus.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('Get bonuses by company failed: $e');
      rethrow;
    }
  }

  static Future<void> updateBonus(Bonus bonus) async {
    try {
      await _firestore.collection(_bonusesCollection).doc(bonus.id).update(bonus.toJson());
    } catch (e) {
      print('Update bonus failed: $e');
      rethrow;
    }
  }

  // Subscriptions
  static Future<void> createSubscription(CompanySubscription subscription) async {
    try {
      await _firestore.collection(_subscriptionsCollection).doc(subscription.id).set(subscription.toJson());
    } catch (e) {
      print('Create subscription failed: $e');
      rethrow;
    }
  }

  static Future<List<CompanySubscription>> getSubscriptionsByCompany(String companyId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_subscriptionsCollection)
          .where('companyId', isEqualTo: companyId)
          .get();
      
      return querySnapshot.docs
          .map((doc) => CompanySubscription.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('Get subscriptions by company failed: $e');
      rethrow;
    }
  }

  static Future<void> updateSubscription(CompanySubscription subscription) async {
    try {
      await _firestore.collection(_subscriptionsCollection).doc(subscription.id).update(subscription.toJson());
    } catch (e) {
      print('Update subscription failed: $e');
      rethrow;
    }
  }

  // Payment Cards
  static Future<void> createPaymentCard(PaymentCard card) async {
    try {
      await _firestore.collection(_paymentCardsCollection).doc(card.id).set(card.toJson());
    } catch (e) {
      print('Create payment card failed: $e');
      rethrow;
    }
  }

  static Future<List<PaymentCard>> getPaymentCardsByUser(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_paymentCardsCollection)
          .where('userId', isEqualTo: userId)
          .get();
      
      return querySnapshot.docs
          .map((doc) => PaymentCard.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('Get payment cards by user failed: $e');
      rethrow;
    }
  }

  // Financial Transactions
  static Future<void> createTransaction(FinancialTransaction transaction) async {
    try {
      await _firestore.collection(_transactionsCollection).doc(transaction.id).set(transaction.toJson());
    } catch (e) {
      print('Create transaction failed: $e');
      rethrow;
    }
  }

  static Future<List<FinancialTransaction>> getTransactionsByCompany(String companyId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_transactionsCollection)
          .where('companyId', isEqualTo: companyId)
          .orderBy('createdAt', descending: true)
          .get();
      
      return querySnapshot.docs
          .map((doc) => FinancialTransaction.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('Get transactions by company failed: $e');
      rethrow;
    }
  }

  // Bank Accounts
  static Future<void> createBankAccount(BankAccount account) async {
    try {
      await _firestore.collection(_bankAccountsCollection).doc(account.id).set(account.toJson());
    } catch (e) {
      print('Create bank account failed: $e');
      rethrow;
    }
  }

  static Future<List<BankAccount>> getBankAccountsByUser(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_bankAccountsCollection)
          .where('userId', isEqualTo: userId)
          .get();
      
      return querySnapshot.docs
          .map((doc) => BankAccount.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('Get bank accounts by user failed: $e');
      rethrow;
    }
  }

  // Notifications
  static Future<void> createNotification(AppNotification notification) async {
    try {
      await _firestore.collection(_notificationsCollection).doc(notification.id).set(notification.toJson());
    } catch (e) {
      print('Create notification failed: $e');
      rethrow;
    }
  }

  static Future<List<AppNotification>> getNotificationsByUser(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_notificationsCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();
      
      return querySnapshot.docs
          .map((doc) => AppNotification.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('Get notifications by user failed: $e');
      rethrow;
    }
  }

  static Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _firestore.collection(_notificationsCollection).doc(notificationId).update({
        'isRead': true,
        'readAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Mark notification as read failed: $e');
      rethrow;
    }
  }

  // Real-time listeners
  static Stream<List<SalesTarget>> watchTargetsByCompany(String companyId) {
    return _firestore
        .collection(_targetsCollection)
        .where('companyId', isEqualTo: companyId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SalesTarget.fromJson(doc.data()))
            .toList());
  }

  static Stream<List<Bonus>> watchBonusesByCompany(String companyId) {
    return _firestore
        .collection(_bonusesCollection)
        .where('companyId', isEqualTo: companyId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Bonus.fromJson(doc.data()))
            .toList());
  }

  static Stream<List<AppNotification>> watchNotificationsByUser(String userId) {
    return _firestore
        .collection(_notificationsCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AppNotification.fromJson(doc.data()))
            .toList());
  }

  // File upload
  static Future<String> uploadFile(String path, Uint8List data) async {
    try {
      final ref = _storage.ref().child(path);
      final uploadTask = ref.putData(data);
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print('File upload failed: $e');
      rethrow;
    }
  }

  // Demo data migration
  static Future<void> migrateDemoData() async {
    try {
      // This will be implemented to migrate existing demo data to Firestore
      print('Demo data migration not yet implemented');
    } catch (e) {
      print('Demo data migration failed: $e');
      rethrow;
    }
  }
}
