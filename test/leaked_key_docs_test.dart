import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final repoRoot = Directory.current;

  group('Leaked-key documentation (BON-6)', () {
    test('exposure and rotate-key runbooks are not in the tree', () {
      for (final name in [
        'URGENT_KEY_EXPOSURE.md',
        'HOW_TO_IDENTIFY_KEY.md',
        'SECURITY_AUDIT_REPORT.md',
        'FIX_ENV_IN_GIT.md',
      ]) {
        expect(
          File('${repoRoot.path}/$name').existsSync(),
          isFalse,
          reason: '$name should not be present',
        );
      }
    });

    test('tracked markdown has no leaked project slug or JWT fragment', () {
      // Split so a naive repo grep for the contiguous identifiers stays clean.
      final leakedSlug = ['hkpkznslz', 'kgnijoahgn'].join();
      final leakedFragment = ['TbqbkOi5', 'ZL0czgmc'].join();
      final jwtHeader = ['eyJ', 'hbGci'].join();

      final listed = Process.runSync(
        'git',
        ['ls-files', '*.md'],
        workingDirectory: repoRoot.path,
      );
      expect(listed.exitCode, 0, reason: listed.stderr.toString());

      final mdPaths = listed.stdout
          .toString()
          .split('\n')
          .map((line) => line.trim())
          .where((line) => line.endsWith('.md'))
          .toList();
      expect(mdPaths, isNotEmpty);

      for (final relative in mdPaths) {
        final text = File('${repoRoot.path}/$relative').readAsStringSync();
        expect(
          text.contains(leakedSlug),
          isFalse,
          reason: '$relative contains leaked project slug',
        );
        expect(
          text.contains(leakedFragment),
          isFalse,
          reason: '$relative contains leaked key fragment',
        );

        // JWT header prefix is only allowed as a generic grep example.
        if (text.contains(jwtHeader)) {
          expect(
            relative,
            'SECURITY_CHECKLIST.md',
            reason: '$relative contains JWT header prefix',
          );
        }
      }
    });

    test('credential note remains: env.example + dart-define, never commit .env',
        () {
      final setup =
          File('${repoRoot.path}/SETUP_ENVIRONMENT_VARIABLES.md')
              .readAsStringSync();
      expect(setup, contains('env.example'));
      expect(setup, contains('--dart-define'));
      expect(setup, contains('Never commit actual credentials'));
    });
  });
}
