import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bonuses/services/storage_service.dart';
import 'package:bonuses/models/payment_record.dart';
import 'package:bonuses/models/company.dart';
import 'package:bonuses/models/company_subscription.dart';

void main() {
  group('Payment Tracking Tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});

      // Create test company and subscription
      final company = Company(
        id: 'test_company',
        name: 'Test Company',
        contactEmail: 'admin@test.com',
        adminUserId: 'admin1',
        createdAt: DateTime.now(),
        isActive: true,
      );
      await StorageService.addCompany(company);

      final subscription = CompanySubscription(
        id: 'test_subscription',
        companyId: 'test_company',
        tierId: 'tier_starter',
        startDate: DateTime.now(),
        status: SubscriptionStatus.active,
        paymentMethod: PaymentMethod.creditCard,
        billingInterval: BillingInterval.monthly,
        nextBillingDate: DateTime.now().add(const Duration(days: 30)),
        currentPrice: 29,
        gracePeriodDays: 7,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await StorageService.addSubscription(subscription);
    });

    group('Payment CRUD Operations', () {
      test('Can create a payment record', () async {
        final payment = PaymentRecord(
          id: 'payment_1',
          companyId: 'test_company',
          subscriptionId: 'test_subscription',
          amount: 29,
          currency: 'USD',
          status: PaymentStatus.completed,
          date: DateTime.now(),
          invoiceId: 'INV-001',
          transactionId: 'TXN-12345',
          paymentGateway: 'stripe',
        );

        await StorageService.addPaymentRecord(payment);

        final payments = await StorageService.getPaymentRecords();
        expect(payments.length, 1);
        expect(payments.first.id, 'payment_1');
        expect(payments.first.amount, 29);
        expect(payments.first.status, PaymentStatus.completed);
      });

      test('Can update a payment record', () async {
        final payment = PaymentRecord(
          id: 'payment_1',
          companyId: 'test_company',
          subscriptionId: 'test_subscription',
          amount: 29,
          currency: 'USD',
          status: PaymentStatus.pending,
          date: DateTime.now(),
        );

        await StorageService.addPaymentRecord(payment);

        final updatedPayment = payment.copyWith(
          status: PaymentStatus.completed,
          transactionId: 'TXN-12345',
        );

        await StorageService.updatePaymentRecord(updatedPayment);

        final payments = await StorageService.getPaymentRecords();
        expect(payments.length, 1);
        expect(payments.first.status, PaymentStatus.completed);
        expect(payments.first.transactionId, 'TXN-12345');
      });

      test('Can delete a payment record', () async {
        final payment = PaymentRecord(
          id: 'payment_1',
          companyId: 'test_company',
          subscriptionId: 'test_subscription',
          amount: 29,
          status: PaymentStatus.completed,
          date: DateTime.now(),
        );

        await StorageService.addPaymentRecord(payment);
        expect((await StorageService.getPaymentRecords()).length, 1);

        await StorageService.deletePaymentRecord('payment_1');
        expect((await StorageService.getPaymentRecords()).length, 0);
      });

      test('Can retrieve payments by company ID', () async {
        final payment1 = PaymentRecord(
          id: 'payment_1',
          companyId: 'test_company',
          subscriptionId: 'test_subscription',
          amount: 29,
          status: PaymentStatus.completed,
          date: DateTime.now(),
        );
        final payment2 = PaymentRecord(
          id: 'payment_2',
          companyId: 'other_company',
          subscriptionId: 'other_subscription',
          amount: 99,
          status: PaymentStatus.completed,
          date: DateTime.now(),
        );

        await StorageService.addPaymentRecord(payment1);
        await StorageService.addPaymentRecord(payment2);

        final companyPayments =
            await StorageService.getPaymentsByCompanyId('test_company');
        expect(companyPayments.length, 1);
        expect(companyPayments.first.companyId, 'test_company');
      });

      test('Can retrieve payments by subscription ID', () async {
        final payment1 = PaymentRecord(
          id: 'payment_1',
          companyId: 'test_company',
          subscriptionId: 'test_subscription',
          amount: 29,
          status: PaymentStatus.completed,
          date: DateTime.now(),
        );
        final payment2 = PaymentRecord(
          id: 'payment_2',
          companyId: 'test_company',
          subscriptionId: 'other_subscription',
          amount: 99,
          status: PaymentStatus.completed,
          date: DateTime.now(),
        );

        await StorageService.addPaymentRecord(payment1);
        await StorageService.addPaymentRecord(payment2);

        final subscriptionPayments =
            await StorageService.getPaymentsBySubscriptionId(
                'test_subscription');
        expect(subscriptionPayments.length, 1);
        expect(subscriptionPayments.first.subscriptionId, 'test_subscription');
      });
    });

    group('Payment Status Tests', () {
      test('Completed payment is marked as successful', () {
        final payment = PaymentRecord(
          id: 'payment_1',
          companyId: 'test_company',
          subscriptionId: 'test_subscription',
          amount: 29,
          status: PaymentStatus.completed,
          date: DateTime.now(),
        );

        expect(payment.isSuccessful, true);
        expect(payment.isFailed, false);
        expect(payment.isRefunded, false);
      });

      test('Failed payment is marked correctly', () {
        final payment = PaymentRecord(
          id: 'payment_1',
          companyId: 'test_company',
          subscriptionId: 'test_subscription',
          amount: 29,
          status: PaymentStatus.failed,
          date: DateTime.now(),
          failureReason: 'Insufficient funds',
        );

        expect(payment.isSuccessful, false);
        expect(payment.isFailed, true);
        expect(payment.failureReason, 'Insufficient funds');
      });

      test('Cancelled payment is marked as failed', () {
        final payment = PaymentRecord(
          id: 'payment_1',
          companyId: 'test_company',
          subscriptionId: 'test_subscription',
          amount: 29,
          status: PaymentStatus.cancelled,
          date: DateTime.now(),
        );

        expect(payment.isFailed, true);
        expect(payment.isSuccessful, false);
      });

      test('Refunded payment is marked correctly', () {
        final payment = PaymentRecord(
          id: 'payment_1',
          companyId: 'test_company',
          subscriptionId: 'test_subscription',
          amount: 29,
          status: PaymentStatus.refunded,
          date: DateTime.now(),
          refundedAt: DateTime.now(),
          refundedAmount: 29,
        );

        expect(payment.isRefunded, true);
        expect(payment.effectiveAmount, 0);
      });

      test('Partially refunded payment calculates effective amount', () {
        final payment = PaymentRecord(
          id: 'payment_1',
          companyId: 'test_company',
          subscriptionId: 'test_subscription',
          amount: 100,
          status: PaymentStatus.partiallyRefunded,
          date: DateTime.now(),
          refundedAt: DateTime.now(),
          refundedAmount: 30,
        );

        expect(payment.isRefunded, true);
        expect(payment.effectiveAmount, 70); // 100 - 30
      });
    });

    group('Payment Serialization', () {
      test('Payment record can be serialized and deserialized', () {
        final payment = PaymentRecord(
          id: 'payment_1',
          companyId: 'test_company',
          subscriptionId: 'test_subscription',
          amount: 99,
          currency: 'USD',
          status: PaymentStatus.completed,
          date: DateTime.now(),
          invoiceId: 'INV-001',
          transactionId: 'TXN-12345',
          paymentGateway: 'stripe',
        );

        final json = payment.toJson();
        final deserialized = PaymentRecord.fromJson(json);

        expect(deserialized.id, payment.id);
        expect(deserialized.companyId, payment.companyId);
        expect(deserialized.amount, payment.amount);
        expect(deserialized.status, payment.status);
        expect(deserialized.invoiceId, payment.invoiceId);
        expect(deserialized.transactionId, payment.transactionId);
      });

      test('Payment with refund data serializes correctly', () {
        final payment = PaymentRecord(
          id: 'payment_1',
          companyId: 'test_company',
          subscriptionId: 'test_subscription',
          amount: 100,
          status: PaymentStatus.refunded,
          date: DateTime.now(),
          refundedAt: DateTime.now(),
          refundedAmount: 100,
        );

        final json = payment.toJson();
        final deserialized = PaymentRecord.fromJson(json);

        expect(deserialized.refundedAmount, 100);
        expect(deserialized.refundedAt, isNotNull);
        expect(deserialized.isRefunded, true);
      });
    });

    group('Payment Gateway Integration', () {
      test('Supports different payment gateways', () {
        final stripePayment = PaymentRecord(
          id: 'payment_1',
          companyId: 'test_company',
          subscriptionId: 'test_subscription',
          amount: 29,
          status: PaymentStatus.completed,
          date: DateTime.now(),
          paymentGateway: 'stripe',
        );

        final paypalPayment = PaymentRecord(
          id: 'payment_2',
          companyId: 'test_company',
          subscriptionId: 'test_subscription',
          amount: 29,
          status: PaymentStatus.completed,
          date: DateTime.now(),
          paymentGateway: 'paypal',
        );

        expect(stripePayment.paymentGateway, 'stripe');
        expect(paypalPayment.paymentGateway, 'paypal');
      });

      test('Payment can have transaction ID from gateway', () {
        final payment = PaymentRecord(
          id: 'payment_1',
          companyId: 'test_company',
          subscriptionId: 'test_subscription',
          amount: 29,
          status: PaymentStatus.completed,
          date: DateTime.now(),
          transactionId: 'ch_1234567890',
          paymentGateway: 'stripe',
        );

        expect(payment.transactionId, 'ch_1234567890');
      });
    });

    group('Currency Support', () {
      test('Default currency is USD', () {
        final payment = PaymentRecord(
          id: 'payment_1',
          companyId: 'test_company',
          subscriptionId: 'test_subscription',
          amount: 29,
          status: PaymentStatus.completed,
          date: DateTime.now(),
        );

        expect(payment.currency, 'USD');
      });

      test('Can specify different currencies', () {
        final payment = PaymentRecord(
          id: 'payment_1',
          companyId: 'test_company',
          subscriptionId: 'test_subscription',
          amount: 25,
          currency: 'EUR',
          status: PaymentStatus.completed,
          date: DateTime.now(),
        );

        expect(payment.currency, 'EUR');
      });
    });

    group('Payment Metadata', () {
      test('Can store metadata with payment', () {
        final payment = PaymentRecord(
          id: 'payment_1',
          companyId: 'test_company',
          subscriptionId: 'test_subscription',
          amount: 29,
          status: PaymentStatus.completed,
          date: DateTime.now(),
          metadata: {
            'coupon': 'SAVE10',
            'discount': 10.0,
            'originalAmount': 39.0,
          },
        );

        expect(payment.metadata, isNotNull);
        expect(payment.metadata!['coupon'], 'SAVE10');
        expect(payment.metadata!['discount'], 10.0);
      });
    });

    group('Payment Workflow Tests', () {
      test('Payment lifecycle: pending -> processing -> completed', () async {
        var payment = PaymentRecord(
          id: 'payment_1',
          companyId: 'test_company',
          subscriptionId: 'test_subscription',
          amount: 29,
          status: PaymentStatus.pending,
          date: DateTime.now(),
        );

        await StorageService.addPaymentRecord(payment);
        expect(payment.status, PaymentStatus.pending);

        payment = payment.copyWith(status: PaymentStatus.processing);
        await StorageService.updatePaymentRecord(payment);
        expect(payment.status, PaymentStatus.processing);

        payment = payment.copyWith(
          status: PaymentStatus.completed,
          transactionId: 'TXN-12345',
        );
        await StorageService.updatePaymentRecord(payment);

        final retrieved = await StorageService.getPaymentRecords();
        expect(retrieved.first.status, PaymentStatus.completed);
        expect(retrieved.first.isSuccessful, true);
      });

      test('Failed payment can have failure reason', () async {
        final payment = PaymentRecord(
          id: 'payment_1',
          companyId: 'test_company',
          subscriptionId: 'test_subscription',
          amount: 29,
          status: PaymentStatus.failed,
          date: DateTime.now(),
          failureReason: 'Card declined',
        );

        await StorageService.addPaymentRecord(payment);

        final payments = await StorageService.getPaymentRecords();
        expect(payments.first.isFailed, true);
        expect(payments.first.failureReason, 'Card declined');
      });

      test('Completed payment can be refunded', () async {
        var payment = PaymentRecord(
          id: 'payment_1',
          companyId: 'test_company',
          subscriptionId: 'test_subscription',
          amount: 100,
          status: PaymentStatus.completed,
          date: DateTime.now(),
          transactionId: 'TXN-12345',
        );

        await StorageService.addPaymentRecord(payment);

        payment = payment.copyWith(
          status: PaymentStatus.refunded,
          refundedAt: DateTime.now(),
          refundedAmount: 100,
        );

        await StorageService.updatePaymentRecord(payment);

        final payments = await StorageService.getPaymentRecords();
        expect(payments.first.isRefunded, true);
        expect(payments.first.effectiveAmount, 0);
      });
    });

    group('Multiple Payments', () {
      test('Can manage multiple payments for same subscription', () async {
        final now = DateTime.now();
        final payments = List.generate(
          3,
          (index) => PaymentRecord(
            id: 'payment_$index',
            companyId: 'test_company',
            subscriptionId: 'test_subscription',
            amount: 29,
            status: PaymentStatus.completed,
            date: now.subtract(Duration(days: 30 * (3 - index))),
            invoiceId: 'INV-00$index',
          ),
        );

        for (final payment in payments) {
          await StorageService.addPaymentRecord(payment);
        }

        final allPayments = await StorageService.getPaymentRecords();
        expect(allPayments.length, 3);

        final subscriptionPayments =
            await StorageService.getPaymentsBySubscriptionId(
                'test_subscription');
        expect(subscriptionPayments.length, 3);
      });

      test('Can filter payments by company', () async {
        // Add second company and subscription
        final company2 = Company(
          id: 'company_2',
          name: 'Company 2',
          contactEmail: 'admin2@test.com',
          adminUserId: 'admin2',
          createdAt: DateTime.now(),
          isActive: true,
        );
        await StorageService.addCompany(company2);

        final subscription2 = CompanySubscription(
          id: 'subscription_2',
          companyId: 'company_2',
          tierId: 'tier_professional',
          startDate: DateTime.now(),
          status: SubscriptionStatus.active,
          paymentMethod: PaymentMethod.creditCard,
          billingInterval: BillingInterval.monthly,
          nextBillingDate: DateTime.now().add(const Duration(days: 30)),
          currentPrice: 99,
          gracePeriodDays: 7,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await StorageService.addSubscription(subscription2);

        final payment1 = PaymentRecord(
          id: 'payment_1',
          companyId: 'test_company',
          subscriptionId: 'test_subscription',
          amount: 29,
          status: PaymentStatus.completed,
          date: DateTime.now(),
        );
        final payment2 = PaymentRecord(
          id: 'payment_2',
          companyId: 'company_2',
          subscriptionId: 'subscription_2',
          amount: 99,
          status: PaymentStatus.completed,
          date: DateTime.now(),
        );

        await StorageService.addPaymentRecord(payment1);
        await StorageService.addPaymentRecord(payment2);

        final company1Payments =
            await StorageService.getPaymentsByCompanyId('test_company');
        final company2Payments =
            await StorageService.getPaymentsByCompanyId('company_2');

        expect(company1Payments.length, 1);
        expect(company2Payments.length, 1);
        expect(company1Payments.first.amount, 29);
        expect(company2Payments.first.amount, 99);
      });
    });

    group('Payment Invoice and Receipt', () {
      test('Payment can have invoice ID', () {
        final payment = PaymentRecord(
          id: 'payment_1',
          companyId: 'test_company',
          subscriptionId: 'test_subscription',
          amount: 29,
          status: PaymentStatus.completed,
          date: DateTime.now(),
          invoiceId: 'INV-2024-001',
        );

        expect(payment.invoiceId, 'INV-2024-001');
      });

      test('Payment can have receipt URL', () {
        final payment = PaymentRecord(
          id: 'payment_1',
          companyId: 'test_company',
          subscriptionId: 'test_subscription',
          amount: 29,
          status: PaymentStatus.completed,
          date: DateTime.now(),
          receiptUrl: 'https://example.com/receipts/12345',
        );

        expect(payment.receiptUrl, 'https://example.com/receipts/12345');
      });
    });

    group('Payment History Analysis', () {
      test('Can calculate total revenue from payments', () async {
        final payments = [
          PaymentRecord(
            id: 'payment_1',
            companyId: 'test_company',
            subscriptionId: 'test_subscription',
            amount: 29,
            status: PaymentStatus.completed,
            date: DateTime.now(),
          ),
          PaymentRecord(
            id: 'payment_2',
            companyId: 'test_company',
            subscriptionId: 'test_subscription',
            amount: 29,
            status: PaymentStatus.completed,
            date: DateTime.now().subtract(const Duration(days: 30)),
          ),
          PaymentRecord(
            id: 'payment_3',
            companyId: 'test_company',
            subscriptionId: 'test_subscription',
            amount: 29,
            status: PaymentStatus.failed,
            date: DateTime.now().subtract(const Duration(days: 60)),
          ),
        ];

        for (final payment in payments) {
          await StorageService.addPaymentRecord(payment);
        }

        final allPayments = await StorageService.getPaymentRecords();
        final totalRevenue = allPayments
            .where((p) => p.isSuccessful)
            .fold<double>(0, (sum, p) => sum + p.amount);

        expect(totalRevenue, 58); // 29 + 29 (failed payment doesn't count)
      });

      test('Can count successful vs failed payments', () async {
        final payments = [
          PaymentRecord(
            id: 'payment_1',
            companyId: 'test_company',
            subscriptionId: 'test_subscription',
            amount: 29,
            status: PaymentStatus.completed,
            date: DateTime.now(),
          ),
          PaymentRecord(
            id: 'payment_2',
            companyId: 'test_company',
            subscriptionId: 'test_subscription',
            amount: 29,
            status: PaymentStatus.completed,
            date: DateTime.now(),
          ),
          PaymentRecord(
            id: 'payment_3',
            companyId: 'test_company',
            subscriptionId: 'test_subscription',
            amount: 29,
            status: PaymentStatus.failed,
            date: DateTime.now(),
          ),
        ];

        for (final payment in payments) {
          await StorageService.addPaymentRecord(payment);
        }

        final allPayments = await StorageService.getPaymentRecords();
        final successfulCount = allPayments.where((p) => p.isSuccessful).length;
        final failedCount = allPayments.where((p) => p.isFailed).length;

        expect(successfulCount, 2);
        expect(failedCount, 1);
      });
    });

    group('Payment Amounts', () {
      test('Effective amount without refund equals amount', () {
        final payment = PaymentRecord(
          id: 'payment_1',
          companyId: 'test_company',
          subscriptionId: 'test_subscription',
          amount: 29,
          status: PaymentStatus.completed,
          date: DateTime.now(),
        );

        expect(payment.effectiveAmount, payment.amount);
      });

      test('Effective amount with full refund is zero', () {
        final payment = PaymentRecord(
          id: 'payment_1',
          companyId: 'test_company',
          subscriptionId: 'test_subscription',
          amount: 100,
          status: PaymentStatus.refunded,
          date: DateTime.now(),
          refundedAmount: 100,
        );

        expect(payment.effectiveAmount, 0);
      });

      test('Effective amount with partial refund is correct', () {
        final payment = PaymentRecord(
          id: 'payment_1',
          companyId: 'test_company',
          subscriptionId: 'test_subscription',
          amount: 150,
          status: PaymentStatus.partiallyRefunded,
          date: DateTime.now(),
          refundedAmount: 50,
        );

        expect(payment.effectiveAmount, 100);
      });
    });
  });
}
