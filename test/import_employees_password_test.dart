import 'dart:io';

import 'package:bonuses/models/company.dart';
import 'package:bonuses/models/user.dart';
import 'package:bonuses/providers/app_provider.dart';
import 'package:bonuses/screens/import_employees_screen.dart';
import 'package:bonuses/services/auth_service.dart';
import 'package:bonuses/services/imported_employee_login.dart';
import 'package:bonuses/services/password_service.dart';
import 'package:bonuses/services/storage_service.dart';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart' hide Border, TextSpan;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Column contract from `_parseFile` in `import_employees_screen.dart`.
List<Map<String, dynamic>> previewEmployeesFromRows(List<List<dynamic>> rows) {
  final employeeData = <Map<String, dynamic>>[];
  for (int i = 1; i < rows.length; i++) {
    final row = rows[i];
    if (row.length < 4) continue;
    final name = row[0]?.toString().trim() ?? '';
    final email = row[1]?.toString().trim() ?? '';
    final phone = row[2]?.toString().trim() ?? '';
    final pointsStr = row[3]?.toString().trim() ?? '0';
    if (name.isEmpty || email.isEmpty) continue;
    int points = 0;
    try {
      points = int.parse(pointsStr.replaceAll(RegExp(r'[^0-9]'), ''));
    } catch (e) {
      points = 0;
    }
    employeeData.add({
      'name': name,
      'email': email,
      'phone': phone,
      'points': points,
    });
  }
  return employeeData;
}

/// New-create and existing-row password assignment from `_importEmployees`.
Future<void> applyImportLoginPath(
  List<Map<String, dynamic>> preview, {
  required String companyId,
  required String companyName,
}) async {
  final existingUsers = await StorageService.getUsers();
  var imported = 0;
  for (final data in preview) {
    final email = data['email'] as String;
    User? existingUser;
    for (final user in existingUsers) {
      if (user.email.toLowerCase() == email.toLowerCase()) {
        existingUser = user;
        break;
      }
    }
    if (existingUser != null && existingUser.id.isNotEmpty) {
      await ensureImportedEmployeePassword(existingUser.id);
      continue;
    }
    final newEmployee = User(
      id: 'emp_import_$imported',
      name: data['name'] as String,
      email: email,
      phoneNumber: data['phone'] as String,
      role: UserRole.employee,
      createdAt: DateTime.now(),
      companyIds: [companyId],
      companyNames: [companyName],
      primaryCompanyId: companyId,
    );
    await StorageService.addUser(newEmployee);
    await ensureImportedEmployeePassword(newEmployee.id);
    imported++;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const userId = 'imported_emp_1';
  const email = 'imported.staff@example.com';
  const companyId = 'import_company';
  const companyName = 'Import Co';

  Future<void> seedImportedEmployee() async {
    SharedPreferences.setMockInitialValues({});
    await AuthService.logout();

    final company = Company(
      id: companyId,
      name: companyName,
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
  }

  group('Imported employee login', () {
    setUp(seedImportedEmployee);

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

  group('CSV/Excel import assigns login', () {
    setUp(seedImportedEmployee);

    tearDown(() async {
      await AuthService.logout();
    });

    test('CSV import saves default password for new staff and they can log in',
        () async {
      // Production `_parseFile` uses CsvToListConverter's default eol (`\r\n`).
      const csv = 'Name,Email,Phone,current points\r\n'
          'Csv Staff,csv.staff@example.com,+1 (555) 000-2222,10\r\n';
      final rows = const CsvToListConverter().convert(csv);
      final preview = previewEmployeesFromRows(rows);
      expect(preview, isNotEmpty,
          reason: 'CSV should parse at least one staff row');
      expect(preview.single['email'], 'csv.staff@example.com');

      await applyImportLoginPath(
        preview,
        companyId: companyId,
        companyName: companyName,
      );

      expect(
        await AuthService.login(
          'csv.staff@example.com',
          kImportedEmployeeDefaultPassword,
        ),
        isTrue,
      );
      expect(AuthService.currentUser?.email, 'csv.staff@example.com');
    });

    test(
        'Excel import saves default password for new staff and they can log in',
        () async {
      final workbook = Excel.createExcel();
      final sheet = workbook[workbook.tables.keys.first];
      sheet.appendRow([
        TextCellValue('Name'),
        TextCellValue('Email'),
        TextCellValue('Phone'),
        TextCellValue('current points'),
      ]);
      sheet.appendRow([
        TextCellValue('Excel Staff'),
        TextCellValue('excel.staff@example.com'),
        TextCellValue('+1 (555) 000-3333'),
        TextCellValue('5'),
      ]);
      final bytes = workbook.save();
      expect(bytes, isNotNull);

      final decoded = Excel.decodeBytes(bytes!);
      final table = decoded.tables[decoded.tables.keys.first]!;
      final rows = table.rows
          .map((row) => row.map((cell) => cell?.value).toList())
          .toList();
      final preview = previewEmployeesFromRows(rows);
      expect(preview.single['email'], 'excel.staff@example.com');

      await applyImportLoginPath(
        preview,
        companyId: companyId,
        companyName: companyName,
      );

      expect(
        await AuthService.login(
          'excel.staff@example.com',
          kImportedEmployeeDefaultPassword,
        ),
        isTrue,
      );
    });

    test('re-import of staff with no password sets the default', () async {
      expect(await StorageService.getPassword(userId), isNull);
      const csv = 'Name,Email,Phone,current points\r\n'
          'Imported Staff,imported.staff@example.com,+1 (555) 000-1111,0\r\n';
      final preview =
          previewEmployeesFromRows(const CsvToListConverter().convert(csv));
      expect(preview, isNotEmpty);
      await applyImportLoginPath(
        preview,
        companyId: companyId,
        companyName: companyName,
      );

      expect(
        await AuthService.login(email, kImportedEmployeeDefaultPassword),
        isTrue,
      );
    });

    test('re-import does not overwrite an existing password', () async {
      await StorageService.savePassword(userId, 'already-set-456');
      const csv = 'Name,Email,Phone,current points\r\n'
          'Imported Staff,imported.staff@example.com,+1 (555) 000-1111,0\r\n';
      final preview =
          previewEmployeesFromRows(const CsvToListConverter().convert(csv));
      expect(preview, isNotEmpty);
      await applyImportLoginPath(
        preview,
        companyId: companyId,
        companyName: companyName,
      );

      expect(await AuthService.login(email, 'already-set-456'), isTrue);
      await AuthService.logout();
      expect(
        await AuthService.login(email, kImportedEmployeeDefaultPassword),
        isFalse,
      );
    });
  });

  group('Import screen source and copy', () {
    test('CSV and Excel paths both assign passwords; no phone OTP', () {
      final source =
          File('lib/screens/import_employees_screen.dart').readAsStringSync();
      expect(
        source,
        contains("import '../services/imported_employee_login.dart';"),
      );
      expect(source, contains(".endsWith('.csv')"));
      expect(source, contains('Excel.decodeBytes'));
      expect(source, contains('CsvToListConverter'));
      expect(
        source,
        contains('await ensureImportedEmployeePassword(newEmployee.id);'),
      );
      expect(
        source,
        contains('await ensureImportedEmployeePassword(existingUser.id);'),
      );
      expect(source.toLowerCase(), isNot(contains('otp')));
      expect(source.toLowerCase(), isNot(contains('sms')));

      final helper =
          File('lib/services/imported_employee_login.dart').readAsStringSync();
      expect(helper.toLowerCase(), isNot(contains('otp')));
      expect(
          helper, contains("kImportedEmployeeDefaultPassword = 'password123'"));
    });

    test('default import password matches manual add-employee', () {
      expect(kImportedEmployeeDefaultPassword, 'password123');
      final dashboard =
          File('lib/screens/admin_dashboard.dart').readAsStringSync();
      expect(dashboard, contains("savePassword(user.id, 'password123')"));
    });

    test('import password test is not a named CI exclusion', () {
      final workflow =
          File('.github/workflows/flutter-tests.yml').readAsStringSync();
      expect(workflow, isNot(contains('import_employees_password_test.dart')));
    });

    testWidgets(
        'import screen tells staff to log in with email and default password',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final provider = AppProvider();
      await tester.pumpWidget(
        MaterialApp(
          home: ImportEmployeesScreen(appProvider: provider),
        ),
      );
      await tester.pump();

      expect(find.text('Select Excel or CSV File'), findsOneWidget);
      expect(
        find.textContaining(
          'New employees can log in with their email and default password '
          '"$kImportedEmployeeDefaultPassword"',
        ),
        findsOneWidget,
      );
      expect(find.textContaining('OTP'), findsNothing);
      expect(find.textContaining('SMS'), findsNothing);
    });
  });
}
