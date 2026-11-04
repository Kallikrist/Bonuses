import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bonuses/models/user.dart';
import 'package:bonuses/providers/app_provider.dart';
import 'package:bonuses/screens/login_screen.dart';
import 'package:bonuses/services/auth_service.dart';
import 'package:bonuses/services/password_service.dart';
import 'package:bonuses/services/storage_service.dart';

/// Canonical demo accounts shown on the login screen and in README
/// "Login-screen accounts". Must match `initializeSampleData()`.
const loginScreenAccounts = <({String email, String password, String name})>[
  (email: 'admin@store.com', password: 'password123', name: 'Store Manager'),
  (
    email: 'admin@utilif.com',
    password: 'utilif123',
    name: 'Utilif Administrator'
  ),
  (email: 'john.doe@example.com', password: 'password123', name: 'John Doe'),
  (
    email: 'superadmin@platform.com',
    password: 'password123',
    name: 'Platform Administrator'
  ),
];

/// Extra users seeded by `initializeSampleData()` and listed in README
/// "Additional seeded employees". Not required on the login Demo Accounts box.
const additionalSeededEmployees =
    <({String email, String password, String name})>[
  (
    email: 'jane.smith@example.com',
    password: 'password123',
    name: 'Jane Smith'
  ),
  (
    email: 'mike.johnson@example.com',
    password: 'password123',
    name: 'Mike Johnson'
  ),
  (email: 'Karl@Utilif.is', password: 'password123', name: 'Karl Kristjánsson'),
  (email: 'kallikrist@test.is', password: 'demo123', name: 'Kalli Krist'),
];

const staleReadmeEmails = ['john@store.com', 'jane@store.com'];

String _readRepoFile(String relativePath) {
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late String readme;
  late String loginScreenSource;
  late String projectStructure;

  setUpAll(() {
    readme = _readRepoFile('README.md');
    loginScreenSource = _readRepoFile('lib/screens/login_screen.dart');
    final structureStart = readme.indexOf('## Project Structure');
    final structureEnd = readme.indexOf('## Technologies Used');
    expect(structureStart, greaterThanOrEqualTo(0),
        reason: 'README must have a Project Structure section');
    expect(structureEnd, greaterThan(structureStart),
        reason:
            'README Project Structure must be followed by Technologies Used');
    projectStructure = readme.substring(structureStart, structureEnd);
  });

  group('README demo accounts', () {
    test('Getting Started and Demo Accounts list login-screen emails', () {
      expect(readme, contains('## Demo Accounts'));
      expect(readme, contains('## Getting Started'));
      for (final account in loginScreenAccounts) {
        expect(readme, contains(account.email),
            reason: 'README should list ${account.email}');
        expect(readme, contains(account.password),
            reason:
                'README should list the seeded password for ${account.email}');
      }
    });

    test('additional seeded employees are documented', () {
      for (final account in additionalSeededEmployees) {
        expect(readme, contains(account.email),
            reason:
                'README additional seeded list should include ${account.email}');
        expect(readme, contains(account.password),
            reason:
                'README should list the seeded password for ${account.email}');
      }
    });

    test('does not advertise stale store.com demo emails', () {
      for (final email in staleReadmeEmails) {
        expect(readme, isNot(contains(email)),
            reason: 'README should not list stale $email');
      }
    });

    test('project structure mentions current folders without Firebase', () {
      final fenceStart = projectStructure.indexOf('```');
      final fenceEnd = projectStructure.indexOf('```', fenceStart + 3);
      expect(fenceStart, greaterThanOrEqualTo(0));
      expect(fenceEnd, greaterThan(fenceStart));
      final tree = projectStructure.substring(fenceStart, fenceEnd);

      expect(tree, contains('services/'));
      expect(tree, contains('screens/'));
      expect(projectStructure.toLowerCase(), contains('super-admin'));
      expect(projectStructure.toLowerCase(), contains('payment'));
      expect(
        projectStructure,
        contains(
            RegExp(r'Supabase|validation|notifications|passwords|rate limit')),
      );
      expect(tree.toLowerCase(), isNot(contains('firebase')));
      expect(readme, contains('There is no Firebase'));
    });
  });

  group('Login screen demo copy', () {
    test('source lists the same four login-screen accounts', () {
      for (final account in loginScreenAccounts) {
        expect(loginScreenSource, contains(account.email));
        expect(loginScreenSource,
            contains('${account.email} / ${account.password}'));
      }
    });

    testWidgets('Demo Accounts box shows canonical login emails',
        (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => AppProvider(),
          child: const MaterialApp(home: LoginScreen()),
        ),
      );
      await tester.pump();

      expect(find.text('Demo Accounts:'), findsOneWidget);
      for (final account in loginScreenAccounts) {
        expect(find.textContaining(account.email), findsWidgets,
            reason: 'Login Demo Accounts box should show ${account.email}');
        expect(find.textContaining(account.password), findsWidgets,
            reason:
                'Login Demo Accounts box should show password for ${account.email}');
      }
      for (final email in staleReadmeEmails) {
        expect(find.textContaining(email), findsNothing);
      }
    });
  });

  group('initializeSampleData canonical users', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await StorageService.clearAllData();
      await StorageService.initializeSampleData();
    });

    tearDown(() async {
      await AuthService.logout();
    });

    test('seeds every documented demo user', () async {
      final users = await StorageService.getUsers();
      final emails = users.map((u) => u.email).toSet();
      for (final account in [
        ...loginScreenAccounts,
        ...additionalSeededEmployees,
      ]) {
        expect(emails, contains(account.email),
            reason: 'initializeSampleData should seed ${account.email}');
        final user = users.firstWhere((u) => u.email == account.email);
        expect(user.name, account.name);
      }
    });

    test('seeded passwords match README and login copy', () async {
      final users = await StorageService.getUsers();
      for (final account in [
        ...loginScreenAccounts,
        ...additionalSeededEmployees,
      ]) {
        final user = users.firstWhere((u) => u.email == account.email);
        final stored = await StorageService.getPassword(user.id);
        expect(stored, isNotNull,
            reason: '${account.email} should have a stored password');
        expect(
          PasswordService.verifyPassword(account.password, stored!),
          isTrue,
          reason: '${account.email} password should remain ${account.password}',
        );
      }
    });

    test('canonical login-screen accounts can sign in', () async {
      for (final account in loginScreenAccounts) {
        await AuthService.logout();
        final success =
            await AuthService.login(account.email, account.password);
        expect(success, isTrue,
            reason: '${account.email} should log in with the seeded password');
        expect(AuthService.currentUser?.email, account.email);
        if (account.email == 'superadmin@platform.com') {
          expect(AuthService.currentUser?.role, UserRole.superAdmin);
        }
      }
    });
  });

  group('tests do not log in with stale store.com emails', () {
    test('fixtures and login calls use seed emails, not john@store.com', () {
      final testRoot = Directory('test');
      expect(testRoot.existsSync(), isTrue);

      final dartFiles = testRoot
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'))
          .toList();
      expect(dartFiles, isNotEmpty);

      for (final file in dartFiles) {
        final relative = file.path.replaceFirst(RegExp(r'^(\./)?'), '');
        if (relative.endsWith('demo_accounts_alignment_test.dart')) {
          continue;
        }
        final source = file.readAsStringSync();
        for (final email in staleReadmeEmails) {
          expect(
            source.contains(email),
            isFalse,
            reason: '$relative still uses stale $email; use seed/README emails',
          );
        }
      }
    });
  });
}
