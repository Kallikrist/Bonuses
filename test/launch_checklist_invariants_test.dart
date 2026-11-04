import 'dart:io';

import 'package:bonuses/config/app_config.dart';
import 'package:flutter_test/flutter_test.dart';

/// Canonical login-box emails from README / login / seed. The launch
/// checklist must list the same set, not a fourth copy.
const loginScreenEmails = [
  'admin@store.com',
  'admin@utilif.com',
  'john.doe@example.com',
  'superadmin@platform.com',
];

const additionalSeededEmails = [
  'jane.smith@example.com',
  'mike.johnson@example.com',
  'Karl@Utilif.is',
  'kallikrist@test.is',
];

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

String _methodBody(String source, String signature) {
  final start = source.indexOf(signature);
  expect(start, greaterThanOrEqualTo(0), reason: 'missing $signature');
  final next = source.indexOf('\n  static ', start + signature.length);
  expect(next, greaterThan(start), reason: 'could not bound $signature');
  return source.substring(start, next);
}

void main() {
  late String checklist;
  late String stripeSource;
  late String authSource;
  late String pubspec;
  late String configToml;
  late String gradle;
  late String mainManifest;
  late String debugManifest;
  late String profileManifest;
  late String functionSource;
  late String loginSource;

  setUpAll(() {
    checklist = _readRepoFile('LAUNCH_CHECKLIST.md');
    stripeSource = _readRepoFile('lib/services/stripe_service.dart');
    authSource = _readRepoFile('lib/services/auth_service.dart');
    pubspec = _readRepoFile('pubspec.yaml');
    configToml = _readRepoFile('supabase/config.toml');
    gradle = _readRepoFile('android/app/build.gradle');
    mainManifest = _readRepoFile('android/app/src/main/AndroidManifest.xml');
    debugManifest = _readRepoFile('android/app/src/debug/AndroidManifest.xml');
    profileManifest =
        _readRepoFile('android/app/src/profile/AndroidManifest.xml');
    functionSource =
        _readRepoFile('supabase/functions/stripe-secret/index.ts');
    loginSource = _readRepoFile('lib/screens/login_screen.dart');
  });

  group('Launch checklist document', () {
    test('exists and is pinned as a living launch list', () {
      expect(checklist.trim(), isNotEmpty);
      expect(checklist, contains('# Launch checklist'));
      expect(checklist, contains('Do not enable live Stripe'));
      expect(checklist, contains('DEMO_MODE'));
    });

    test('lists the canonical demo accounts', () {
      for (final email in [...loginScreenEmails, ...additionalSeededEmails]) {
        expect(checklist, contains(email),
            reason: 'LAUNCH_CHECKLIST.md should list $email');
      }
      expect(checklist, contains('password123'));
      expect(checklist, contains('utilif123'));
      expect(checklist, contains('demo123'));
    });
  });

  group('Mock Stripe default (no live payments)', () {
    test('AppConfig defaults keep Stripe on the mock path', () {
      expect(AppConfig.demoMode, isTrue);
      expect(AppConfig.isSupabaseConfigured, isFalse);
      expect(AppConfig.useMockStripe, isTrue);
      expect(AppConfig.stripePublishableKey, isEmpty);
    });

    test('processPayment and Apple Pay always simulate', () {
      final processPayment = _methodBody(
        stripeSource,
        'static Future<Map<String, dynamic>> processPayment({',
      );
      final appleIntent = _methodBody(
        stripeSource,
        'static Future<Map<String, dynamic>> createApplePayPaymentIntent({',
      );
      final applePay = _methodBody(
        stripeSource,
        'static Future<Map<String, dynamic>> processApplePayPayment({',
      );
      expect(processPayment, isNot(contains('useMockStripe')));
      expect(processPayment, isNot(contains('_invokeSecretAction')));
      expect(appleIntent, isNot(contains('useMockStripe')));
      expect(appleIntent, isNot(contains('_invokeSecretAction')));
      expect(applePay, isNot(contains('useMockStripe')));
      expect(applePay, isNot(contains('_invokeSecretAction')));
    });

    test('secret-key calls go through stripe-secret when mock is off', () {
      expect(stripeSource, contains("_functionName = 'stripe-secret'"));
      expect(stripeSource, contains('_invokeSecretAction'));
      expect(functionSource, contains('Deno.env.get("STRIPE_SECRET_KEY")'));
      expect(functionSource.toLowerCase(), isNot(contains('getuser')));
    });
  });

  group('Auth is still local', () {
    test('login uses StorageService and prints the local-auth debug line', () {
      expect(authSource, contains('Using local storage authentication'));
      expect(authSource, contains('StorageService.getPassword'));
      expect(authSource, isNot(contains('supabase_service')));
      expect(authSource, isNot(contains('signInWithPassword')));
    });

    test('login screen always shows demo chrome (not gated)', () {
      expect(loginSource, contains('Demo Accounts:'));
      expect(loginSource, contains('Reset Demo Data'));
      expect(loginSource, contains('Test Supabase Integration'));
      expect(loginSource, contains('Debug Users'));
      final demoBox = loginSource.substring(
        loginSource.indexOf('Demo Accounts:'),
        loginSource.indexOf('Reset Demo Data'),
      );
      expect(demoBox, isNot(contains('kDebugMode')));
      expect(demoBox, isNot(contains('kReleaseMode')));
      expect(demoBox, isNot(contains('demoMode')));
    });
  });

  group('Crash reporting and privacy still absent', () {
    test('pubspec has no crash-reporting package', () {
      expect(
        pubspec,
        isNot(contains(RegExp(
          r'^\s+(sentry|sentry_flutter|firebase_crashlytics|firebase_core)\s*:',
          multiLine: true,
        ))),
      );
    });

    test('no PRIVACY.md or LICENSE in the tree', () {
      expect(File('PRIVACY.md').existsSync(), isFalse);
      expect(File('LICENSE').existsSync(), isFalse);
    });
  });

  group('Store identifiers and Android release gaps', () {
    test('stripe-secret JWT gate is still off', () {
      expect(configToml, contains('[functions.stripe-secret]'));
      expect(configToml, contains('verify_jwt = false'));
    });

    test('Android still uses debug signing and default applicationId', () {
      expect(gradle, contains('applicationId = "com.bonuses.app.bonuses"'));
      expect(gradle, contains('signingConfig = signingConfigs.debug'));
      expect(gradle, contains('minSdk = 23'));
      expect(gradle, contains('compileSdk = 35'));
    });

    test('INTERNET is only on debug/profile manifests', () {
      expect(mainManifest, isNot(contains('android.permission.INTERNET')));
      expect(debugManifest, contains('android.permission.INTERNET'));
      expect(profileManifest, contains('android.permission.INTERNET'));
    });
  });
}
