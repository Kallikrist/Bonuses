import '../services/storage_service.dart';
import '../services/supabase_service.dart';
import '../models/user.dart' as models;
import '../models/company.dart';
import '../models/sales_target.dart';
import '../models/points_transaction.dart';
import '../models/bonus.dart';
import '../models/workplace.dart';
import '../models/message.dart';
import '../models/approval_request.dart';

class SupabaseMigrationService {
  /// Migrate all local storage data to Supabase
  static Future<void> migrateAllDataToSupabase() async {
    print('🔄 Starting migration from local storage to Supabase...');

    try {
      // 1. Migrate Users
      await _migrateUsers();

      // 2. Migrate Companies
      await _migrateCompanies();

      // 3. Migrate Workplaces
      await _migrateWorkplaces();

      // 4. Migrate Sales Targets
      await _migrateSalesTargets();

      // 5. Migrate Points Transactions
      await _migratePointsTransactions();

      // 6. Migrate Bonuses
      await _migrateBonuses();

      // 7. Migrate Messages
      await _migrateMessages();

      // 8. Migrate Approval Requests
      await _migrateApprovalRequests();

      print('✅ Migration completed successfully!');
      print('ℹ️ All data has been migrated to Supabase');
    } catch (e) {
      print('❌ Migration failed: $e');
      rethrow;
    }
  }

  static Future<void> _migrateUsers() async {
    print('🔄 Migrating users...');
    final users = await StorageService.getUsers();

    for (final user in users) {
      try {
        await SupabaseService.createUser(user);
        print('✅ Migrated user: ${user.email}');
      } catch (e) {
        print('⚠️ Failed to migrate user ${user.email}: $e');
      }
    }

    print('✅ Users migration completed');
  }

  static Future<void> _migrateCompanies() async {
    print('🔄 Migrating companies...');
    final companies = await StorageService.getCompanies();

    for (final company in companies) {
      try {
        await SupabaseService.createCompany(company);
        print('✅ Migrated company: ${company.name}');
      } catch (e) {
        print('⚠️ Failed to migrate company ${company.name}: $e');
      }
    }

    print('✅ Companies migration completed');
  }

  static Future<void> _migrateWorkplaces() async {
    print('🔄 Migrating workplaces...');
    final workplaces = await StorageService.getWorkplaces();

    for (final workplace in workplaces) {
      try {
        await SupabaseService.createWorkplace(workplace);
        print('✅ Migrated workplace: ${workplace.name}');
      } catch (e) {
        print('⚠️ Failed to migrate workplace ${workplace.name}: $e');
      }
    }

    print('✅ Workplaces migration completed');
  }

  static Future<void> _migrateSalesTargets() async {
    print('🔄 Migrating sales targets...');
    final targets = await StorageService.getSalesTargets();

    for (final target in targets) {
      try {
        await SupabaseService.createSalesTarget(target);
        print('✅ Migrated sales target: ${target.id}');
      } catch (e) {
        print('⚠️ Failed to migrate sales target ${target.id}: $e');
      }
    }

    print('✅ Sales targets migration completed');
  }

  static Future<void> _migratePointsTransactions() async {
    print('🔄 Migrating points transactions...');
    final transactions = await StorageService.getPointsTransactions();

    for (final transaction in transactions) {
      try {
        await SupabaseService.createPointsTransaction(transaction);
        print('✅ Migrated points transaction: ${transaction.id}');
      } catch (e) {
        print('⚠️ Failed to migrate points transaction ${transaction.id}: $e');
      }
    }

    print('✅ Points transactions migration completed');
  }

  static Future<void> _migrateBonuses() async {
    print('🔄 Migrating bonuses...');
    final bonuses = await StorageService.getBonuses();

    for (final bonus in bonuses) {
      try {
        await SupabaseService.createBonus(bonus);
        print('✅ Migrated bonus: ${bonus.name}');
      } catch (e) {
        print('⚠️ Failed to migrate bonus ${bonus.name}: $e');
      }
    }

    print('✅ Bonuses migration completed');
  }

  static Future<void> _migrateMessages() async {
    print('🔄 Migrating messages...');
    final messages = await StorageService.getMessages();

    for (final message in messages) {
      try {
        await SupabaseService.createMessage(message);
        print('✅ Migrated message: ${message.id}');
      } catch (e) {
        print('⚠️ Failed to migrate message ${message.id}: $e');
      }
    }

    print('✅ Messages migration completed');
  }

  static Future<void> _migrateApprovalRequests() async {
    print('🔄 Migrating approval requests...');
    final requests = await StorageService.getApprovalRequests();

    for (final request in requests) {
      try {
        await SupabaseService.createApprovalRequest(request);
        print('✅ Migrated approval request: ${request.id}');
      } catch (e) {
        print('⚠️ Failed to migrate approval request ${request.id}: $e');
      }
    }

    print('✅ Approval requests migration completed');
  }

  /// Create demo data in Supabase
  static Future<void> createDemoDataInSupabase() async {
    print('🔄 Creating demo data in Supabase...');

    try {
      // Create demo companies
      final utilifCompany = Company(
        id: 'utilif_company',
        name: 'Utilif',
        adminUserId: 'admin_utilif',
        isActive: true,
        createdAt: DateTime.now(),
      );
      await SupabaseService.createCompany(utilifCompany);

      final testCompany = Company(
        id: 'test_company_1',
        name: 'TestCompany1',
        adminUserId: 'admin_test',
        isActive: true,
        createdAt: DateTime.now(),
      );
      await SupabaseService.createCompany(testCompany);

      // Create demo users
      final superAdmin = models.User(
        id: 'superadmin_1',
        name: 'Super Admin',
        email: 'superadmin@platform.com',
        role: models.UserRole.superAdmin,
        createdAt: DateTime.now(),
      );
      await SupabaseService.createUser(superAdmin);

      final utilifAdmin = models.User(
        id: 'admin_utilif',
        name: 'Utilif Admin',
        email: 'admin@utilif.com',
        role: models.UserRole.admin,
        createdAt: DateTime.now(),
        companyIds: ['utilif_company'],
        companyNames: ['Utilif'],
        primaryCompanyId: 'utilif_company',
        companyRoles: {'utilif_company': 'admin'},
      );
      await SupabaseService.createUser(utilifAdmin);

      final testUser = models.User(
        id: 'test_user_1',
        name: 'Kalli Krist',
        email: 'kallikrist@test.is',
        role: models.UserRole.employee,
        createdAt: DateTime.now(),
        companyIds: ['test_company_1'],
        companyNames: ['TestCompany1'],
        primaryCompanyId: 'test_company_1',
        companyRoles: {'test_company_1': 'employee'},
      );
      await SupabaseService.createUser(testUser);

      print('✅ Demo data created in Supabase');
    } catch (e) {
      print('❌ Failed to create demo data: $e');
      rethrow;
    }
  }

  /// Test Supabase connection
  static Future<bool> testConnection() async {
    try {
      print('🔄 Testing Supabase connection...');

      // Try to get users (this will test the connection)
      await SupabaseService.getUsers();

      print('✅ Supabase connection successful');
      return true;
    } catch (e) {
      print('❌ Supabase connection failed: $e');
      return false;
    }
  }
}
