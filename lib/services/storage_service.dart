import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/sales_target.dart';
import '../models/points_transaction.dart';
import '../models/bonus.dart';
import '../models/workplace.dart';
import '../models/company.dart';
import '../models/approval_request.dart';
import '../models/points_rules.dart';
import '../models/message.dart';

class StorageService {
  static const String _usersKey = 'users';
  static const String _currentUserKey = 'current_user';
  static const String _salesTargetsKey = 'sales_targets';
  static const String _pointsTransactionsKey = 'points_transactions';
  static const String _bonusesKey = 'bonuses';
  static const String _workplacesKey = 'workplaces';
  static const String _companiesKey = 'companies';
  static const String _approvalRequestsKey = 'approval_requests';
  static const String _pointsRulesKey = 'points_rules';
  static const String _messagesKey = 'messages';
  static const String _onboardingCompleteKey = 'onboarding_complete';
  static const String _passwordsKey = 'user_passwords'; // Map<userId, password>
  static const String _darkModeKey = 'dark_mode';

  static Future<SharedPreferences> get _prefs async =>
      await SharedPreferences.getInstance();

  // User management
  static Future<List<User>> getUsers() async {
    final prefs = await _prefs;
    final usersJson = prefs.getStringList(_usersKey) ?? [];
    return usersJson.map((json) => User.fromJson(jsonDecode(json))).toList();
  }

  static Future<void> saveUsers(List<User> users) async {
    final prefs = await _prefs;
    final usersJson = users.map((user) => jsonEncode(user.toJson())).toList();
    await prefs.setStringList(_usersKey, usersJson);
  }

  static Future<void> addUser(User user) async {
    final users = await getUsers();
    users.add(user);
    await saveUsers(users);
  }

  static Future<void> updateUser(User user) async {
    final users = await getUsers();
    final index = users.indexWhere((u) => u.id == user.id);
    if (index != -1) {
      users[index] = user;
      await saveUsers(users);
    }
  }

  static Future<void> deleteUser(String userId) async {
    final users = await getUsers();
    users.removeWhere((u) => u.id == userId);
    await saveUsers(users);
  }

  static Future<User?> getCurrentUser() async {
    final prefs = await _prefs;
    final userJson = prefs.getString(_currentUserKey);
    if (userJson != null) {
      return User.fromJson(jsonDecode(userJson));
    }
    return null;
  }

  static Future<void> setCurrentUser(User user) async {
    final prefs = await _prefs;
    await prefs.setString(_currentUserKey, jsonEncode(user.toJson()));
  }

  static Future<void> clearCurrentUser() async {
    final prefs = await _prefs;
    await prefs.remove(_currentUserKey);
  }

  // Points rules - company-specific
  static Future<Map<String, PointsRules>> getCompanyPointsRules() async {
    final prefs = await _prefs;
    final jsonStr = prefs.getString(_pointsRulesKey);
    if (jsonStr == null) return {};
    try {
      final Map<String, dynamic> jsonMap = jsonDecode(jsonStr);
      return jsonMap.map((key, value) =>
          MapEntry(key, PointsRules.fromJson(value as Map<String, dynamic>)));
    } catch (_) {
      return {};
    }
  }

  static Future<void> setCompanyPointsRules(
      Map<String, PointsRules> companyRules) async {
    final prefs = await _prefs;
    final jsonMap =
        companyRules.map((key, value) => MapEntry(key, value.toJson()));
    await prefs.setString(_pointsRulesKey, jsonEncode(jsonMap));
  }

  // Backward compatibility - kept for migration
  static Future<PointsRules> getPointsRules() async {
    final prefs = await _prefs;
    final jsonStr = prefs.getString(_pointsRulesKey);
    if (jsonStr == null) return PointsRules.defaults();
    try {
      return PointsRules.fromJson(jsonDecode(jsonStr));
    } catch (_) {
      return PointsRules.defaults();
    }
  }

  static Future<void> setPointsRules(PointsRules rules) async {
    final prefs = await _prefs;
    await prefs.setString(_pointsRulesKey, jsonEncode(rules.toJson()));
  }

  // Sales targets management
  static Future<List<SalesTarget>> getSalesTargets() async {
    final prefs = await _prefs;
    final targetsJson = prefs.getStringList(_salesTargetsKey) ?? [];
    return targetsJson
        .map((json) => SalesTarget.fromJson(jsonDecode(json)))
        .toList();
  }

  static Future<void> saveSalesTargets(List<SalesTarget> targets) async {
    final prefs = await _prefs;
    final targetsJson =
        targets.map((target) => jsonEncode(target.toJson())).toList();
    await prefs.setStringList(_salesTargetsKey, targetsJson);
  }

  static Future<void> addSalesTarget(SalesTarget target) async {
    print(
        'DEBUG: StorageService - Adding target with assignment - Employee: ${target.assignedEmployeeName}, Workplace: ${target.assignedWorkplaceName}');
    final targets = await getSalesTargets();
    targets.add(target);
    await saveSalesTargets(targets);
    print(
        'DEBUG: StorageService - Target saved. Total targets: ${targets.length}');
  }

  static Future<void> updateSalesTarget(SalesTarget target) async {
    print('DEBUG: StorageService - Updating target ${target.id}');
    print(
        'DEBUG: StorageService - Collaborative IDs: ${target.collaborativeEmployeeIds}');
    print(
        'DEBUG: StorageService - Collaborative Names: ${target.collaborativeEmployeeNames}');
    final targets = await getSalesTargets();
    final index = targets.indexWhere((t) => t.id == target.id);
    if (index != -1) {
      targets[index] = target;
      await saveSalesTargets(targets);
      print('DEBUG: StorageService - Target updated successfully');
    } else {
      print('DEBUG: StorageService - Target not found for update');
    }
  }

  static Future<void> deleteSalesTarget(String targetId) async {
    final targets = await getSalesTargets();
    targets.removeWhere((t) => t.id == targetId);
    await saveSalesTargets(targets);
  }

  static Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_salesTargetsKey);
    await prefs.remove(_usersKey);
    await prefs.remove(_pointsTransactionsKey);
    await prefs.remove(_bonusesKey);
    await prefs.remove(_workplacesKey);
    await prefs.remove(_companiesKey);
    await prefs.remove(_currentUserKey);
    await prefs.remove(_messagesKey);
  }

  // Points transactions management
  static Future<List<PointsTransaction>> getPointsTransactions() async {
    final prefs = await _prefs;
    final transactionsJson = prefs.getStringList(_pointsTransactionsKey) ?? [];
    return transactionsJson
        .map((json) => PointsTransaction.fromJson(jsonDecode(json)))
        .toList();
  }

  static Future<void> savePointsTransactions(
      List<PointsTransaction> transactions) async {
    final prefs = await _prefs;
    final transactionsJson = transactions
        .map((transaction) => jsonEncode(transaction.toJson()))
        .toList();
    await prefs.setStringList(_pointsTransactionsKey, transactionsJson);
  }

  static Future<void> addPointsTransaction(
      PointsTransaction transaction) async {
    final transactions = await getPointsTransactions();
    transactions.add(transaction);
    await savePointsTransactions(transactions);
  }

  // Bonuses management
  static Future<List<Bonus>> getBonuses() async {
    final prefs = await _prefs;
    final bonusesJson = prefs.getStringList(_bonusesKey) ?? [];
    return bonusesJson.map((json) => Bonus.fromJson(jsonDecode(json))).toList();
  }

  static Future<void> saveBonuses(List<Bonus> bonuses) async {
    final prefs = await _prefs;
    final bonusesJson =
        bonuses.map((bonus) => jsonEncode(bonus.toJson())).toList();
    await prefs.setStringList(_bonusesKey, bonusesJson);
  }

  static Future<void> addBonus(Bonus bonus) async {
    final bonuses = await getBonuses();
    bonuses.add(bonus);
    await saveBonuses(bonuses);
  }

  static Future<void> updateBonus(Bonus bonus) async {
    final bonuses = await getBonuses();
    final index = bonuses.indexWhere((b) => b.id == bonus.id);
    if (index != -1) {
      bonuses[index] = bonus;
      await saveBonuses(bonuses);
    }
  }

  static Future<void> deleteBonus(String bonusId) async {
    final bonuses = await getBonuses();
    bonuses.removeWhere((b) => b.id == bonusId);
    await saveBonuses(bonuses);
  }

  // Workplace management
  static Future<List<Workplace>> getWorkplaces() async {
    final prefs = await _prefs;
    final workplacesJson = prefs.getStringList(_workplacesKey) ?? [];
    return workplacesJson
        .map((json) => Workplace.fromJson(jsonDecode(json)))
        .toList();
  }

  static Future<void> saveWorkplaces(List<Workplace> workplaces) async {
    final prefs = await _prefs;
    final workplacesJson =
        workplaces.map((workplace) => jsonEncode(workplace.toJson())).toList();
    await prefs.setStringList(_workplacesKey, workplacesJson);
  }

  static Future<void> addWorkplace(Workplace workplace) async {
    final workplaces = await getWorkplaces();
    workplaces.add(workplace);
    await saveWorkplaces(workplaces);
  }

  static Future<void> updateWorkplace(Workplace workplace) async {
    final workplaces = await getWorkplaces();
    final index = workplaces.indexWhere((w) => w.id == workplace.id);
    if (index != -1) {
      workplaces[index] = workplace;
      await saveWorkplaces(workplaces);
    }
  }

  static Future<void> deleteWorkplace(String workplaceId) async {
    final workplaces = await getWorkplaces();
    workplaces.removeWhere((w) => w.id == workplaceId);
    await saveWorkplaces(workplaces);
  }

  // Company management
  static Future<List<Company>> getCompanies() async {
    final prefs = await _prefs;
    final companiesJson = prefs.getStringList(_companiesKey) ?? [];
    return companiesJson
        .map((json) => Company.fromJson(jsonDecode(json)))
        .toList();
  }

  static Future<void> saveCompanies(List<Company> companies) async {
    final prefs = await _prefs;
    final companiesJson =
        companies.map((company) => jsonEncode(company.toJson())).toList();
    await prefs.setStringList(_companiesKey, companiesJson);
  }

  static Future<void> addCompany(Company company) async {
    final companies = await getCompanies();
    companies.add(company);
    await saveCompanies(companies);
  }

  static Future<void> updateCompany(Company company) async {
    final companies = await getCompanies();
    final index = companies.indexWhere((c) => c.id == company.id);
    if (index != -1) {
      companies[index] = company;
      await saveCompanies(companies);
    }
  }

  static Future<void> deleteCompany(String companyId) async {
    final companies = await getCompanies();
    companies.removeWhere((c) => c.id == companyId);
    await saveCompanies(companies);
  }

  // Run data migrations - called every time app initializes
  static Future<void> runMigrations() async {
    const demoCompanyId = 'demo_company_utilif';

    // Migration: Update existing workplaces without companyId
    final workplaces = await getWorkplaces();
    bool workplacesNeedUpdate = false;
    final updatedWorkplaces = workplaces.map((wp) {
      if (wp.companyId == null || wp.companyId!.isEmpty) {
        workplacesNeedUpdate = true;
        return Workplace(
          id: wp.id,
          name: wp.name,
          address: wp.address,
          createdAt: wp.createdAt,
          companyId: demoCompanyId,
        );
      }
      return wp;
    }).toList();

    if (workplacesNeedUpdate) {
      await saveWorkplaces(updatedWorkplaces);
      print(
          'DEBUG: Migration - Updated ${updatedWorkplaces.length} workplaces with companyId');
    }

    // Migration: Update existing targets without companyId
    final existingTargets = await getSalesTargets();
    bool targetsNeedUpdate = false;
    final updatedTargets = existingTargets.map((target) {
      if (target.companyId == null || target.companyId!.isEmpty) {
        targetsNeedUpdate = true;
        print(
            'DEBUG: Migration - Updating target ${target.id} with companyId: $demoCompanyId');
        return target.copyWith(companyId: demoCompanyId);
      }
      return target;
    }).toList();

    if (targetsNeedUpdate) {
      await saveSalesTargets(updatedTargets);
      print(
          'DEBUG: Migration - Updated ${updatedTargets.where((t) => t.companyId == demoCompanyId).length} targets with companyId');

      // Verify the migration worked
      final verifyTargets = await getSalesTargets();
      final nullCompanyTargets = verifyTargets
          .where((t) => t.companyId == null || t.companyId!.isEmpty)
          .toList();
      if (nullCompanyTargets.isNotEmpty) {
        print(
            'WARNING: Migration failed! Still have ${nullCompanyTargets.length} targets without companyId');
        for (var t in nullCompanyTargets) {
          print('  - Target ${t.id}: companyId=${t.companyId}');
        }
      } else {
        print('DEBUG: Migration verification - All targets now have companyId');
      }
    }
  }

  // Initialize with sample data
  static Future<void> initializeSampleData() async {
    // Create demo company first
    const demoCompanyId = 'demo_company_utilif';
    final companies = await getCompanies();
    if (!companies.any((c) => c.id == demoCompanyId)) {
      final demoCompany = Company(
        id: demoCompanyId,
        name: 'Utilif',
        address: 'Reykjavik, Iceland',
        contactEmail: 'admin@store.com',
        contactPhone: '+354 555 1234',
        adminUserId: 'admin1',
        createdAt: DateTime.now(),
        employeeCount: '11-30',
      );
      await addCompany(demoCompany);
    }

    // Initialize workplaces with company ID
    final workplaces = await getWorkplaces();
    final companyWorkplaces =
        workplaces.where((w) => w.companyId == demoCompanyId).toList();
    if (companyWorkplaces.isEmpty) {
      final sampleWorkplaces = [
        Workplace(
          id: 'wp1',
          name: 'Downtown Store',
          address: '123 Main St, Downtown',
          createdAt: DateTime.now(),
          companyId: demoCompanyId,
        ),
        Workplace(
          id: 'wp2',
          name: 'Mall Location',
          address: '456 Mall Ave, Shopping Center',
          createdAt: DateTime.now(),
          companyId: demoCompanyId,
        ),
        Workplace(
          id: 'wp3',
          name: 'Airport Store',
          address: '789 Airport Blvd, Terminal 2',
          createdAt: DateTime.now(),
          companyId: demoCompanyId,
        ),
      ];
      for (final wp in sampleWorkplaces) {
        await addWorkplace(wp);
      }
    }

    final users = await getUsers();

    // Add or update Karl Kristjánsson if email matches
    User? existingKarl = users.cast<User?>().firstWhere(
          (u) => u?.email == 'Karl@Utilif.is',
          orElse: () => null,
        );

    print('DEBUG: Demo Data - Looking for Karl@Utilif.is');
    print('DEBUG: Demo Data - Found existing Karl: ${existingKarl != null}');

    if (existingKarl != null) {
      print(
          'DEBUG: Demo Data - Karl\'s current companies: ${existingKarl.companyIds}');
      print(
          'DEBUG: Demo Data - Karl\'s current roles: ${existingKarl.companyRoles}');

      // Check if Karl needs to be added/updated in the demo company
      final needsCompanyAdded =
          !existingKarl.companyIds.contains(demoCompanyId);
      final needsRoleSet =
          existingKarl.companyRoles[demoCompanyId] != 'employee';

      if (needsCompanyAdded || needsRoleSet) {
        print(
            'DEBUG: Demo Data - Updating Karl for Utilif company (Add: $needsCompanyAdded, Set Role: $needsRoleSet)');

        final updatedCompanyIds = needsCompanyAdded
            ? [...existingKarl.companyIds, demoCompanyId]
            : existingKarl.companyIds;

        final updatedCompanyNames = needsCompanyAdded
            ? [...existingKarl.companyNames, 'Utilif']
            : existingKarl.companyNames;

        final updatedKarl = existingKarl.copyWith(
          companyIds: updatedCompanyIds,
          companyNames: updatedCompanyNames,
          companyRoles: {
            ...existingKarl.companyRoles,
            demoCompanyId: 'employee', // Always set as employee in demo company
          },
          companyPoints: {
            ...existingKarl.companyPoints,
            demoCompanyId: existingKarl.companyPoints[demoCompanyId] ??
                150, // Give Karl 150 points if not set
          },
        );
        await updateUser(updatedKarl);

        print(
            'DEBUG: Demo Data - Karl updated! New companies: ${updatedKarl.companyIds}');
        print(
            'DEBUG: Demo Data - Karl updated! New roles: ${updatedKarl.companyRoles}');

        existingKarl =
            updatedKarl; // Update reference for current user check below
      } else {
        print(
            'DEBUG: Demo Data - Karl already properly set up in Utilif company');
      }

      // Always check if Karl is current user and sync the current user reference
      final currentUser = await getCurrentUser();
      if (currentUser?.id == existingKarl.id) {
        print(
            'DEBUG: Demo Data - Karl is current user, syncing current user reference');
        print(
            'DEBUG: Demo Data - Syncing Karl with companies: ${existingKarl.companyIds}');
        print(
            'DEBUG: Demo Data - Syncing Karl with roles: ${existingKarl.companyRoles}');
        await setCurrentUser(existingKarl);

        // Verify the save by reading it back
        final verifyCurrentUser = await getCurrentUser();
        print(
            'DEBUG: Demo Data - Verified current user companies after save: ${verifyCurrentUser?.companyIds}');
        print(
            'DEBUG: Demo Data - Verified current user roles after save: ${verifyCurrentUser?.companyRoles}');
      }
    } else {
      print('DEBUG: Demo Data - No existing Karl found');
    }

    // Clean up duplicate users with same email (keep the one with more companies/data)
    final allUsers = await getUsers();
    final emailMap = <String, List<User>>{};

    // Group users by email
    for (var user in allUsers) {
      if (!emailMap.containsKey(user.email)) {
        emailMap[user.email] = [];
      }
      emailMap[user.email]!.add(user);
    }

    // Find and remove duplicates
    for (var email in emailMap.keys) {
      final usersWithEmail = emailMap[email]!;
      if (usersWithEmail.length > 1) {
        print('DEBUG: Found ${usersWithEmail.length} users with email: $email');

        // Sort by number of companies (descending) to keep the one with most data
        usersWithEmail
            .sort((a, b) => b.companyIds.length.compareTo(a.companyIds.length));

        final userToKeep = usersWithEmail.first;
        final usersToRemove = usersWithEmail.skip(1).toList();

        print(
            'DEBUG: Keeping user ${userToKeep.id} with ${userToKeep.companyIds.length} companies');
        print('DEBUG: Removing ${usersToRemove.length} duplicate users');

        for (var duplicateUser in usersToRemove) {
          await deleteUser(duplicateUser.id);
          print('DEBUG: Removed duplicate user ${duplicateUser.id}');
        }

        // If the current user was a duplicate, update to the kept version
        final currentUser = await getCurrentUser();
        if (currentUser != null &&
            usersToRemove.any((u) => u.id == currentUser.id)) {
          await setCurrentUser(userToKeep);
          print('DEBUG: Updated current user to the kept version');
        }
      }
    }

    // Add demo users if they don't exist
    final demoUserIds = ['admin1', 'emp1', 'emp2', 'emp3', 'emp4'];
    final existingDemoUsers =
        users.where((u) => demoUserIds.contains(u.id)).toList();

    if (existingDemoUsers.isEmpty) {
      final sampleUsers = [
        User(
          id: 'admin1',
          name: 'Store Manager',
          email: 'admin@store.com',
          phoneNumber: '+1 (555) 123-4567',
          role: UserRole.admin,
          createdAt: DateTime.now(),
          workplaceIds: ['wp1'],
          workplaceNames: ['Downtown Store'],
          companyIds: [demoCompanyId],
          companyNames: ['Utilif'],
          primaryCompanyId: demoCompanyId,
          companyRoles: {demoCompanyId: 'admin'},
          companyPoints: {demoCompanyId: 200},
        ),
        User(
          id: 'emp1',
          name: 'John Doe',
          email: 'john.doe@example.com',
          phoneNumber: '+1 (555) 234-5678',
          role: UserRole.employee,
          createdAt: DateTime.now(),
          workplaceIds: ['wp1'],
          workplaceNames: ['Downtown Store'],
          companyIds: [demoCompanyId],
          companyNames: ['Utilif'],
          primaryCompanyId: demoCompanyId,
          companyRoles: {demoCompanyId: 'employee'},
          companyPoints: {demoCompanyId: 100},
        ),
        User(
          id: 'emp2',
          name: 'Jane Smith',
          email: 'jane.smith@example.com',
          phoneNumber: '+1 (555) 345-6789',
          role: UserRole.employee,
          createdAt: DateTime.now(),
          workplaceIds: ['wp2'],
          workplaceNames: ['Mall Location'],
          companyIds: [demoCompanyId],
          companyNames: ['Utilif'],
          primaryCompanyId: demoCompanyId,
          companyRoles: {demoCompanyId: 'employee'},
          companyPoints: {demoCompanyId: 75},
        ),
        User(
          id: 'emp3',
          name: 'Mike Johnson',
          email: 'mike.johnson@example.com',
          phoneNumber: '+1 (555) 456-7890',
          role: UserRole.employee,
          createdAt: DateTime.now(),
          workplaceIds: ['wp3'],
          workplaceNames: ['Airport Store'],
          companyIds: [demoCompanyId],
          companyNames: ['Utilif'],
          primaryCompanyId: demoCompanyId,
          companyRoles: {demoCompanyId: 'employee'},
          companyPoints: {demoCompanyId: 50},
        ),
        User(
          id: 'emp4',
          name: 'Karl Kristjánsson',
          email: 'Karl@Utilif.is',
          phoneNumber: '+3546901233',
          role: UserRole.employee,
          createdAt: DateTime.now(),
          workplaceIds: ['wp2'],
          workplaceNames: ['Mall Location'],
          companyIds: [demoCompanyId],
          companyNames: ['Utilif'],
          primaryCompanyId: demoCompanyId,
          companyRoles: {demoCompanyId: 'employee'},
          companyPoints: {demoCompanyId: 150},
        ),
      ];
      for (final user in sampleUsers) {
        // Only add if user with this ID doesn't exist
        if (!users.any((u) => u.id == user.id)) {
          await addUser(user);
        }
      }
    }

    // Create sample targets for the last 12 years (demo company only)
    final sampleDataTargets = await getSalesTargets();
    final demoTargets =
        sampleDataTargets.where((t) => t.companyId == demoCompanyId).toList();
    if (demoTargets.isEmpty) {
      final now = DateTime.now();
      final sampleTargets = <SalesTarget>[];

      // Create 12 targets for the last 12 years (2024-2013)
      for (int i = 0; i < 12; i++) {
        final year = now.year - i;
        final targetDate = DateTime(year, 9, 26); // September 26th each year

        // Vary the target amounts and actual amounts for realistic data
        final targetAmount =
            1000.0 + (i * 100.0); // Increasing targets over time
        final actualAmount =
            targetAmount * (0.7 + (i * 0.05)); // Varying performance

        // Determine if target was met
        final isMet = actualAmount >= targetAmount;
        final status = isMet ? TargetStatus.met : TargetStatus.missed;

        sampleTargets.add(SalesTarget(
          id: 'sample_target_$year',
          date: targetDate,
          targetAmount: targetAmount,
          actualAmount: actualAmount,
          isMet: isMet,
          status: status,
          percentageAboveTarget: isMet
              ? ((actualAmount - targetAmount) / targetAmount * 100)
              : 0.0,
          pointsAwarded: isMet ? (5 + i) : 0, // More points for recent targets
          createdAt: targetDate,
          createdBy: 'admin1',
          assignedEmployeeId: 'emp1',
          assignedEmployeeName: 'John Doe',
          assignedWorkplaceId: 'wp2', // Use Mall Location for consistency
          assignedWorkplaceName: 'Mall Location',
          collaborativeEmployeeIds: [],
          collaborativeEmployeeNames: [],
          companyId: demoCompanyId, // Link to demo company
        ));
      }

      // Add all sample targets
      for (final target in sampleTargets) {
        await addSalesTarget(target);
      }
    }

    final bonuses = await getBonuses();
    if (bonuses.isEmpty) {
      final sampleBonuses = [
        Bonus(
          id: 'bonus1',
          name: 'Free Coffee',
          description: 'Get a free coffee from the break room',
          pointsRequired: 50,
          createdAt: DateTime.now(),
          companyId: demoCompanyId,
        ),
        Bonus(
          id: 'bonus2',
          name: 'Extra Break',
          description: 'Take an extra 15-minute break',
          pointsRequired: 100,
          createdAt: DateTime.now(),
          companyId: demoCompanyId,
        ),
        Bonus(
          id: 'bonus3',
          name: 'Gift Card',
          description: 'Receive a \$25 gift card',
          pointsRequired: 200,
          createdAt: DateTime.now(),
          giftCardCode: 'GC-2024-ABC123',
          companyId: demoCompanyId,
        ),
        Bonus(
          id: 'bonus4',
          name: 'Day Off',
          description: 'Take a paid day off',
          pointsRequired: 500,
          createdAt: DateTime.now(),
          companyId: demoCompanyId,
        ),
      ];
      await saveBonuses(sampleBonuses);
    }
  }

  // Approval Request management
  static Future<List<ApprovalRequest>> getApprovalRequests() async {
    final prefs = await _prefs;
    final String? requestsJson = prefs.getString(_approvalRequestsKey);
    if (requestsJson == null) {
      return [];
    }
    final List<dynamic> requestsList = json.decode(requestsJson);
    return requestsList.map((json) => ApprovalRequest.fromJson(json)).toList();
  }

  static Future<void> saveApprovalRequests(
      List<ApprovalRequest> requests) async {
    final prefs = await _prefs;
    final String requestsJson =
        json.encode(requests.map((r) => r.toJson()).toList());
    await prefs.setString(_approvalRequestsKey, requestsJson);
  }

  static Future<void> addApprovalRequest(ApprovalRequest request) async {
    final requests = await getApprovalRequests();
    requests.add(request);
    await saveApprovalRequests(requests);
  }

  static Future<void> updateApprovalRequest(ApprovalRequest request) async {
    final requests = await getApprovalRequests();
    final index = requests.indexWhere((r) => r.id == request.id);
    if (index != -1) {
      requests[index] = request;
      await saveApprovalRequests(requests);
    }
  }

  static Future<void> deleteApprovalRequest(String requestId) async {
    final requests = await getApprovalRequests();
    requests.removeWhere((r) => r.id == requestId);
    await saveApprovalRequests(requests);
  }

  // Onboarding management
  static Future<bool> isOnboardingComplete() async {
    final prefs = await _prefs;
    return prefs.getBool(_onboardingCompleteKey) ?? false;
  }

  static Future<void> setOnboardingComplete() async {
    final prefs = await _prefs;
    await prefs.setBool(_onboardingCompleteKey, true);
  }

  // Password management
  static Future<Map<String, String>> getPasswords() async {
    final prefs = await _prefs;
    final jsonString = prefs.getString(_passwordsKey);
    if (jsonString == null) return {};
    final Map<String, dynamic> decoded = jsonDecode(jsonString);
    return decoded.map((key, value) => MapEntry(key, value.toString()));
  }

  static Future<void> savePassword(String userId, String password) async {
    final passwords = await getPasswords();
    passwords[userId] = password;
    final prefs = await _prefs;
    await prefs.setString(_passwordsKey, jsonEncode(passwords));
  }

  static Future<String?> getPassword(String userId) async {
    final passwords = await getPasswords();
    return passwords[userId];
  }

  // Message management
  static Future<List<Message>> getMessages() async {
    final prefs = await _prefs;
    final messagesJson = prefs.getStringList(_messagesKey) ?? [];
    return messagesJson
        .map((json) => Message.fromJson(jsonDecode(json)))
        .toList();
  }

  static Future<void> saveMessages(List<Message> messages) async {
    final prefs = await _prefs;
    final messagesJson =
        messages.map((message) => jsonEncode(message.toJson())).toList();
    await prefs.setStringList(_messagesKey, messagesJson);
  }

  static Future<void> addMessage(Message message) async {
    final messages = await getMessages();
    messages.add(message);
    await saveMessages(messages);
  }

  static Future<void> updateMessage(Message message) async {
    final messages = await getMessages();
    final index = messages.indexWhere((m) => m.id == message.id);
    if (index != -1) {
      messages[index] = message;
      await saveMessages(messages);
    }
  }

  static Future<List<Message>> getMessagesForUser(String userId) async {
    final messages = await getMessages();
    return messages
        .where((message) =>
            message.senderId == userId || message.recipientId == userId)
        .toList();
  }

  static Future<List<Message>> getConversation(
      String userId1, String userId2) async {
    final messages = await getMessages();
    return messages
        .where((message) =>
            (message.senderId == userId1 && message.recipientId == userId2) ||
            (message.senderId == userId2 && message.recipientId == userId1))
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  static Future<int> getUnreadMessageCount(String userId) async {
    final messages = await getMessages();
    return messages
        .where((message) => message.recipientId == userId && !message.isRead)
        .length;
  }

  static Future<void> markMessagesAsRead(String userId, String senderId) async {
    final messages = await getMessages();
    for (int i = 0; i < messages.length; i++) {
      if (messages[i].recipientId == userId &&
          messages[i].senderId == senderId &&
          !messages[i].isRead) {
        messages[i] = messages[i].copyWith(isRead: true);
      }
    }
    await saveMessages(messages);
  }

  // Dark mode preference
  static Future<bool> getDarkMode() async {
    final prefs = await _prefs;
    return prefs.getBool(_darkModeKey) ?? false;
  }

  static Future<void> setDarkMode(bool isDark) async {
    final prefs = await _prefs;
    await prefs.setBool(_darkModeKey, isDark);
  }
}
