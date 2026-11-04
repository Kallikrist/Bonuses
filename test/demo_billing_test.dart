import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bonuses/config/app_config.dart';
import 'package:bonuses/models/company_subscription.dart';
import 'package:bonuses/models/user.dart';
import 'package:bonuses/providers/app_provider.dart';
import 'package:bonuses/services/storage_service.dart';
import 'package:bonuses/utils/demo_billing.dart';

const _legacyApplePayUtilifId = 'legacy_apple_pay_utilif';

CompanySubscription _subscription({
  String? id,
  required String companyId,
  required SubscriptionStatus status,
  double currentPrice = 29,
  String tierId = 'tier_starter',
}) {
  final now = DateTime(2026, 11, 4);
  return CompanySubscription(
    id: id ?? 'sub_$companyId',
    companyId: companyId,
    tierId: tierId,
    startDate: now,
    status: status,
    paymentMethod: PaymentMethod.creditCard,
    billingInterval: BillingInterval.monthly,
    nextBillingDate: now.add(const Duration(days: 30)),
    currentPrice: currentPrice,
    createdAt: now,
    updatedAt: now,
  );
}

String _readRepoFile(String relativePath) {
  final candidates = [
    File(relativePath),
    File('${Directory.current.path}/$relativePath'),
  ];
  for (final file in candidates) {
    if (file.existsSync()) {
      return file.readAsStringSync();
    }
  }
  fail('Could not read $relativePath from ${Directory.current.path}');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('shouldShowPaymentRequiredBanner', () {
    final pastDueUtilif = _subscription(
      companyId: kDemoCompanyUtilifId,
      status: SubscriptionStatus.pastDue,
      currentPrice: 1.0,
    );
    final activeOther = _subscription(
      companyId: 'real_company',
      status: SubscriptionStatus.active,
    );
    final pastDueOther = _subscription(
      companyId: 'real_company',
      status: SubscriptionStatus.pastDue,
      currentPrice: 49,
    );

    test('hides the banner in demo mode even when the company is past due', () {
      expect(
        shouldShowPaymentRequiredBanner(
          demoMode: true,
          companyId: kDemoCompanyUtilifId,
          subscriptions: [pastDueUtilif, activeOther],
        ),
        isFalse,
      );
    });

    test('shows the banner for the signed-in company when not in demo mode',
        () {
      expect(
        shouldShowPaymentRequiredBanner(
          demoMode: false,
          companyId: kDemoCompanyUtilifId,
          subscriptions: [pastDueUtilif],
        ),
        isTrue,
      );
    });

    test('does not fall back to another tenant\'s past-due subscription', () {
      expect(
        shouldShowPaymentRequiredBanner(
          demoMode: false,
          companyId: kDemoCompanyUtilifId,
          subscriptions: [pastDueOther],
        ),
        isFalse,
      );
    });

    test('hides when the signed-in company is active', () {
      expect(
        shouldShowPaymentRequiredBanner(
          demoMode: false,
          companyId: 'real_company',
          subscriptions: [activeOther, pastDueUtilif],
        ),
        isFalse,
      );
    });

    test('hides when company id is missing', () {
      expect(
        shouldShowPaymentRequiredBanner(
          demoMode: false,
          companyId: null,
          subscriptions: [pastDueUtilif],
        ),
        isFalse,
      );
    });

    test('hides when company id is empty', () {
      expect(
        shouldShowPaymentRequiredBanner(
          demoMode: false,
          companyId: '',
          subscriptions: [pastDueUtilif],
        ),
        isFalse,
      );
    });

    test('default AppConfig.demoMode hides the banner without an override', () {
      expect(AppConfig.demoMode, isTrue);
      expect(AppConfig.useMockStripe, isTrue);
      expect(
        shouldShowPaymentRequiredBanner(
          companyId: kDemoCompanyUtilifId,
          subscriptions: [pastDueUtilif],
        ),
        isFalse,
      );
    });
  });

  group('isDemoApplePayPastDueFixture', () {
    test('matches only Utilif at \$1 pastDue', () {
      expect(
        isDemoApplePayPastDueFixture(_subscription(
          companyId: kDemoCompanyUtilifId,
          status: SubscriptionStatus.pastDue,
          currentPrice: 1.0,
        )),
        isTrue,
      );
      expect(
        isDemoApplePayPastDueFixture(_subscription(
          companyId: kDemoCompanyUtilifId,
          status: SubscriptionStatus.active,
          currentPrice: 1.0,
        )),
        isFalse,
      );
      expect(
        isDemoApplePayPastDueFixture(_subscription(
          companyId: 'other',
          status: SubscriptionStatus.pastDue,
          currentPrice: 1.0,
        )),
        isFalse,
      );
      expect(
        isDemoApplePayPastDueFixture(_subscription(
          companyId: kDemoCompanyUtilifId,
          status: SubscriptionStatus.pastDue,
          currentPrice: kDemoUtilifActivePrice,
        )),
        isFalse,
        reason: 'real Utilif past-due at the professional price is not the \$1 fixture',
      );
    });
  });

  group('demo subscription seed', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await StorageService.clearAllData();
    });

    test('initializeSampleData seeds Utilif as active, not \$1 pastDue',
        () async {
      await StorageService.initializeSampleData();
      final subscriptions = await StorageService.getSubscriptions();
      final utilif = subscriptions
          .where((s) => s.companyId == kDemoCompanyUtilifId)
          .firstOrNull;
      expect(utilif, isNotNull);
      expect(utilif!.status, SubscriptionStatus.active);
      expect(utilif.currentPrice, kDemoUtilifActivePrice);
      expect(utilif.tierId, kDemoUtilifTierId);
      expect(
        subscriptions.where((s) => s.status == SubscriptionStatus.pastDue),
        isEmpty,
      );
    });

    test('initializeSampleData seeds other demo companies as active starter \$29',
        () async {
      await StorageService.initializeSampleData();
      final subscriptions = await StorageService.getSubscriptions();
      expect(subscriptions, isNotEmpty);
      expect(
        subscriptions.every((s) => s.status == SubscriptionStatus.active),
        isTrue,
      );

      final others = subscriptions
          .where((s) => s.companyId != kDemoCompanyUtilifId)
          .toList();
      expect(others, isNotEmpty);
      for (final subscription in others) {
        expect(subscription.status, SubscriptionStatus.active);
        expect(subscription.currentPrice, 29);
        expect(subscription.tierId, 'tier_starter');
      }
    });

    test('heal converts the \$1 Utilif fixture in place and leaves other billing',
        () async {
      await StorageService.saveSubscriptions([
        _subscription(
          id: _legacyApplePayUtilifId,
          companyId: kDemoCompanyUtilifId,
          status: SubscriptionStatus.pastDue,
          currentPrice: 1.0,
          tierId: 'tier_basic',
        ),
        _subscription(
          id: 'sub_real_company',
          companyId: 'real_company',
          status: SubscriptionStatus.pastDue,
          currentPrice: 49,
        ),
      ]);

      await StorageService.healDemoPastDueFixture();

      final subscriptions = await StorageService.getSubscriptions();
      expect(subscriptions, hasLength(2));
      expect(
        subscriptions.map((s) => s.id),
        unorderedEquals([_legacyApplePayUtilifId, 'sub_real_company']),
      );

      final utilif =
          subscriptions.firstWhere((s) => s.companyId == kDemoCompanyUtilifId);
      expect(utilif.id, _legacyApplePayUtilifId);
      expect(utilif.status, SubscriptionStatus.active);
      expect(utilif.currentPrice, kDemoUtilifActivePrice);
      expect(utilif.tierId, kDemoUtilifTierId);

      final real =
          subscriptions.firstWhere((s) => s.companyId == 'real_company');
      expect(real.id, 'sub_real_company');
      expect(real.status, SubscriptionStatus.pastDue);
      expect(real.currentPrice, 49);
    });

    test('heal does not convert Utilif pastDue at a non-\$1 price', () async {
      await StorageService.saveSubscriptions([
        _subscription(
          id: 'utilif_real_past_due',
          companyId: kDemoCompanyUtilifId,
          status: SubscriptionStatus.pastDue,
          currentPrice: kDemoUtilifActivePrice,
          tierId: kDemoUtilifTierId,
        ),
      ]);

      await StorageService.healDemoPastDueFixture();

      final subscriptions = await StorageService.getSubscriptions();
      expect(subscriptions, hasLength(1));
      expect(subscriptions.single.id, 'utilif_real_past_due');
      expect(subscriptions.single.status, SubscriptionStatus.pastDue);
      expect(subscriptions.single.currentPrice, kDemoUtilifActivePrice);
    });

    test('heal is a no-op when the \$1 fixture is absent', () async {
      await StorageService.saveSubscriptions([
        _subscription(
          id: 'already_healthy',
          companyId: kDemoCompanyUtilifId,
          status: SubscriptionStatus.active,
          currentPrice: kDemoUtilifActivePrice,
          tierId: kDemoUtilifTierId,
        ),
        _subscription(
          id: 'sub_real_company',
          companyId: 'real_company',
          status: SubscriptionStatus.pastDue,
          currentPrice: 49,
        ),
      ]);

      await StorageService.healDemoPastDueFixture();

      final subscriptions = await StorageService.getSubscriptions();
      expect(subscriptions, hasLength(2));
      expect(
        subscriptions.map((s) => s.id),
        unorderedEquals(['already_healthy', 'sub_real_company']),
      );
      final utilif =
          subscriptions.firstWhere((s) => s.id == 'already_healthy');
      expect(utilif.status, SubscriptionStatus.active);
      expect(utilif.currentPrice, kDemoUtilifActivePrice);
      final real =
          subscriptions.firstWhere((s) => s.id == 'sub_real_company');
      expect(real.status, SubscriptionStatus.pastDue);
      expect(real.currentPrice, 49);
    });

    test(
        'initializeSampleData heals an existing \$1 fixture without deleting other billing',
        () async {
      await StorageService.saveSubscriptions([
        _subscription(
          id: _legacyApplePayUtilifId,
          companyId: kDemoCompanyUtilifId,
          status: SubscriptionStatus.pastDue,
          currentPrice: 1.0,
          tierId: 'tier_basic',
        ),
        _subscription(
          id: 'sub_real_company',
          companyId: 'real_company',
          status: SubscriptionStatus.pastDue,
          currentPrice: 49,
        ),
      ]);

      await StorageService.initializeSampleData();

      final subscriptions = await StorageService.getSubscriptions();
      expect(
        subscriptions.map((s) => s.id),
        containsAll([_legacyApplePayUtilifId, 'sub_real_company']),
      );
      expect(
        subscriptions.where((s) => s.id == _legacyApplePayUtilifId),
        hasLength(1),
        reason: 'heal must convert in place, not insert a second Utilif row',
      );

      final utilif =
          subscriptions.firstWhere((s) => s.id == _legacyApplePayUtilifId);
      expect(utilif.status, SubscriptionStatus.active);
      expect(utilif.currentPrice, kDemoUtilifActivePrice);

      final real =
          subscriptions.firstWhere((s) => s.id == 'sub_real_company');
      expect(real.status, SubscriptionStatus.pastDue);
      expect(real.currentPrice, 49);
    });

    test(
        'AppProvider.initialize heals leftover fixture when demo users already exist',
        () async {
      for (final email in [
        'admin@store.com',
        'admin@utilif.com',
        'john.doe@example.com',
        'superadmin@platform.com',
      ]) {
        await StorageService.addUser(User(
          id: 'stub_$email',
          name: 'Stub',
          email: email,
          role: UserRole.admin,
          createdAt: DateTime(2026, 11, 4),
        ));
      }
      await StorageService.saveSubscriptions([
        _subscription(
          id: _legacyApplePayUtilifId,
          companyId: kDemoCompanyUtilifId,
          status: SubscriptionStatus.pastDue,
          currentPrice: 1.0,
          tierId: 'tier_basic',
        ),
        _subscription(
          id: 'sub_real_company',
          companyId: 'real_company',
          status: SubscriptionStatus.pastDue,
          currentPrice: 49,
        ),
      ]);

      final provider = AppProvider();
      await provider.initialize();

      final subscriptions = await StorageService.getSubscriptions();
      expect(subscriptions, hasLength(2));
      final utilif =
          subscriptions.firstWhere((s) => s.id == _legacyApplePayUtilifId);
      expect(utilif.status, SubscriptionStatus.active);
      expect(utilif.currentPrice, kDemoUtilifActivePrice);
      expect(utilif.tierId, kDemoUtilifTierId);

      final real =
          subscriptions.firstWhere((s) => s.id == 'sub_real_company');
      expect(real.status, SubscriptionStatus.pastDue);
      expect(real.currentPrice, 49);
    });
  });

  group('admin dashboard payment-due display', () {
    late String dashboard;
    late String bannerMethod;
    late String updateMethod;
    late String seedBlock;
    late String storage;
    late String providerSource;
    late String ciWorkflow;

    setUpAll(() {
      dashboard = _readRepoFile('lib/screens/admin_dashboard.dart');
      final bannerStart =
          dashboard.indexOf('Widget _buildSubscriptionStatusBanner');
      final bannerEnd = dashboard.indexOf('void _showDeleteTargetDialog');
      expect(bannerStart, greaterThanOrEqualTo(0));
      expect(bannerEnd, greaterThan(bannerStart));
      bannerMethod = dashboard.substring(bannerStart, bannerEnd);

      final updateStart = dashboard.indexOf(
          'Future<List<CompanySubscription>> _getSubscriptionsWithUpdate');
      expect(updateStart, greaterThanOrEqualTo(0));
      updateMethod = dashboard.substring(updateStart, bannerStart);

      storage = _readRepoFile('lib/services/storage_service.dart');
      final seedStart =
          storage.indexOf('Initialize demo subscriptions if they don\'t exist');
      final seedEnd = storage.indexOf('Approval Request management');
      expect(seedStart, greaterThanOrEqualTo(0));
      expect(seedEnd, greaterThan(seedStart));
      seedBlock = storage.substring(seedStart, seedEnd);

      providerSource = _readRepoFile('lib/providers/app_provider.dart');
      ciWorkflow = _readRepoFile('.github/workflows/flutter-tests.yml');
    });

    test(
        'banner uses demo-mode helper and does not fall back to another tenant',
        () {
      expect(bannerMethod, contains('shouldShowPaymentRequiredBanner'));
      expect(bannerMethod, contains('AppConfig.demoMode'));
      expect(
          bannerMethod, isNot(contains('orElse: () => subscriptions.first')));
      expect(bannerMethod, contains('Pay Now'));
      expect(bannerMethod, isNot(contains('Reset')));
      expect(bannerMethod, isNot(contains('forceUpdateUtilifSubscription')));
      expect(
          bannerMethod, isNot(contains('resetUtilifSubscriptionForTesting')));
    });

    test('Reset remains in Demo Settings, not on the payment-due banner', () {
      expect(dashboard, contains('Demo Settings'));
      expect(dashboard, contains('Reset Subscription for Testing'));
      expect(dashboard, contains('_resetSubscriptionForTesting(context)'));
      expect(bannerMethod, isNot(contains('Reset Subscription for Testing')));
      expect(bannerMethod, isNot(contains('_resetSubscriptionForTesting')));
    });

    test('dashboard load heals the fixture instead of forcing pastDue', () {
      expect(updateMethod, contains('healDemoPastDueFixture'));
      expect(updateMethod, isNot(contains('forceUpdateUtilifSubscription')));
      expect(
        dashboard,
        contains(
            'Future<List<CompanySubscription>> _getSubscriptionsWithUpdate'),
      );
    });

    test('sample-data seed no longer forces Utilif pastDue', () {
      expect(seedBlock, isNot(contains('SubscriptionStatus.pastDue')));
      expect(seedBlock, isNot(contains('currentPrice: 1.0')));
      expect(seedBlock, contains('healDemoPastDueFixture'));
    });

    test('AppProvider.initialize always heals the leftover fixture', () {
      expect(providerSource, contains('healDemoPastDueFixture'));
      expect(providerSource, isNot(contains('forceUpdateUtilifSubscription')));
    });

    test('opt-in Apple Pay helpers remain but are not called on load or seed',
        () {
      expect(storage, contains('forceUpdateUtilifSubscription'));
      expect(storage, contains('resetUtilifSubscriptionForTesting'));
      expect(RegExp(r'SubscriptionStatus\.pastDue').allMatches(storage),
          hasLength(2));
      expect(seedBlock, isNot(contains('forceUpdateUtilifSubscription')));
      expect(seedBlock, isNot(contains('resetUtilifSubscriptionForTesting')));
      expect(providerSource, isNot(contains('resetUtilifSubscriptionForTesting')));
    });

    test('demo billing tests are not a named CI exclusion', () {
      expect(ciWorkflow, contains('EXCLUDE='));
      expect(ciWorkflow, isNot(contains('demo_billing_test.dart')));
    });
  });
}
