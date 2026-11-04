import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:bonuses/config/app_config.dart';
import 'package:bonuses/services/stripe_service.dart';

void main() {
  group('Stripe secret handling', () {
    test('default test run uses the mock Stripe path', () {
      expect(AppConfig.demoMode, isTrue);
      expect(AppConfig.isSupabaseConfigured, isFalse);
      expect(AppConfig.useMockStripe, isTrue);
      expect(AppConfig.stripePublishableKey, isEmpty);
    });

    test('createPaymentIntent stays mock without calling Stripe', () async {
      final intent = await StripeService.createPaymentIntent(
        companyId: 'co_1',
        amount: 1,
        currency: 'USD',
        description: 'test',
      );
      expect(intent['id'], startsWith('pi_mock_'));
      expect(intent['client_secret'], contains('secret_mock'));
      expect(intent['amount'], 100);
    });

    test('createCustomer stays mock without a Stripe secret', () async {
      final customer = await StripeService.createCustomer(
        email: 'demo@example.com',
        name: 'Demo',
      );
      expect(customer['id'], startsWith('cus_mock_'));
      expect(customer['email'], 'demo@example.com');
    });

    test('createSubscription stays mock without calling Stripe', () async {
      final subscription = await StripeService.createSubscription(
        customerId: 'cus_mock_1',
        priceId: 'price_1',
        paymentMethodId: 'pm_1',
      );
      expect(subscription['id'], startsWith('sub_mock_'));
      expect(subscription['customer'], 'cus_mock_1');
      expect(subscription['status'], 'active');
    });

    test('getPaymentMethods stays mock without calling Stripe', () async {
      final methods =
          await StripeService.getPaymentMethods(customerId: 'cus_mock_1');
      expect(methods, isEmpty);
    });

    test('cancelSubscription stays mock without calling Stripe', () async {
      final result = await StripeService.cancelSubscription(
        subscriptionId: 'sub_mock_1',
      );
      expect(result['id'], 'sub_mock_1');
      expect(result['status'], 'canceled');
    });

    test('processPayment stays on the mock card path', () async {
      final result = await StripeService.processPayment(
        paymentIntentId: 'pi_mock_1',
        cardNumber: '4242424242424242',
        expiryMonth: '12',
        expiryYear: '2030',
        cvc: '123',
        cardholderName: 'Demo',
      );
      expect(result['success'], isTrue);
      expect(result['payment_intent'], isA<Map>());
      expect(result['payment_intent']['id'], 'pi_mock_1');
      expect(result['payment_intent']['status'], 'succeeded');
      expect(result['payment_method']['id'], startsWith('pm_mock_'));
    });

    test('app Dart sources do not hold a Stripe secret key', () {
      const paths = [
        'lib/config/app_config.dart',
        'lib/services/stripe_service.dart',
        'lib/services/payment_service.dart',
        'env.example',
        'scripts/run_with_env.sh',
      ];
      for (final path in paths) {
        final text = File(path).readAsStringSync();
        expect(text, isNot(contains('stripeSecretKey')), reason: path);
        expect(text, isNot(contains('STRIPE_SECRET_KEY=')), reason: path);
        expect(
          text,
          isNot(contains("Authorization': 'Bearer \$_secretKey")),
          reason: path,
        );
        expect(
          text,
          isNot(contains("fromEnvironment('STRIPE_SECRET_KEY'")),
          reason: path,
        );
        expect(
          text,
          isNot(contains('fromEnvironment("STRIPE_SECRET_KEY"')),
          reason: path,
        );
        expect(
          text,
          isNot(contains('--dart-define=STRIPE_SECRET_KEY')),
          reason: path,
        );
      }
    });

    test('no lib Dart file dart-defines or fromEnvironment a Stripe secret', () {
      final dartFiles = Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'))
          .toList();
      expect(dartFiles, isNotEmpty);
      for (final file in dartFiles) {
        final text = file.readAsStringSync();
        expect(text, isNot(contains('stripeSecretKey')), reason: file.path);
        expect(
          text,
          isNot(contains("fromEnvironment('STRIPE_SECRET_KEY'")),
          reason: file.path,
        );
        expect(
          text,
          isNot(contains('fromEnvironment("STRIPE_SECRET_KEY"')),
          reason: file.path,
        );
        expect(
          text,
          isNot(contains('--dart-define=STRIPE_SECRET_KEY')),
          reason: file.path,
        );
      }
    });

    test('env.example keeps the publishable key and rejects a secret dart-define', () {
      final text = File('env.example').readAsStringSync();
      expect(text, contains('STRIPE_PUBLISHABLE_KEY='));
      expect(text, contains('Do NOT put STRIPE_SECRET_KEY'));
      expect(text, isNot(contains('\nSTRIPE_SECRET_KEY=')));
    });

    test('run_with_env.sh never passes STRIPE_SECRET_KEY as a dart-define', () {
      final text = File('scripts/run_with_env.sh').readAsStringSync();
      expect(text, contains('--dart-define=STRIPE_PUBLISHABLE_KEY='));
      expect(text, isNot(contains('--dart-define=STRIPE_SECRET_KEY')));
    });

    test('Edge Function reads STRIPE_SECRET_KEY from Deno env', () {
      final text =
          File('supabase/functions/stripe-secret/index.ts').readAsStringSync();
      expect(text, contains('Deno.env.get("STRIPE_SECRET_KEY")'));
      expect(text, contains('createPaymentIntent'));
      expect(text, contains('configured: Boolean(secret)'));
      expect(text, isNot(contains('sk_live_')));
      expect(text, isNot(contains('sk_test_')));
      expect(
        RegExp(r'sk_(live|test)_[0-9a-zA-Z]{16,}').hasMatch(text),
        isFalse,
      );
    });

    test('Edge Function requires a Supabase Auth user and rate-limits', () {
      final text =
          File('supabase/functions/stripe-secret/index.ts').readAsStringSync();
      expect(text, contains('auth.getUser'));
      expect(text, contains('Unauthorized'));
      expect(text, contains('Too many requests'));
      expect(text, contains('RATE_LIMIT_MAX'));
      expect(text, contains('MAX_AMOUNT_DOLLARS'));
      expect(text, contains('ALLOWED_CURRENCIES'));
      expect(text, contains('user.is_anonymous'));
      expect(text, isNot(contains('verify_jwt = false')));
    });

    test('config.toml enables JWT verification on stripe-secret', () {
      final text = File('supabase/config.toml').readAsStringSync();
      expect(text, contains('verify_jwt = true'));
      expect(text, isNot(contains('verify_jwt = false')));
    });

    test('AuthService uses Supabase Auth when the client is ready', () {
      final auth = File('lib/services/auth_service.dart').readAsStringSync();
      final supabase =
          File('lib/services/supabase_service.dart').readAsStringSync();
      expect(auth, contains('SupabaseService.signIn'));
      expect(auth, contains('_loginWithSupabaseAuth'));
      expect(auth, contains('_loginLocal'));
      expect(auth, contains('usesSupabaseAuth'));
      expect(supabase, contains('signInWithPassword'));
    });

    test('function env example is a placeholder, not an embedded secret', () {
      final text = File('supabase/functions/.env.example').readAsStringSync();
      expect(text, contains('STRIPE_SECRET_KEY='));
      expect(text, contains('sk_test_your_stripe_secret_key_here'));
      expect(
        RegExp(r'sk_(live|test)_[0-9a-zA-Z]{16,}').hasMatch(text),
        isFalse,
      );
    });
  });
}
