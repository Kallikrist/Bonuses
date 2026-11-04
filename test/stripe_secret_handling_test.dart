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
      }
    });

    test('env.example keeps the publishable key and rejects a secret dart-define', () {
      final text = File('env.example').readAsStringSync();
      expect(text, contains('STRIPE_PUBLISHABLE_KEY='));
      expect(text, contains('Do NOT put STRIPE_SECRET_KEY'));
      expect(text, isNot(contains('\nSTRIPE_SECRET_KEY=')));
    });

    test('Edge Function reads STRIPE_SECRET_KEY from Deno env', () {
      final text =
          File('supabase/functions/stripe-secret/index.ts').readAsStringSync();
      expect(text, contains('Deno.env.get("STRIPE_SECRET_KEY")'));
      expect(text, contains('createPaymentIntent'));
      expect(text, isNot(contains('sk_live_')));
    });
  });
}
