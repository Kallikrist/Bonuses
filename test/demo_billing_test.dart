import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bonuses/models/company_subscription.dart';
import 'package:bonuses/services/storage_service.dart';
import 'package:bonuses/utils/demo_billing.dart';

CompanySubscription _subscription({
  required String companyId,
  required SubscriptionStatus status,
  double currentPrice = 29,
  String tierId = 'tier_starter',
}) {
  final now = DateTime(2026, 11, 4);
  return CompanySubscription(
    id: 'sub_$companyId',
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

    test('heal converts the \$1 Utilif fixture and leaves other billing',
        () async {
      final now = DateTime(2026, 11, 4);
      await StorageService.saveSubscriptions([
        _subscription(
          companyId: kDemoCompanyUtilifId,
          status: SubscriptionStatus.pastDue,
          currentPrice: 1.0,
          tierId: 'tier_basic',
        ),
        CompanySubscription(
          id: 'sub_real_company',
          companyId: 'real_company',
          tierId: 'tier_starter',
          startDate: now,
          status: SubscriptionStatus.pastDue,
          paymentMethod: PaymentMethod.creditCard,
          billingInterval: BillingInterval.monthly,
          nextBillingDate: now.add(const Duration(days: 10)),
          currentPrice: 49,
          createdAt: now,
          updatedAt: now,
        ),
      ]);

      await StorageService.healDemoPastDueFixture();

      final subscriptions = await StorageService.getSubscriptions();
      expect(subscriptions, hasLength(2));
      final utilif =
          subscriptions.firstWhere((s) => s.companyId == kDemoCompanyUtilifId);
      expect(utilif.status, SubscriptionStatus.active);
      expect(utilif.currentPrice, kDemoUtilifActivePrice);
      expect(utilif.tierId, kDemoUtilifTierId);

      final real =
          subscriptions.firstWhere((s) => s.companyId == 'real_company');
      expect(real.status, SubscriptionStatus.pastDue);
      expect(real.currentPrice, 49);
    });
  });

  group('admin dashboard payment-due display', () {
    late String bannerMethod;
    late String updateMethod;
    late String seedBlock;

    setUpAll(() {
      final dashboard = _readRepoFile('lib/screens/admin_dashboard.dart');
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

      final storage = _readRepoFile('lib/services/storage_service.dart');
      final seedStart =
          storage.indexOf('Initialize demo subscriptions if they don\'t exist');
      final seedEnd = storage.indexOf('Approval Request management');
      expect(seedStart, greaterThanOrEqualTo(0));
      expect(seedEnd, greaterThan(seedStart));
      seedBlock = storage.substring(seedStart, seedEnd);
    });

    test(
        'banner uses demo-mode helper and does not fall back to another tenant',
        () {
      expect(bannerMethod, contains('shouldShowPaymentRequiredBanner'));
      expect(bannerMethod, contains('AppConfig.demoMode'));
      expect(
          bannerMethod, isNot(contains('orElse: () => subscriptions.first')));
      expect(bannerMethod, isNot(contains('Reset')));
      expect(bannerMethod, isNot(contains('forceUpdateUtilifSubscription')));
      expect(
          bannerMethod, isNot(contains('resetUtilifSubscriptionForTesting')));
    });

    test('dashboard load heals the fixture instead of forcing pastDue', () {
      expect(updateMethod, contains('healDemoPastDueFixture'));
      expect(updateMethod, isNot(contains('forceUpdateUtilifSubscription')));
    });

    test('sample-data seed no longer forces Utilif pastDue', () {
      expect(seedBlock, isNot(contains('SubscriptionStatus.pastDue')));
      expect(seedBlock, isNot(contains('currentPrice: 1.0')));
      expect(seedBlock, contains('healDemoPastDueFixture'));
    });
  });
}
