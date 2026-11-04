import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:bonuses/models/user.dart';
import 'package:bonuses/utils/super_admin_routing.dart';

User _user({
  required UserRole role,
  required String email,
}) {
  return User(
    id: 'u_${role.name}',
    name: 'Test ${role.name}',
    email: email,
    phoneNumber: '',
    role: role,
    createdAt: DateTime.now(),
    companyIds: const [],
    companyNames: const [],
  );
}

String _read(String relativePath) {
  final file = File(relativePath);
  expect(file.existsSync(), isTrue, reason: 'missing $relativePath');
  return file.readAsStringSync();
}

void main() {
  group('skipsCompanyStatusCheck', () {
    test('is true only for UserRole.superAdmin, regardless of email', () {
      expect(
        skipsCompanyStatusCheck(
          _user(role: UserRole.superAdmin, email: 'other-admin@example.com'),
        ),
        isTrue,
      );
      expect(
        skipsCompanyStatusCheck(
          _user(
            role: UserRole.superAdmin,
            email: 'superadmin@platform.com',
          ),
        ),
        isTrue,
      );
    });

    test('is false for other roles even with the demo super-admin email', () {
      expect(
        skipsCompanyStatusCheck(
          _user(
            role: UserRole.admin,
            email: 'superadmin@platform.com',
          ),
        ),
        isFalse,
      );
      expect(
        skipsCompanyStatusCheck(
          _user(
            role: UserRole.employee,
            email: 'superadmin@platform.com',
          ),
        ),
        isFalse,
      );
    });
  });

  group('AppWrapper / AuthService source', () {
    test('company-status gate does not special-case superadmin email', () {
      final mainSource = _read('lib/main.dart');
      final authSource = _read('lib/services/auth_service.dart');
      final helperSource = _read('lib/utils/super_admin_routing.dart');

      expect(mainSource, contains('skipsCompanyStatusCheck'));
      expect(authSource, contains('skipsCompanyStatusCheck'));
      expect(
        helperSource,
        contains(
          'bool skipsCompanyStatusCheck(User user) => user.role == UserRole.superAdmin;',
        ),
      );
      expect(helperSource, isNot(contains('user.email')));

      for (final source in [mainSource, authSource]) {
        expect(source, isNot(contains("email != 'superadmin@platform.com'")));
        expect(source, isNot(contains("email == 'superadmin@platform.com'")));
      }
    });

    test('role-gate tests are included in product CI', () {
      final workflow = _read('.github/workflows/flutter-tests.yml');
      final excludeMatch = RegExp(r"EXCLUDE='([^']+)'").firstMatch(workflow);
      expect(excludeMatch, isNotNull);
      expect(
        excludeMatch!.group(1),
        isNot(contains('super_admin_routing_test.dart')),
        reason: 'auth_service_test.dart is CI-excluded; this file must run',
      );
    });

    test('tracked lib dart has no email != superadmin company-status gate', () {
      final listed = Process.runSync(
        'git',
        ['ls-files', 'lib'],
        workingDirectory: Directory.current.path,
      );
      expect(listed.exitCode, 0, reason: listed.stderr.toString());
      final paths = listed.stdout
          .toString()
          .split('\n')
          .map((line) => line.trim())
          .where((line) => line.endsWith('.dart'))
          .toList();
      expect(paths, isNotEmpty);

      for (final relative in paths) {
        final source = File(relative).readAsStringSync();
        expect(
          source.contains("email != 'superadmin@platform.com'"),
          isFalse,
          reason: '$relative still special-cases the demo super-admin email',
        );
      }
    });
  });
}
