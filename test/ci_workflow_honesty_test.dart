import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String workflow;

  setUpAll(() {
    final candidates = [
      File('.github/workflows/flutter-tests.yml'),
      File('${Directory.current.path}/.github/workflows/flutter-tests.yml'),
    ];
    for (final file in candidates) {
      if (file.existsSync()) {
        workflow = file.readAsStringSync();
        return;
      }
    }
    fail(
        'Could not read .github/workflows/flutter-tests.yml from ${Directory.current.path}');
  });

  group('Honest CI workflow (BON-4)', () {
    test('product test step has no trailing exit 0', () {
      expect(
        workflow,
        isNot(contains(RegExp(r'^\s+exit 0\s*$', multiLine: true))),
        reason: 'CI must not swallow flutter test with a trailing exit 0',
      );
      expect(
        workflow,
        isNot(contains(RegExp(r'flutter test.*\|\|'))),
        reason: 'flutter test must not be followed by || echo / || true',
      );
    });

    test('analyze job fails on errors, not warnings', () {
      expect(workflow,
          contains('flutter analyze --no-fatal-warnings --no-fatal-infos'));
      expect(workflow, contains('name: Analyze'));
    });

    test('Cursor API smoke test is not in the workflow', () {
      expect(workflow, isNot(contains('CURSOR_API_KEY')));
      expect(workflow, isNot(contains('cursor_api_key_smoke')));
    });

    test('named test exclusions are listed in the product test step', () {
      const excluded = [
        'payment_system_test.dart',
        'environment_config_test.dart',
        'widget_test.dart',
        'ui_state_management_test.dart',
        'employee_profile_access_test.dart',
        'auth_service_test.dart',
      ];
      expect(workflow, contains('EXCLUDE='));
      for (final name in excluded) {
        expect(workflow, contains(name),
            reason: '$name must be a named exclusion');
      }
    });

    test('ignore-3-payment-tests TODO is gone', () {
      expect(
        workflow.toLowerCase(),
        isNot(contains('ignore 3 failing')),
      );
    });
  });
}
