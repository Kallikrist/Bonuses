import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/sales_target.dart';
import '../models/points_transaction.dart';
import '../models/bonus.dart';
import '../models/workplace.dart';
import '../models/approval_request.dart';
import '../models/points_rules.dart';

class StorageService {
  static const String _usersKey = 'users';
  static const String _currentUserKey = 'current_user';
  static const String _salesTargetsKey = 'sales_targets';
  static const String _pointsTransactionsKey = 'points_transactions';
  static const String _bonusesKey = 'bonuses';
  static const String _workplacesKey = 'workplaces';
  static const String _approvalRequestsKey = 'approval_requests';
  static const String _pointsRulesKey = 'points_rules';

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

  // Points rules
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
    await prefs.remove(_currentUserKey);
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

  // Initialize with sample data
  static Future<void> initializeSampleData() async {
    // Initialize workplaces first
    final workplaces = await getWorkplaces();
    if (workplaces.isEmpty) {
      final sampleWorkplaces = [
        Workplace(
          id: 'wp1',
          name: 'Downtown Store',
          address: '123 Main St, Downtown',
          createdAt: DateTime.now(),
        ),
        Workplace(
          id: 'wp2',
          name: 'Mall Location',
          address: '456 Mall Ave, Shopping Center',
          createdAt: DateTime.now(),
        ),
        Workplace(
          id: 'wp3',
          name: 'Airport Store',
          address: '789 Airport Blvd, Terminal 2',
          createdAt: DateTime.now(),
        ),
      ];
      await saveWorkplaces(sampleWorkplaces);
    }

    final users = await getUsers();
    if (users.isEmpty) {
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
        ),
        User(
          id: 'emp1',
          name: 'John Doe',
          email: 'john@store.com',
          phoneNumber: '+1 (555) 234-5678',
          role: UserRole.employee,
          createdAt: DateTime.now(),
          workplaceIds: ['wp1'],
          workplaceNames: ['Downtown Store'],
        ),
        User(
          id: 'emp2',
          name: 'Jane Smith',
          email: 'jane@store.com',
          phoneNumber: '+1 (555) 345-6789',
          role: UserRole.employee,
          createdAt: DateTime.now(),
          workplaceIds: ['wp2'],
          workplaceNames: ['Mall Location'],
        ),
        User(
          id: 'emp3',
          name: 'Mike Johnson',
          email: 'mike@store.com',
          phoneNumber: '+1 (555) 456-7890',
          role: UserRole.employee,
          createdAt: DateTime.now(),
          workplaceIds: ['wp3'],
          workplaceNames: ['Airport Store'],
        ),
      ];
      await saveUsers(sampleUsers);
    }

    // Create sample targets for the last 12 years
    final targets = await getSalesTargets();
    if (targets.isEmpty) {
      final now = DateTime.now();
      final sampleTargets = <SalesTarget>[];
      
      // Create 12 targets for the last 12 years (2024-2013)
      for (int i = 0; i < 12; i++) {
        final year = now.year - i;
        final targetDate = DateTime(year, 9, 26); // September 26th each year
        
        // Vary the target amounts and actual amounts for realistic data
        final targetAmount = 1000.0 + (i * 100.0); // Increasing targets over time
        final actualAmount = targetAmount * (0.7 + (i * 0.05)); // Varying performance
        
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
          percentageAboveTarget: isMet ? ((actualAmount - targetAmount) / targetAmount * 100) : 0.0,
          pointsAwarded: isMet ? (5 + i) : 0, // More points for recent targets
          createdAt: targetDate,
          createdBy: 'admin1',
          assignedEmployeeId: 'emp1',
          assignedEmployeeName: 'John Doe',
          assignedWorkplaceId: 'wp2', // Use Mall Location for consistency
          assignedWorkplaceName: 'Mall Location',
          collaborativeEmployeeIds: [],
          collaborativeEmployeeNames: [],
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
        ),
        Bonus(
          id: 'bonus2',
          name: 'Extra Break',
          description: 'Take an extra 15-minute break',
          pointsRequired: 100,
          createdAt: DateTime.now(),
        ),
        Bonus(
          id: 'bonus3',
          name: 'Gift Card',
          description: 'Receive a \$25 gift card',
          pointsRequired: 200,
          createdAt: DateTime.now(),
          giftCardCode: 'GC-2024-ABC123',
        ),
        Bonus(
          id: 'bonus4',
          name: 'Day Off',
          description: 'Take a paid day off',
          pointsRequired: 500,
          createdAt: DateTime.now(),
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
}
