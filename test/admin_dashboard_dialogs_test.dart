import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:bonuses/models/company.dart';
import 'package:bonuses/models/sales_target.dart';
import 'package:bonuses/models/user.dart';
import 'package:bonuses/providers/app_provider.dart';
import 'package:bonuses/services/storage_service.dart';
import 'package:bonuses/services/validation_service.dart';
import 'test_helpers.dart';

/// Isolated dialog pumps (Designer: full AdminDashboard hangs on pumpAndSettle).
/// Trees match `_showCreateCompanyDialog` / `_showEditTargetDialog` on 5ca47c5:
/// AlertDialog.actions are direct children, not a nested Row.
void main() {
  setupSharedPreferencesMock();

  group('BON-3 source: actions are AlertDialog parameters', () {
    late String source;
    late String createMethod;
    late String editMethod;

    setUpAll(() {
      source = File('lib/screens/admin_dashboard.dart').readAsStringSync();
      final createStart = source.indexOf('void _showCreateCompanyDialog');
      final createEnd =
          source.indexOf('void _showEditCompanyDialog', createStart);
      createMethod = source.substring(createStart, createEnd);

      final editStart = source.indexOf('void _showEditTargetDialog');
      final editEnd = source.indexOf(
          'Future<List<CompanySubscription>> _getSubscriptionsWithUpdate');
      editMethod = source.substring(editStart, editEnd);
    });

    test('create-company AlertDialog has actions beside content', () {
      expect(createMethod, contains("title: const Text('Register Your Company')"));
      expect(createMethod, contains('\n        actions:'));
      expect(createMethod, contains("child: const Text('Cancel')"));
      expect(createMethod, contains("child: const Text('Create Company')"));
    });

    test('edit-target actions are unwrapped (no nested Row) so they can wrap',
        () {
      expect(editMethod, contains("title: const Text('Edit Target')"));
      expect(editMethod, contains('\n            actions:'));
      expect(editMethod, contains("const Text('Cancel'"));
      expect(editMethod, contains("const Text('Update'"));
      expect(editMethod, contains("const Text('Delete Target'"));

      final actionsStart = editMethod.indexOf('\n            actions:');
      final actionsBlock = editMethod.substring(actionsStart);
      expect(actionsBlock.contains('Row('), isFalse,
          reason: '5ca47c5 unwraps the nested Row so OverflowBar can wrap');
    });
  });

  group('Create-company and edit-target dialogs', () {
    late AppProvider appProvider;
    late User adminUser;
    late SalesTarget todayTarget;
    late List<FlutterErrorDetails> overflows;

    void Function(FlutterErrorDetails)? previousOnError;

    setUp(() async {
      overflows = [];
      previousOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        final text = details.exceptionAsString();
        if (text.contains('overflowed')) {
          overflows.add(details);
        } else {
          previousOnError?.call(details);
        }
      };

      await StorageService.clearAllData();

      final company = Company(
        id: 'dialog_test_company',
        name: 'Dialog Test Co',
        adminUserId: 'dialog_admin',
        createdAt: DateTime.now(),
      );
      adminUser = User(
        id: 'dialog_admin',
        name: 'Dialog Test Admin',
        email: 'dialog.admin@test.com',
        role: UserRole.admin,
        createdAt: DateTime.now(),
        primaryCompanyId: company.id,
        companyIds: [company.id],
        companyNames: [company.name],
        companyRoles: {company.id: 'admin'},
      );
      final now = DateTime.now();
      todayTarget = SalesTarget(
        id: 'dialog_target_today',
        targetAmount: 1000,
        actualAmount: 0,
        date: DateTime(now.year, now.month, now.day),
        companyId: company.id,
        assignedEmployeeId: 'dialog_employee',
        assignedEmployeeName: 'Dialog Test Employee',
        createdAt: DateTime.now(),
        createdBy: adminUser.id,
      );

      for (final email in [
        'admin@store.com',
        'admin@utilif.com',
        'john.doe@example.com',
        'superadmin@platform.com',
      ]) {
        await StorageService.addUser(User(
          id: 'stub_$email',
          name: 'Stub',
          email: email,
          role: UserRole.admin,
          createdAt: DateTime.now(),
        ));
      }

      await StorageService.addCompany(company);
      await StorageService.addUser(adminUser);
      await StorageService.addSalesTarget(todayTarget);
      await StorageService.setCurrentUser(adminUser);

      appProvider = AppProvider();
      await appProvider.initialize();
    });

    tearDown(() async {
      FlutterError.onError = previousOnError;
      await StorageService.clearAllData();
    });

    Future<void> pumpHost(
      WidgetTester tester, {
      required Size size,
      required Widget Function(BuildContext) dialogBuilder,
    }) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();

      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(size: size),
          child: ChangeNotifierProvider<AppProvider>.value(
            value: appProvider,
            child: MaterialApp(
              home: Builder(
                builder: (context) => Scaffold(
                  body: TextButton(
                    onPressed: () {
                      showDialog<void>(
                        context: context,
                        builder: dialogBuilder,
                      );
                    },
                    child: const Text('Open'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
    }

    Widget createCompanyDialog(BuildContext context) {
      final formKey = GlobalKey<FormState>();
      final nameController = TextEditingController();
      return AlertDialog(
        title: const Text('Register Your Company'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: TextFormField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Company Name *'),
              validator: (value) => ValidationService.validateName(value,
                  fieldName: 'Company Name'),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final newCompany = Company(
                id: 'company_${DateTime.now().millisecondsSinceEpoch}',
                name: nameController.text.trim(),
                adminUserId: appProvider.currentUser!.id,
                createdAt: DateTime.now(),
              );
              await appProvider.addCompany(newCompany);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Create Company'),
          ),
        ],
      );
    }

    Widget editTargetDialog(BuildContext context) {
      final formKey = GlobalKey<FormState>();
      final amountController = TextEditingController(
        text: todayTarget.targetAmount.toString(),
      );
      return AlertDialog(
        title: const Text('Edit Target'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: TextFormField(
              controller: amountController,
              decoration:
                  const InputDecoration(labelText: 'Target Amount (\$) *'),
              validator: (value) => ValidationService.validateNumeric(
                value,
                fieldName: 'Target Amount',
                min: 0.01,
                max: 10000000.0,
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(fontSize: 13)),
          ),
          TextButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final amount = double.parse(amountController.text.trim());
              await appProvider.updateSalesTarget(
                todayTarget.copyWith(targetAmount: amount),
              );
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Update', style: TextStyle(fontSize: 13)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete Target', style: TextStyle(fontSize: 13)),
          ),
        ],
      );
    }

    testWidgets('create-company opens, validates, cancels, submits',
        (tester) async {
      await pumpHost(
        tester,
        size: const Size(360, 640),
        dialogBuilder: createCompanyDialog,
      );

      expect(find.text('Register Your Company'), findsOneWidget);
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(overflows, isEmpty);

      await tester.tap(find.text('Create Company'));
      await tester.pumpAndSettle();
      expect(find.text('Company Name is required'), findsOneWidget);
      expect(find.text('Register Your Company'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Register Your Company'), findsNothing);

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Company Name *'),
        'Brand New Co',
      );
      await tester.tap(find.text('Create Company'));
      await tester.pumpAndSettle();
      expect(find.text('Register Your Company'), findsNothing);
      expect(appProvider.companies.any((c) => c.name == 'Brand New Co'), isTrue);
      expect(overflows, isEmpty);
    });

    testWidgets('edit-target opens, validates, cancels, submits',
        (tester) async {
      await pumpHost(
        tester,
        size: const Size(360, 640),
        dialogBuilder: editTargetDialog,
      );

      expect(find.text('Edit Target'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Update'), findsOneWidget);
      expect(find.text('Delete Target'), findsOneWidget);
      expect(overflows, isEmpty);

      await tester.enterText(find.byType(TextFormField), '');
      await tester.tap(find.text('Update'));
      await tester.pumpAndSettle();
      expect(find.text('Target Amount is required'), findsOneWidget);
      expect(find.text('Edit Target'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Edit Target'), findsNothing);
      expect(
        appProvider.salesTargets
            .firstWhere((t) => t.id == todayTarget.id)
            .targetAmount,
        1000,
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), '2500');
      await tester.tap(find.text('Update'));
      await tester.pumpAndSettle();
      expect(find.text('Edit Target'), findsNothing);
      expect(
        appProvider.salesTargets
            .firstWhere((t) => t.id == todayTarget.id)
            .targetAmount,
        2500,
      );
      expect(overflows, isEmpty);
    });

    testWidgets('edit-target actions do not overflow at 360x640 or 1024x768',
        (tester) async {
      for (final size in const [Size(360, 640), Size(1024, 768)]) {
        overflows.clear();
        await pumpHost(tester, size: size, dialogBuilder: editTargetDialog);
        expect(find.text('Edit Target'), findsOneWidget);
        expect(overflows, isEmpty, reason: 'overflow at $size');
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
      }
    });
  });
}
