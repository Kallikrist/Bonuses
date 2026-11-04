import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:bonuses/models/bonus.dart';
import 'package:bonuses/models/company.dart';
import 'package:bonuses/models/points_transaction.dart';
import 'package:bonuses/models/sales_target.dart';
import 'package:bonuses/models/user.dart';
import 'package:bonuses/providers/app_provider.dart';
import 'package:bonuses/screens/employee_dashboard.dart';
import 'package:bonuses/services/storage_service.dart';
import 'package:bonuses/widgets/target_card_widget.dart';
import 'test_helpers.dart';

/// Widget coverage for EmployeeDashboard main surfaces.
/// Does not refactor the screen. Payments stay mock; no secrets.
void main() {
  setupSharedPreferencesMock();

  late AppProvider appProvider;
  late User employee;
  late Company company;

  const employeeName = 'Pat Dashboard';
  const bonusName = 'Dashboard Test Gift Card';
  const targetAmount = 1847.0;

  Future<void> seed({
    bool withTarget = true,
    bool withBonus = true,
  }) async {
    await StorageService.clearAllData();
    // clearAllData does not reset per-user selected date or dark mode.
    await StorageService.clearSelectedDate('ed_employee');
    await StorageService.setDarkMode(false);

    company = Company(
      id: 'ed_company',
      name: 'Dashboard Test Co',
      adminUserId: 'ed_admin',
      createdAt: DateTime.now(),
    );
    employee = User(
      id: 'ed_employee',
      name: employeeName,
      email: 'pat.dashboard@test.com',
      role: UserRole.employee,
      createdAt: DateTime.now(),
      primaryCompanyId: company.id,
      companyIds: [company.id],
      companyNames: [company.name],
      companyRoles: {company.id: 'employee'},
      companyPoints: {company.id: 75},
    );

    // Local-only fixtures (skip addUser/add* so tests do not hit Supabase).
    // Demo emails + superadmin1 keep initialize() from reseeding sample data.
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
    ]);

    if (withTarget) {
      final now = DateTime.now();
      await StorageService.saveSalesTargets([
        SalesTarget(
          id: 'ed_target_today',
          targetAmount: targetAmount,
          actualAmount: 0,
          date: DateTime(now.year, now.month, now.day),
          companyId: company.id,
          assignedEmployeeId: employee.id,
          assignedEmployeeName: employee.name,
          createdAt: DateTime.now(),
          createdBy: 'ed_admin',
        ),
      ]);
    }

    if (withBonus) {
      await StorageService.saveBonuses([
        Bonus(
          id: 'ed_bonus_available',
          name: bonusName,
          description: 'Widget-test bonus, mock only',
          pointsRequired: 50,
          status: BonusStatus.available,
          createdAt: DateTime.now(),
          companyId: company.id,
        ),
      ]);
    }

    await StorageService.savePointsTransactions([
      PointsTransaction(
        id: 'ed_points_earned',
        userId: employee.id,
        type: PointsTransactionType.earned,
        points: 75,
        description: 'Test earned points',
        date: DateTime.now(),
        companyId: company.id,
      ),
    ]);

    await StorageService.setCurrentUser(employee);
    appProvider = AppProvider();
    await appProvider.initialize();
  }

  Future<void> pumpDashboard(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ChangeNotifierProvider<AppProvider>.value(
        value: appProvider,
        child: const MaterialApp(home: EmployeeDashboard()),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  Finder bottomNav() => find.byType(BottomNavigationBar);

  Finder navIcon(IconData icon) =>
      find.descendant(of: bottomNav(), matching: find.byIcon(icon));

  int navIndex(WidgetTester tester) =>
      tester.widget<BottomNavigationBar>(bottomNav()).currentIndex;

  tearDown(() async {
    await StorageService.clearAllData();
  });

  group('EmployeeDashboard chrome and nav', () {
    setUp(() async {
      await seed();
    });

    testWidgets('renders app bar, employee header, and default bottom tabs',
        (tester) async {
      await pumpDashboard(tester);

      expect(find.text('Employee Dashboard'), findsOneWidget);
      expect(find.text(employeeName), findsWidgets);
      expect(find.byTooltip('Settings'), findsOneWidget);

      expect(bottomNav(), findsOneWidget);
      expect(navIcon(Icons.dashboard), findsOneWidget);
      expect(navIcon(Icons.track_changes), findsOneWidget);
      expect(navIcon(Icons.card_giftcard), findsOneWidget);
      expect(navIcon(Icons.analytics), findsOneWidget);
      expect(navIcon(Icons.person), findsOneWidget);
      // Messages is hidden in the default bottom bar (header shortcut instead).
      expect(navIcon(Icons.message), findsNothing);
      expect(navIndex(tester), 0);
    });

    testWidgets('bottom nav switches Overview, Targets, Bonuses, Settings',
        (tester) async {
      await pumpDashboard(tester);

      expect(find.text("Today's Targets").hitTestable(), findsOneWidget);

      await tester.tap(navIcon(Icons.track_changes));
      await tester.pump();
      expect(navIndex(tester), 1);
      expect(find.text('Your Personal Target').hitTestable(), findsWidgets);

      await tester.tap(navIcon(Icons.card_giftcard));
      await tester.pump();
      expect(navIndex(tester), 2);
      expect(find.text('Your Points').hitTestable(), findsOneWidget);
      expect(find.text(bonusName).hitTestable(), findsOneWidget);

      await tester.tap(navIcon(Icons.analytics));
      await tester.pump();
      expect(navIndex(tester), 3);
      expect(find.text('Settings & Analytics').hitTestable(), findsOneWidget);
    });

    testWidgets('app bar settings icon opens the Settings tab', (tester) async {
      await pumpDashboard(tester);

      await tester.tap(find.byTooltip('Settings'));
      await tester.pump();

      expect(navIndex(tester), 3);
      expect(find.text('Settings & Analytics').hitTestable(), findsOneWidget);
      expect(find.text('Personal Settings').hitTestable(), findsOneWidget);
    });

    testWidgets('header shortcuts include Calendar and Messages',
        (tester) async {
      await pumpDashboard(tester);

      expect(find.text('Calendar').hitTestable(), findsOneWidget);
      expect(find.text('Messages').hitTestable(), findsOneWidget);
      // Messages lives in the header; default bottom bar hides it.
      expect(navIcon(Icons.message), findsNothing);
    });

    testWidgets('Profile tab shows the employee profile', (tester) async {
      await pumpDashboard(tester);

      await tester.tap(navIcon(Icons.person));
      await tester.pump();

      expect(navIndex(tester), 4);
      expect(find.text('Personal Information').hitTestable(), findsOneWidget);
      expect(find.text('pat.dashboard@test.com').hitTestable(), findsWidgets);
      expect(find.text('Full Name').hitTestable(), findsOneWidget);
    });
  });

  group('EmployeeDashboard overview and targets', () {
    testWidgets('overview shows today\'s assigned target', (tester) async {
      await seed();
      await pumpDashboard(tester);

      expect(find.text("Today's Targets"), findsWidgets);
      expect(find.text("Today's Sales Targets"), findsOneWidget);
      expect(find.text('Previous'), findsOneWidget);
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);
      expect(find.text('Your Personal Target'), findsWidgets);
      expect(find.text('Assigned to You'), findsWidgets);
      expect(find.byType(TargetCard), findsWidgets);
    });

    testWidgets('overview empty state when the employee has no targets',
        (tester) async {
      await seed(withTarget: false);
      await pumpDashboard(tester);

      expect(find.text('No sales targets set for today').hitTestable(),
          findsOneWidget);
      expect(find.text('Targets will appear here when assigned').hitTestable(),
          findsOneWidget);
    });

    testWidgets('date Next shows selected-date empty copy', (tester) async {
      await seed();
      await pumpDashboard(tester);

      await tester.tap(find.text('Next'));
      await tester.pump();

      expect(
          find.text('Targets for Selected Date').hitTestable(), findsOneWidget);
      expect(find.text('No sales targets for selected date').hitTestable(),
          findsOneWidget);
    });

    testWidgets('Submit Sales dialog can be opened and cancelled',
        (tester) async {
      await seed();
      await pumpDashboard(tester);

      expect(find.text('Submit Sales').hitTestable(), findsOneWidget);
      expect(find.text('Add Team').hitTestable(), findsOneWidget);

      await tester.tap(find.text('Submit Sales').hitTestable());
      await tester.pump();

      expect(find.widgetWithText(AlertDialog, 'Submit Sales'), findsOneWidget);
      expect(find.text('Your Actual Sales (\$)'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Cancel'), findsOneWidget);

      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pump();

      expect(find.widgetWithText(AlertDialog, 'Submit Sales'), findsNothing);
      expect(find.text('Employee Dashboard'), findsOneWidget);
    });

    testWidgets('Targets tab lists the assigned target card', (tester) async {
      await seed();
      await pumpDashboard(tester);

      await tester.tap(navIcon(Icons.track_changes));
      await tester.pump();

      expect(navIndex(tester), 1);
      expect(find.text('No targets for today').hitTestable(), findsNothing);
      expect(find.text('Your Personal Target').hitTestable(), findsWidgets);
      expect(
        find.text('of \$${targetAmount.toStringAsFixed(0)}').hitTestable(),
        findsWidgets,
      );
    });
  });

  group('EmployeeDashboard bonuses', () {
    testWidgets('Bonuses tab shows points, Available chip, and gift card',
        (tester) async {
      await seed();
      await pumpDashboard(tester);

      await tester.tap(navIcon(Icons.card_giftcard));
      await tester.pump();

      expect(find.text('Your Points').hitTestable(), findsOneWidget);
      expect(find.text('75').hitTestable(), findsWidgets);
      expect(find.text('Available').hitTestable(), findsOneWidget);
      expect(find.text('Redeemed').hitTestable(), findsOneWidget);
      expect(find.text(bonusName).hitTestable(), findsOneWidget);
      expect(find.text('Widget-test bonus, mock only').hitTestable(),
          findsOneWidget);
      expect(find.text('50 points').hitTestable(), findsOneWidget);
    });

    testWidgets('Redeemed toggle shows empty claimed state', (tester) async {
      await seed();
      await pumpDashboard(tester);

      await tester.tap(navIcon(Icons.card_giftcard));
      await tester.pump();
      await tester.tap(find.text('Redeemed').hitTestable());
      await tester.pump();

      expect(find.text('No bonuses claimed yet').hitTestable(), findsOneWidget);
      expect(find.text('Start earning points to claim bonuses!').hitTestable(),
          findsOneWidget);
    });

    testWidgets('empty available-bonuses copy when none exist', (tester) async {
      await seed(withBonus: false);
      await pumpDashboard(tester);

      await tester.tap(navIcon(Icons.card_giftcard));
      await tester.pump();

      expect(find.text('No bonuses available').hitTestable(), findsOneWidget);
      expect(find.text('Bonuses will appear here when created').hitTestable(),
          findsOneWidget);
    });
  });

  group('EmployeeDashboard settings', () {
    setUp(() async {
      await seed();
    });

    testWidgets('settings lists personal, nav, and analytics sections',
        (tester) async {
      await pumpDashboard(tester);
      await tester.tap(find.byTooltip('Settings'));
      await tester.pump();

      expect(find.text('Settings & Analytics').hitTestable(), findsOneWidget);
      expect(find.text('Personal Settings').hitTestable(), findsOneWidget);
      expect(find.text('Edit Profile').hitTestable(), findsOneWidget);
      expect(find.text('View Employees').hitTestable(), findsOneWidget);
      expect(find.text('Dark Mode').hitTestable(), findsOneWidget);
      expect(find.text('Logout').hitTestable(), findsOneWidget);
      expect(find.text('Customize Navigation'), findsOneWidget);
      expect(find.text('Customize Bottom Bar'), findsOneWidget);
      expect(find.text('Required - cannot be disabled'), findsOneWidget);
    });

    testWidgets('Logout opens a confirm dialog that can be cancelled',
        (tester) async {
      await pumpDashboard(tester);
      await tester.tap(find.byTooltip('Settings'));
      await tester.pump();

      await tester.tap(find.text('Sign out of your account').hitTestable());
      await tester.pump();

      expect(find.text('Are you sure you want to logout?'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Logout'), findsOneWidget);

      await tester.tap(find.widgetWithText(TextButton, 'Cancel').first);
      await tester.pump();

      expect(find.text('Are you sure you want to logout?'), findsNothing);
      expect(find.text('Employee Dashboard'), findsOneWidget);
      expect(appProvider.currentUser, isNotNull);
    });

    testWidgets('Dark Mode switch enables dark mode', (tester) async {
      await pumpDashboard(tester);
      await tester.tap(find.byTooltip('Settings'));
      await tester.pump();

      expect(appProvider.isDarkMode, isFalse);
      expect(find.text('Disabled').hitTestable(), findsOneWidget);

      final darkModeRow = find.ancestor(
        of: find.text('Dark Mode'),
        matching: find.byType(Row),
      );
      await tester.tap(find.descendant(
        of: darkModeRow,
        matching: find.byType(Switch),
      ));
      await tester.pump();

      expect(appProvider.isDarkMode, isTrue);
      expect(find.text('Enabled').hitTestable(), findsOneWidget);
    });
  });
}
