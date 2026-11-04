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

      expect(mainSource, contains('skipsCompanyStatusCheck'));
      expect(authSource, contains('skipsCompanyStatusCheck'));
      expect(mainSource, isNot(contains("email != 'superadmin@platform.com'")));
      expect(authSource, isNot(contains("email != 'superadmin@platform.com'")));
    });
  });
}
