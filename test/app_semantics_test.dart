import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:bonuses/models/approval_request.dart';
import 'package:bonuses/models/company.dart';
import 'package:bonuses/models/sales_target.dart';
import 'package:bonuses/models/user.dart';
import 'package:bonuses/providers/app_provider.dart';
import 'package:bonuses/screens/admin_dashboard.dart';
import 'package:bonuses/screens/employee_dashboard.dart';
import 'package:bonuses/screens/login_screen.dart';
import 'package:bonuses/screens/super_admin_dashboard.dart';
import 'package:bonuses/services/storage_service.dart';
import 'package:bonuses/utils/app_semantics.dart';
import 'package:bonuses/widgets/profile_header_widget.dart';
import 'test_helpers.dart';

const _removedLoginChrome = [
  'Demo Accounts:',
  'password123',
  'utilif123',
  'Reset Demo Data',
  'Reset Password for User',
  'Reset Password',
  'Debug Users',
  'Test Supabase Integration',
  'Test Create Jon2 Employee',
  'Test Create Bonus',
  'Comprehensive DB Test',
  'Check Password Status',
];

void main() {
  setupSharedPreferencesMock();

  late String loginSource;
  late String employeeSource;
  late String adminSource;
  late String superAdminSource;
  late String headerSource;
  late String workflowSource;

  setUpAll(() {
    loginSource = File('lib/screens/login_screen.dart').readAsStringSync();
    employeeSource =
        File('lib/screens/employee_dashboard.dart').readAsStringSync();
    adminSource = File('lib/screens/admin_dashboard.dart').readAsStringSync();
    superAdminSource =
        File('lib/screens/super_admin_dashboard.dart').readAsStringSync();
    headerSource =
        File('lib/widgets/profile_header_widget.dart').readAsStringSync();
    workflowSource =
        File('.github/workflows/flutter-tests.yml').readAsStringSync();
  });

  group('source locks — labels stay wired', () {
    test('login form fields and primary actions use AppSemantics', () {
      for (final token in [
        'AppSemantics.loginScreen',
        'AppSemantics.loginForm',
        'AppSemantics.emailField',
        'AppSemantics.passwordField',
        'AppSemantics.loginButton',
        'AppSemantics.signingIn',
        'AppSemantics.createCompany',
        'AppSemantics.showPassword',
        'AppSemantics.hidePassword',
        'AppSemantics.darkMode',
        'AppSemantics.lightMode',
      ]) {
        expect(loginSource, contains(token),
            reason: 'login_screen.dart must keep $token');
      }
    });

    test('employee chrome uses AppSemantics', () {
      for (final token in [
        'AppSemantics.employeeDashboard',
        'AppSemantics.employeeNavigation',
        'AppSemantics.settings',
        'AppSemantics.previousDate',
        'AppSemantics.todayDate',
        'AppSemantics.nextDate',
        'AppSemantics.darkMode',
      ]) {
        expect(employeeSource, contains(token),
            reason: 'employee_dashboard.dart must keep $token');
      }
    });

    test('admin chrome uses AppSemantics', () {
      for (final token in [
        'AppSemantics.adminDashboard',
        'AppSemantics.adminNavigation',
        'AppSemantics.settings',
        'AppSemantics.approveAll',
        'AppSemantics.darkMode',
      ]) {
        expect(adminSource, contains(token),
            reason: 'admin_dashboard.dart must keep $token');
      }
    });

    test('super-admin chrome uses AppSemantics', () {
      for (final token in [
        'AppSemantics.superAdminDashboard',
        'AppSemantics.superAdminNavigation',
        'AppSemantics.settings',
        'AppSemantics.newSubscription',
        'AppSemantics.manageBankAccounts',
        'AppSemantics.logout',
      ]) {
        expect(superAdminSource, contains(token),
            reason: 'super_admin_dashboard.dart must keep $token');
      }
    });

    test('profile header chrome uses AppSemantics', () {
      for (final token in [
        'AppSemantics.profileHeader',
        'AppSemantics.profile',
        'AppSemantics.companySwitcher',
      ]) {
        expect(headerSource, contains(token),
            reason: 'profile_header_widget.dart must keep $token');
      }
    });

    test('logged-out login still has no demo chrome or phone OTP', () {
      for (final chrome in _removedLoginChrome) {
        expect(loginSource.contains(chrome), isFalse,
            reason: 'login_screen.dart must not restore "$chrome"');
      }
      expect(loginSource, isNot(contains('signInWithOtp')));
      expect(loginSource, isNot(contains('verifyOTP')));
      expect(loginSource, isNot(contains('Phone OTP')));
    });

    test('Payment Required banner is unchanged (BON-31)', () {
      expect(adminSource, contains('Widget _buildSubscriptionStatusBanner'));
      expect(adminSource, contains('Payment Required:'));
      expect(adminSource, contains('past due'));
      final bannerStart =
          adminSource.indexOf('Widget _buildSubscriptionStatusBanner');
      final bannerEnd = adminSource.indexOf(
        'void _showDeleteTargetDialog',
        bannerStart,
      );
      expect(bannerStart, greaterThanOrEqualTo(0));
      expect(bannerEnd, greaterThan(bannerStart));
      final banner = adminSource.substring(bannerStart, bannerEnd);
      expect(banner, isNot(contains('AppSemantics')),
          reason:
              'BON-31 owns the subscription banner; do not relabel it here');
    });

    test('product CI includes app_semantics_test.dart', () {
      final excludeMatch =
          RegExp(r"EXCLUDE='([^']+)'").firstMatch(workflowSource);
      expect(excludeMatch, isNotNull);
      expect(
          excludeMatch!.group(1), isNot(contains('app_semantics_test.dart')));
      expect(workflowSource, contains("find test -name '*_test.dart'"));
    });
  });

  group('LoginScreen semantics', () {
    testWidgets('exposes identifiers and labels for form fields and actions',
        (tester) async {
      await tester.pumpWidget(_loginApp());
      await tester.pumpAndSettle();

      _expectSemantics(identifier: AppSemantics.loginScreen);
      _expectSemantics(identifier: AppSemantics.loginForm);
      _expectSemantics(identifier: AppSemantics.emailField);
      _expectSemantics(identifier: AppSemantics.passwordField);
      _expectSemantics(identifier: AppSemantics.loginButton);
      _expectSemantics(identifier: AppSemantics.createCompany);
      _expectSemantics(label: AppSemantics.emailField);
      _expectSemantics(label: AppSemantics.passwordField);
      _expectSemantics(label: AppSemantics.loginButton);
      _expectSemantics(label: AppSemantics.createCompany);
      _expectIconLabel(AppSemantics.showPassword);
      _expectIconLabel(AppSemantics.darkMode);
      expect(find.byTooltip(AppSemantics.darkMode), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2));

      for (final chrome in _removedLoginChrome) {
        expect(find.textContaining(chrome), findsNothing,
            reason: 'logged-out login must not show "$chrome"');
      }
    });

    testWidgets('password visibility toggle flips show/hide labels',
        (tester) async {
      await tester.pumpWidget(_loginApp());
      await tester.pumpAndSettle();

      expect(find.byTooltip(AppSemantics.showPassword), findsOneWidget);
      await tester.tap(find.byTooltip(AppSemantics.showPassword));
      await tester.pump();

      expect(find.byTooltip(AppSemantics.hidePassword), findsOneWidget);
      _expectIconLabel(AppSemantics.hidePassword);
    });
  });

  group('ProfileHeaderWidget semantics', () {
    testWidgets('header, profile, actions, and company switcher are labeled',
        (tester) async {
      final companies = [
        Company(
          id: 'c1',
          name: 'Alpha Co',
          adminUserId: 'admin',
          createdAt: DateTime.now(),
        ),
        Company(
          id: 'c2',
          name: 'Beta Co',
          adminUserId: 'admin',
          createdAt: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProfileHeaderWidget(
              userName: 'Pat Dashboard',
              userEmail: 'pat@test.com',
              onProfileTap: () {},
              actionButtons: [
                ActionButton(
                  icon: Icons.calendar_today,
                  label: 'Calendar',
                  color: Colors.blue,
                  onTap: () {},
                ),
                ActionButton(
                  icon: Icons.message,
                  label: 'Messages',
                  color: Colors.green,
                  onTap: () {},
                ),
              ],
              userCompanies: companies,
              currentCompanyId: 'c1',
              onCompanyChanged: (_) {},
            ),
          ),
        ),
      );
      await tester.pump();

      _expectSemantics(identifier: AppSemantics.profileHeader);
      _expectSemantics(label: AppSemantics.profile);
      _expectSemantics(identifier: AppSemantics.companySwitcher);
      _expectSemantics(label: 'Calendar');
      _expectSemantics(label: 'Messages');
      _expectIconLabel(AppSemantics.profile);
      _expectIconLabel(AppSemantics.companySwitcher);
    });
  });

  group('EmployeeDashboard semantics', () {
    late AppProvider appProvider;

    setUp(() async {
      appProvider = await _seedDashboard(role: UserRole.employee);
    });

    tearDown(() async {
      await StorageService.clearAllData();
    });

    testWidgets('app bar, nav, date controls, and header are labeled',
        (tester) async {
      await _pumpRoleDashboard(tester, appProvider, const EmployeeDashboard());

      _expectSemantics(identifier: AppSemantics.employeeDashboard);
      _expectSemantics(identifier: AppSemantics.employeeNavigation);
      _expectIconLabel(AppSemantics.settings);
      expect(find.byTooltip(AppSemantics.settings), findsOneWidget);
      _expectSemantics(identifier: AppSemantics.profileHeader);
      _expectSemantics(identifier: AppSemantics.previousDate);
      _expectSemantics(identifier: AppSemantics.todayDate);
      _expectSemantics(identifier: AppSemantics.nextDate);
      _expectIconLabel('Overview');
      _expectIconLabel('Targets');
      _expectIconLabel('Bonuses');
      _expectIconLabel('Profile');
    });

    testWidgets('settings items and dark mode are labeled', (tester) async {
      await _pumpRoleDashboard(tester, appProvider, const EmployeeDashboard());

      await tester.tap(find.byTooltip(AppSemantics.settings));
      await tester.pump();
      await tester.pump();

      _expectSemantics(identifier: AppSemantics.darkMode);
      _expectSemantics(label: 'Edit Profile');
      _expectSemantics(label: 'View Employees');
      _expectSemantics(label: 'Logout');
    });
  });

  group('AdminDashboard semantics', () {
    late AppProvider appProvider;

    setUp(() async {
      appProvider = await _seedDashboard(
        role: UserRole.admin,
        withPendingApproval: true,
      );
    });

    tearDown(() async {
      await StorageService.clearAllData();
    });

    testWidgets('app bar, custom nav, header, and Approve All are labeled',
        (tester) async {
      await _pumpRoleDashboard(tester, appProvider, const AdminDashboard());

      _expectSemantics(identifier: AppSemantics.adminDashboard);
      _expectSemantics(identifier: AppSemantics.adminNavigation);
      expect(find.byTooltip(AppSemantics.settings), findsOneWidget);
      _expectSemantics(identifier: AppSemantics.profileHeader);
      _expectSemantics(label: 'Dashboard');
      _expectSemantics(label: 'Bonuses');
      _expectSemantics(label: 'Settings');
      _expectSemantics(identifier: AppSemantics.approveAll);
    });

    testWidgets('settings items and dark mode are labeled', (tester) async {
      await _pumpRoleDashboard(tester, appProvider, const AdminDashboard());

      await tester.tap(find.byTooltip(AppSemantics.settings));
      await tester.pump();
      await tester.pump();

      final settingsHeader = find.descendant(
        of: find.byType(InkWell),
        matching: find.text('Settings'),
      );
      expect(settingsHeader, findsWidgets);
      await tester.tap(settingsHeader.first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      _expectSemantics(identifier: AppSemantics.darkMode);
      _expectSemantics(label: 'Manage Employees');
      _expectSemantics(label: 'Logout');
    });
  });

  group('SuperAdminDashboard semantics', () {
    late AppProvider appProvider;

    setUp(() async {
      appProvider = await _seedDashboard(role: UserRole.superAdmin);
    });

    tearDown(() async {
      await StorageService.clearAllData();
    });

    testWidgets('app bar, nav, and overview stat cards are labeled',
        (tester) async {
      await _pumpRoleDashboard(
          tester, appProvider, const SuperAdminDashboard());
      await tester.pump();
      await tester.pump();

      _expectSemantics(identifier: AppSemantics.superAdminDashboard);
      _expectSemantics(identifier: AppSemantics.superAdminNavigation);
      _expectIconLabel('Overview');
      _expectIconLabel('Companies');
      _expectIconLabel('Subscriptions');
      _expectIconLabel('Analytics');
      _expectIconLabel(AppSemantics.settings);
      _expectSemantics(label: 'Total Companies');
      _expectSemantics(label: 'Active Companies');
      _expectSemantics(label: 'Total Employees');
      _expectSemantics(label: 'Monthly Revenue');
    });

    testWidgets('New Subscription is labeled on the subscriptions tab',
        (tester) async {
      // Pre-existing: _buildTierCard Row overflows ~9px (BON-28 out of scope).
      final previousOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        if (details.exceptionAsString().contains('overflowed')) return;
        previousOnError?.call(details);
      };
      addTearDown(() => FlutterError.onError = previousOnError);

      await _pumpRoleDashboard(
          tester, appProvider, const SuperAdminDashboard());
      await tester.pump();

      await tester.tap(find.byIcon(Icons.subscriptions));
      await tester.pump();
      await tester.pump();
      await tester.pump();

      _expectSemantics(identifier: AppSemantics.newSubscription);
    });

    testWidgets('Logout and Manage Bank Accounts are labeled on Settings',
        (tester) async {
      await _pumpRoleDashboard(
          tester, appProvider, const SuperAdminDashboard());
      await tester.pump();

      await tester.tap(find.byIcon(Icons.settings));
      await tester.pump();
      await tester.pump();

      _expectSemantics(identifier: AppSemantics.manageBankAccounts);
      _expectSemantics(identifier: AppSemantics.logout);
    });
  });
}

void _expectSemantics({String? identifier, String? label}) {
  expect(
    find.byWidgetPredicate(
      (widget) {
        if (widget is! Semantics) return false;
        final props = widget.properties;
        if (identifier != null && props.identifier != identifier) return false;
        if (label != null && props.label != label) return false;
        return true;
      },
      description: 'Semantics(identifier: $identifier, label: $label)',
    ),
    findsAtLeastNWidgets(1),
    reason: 'missing Semantics identifier="$identifier" label="$label"',
  );
}

void _expectIconLabel(String label) {
  expect(
    find.byWidgetPredicate(
      (widget) => widget is Icon && widget.semanticLabel == label,
      description: 'Icon(semanticLabel: $label)',
    ),
    findsAtLeastNWidgets(1),
    reason: 'missing Icon semanticLabel "$label"',
  );
}

Widget _loginApp() {
  return ChangeNotifierProvider(
    create: (_) => AppProvider(),
    child: MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: const LoginScreen(),
    ),
  );
}

Future<void> _pumpRoleDashboard(
  WidgetTester tester,
  AppProvider appProvider,
  Widget dashboard,
) async {
  tester.view.physicalSize = const Size(800, 1800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ChangeNotifierProvider<AppProvider>.value(
      value: appProvider,
      child: MaterialApp(home: dashboard),
    ),
  );
  await tester.pump();
  await tester.pump();
}

Future<AppProvider> _seedDashboard({
  required UserRole role,
  bool withPendingApproval = false,
}) async {
  await StorageService.clearAllData();
  await StorageService.setDarkMode(false);

  final company = Company(
    id: 'sem_company',
    name: 'Semantics Test Co',
    adminUserId: 'sem_admin',
    createdAt: DateTime.now(),
  );

  final employee = User(
    id: 'sem_employee',
    name: 'Pat Employee',
    email: 'pat.semantics@test.com',
    role: UserRole.employee,
    createdAt: DateTime.now(),
    primaryCompanyId: company.id,
    companyIds: [company.id],
    companyNames: [company.name],
    companyRoles: {company.id: 'employee'},
  );
  final admin = User(
    id: 'sem_admin',
    name: 'Pat Admin',
    email: 'pat.admin.semantics@test.com',
    role: UserRole.admin,
    createdAt: DateTime.now(),
    primaryCompanyId: company.id,
    companyIds: [company.id],
    companyNames: [company.name],
    companyRoles: {company.id: 'admin'},
  );
  final superAdmin = User(
    id: 'sem_super',
    name: 'Pat Super',
    email: 'pat.super.semantics@test.com',
    role: UserRole.superAdmin,
    createdAt: DateTime.now(),
  );

  await StorageService.saveCompanies([company]);
  await StorageService.saveUsers([
    User(
      id: 'stub_admin_store',
      name: 'Stub',
      email: 'admin@store.com',
      role: UserRole.admin,
      createdAt: DateTime.now(),
      primaryCompanyId: company.id,
      companyIds: [company.id],
    ),
    User(
      id: 'stub_admin_utilif',
      name: 'Stub',
      email: 'admin@utilif.com',
      role: UserRole.admin,
      createdAt: DateTime.now(),
      primaryCompanyId: company.id,
      companyIds: [company.id],
    ),
    User(
      id: 'stub_john',
      name: 'Stub',
      email: 'john.doe@example.com',
      role: UserRole.employee,
      createdAt: DateTime.now(),
      primaryCompanyId: company.id,
      companyIds: [company.id],
    ),
    User(
      id: 'superadmin1',
      name: 'Platform Administrator',
      email: 'superadmin@platform.com',
      role: UserRole.superAdmin,
      createdAt: DateTime.now(),
    ),
    employee,
    admin,
    superAdmin,
  ]);

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final target = SalesTarget(
    id: 'sem_target_today',
    targetAmount: 1847,
    date: today,
    companyId: company.id,
    assignedEmployeeId: employee.id,
    assignedEmployeeName: employee.name,
    createdAt: DateTime.now(),
    createdBy: admin.id,
  );
  await StorageService.saveSalesTargets([target]);

  if (withPendingApproval) {
    await StorageService.saveApprovalRequests([
      ApprovalRequest(
        id: 'sem_approval',
        targetId: target.id,
        submittedBy: employee.id,
        submittedByName: employee.name,
        type: ApprovalRequestType.salesSubmission,
        status: ApprovalStatus.pending,
        submittedAt: DateTime.now(),
        newActualAmount: 50,
      ),
    ]);
  }

  final current = switch (role) {
    UserRole.admin => admin,
    UserRole.superAdmin => superAdmin,
    UserRole.employee => employee,
  };
  await StorageService.clearSelectedDate(current.id);
  await StorageService.setCurrentUser(current);

  final appProvider = AppProvider();
  await appProvider.initialize();
  return appProvider;
}
