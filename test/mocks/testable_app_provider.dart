import 'package:flutter/foundation.dart';
import '../mocks/mock_storage_service.dart';
import '../../lib/models/user.dart';
import '../../lib/models/sales_target.dart';
import '../../lib/models/points_transaction.dart';
import '../../lib/models/bonus.dart';
import '../../lib/models/workplace.dart';
import '../../lib/models/approval_request.dart';

class TestableAppProvider with ChangeNotifier {
  User? _currentUser;
  List<SalesTarget> _salesTargets = [];
  List<PointsTransaction> _pointsTransactions = [];
  List<Bonus> _bonuses = [];
  List<Workplace> _workplaces = [];
  List<ApprovalRequest> _approvalRequests = [];
  bool _isLoading = false;

  User? get currentUser => _currentUser;
  List<SalesTarget> get salesTargets => _salesTargets;
  List<PointsTransaction> get pointsTransactions => _pointsTransactions;
  List<Bonus> get bonuses => _bonuses;
  List<Workplace> get workplaces => _workplaces;
  List<ApprovalRequest> get approvalRequests => _approvalRequests;
  bool get isLoading => _isLoading;
  bool get isAdmin => _currentUser?.role == UserRole.admin;
  bool get isEmployee => _currentUser?.role == UserRole.employee;

  Future<void> initialize() async {
    _setLoading(true);
    try {
      // Only clear data if no users exist (first time running)
      final existingUsers = await MockStorageService.getUsers();
      if (existingUsers.isEmpty) {
        await MockStorageService.clearAllData();
      }
      await MockStorageService.initializeSampleData();
      await _loadData();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _loadData() async {
    _currentUser = await MockStorageService.getCurrentUser();
    _salesTargets = await MockStorageService.getSalesTargets();
    _pointsTransactions = await MockStorageService.getPointsTransactions();
    _bonuses = await MockStorageService.getBonuses();
    _workplaces = await MockStorageService.getWorkplaces();
    _approvalRequests = await MockStorageService.getApprovalRequests();

    // Process existing targets that should be marked as missed
    await processExistingTargets();

    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    try {
      final success = await _performLogin(email, password);
      if (success) {
        await _loadData();
      }
      return success;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> _performLogin(String email, String password) async {
    // In a real app, this would validate against a server
    // For demo purposes, we'll use simple email-based authentication
    final users = await MockStorageService.getUsers();

    try {
      final user = users.firstWhere((u) => u.email == email);

      // Simple password validation (in real app, use proper authentication)
      if (password == 'password123') {
        _currentUser = user;
        await MockStorageService.setCurrentUser(user);
        return true;
      }
      return false;
    } catch (e) {
      // User not found
      return false;
    }
  }

  Future<void> logout() async {
    _currentUser = null;
    await MockStorageService.clearCurrentUser();
    _salesTargets.clear();
    _pointsTransactions.clear();
    _bonuses.clear();
    _workplaces.clear();
    notifyListeners();
  }

  Future<void> addSalesTarget(SalesTarget target) async {
    await MockStorageService.addSalesTarget(target);
    _salesTargets.add(target);
    notifyListeners();
  }

  Future<void> updateSalesTarget(SalesTarget target) async {
    await MockStorageService.updateSalesTarget(target);
    final index = _salesTargets.indexWhere((t) => t.id == target.id);
    if (index != -1) {
      _salesTargets[index] = target;
    }
    notifyListeners();
  }

  Future<void> deleteSalesTarget(String targetId) async {
    await MockStorageService.deleteSalesTarget(targetId);
    _salesTargets.removeWhere((t) => t.id == targetId);
    notifyListeners();
  }

  Future<void> processExistingTargets() async {
    // Process existing targets that have actual amounts but are still pending
    for (int i = 0; i < _salesTargets.length; i++) {
      final target = _salesTargets[i];

      // Check if target has actual amount and is below target (regardless of current status)
      if (target.actualAmount > 0 &&
          target.actualAmount < target.targetAmount &&
          (target.status == TargetStatus.pending ||
              target.status == TargetStatus.submitted ||
              (target.status == TargetStatus.met && !target.isMet))) {
        // Mark as missed with no points - use calculateResults to ensure proper status
        final calculatedTarget = target
            .copyWith(
              actualAmount: target.actualAmount,
              isSubmitted: true,
            )
            .calculateResults();

        final updatedTarget = calculatedTarget.copyWith(
          pointsAwarded: 0, // Ensure no points are awarded
        );

        await MockStorageService.updateSalesTarget(updatedTarget);
        _salesTargets[i] = updatedTarget;
      }
    }

    notifyListeners();
  }

  // User management methods
  Future<void> addUser(User user) async {
    await MockStorageService.addUser(user);
    notifyListeners();
  }

  Future<void> updateUser(User user) async {
    await MockStorageService.updateUser(user);

    // If this is the current user being updated, update the current user reference
    if (_currentUser != null && _currentUser!.id == user.id) {
      _currentUser = user;
      await MockStorageService.setCurrentUser(user);
    }

    notifyListeners();
  }

  Future<void> deleteUser(String userId) async {
    await MockStorageService.deleteUser(userId);
    notifyListeners();
  }

  // Workplace management methods
  Future<void> addWorkplace(Workplace workplace) async {
    await MockStorageService.addWorkplace(workplace);
    notifyListeners();
  }

  Future<void> updateWorkplace(Workplace workplace) async {
    await MockStorageService.updateWorkplace(workplace);
    notifyListeners();
  }

  Future<void> deleteWorkplace(String workplaceId) async {
    await MockStorageService.deleteWorkplace(workplaceId);
    notifyListeners();
  }

  Future<void> addPointsTransaction(PointsTransaction transaction) async {
    await MockStorageService.addPointsTransaction(transaction);
    _pointsTransactions.add(transaction);
    notifyListeners();
  }

  Future<void> addBonus(Bonus bonus) async {
    await MockStorageService.addBonus(bonus);
    _bonuses.add(bonus);
    notifyListeners();
  }

  Future<void> updateBonus(Bonus bonus) async {
    await MockStorageService.updateBonus(bonus);
    final index = _bonuses.indexWhere((b) => b.id == bonus.id);
    if (index != -1) {
      _bonuses[index] = bonus;
    }
    notifyListeners();
  }

  List<SalesTarget> getTodaysTargets() {
    final today = DateTime.now();
    return _salesTargets.where((target) {
      return target.date.year == today.year &&
          target.date.month == today.month &&
          target.date.day == today.day;
    }).toList();
  }

  List<SalesTarget> getEmployeeTargets(String employeeId) {
    return _salesTargets
        .where((target) => target.assignedEmployeeId == employeeId)
        .toList();
  }

  List<SalesTarget> getTodaysEmployeeTargets(String employeeId) {
    final today = DateTime.now();
    return _salesTargets.where((target) {
      return target.assignedEmployeeId == employeeId &&
          target.date.year == today.year &&
          target.date.month == today.month &&
          target.date.day == today.day;
    }).toList();
  }

  List<SalesTarget> getTodaysTargetsForEmployee(String employeeId) {
    final today = DateTime.now();
    final user = _currentUser;
    if (user == null) return [];

    return _salesTargets.where((target) {
      final isToday = target.date.year == today.year &&
          target.date.month == today.month &&
          target.date.day == today.day;

      if (!isToday) return false;

      // Include targets if:
      // 1. Assigned directly to this employee
      if (target.assignedEmployeeId == employeeId) return true;

      // 2. Assigned to this employee's workplace (and no specific employee assigned)
      if (user.workplaceIds.contains(target.assignedWorkplaceId) &&
          target.assignedEmployeeId == null) return true;

      // 3. Company-wide targets (no employee and no workplace assigned)
      if (target.assignedEmployeeId == null &&
          target.assignedWorkplaceId == null) return true;

      return false;
    }).toList();
  }

  List<SalesTarget> getUnassignedTargets() {
    return _salesTargets
        .where((target) => target.assignedEmployeeId == null)
        .toList();
  }

  List<PointsTransaction> getUserPointsTransactions(String userId) {
    return _pointsTransactions
        .where((transaction) => transaction.userId == userId)
        .toList();
  }

  List<Bonus> getAvailableBonuses() {
    return _bonuses
        .where((bonus) => bonus.status == BonusStatus.available)
        .toList();
  }

  List<Bonus> getUserRedeemedBonuses(String userId) {
    return _bonuses.where((bonus) => bonus.redeemedBy == userId).toList();
  }

  Future<bool> redeemBonus(String bonusId, String userId) async {
    final bonusIndex = _bonuses.indexWhere((b) => b.id == bonusId);
    if (bonusIndex == -1) {
      return false;
    }

    final bonus = _bonuses[bonusIndex];
    final user = _currentUser;

    if (user == null) {
      return false;
    }

    if (user.totalPoints < bonus.pointsRequired) {
      return false;
    }

    if (bonus.status != BonusStatus.available) {
      return false;
    }

    // Update bonus status
    final updatedBonus = bonus.copyWith(
      status: BonusStatus.redeemed,
      redeemedBy: userId,
      redeemedAt: DateTime.now(),
    );

    _bonuses[bonusIndex] = updatedBonus;
    await MockStorageService.updateBonus(updatedBonus);

    // Deduct points from user
    final pointsTransaction = PointsTransaction(
      id: '${DateTime.now().millisecondsSinceEpoch}_redeem_$bonusId',
      userId: userId,
      type: PointsTransactionType.redeemed,
      points: bonus.pointsRequired,
      description: 'Redeemed ${bonus.name}',
      date: DateTime.now(),
    );

    await MockStorageService.addPointsTransaction(pointsTransaction);
    _pointsTransactions.add(pointsTransaction);

    // Update user's total points
    final updatedUser = user.copyWith(
      totalPoints: user.totalPoints - bonus.pointsRequired,
    );
    _currentUser = updatedUser;
    await MockStorageService.updateUser(updatedUser);

    notifyListeners();
    return true;
  }

  Future<List<User>> getUsers() async {
    return await MockStorageService.getUsers();
  }

  Future<List<Workplace>> getWorkplaces() async {
    return await MockStorageService.getWorkplaces();
  }

  int getUserTotalPoints(String userId) {
    final userTransactions = getUserPointsTransactions(userId);
    return userTransactions.fold(0, (sum, transaction) {
      switch (transaction.type) {
        case PointsTransactionType.earned:
        case PointsTransactionType.adjustment:
          return sum + transaction.points;
        case PointsTransactionType.redeemed:
        case PointsTransactionType.bonus:
          return sum - transaction.points;
      }
    });
  }

  int getUserEarnedPoints(String userId) {
    final userTransactions = getUserPointsTransactions(userId);
    return userTransactions.fold(0, (sum, transaction) {
      switch (transaction.type) {
        case PointsTransactionType.earned:
        case PointsTransactionType.adjustment:
          return sum + transaction.points;
        case PointsTransactionType.redeemed:
        case PointsTransactionType.bonus:
          return sum; // Don't subtract redeemed points
      }
    });
  }

  List<SalesTarget> getPendingSubmissions() {
    return _salesTargets
        .where((target) => target.isSubmitted && !target.isApproved)
        .toList();
  }

  Future<void> updateUserPoints(
      String userId, int pointsChange, String description) async {
    // Get all users
    final users = await MockStorageService.getUsers();
    final userIndex = users.indexWhere((u) => u.id == userId);

    if (userIndex == -1) {
      return;
    }

    final user = users[userIndex];
    final newTotalPoints = user.totalPoints + pointsChange;

    // Ensure points don't go below 0
    if (newTotalPoints < 0) {
      return;
    }

    // Update user's total points
    final updatedUser = user.copyWith(totalPoints: newTotalPoints);
    users[userIndex] = updatedUser;
    await MockStorageService.saveUsers(users);

    // Create a points transaction
    final transaction = PointsTransaction(
      id: '${DateTime.now().millisecondsSinceEpoch}_admin_adjust_$userId',
      userId: userId,
      type: pointsChange > 0
          ? PointsTransactionType.earned
          : PointsTransactionType.redeemed,
      points: pointsChange.abs(),
      description: description,
      date: DateTime.now(),
    );

    await MockStorageService.addPointsTransaction(transaction);

    // Update local data
    _pointsTransactions.add(transaction);

    // Update current user if it's the same user
    if (_currentUser != null && _currentUser!.id == userId) {
      _currentUser = updatedUser;
    }

    // Reload data to ensure consistency
    await _loadData();

    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Approval Request methods
  Future<void> addApprovalRequest(ApprovalRequest request) async {
    await MockStorageService.addApprovalRequest(request);
    _approvalRequests = await MockStorageService.getApprovalRequests();
    notifyListeners();
  }

  Future<void> updateApprovalRequest(ApprovalRequest request) async {
    await MockStorageService.updateApprovalRequest(request);
    _approvalRequests = await MockStorageService.getApprovalRequests();
    notifyListeners();
  }

  Future<void> deleteApprovalRequest(String requestId) async {
    await MockStorageService.deleteApprovalRequest(requestId);
    _approvalRequests = await MockStorageService.getApprovalRequests();
    notifyListeners();
  }

  Future<void> approveRequest(ApprovalRequest request) async {
    final updatedRequest = request.copyWith(
      status: ApprovalStatus.approved,
      reviewedAt: DateTime.now(),
      reviewedBy: _currentUser?.id,
      reviewedByName: _currentUser?.name,
    );

    await MockStorageService.updateApprovalRequest(updatedRequest);

    // Apply the approved changes
    if (request.type == ApprovalRequestType.salesSubmission) {
      await _applySalesSubmission(request);
    } else if (request.type == ApprovalRequestType.teamChange) {
      await _applyTeamChange(request);
    }

    _approvalRequests = await MockStorageService.getApprovalRequests();
    notifyListeners();
  }

  Future<void> rejectRequest(ApprovalRequest request, String reason) async {
    final updatedRequest = request.copyWith(
      status: ApprovalStatus.rejected,
      reviewedAt: DateTime.now(),
      reviewedBy: _currentUser?.id,
      reviewedByName: _currentUser?.name,
      rejectionReason: reason,
    );

    await MockStorageService.updateApprovalRequest(updatedRequest);
    _approvalRequests = await MockStorageService.getApprovalRequests();
    notifyListeners();
  }

  Future<void> _applySalesSubmission(ApprovalRequest request) async {
    final target = _salesTargets.firstWhere((t) => t.id == request.targetId);

    // Calculate the updated target with new actual amount
    final updatedTarget = target
        .copyWith(
          actualAmount: request.newActualAmount!,
        )
        .calculateResults();

    await updateSalesTarget(updatedTarget);

    // Award points to team members if target is met
    if (updatedTarget.isMet) {
      await _awardPointsForTargetCompletion(updatedTarget);
    }
  }

  Future<void> _applyTeamChange(ApprovalRequest request) async {
    final target = _salesTargets.firstWhere((t) => t.id == request.targetId);
    final updatedTarget = target.copyWith(
      collaborativeEmployeeIds: request.newTeamMemberIds!,
      collaborativeEmployeeNames: request.newTeamMemberNames!,
    );
    await updateSalesTarget(updatedTarget);
  }

  Future<void> _awardPointsForTargetCompletion(SalesTarget target) async {
    // Award points to the assigned employee
    if (target.assignedEmployeeId != null) {
      final transaction = PointsTransaction(
        id: '${DateTime.now().millisecondsSinceEpoch}_${target.assignedEmployeeId}',
        userId: target.assignedEmployeeId!,
        type: PointsTransactionType.earned,
        points: target.pointsAwarded,
        description:
            'Sales target exceeded by ${((target.actualAmount / target.targetAmount) * 100 - 100).toStringAsFixed(1)}%',
        date: DateTime.now(),
        relatedTargetId: target.id,
      );

      await MockStorageService.addPointsTransaction(transaction);
      _pointsTransactions.add(transaction);

      // Update user's total points
      final users = await MockStorageService.getUsers();
      final userIndex =
          users.indexWhere((u) => u.id == target.assignedEmployeeId);
      if (userIndex != -1) {
        final user = users[userIndex];
        users[userIndex] =
            user.copyWith(totalPoints: user.totalPoints + target.pointsAwarded);
        await MockStorageService.saveUsers(users);
      }
    }

    // Award points to team members
    for (int i = 0; i < target.collaborativeEmployeeIds.length; i++) {
      final employeeId = target.collaborativeEmployeeIds[i];
      final transaction = PointsTransaction(
        id: '${DateTime.now().millisecondsSinceEpoch}_${employeeId}',
        userId: employeeId,
        type: PointsTransactionType.earned,
        points: target.pointsAwarded,
        description:
            'Team target completed: \$${target.targetAmount.toStringAsFixed(0)}',
        date: DateTime.now(),
        relatedTargetId: target.id,
      );

      await MockStorageService.addPointsTransaction(transaction);
      _pointsTransactions.add(transaction);

      // Update user's total points
      final users = await MockStorageService.getUsers();
      final userIndex = users.indexWhere((u) => u.id == employeeId);
      if (userIndex != -1) {
        final user = users[userIndex];
        users[userIndex] =
            user.copyWith(totalPoints: user.totalPoints + target.pointsAwarded);
        await MockStorageService.saveUsers(users);
      }
    }
  }

  // Points calculation method
  int getPointsForEffectivePercent(double effectivePercent) {
    // Default points rules (matching the real implementation)
    if (effectivePercent < 100) return 0;
    if (effectivePercent < 110) return 10; // 100-109% = 10 points
    if (effectivePercent < 120) return 15; // 110-119% = 15 points
    if (effectivePercent < 150) return 20; // 120-149% = 20 points
    if (effectivePercent < 200) return 30; // 150-199% = 30 points
    return 50; // 200%+ = 50 points
  }

  // Sales target approval method
  Future<void> approveSalesTarget(String targetId, String adminId) async {
    final targetIndex = _salesTargets.indexWhere((t) => t.id == targetId);
    if (targetIndex == -1) {
      throw Exception('Target not found');
    }

    final target = _salesTargets[targetIndex];

    // Check if already approved
    if (target.isApproved) {
      return; // Already approved, don't award points again
    }

    // Calculate points based on achievement
    int pointsAwarded = 0;
    if (target.actualAmount >= target.targetAmount) {
      final effectivePercent =
          (target.actualAmount / target.targetAmount) * 100;
      pointsAwarded = getPointsForEffectivePercent(effectivePercent);
    }

    // Update target status
    final updatedTarget = target.copyWith(
      status: TargetStatus.approved,
      isApproved: true,
      approvedBy: adminId,
      approvedAt: DateTime.now(),
      pointsAwarded: pointsAwarded,
      isMet: target.actualAmount >= target.targetAmount,
    );

    await MockStorageService.updateSalesTarget(updatedTarget);
    _salesTargets[targetIndex] = updatedTarget;

    // Award points to team members if target is met
    if (updatedTarget.isMet && updatedTarget.pointsAwarded > 0) {
      await _awardPointsForTargetCompletion(updatedTarget);
    }

    notifyListeners();
  }
}
