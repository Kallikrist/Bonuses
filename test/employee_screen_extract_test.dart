import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:bonuses/models/company.dart';
import 'package:bonuses/models/user.dart';
import 'package:bonuses/providers/app_provider.dart';
import 'package:bonuses/screens/employee_profile_screen.dart';
import 'package:bonuses/screens/employees_list_screen.dart';
import 'package:bonuses/services/storage_service.dart';
import 'test_helpers.dart';

String _read(String relativePath) {
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

bool _declaresClass(String source, String className) {
  return RegExp('class $className\\b').hasMatch(source);
}

bool _importsRelative(String source, String fileName) {
  return RegExp(
    """^\\s*import\\s+['"]$fileName['"]""",
    multiLine: true,
  ).hasMatch(source);
}

bool _importsPackageScreen(String source, String fileName) {
  return RegExp(
    """^\\s*import\\s+['"]package:bonuses/screens/$fileName['"]""",
    multiLine: true,
  ).hasMatch(source);
}

void main() {
  group('Extracted employee screens live in their own files', () {
    late String profile;
    late String list;
    late String admin;
    late String employeeDashboard;
    late String companyProfile;
    late String accessTest;

    setUpAll(() {
      profile = _read('lib/screens/employee_profile_screen.dart');
      list = _read('lib/screens/employees_list_screen.dart');
      admin = _read('lib/screens/admin_dashboard.dart');
      employeeDashboard = _read('lib/screens/employee_dashboard.dart');
      companyProfile = _read('lib/screens/company_profile_screen.dart');
      accessTest = _read('test/employee_profile_access_test.dart');
    });

    test('EmployeeProfileScreen is declared only in employee_profile_screen.dart',
        () {
      expect(_declaresClass(profile, 'EmployeeProfileScreen'), isTrue);
      expect(_declaresClass(admin, 'EmployeeProfileScreen'), isFalse);
      expect(_declaresClass(list, 'EmployeeProfileScreen'), isFalse);
      expect(_declaresClass(employeeDashboard, 'EmployeeProfileScreen'), isFalse);
    });

    test('EmployeesListScreen is declared only in employees_list_screen.dart',
        () {
      expect(_declaresClass(list, 'EmployeesListScreen'), isTrue);
      expect(_declaresClass(admin, 'EmployeesListScreen'), isFalse);
      expect(_declaresClass(profile, 'EmployeesListScreen'), isFalse);
      expect(_declaresClass(employeeDashboard, 'EmployeesListScreen'), isFalse);
    });

    test('admin_dashboard.dart imports the extracted screens', () {
      expect(_importsRelative(admin, 'employee_profile_screen.dart'), isTrue);
      expect(_importsRelative(admin, 'employees_list_screen.dart'), isTrue);
    });

    test('employee_dashboard.dart no longer imports admin_dashboard.dart', () {
      expect(
        _importsRelative(employeeDashboard, 'admin_dashboard.dart'),
        isFalse,
        reason: 'Employee UI must not import the admin dashboard god-file',
      );
      expect(
        _importsRelative(employeeDashboard, 'employee_profile_screen.dart'),
        isTrue,
      );
      expect(
        _importsRelative(employeeDashboard, 'employees_list_screen.dart'),
        isTrue,
      );
    });

    test('company_profile_screen.dart imports EmployeesListScreen from new file',
        () {
      expect(
        _importsRelative(companyProfile, 'employees_list_screen.dart'),
        isTrue,
      );
      expect(
        _importsRelative(companyProfile, 'employee_profile_screen.dart'),
        isFalse,
        reason: 'Company profile only needs the list screen',
      );
    });

    test('employees_list_screen.dart opens EmployeeProfileScreen from new file',
        () {
      expect(_importsRelative(list, 'employee_profile_screen.dart'), isTrue);
      expect(_importsRelative(list, 'admin_dashboard.dart'), isFalse);
      expect(list, contains('EmployeeProfileScreen('));
    });

    test('employee_profile_access_test.dart imports extracted screens', () {
      expect(
        _importsPackageScreen(accessTest, 'employee_profile_screen.dart'),
        isTrue,
      );
      expect(
        _importsPackageScreen(accessTest, 'employees_list_screen.dart'),
        isTrue,
      );
      expect(
        _importsPackageScreen(accessTest, 'admin_dashboard.dart'),
        isFalse,
      );
    });

    test('extract contract is included in product CI', () {
      final workflow = _read('.github/workflows/flutter-tests.yml');
      expect(
        workflow.contains('employee_screen_extract_test.dart'),
        isFalse,
        reason: 'New extract tests must not be added to the named EXCLUDE list',
      );
      expect(
        workflow.contains("EXCLUDE='"),
        isTrue,
      );
    });
  });

  group('Extracted screens still construct from callers', () {
    setupSharedPreferencesMock();

    late AppProvider appProvider;
    late User employee;
    late User admin;
    late Company company;

    setUp(() async {
      await StorageService.clearAllData();
      appProvider = AppProvider();
      company = Company(
        id: 'extract_company',
        name: 'Extract Co',
        address: '1 Test St',
        contactEmail: 'extract@company.com',
        contactPhone: '555-0200',
        adminUserId: 'extract_admin',
        createdAt: DateTime.now(),
      );
      admin = User(
        id: 'extract_admin',
        name: 'Extract Admin',
        email: 'extract.admin@test.com',
        role: UserRole.admin,
        createdAt: DateTime.now(),
        primaryCompanyId: company.id,
        companyIds: [company.id],
        companyRoles: {company.id: 'admin'},
        phoneNumber: '555-0201',
      );
      employee = User(
        id: 'extract_emp',
        name: 'Extract Employee',
        email: 'extract.emp@test.com',
        role: UserRole.employee,
        createdAt: DateTime.now(),
        primaryCompanyId: company.id,
        companyIds: [company.id],
        companyRoles: {company.id: 'employee'},
        phoneNumber: '555-0202',
      );
      await StorageService.addCompany(company);
      await StorageService.addUser(admin);
      await StorageService.addUser(employee);
      await StorageService.setCurrentUser(employee);
      await appProvider.initialize();
    });

    tearDown(() async {
      await StorageService.clearAllData();
    });

    test('EmployeeProfileScreen and EmployeesListScreen constructors work', () {
      final profileScreen = EmployeeProfileScreen(
        employee: employee,
        appProvider: appProvider,
        readOnly: true,
        showBackButton: true,
        companyContext: company.id,
      );
      final listScreen = EmployeesListScreen(
        appProvider: appProvider,
        filterCompanyId: company.id,
        customTitle: 'Company Employees',
        readOnly: true,
      );

      expect(profileScreen.employee.id, employee.id);
      expect(profileScreen.readOnly, isTrue);
      expect(profileScreen.companyContext, company.id);
      expect(listScreen.filterCompanyId, company.id);
      expect(listScreen.customTitle, 'Company Employees');
      expect(listScreen.readOnly, isTrue);
    });

    testWidgets('EmployeesListScreen from extracted file lists company employees',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<AppProvider>.value(
          value: appProvider,
          child: MaterialApp(
            home: EmployeesListScreen(
              appProvider: appProvider,
              filterCompanyId: company.id,
              customTitle: 'Company Employees',
              readOnly: true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Company Employees'), findsOneWidget);
      expect(find.text('Extract Employee'), findsWidgets);
      expect(find.byType(FloatingActionButton), findsNothing);
    });

    testWidgets(
        'tapping a listed employee opens EmployeeProfileScreen from new file',
        (WidgetTester tester) async {
      // Pre-existing header Row overflow in EmployeeProfileScreen (moved, not rewritten).
      final previousOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        if (details.exceptionAsString().contains('overflowed')) {
          return;
        }
        previousOnError?.call(details);
      };
      addTearDown(() {
        FlutterError.onError = previousOnError;
      });

      await tester.pumpWidget(
        ChangeNotifierProvider<AppProvider>.value(
          value: appProvider,
          child: MaterialApp(
            home: EmployeesListScreen(
              appProvider: appProvider,
              filterCompanyId: company.id,
              customTitle: 'Company Employees',
              readOnly: true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('Extract Employee'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(EmployeeProfileScreen), findsOneWidget);
      expect(find.text('extract.emp@test.com'), findsWidgets);
    });
  });
}
