import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bonuses/models/company.dart';
import 'package:bonuses/models/user.dart';
import 'package:bonuses/services/auth_service.dart';
import 'package:bonuses/services/imported_employee_login.dart';
import 'package:bonuses/services/password_service.dart';
import 'package:bonuses/services/storage_service.dart';

void main() {
  group('Imported employee login', () {
    const userId = 'imported_emp_1';
    const email = 'imported.staff@example.com';

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await AuthService.logout();

      final company = Company(
        id: 'import_company',
        name: 'Import Co',
        contactEmail: 'admin@import.co',
        adminUserId: 'admin_import',
        createdAt: DateTime.now(),
        isActive: true,
      );

      final employee = User(
        id: userId,
        name: 'Imported Staff',
        email: email,
        phoneNumber: '+1 (555) 000-1111',
        role: UserRole.employee,
        createdAt: DateTime.now(),
        companyIds: [company.id],
        companyNames: [company.name],
        primaryCompanyId: company.id,
        companyRoles: {company.id: 'employee'},
        companyPoints: {company.id: 0},
      );

      await StorageService.addCompany(company);
      await StorageService.addUser(employee);
    });

    tearDown(() async {
      await AuthService.logout();
    });

    test('imported employee without a password cannot log in', () async {
      expect(await StorageService.getPassword(userId), isNull);
      final success = await AuthService.login(
        email,
        kImportedEmployeeDefaultPassword,
      );
      expect(success, isFalse);
    });

    test('ensureImportedEmployeePassword sets the default so they can log in',
        () async {
      await ensureImportedEmployeePassword(userId);

      final stored = await StorageService.getPassword(userId);
      expect(stored, isNotNull);
      expect(stored, isNot(equals(kImportedEmployeeDefaultPassword)));
      expect(PasswordService.isBcryptHash(stored!), isTrue);

      final success = await AuthService.login(
        email,
        kImportedEmployeeDefaultPassword,
      );
      expect(success, isTrue);
      expect(AuthService.currentUser?.email, email);
    });

    test('does not overwrite an existing password', () async {
      await StorageService.savePassword(userId, 'already-set-456');
      await ensureImportedEmployeePassword(userId);

      expect(
        await AuthService.login(email, 'already-set-456'),
        isTrue,
      );
      await AuthService.logout();
      expect(
        await AuthService.login(email, kImportedEmployeeDefaultPassword),
        isFalse,
      );
    });
  });
}
