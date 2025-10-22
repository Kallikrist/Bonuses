import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/payment_card.dart';
import '../models/financial_transaction.dart';
import '../models/company_subscription.dart';
import '../models/payment_record.dart';
import 'storage_service.dart';

/// Service for handling payment card and transaction processing
class PaymentService {
  // Mock Stripe API endpoints (replace with real Stripe integration)
  static const String _stripeApiUrl = 'https://api.stripe.com/v1';
  static const String _stripePublishableKey = 'pk_test_mock_key';
  static const String _stripeSecretKey = 'sk_test_mock_key';

  /// Add a new payment card for a company
  static Future<PaymentCard?> addPaymentCard({
    required String companyId,
    required String userId,
    required String cardNumber,
    required int expiryMonth,
    required int expiryYear,
    required String cvc,
    String? cardholderName,
  }) async {
    try {
      // In a real implementation, this would use Stripe's API
      // For now, we'll simulate the process
      
      // Extract last 4 digits
      final lastFourDigits = cardNumber.substring(cardNumber.length - 4);
      
      // Determine card type
      final cardType = _determineCardType(cardNumber);
      final brand = _getCardBrand(cardType);
      
      // Create card ID
      final cardId = 'card_${DateTime.now().millisecondsSinceEpoch}';
      
      // Create payment card
      final paymentCard = PaymentCard(
        id: cardId,
        companyId: companyId,
        userId: userId,
        lastFourDigits: lastFourDigits,
        brand: brand,
        cardType: cardType,
        expiryMonth: expiryMonth,
        expiryYear: expiryYear,
        cardholderName: cardholderName,
        status: CardStatus.active,
        createdAt: DateTime.now(),
        stripeCardId: 'stripe_$cardId', // Mock Stripe ID
        fingerprint: _generateFingerprint(cardNumber),
      );

      // Save to storage
      await StorageService.addPaymentCard(paymentCard);
      
      return paymentCard;
    } catch (e) {
      print('Error adding payment card: $e');
      return null;
    }
  }

  /// Process a payment using a card
  static Future<FinancialTransaction?> processPayment({
    required String companyId,
    required String userId,
    required String cardId,
    required double amount,
    required String description,
    required TransactionType type,
    required TransactionCategory category,
    String? subscriptionId,
    String? bonusId,
  }) async {
    try {
      // Get the payment card
      final card = await StorageService.getPaymentCardById(cardId);
      if (card == null || !card.isValid) {
        throw Exception('Invalid payment card');
      }

      // Create transaction ID
      final transactionId = 'txn_${DateTime.now().millisecondsSinceEpoch}';
      
      // Create financial transaction
      final transaction = FinancialTransaction(
        id: transactionId,
        companyId: companyId,
        userId: userId,
        type: type,
        status: TransactionStatus.processing,
        category: category,
        amount: amount,
        description: description,
        createdAt: DateTime.now(),
        paymentCardId: cardId,
        subscriptionId: subscriptionId,
        bonusId: bonusId,
        paymentGateway: 'stripe',
        metadata: {
          'card_last_four': card.lastFourDigits,
          'card_brand': card.brand,
        },
      );

      // Save transaction
      await StorageService.addFinancialTransaction(transaction);

      // Simulate payment processing
      await Future.delayed(const Duration(seconds: 2));

      // Simulate success (in real implementation, call Stripe API)
      final completedTransaction = transaction.copyWith(
        status: TransactionStatus.completed,
        completedAt: DateTime.now(),
        transactionId: 'stripe_$transactionId',
        receiptUrl: 'https://receipt.example.com/$transactionId',
      );

      // Update transaction
      await StorageService.updateFinancialTransaction(completedTransaction);

      // Update card last used
      final updatedCard = card.copyWith(lastUsedAt: DateTime.now());
      await StorageService.updatePaymentCard(updatedCard);

      return completedTransaction;
    } catch (e) {
      print('Error processing payment: $e');
      
      // Create failed transaction
      final failedTransaction = FinancialTransaction(
        id: 'txn_${DateTime.now().millisecondsSinceEpoch}',
        companyId: companyId,
        userId: userId,
        type: type,
        status: TransactionStatus.failed,
        category: category,
        amount: amount,
        description: description,
        createdAt: DateTime.now(),
        paymentCardId: cardId,
        failureReason: e.toString(),
      );

      await StorageService.addFinancialTransaction(failedTransaction);
      return failedTransaction;
    }
  }

  /// Process subscription payment
  static Future<PaymentRecord?> processSubscriptionPayment({
    required String companyId,
    required String subscriptionId,
    required double amount,
    required String cardId,
  }) async {
    try {
      // Process the payment
      final transaction = await processPayment(
        companyId: companyId,
        userId: 'system', // System user for subscription payments
        cardId: cardId,
        amount: amount,
        description: 'Subscription payment',
        type: TransactionType.subscription,
        category: TransactionCategory.subscription,
        subscriptionId: subscriptionId,
      );

      if (transaction == null || !transaction.isSuccessful) {
        return null;
      }

      // Create payment record
      final paymentRecord = PaymentRecord(
        id: 'payment_${DateTime.now().millisecondsSinceEpoch}',
        companyId: companyId,
        subscriptionId: subscriptionId,
        amount: amount,
        status: PaymentStatus.completed,
        date: DateTime.now(),
        invoiceId: 'INV-${DateTime.now().millisecondsSinceEpoch}',
        transactionId: transaction.transactionId,
        paymentGateway: 'stripe',
        receiptUrl: transaction.receiptUrl,
      );

      await StorageService.addPaymentRecord(paymentRecord);
      return paymentRecord;
    } catch (e) {
      print('Error processing subscription payment: $e');
      return null;
    }
  }

  /// Refund a transaction
  static Future<FinancialTransaction?> refundTransaction({
    required String transactionId,
    required double refundAmount,
    String? reason,
  }) async {
    try {
      final transaction = await StorageService.getFinancialTransactionById(transactionId);
      if (transaction == null) {
        throw Exception('Transaction not found');
      }

      if (!transaction.isSuccessful) {
        throw Exception('Cannot refund unsuccessful transaction');
      }

      final refundTransaction = transaction.copyWith(
        status: refundAmount >= transaction.amount 
            ? TransactionStatus.refunded 
            : TransactionStatus.partiallyRefunded,
        refundedAmount: refundAmount,
        refundedAt: DateTime.now(),
        description: '${transaction.description} (Refunded)',
      );

      await StorageService.updateFinancialTransaction(refundTransaction);
      return refundTransaction;
    } catch (e) {
      print('Error refunding transaction: $e');
      return null;
    }
  }

  /// Get company's payment cards
  static Future<List<PaymentCard>> getCompanyPaymentCards(String companyId) async {
    final cards = await StorageService.getPaymentCards();
    return cards.where((card) => card.companyId == companyId).toList();
  }

  /// Get company's financial transactions
  static Future<List<FinancialTransaction>> getCompanyTransactions(String companyId) async {
    final transactions = await StorageService.getFinancialTransactions();
    return transactions.where((tx) => tx.companyId == companyId).toList();
  }

  /// Set default payment card
  static Future<void> setDefaultCard(String cardId) async {
    try {
      final card = await StorageService.getPaymentCardById(cardId);
      if (card == null) return;

      // Remove default from other cards in same company
      final companyCards = await getCompanyPaymentCards(card.companyId);
      for (final companyCard in companyCards) {
        if (companyCard.isDefault && companyCard.id != cardId) {
          final updatedCard = companyCard.copyWith(isDefault: false);
          await StorageService.updatePaymentCard(updatedCard);
        }
      }

      // Set this card as default
      final updatedCard = card.copyWith(isDefault: true);
      await StorageService.updatePaymentCard(updatedCard);
    } catch (e) {
      print('Error setting default card: $e');
    }
  }

  /// Delete payment card
  static Future<void> deletePaymentCard(String cardId) async {
    try {
      await StorageService.deletePaymentCard(cardId);
    } catch (e) {
      print('Error deleting payment card: $e');
    }
  }

  // Helper methods

  static CardType _determineCardType(String cardNumber) {
    final cleanNumber = cardNumber.replaceAll(RegExp(r'\D'), '');
    
    if (cleanNumber.startsWith('4')) return CardType.visa;
    if (cleanNumber.startsWith('5') || cleanNumber.startsWith('2')) return CardType.mastercard;
    if (cleanNumber.startsWith('3')) return CardType.americanExpress;
    if (cleanNumber.startsWith('6')) return CardType.discover;
    
    return CardType.unknown;
  }

  static String _getCardBrand(CardType cardType) {
    switch (cardType) {
      case CardType.visa:
        return 'Visa';
      case CardType.mastercard:
        return 'Mastercard';
      case CardType.americanExpress:
        return 'American Express';
      case CardType.discover:
        return 'Discover';
      case CardType.dinersClub:
        return 'Diners Club';
      case CardType.jcb:
        return 'JCB';
      case CardType.unionPay:
        return 'UnionPay';
      default:
        return 'Unknown';
    }
  }

  static String _generateFingerprint(String cardNumber) {
    // Simple fingerprint generation (in real implementation, use proper hashing)
    return 'fp_${cardNumber.hashCode}';
  }
}
