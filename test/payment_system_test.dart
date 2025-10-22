import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bonuses/models/payment_card.dart';
import 'package:bonuses/models/financial_transaction.dart';
import 'package:bonuses/models/payment_record.dart';
import 'package:bonuses/services/payment_service.dart';
import 'package:bonuses/services/storage_service.dart';

void main() {
  group('Payment System Tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    group('Payment Card Management', () {
      test('Can add payment card', () async {
        final card = await PaymentService.addPaymentCard(
          companyId: 'test_company',
          userId: 'test_user',
          cardNumber: '4111111111111111',
          expiryMonth: 12,
          expiryYear: 2025,
          cvc: '123',
          cardholderName: 'John Doe',
        );

        expect(card, isNotNull);
        expect(card!.companyId, 'test_company');
        expect(card.userId, 'test_user');
        expect(card.lastFourDigits, '1111');
        expect(card.brand, 'Visa');
        expect(card.cardType, CardType.visa);
        expect(card.expiryMonth, 12);
        expect(card.expiryYear, 2025);
        expect(card.cardholderName, 'John Doe');
        expect(card.status, CardStatus.active);
        expect(card.isValid, true);
      });

      test('Can retrieve company payment cards', () async {
        // Add multiple cards for different companies
        await PaymentService.addPaymentCard(
          companyId: 'company_1',
          userId: 'user_1',
          cardNumber: '4111111111111111',
          expiryMonth: 12,
          expiryYear: 2025,
          cvc: '123',
        );

        await PaymentService.addPaymentCard(
          companyId: 'company_2',
          userId: 'user_2',
          cardNumber: '5555555555554444',
          expiryMonth: 6,
          expiryYear: 2026,
          cvc: '456',
        );

        final company1Cards = await PaymentService.getCompanyPaymentCards('company_1');
        final company2Cards = await PaymentService.getCompanyPaymentCards('company_2');

        expect(company1Cards.length, 1);
        expect(company2Cards.length, 1);
        expect(company1Cards.first.companyId, 'company_1');
        expect(company2Cards.first.companyId, 'company_2');
      });

      test('Can set default payment card', () async {
        // Add two cards
        final card1 = await PaymentService.addPaymentCard(
          companyId: 'test_company',
          userId: 'test_user',
          cardNumber: '4111111111111111',
          expiryMonth: 12,
          expiryYear: 2025,
          cvc: '123',
        );

        final card2 = await PaymentService.addPaymentCard(
          companyId: 'test_company',
          userId: 'test_user',
          cardNumber: '5555555555554444',
          expiryMonth: 6,
          expiryYear: 2026,
          cvc: '456',
        );

        // Set first card as default
        await PaymentService.setDefaultCard(card1!.id);

        // Set second card as default
        await PaymentService.setDefaultCard(card2!.id);

        final cards = await PaymentService.getCompanyPaymentCards('test_company');
        final defaultCard = cards.firstWhere((c) => c.isDefault);
        final nonDefaultCard = cards.firstWhere((c) => !c.isDefault);

        expect(defaultCard.id, card2.id);
        expect(nonDefaultCard.id, card1.id);
      });

      test('Can delete payment card', () async {
        final card = await PaymentService.addPaymentCard(
          companyId: 'test_company',
          userId: 'test_user',
          cardNumber: '4111111111111111',
          expiryMonth: 12,
          expiryYear: 2025,
          cvc: '123',
        );

        await PaymentService.deletePaymentCard(card!.id);

        final cards = await PaymentService.getCompanyPaymentCards('test_company');
        expect(cards.isEmpty, true);
      });

      test('Card expiration detection works', () async {
        final expiredCard = await PaymentService.addPaymentCard(
          companyId: 'test_company',
          userId: 'test_user',
          cardNumber: '4111111111111111',
          expiryMonth: 1,
          expiryYear: 2020, // Expired
          cvc: '123',
        );

        final validCard = await PaymentService.addPaymentCard(
          companyId: 'test_company',
          userId: 'test_user',
          cardNumber: '5555555555554444',
          expiryMonth: 12,
          expiryYear: 2030, // Valid
          cvc: '456',
        );

        expect(expiredCard!.isExpired, true);
        expect(validCard!.isExpired, false);
        expect(expiredCard.isValid, false);
        expect(validCard.isValid, true);
      });
    });

    group('Financial Transaction Processing', () {
      test('Can process payment', () async {
        // Add a payment card first
        final card = await PaymentService.addPaymentCard(
          companyId: 'test_company',
          userId: 'test_user',
          cardNumber: '4111111111111111',
          expiryMonth: 12,
          expiryYear: 2025,
          cvc: '123',
        );

        // Process a payment
        final transaction = await PaymentService.processPayment(
          companyId: 'test_company',
          userId: 'test_user',
          cardId: card!.id,
          amount: 99.99,
          description: 'Test payment',
          type: TransactionType.subscription,
          category: TransactionCategory.subscription,
        );

        expect(transaction, isNotNull);
        expect(transaction!.companyId, 'test_company');
        expect(transaction.userId, 'test_user');
        expect(transaction.amount, 99.99);
        expect(transaction.description, 'Test payment');
        expect(transaction.type, TransactionType.subscription);
        expect(transaction.category, TransactionCategory.subscription);
        expect(transaction.isSuccessful, true);
      });

      test('Can process subscription payment', () async {
        // Add a payment card
        final card = await PaymentService.addPaymentCard(
          companyId: 'test_company',
          userId: 'test_user',
          cardNumber: '4111111111111111',
          expiryMonth: 12,
          expiryYear: 2025,
          cvc: '123',
        );

        // Process subscription payment
        final paymentRecord = await PaymentService.processSubscriptionPayment(
          companyId: 'test_company',
          subscriptionId: 'sub_123',
          amount: 29.99,
          cardId: card!.id,
        );

        expect(paymentRecord, isNotNull);
        expect(paymentRecord!.companyId, 'test_company');
        expect(paymentRecord.subscriptionId, 'sub_123');
        expect(paymentRecord.amount, 29.99);
        expect(paymentRecord.status, PaymentStatus.completed);
      });

      test('Can refund transaction', () async {
        // Add a payment card and process payment
        final card = await PaymentService.addPaymentCard(
          companyId: 'test_company',
          userId: 'test_user',
          cardNumber: '4111111111111111',
          expiryMonth: 12,
          expiryYear: 2025,
          cvc: '123',
        );

        final transaction = await PaymentService.processPayment(
          companyId: 'test_company',
          userId: 'test_user',
          cardId: card!.id,
          amount: 50.00,
          description: 'Test payment',
          type: TransactionType.subscription,
          category: TransactionCategory.subscription,
        );

        // Refund the transaction
        final refundedTransaction = await PaymentService.refundTransaction(
          transactionId: transaction!.id,
          refundAmount: 25.00,
          reason: 'Partial refund',
        );

        expect(refundedTransaction, isNotNull);
        expect(refundedTransaction!.status, TransactionStatus.partiallyRefunded);
        expect(refundedTransaction.refundedAmount, 25.00);
        expect(refundedTransaction.effectiveAmount, 25.00);
      });

      test('Can retrieve company transactions', () async {
        // Add cards and process payments for different companies
        final card1 = await PaymentService.addPaymentCard(
          companyId: 'company_1',
          userId: 'user_1',
          cardNumber: '4111111111111111',
          expiryMonth: 12,
          expiryYear: 2025,
          cvc: '123',
        );

        final card2 = await PaymentService.addPaymentCard(
          companyId: 'company_2',
          userId: 'user_2',
          cardNumber: '5555555555554444',
          expiryMonth: 6,
          expiryYear: 2026,
          cvc: '456',
        );

        // Process payments for both companies
        await PaymentService.processPayment(
          companyId: 'company_1',
          userId: 'user_1',
          cardId: card1!.id,
          amount: 100.00,
          description: 'Company 1 payment',
          type: TransactionType.subscription,
          category: TransactionCategory.subscription,
        );

        await PaymentService.processPayment(
          companyId: 'company_2',
          userId: 'user_2',
          cardId: card2!.id,
          amount: 200.00,
          description: 'Company 2 payment',
          type: TransactionType.subscription,
          category: TransactionCategory.subscription,
        );

        final company1Transactions = await PaymentService.getCompanyTransactions('company_1');
        final company2Transactions = await PaymentService.getCompanyTransactions('company_2');

        expect(company1Transactions.length, 1);
        expect(company2Transactions.length, 1);
        expect(company1Transactions.first.companyId, 'company_1');
        expect(company2Transactions.first.companyId, 'company_2');
      });
    });

    group('Card Type Detection', () {
      test('Detects Visa cards correctly', () async {
        final visaCard = await PaymentService.addPaymentCard(
          companyId: 'test_company',
          userId: 'test_user',
          cardNumber: '4111111111111111',
          expiryMonth: 12,
          expiryYear: 2025,
          cvc: '123',
        );

        expect(visaCard!.cardType, CardType.visa);
        expect(visaCard.brand, 'Visa');
      });

      test('Detects Mastercard correctly', () async {
        final mastercard = await PaymentService.addPaymentCard(
          companyId: 'test_company',
          userId: 'test_user',
          cardNumber: '5555555555554444',
          expiryMonth: 12,
          expiryYear: 2025,
          cvc: '123',
        );

        expect(mastercard!.cardType, CardType.mastercard);
        expect(mastercard.brand, 'Mastercard');
      });

      test('Detects American Express correctly', () async {
        final amexCard = await PaymentService.addPaymentCard(
          companyId: 'test_company',
          userId: 'test_user',
          cardNumber: '378282246310005',
          expiryMonth: 12,
          expiryYear: 2025,
          cvc: '123',
        );

        expect(amexCard!.cardType, CardType.americanExpress);
        expect(amexCard.brand, 'American Express');
      });
    });

    group('Transaction Status and Categories', () {
      test('Transaction status properties work correctly', () async {
        final card = await PaymentService.addPaymentCard(
          companyId: 'test_company',
          userId: 'test_user',
          cardNumber: '4111111111111111',
          expiryMonth: 12,
          expiryYear: 2025,
          cvc: '123',
        );

        final transaction = await PaymentService.processPayment(
          companyId: 'test_company',
          userId: 'test_user',
          cardId: card!.id,
          amount: 50.00,
          description: 'Test payment',
          type: TransactionType.subscription,
          category: TransactionCategory.subscription,
        );

        expect(transaction!.isSuccessful, true);
        expect(transaction.isFailed, false);
        expect(transaction.isRefunded, false);
        expect(transaction.effectiveAmount, 50.00);
      });

      test('Refunded transaction properties work correctly', () async {
        final card = await PaymentService.addPaymentCard(
          companyId: 'test_company',
          userId: 'test_user',
          cardNumber: '4111111111111111',
          expiryMonth: 12,
          expiryYear: 2025,
          cvc: '123',
        );

        final transaction = await PaymentService.processPayment(
          companyId: 'test_company',
          userId: 'test_user',
          cardId: card!.id,
          amount: 100.00,
          description: 'Test payment',
          type: TransactionType.subscription,
          category: TransactionCategory.subscription,
        );

        final refundedTransaction = await PaymentService.refundTransaction(
          transactionId: transaction!.id,
          refundAmount: 100.00,
        );

        expect(refundedTransaction, isNotNull);
        expect(refundedTransaction!.isSuccessful, true);
        expect(refundedTransaction.isRefunded, true);
        expect(refundedTransaction.effectiveAmount, 0.00);
      });
    });

    group('Error Handling', () {
      test('Handles invalid card number gracefully', () async {
        final card = await PaymentService.addPaymentCard(
          companyId: 'test_company',
          userId: 'test_user',
          cardNumber: '1234', // Invalid card number
          expiryMonth: 12,
          expiryYear: 2025,
          cvc: '123',
        );

        expect(card, isNotNull);
        expect(card!.cardType, CardType.unknown);
        expect(card.brand, 'Unknown');
      });

      test('Handles payment processing errors', () async {
        // Try to process payment with invalid card
        final transaction = await PaymentService.processPayment(
          companyId: 'test_company',
          userId: 'test_user',
          cardId: 'invalid_card_id',
          amount: 50.00,
          description: 'Test payment',
          type: TransactionType.subscription,
          category: TransactionCategory.subscription,
        );

        expect(transaction, isNotNull);
        expect(transaction!.isFailed, true);
        expect(transaction.failureReason, isNotNull);
      });
    });
  });
}
