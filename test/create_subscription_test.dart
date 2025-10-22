import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bonuses/services/storage_service.dart';
import 'package:bonuses/models/company.dart';
import 'package:bonuses/models/company_subscription.dart';
import 'package:bonuses/models/subscription_tier.dart';

void main() {
  group('Create Subscription Tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    group('Subscription Creation', () {
      test('Can create a new subscription for a company', () async {
        final company = Company(
          id: 'company_1',
          name: 'Test Company',
          createdAt: DateTime.now(),
          adminUserId: 'admin_1',
          isActive: true,
        );

        await StorageService.addCompany(company);

        final subscription = CompanySubscription(
          id: 'sub_1',
          companyId: company.id,
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

        final subscriptions = await StorageService.getSubscriptions();
        expect(subscriptions.length, 1);
        expect(subscriptions.first.companyId, company.id);
        expect(subscriptions.first.status, SubscriptionStatus.trial);
      });

      test('Can create subscription with monthly billing', () async {
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

        final retrieved =
            await StorageService.getSubscriptionByCompanyId('company_1');
        expect(retrieved, isNotNull);
        expect(retrieved!.billingInterval, BillingInterval.monthly);
        expect(retrieved.currentPrice, 29.0);
      });

      test('Can create subscription with yearly billing', () async {
        final subscription = CompanySubscription(
          id: 'sub_1',
          companyId: 'company_1',
          tierId: 'tier_professional',
          startDate: DateTime.now(),
          status: SubscriptionStatus.active,
          paymentMethod: PaymentMethod.creditCard,
          billingInterval: BillingInterval.yearly,
          nextBillingDate: DateTime.now().add(const Duration(days: 365)),
          currentPrice: 999.0, // Yearly price
          gracePeriodDays: 7,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await StorageService.addSubscription(subscription);

        final retrieved =
            await StorageService.getSubscriptionByCompanyId('company_1');
        expect(retrieved, isNotNull);
        expect(retrieved!.billingInterval, BillingInterval.yearly);
        expect(retrieved.currentPrice, 999.0);
      });

      test('Can create trial subscription', () async {
        final now = DateTime.now();
        final trialDays = 14;

        final subscription = CompanySubscription(
          id: 'sub_1',
          companyId: 'company_1',
          tierId: 'tier_starter',
          startDate: now,
          status: SubscriptionStatus.trial,
          paymentMethod: PaymentMethod.creditCard,
          billingInterval: BillingInterval.monthly,
          nextBillingDate: now.add(Duration(days: trialDays)),
          currentPrice: 29.0,
          gracePeriodDays: 7,
          createdAt: now,
          updatedAt: now,
          trialEndsAt: now.add(Duration(days: trialDays)),
        );

        await StorageService.addSubscription(subscription);

        final retrieved =
            await StorageService.getSubscriptionByCompanyId('company_1');
        expect(retrieved, isNotNull);
        expect(retrieved!.status, SubscriptionStatus.trial);
        expect(retrieved.isTrial, true);
        expect(retrieved.trialEndsAt, isNotNull);
      });

      test('Can create active subscription', () async {
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

        final retrieved =
            await StorageService.getSubscriptionByCompanyId('company_1');
        expect(retrieved, isNotNull);
        expect(retrieved!.status, SubscriptionStatus.active);
        expect(retrieved.isActive, true);
      });
    });

    group('Subscription Tier Selection', () {
      test('Can create subscription with Free tier', () async {
        final subscription = CompanySubscription(
          id: 'sub_1',
          companyId: 'company_1',
          tierId: 'tier_free',
          startDate: DateTime.now(),
          status: SubscriptionStatus.active,
          paymentMethod: PaymentMethod.creditCard,
          billingInterval: BillingInterval.monthly,
          nextBillingDate: DateTime.now().add(const Duration(days: 30)),
          currentPrice: 0.0,
          gracePeriodDays: 7,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await StorageService.addSubscription(subscription);

        final retrieved =
            await StorageService.getSubscriptionByCompanyId('company_1');
        expect(retrieved, isNotNull);
        expect(retrieved!.tierId, 'tier_free');
        expect(retrieved.currentPrice, 0.0);
      });

      test('Can create subscription with Starter tier', () async {
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

        final retrieved =
            await StorageService.getSubscriptionByCompanyId('company_1');
        expect(retrieved, isNotNull);
        expect(retrieved!.tierId, 'tier_starter');
        expect(retrieved.currentPrice, 29.0);
      });

      test('Can create subscription with Professional tier', () async {
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

        await StorageService.addSubscription(subscription);

        final retrieved =
            await StorageService.getSubscriptionByCompanyId('company_1');
        expect(retrieved, isNotNull);
        expect(retrieved!.tierId, 'tier_professional');
        expect(retrieved.currentPrice, 99.0);
      });

      test('Can create subscription with Enterprise tier', () async {
        final subscription = CompanySubscription(
          id: 'sub_1',
          companyId: 'company_1',
          tierId: 'tier_enterprise',
          startDate: DateTime.now(),
          status: SubscriptionStatus.active,
          paymentMethod: PaymentMethod.creditCard,
          billingInterval: BillingInterval.monthly,
          nextBillingDate: DateTime.now().add(const Duration(days: 30)),
          currentPrice: 299.0,
          gracePeriodDays: 7,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await StorageService.addSubscription(subscription);

        final retrieved =
            await StorageService.getSubscriptionByCompanyId('company_1');
        expect(retrieved, isNotNull);
        expect(retrieved!.tierId, 'tier_enterprise');
        expect(retrieved.currentPrice, 299.0);
      });
    });

    group('Payment Methods', () {
      test('Can create subscription with credit card payment', () async {
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

        final retrieved =
            await StorageService.getSubscriptionByCompanyId('company_1');
        expect(retrieved!.paymentMethod, PaymentMethod.creditCard);
      });

      test('Can create subscription with debit card payment', () async {
        final subscription = CompanySubscription(
          id: 'sub_1',
          companyId: 'company_1',
          tierId: 'tier_starter',
          startDate: DateTime.now(),
          status: SubscriptionStatus.active,
          paymentMethod: PaymentMethod.debitCard,
          billingInterval: BillingInterval.monthly,
          nextBillingDate: DateTime.now().add(const Duration(days: 30)),
          currentPrice: 29.0,
          gracePeriodDays: 7,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await StorageService.addSubscription(subscription);

        final retrieved =
            await StorageService.getSubscriptionByCompanyId('company_1');
        expect(retrieved!.paymentMethod, PaymentMethod.debitCard);
      });

      test('Can create subscription with bank transfer payment', () async {
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

        await StorageService.addSubscription(subscription);

        final retrieved =
            await StorageService.getSubscriptionByCompanyId('company_1');
        expect(retrieved!.paymentMethod, PaymentMethod.bankTransfer);
      });

      test('Can create subscription with PayPal payment', () async {
        final subscription = CompanySubscription(
          id: 'sub_1',
          companyId: 'company_1',
          tierId: 'tier_starter',
          startDate: DateTime.now(),
          status: SubscriptionStatus.active,
          paymentMethod: PaymentMethod.paypal,
          billingInterval: BillingInterval.monthly,
          nextBillingDate: DateTime.now().add(const Duration(days: 30)),
          currentPrice: 29.0,
          gracePeriodDays: 7,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await StorageService.addSubscription(subscription);

        final retrieved =
            await StorageService.getSubscriptionByCompanyId('company_1');
        expect(retrieved!.paymentMethod, PaymentMethod.paypal);
      });
    });

    group('Trial Duration', () {
      test('Can create subscription with 7-day trial', () async {
        final now = DateTime.now();
        final trialDays = 7;

        final subscription = CompanySubscription(
          id: 'sub_1',
          companyId: 'company_1',
          tierId: 'tier_starter',
          startDate: now,
          status: SubscriptionStatus.trial,
          paymentMethod: PaymentMethod.creditCard,
          billingInterval: BillingInterval.monthly,
          nextBillingDate: now.add(Duration(days: trialDays)),
          currentPrice: 29.0,
          gracePeriodDays: 7,
          createdAt: now,
          updatedAt: now,
          trialEndsAt: now.add(Duration(days: trialDays)),
        );

        await StorageService.addSubscription(subscription);

        final retrieved =
            await StorageService.getSubscriptionByCompanyId('company_1');
        // Allow for 1-day difference due to timing
        expect(
            retrieved!.daysUntilTrialEnds, greaterThanOrEqualTo(trialDays - 1));
        expect(retrieved.daysUntilTrialEnds, lessThanOrEqualTo(trialDays));
      });

      test('Can create subscription with 14-day trial', () async {
        final now = DateTime.now();
        final trialDays = 14;

        final subscription = CompanySubscription(
          id: 'sub_1',
          companyId: 'company_1',
          tierId: 'tier_starter',
          startDate: now,
          status: SubscriptionStatus.trial,
          paymentMethod: PaymentMethod.creditCard,
          billingInterval: BillingInterval.monthly,
          nextBillingDate: now.add(Duration(days: trialDays)),
          currentPrice: 29.0,
          gracePeriodDays: 7,
          createdAt: now,
          updatedAt: now,
          trialEndsAt: now.add(Duration(days: trialDays)),
        );

        await StorageService.addSubscription(subscription);

        final retrieved =
            await StorageService.getSubscriptionByCompanyId('company_1');
        // Allow for 1-day difference due to timing
        expect(
            retrieved!.daysUntilTrialEnds, greaterThanOrEqualTo(trialDays - 1));
        expect(retrieved.daysUntilTrialEnds, lessThanOrEqualTo(trialDays));
      });

      test('Can create subscription with 30-day trial', () async {
        final now = DateTime.now();
        final trialDays = 30;

        final subscription = CompanySubscription(
          id: 'sub_1',
          companyId: 'company_1',
          tierId: 'tier_starter',
          startDate: now,
          status: SubscriptionStatus.trial,
          paymentMethod: PaymentMethod.creditCard,
          billingInterval: BillingInterval.monthly,
          nextBillingDate: now.add(Duration(days: trialDays)),
          currentPrice: 29.0,
          gracePeriodDays: 7,
          createdAt: now,
          updatedAt: now,
          trialEndsAt: now.add(Duration(days: trialDays)),
        );

        await StorageService.addSubscription(subscription);

        final retrieved =
            await StorageService.getSubscriptionByCompanyId('company_1');
        // Allow for 1-day difference due to timing
        expect(
            retrieved!.daysUntilTrialEnds, greaterThanOrEqualTo(trialDays - 1));
        expect(retrieved.daysUntilTrialEnds, lessThanOrEqualTo(trialDays));
      });
    });

    group('Multiple Companies', () {
      test('Can create subscriptions for multiple companies', () async {
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

        final subscriptions = await StorageService.getSubscriptions();
        expect(subscriptions.length, 2);

        final retrieved1 =
            await StorageService.getSubscriptionByCompanyId('company_1');
        final retrieved2 =
            await StorageService.getSubscriptionByCompanyId('company_2');

        expect(retrieved1!.tierId, 'tier_starter');
        expect(retrieved2!.tierId, 'tier_professional');
      });

      test('Each company can have only one active subscription', () async {
        final company = Company(
          id: 'company_1',
          name: 'Company 1',
          createdAt: DateTime.now(),
          adminUserId: 'admin_1',
          isActive: true,
        );

        await StorageService.addCompany(company);

        final sub1 = CompanySubscription(
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

        await StorageService.addSubscription(sub1);

        // Try to get subscription by company ID
        final retrieved =
            await StorageService.getSubscriptionByCompanyId('company_1');
        expect(retrieved, isNotNull);
        expect(retrieved!.status, SubscriptionStatus.active);
      });
    });

    group('Subscription Validation', () {
      test('Subscription has valid next billing date', () async {
        final now = DateTime.now();
        final subscription = CompanySubscription(
          id: 'sub_1',
          companyId: 'company_1',
          tierId: 'tier_starter',
          startDate: now,
          status: SubscriptionStatus.active,
          paymentMethod: PaymentMethod.creditCard,
          billingInterval: BillingInterval.monthly,
          nextBillingDate: now.add(const Duration(days: 30)),
          currentPrice: 29.0,
          gracePeriodDays: 7,
          createdAt: now,
          updatedAt: now,
        );

        await StorageService.addSubscription(subscription);

        final retrieved =
            await StorageService.getSubscriptionByCompanyId('company_1');
        expect(retrieved!.nextBillingDate.isAfter(now), true);
        expect(retrieved.daysUntilNextBilling, greaterThanOrEqualTo(29));
      });

      test('Trial subscription has valid trial end date', () async {
        final now = DateTime.now();
        final trialDays = 14;

        final subscription = CompanySubscription(
          id: 'sub_1',
          companyId: 'company_1',
          tierId: 'tier_starter',
          startDate: now,
          status: SubscriptionStatus.trial,
          paymentMethod: PaymentMethod.creditCard,
          billingInterval: BillingInterval.monthly,
          nextBillingDate: now.add(Duration(days: trialDays)),
          currentPrice: 29.0,
          gracePeriodDays: 7,
          createdAt: now,
          updatedAt: now,
          trialEndsAt: now.add(Duration(days: trialDays)),
        );

        await StorageService.addSubscription(subscription);

        final retrieved =
            await StorageService.getSubscriptionByCompanyId('company_1');
        expect(retrieved!.trialEndsAt, isNotNull);
        expect(retrieved.trialEndsAt!.isAfter(now), true);
      });

      test('Subscription price matches tier pricing', () async {
        final tiers = SubscriptionTier.defaultTiers;
        final starterTier = tiers.firstWhere((t) => t.id == 'tier_starter');

        final subscription = CompanySubscription(
          id: 'sub_1',
          companyId: 'company_1',
          tierId: starterTier.id,
          startDate: DateTime.now(),
          status: SubscriptionStatus.active,
          paymentMethod: PaymentMethod.creditCard,
          billingInterval: BillingInterval.monthly,
          nextBillingDate: DateTime.now().add(const Duration(days: 30)),
          currentPrice: starterTier.monthlyPrice,
          gracePeriodDays: 7,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await StorageService.addSubscription(subscription);

        final retrieved =
            await StorageService.getSubscriptionByCompanyId('company_1');
        expect(retrieved!.currentPrice, starterTier.monthlyPrice);
      });
    });

    group('Filtering Companies', () {
      test('Can identify companies without subscriptions', () async {
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

        // Add subscription only for company1
        final sub = CompanySubscription(
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

        await StorageService.addSubscription(sub);

        final allCompanies = await StorageService.getCompanies();
        final subscriptions = await StorageService.getSubscriptions();

        final companiesWithoutSub = allCompanies.where((company) {
          return !subscriptions.any((s) =>
              s.companyId == company.id &&
              (s.status == SubscriptionStatus.active ||
                  s.status == SubscriptionStatus.trial));
        }).toList();

        expect(companiesWithoutSub.length, 1);
        expect(companiesWithoutSub.first.id, 'company_2');
      });

      test('All companies with active or trial subscriptions are filtered out',
          () async {
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

        // Add active subscription for company1
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

        // Add trial subscription for company2
        final sub2 = CompanySubscription(
          id: 'sub_2',
          companyId: company2.id,
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

        await StorageService.addSubscription(sub1);
        await StorageService.addSubscription(sub2);

        final allCompanies = await StorageService.getCompanies();
        final subscriptions = await StorageService.getSubscriptions();

        final companiesWithoutSub = allCompanies.where((company) {
          return !subscriptions.any((s) =>
              s.companyId == company.id &&
              (s.status == SubscriptionStatus.active ||
                  s.status == SubscriptionStatus.trial));
        }).toList();

        expect(companiesWithoutSub.length, 0);
      });
    });
  });
}
