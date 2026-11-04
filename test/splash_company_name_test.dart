import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:bonuses/models/company.dart';
import 'package:bonuses/models/user.dart';
import 'package:bonuses/utils/splash_company_name.dart';

String _mustRead(List<String> relativePaths) {
  for (final relative in relativePaths) {
    final candidates = [
      File(relative),
      File('${Directory.current.path}/$relative'),
    ];
    for (final file in candidates) {
      if (file.existsSync()) {
        return file.readAsStringSync();
      }
    }
  }
  fail(
    'Could not read ${relativePaths.join(" or ")} from ${Directory.current.path}',
  );
}

/// Body of `_getCompanyName` in lib/main.dart (splash branding only).
String _getCompanyNameMethod(String mainSource) {
  const startMarker = 'Future<String?> _getCompanyName';
  const endMarker = 'Future<List<Company>> _getUserActiveCompanies';
  final start = mainSource.indexOf(startMarker);
  final end = mainSource.indexOf(endMarker);
  expect(start, greaterThanOrEqualTo(0),
      reason: 'lib/main.dart must define _getCompanyName');
  expect(end, greaterThan(start),
      reason: '_getCompanyName must end before _getUserActiveCompanies');
  return mainSource.substring(start, end);
}

User _user({
  required String id,
  required UserRole role,
  List<String> companyIds = const [],
  List<String> companyNames = const [],
  String? primaryCompanyId,
}) {
  return User(
    id: id,
    name: id,
    email: '$id@example.com',
    role: role,
    createdAt: DateTime(2026, 1, 1),
    companyIds: companyIds,
    companyNames: companyNames,
    primaryCompanyId: primaryCompanyId,
  );
}

Company _company(String id, String name) {
  return Company(
    id: id,
    name: name,
    adminUserId: 'admin-$id',
    createdAt: DateTime(2026, 1, 1),
  );
}

void main() {
  final otherTenant = _company('co-alpha', 'Alpha Tenant');
  final signedInCompany = _company('co-beta', 'Beta Tenant');
  final companies = [otherTenant, signedInCompany];

  test('logged-out splash does not use another tenant from companies.first', () {
    expect(
      resolveSplashCompanyName(currentUser: null, companies: companies),
      'Bonuses',
    );
  });

  test('super-admin splash uses the app name', () {
    final superAdmin = _user(
      id: 'sa',
      role: UserRole.superAdmin,
      companyIds: ['co-beta'],
      companyNames: ['Beta Tenant'],
      primaryCompanyId: 'co-beta',
    );
    expect(
      resolveSplashCompanyName(currentUser: superAdmin, companies: companies),
      'Bonuses',
    );
  });

  test('signed-in user splash uses primary company, not users/companies.first',
      () {
    final signedIn = _user(
      id: 'emp-beta',
      role: UserRole.employee,
      companyIds: ['co-gamma', 'co-beta'],
      companyNames: ['Gamma Tenant', 'Beta Tenant'],
      primaryCompanyId: 'co-beta',
    );
    expect(
      resolveSplashCompanyName(currentUser: signedIn, companies: companies),
      'Beta Tenant',
    );
  });

  test('looks up company name by primaryCompanyId when names are missing', () {
    final signedIn = _user(
      id: 'admin-beta',
      role: UserRole.admin,
      companyIds: ['co-beta'],
      companyNames: const [],
      primaryCompanyId: 'co-beta',
    );
    expect(
      resolveSplashCompanyName(currentUser: signedIn, companies: companies),
      'Beta Tenant',
    );
  });

  test('does not brand from a company the signed-in user does not belong to',
      () {
    final signedIn = _user(
      id: 'emp-none',
      role: UserRole.employee,
      companyIds: const [],
      companyNames: const [],
      primaryCompanyId: 'co-alpha',
    );
    expect(
      resolveSplashCompanyName(currentUser: signedIn, companies: companies),
      'Bonuses',
    );
  });

  test('falls back to the signed-in user companyNames when primary is missing',
      () {
    final signedIn = _user(
      id: 'emp-gamma',
      role: UserRole.employee,
      companyIds: ['co-gamma'],
      companyNames: ['Gamma Tenant'],
    );
    expect(
      resolveSplashCompanyName(currentUser: signedIn, companies: companies),
      'Gamma Tenant',
    );
  });

  test('empty primary name falls through to that user company lookup', () {
    final signedIn = _user(
      id: 'emp-beta',
      role: UserRole.employee,
      companyIds: ['co-beta'],
      companyNames: [''],
      primaryCompanyId: 'co-beta',
    );
    expect(
      resolveSplashCompanyName(currentUser: signedIn, companies: companies),
      'Beta Tenant',
    );
  });

  group('AppWrapper splash wiring (BON-26)', () {
    late String mainSource;
    late String getCompanyName;
    late String productWorkflow;

    setUpAll(() {
      mainSource = _mustRead(['lib/main.dart']);
      getCompanyName = _getCompanyNameMethod(mainSource);
      productWorkflow = _mustRead(['.github/workflows/flutter-tests.yml']);
    });

    test('_getCompanyName uses resolveSplashCompanyName, not users.first', () {
      expect(mainSource, contains('resolveSplashCompanyName'));
      expect(getCompanyName, contains('currentUser'));
      expect(getCompanyName, isNot(contains('users.first')));
      expect(getCompanyName, isNot(contains('getUsers(')));
      expect(getCompanyName, isNot(contains('companies.first')));
      expect(getCompanyName, isNot(contains("'Utilif'")));
    });

    test('splash contract tests are included in product CI', () {
      final excludeMatch =
          RegExp(r"EXCLUDE='([^']+)'").firstMatch(productWorkflow);
      expect(excludeMatch, isNotNull,
          reason: 'product CI must name exclusions');
      expect(
        excludeMatch!.group(1),
        isNot(contains('splash_company_name')),
        reason: 'test/splash_company_name_test.dart must run in CI',
      );
    });
  });
}
