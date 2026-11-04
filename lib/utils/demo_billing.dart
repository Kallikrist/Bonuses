import '../config/app_config.dart';
import '../models/company_subscription.dart';

/// Seed tenant id for Utilif / `admin@store.com` (see `initializeSampleData`).
const kDemoCompanyUtilifId = 'demo_company_utilif';

/// Professional-tier price used for a healthy Utilif demo subscription.
const kDemoUtilifActivePrice = 99.0;

/// Tier assigned to the Utilif demo company when it is in good standing.
const kDemoUtilifTierId = 'tier_professional';

/// Leftover Apple Pay test fixture: Utilif at $1 with [SubscriptionStatus.pastDue].
bool isDemoApplePayPastDueFixture(CompanySubscription subscription) {
  return subscription.companyId == kDemoCompanyUtilifId &&
      subscription.status == SubscriptionStatus.pastDue &&
      subscription.currentPrice == 1.0;
}

/// Whether the Store Manager dashboard should nag about a past-due invoice.
///
/// Demo/mock mode never shows a real past-due banner — payments are not live.
/// Only the signed-in company's own subscription counts; never fall back to
/// another tenant's record.
bool shouldShowPaymentRequiredBanner({
  bool? demoMode,
  required String? companyId,
  required List<CompanySubscription> subscriptions,
}) {
  final inDemoMode = demoMode ?? AppConfig.demoMode;
  if (inDemoMode) return false;
  if (companyId == null || companyId.isEmpty) return false;
  for (final subscription in subscriptions) {
    if (subscription.companyId == companyId) {
      return subscription.status == SubscriptionStatus.pastDue;
    }
  }
  return false;
}
