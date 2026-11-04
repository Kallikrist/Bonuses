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

List<File> _workflowFiles() {
  final dirs = [
    Directory('.github/workflows'),
    Directory('${Directory.current.path}/.github/workflows'),
  ];
  for (final dir in dirs) {
    if (dir.existsSync()) {
      return dir.listSync().whereType<File>().toList();
    }
  }
  fail('Could not list .github/workflows from ${Directory.current.path}');
}

void main() {
  late String dependabot;
  late String auditWorkflow;
  late String productWorkflow;
  late String auditScript;
  late List<File> workflowFiles;

  setUpAll(() {
    dependabot = _mustRead(['.github/dependabot.yml']);
    auditWorkflow = _mustRead(['.github/workflows/dependency-audit.yml']);
    productWorkflow = _mustRead(['.github/workflows/flutter-tests.yml']);
    auditScript = _mustRead(['scripts/dependency_audit.sh']);
    workflowFiles = _workflowFiles();
  });

  group('Dependabot (BON-17)', () {
    test('weekly pub updates are configured in-repo', () {
      expect(dependabot, contains('version: 2'));
      expect(dependabot, contains('package-ecosystem: "pub"'));
      expect(dependabot, contains('directory: "/"'));
      expect(dependabot, contains('interval: "weekly"'));
      expect(dependabot, contains('day: "monday"'));
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
      expect(auditWorkflow, contains('fail-on-vuln: true'));
      expect(auditWorkflow, contains('upload-sarif: false'));
    });

    test('uses Flutter 3.27.4 stable and read-only contents by default', () {
      expect(auditWorkflow, contains('channel: stable'));
      expect(auditWorkflow, contains("flutter-version: '3.27.4'"));
      expect(
        auditWorkflow,
        contains(RegExp(r'^permissions:\s*$', multiLine: true)),
      );
      expect(auditWorkflow, contains('contents: read'));
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

    test('audit script is tracked as executable', () {
      final result = Process.runSync(
        'git',
        ['ls-files', '-s', 'scripts/dependency_audit.sh'],
      );
      expect(result.exitCode, 0, reason: result.stderr.toString());
      expect(result.stdout.toString(), startsWith('100755'));
    });
  });

  group('CI isolation and secrets (BON-17)', () {
    test('product flutter-tests.yml is not mixed with TestFlight or the audit',
        () {
      final productBody = _withoutCommentLines(productWorkflow).toLowerCase();
      expect(productBody, isNot(contains('testflight')));
      expect(productBody, isNot(contains('fastlane')));
      expect(productWorkflow, isNot(contains('osv-scanner')));
      expect(productWorkflow, isNot(contains('dependabot')));
      expect(productWorkflow, isNot(contains('flutter pub outdated')));
    });

    test('no workflow mixes TestFlight or Fastlane with the audit script', () {
      expect(
        workflowFiles.map((f) => f.uri.pathSegments.last),
        containsAll(['flutter-tests.yml', 'dependency-audit.yml']),
      );
      for (final file in workflowFiles) {
        final name = file.uri.pathSegments.last;
        final body =
            _withoutCommentLines(file.readAsStringSync()).toLowerCase();
        final runsAudit = body.contains('dependency_audit.sh') ||
            body.contains('osv-scanner');
        if (runsAudit) {
          expect(name, 'dependency-audit.yml',
              reason: '$name runs the audit and must stay a dedicated file');
          expect(body, isNot(contains('testflight')));
          expect(body, isNot(contains('fastlane')));
        }
      }
    });

    test('dependency audit contract tests are included in product CI', () {
      final excludeMatch =
          RegExp(r"EXCLUDE='([^']+)'").firstMatch(productWorkflow);
      expect(excludeMatch, isNotNull,
          reason: 'product CI must name exclusions');
      expect(
        excludeMatch!.group(1),
        isNot(contains('dependency_audit')),
        reason: 'test/dependency_audit_workflow_test.dart must run in CI',
      );
    });

    test('BON-17 files do not contain live-looking secrets', () {
      final blob = '$dependabot\n$auditWorkflow\n$auditScript';
      expect(blob, isNot(contains('eyJhbGci')));
      expect(blob, isNot(contains('sk_live_')));
      expect(blob, isNot(contains('sk_test_')));
      expect(blob, isNot(contains('github_pat_')));
      expect(blob, isNot(contains('ghp_')));
      expect(blob, isNot(contains('RENOVATE_TOKEN=')));
    });
  });
}
