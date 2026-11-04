import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
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

String _klingSignature(String rawBody, String secret) {
  final hmac = Hmac(sha256, utf8.encode(secret));
  final digest = hmac.convert(utf8.encode(rawBody));
  return 'sha256=${digest.toString()}';
}

bool _verifyKlingSignature(String rawBody, String? header, String secret) {
  if (header == null || header.isEmpty || secret.isEmpty) return false;
  final expected = _klingSignature(rawBody, secret);
  if (expected.length != header.length) return false;
  var diff = 0;
  for (var i = 0; i < expected.length; i++) {
    diff |= expected.codeUnitAt(i) ^ header.codeUnitAt(i);
  }
  return diff == 0;
}

final _embeddedSecret = RegExp(r'sk_(live|test)_[0-9a-zA-Z]{16,}');

void main() {
  late String handlerSource;
  late String signatureSource;
  late String indexSource;
  late String secretSource;
  late String stripeSource;
  late String configToml;
  late String envExample;
  late String functionEnvExample;
  late String runWithEnv;
  late String workflow;
  late String migration;

  setUpAll(() {
    handlerSource = _mustRead('supabase/functions/_shared/kling_webhook.ts');
    signatureSource =
        _mustRead('supabase/functions/_shared/kling_signature.ts');
    indexSource = _mustRead('supabase/functions/kling-webhook/index.ts');
    secretSource = _mustRead('supabase/functions/kling-secret/index.ts');
    stripeSource = _mustRead('supabase/functions/stripe-secret/index.ts');
    configToml = _mustRead('supabase/config.toml');
    envExample = _mustRead('env.example');
    functionEnvExample = _mustRead('supabase/functions/.env.example');
    runWithEnv = _mustRead('scripts/run_with_env.sh');
    workflow = _mustRead('.github/workflows/flutter-tests.yml');
    migration = _mustRead('supabase/migrations/20261104233000_kling_webhook.sql');
  });

  group('X-Kling-Signature verify', () {
    const secret = 'test_kling_webhook_signing_secret';
    const raw =
        '{"id":"5b0c6f0e-2d7a-4f43-9a51-3f0b8f6c1e2d","type":"subscription.activated","data":{"id":"9d2e4b7a-1c3f-4e8a-b6d5-0a7f2c9e4b11"},"environment":"test"}';

    test('accepts sha256= HMAC-SHA256 of the raw body', () {
      final header = _klingSignature(raw, secret);
      expect(header, startsWith('sha256='));
      expect(header.length, 7 + 64);
      expect(_verifyKlingSignature(raw, header, secret), isTrue);
    });

    test('rejects missing, wrong, or body-tampered signatures', () {
      final header = _klingSignature(raw, secret);
      expect(_verifyKlingSignature(raw, null, secret), isFalse);
      expect(_verifyKlingSignature(raw, '', secret), isFalse);
      expect(_verifyKlingSignature(raw, header, 'other'), isFalse);
      expect(_verifyKlingSignature('$raw ', header, secret), isFalse);
      expect(
        _verifyKlingSignature(raw, '${header.substring(0, header.length - 1)}0',
            secret),
        isFalse,
      );
    });
  });

  group('kling-webhook Edge Function (BON-41)', () {
    test('reads KLING_WEBHOOK_SECRET from Deno env only', () {
      expect(indexSource, contains('Deno.env.get("KLING_WEBHOOK_SECRET")'));
      expect(indexSource, contains('configured: Boolean(secret)'));
      expect(indexSource, contains('x-kling-signature'));
      expect(indexSource, contains('Invalid signature'));
      expect(signatureSource, contains('sha256='));
      expect(signatureSource, contains('HMAC'));
      expect(signatureSource, contains('SHA-256'));
      expect(_embeddedSecret.hasMatch(indexSource), isFalse);
      expect(_embeddedSecret.hasMatch(signatureSource), isFalse);
      expect(_embeddedSecret.hasMatch(handlerSource), isFalse);
    });

    test('handles the four required events and checks cancel status', () {
      expect(handlerSource, contains('subscription.activated'));
      expect(handlerSource, contains('payment_intent.captured'));
      expect(handlerSource, contains('subscription.renewed'));
      expect(handlerSource, contains('subscription.canceled'));
      expect(handlerSource, contains('card verification (amount 0)'));
      expect(handlerSource, contains('not a subscription charge'));
      expect(handlerSource, contains('canceled event missing status'));
      expect(handlerSource, contains('accessRevoked: true'));
      expect(handlerSource, contains('accessRevoked: false'));
      expect(handlerSource, contains('cancel_at_period_end'));
      expect(handlerSource, contains('test-mode only'));
      expect(handlerSource, isNot(contains('* 100')));
      expect(handlerSource, isNot(contains('*100')));
      expect(handlerSource, contains('Never multiply by 100'));
    });

    test('is idempotent on event id and payment intent id', () {
      expect(handlerSource, contains('alreadyProcessedEventId'));
      expect(handlerSource, contains('alreadyCapturedPaymentIntentId'));
      expect(handlerSource, contains('reason: "event_id"'));
      expect(handlerSource, contains('reason: "payment_intent"'));
      expect(indexSource, contains('kling_webhook_events'));
      expect(indexSource, contains('duplicate: true'));
      expect(migration, contains('kling_webhook_events'));
      expect(migration, contains('kling_subscriptions'));
      expect(migration, contains('ENABLE ROW LEVEL SECURITY'));
      expect(migration, contains('REVOKE ALL'));
      expect(migration, contains('amount_isk'));
      expect(migration, isNot(contains('DROP TABLE')));
    });

    test('config.toml registers kling-webhook with verify_jwt false', () {
      expect(configToml, contains('[functions.kling-webhook]'));
      expect(configToml, contains('./functions/kling-webhook/index.ts'));
      expect(configToml, contains('[functions.kling-secret]'));
      expect(configToml, contains('[functions.stripe-secret]'));
      expect(configToml, contains('verify_jwt = false'));
    });

    test('function env example is a placeholder, not an embedded secret', () {
      expect(functionEnvExample, contains('KLING_WEBHOOK_SECRET='));
      expect(
        functionEnvExample,
        contains('your_kling_webhook_signing_secret_here'),
      );
      expect(_embeddedSecret.hasMatch(functionEnvExample), isFalse);
    });

    test('app env templates never dart-define Kling webhook or secret keys', () {
      expect(
        envExample,
        contains('Do NOT put KLING_SECRET_KEY or KLING_WEBHOOK_SECRET'),
      );
      expect(envExample, isNot(contains('\nKLING_WEBHOOK_SECRET=')));
      expect(envExample, isNot(contains('\nKLING_SECRET_KEY=')));
      expect(runWithEnv, isNot(contains('--dart-define=KLING_WEBHOOK_SECRET')));
      expect(runWithEnv, isNot(contains('--dart-define=KLING_SECRET_KEY')));
      expect(runWithEnv, contains('KLING_WEBHOOK_SECRET'));
    });

    test('this file is not a named CI exclusion', () {
      final excludeLine = workflow
          .split('\n')
          .firstWhere((line) => line.contains("EXCLUDE='"));
      expect(excludeLine, isNot(contains('kling_webhook_handling_test.dart')));
      expect(
        workflow,
        isNot(contains(RegExp(r'^\s+exit 0\s*$', multiLine: true))),
      );
    });

    test('does not change kling-secret actions or Stripe; Flutter does not invoke webhook',
        () {
      expect(secretSource, contains('createCheckoutSession'));
      expect(secretSource, contains('createBillingPortalSession'));
      expect(secretSource, isNot(contains('KLING_WEBHOOK_SECRET')));
      expect(secretSource, isNot(contains('X-Kling-Signature')));
      expect(secretSource, isNot(contains('kling-webhook')));
      expect(stripeSource, contains('Deno.env.get("STRIPE_SECRET_KEY")'));
      expect(stripeSource, contains('Math.round(amount * 100)'));
      expect(stripeSource, isNot(contains('KLING_WEBHOOK_SECRET')));

      final dartFiles = Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'))
          .toList();
      expect(dartFiles, isNotEmpty);
      for (final file in dartFiles) {
        final text = file.readAsStringSync();
        expect(text, isNot(contains("invoke('kling-webhook')")),
            reason: file.path);
        expect(text, isNot(contains("_functionName = 'kling-webhook'")),
            reason: file.path);
        expect(
          text,
          isNot(contains("fromEnvironment('KLING_WEBHOOK_SECRET'")),
          reason: file.path,
        );
        expect(
          text,
          isNot(contains('--dart-define=KLING_WEBHOOK_SECRET')),
          reason: file.path,
        );
      }
    });
  });

  group('shared handler unit tests (node)', () {
    test('signature verify, idempotency, and event handling', () async {
      final result = await Process.run(
        'node',
        [
          '--experimental-strip-types',
          'supabase/functions/_shared/kling_webhook_test.ts',
        ],
        workingDirectory: Directory.current.path,
      );
      expect(
        result.exitCode,
        0,
        reason: 'stdout:\n${result.stdout}\nstderr:\n${result.stderr}',
      );
      expect(result.stdout.toString(), contains('kling_webhook_test.ts ok'));
    });
  });
}
