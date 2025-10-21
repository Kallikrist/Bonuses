import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bonuses/services/storage_service.dart';
import 'package:bonuses/models/company.dart';
import 'package:bonuses/models/company_subscription.dart';
import 'package:bonuses/models/subscription_tier.dart';
import 'package:bonuses/models/user.dart';

void main() {
  group('Subscription Management Tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      
      // Create test company
      final testCompany = Company(
        id: 'test_company',
        name: 'Test Company',
        contactEmail: 'admin@test.com',
        adminUserId: 'admin1',
        createdAt: DateTime.now(),
        isActive: true,
      );
      await StorageService.addCompany(testCompany);
    });

    group('Subscription CRUD Operations', () {
      test('Can create a new subscription', () async {
        final now = DateTime.now();
        final subscription = CompanySubscription(
          id: 'sub_1',
          companyId: 'test_company',
          tierId: 'tier_starter',
          startDate: now,
          status: SubscriptionStatus.trial,
          paymentMethod: PaymentMethod.none,
          billingInterval: BillingInterval.monthly,
          nextBillingDate: now.add(const Duration(days: 14)),
          currentPrice: 0,
          trialEndsAt: now.add(const Duration(days: 14)),
          gracePeriodDays: 7,
          createdAt: now,
          updatedAt: now,
        );

        await StorageService.addSubscription(subscription);

        final subscriptions = await StorageService.getSubscriptions();
        expect(subscriptions.length, 1);
        expect(subscriptions.first.id, 'sub_1');
        expect(subscriptions.first.companyId, 'test_company');
        expect(subscriptions.first.status, SubscriptionStatus.trial);
      });

      test('Can retrieve subscription by company ID', () async {
        final now = DateTime.now();
        final subscription = CompanySubscription(
          id: 'sub_1',
          companyId: 'test_company',
          tierId: 'tier_starter',
          startDate: now,
          status: SubscriptionStatus.active,
          paymentMethod: PaymentMethod.creditCard,
          billingInterval: BillingInterval.monthly,
          nextBillingDate: now.add(const Duration(days: 30)),
          currentPrice: 29,
          gracePeriodDays: 7,
          createdAt: now,
          updatedAt: now,
        );

        await StorageService.addSubscription(subscription);

        final retrieved = await StorageService.getSubscriptionByCompanyId('test_company');
        expect(retrieved, isNotNull);
        expect(retrieved!.id, 'sub_1');
        expect(retrieved.companyId, 'test_company');
      });

      test('Returns null for non-existent company subscription', () async {
        final retrieved = await StorageService.getSubscriptionByCompanyId('non_existent');
        expect(retrieved, isNull);
      });

      test('Can update a subscription', () async {
        final now = DateTime.now();
        final subscription = CompanySubscription(
          id: 'sub_1',
          companyId: 'test_company',
          tierId: 'tier_starter',
          startDate: now,
          status: SubscriptionStatus.trial,
          paymentMethod: PaymentMethod.none,
          billingInterval: BillingInterval.monthly,
          nextBillingDate: now.add(const Duration(days: 14)),
          currentPrice: 0,
          trialEndsAt: now.add(const Duration(days: 14)),
          gracePeriodDays: 7,
          createdAt: now,
          updatedAt: now,
        );

        await StorageService.addSubscription(subscription);

        // Update to active status
        final updatedSubscription = subscription.copyWith(
          status: SubscriptionStatus.active,
          currentPrice: 29,
          paymentMethod: PaymentMethod.creditCard,
          trialEndsAt: null,
          updatedAt: DateTime.now(),
        );

        await StorageService.updateSubscription(updatedSubscription);

        final subscriptions = await StorageService.getSubscriptions();
        expect(subscriptions.length, 1);
        expect(subscriptions.first.status, SubscriptionStatus.active);
        expect(subscriptions.first.currentPrice, 29);
        expect(subscriptions.first.paymentMethod, PaymentMethod.creditCard);
      });

      test('Can delete a subscription', () async {
        final now = DateTime.now();
        final subscription = CompanySubscription(
          id: 'sub_1',
          companyId: 'test_company',
          tierId: 'tier_starter',
          startDate: now,
          status: SubscriptionStatus.active,
          paymentMethod: PaymentMethod.creditCard,
          billingInterval: BillingInterval.monthly,
          nextBillingDate: now.add(const Duration(days: 30)),
          currentPrice: 29,
          gracePeriodDays: 7,
          createdAt: now,
          updatedAt: now,
        );

        await StorageService.addSubscription(subscription);
        expect((await StorageService.getSubscriptions()).length, 1);

        await StorageService.deleteSubscription('sub_1');
        expect((await StorageService.getSubscriptions()).length, 0);
      });
    });

    group('Subscription Status Tests', () {
      test('Trial subscription is considered active', () {
        final now = DateTime.now();
        final subscription = CompanySubscription(
          id: 'sub_1',
          companyId: 'test_company',
          tierId: 'tier_starter',
          startDate: now,
          status: SubscriptionStatus.trial,
          paymentMethod: PaymentMethod.none,
          billingInterval: BillingInterval.monthly,
          nextBillingDate: now.add(const Duration(days: 14)),
          currentPrice: 0,
          trialEndsAt: now.add(const Duration(days: 14)),
          gracePeriodDays: 7,
          createdAt: now,
          updatedAt: now,
        );

        expect(subscription.isActive, true);
        expect(subscription.isTrial, true);
        expect(subscription.needsAttention, false);
      });

      test('Active subscription status is correct', () {
        final now = DateTime.now();
        final subscription = CompanySubscription(
          id: 'sub_1',
          companyId: 'test_company',
          tierId: 'tier_starter',
          startDate: now,
          status: SubscriptionStatus.active,
          paymentMethod: PaymentMethod.creditCard,
          billingInterval: BillingInterval.monthly,
          nextBillingDate: now.add(const Duration(days: 30)),
          currentPrice: 29,
          gracePeriodDays: 7,
          createdAt: now,
          updatedAt: now,
        );

        expect(subscription.isActive, true);
        expect(subscription.isTrial, false);
        expect(subscription.needsAttention, false);
      });

      test('Past due subscription needs attention', () {
        final now = DateTime.now();
        final subscription = CompanySubscription(
          id: 'sub_1',
          companyId: 'test_company',
          tierId: 'tier_starter',
          startDate: now,
          status: SubscriptionStatus.pastDue,
          paymentMethod: PaymentMethod.creditCard,
          billingInterval: BillingInterval.monthly,
          nextBillingDate: now.subtract(const Duration(days: 5)),
          currentPrice: 29,
          gracePeriodDays: 7,
          createdAt: now,
          updatedAt: now,
        );

        expect(subscription.isActive, false);
        expect(subscription.needsAttention, true);
      });

      test('Suspended subscription needs attention', () {
        final now = DateTime.now();
        final subscription = CompanySubscription(
          id: 'sub_1',
          companyId: 'test_company',
          tierId: 'tier_starter',
          startDate: now,
          status: SubscriptionStatus.suspended,
          paymentMethod: PaymentMethod.creditCard,
          billingInterval: BillingInterval.monthly,
          nextBillingDate: now.add(const Duration(days: 30)),
          currentPrice: 29,
          gracePeriodDays: 7,
          createdAt: now,
          updatedAt: now,
        );

        expect(subscription.isActive, false);
        expect(subscription.needsAttention, true);
      });

      test('Trial days calculation works correctly', () {
        final now = DateTime.now();
        final subscription = CompanySubscription(
          id: 'sub_1',
          companyId: 'test_company',
          tierId: 'tier_starter',
          startDate: now,
          status: SubscriptionStatus.trial,
          paymentMethod: PaymentMethod.none,
          billingInterval: BillingInterval.monthly,
          nextBillingDate: now.add(const Duration(days: 14)),
          currentPrice: 0,
          trialEndsAt: now.add(const Duration(days: 10)),
          gracePeriodDays: 7,
          createdAt: now,
          updatedAt: now,
        );

        final daysLeft = subscription.daysUntilTrialEnds;
        expect(daysLeft, isNotNull);
        expect(daysLeft! >= 9 && daysLeft <= 10, true); // Allow for timing differences
      });

      test('Billing interval affects pricing correctly', () {
        final now = DateTime.now();
        final monthlySubscription = CompanySubscription(
          id: 'sub_monthly',
          companyId: 'test_company',
          tierId: 'tier_professional',
          startDate: now,
          status: SubscriptionStatus.active,
          paymentMethod: PaymentMethod.creditCard,
          billingInterval: BillingInterval.monthly,
          nextBillingDate: now.add(const Duration(days: 30)),
          currentPrice: 99,
          gracePeriodDays: 7,
          createdAt: now,
          updatedAt: now,
        );

        final yearlySubscription = CompanySubscription(
          id: 'sub_yearly',
          companyId: 'test_company',
          tierId: 'tier_professional',
          startDate: now,
          status: SubscriptionStatus.active,
          paymentMethod: PaymentMethod.creditCard,
          billingInterval: BillingInterval.yearly,
          nextBillingDate: now.add(const Duration(days: 365)),
          currentPrice: 990,
          gracePeriodDays: 7,
          createdAt: now,
          updatedAt: now,
        );

        expect(monthlySubscription.billingInterval, BillingInterval.monthly);
        expect(yearlySubscription.billingInterval, BillingInterval.yearly);
        expect(monthlySubscription.currentPrice, 99);
        expect(yearlySubscription.currentPrice, 990);
      });
    });

    group('Subscription Tier Tests', () {
      test('Default tiers are available', () {
        final tiers = SubscriptionTier.defaultTiers;
        expect(tiers.length, 4);
        expect(tiers.any((t) => t.name == 'Free Trial'), true);
        expect(tiers.any((t) => t.name == 'Starter'), true);
        expect(tiers.any((t) => t.name == 'Professional'), true);
        expect(tiers.any((t) => t.name == 'Enterprise'), true);
      });

      test('Free tier has correct limits', () {
        final freeTier = SubscriptionTier.free;
        expect(freeTier.monthlyPrice, 0);
        expect(freeTier.maxEmployees, 5);
        expect(freeTier.maxWorkplaces, 1);
        expect(freeTier.maxBonuses, 10);
      });

      test('Professional tier has unlimited bonuses', () {
        final proTier = SubscriptionTier.professional;
        expect(proTier.maxBonuses, -1); // -1 means unlimited
        expect(proTier.maxEmployees, 50);
        expect(proTier.maxWorkplaces, 10);
      });

      test('Enterprise tier has unlimited everything', () {
        final entTier = SubscriptionTier.enterprise;
        expect(entTier.maxEmployees, -1); // unlimited
        expect(entTier.maxWorkplaces, -1); // unlimited
        expect(entTier.maxBonuses, -1); // unlimited
      });

      test('Tier pricing is correct', () {
        expect(SubscriptionTier.free.monthlyPrice, 0);
        expect(SubscriptionTier.starter.monthlyPrice, 29);
        expect(SubscriptionTier.professional.monthlyPrice, 99);
        expect(SubscriptionTier.enterprise.monthlyPrice, 299);
      });

      test('Yearly pricing includes discount', () {
        final starter = SubscriptionTier.starter;
        final yearlyPrice = starter.yearlyPrice!;
        final monthlyEquivalent = starter.monthlyPrice * 12;
        expect(yearlyPrice < monthlyEquivalent, true); // Yearly should be discounted
      });
    });

    group('Multiple Subscriptions', () {
      test('Can manage multiple subscriptions for different companies', () async {
        final company1 = Company(
          id: 'company_1',
          name: 'Company 1',
          contactEmail: 'admin1@test.com',
          adminUserId: 'admin1',
          createdAt: DateTime.now(),
          isActive: true,
        );
        final company2 = Company(
          id: 'company_2',
          name: 'Company 2',
          contactEmail: 'admin2@test.com',
          adminUserId: 'admin2',
          createdAt: DateTime.now(),
          isActive: true,
        );

        await StorageService.addCompany(company1);
        await StorageService.addCompany(company2);

        final now = DateTime.now();
        final sub1 = CompanySubscription(
          id: 'sub_1',
          companyId: 'company_1',
          tierId: 'tier_starter',
          startDate: now,
          status: SubscriptionStatus.active,
          paymentMethod: PaymentMethod.creditCard,
          billingInterval: BillingInterval.monthly,
          nextBillingDate: now.add(const Duration(days: 30)),
          currentPrice: 29,
          gracePeriodDays: 7,
          createdAt: now,
          updatedAt: now,
        );

        final sub2 = CompanySubscription(
          id: 'sub_2',
          companyId: 'company_2',
          tierId: 'tier_professional',
          startDate: now,
          status: SubscriptionStatus.active,
          paymentMethod: PaymentMethod.creditCard,
          billingInterval: BillingInterval.yearly,
          nextBillingDate: now.add(const Duration(days: 365)),
          currentPrice: 990,
          gracePeriodDays: 7,
          createdAt: now,
          updatedAt: now,
        );

        await StorageService.addSubscription(sub1);
        await StorageService.addSubscription(sub2);

        final subscriptions = await StorageService.getSubscriptions();
        expect(subscriptions.length, 2);

        final company1Sub = await StorageService.getSubscriptionByCompanyId('company_1');
        final company2Sub = await StorageService.getSubscriptionByCompanyId('company_2');

        expect(company1Sub?.tierId, 'tier_starter');
        expect(company2Sub?.tierId, 'tier_professional');
      });

      test('Subscriptions can have different statuses', () async {
        final now = DateTime.now();
        final subscriptions = [
          CompanySubscription(
            id: 'sub_trial',
            companyId: 'test_company',
            tierId: 'tier_free',
            startDate: now,
            status: SubscriptionStatus.trial,
            paymentMethod: PaymentMethod.none,
            billingInterval: BillingInterval.monthly,
            nextBillingDate: now.add(const Duration(days: 14)),
            currentPrice: 0,
            trialEndsAt: now.add(const Duration(days: 14)),
            gracePeriodDays: 7,
            createdAt: now,
            updatedAt: now,
          ),
        ];

        await StorageService.saveSubscriptions(subscriptions);

        // Update to active
        final updatedSub = subscriptions.first.copyWith(
          status: SubscriptionStatus.active,
          currentPrice: 29,
          trialEndsAt: null,
        );

        await StorageService.updateSubscription(updatedSub);

        final retrieved = await StorageService.getSubscriptionByCompanyId('test_company');
        expect(retrieved?.status, SubscriptionStatus.active);
        expect(retrieved?.isTrial, false);
        expect(retrieved?.isActive, true);
      });
    });

    group('Subscription Status Transitions', () {
      test('Trial can transition to active', () async {
        final now = DateTime.now();
        final trialSub = CompanySubscription(
          id: 'sub_1',
          companyId: 'test_company',
          tierId: 'tier_starter',
          startDate: now,
          status: SubscriptionStatus.trial,
          paymentMethod: PaymentMethod.none,
          billingInterval: BillingInterval.monthly,
          nextBillingDate: now.add(const Duration(days: 14)),
          currentPrice: 0,
          trialEndsAt: now.add(const Duration(days: 14)),
          gracePeriodDays: 7,
          createdAt: now,
          updatedAt: now,
        );

        await StorageService.addSubscription(trialSub);

        final activeSub = trialSub.copyWith(
          status: SubscriptionStatus.active,
          paymentMethod: PaymentMethod.creditCard,
          currentPrice: 29,
          trialEndsAt: null,
        );

        await StorageService.updateSubscription(activeSub);

        final retrieved = await StorageService.getSubscriptionByCompanyId('test_company');
        expect(retrieved?.status, SubscriptionStatus.active);
        expect(retrieved?.paymentMethod, PaymentMethod.creditCard);
      });

      test('Active can transition to past due', () async {
        final now = DateTime.now();
        final activeSub = CompanySubscription(
          id: 'sub_1',
          companyId: 'test_company',
          tierId: 'tier_starter',
          startDate: now,
          status: SubscriptionStatus.active,
          paymentMethod: PaymentMethod.creditCard,
          billingInterval: BillingInterval.monthly,
          nextBillingDate: now.add(const Duration(days: 30)),
          currentPrice: 29,
          gracePeriodDays: 7,
          createdAt: now,
          updatedAt: now,
        );

        await StorageService.addSubscription(activeSub);

        final pastDueSub = activeSub.copyWith(
          status: SubscriptionStatus.pastDue,
        );

        await StorageService.updateSubscription(pastDueSub);

        final retrieved = await StorageService.getSubscriptionByCompanyId('test_company');
        expect(retrieved?.status, SubscriptionStatus.pastDue);
        expect(retrieved?.needsAttention, true);
        expect(retrieved?.isActive, false);
      });

      test('Past due can transition to suspended', () async {
        final now = DateTime.now();
        final pastDueSub = CompanySubscription(
          id: 'sub_1',
          companyId: 'test_company',
          tierId: 'tier_starter',
          startDate: now,
          status: SubscriptionStatus.pastDue,
          paymentMethod: PaymentMethod.creditCard,
          billingInterval: BillingInterval.monthly,
          nextBillingDate: now.subtract(const Duration(days: 10)),
          currentPrice: 29,
          gracePeriodDays: 7,
          createdAt: now,
          updatedAt: now,
        );

        await StorageService.addSubscription(pastDueSub);

        final suspendedSub = pastDueSub.copyWith(
          status: SubscriptionStatus.suspended,
        );

        await StorageService.updateSubscription(suspendedSub);

        final retrieved = await StorageService.getSubscriptionByCompanyId('test_company');
        expect(retrieved?.status, SubscriptionStatus.suspended);
        expect(retrieved?.needsAttention, true);
      });

      test('Subscription can be cancelled', () async {
        final now = DateTime.now();
        final activeSub = CompanySubscription(
          id: 'sub_1',
          companyId: 'test_company',
          tierId: 'tier_starter',
          startDate: now,
          status: SubscriptionStatus.active,
          paymentMethod: PaymentMethod.creditCard,
          billingInterval: BillingInterval.monthly,
          nextBillingDate: now.add(const Duration(days: 30)),
          currentPrice: 29,
          gracePeriodDays: 7,
          createdAt: now,
          updatedAt: now,
        );

        await StorageService.addSubscription(activeSub);

        final cancelledSub = activeSub.copyWith(
          status: SubscriptionStatus.cancelled,
          endDate: now,
        );

        await StorageService.updateSubscription(cancelledSub);

        final retrieved = await StorageService.getSubscriptionByCompanyId('test_company');
        expect(retrieved?.status, SubscriptionStatus.cancelled);
        expect(retrieved?.endDate, isNotNull);
      });
    });

    group('Subscription and Company Integration', () {
      test('Company can have a subscription reference', () async {
        final now = DateTime.now();
        final subscription = CompanySubscription(
          id: 'sub_1',
          companyId: 'test_company',
          tierId: 'tier_starter',
          startDate: now,
          status: SubscriptionStatus.active,
          paymentMethod: PaymentMethod.creditCard,
          billingInterval: BillingInterval.monthly,
          nextBillingDate: now.add(const Duration(days: 30)),
          currentPrice: 29,
          gracePeriodDays: 7,
          createdAt: now,
          updatedAt: now,
        );

        await StorageService.addSubscription(subscription);

        // Update company to reference subscription
        final companies = await StorageService.getCompanies();
        final company = companies.firstWhere((c) => c.id == 'test_company');
        final updatedCompany = company.copyWith(subscriptionId: 'sub_1');
        await StorageService.updateCompany(updatedCompany);

        final updatedCompanies = await StorageService.getCompanies();
        final retrievedCompany = updatedCompanies.firstWhere((c) => c.id == 'test_company');
        expect(retrievedCompany.subscriptionId, 'sub_1');
      });

      test('Can find subscription for a company', () async {
        final now = DateTime.now();
        final subscription = CompanySubscription(
          id: 'sub_1',
          companyId: 'test_company',
          tierId: 'tier_professional',
          startDate: now,
          status: SubscriptionStatus.active,
          paymentMethod: PaymentMethod.creditCard,
          billingInterval: BillingInterval.monthly,
          nextBillingDate: now.add(const Duration(days: 30)),
          currentPrice: 99,
          gracePeriodDays: 7,
          createdAt: now,
          updatedAt: now,
        );

        await StorageService.addSubscription(subscription);

        final retrieved = await StorageService.getSubscriptionByCompanyId('test_company');
        expect(retrieved, isNotNull);
        expect(retrieved!.companyId, 'test_company');
        expect(retrieved.tierId, 'tier_professional');
      });
    });

    group('Subscription JSON Serialization', () {
      test('Subscription can be serialized and deserialized', () {
        final now = DateTime.now();
        final subscription = CompanySubscription(
          id: 'sub_1',
          companyId: 'test_company',
          tierId: 'tier_starter',
          startDate: now,
          status: SubscriptionStatus.active,
          paymentMethod: PaymentMethod.creditCard,
          billingInterval: BillingInterval.monthly,
          nextBillingDate: now.add(const Duration(days: 30)),
          currentPrice: 29,
          gracePeriodDays: 7,
          createdAt: now,
          updatedAt: now,
        );

        final json = subscription.toJson();
        final deserialized = CompanySubscription.fromJson(json);

        expect(deserialized.id, subscription.id);
        expect(deserialized.companyId, subscription.companyId);
        expect(deserialized.tierId, subscription.tierId);
        expect(deserialized.status, subscription.status);
        expect(deserialized.paymentMethod, subscription.paymentMethod);
        expect(deserialized.billingInterval, subscription.billingInterval);
        expect(deserialized.currentPrice, subscription.currentPrice);
      });

      test('Subscription tier can be serialized and deserialized', () {
        final tier = SubscriptionTier.professional;
        final json = tier.toJson();
        final deserialized = SubscriptionTier.fromJson(json);

        expect(deserialized.id, tier.id);
        expect(deserialized.name, tier.name);
        expect(deserialized.monthlyPrice, tier.monthlyPrice);
        expect(deserialized.maxEmployees, tier.maxEmployees);
        expect(deserialized.features.length, tier.features.length);
      });
    });

    group('Payment Method Tests', () {
      test('Different payment methods are supported', () {
        expect(PaymentMethod.values.contains(PaymentMethod.creditCard), true);
        expect(PaymentMethod.values.contains(PaymentMethod.debitCard), true);
        expect(PaymentMethod.values.contains(PaymentMethod.paypal), true);
        expect(PaymentMethod.values.contains(PaymentMethod.bankTransfer), true);
        expect(PaymentMethod.values.contains(PaymentMethod.manual), true);
        expect(PaymentMethod.values.contains(PaymentMethod.none), true);
      });

      test('Free tier uses none payment method', () {
        final now = DateTime.now();
        final freeSub = CompanySubscription(
          id: 'sub_1',
          companyId: 'test_company',
          tierId: 'tier_free',
          startDate: now,
          status: SubscriptionStatus.trial,
          paymentMethod: PaymentMethod.none,
          billingInterval: BillingInterval.monthly,
          nextBillingDate: now.add(const Duration(days: 14)),
          currentPrice: 0,
          trialEndsAt: now.add(const Duration(days: 14)),
          gracePeriodDays: 7,
          createdAt: now,
          updatedAt: now,
        );

        expect(freeSub.paymentMethod, PaymentMethod.none);
        expect(freeSub.currentPrice, 0);
      });
    });
  });
}

