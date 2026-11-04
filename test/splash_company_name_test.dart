import 'package:flutter_test/flutter_test.dart';
import 'package:bonuses/models/company.dart';
import 'package:bonuses/models/user.dart';
import 'package:bonuses/utils/splash_company_name.dart';

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
}
