import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String _mustRead(List<String> relativePaths) {
  for (final relative in relativePaths) {
    final candidates = [
      File(relative),
      File('${Directory.current.path}/$relative'),
    ];
    for (final file in candidates) {
      if (file.existsSync()) {
        return file.readAsStringSync();
      }
    }
  }
  fail(
    'Could not read ${relativePaths.join(" or ")} from ${Directory.current.path}',
  );
}

/// YAML/shell with `# ...` comment lines removed so prose cannot trip assertions.
String _withoutCommentLines(String source) {
  return source
      .split('\n')
      .where((line) => !line.trimLeft().startsWith('#'))
      .join('\n');
}

void main() {
  late String dependabot;
  late String auditWorkflow;
  late String productWorkflow;
  late String auditScript;

  setUpAll(() {
    dependabot = _mustRead(['.github/dependabot.yml']);
    auditWorkflow = _mustRead(['.github/workflows/dependency-audit.yml']);
    productWorkflow = _mustRead(['.github/workflows/flutter-tests.yml']);
    auditScript = _mustRead(['scripts/dependency_audit.sh']);
  });

  group('Dependabot (BON-17)', () {
    test('weekly pub updates are configured in-repo', () {
      expect(dependabot, contains('version: 2'));
      expect(dependabot, contains('package-ecosystem: "pub"'));
      expect(dependabot, contains('directory: "/"'));
      expect(dependabot, contains('interval: "weekly"'));
    });

    test('also updates GitHub Actions on the same weekly cadence', () {
      expect(dependabot, contains('package-ecosystem: "github-actions"'));
    });

    test('does not store registry tokens or other secrets', () {
      final body = _withoutCommentLines(dependabot);
      expect(body, isNot(contains('registries:')));
      expect(body, isNot(contains(RegExp(r'secrets\.'))));
      expect(body, isNot(contains('token:')));
      expect(body, isNot(contains(r'${{')));
    });
  });

  group('Weekly dependency audit workflow (BON-17)', () {
    test('is a scheduled job, not TestFlight or product-test CI', () {
      final auditBody = _withoutCommentLines(auditWorkflow).toLowerCase();
      expect(auditWorkflow, contains("cron: '0 6 * * 1'"));
      expect(auditWorkflow, contains('workflow_dispatch'));
      expect(auditBody, isNot(contains('testflight')));
      expect(auditBody, isNot(contains('fastlane')));
      expect(auditBody, isNot(contains('flutter test')));
      expect(productWorkflow, isNot(contains('schedule:')));
      expect(productWorkflow, isNot(contains('dependency_audit')));
    });

    test('runs flutter pub outdated and an advisory scan', () {
      expect(auditWorkflow, contains('./scripts/dependency_audit.sh'));
      expect(auditScript, contains('flutter pub outdated'));
      expect(
        auditScript,
        anyOf(
          contains('dart pub audit'),
          contains('affected by security advisories'),
        ),
      );
      expect(auditWorkflow, contains('osv-scanner'));
      expect(auditWorkflow, contains('--lockfile=pubspec.lock'));
    });

    test('does not swallow failures or check in secrets', () {
      final auditBody = _withoutCommentLines(auditWorkflow);
      final scriptBody = _withoutCommentLines(auditScript);
      expect(
        auditBody,
        isNot(contains(RegExp(r'^\s+exit 0\s*$', multiLine: true))),
      );
      expect(
        scriptBody,
        isNot(contains(RegExp(r'^\s+exit 0\s*$', multiLine: true))),
      );
      expect(auditBody, isNot(contains(r'${{ secrets')));
      expect(auditBody, isNot(contains('STRIPE_SECRET')));
      expect(auditBody, isNot(contains('SUPABASE_ANON_KEY')));
      expect(scriptBody, isNot(contains(r'${{ secrets')));
    });
  });
}
