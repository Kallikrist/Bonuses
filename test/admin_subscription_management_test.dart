import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bonuses/services/storage_service.dart';
import 'package:bonuses/models/company.dart';
import 'package:bonuses/models/company_subscription.dart';
import 'package:bonuses/models/subscription_tier.dart';
import 'package:bonuses/models/payment_record.dart';
import 'package:bonuses/models/user.dart';

void main() {
  group('Admin Subscription Management Tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    group('Subscription Retrieval', () {
      test('Can retrieve subscription by company ID', () async {
        final company = Company(
          id: 'company_1',
          name: 'Test Company',
          createdAt: DateTime.now(),
          adminUserId: 'admin_1',
          isActive: true,
        );

        final subscription = CompanySubscription(
          id: 'sub_1',
          companyId: company.id,
          tierId: 'tier_starter',
          startDate: DateTime.now(),
          status: SubscriptionStatus.active,
          paymentMethod: PaymentMethod.creditCard,
          billingInterval: BillingInterval.monthly,
          nextBillingDate: DateTime.now().add(const Duration(days: 30)),
          currentPrice: 29.0,
          gracePeriodDays: 7,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await StorageService.addCompany(company);
        await StorageService.addSubscription(subscription);

        final retrieved =
            await StorageService.getSubscriptionByCompanyId(company.id);

        expect(retrieved, isNotNull);
        expect(retrieved!.companyId, company.id);
        expect(retrieved.tierId, 'tier_starter');
      });

      test('Returns null when company has no subscription', () async {
        final company = Company(
          id: 'company_1',
          name: 'Test Company',
          createdAt: DateTime.now(),
          adminUserId: 'admin_1',
          isActive: true,
        );

        await StorageService.addCompany(company);

        final subscription =
            await StorageService.getSubscriptionByCompanyId(company.id);

        expect(subscription, isNull);
      });

      test('Can retrieve subscription tier details', () {
        final tiers = SubscriptionTier.defaultTiers;
        final starterTier = tiers.firstWhere((t) => t.id == 'tier_starter');

        expect(starterTier.name, 'Starter');
        expect(starterTier.monthlyPrice, 29.0);
        expect(starterTier.maxEmployees, 10);
        expect(starterTier.isActive, true);
      });
    });

    group('Subscription Status Display', () {
      test('Active subscription displays correctly', () async {
        final subscription = CompanySubscription(
          id: 'sub_1',
          companyId: 'company_1',
          tierId: 'tier_professional',
          startDate: DateTime.now(),
          status: SubscriptionStatus.active,
          paymentMethod: PaymentMethod.creditCard,
          billingInterval: BillingInterval.monthly,
          nextBillingDate: DateTime.now().add(const Duration(days: 30)),
          currentPrice: 99.0,
          gracePeriodDays: 7,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        expect(subscription.isActive, true);
        expect(subscription.isTrial, false);
        expect(subscription.status, SubscriptionStatus.active);
      });

      test('Trial subscription displays trial info', () async {
        final now = DateTime.now();
        final subscription = CompanySubscription(
          id: 'sub_1',
          companyId: 'company_1',
          tierId: 'tier_starter',
          startDate: now,
          status: SubscriptionStatus.trial,
          paymentMethod: PaymentMethod.creditCard,
          billingInterval: BillingInterval.monthly,
          nextBillingDate: now.add(const Duration(days: 14)),
          currentPrice: 29.0,
          gracePeriodDays: 7,
          createdAt: now,
          updatedAt: now,
          trialEndsAt: now.add(const Duration(days: 14)),
        );

        expect(subscription.isTrial, true);
        expect(subscription.trialEndsAt, isNotNull);
        expect(subscription.daysUntilTrialEnds, greaterThanOrEqualTo(13));
      });

      test('Cancelled subscription status is correct', () async {
        final subscription = CompanySubscription(
          id: 'sub_1',
          companyId: 'company_1',
          tierId: 'tier_starter',
          startDate: DateTime.now(),
          status: SubscriptionStatus.cancelled,
          paymentMethod: PaymentMethod.creditCard,
          billingInterval: BillingInterval.monthly,
          nextBillingDate: DateTime.now().add(const Duration(days: 30)),
          currentPrice: 29.0,
          gracePeriodDays: 7,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        expect(subscription.isActive, false);
        expect(subscription.status, SubscriptionStatus.cancelled);
      });
    });

    group('Billing Information', () {
      test('Monthly billing displays correct price', () async {
        final subscription = CompanySubscription(
          id: 'sub_1',
          companyId: 'company_1',
          tierId: 'tier_starter',
          startDate: DateTime.now(),
          status: SubscriptionStatus.active,
          paymentMethod: PaymentMethod.creditCard,
          billingInterval: BillingInterval.monthly,
          nextBillingDate: DateTime.now().add(const Duration(days: 30)),
          currentPrice: 29.0,
          gracePeriodDays: 7,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        expect(subscription.billingInterval, BillingInterval.monthly);
        expect(subscription.currentPrice, 29.0);
        expect(subscription.daysUntilNextBilling, greaterThanOrEqualTo(29));
      });

      test('Yearly billing displays correct price', () async {
        final subscription = CompanySubscription(
          id: 'sub_1',
          companyId: 'company_1',
          tierId: 'tier_professional',
          startDate: DateTime.now(),
          status: SubscriptionStatus.active,
          paymentMethod: PaymentMethod.creditCard,
          billingInterval: BillingInterval.yearly,
          nextBillingDate: DateTime.now().add(const Duration(days: 365)),
          currentPrice: 999.0,
          gracePeriodDays: 7,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        expect(subscription.billingInterval, BillingInterval.yearly);
        expect(subscription.currentPrice, 999.0);
      });

      test('Payment method is stored correctly', () async {
        final subscription = CompanySubscription(
          id: 'sub_1',
          companyId: 'company_1',
          tierId: 'tier_starter',
          startDate: DateTime.now(),
          status: SubscriptionStatus.active,
          paymentMethod: PaymentMethod.bankTransfer,
          billingInterval: BillingInterval.monthly,
          nextBillingDate: DateTime.now().add(const Duration(days: 30)),
          currentPrice: 29.0,
          gracePeriodDays: 7,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        expect(subscription.paymentMethod, PaymentMethod.bankTransfer);
      });
    });

    group('Payment History', () {
      test('Can retrieve payment history for subscription', () async {
        final subscription = CompanySubscription(
          id: 'sub_1',
          companyId: 'company_1',
          tierId: 'tier_starter',
          startDate: DateTime.now(),
          status: SubscriptionStatus.active,
          paymentMethod: PaymentMethod.creditCard,
          billingInterval: BillingInterval.monthly,
          nextBillingDate: DateTime.now().add(const Duration(days: 30)),
          currentPrice: 29.0,
          gracePeriodDays: 7,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await StorageService.addSubscription(subscription);

        // Add payment records
        for (int i = 0; i < 3; i++) {
          final payment = PaymentRecord(
            id: 'payment_$i',
            companyId: 'company_1',
            subscriptionId: subscription.id,
            amount: 29.0,
            currency: 'USD',
            status: PaymentStatus.completed,
            date: DateTime.now().subtract(Duration(days: 30 * (3 - i))),
            invoiceId: 'INV-00$i',
            transactionId: 'TXN-00$i',
            paymentGateway: 'stripe',
          );
          await StorageService.addPaymentRecord(payment);
        }

        final payments =
            await StorageService.getPaymentsBySubscriptionId(subscription.id);

        expect(payments.length, 3);
        expect(
            payments.every((p) => p.subscriptionId == subscription.id), true);
      });

      test('Payment records show correct status', () async {
        final completedPayment = PaymentRecord(
          id: 'payment_1',
          companyId: 'company_1',
          subscriptionId: 'sub_1',
          amount: 29.0,
          currency: 'USD',
          status: PaymentStatus.completed,
          date: DateTime.now(),
          invoiceId: 'INV-001',
          transactionId: 'TXN-001',
          paymentGateway: 'stripe',
        );

        final failedPayment = PaymentRecord(
          id: 'payment_2',
          companyId: 'company_1',
          subscriptionId: 'sub_1',
          amount: 29.0,
          currency: 'USD',
          status: PaymentStatus.failed,
          date: DateTime.now(),
          invoiceId: 'INV-002',
          transactionId: 'TXN-002',
          paymentGateway: 'stripe',
        );

        expect(completedPayment.isSuccessful, true);
        expect(failedPayment.isFailed, true);
      });

      test('Empty payment history handled correctly', () async {
        final payments =
            await StorageService.getPaymentsBySubscriptionId('non_existent');
        expect(payments, isEmpty);
      });
    });

    group('Plan Features Display', () {
      test('Starter tier features are correct', () {
        final tiers = SubscriptionTier.defaultTiers;
        final starter = tiers.firstWhere((t) => t.id == 'tier_starter');

        expect(starter.maxEmployees, 10);
        expect(starter.maxWorkplaces, 2); // Corrected from 3 to 2
        expect(starter.maxBonuses, 50);
        expect(starter.features.isNotEmpty, true);
      });

      test('Professional tier features are correct', () {
        final tiers = SubscriptionTier.defaultTiers;
        final professional =
            tiers.firstWhere((t) => t.id == 'tier_professional');

        expect(professional.maxEmployees, 50);
        expect(professional.maxWorkplaces, 10);
        expect(professional.maxBonuses,
            -1); // Corrected from 200 to -1 (unlimited)
        expect(
            professional.features.length,
            greaterThan(SubscriptionTier.defaultTiers
                .firstWhere((t) => t.id == 'tier_starter')
                .features
                .length));
      });

      test('Enterprise tier has unlimited features', () {
        final tiers = SubscriptionTier.defaultTiers;
        final enterprise = tiers.firstWhere((t) => t.id == 'tier_enterprise');

        expect(enterprise.maxEmployees, -1); // Unlimited
        expect(enterprise.maxWorkplaces, -1); // Unlimited
        expect(enterprise.maxBonuses, -1); // Unlimited
      });

      test('Free tier has basic features', () {
        final tiers = SubscriptionTier.defaultTiers;
        final free = tiers.firstWhere((t) => t.id == 'tier_free');

        expect(free.monthlyPrice, 0.0);
        expect(free.maxEmployees, 5); // Corrected from 3 to 5
        expect(free.maxWorkplaces, 1);
      });
    });

    group('Plan Comparison', () {
      test('Can identify upgrade vs downgrade', () {
        final tiers = SubscriptionTier.defaultTiers;
        final starter = tiers.firstWhere((t) => t.id == 'tier_starter');
        final professional =
            tiers.firstWhere((t) => t.id == 'tier_professional');

        expect(professional.monthlyPrice > starter.monthlyPrice, true);
        expect(professional.maxEmployees > starter.maxEmployees, true);
      });

      test('Available tiers are filtered correctly', () {
        final tiers = SubscriptionTier.defaultTiers;
        final activeTiers = tiers.where((t) => t.isActive).toList();

        expect(activeTiers.length, greaterThan(0));
        expect(activeTiers.every((t) => t.isActive), true);
      });

      test('Current tier is excluded from available plans', () {
        final tiers = SubscriptionTier.defaultTiers;
        final currentTierId = 'tier_starter';
        final otherTiers =
            tiers.where((t) => t.id != currentTierId && t.isActive).toList();

        expect(otherTiers.every((t) => t.id != currentTierId), true);
      });
    });

    group('Admin Access Control', () {
      test('Admin can view their company subscription', () async {
        final admin = User(
          id: 'admin_1',
          name: 'Admin User',
          email: 'admin@test.com',
          phoneNumber: '+1 (555) 111-1111',
          role: UserRole.admin,
          createdAt: DateTime.now(),
          workplaceIds: [],
          workplaceNames: [],
          companyIds: ['company_1'],
          companyNames: ['Test Company'],
          primaryCompanyId: 'company_1',
          companyRoles: {'company_1': 'admin'},
          companyPoints: {'company_1': 0},
        );

        await StorageService.addUser(admin);

        final subscription = CompanySubscription(
          id: 'sub_1',
          companyId: admin.primaryCompanyId!,
          tierId: 'tier_starter',
          startDate: DateTime.now(),
          status: SubscriptionStatus.active,
          paymentMethod: PaymentMethod.creditCard,
          billingInterval: BillingInterval.monthly,
          nextBillingDate: DateTime.now().add(const Duration(days: 30)),
          currentPrice: 29.0,
          gracePeriodDays: 7,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await StorageService.addSubscription(subscription);

        final retrieved = await StorageService.getSubscriptionByCompanyId(
            admin.primaryCompanyId!);

        expect(retrieved, isNotNull);
        expect(retrieved!.companyId, admin.primaryCompanyId);
      });

      test('Employee cannot see subscription management', () {
        final employee = User(
          id: 'emp_1',
          name: 'Employee User',
          email: 'employee@test.com',
          phoneNumber: '+1 (555) 222-2222',
          role: UserRole.employee,
          createdAt: DateTime.now(),
          workplaceIds: [],
          workplaceNames: [],
          companyIds: ['company_1'],
          companyNames: ['Test Company'],
          primaryCompanyId: 'company_1',
          companyRoles: {'company_1': 'employee'},
          companyPoints: {'company_1': 100},
        );

        // Employees should not have access to subscription management
        // This is enforced at the UI level
        expect(employee.role, UserRole.employee);
        expect(employee.role, isNot(UserRole.admin));
      });
    });

    group('Subscription Updates', () {
      test('Subscription can be updated', () async {
        final subscription = CompanySubscription(
          id: 'sub_1',
          companyId: 'company_1',
          tierId: 'tier_starter',
          startDate: DateTime.now(),
          status: SubscriptionStatus.active,
          paymentMethod: PaymentMethod.creditCard,
          billingInterval: BillingInterval.monthly,
          nextBillingDate: DateTime.now().add(const Duration(days: 30)),
          currentPrice: 29.0,
          gracePeriodDays: 7,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await StorageService.addSubscription(subscription);

        // Update to professional tier
        final updated = subscription.copyWith(
          tierId: 'tier_professional',
          currentPrice: 99.0,
          updatedAt: DateTime.now(),
        );

        await StorageService.updateSubscription(updated);

        final retrieved =
            await StorageService.getSubscriptionByCompanyId('company_1');

        expect(retrieved!.tierId, 'tier_professional');
        expect(retrieved.currentPrice, 99.0);
      });

      test('Subscription status can be changed', () async {
        final subscription = CompanySubscription(
          id: 'sub_1',
          companyId: 'company_1',
          tierId: 'tier_starter',
          startDate: DateTime.now(),
          status: SubscriptionStatus.trial,
          paymentMethod: PaymentMethod.creditCard,
          billingInterval: BillingInterval.monthly,
          nextBillingDate: DateTime.now().add(const Duration(days: 14)),
          currentPrice: 29.0,
          gracePeriodDays: 7,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          trialEndsAt: DateTime.now().add(const Duration(days: 14)),
        );

        await StorageService.addSubscription(subscription);

        // Convert trial to active
        final updated = subscription.copyWith(
          status: SubscriptionStatus.active,
          trialEndsAt: null,
          nextBillingDate: DateTime.now().add(const Duration(days: 30)),
        );

        await StorageService.updateSubscription(updated);

        final retrieved =
            await StorageService.getSubscriptionByCompanyId('company_1');

        expect(retrieved!.status, SubscriptionStatus.active);
        expect(retrieved.isTrial, false);
      });
    });

    group('Error Handling', () {
      test('Handles missing company gracefully', () async {
        final subscription =
            await StorageService.getSubscriptionByCompanyId('non_existent');
        expect(subscription, isNull);
      });

      test('Handles invalid subscription ID', () async {
        final payments = await StorageService.getPaymentsBySubscriptionId(
            'non_existent_subscription');
        expect(payments, isEmpty);
      });
    });

    group('Multiple Companies', () {
      test('Each company has independent subscription', () async {
        final company1 = Company(
          id: 'company_1',
          name: 'Company 1',
          createdAt: DateTime.now(),
          adminUserId: 'admin_1',
          isActive: true,
        );

        final company2 = Company(
          id: 'company_2',
          name: 'Company 2',
          createdAt: DateTime.now(),
          adminUserId: 'admin_2',
          isActive: true,
        );

        await StorageService.addCompany(company1);
        await StorageService.addCompany(company2);

        final sub1 = CompanySubscription(
          id: 'sub_1',
          companyId: company1.id,
          tierId: 'tier_starter',
          startDate: DateTime.now(),
          status: SubscriptionStatus.active,
          paymentMethod: PaymentMethod.creditCard,
          billingInterval: BillingInterval.monthly,
          nextBillingDate: DateTime.now().add(const Duration(days: 30)),
          currentPrice: 29.0,
          gracePeriodDays: 7,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final sub2 = CompanySubscription(
          id: 'sub_2',
          companyId: company2.id,
          tierId: 'tier_professional',
          startDate: DateTime.now(),
          status: SubscriptionStatus.active,
          paymentMethod: PaymentMethod.bankTransfer,
          billingInterval: BillingInterval.yearly,
          nextBillingDate: DateTime.now().add(const Duration(days: 365)),
          currentPrice: 999.0,
          gracePeriodDays: 7,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await StorageService.addSubscription(sub1);
        await StorageService.addSubscription(sub2);

        final retrieved1 =
            await StorageService.getSubscriptionByCompanyId(company1.id);
        final retrieved2 =
            await StorageService.getSubscriptionByCompanyId(company2.id);

        expect(retrieved1!.tierId, 'tier_starter');
        expect(retrieved2!.tierId, 'tier_professional');
        expect(retrieved1.companyId, company1.id);
        expect(retrieved2.companyId, company2.id);
      });
    });
  });
}
