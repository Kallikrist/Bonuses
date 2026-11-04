import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

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
  late String workflow;
  late String dartDefines;
  late String gitignore;
  late String iosGitignore;
  late String infoPlist;
  late String pubspec;
  late String gradle;

  setUpAll(() {
    workflow = _readRepoFile('.github/workflows/distribute.yml');
    dartDefines = _readRepoFile('scripts/ci/release_dart_defines.sh');
    gitignore = _readRepoFile('.gitignore');
    iosGitignore = _readRepoFile('ios/.gitignore');
    infoPlist = _readRepoFile('ios/Runner/Info.plist');
    pubspec = _readRepoFile('pubspec.yaml');
    gradle = _readRepoFile('android/app/build.gradle');
  });

  group('Distribute workflow (BON-14)', () {
    test('runs on push to main and workflow_dispatch', () {
      expect(workflow, contains(RegExp(r'^name:\s*Distribute\s*$', multiLine: true)));
      expect(
        workflow,
        contains(RegExp(r'''^on:\s*$
^\s+push:\s*$
^\s+branches:\s*\[main\]\s*$
^\s+workflow_dispatch:\s*$''', multiLine: true)),
      );
      expect(
        workflow,
        isNot(contains(RegExp(r'^\s+pull_request:', multiLine: true))),
        reason: 'Distribute is merge-to-main, not a PR check',
      );
    });

    test('has iOS TestFlight and Android Firebase App Distribution jobs', () {
      expect(workflow, contains('ios-testflight:'));
      expect(workflow, contains('name: iOS TestFlight'));
      expect(workflow, contains('android-firebase:'));
      expect(workflow, contains('name: Android Firebase App Distribution'));
      expect(workflow, contains('flutter build ipa'));
      expect(workflow, contains('xcrun altool --upload-app'));
      expect(workflow, contains('flutter build apk'));
      expect(workflow, contains('firebase appdistribution:distribute'));
    });

    test('fails fast when owner secrets are missing', () {
      expect(workflow, contains('name: Require Apple / signing secrets'));
      expect(workflow, contains('name: Require Android / Firebase secrets'));
      expect(
        workflow,
        contains('::error::Missing GitHub Actions secrets:'),
      );
      for (final secret in [
        'APP_STORE_CONNECT_API_KEY_ID',
        'APP_STORE_CONNECT_ISSUER_ID',
        'APP_STORE_CONNECT_API_KEY_P8_BASE64',
        'IOS_CERTIFICATE_P12_BASE64',
        'IOS_CERTIFICATE_PASSWORD',
        'IOS_PROVISIONING_PROFILE_BASE64',
        'ANDROID_KEYSTORE_BASE64',
        'ANDROID_KEYSTORE_PASSWORD',
        'ANDROID_KEY_ALIAS',
        'ANDROID_KEY_PASSWORD',
        'FIREBASE_ANDROID_APP_ID',
        'FIREBASE_SERVICE_ACCOUNT',
      ]) {
        expect(workflow, contains(secret), reason: 'must require $secret');
      }
    });

    test('does not pass Stripe keys or add a Firebase SDK', () {
      expect(workflow, isNot(contains('--dart-define=STRIPE')));
      expect(workflow, isNot(contains('secrets.STRIPE')));
      expect(workflow, contains('source scripts/ci/release_dart_defines.sh'));
      expect(workflow, contains('DEMO_MODE=true'));
      final jobs = workflow.substring(workflow.indexOf('\njobs:'));
      expect(jobs, isNot(contains('google-services.json')));
      expect(jobs, isNot(contains('firebase_options.dart')));
      expect(workflow, contains('Do not add\n# google-services.json'));
      expect(
        pubspec,
        isNot(contains(RegExp(
          r'^\s+(firebase_core|firebase_analytics|firebase_crashlytics|firebase_app_distribution)\s*:',
          multiLine: true,
        ))),
      );
    });
  });

  group('Release dart-defines stay mock', () {
    test('script hardcodes DEMO_MODE=true and never dart-defines Stripe', () {
      expect(dartDefines, contains('--dart-define=DEMO_MODE=true'));
      expect(dartDefines, contains('--dart-define=DEBUG_MODE=false'));
      expect(dartDefines, contains('Do not add STRIPE_SECRET_KEY'));
      expect(dartDefines, isNot(contains('--dart-define=STRIPE')));
      final arrayStart = dartDefines.indexOf('RELEASE_DART_DEFINES=(');
      expect(arrayStart, greaterThanOrEqualTo(0));
      final array = dartDefines.substring(arrayStart);
      expect(array.toLowerCase(), isNot(contains('stripe')));
    });

    test('sourcing ignores DEMO_MODE=false and Stripe env vars', () {
      final result = Process.runSync(
        'bash',
        [
          '-c',
          r'source scripts/ci/release_dart_defines.sh && '
              r'printf "%s\n" "${RELEASE_DART_DEFINES[@]}"',
        ],
        workingDirectory: Directory.current.path,
        environment: {
          ...Platform.environment,
          'DEMO_MODE': 'false',
          'STRIPE_SECRET_KEY': 'sk_test_should_not_appear',
          'STRIPE_PUBLISHABLE_KEY': 'pk_test_should_not_appear',
          'SUPABASE_URL': 'https://example.supabase.co',
          'SUPABASE_ANON_KEY': 'anon-test-key',
        },
      );
      expect(result.exitCode, 0, reason: result.stderr.toString());
      final lines = result.stdout
          .toString()
          .split('\n')
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList();
      expect(lines, contains('--dart-define=DEMO_MODE=true'));
      expect(lines, contains('--dart-define=DEBUG_MODE=false'));
      expect(lines, contains('--dart-define=SUPABASE_URL=https://example.supabase.co'));
      expect(lines, contains('--dart-define=SUPABASE_ANON_KEY=anon-test-key'));
      expect(lines.join('\n'), isNot(contains('STRIPE')));
      expect(lines, isNot(contains('--dart-define=DEMO_MODE=false')));
    });

    test('script exits if executed instead of sourced', () {
      final result = Process.runSync(
        'bash',
        ['scripts/ci/release_dart_defines.sh'],
        workingDirectory: Directory.current.path,
      );
      expect(result.exitCode, isNot(0));
    });
  });

  group('ExportOptions and signing material stay out of git', () {
    test('python helper writes App Store ExportOptions for the bundle id', () {
      final dir = Directory.systemTemp.createTempSync('bon14-export-');
      final output = File('${dir.path}/ExportOptions.plist');
      addTearDown(() {
        if (dir.existsSync()) {
          dir.deleteSync(recursive: true);
        }
      });
      final result = Process.runSync(
        'python3',
        [
          'scripts/ci/write_ios_export_options.py',
          '--output',
          output.path,
          '--team-id',
          'ABCDE12345',
          '--profile-name',
          'Bonuses App Store',
        ],
        workingDirectory: Directory.current.path,
      );
      expect(result.exitCode, 0, reason: result.stderr.toString());
      final plist = output.readAsStringSync();
      expect(plist, contains('<string>app-store</string>'));
      expect(plist, contains('<string>manual</string>'));
      expect(plist, contains('<string>ABCDE12345</string>'));
      expect(plist, contains('<key>com.bonuses.app.bonuses</key>'));
      expect(plist, contains('<string>Bonuses App Store</string>'));
      expect(plist, isNot(contains('sk_')));
      expect(plist, isNot(contains('BEGIN PRIVATE KEY')));
    });

    test('signing binaries and CI xcconfig are gitignored and untracked', () {
      expect(gitignore, contains('*.p12'));
      expect(gitignore, contains('*.mobileprovision'));
      expect(gitignore, contains('*.jks'));
      expect(gitignore, contains('AuthKey_*.p8'));
      expect(iosGitignore, contains('Flutter/CodeSign.ci.xcconfig'));
      expect(iosGitignore, contains('ExportOptions.plist'));

      final listed = Process.runSync('git', [
        'ls-files',
        '*.p12',
        '*.p8',
        '*.jks',
        '*.keystore',
        '*.mobileprovision',
        'google-services.json',
        'firebase_options.dart',
        'android/key.properties',
        'ios/Flutter/CodeSign.ci.xcconfig',
      ]);
      expect(listed.exitCode, 0, reason: listed.stderr.toString());
      expect(listed.stdout.toString().trim(), isEmpty);
    });

    test('Android release uses env keystore when present', () {
      expect(gradle, contains('ANDROID_KEYSTORE_PATH'));
      expect(gradle, contains('signingConfigs.release'));
      expect(infoPlist, contains('ITSAppUsesNonExemptEncryption'));
      expect(infoPlist, contains('<false/>'));
    });
  });
}
