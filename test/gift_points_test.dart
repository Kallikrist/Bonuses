import 'package:flutter_test/flutter_test.dart';
import 'package:bonuses/providers/app_provider.dart';
import 'package:bonuses/models/user.dart';
import 'package:bonuses/models/company.dart';
import 'package:bonuses/models/points_transaction.dart';
import 'package:bonuses/services/storage_service.dart';
import 'test_helpers.dart';

void main() {
  // Initialize Flutter binding and mock shared_preferences
  setupSharedPreferencesMock();

  group('Gift Points Tests', () {
    late AppProvider appProvider;
    late User sender;
    late User recipient;
    late Company testCompany;

    setUp(() async {
      // Clear storage before each test
      await StorageService.clearAllData();

      appProvider = AppProvider();

      // Create test company
      testCompany = Company(
        id: 'test_company',
        name: 'Test Company',
        address: '123 Test St',
        contactEmail: 'test@company.com',
        contactPhone: '555-0100',
        adminUserId: 'sender',
        createdAt: DateTime.now(),
      );

      // Create sender with some points
      sender = User(
        id: 'sender',
        name: 'Alice Sender',
        email: 'alice@test.com',
        role: UserRole.employee,
        createdAt: DateTime.now(),
        primaryCompanyId: testCompany.id,
        companyIds: [testCompany.id],
        companyRoles: {testCompany.id: 'employee'},
        companyPoints: {testCompany.id: 100}, // Start with 100 points
      );

      // Create recipient
      recipient = User(
        id: 'recipient',
        name: 'Bob Recipient',
        email: 'bob@test.com',
        role: UserRole.employee,
        createdAt: DateTime.now(),
        primaryCompanyId: testCompany.id,
        companyIds: [testCompany.id],
        companyRoles: {testCompany.id: 'employee'},
        companyPoints: {testCompany.id: 50}, // Start with 50 points
      );

      // Save test data
      await StorageService.addCompany(testCompany);
      await StorageService.addUser(sender);
      await StorageService.addUser(recipient);

      // Set current user and initialize provider
      await StorageService.setCurrentUser(sender);
      await appProvider.initialize();

      // Give users their initial points AFTER initialization
      // (initialize() resets points, so we add them afterwards)
      await appProvider.updateUserPoints(
        sender.id,
        100,
        'Initial test balance',
        companyId: testCompany.id,
      );

      await appProvider.updateUserPoints(
        recipient.id,
        50,
        'Initial test balance',
        companyId: testCompany.id,
      );
    });

    tearDown(() async {
      await StorageService.clearAllData();
    });

    group('Points Gifting Flow', () {
      test('User can gift points to another user', () async {
        // Gift 25 points
        await appProvider.updateUserPoints(
          sender.id,
          -25,
          'Gifted to ${recipient.name}',
          companyId: testCompany.id,
        );

        await appProvider.updateUserPoints(
          recipient.id,
          25,
          'Gift from ${sender.name}',
          companyId: testCompany.id,
        );

        // Verify sender's points decreased
        final senderPoints =
            appProvider.getUserCompanyPoints(sender.id, testCompany.id);
        expect(senderPoints, 75); // 100 - 25

        // Verify recipient's points increased
        final recipientPoints =
            appProvider.getUserCompanyPoints(recipient.id, testCompany.id);
        expect(recipientPoints, 75); // 50 + 25
      });

      test('Gifting deducts points from sender', () async {
        final initialPoints =
            appProvider.getUserCompanyPoints(sender.id, testCompany.id);

        await appProvider.updateUserPoints(
          sender.id,
          -30,
          'Gifted to ${recipient.name}',
          companyId: testCompany.id,
        );

        final finalPoints =
            appProvider.getUserCompanyPoints(sender.id, testCompany.id);
        expect(finalPoints, initialPoints - 30);
      });

      test('Gifting adds points to recipient', () async {
        final initialPoints =
            appProvider.getUserCompanyPoints(recipient.id, testCompany.id);

        await appProvider.updateUserPoints(
          recipient.id,
          30,
          'Gift from ${sender.name}',
          companyId: testCompany.id,
        );

        final finalPoints =
            appProvider.getUserCompanyPoints(recipient.id, testCompany.id);
        expect(finalPoints, initialPoints + 30);
      });

      test('Points are transferred within same company', () async {
        // Gift points
        await appProvider.updateUserPoints(
          sender.id,
          -20,
          'Gifted to ${recipient.name}',
          companyId: testCompany.id,
        );

        await appProvider.updateUserPoints(
          recipient.id,
          20,
          'Gift from ${sender.name}',
          companyId: testCompany.id,
        );

        // Verify points are in the correct company
        final senderPoints =
            appProvider.getUserCompanyPoints(sender.id, testCompany.id);
        final recipientPoints =
            appProvider.getUserCompanyPoints(recipient.id, testCompany.id);

        expect(senderPoints, 80);
        expect(recipientPoints, 70);
      });
    });

    group('Gift Points Validation', () {
      test('Can gift all available points', () async {
        // Gift all 100 points
        await appProvider.updateUserPoints(
          sender.id,
          -100,
          'Gifted to ${recipient.name}',
          companyId: testCompany.id,
        );

        final senderPoints =
            appProvider.getUserCompanyPoints(sender.id, testCompany.id);
        expect(senderPoints, 0);
      });

      test('Gifting more than available is prevented by safety mechanism',
          () async {
        // The backend prevents negative balances (safety feature)
        // UI also validates, but backend is the final guard
        await appProvider.updateUserPoints(
          sender.id,
          -150, // More than the 100 available
          'Gifted to ${recipient.name}',
          companyId: testCompany.id,
        );

        final senderPoints =
            appProvider.getUserCompanyPoints(sender.id, testCompany.id);
        expect(senderPoints, 100); // Unchanged - transaction was blocked
      });

      test('Gifting zero points works but is pointless', () async {
        final initialSenderPoints =
            appProvider.getUserCompanyPoints(sender.id, testCompany.id);
        final initialRecipientPoints =
            appProvider.getUserCompanyPoints(recipient.id, testCompany.id);

        await appProvider.updateUserPoints(
          sender.id,
          0,
          'Gifted to ${recipient.name}',
          companyId: testCompany.id,
        );

        final finalSenderPoints =
            appProvider.getUserCompanyPoints(sender.id, testCompany.id);
        final finalRecipientPoints =
            appProvider.getUserCompanyPoints(recipient.id, testCompany.id);

        expect(finalSenderPoints, initialSenderPoints);
        expect(finalRecipientPoints, initialRecipientPoints);
      });
    });

    group('Gift Points Transactions', () {
      test('Sender transaction is created with correct description', () async {
        await appProvider.updateUserPoints(
          sender.id,
          -25,
          'Gifted to ${recipient.name}',
          companyId: testCompany.id,
        );

        // Get transactions
        final transactions = appProvider.pointsTransactions;
        final senderTransaction = transactions.lastWhere(
          (t) => t.userId == sender.id && t.description.contains('Gifted to'),
        );

        expect(senderTransaction.description, contains('Gifted to'));
        expect(senderTransaction.description, contains(recipient.name));
        expect(senderTransaction.companyId, testCompany.id);
      });

      test('Recipient transaction is created with correct description',
          () async {
        await appProvider.updateUserPoints(
          recipient.id,
          25,
          'Gift from ${sender.name}',
          companyId: testCompany.id,
        );

        // Get transactions
        final transactions = appProvider.pointsTransactions;
        final recipientTransaction = transactions.lastWhere(
          (t) => t.userId == recipient.id && t.points == 25,
        );

        expect(recipientTransaction.description, contains('Gift from'));
        expect(recipientTransaction.description, contains(sender.name));
        expect(recipientTransaction.companyId, testCompany.id);
      });

      test('Gift with message includes message in transaction', () async {
        const giftMessage = 'Great work on the sale!';

        await appProvider.updateUserPoints(
          sender.id,
          -10,
          'Gifted to ${recipient.name}: $giftMessage',
          companyId: testCompany.id,
        );

        final transactions = appProvider.pointsTransactions;
        final transaction = transactions.lastWhere(
          (t) => t.userId == sender.id && t.description.contains('Gifted to'),
        );

        expect(transaction.description, contains(giftMessage));
      });

      test('Gift without message has simple description', () async {
        await appProvider.updateUserPoints(
          sender.id,
          -10,
          'Gifted to ${recipient.name}',
          companyId: testCompany.id,
        );

        final transactions = appProvider.pointsTransactions;
        final transaction = transactions.lastWhere(
          (t) => t.userId == sender.id && t.description.contains('Gifted to'),
        );

        expect(transaction.description, 'Gifted to ${recipient.name}');
        expect(transaction.description, isNot(contains(':')));
      });

      test('Both transactions have correct company context', () async {
        await appProvider.updateUserPoints(
          sender.id,
          -15,
          'Gifted to ${recipient.name}',
          companyId: testCompany.id,
        );

        await appProvider.updateUserPoints(
          recipient.id,
          15,
          'Gift from ${sender.name}',
          companyId: testCompany.id,
        );

        final transactions = appProvider.pointsTransactions;
        final senderTx = transactions.lastWhere(
          (t) => t.userId == sender.id && t.description.contains('Gifted to'),
        );
        final recipientTx = transactions.lastWhere(
          (t) =>
              t.userId == recipient.id && t.description.contains('Gift from'),
        );

        expect(senderTx.companyId, testCompany.id);
        expect(recipientTx.companyId, testCompany.id);
      });
    });

    group('Gift Points Edge Cases', () {
      test('Multiple consecutive gifts work correctly', () async {
        // Gift 10 points three times
        for (int i = 0; i < 3; i++) {
          await appProvider.updateUserPoints(
            sender.id,
            -10,
            'Gifted to ${recipient.name}',
            companyId: testCompany.id,
          );

          await appProvider.updateUserPoints(
            recipient.id,
            10,
            'Gift from ${sender.name}',
            companyId: testCompany.id,
          );
        }

        final senderPoints =
            appProvider.getUserCompanyPoints(sender.id, testCompany.id);
        final recipientPoints =
            appProvider.getUserCompanyPoints(recipient.id, testCompany.id);

        expect(senderPoints, 70); // 100 - 30
        expect(recipientPoints, 80); // 50 + 30
      });

      test('Gift with very long message is handled', () async {
        final longMessage = 'A' * 500; // 500 character message

        await appProvider.updateUserPoints(
          sender.id,
          -5,
          'Gifted to ${recipient.name}: $longMessage',
          companyId: testCompany.id,
        );

        final transactions = appProvider.pointsTransactions;
        final transaction = transactions.lastWhere(
          (t) => t.userId == sender.id && t.description.contains('Gifted to'),
        );

        expect(transaction.description, contains(longMessage));
      });

      test('Gift with special characters in message works', () async {
        const specialMessage =
            'Great job! 🎉 You\'re amazing & deserve this 💯';

        await appProvider.updateUserPoints(
          sender.id,
          -5,
          'Gifted to ${recipient.name}: $specialMessage',
          companyId: testCompany.id,
        );

        final transactions = appProvider.pointsTransactions;
        final transaction = transactions.lastWhere(
          (t) => t.userId == sender.id && t.description.contains('Gifted to'),
        );

        expect(transaction.description, contains(specialMessage));
      });

      test('Total points in system remains constant after gift', () async {
        final initialTotal =
            appProvider.getUserCompanyPoints(sender.id, testCompany.id) +
                appProvider.getUserCompanyPoints(recipient.id, testCompany.id);

        // Gift 40 points
        await appProvider.updateUserPoints(
          sender.id,
          -40,
          'Gifted to ${recipient.name}',
          companyId: testCompany.id,
        );

        await appProvider.updateUserPoints(
          recipient.id,
          40,
          'Gift from ${sender.name}',
          companyId: testCompany.id,
        );

        final finalTotal =
            appProvider.getUserCompanyPoints(sender.id, testCompany.id) +
                appProvider.getUserCompanyPoints(recipient.id, testCompany.id);

        expect(finalTotal, initialTotal); // Conservation of points
      });
    });

    group('Company Isolation', () {
      test('Points are only gifted within same company', () async {
        // Create second company
        final otherCompany = Company(
          id: 'other_company',
          name: 'Other Company',
          address: '456 Other St',
          contactEmail: 'other@company.com',
          contactPhone: '555-0200',
          adminUserId: 'admin2',
          createdAt: DateTime.now(),
        );

        await StorageService.addCompany(otherCompany);

        // Gift points in test company
        await appProvider.updateUserPoints(
          sender.id,
          -20,
          'Gifted to ${recipient.name}',
          companyId: testCompany.id,
        );

        // Verify points in other company are unaffected
        final senderOtherPoints =
            appProvider.getUserCompanyPoints(sender.id, otherCompany.id);
        expect(senderOtherPoints, 0); // No points in other company
      });

      test('User with multiple companies can gift in specific company',
          () async {
        // Create second company
        final company2 = Company(
          id: 'company2',
          name: 'Company Two',
          address: '789 Second St',
          contactEmail: 'company2@test.com',
          contactPhone: '555-0300',
          adminUserId: 'sender',
          createdAt: DateTime.now(),
        );

        await StorageService.addCompany(company2);

        // Update sender to be in both companies
        final updatedSender = sender.copyWith(
          companyIds: [testCompany.id, company2.id],
          companyRoles: {
            testCompany.id: 'employee',
            company2.id: 'employee',
          },
        );

        await appProvider.updateUser(updatedSender);

        // Give sender points in company2
        await appProvider.updateUserPoints(
          sender.id,
          200,
          'Initial test balance company2',
          companyId: company2.id,
        );

        // Gift from company2
        await appProvider.updateUserPoints(
          sender.id,
          -50,
          'Gifted in Company 2',
          companyId: company2.id,
        );

        // Verify correct company was affected
        final company1Points =
            appProvider.getUserCompanyPoints(sender.id, testCompany.id);
        final company2Points =
            appProvider.getUserCompanyPoints(sender.id, company2.id);

        expect(company1Points, 100); // Unchanged
        expect(company2Points, 150); // 200 - 50
      });
    });

    group('Transaction History', () {
      test('Gift creates two transaction records', () async {
        final initialTransactionCount = appProvider.pointsTransactions.length;

        await appProvider.updateUserPoints(
          sender.id,
          -15,
          'Gifted to ${recipient.name}',
          companyId: testCompany.id,
        );

        await appProvider.updateUserPoints(
          recipient.id,
          15,
          'Gift from ${sender.name}',
          companyId: testCompany.id,
        );

        final finalTransactionCount = appProvider.pointsTransactions.length;
        expect(finalTransactionCount, initialTransactionCount + 2);
      });

      test('Transaction amounts match gift amount', () async {
        const giftAmount = 35;

        await appProvider.updateUserPoints(
          sender.id,
          -giftAmount,
          'Gifted to ${recipient.name}',
          companyId: testCompany.id,
        );

        await appProvider.updateUserPoints(
          recipient.id,
          giftAmount,
          'Gift from ${sender.name}',
          companyId: testCompany.id,
        );

        final transactions = appProvider.pointsTransactions;
        final senderTx = transactions.lastWhere(
          (t) => t.userId == sender.id && t.description.contains('Gifted to'),
        );
        final recipientTx = transactions.lastWhere(
          (t) =>
              t.userId == recipient.id && t.description.contains('Gift from'),
        );

        // Points are stored as absolute values, type indicates direction
        expect(senderTx.points, giftAmount); // Stored as positive
        expect(senderTx.type,
            PointsTransactionType.redeemed); // Type indicates it's a deduction
        expect(recipientTx.points, giftAmount);
        expect(recipientTx.type, PointsTransactionType.earned);
      });

      test('Transaction timestamps are recorded correctly', () async {
        final beforeTime = DateTime.now();

        await appProvider.updateUserPoints(
          sender.id,
          -10,
          'Gifted to ${recipient.name}',
          companyId: testCompany.id,
        );

        final afterTime = DateTime.now();

        final transactions = appProvider.pointsTransactions;
        final transaction = transactions.lastWhere(
          (t) => t.userId == sender.id && t.description.contains('Gifted to'),
        );

        expect(
            transaction.date.isAfter(beforeTime.subtract(Duration(seconds: 1))),
            true);
        expect(transaction.date.isBefore(afterTime.add(Duration(seconds: 1))),
            true);
      });
    });

    group('Data Persistence', () {
      test('Gift transactions are persisted to storage', () async {
        await appProvider.updateUserPoints(
          sender.id,
          -25,
          'Gifted to ${recipient.name}',
          companyId: testCompany.id,
        );

        // Reload data from storage
        final storedTransactions = await StorageService.getPointsTransactions();
        final giftTransaction = storedTransactions.lastWhere(
          (t) => t.userId == sender.id && t.description.contains('Gifted'),
        );

        // Points are stored as absolute values
        expect(giftTransaction.points, 25);
        expect(giftTransaction.type, PointsTransactionType.redeemed);
        expect(giftTransaction.companyId, testCompany.id);
      });

      test('Updated user points are persisted to storage', () async {
        await appProvider.updateUserPoints(
          sender.id,
          -30,
          'Gifted to ${recipient.name}',
          companyId: testCompany.id,
        );

        // Reload users from storage
        final storedUsers = await StorageService.getUsers();
        final storedSender = storedUsers.firstWhere((u) => u.id == sender.id);

        expect(storedSender.companyPoints[testCompany.id], 70);
      });
    });

    group('Gift Points with Messages', () {
      test('Short message is included correctly', () async {
        const message = 'Thanks!';

        await appProvider.updateUserPoints(
          sender.id,
          -10,
          'Gifted to ${recipient.name}: $message',
          companyId: testCompany.id,
        );

        final transactions = appProvider.pointsTransactions;
        final transaction = transactions.lastWhere(
          (t) => t.userId == sender.id && t.description.contains('Gifted to'),
        );

        expect(
            transaction.description, 'Gifted to ${recipient.name}: $message');
      });

      test('Empty message results in simple description', () async {
        await appProvider.updateUserPoints(
          sender.id,
          -10,
          'Gifted to ${recipient.name}',
          companyId: testCompany.id,
        );

        final transactions = appProvider.pointsTransactions;
        final transaction = transactions.lastWhere(
          (t) => t.userId == sender.id && t.description.contains('Gifted to'),
        );

        expect(transaction.description, 'Gifted to ${recipient.name}');
      });

      test('Message with newlines is preserved', () async {
        const message = 'Line 1\nLine 2\nLine 3';

        await appProvider.updateUserPoints(
          sender.id,
          -5,
          'Gifted to ${recipient.name}: $message',
          companyId: testCompany.id,
        );

        final transactions = appProvider.pointsTransactions;
        final transaction = transactions.lastWhere(
          (t) => t.userId == sender.id && t.description.contains('Gifted to'),
        );

        expect(transaction.description, contains('Line 1\nLine 2\nLine 3'));
      });
    });
  });
}
