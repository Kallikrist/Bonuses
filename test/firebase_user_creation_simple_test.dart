import 'package:flutter_test/flutter_test.dart';
import 'package:bonuses/models/user.dart' as models;
import 'package:bonuses/models/company.dart';

void main() {
  group('Firebase User Creation Tests (Simple)', () {
    test('Create test company model', () {
      final company = Company(
        id: 'test_company_1',
        name: 'TestCompany1',
        adminUserId: 'test_admin_1',
        createdAt: DateTime.now(),
        isActive: true,
      );

      expect(company.id, equals('test_company_1'));
      expect(company.name, equals('TestCompany1'));
      expect(company.isActive, isTrue);
      expect(company.adminUserId, equals('test_admin_1'));

      print('✅ Created test company: ${company.name}');
    });

    test('Create kallikrist@test.is user model', () {
      final user = models.User(
        id: 'test_user_1',
        name: 'Kalli Krist',
        email: 'kallikrist@test.is',
        role: models.UserRole.employee,
        createdAt: DateTime.now(),
        workplaceIds: [],
        workplaceNames: [],
        companyIds: ['test_company_1'],
        companyNames: ['TestCompany1'],
        primaryCompanyId: 'test_company_1',
        companyRoles: {'test_company_1': 'employee'},
        companyPoints: {'test_company_1': 0},
      );

      expect(user.email, equals('kallikrist@test.is'));
      expect(user.name, equals('Kalli Krist'));
      expect(user.role, equals(models.UserRole.employee));
      expect(user.companyIds, contains('test_company_1'));
      expect(user.primaryCompanyId, equals('test_company_1'));

      print('✅ Created user: ${user.email} with role: ${user.role}');
    });

    test('Create additional test users', () {
      final testUsers = [
        {
          'email': 'testuser1@example.com',
          'name': 'Test User 1',
          'role': models.UserRole.employee,
        },
        {
          'email': 'testuser2@example.com',
          'name': 'Test User 2',
          'role': models.UserRole.admin,
        },
        {
          'email': 'testuser3@example.com',
          'name': 'Test User 3',
          'role': models.UserRole.employee,
        },
      ];

      for (final userData in testUsers) {
        final user = models.User(
          id: 'test_user_${userData['email']}',
          name: userData['name'] as String,
          email: userData['email'] as String,
          role: userData['role'] as models.UserRole,
          createdAt: DateTime.now(),
          workplaceIds: [],
          workplaceNames: [],
          companyIds: ['test_company_1'],
          companyNames: ['TestCompany1'],
          primaryCompanyId: 'test_company_1',
          companyRoles: {
            'test_company_1':
                userData['role'] == models.UserRole.admin ? 'admin' : 'employee'
          },
          companyPoints: {'test_company_1': 0},
        );

        expect(user.email, equals(userData['email']));
        expect(user.name, equals(userData['name']));
        expect(user.role, equals(userData['role']));

        print('✅ Created user: ${user.email} with role: ${user.role}');
      }
    });

    test('Verify user model JSON serialization', () {
      final user = models.User(
        id: 'test_user_1',
        name: 'Kalli Krist',
        email: 'kallikrist@test.is',
        role: models.UserRole.employee,
        createdAt: DateTime.now(),
        workplaceIds: [],
        workplaceNames: [],
        companyIds: ['test_company_1'],
        companyNames: ['TestCompany1'],
        primaryCompanyId: 'test_company_1',
        companyRoles: {'test_company_1': 'employee'},
        companyPoints: {'test_company_1': 0},
      );

      // Test JSON serialization
      final json = user.toJson();
      expect(json['email'], equals('kallikrist@test.is'));
      expect(json['name'], equals('Kalli Krist'));
      expect(json['role'], equals('employee'));
      expect(json['companyIds'], contains('test_company_1'));
      expect(json['primaryCompanyId'], equals('test_company_1'));

      // Test JSON deserialization
      final userFromJson = models.User.fromJson(json);
      expect(userFromJson.email, equals(user.email));
      expect(userFromJson.name, equals(user.name));
      expect(userFromJson.role, equals(user.role));
      expect(userFromJson.companyIds, equals(user.companyIds));
      expect(userFromJson.primaryCompanyId, equals(user.primaryCompanyId));

      print('✅ User JSON serialization/deserialization successful');
    });

    test('Verify company model JSON serialization', () {
      final company = Company(
        id: 'test_company_1',
        name: 'TestCompany1',
        adminUserId: 'test_admin_1',
        createdAt: DateTime.now(),
        isActive: true,
      );

      // Test JSON serialization
      final json = company.toJson();
      expect(json['id'], equals('test_company_1'));
      expect(json['name'], equals('TestCompany1'));
      expect(json['isActive'], isTrue);
      expect(json['adminUserId'], equals('test_admin_1'));

      // Test JSON deserialization
      final companyFromJson = Company.fromJson(json);
      expect(companyFromJson.id, equals(company.id));
      expect(companyFromJson.name, equals(company.name));
      expect(companyFromJson.isActive, equals(company.isActive));
      expect(companyFromJson.adminUserId, equals(company.adminUserId));

      print('✅ Company JSON serialization/deserialization successful');
    });
  });
}
