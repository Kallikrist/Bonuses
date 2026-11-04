import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

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
  late String functionSource;
  late String stripeFunctionSource;
  late String configToml;
  late String envExample;
  late String functionEnvExample;
  late String runWithEnv;
  late String workflow;

  setUpAll(() {
    functionSource = _mustRead('supabase/functions/kling-secret/index.ts');
    stripeFunctionSource =
        _mustRead('supabase/functions/stripe-secret/index.ts');
    configToml = _mustRead('supabase/config.toml');
    envExample = _mustRead('env.example');
    functionEnvExample = _mustRead('supabase/functions/.env.example');
    runWithEnv = _mustRead('scripts/run_with_env.sh');
    workflow = _mustRead('.github/workflows/flutter-tests.yml');
  });

  group('kling-secret Edge Function (BON-40)', () {
    test('reads KLING_SECRET_KEY from Deno env only', () {
      expect(functionSource, contains('Deno.env.get("KLING_SECRET_KEY")'));
      expect(functionSource, contains('configured: Boolean(secret)'));
      expect(functionSource, contains('https://api.kling.is/v1'));
      expect(_embeddedSecret.hasMatch(functionSource), isFalse);
    });

    test('allowlists Path A actions and forces card-only ISK checkout', () {
      expect(functionSource, contains('createCheckoutSession'));
      expect(functionSource, contains('getCheckoutSession'));
      expect(functionSource, contains('createBillingPortalSession'));
      expect(functionSource, contains('createCustomer'));
      expect(functionSource, contains('createSubscription'));
      expect(functionSource, contains('getSubscription'));
      expect(functionSource, contains('cancelSubscription'));
      expect(functionSource, contains('reactivateSubscription'));
      expect(functionSource, contains('payment_method_type: CARD_ONLY'));
      expect(functionSource, contains('collection_method: CARD_ONLY'));
      expect(functionSource, contains('const CARD_ONLY = "card"'));
      expect(functionSource, contains('const ISK = "ISK"'));
      expect(functionSource, contains('currency: ISK'));
      expect(functionSource, contains('only card is supported'));
      expect(functionSource, isNot(contains('payment_method_type: "bank_claim"')));
      expect(functionSource, isNot(contains('collection_method: "bank_claim"')));
    });

    test('does not multiply ISK amounts by 100', () {
      expect(functionSource, isNot(contains('* 100')));
      expect(functionSource, isNot(contains('*100')));
      expect(functionSource, isNot(contains('Math.round')));
      expect(
        functionSource,
        contains('Never multiply by 100.'),
      );
    });

    test('refuses live keys and does not implement the webhook handler', () {
      expect(functionSource, contains('must be a test-mode key'));
      expect(functionSource, contains('startsWith("sk_test_")'));
      expect(functionSource, contains('startsWith("sk_live_")'));
      expect(functionSource, isNot(contains('KLING_WEBHOOK_SECRET')));
      expect(functionSource, isNot(contains('X-Kling-Signature')));
      expect(functionSource, isNot(contains('notification-channels')));
    });

    test('config.toml registers kling-secret with verify_jwt false', () {
      expect(configToml, contains('[functions.kling-secret]'));
      expect(configToml, contains('./functions/kling-secret/index.ts'));
      expect(configToml, contains('[functions.stripe-secret]'));
      expect(configToml, contains('verify_jwt = false'));
    });

    test('function env example is a placeholder, not an embedded secret', () {
      expect(functionEnvExample, contains('KLING_SECRET_KEY='));
      expect(functionEnvExample, contains('sk_test_your_kling_secret_key_here'));
      expect(functionEnvExample, contains('STRIPE_SECRET_KEY='));
      expect(_embeddedSecret.hasMatch(functionEnvExample), isFalse);
    });

    test('app env templates never dart-define KLING_SECRET_KEY', () {
      expect(envExample, contains('Do NOT put KLING_SECRET_KEY'));
      expect(envExample, isNot(contains('\nKLING_SECRET_KEY=')));
      expect(runWithEnv, isNot(contains('--dart-define=KLING_SECRET_KEY')));
      expect(runWithEnv, contains('KLING_SECRET_KEY'));
    });

    test('this file is not a named CI exclusion', () {
      final excludeLine = workflow
          .split('\n')
          .firstWhere((line) => line.contains("EXCLUDE='"));
      expect(excludeLine, isNot(contains('kling_secret_handling_test.dart')));
      expect(
        workflow,
        isNot(contains(RegExp(r'^\s+exit 0\s*$', multiLine: true))),
      );
    });

    test('does not change stripe-secret or add a Flutter Kling client', () {
      expect(
        stripeFunctionSource,
        contains('Deno.env.get("STRIPE_SECRET_KEY")'),
      );
      expect(stripeFunctionSource, isNot(contains('KLING_SECRET_KEY')));
      expect(stripeFunctionSource, contains('Math.round(amount * 100)'));

      final dartFiles = Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'))
          .toList();
      expect(dartFiles, isNotEmpty);
      for (final file in dartFiles) {
        final text = file.readAsStringSync();
        expect(text, isNot(contains('kling-secret')), reason: file.path);
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
          isNot(contains('--dart-define=KLING_SECRET_KEY')),
          reason: file.path,
        );
      }
    });
  });
}
