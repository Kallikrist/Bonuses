import 'package:bonuses/models/user.dart';
import 'package:bonuses/models/sales_target.dart';
import 'package:bonuses/models/points_transaction.dart';
import 'package:bonuses/models/bonus.dart';
import 'package:bonuses/models/workplace.dart';
import 'package:bonuses/models/approval_request.dart';

class MockStorageService {
  static final List<User> _users = [];
  static final List<SalesTarget> _salesTargets = [];
  static final List<PointsTransaction> _pointsTransactions = [];
  static final List<Bonus> _bonuses = [];
  static final List<Workplace> _workplaces = [];
  static final List<ApprovalRequest> _approvalRequests = [];
  static User? _currentUser;

  // User management
  static Future<List<User>> getUsers() async {
    return List.from(_users);
  }

  static Future<void> saveUsers(List<User> users) async {
    _users.clear();
    _users.addAll(users);
  }

  static Future<void> addUser(User user) async {
    _users.add(user);
  }

  static Future<void> updateUser(User user) async {
    final index = _users.indexWhere((u) => u.id == user.id);
    if (index != -1) {
      _users[index] = user;
    }
  }

  static Future<void> deleteUser(String userId) async {
    _users.removeWhere((u) => u.id == userId);
  }

  static Future<User?> getCurrentUser() async {
    return _currentUser;
  }

  static Future<void> setCurrentUser(User user) async {
    _currentUser = user;
  }

  static Future<void> clearCurrentUser() async {
    _currentUser = null;
  }

  // Sales targets management
  static Future<List<SalesTarget>> getSalesTargets() async {
    return List.from(_salesTargets);
  }

  static Future<void> saveSalesTargets(List<SalesTarget> targets) async {
    _salesTargets.clear();
    _salesTargets.addAll(targets);
  }

  static Future<void> addSalesTarget(SalesTarget target) async {
    _salesTargets.add(target);
  }

  static Future<void> updateSalesTarget(SalesTarget target) async {
    final index = _salesTargets.indexWhere((t) => t.id == target.id);
    if (index != -1) {
      _salesTargets[index] = target;
    }
  }

  static Future<void> deleteSalesTarget(String targetId) async {
    _salesTargets.removeWhere((t) => t.id == targetId);
  }

  static Future<void> clearAllData() async {
    _users.clear();
    _salesTargets.clear();
    _pointsTransactions.clear();
    _bonuses.clear();
    _workplaces.clear();
    _approvalRequests.clear();
    _currentUser = null;
  }

  // Points transactions management
  static Future<List<PointsTransaction>> getPointsTransactions() async {
    return List.from(_pointsTransactions);
  }

  static Future<void> savePointsTransactions(List<PointsTransaction> transactions) async {
    _pointsTransactions.clear();
    _pointsTransactions.addAll(transactions);
  }

  static Future<void> addPointsTransaction(PointsTransaction transaction) async {
    _pointsTransactions.add(transaction);
  }

  // Bonuses management
  static Future<List<Bonus>> getBonuses() async {
    return List.from(_bonuses);
  }

  static Future<void> saveBonuses(List<Bonus> bonuses) async {
    _bonuses.clear();
    _bonuses.addAll(bonuses);
  }

  static Future<void> addBonus(Bonus bonus) async {
    _bonuses.add(bonus);
  }

  static Future<void> updateBonus(Bonus bonus) async {
    final index = _bonuses.indexWhere((b) => b.id == bonus.id);
    if (index != -1) {
      _bonuses[index] = bonus;
    }
  }

  // Workplace management
  static Future<List<Workplace>> getWorkplaces() async {
    return List.from(_workplaces);
  }

  static Future<void> saveWorkplaces(List<Workplace> workplaces) async {
    _workplaces.clear();
    _workplaces.addAll(workplaces);
  }

  static Future<void> addWorkplace(Workplace workplace) async {
    _workplaces.add(workplace);
  }

  static Future<void> updateWorkplace(Workplace workplace) async {
    final index = _workplaces.indexWhere((w) => w.id == workplace.id);
    if (index != -1) {
      _workplaces[index] = workplace;
    }
  }

  static Future<void> deleteWorkplace(String workplaceId) async {
    _workplaces.removeWhere((w) => w.id == workplaceId);
  }

  // Initialize with sample data
  static Future<void> initializeSampleData() async {
    // Initialize workplaces first
    if (_workplaces.isEmpty) {
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

    if (_users.isEmpty) {
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

    // Create a sample target with assignment information
    if (_salesTargets.isEmpty) {
      final sampleTarget = SalesTarget(
        id: 'sample_target_1',
        date: DateTime.now(),
        targetAmount: 1000.0,
        createdAt: DateTime.now(),
        createdBy: 'admin1',
        assignedEmployeeId: 'emp1',
        assignedEmployeeName: 'John Doe',
        assignedWorkplaceId: 'wp1',
        assignedWorkplaceName: 'Downtown Store',
        collaborativeEmployeeIds: ['emp2'],
        collaborativeEmployeeNames: ['Jane Smith'],
      );
      await addSalesTarget(sampleTarget);
    }

    if (_bonuses.isEmpty) {
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
    return List.from(_approvalRequests);
  }

  static Future<void> saveApprovalRequests(List<ApprovalRequest> requests) async {
    _approvalRequests.clear();
    _approvalRequests.addAll(requests);
  }

  static Future<void> addApprovalRequest(ApprovalRequest request) async {
    _approvalRequests.add(request);
  }

  static Future<void> updateApprovalRequest(ApprovalRequest request) async {
    final index = _approvalRequests.indexWhere((r) => r.id == request.id);
    if (index != -1) {
      _approvalRequests[index] = request;
    }
  }

  static Future<void> deleteApprovalRequest(String requestId) async {
    _approvalRequests.removeWhere((r) => r.id == requestId);
  }
}