import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bonuses/config/app_config.dart';
import 'package:bonuses/models/company_subscription.dart';
import 'package:bonuses/services/kling_embed.dart';
import 'package:bonuses/services/kling_service.dart';
import 'package:bonuses/utils/app_semantics.dart';
import 'package:bonuses/utils/demo_billing.dart';
import 'package:bonuses/widgets/kling_billing_card.dart';
import 'package:bonuses/widgets/kling_checkout_overlay.dart';

String _mustRead(String relative) {
  final candidates = [
    File(relative),
    File('${Directory.current.path}/$relative'),
  ];
  for (final file in candidates) {
    if (file.existsSync()) {
      return file.readAsStringSync();
    }
  }
  fail('Could not read $relative from ${Directory.current.path}');
}

final _embeddedSecret = RegExp(r'sk_(live|test)_[0-9a-zA-Z]{16,}');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late String klingService;
  late String stripeService;
  late String klingSecret;
  late String klingWebhook;
  late String overlay;
  late String card;
  late String adminSub;
  late String config;
  late String envExample;
  late String runWithEnv;
  late String indexHtml;
  late String workflow;
  late String checklist;

  setUpAll(() {
    klingService = _mustRead('lib/services/kling_service.dart');
    stripeService = _mustRead('lib/services/stripe_service.dart');
    klingSecret = _mustRead('supabase/functions/kling-secret/index.ts');
    klingWebhook = _mustRead('supabase/functions/kling-webhook/index.ts');
    overlay = _mustRead('lib/widgets/kling_checkout_overlay.dart');
    card = _mustRead('lib/widgets/kling_billing_card.dart');
    adminSub = _mustRead('lib/screens/admin_subscription_screen.dart');
    config = _mustRead('lib/config/app_config.dart');
    envExample = _mustRead('env.example');
    runWithEnv = _mustRead('scripts/run_with_env.sh');
    indexHtml = _mustRead('web/index.html');
    workflow = _mustRead('.github/workflows/flutter-tests.yml');
    checklist = _mustRead('LAUNCH_CHECKLIST.md');
  });

  group('demo-gate', () {
    test('AppConfig defaults keep Kling on the mock path', () {
      expect(AppConfig.demoMode, isTrue);
      expect(AppConfig.isSupabaseConfigured, isFalse);
      expect(AppConfig.useMockKling, isTrue);
      expect(AppConfig.useMockStripe, isTrue);
      expect(AppConfig.klingStoreProductId, isEmpty);
      expect(AppConfig.stripePublishableKey, isEmpty);
    });

    test('createCheckoutSession stays mock: card, ISK integer, no x100',
        () async {
      final session = await KlingService.createCheckoutSession(
        companyId: 'demo_company_utilif',
        customerEmail: 'admin@store.com',
        customerName: 'Store Admin',
      );
      expect(session['demo'], isTrue);
      expect(session['amount'], KlingService.mockStoreAmountIsk);
      expect(session['amount'], 4990);
      expect(session['amount'], isNot(499000));
      expect(session['currency'], 'ISK');
      expect(session['payment_method_type'], 'card');
      expect(session['id'], isA<String>());
    });

    test('createBillingPortalSession stays mock without a Kling secret',
        () async {
      final portal = await KlingService.createBillingPortalSession(
        customerId: '00000000-0000-4000-8000-000000000001',
        returnUrl: 'https://bonuses.app/account',
      );
      expect(portal['demo'], isTrue);
      expect(portal['url'], contains('pay.kling.is'));
      expect(portal['customer'], '00000000-0000-4000-8000-000000000001');
    });

    test('formatIsk prints whole krónur without multiplying', () {
      expect(KlingService.formatIsk(4990), '4.990 kr');
      expect(KlingService.formatIsk(5000), '5.000 kr');
      expect(KlingService.mockStoreAmountIsk, 4990);
    });

    test('demo accounts still hide the payment-required banner', () {
      expect(
        shouldShowPaymentRequiredBanner(
          companyId: kDemoCompanyUtilifId,
          subscriptions: [
            CompanySubscription(
              id: 'sub_utilif',
              companyId: kDemoCompanyUtilifId,
              tierId: kDemoUtilifTierId,
              startDate: DateTime(2026, 11, 4),
              status: SubscriptionStatus.pastDue,
              paymentMethod: PaymentMethod.creditCard,
              billingInterval: BillingInterval.monthly,
              nextBillingDate: DateTime(2026, 12, 4),
              currentPrice: 1.0,
              createdAt: DateTime(2026, 11, 4),
              updatedAt: DateTime(2026, 11, 4),
            ),
          ],
        ),
        isFalse,
      );
    });
  });

  group('secrets stay out of lib/', () {
    test('no lib Dart file holds Kling or Stripe secrets', () {
      final dartFiles = Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'))
          .toList();
      expect(dartFiles, isNotEmpty);
      for (final file in dartFiles) {
        final text = file.readAsStringSync();
        expect(_embeddedSecret.hasMatch(text), isFalse, reason: file.path);
        expect(
          text,
          isNot(contains("fromEnvironment('KLING_SECRET_KEY'")),
          reason: file.path,
        );
        expect(
          text,
          isNot(contains('fromEnvironment("KLING_SECRET_KEY"')),
          reason: file.path,
        );
        expect(
          text,
          isNot(contains("fromEnvironment('KLING_WEBHOOK_SECRET'")),
          reason: file.path,
        );
        expect(
          text,
          isNot(contains('fromEnvironment("KLING_WEBHOOK_SECRET"')),
          reason: file.path,
        );
        expect(
          text,
          isNot(contains('--dart-define=KLING_SECRET_KEY')),
          reason: file.path,
        );
        expect(
          text,
          isNot(contains('--dart-define=KLING_WEBHOOK_SECRET')),
          reason: file.path,
        );
      }
    });

    test('kling_service invokes kling-secret like stripe-secret, not webhook',
        () {
      expect(klingService, contains("_functionName = 'kling-secret'"));
      expect(klingService, contains('_invokeSecretAction'));
      expect(klingService, contains('createCheckoutSession'));
      expect(klingService, contains('createBillingPortalSession'));
      expect(klingService, contains("'paymentMethodType': paymentMethodType"));
      expect(klingService, contains("paymentMethodType = 'card'"));
      expect(klingService, contains("currency = 'ISK'"));
      expect(klingService, contains('Never multiply by 100'));
      expect(klingService, isNot(contains('* 100')));
      expect(klingService, isNot(contains('*100')));
      expect(klingService, isNot(contains("invoke('kling-webhook')")));
      expect(klingService, isNot(contains("_functionName = 'kling-webhook'")));

      expect(stripeService, contains("_functionName = 'stripe-secret'"));
      expect(stripeService, contains('_invokeSecretAction'));
      expect(stripeService, contains('(amount * 100)'));
      expect(stripeService, isNot(contains('kling-secret')));
    });

    test('live checkout payload uses productId, never amount', () {
      final invoke = klingService.indexOf(
        "_invokeSecretAction('createCheckoutSession'",
      );
      expect(invoke, greaterThanOrEqualTo(0));
      final payloadEnd = klingService.indexOf('});', invoke);
      expect(payloadEnd, greaterThan(invoke));
      final livePayload = klingService.substring(invoke, payloadEnd);
      expect(livePayload, contains("'productId': resolvedProductId"));
      expect(livePayload, isNot(contains("'amount':")));
      expect(livePayload, contains("'paymentMethodType': paymentMethodType"));
    });

    test('env templates never dart-define Kling secrets', () {
      expect(envExample, contains('Do NOT put KLING_SECRET_KEY'));
      expect(envExample, contains('KLING_STORE_PRODUCT_ID='));
      expect(envExample, isNot(contains('\nKLING_SECRET_KEY=')));
      expect(envExample, isNot(contains('\nKLING_WEBHOOK_SECRET=')));
      expect(runWithEnv, contains('--dart-define=KLING_STORE_PRODUCT_ID='));
      expect(runWithEnv, isNot(contains('--dart-define=KLING_SECRET_KEY')));
      expect(
        runWithEnv,
        isNot(contains('--dart-define=KLING_WEBHOOK_SECRET')),
      );
      expect(config, contains('KLING_STORE_PRODUCT_ID'));
      expect(config, isNot(contains("fromEnvironment('KLING_SECRET_KEY'")));
      expect(config, contains('useMockKling'));
    });

    test('web overlay script is the public kling.js URL, not a key', () {
      expect(indexHtml, contains('https://api.kling.is/v1/kling.js'));
      expect(indexHtml, contains('not a secret key'));
      expect(KlingService.publicEmbedScriptUrl,
          'https://api.kling.is/v1/kling.js');
      expect(_embeddedSecret.hasMatch(indexHtml), isFalse);
    });
  });

  group('edge functions stay as BON-40/41 left them', () {
    test('kling-secret still forces card + ISK and is not x100', () {
      expect(klingSecret, contains('payment_method_type: CARD_ONLY'));
      expect(klingSecret, contains('const CARD_ONLY = "card"'));
      expect(klingSecret, contains('const ISK = "ISK"'));
      expect(klingSecret, contains('createCheckoutSession'));
      expect(klingSecret, contains('createBillingPortalSession'));
      expect(klingSecret, isNot(contains('* 100')));
      expect(klingSecret, isNot(contains('Math.round')));
    });

    test('kling-webhook is not invoked from Flutter', () {
      expect(klingWebhook, contains('KLING_WEBHOOK_SECRET'));
      expect(overlay, isNot(contains('kling-webhook')));
      expect(card, isNot(contains('kling-webhook')));
    });
  });

  group('UI wiring and accessibility', () {
    test('admin subscription hosts the Kling card and demo-gates past due', () {
      expect(adminSub, contains('KlingBillingCard'));
      expect(adminSub, contains('shouldShowPaymentRequiredBanner'));
      expect(card, contains('AppSemantics.klingBilling'));
      expect(card, contains('AppSemantics.klingSubscribe'));
      expect(card, contains('AppSemantics.klingManageBilling'));
      expect(card, contains('AppSemantics.klingDemoNotice'));
      expect(overlay, contains('AppSemantics.klingCheckoutOverlay'));
      expect(overlay, contains('AppSemantics.klingCheckoutPay'));
      expect(overlay, contains('AppSemantics.klingPortal'));
      expect(checklist, contains('demo-gated'));
      expect(checklist, contains('useMockKling'));
    });

    test('this file is not a named CI exclusion', () {
      final excludeLine = workflow
          .split('\n')
          .firstWhere((line) => line.contains("EXCLUDE='"));
      expect(excludeLine, isNot(contains('kling_checkout_client_test.dart')));
      expect(
        workflow,
        isNot(contains(RegExp(r'^\s+exit 0\s*$', multiLine: true))),
      );
    });
  });

  group('widgets', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('billing card shows demo-gated subscribe and portal actions',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: KlingBillingCard(
                companyId: 'demo_company_utilif',
                customerEmail: 'admin@store.com',
                customerName: 'Store Admin',
              ),
            ),
          ),
        ),
      );

      expect(find.text('Subscribe with Kling'), findsOneWidget);
      expect(find.text('Manage billing'), findsOneWidget);
      expect(find.textContaining('Demo mode'), findsOneWidget);
      expect(find.bySemanticsLabel(AppSemantics.klingBilling), findsWidgets);
      expect(find.bySemanticsLabel(AppSemantics.klingSubscribe), findsWidgets);
    });

    testWidgets('demo overlay pay is marked demo and paid', (tester) async {
      KlingEmbedResult? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await showDialog<KlingEmbedResult>(
                  context: context,
                  builder: (_) => const KlingDemoCheckoutDialog(),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel(AppSemantics.klingCheckoutOverlay),
          findsWidgets);
      await tester.tap(find.text('Pay with card'));
      await tester.pumpAndSettle();
      expect(result?.demo, isTrue);
      expect(result?.paid, isTrue);
      expect(result?.canceled, isFalse);
    });

    testWidgets('subscribe then portal stay on the demo path', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: KlingBillingCard(
                companyId: 'demo_company_utilif',
                customerEmail: 'admin@store.com',
                customerName: 'Store Admin',
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Subscribe with Kling'));
      await tester.pumpAndSettle();
      expect(find.text('Pay with card'), findsOneWidget);
      await tester.tap(find.text('Pay with card'));
      await tester.pumpAndSettle();
      expect(find.textContaining('No live charge'), findsOneWidget);

      await tester.tap(find.text('Manage billing'));
      await tester.pumpAndSettle();
      expect(find.textContaining('No live Kling portal'), findsOneWidget);

      final customerId =
          await KlingService.storedCustomerId('demo_company_utilif');
      expect(customerId, isNotNull);
    });

    testWidgets('portal without a customer asks to subscribe first',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: KlingBillingCard(
                companyId: 'new_company',
                customerEmail: 'new@store.com',
                customerName: 'New Admin',
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Manage billing'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Subscribe with Kling before opening'),
        findsOneWidget,
      );
    });
  });
}
