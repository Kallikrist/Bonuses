import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../models/sales_target.dart';
import '../models/points_transaction.dart';
import '../models/bonus.dart';
import '../models/workplace.dart';
import '../models/approval_request.dart';
import '../services/storage_service.dart';
import '../services/auth_service.dart';

class AppProvider with ChangeNotifier {
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
      final existingUsers = await StorageService.getUsers();
      if (existingUsers.isEmpty) {
        await StorageService.clearAllData();
      }
      await StorageService.initializeSampleData();
      await _loadData();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _loadData() async {
    _currentUser = await StorageService.getCurrentUser();
    _salesTargets = await StorageService.getSalesTargets();
    print('DEBUG: Loaded ${_salesTargets.length} targets');
    for (var target in _salesTargets) {
      print(
          'DEBUG: Target ${target.id} - Employee: ${target.assignedEmployeeName}, Workplace: ${target.assignedWorkplaceName}');
      print(
          'DEBUG: Target ${target.id} - Collaborative IDs: ${target.collaborativeEmployeeIds}');
      print(
          'DEBUG: Target ${target.id} - Collaborative Names: ${target.collaborativeEmployeeNames}');
    }
    _pointsTransactions = await StorageService.getPointsTransactions();
    _bonuses = await StorageService.getBonuses();
    _workplaces = await StorageService.getWorkplaces();
    _approvalRequests = await StorageService.getApprovalRequests();

    // Process existing targets that should be marked as missed
    await processExistingTargets();

    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    try {
      final success = await AuthService.login(email, password);
      if (success) {
        _currentUser = AuthService.currentUser;
        await _loadData();
      }
      return success;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    await AuthService.logout();
    _currentUser = null;
    _salesTargets.clear();
    _pointsTransactions.clear();
    _bonuses.clear();
    _workplaces.clear();
    notifyListeners();
  }

  Future<void> addSalesTarget(SalesTarget target) async {
    print(
        'DEBUG: Adding target with assignment - Employee: ${target.assignedEmployeeName}, Workplace: ${target.assignedWorkplaceName}');
    await StorageService.addSalesTarget(target);
    _salesTargets.add(target);
    print(
        'DEBUG: Target added to list. Total targets: ${_salesTargets.length}');

    // Award points to admins when they're added as team members
    await _awardAdminTeamParticipationPoints(target);

    notifyListeners();
  }

  // Helper method to award points to admins when added as team members
  Future<void> _awardAdminTeamParticipationPoints(SalesTarget target) async {
    final users = await StorageService.getUsers();

    // Check if any admins are in the collaborative team members
    for (final collaboratorId in target.collaborativeEmployeeIds) {
      final user = users.firstWhere(
        (u) => u.id == collaboratorId,
        orElse: () => User(
          id: '',
          name: '',
          email: '',
          role: UserRole.employee,
          createdAt: DateTime.now(),
        ),
      );

      // If the collaborator is an admin, award team participation points
      if (user.role == UserRole.admin && user.id.isNotEmpty) {
        print(
            'DEBUG: Admin ${user.name} added as team member to ${target.assignedWorkplaceName}');
        await awardAdminTeamParticipationPoints(
          user.id,
          target.assignedWorkplaceName ?? 'Unknown Store',
          target.id,
        );
      }
    }
  }

  Future<void> updateSalesTarget(SalesTarget target) async {
    // Find the original target to compare points
    final originalTarget = _salesTargets.firstWhere(
      (t) => t.id == target.id,
      orElse: () => target,
    );

    // Check if points need to be adjusted
    if (originalTarget.pointsAwarded != target.pointsAwarded) {
      await _adjustPointsForTargetUpdate(originalTarget, target);
    }

    await StorageService.updateSalesTarget(target);
    final index = _salesTargets.indexWhere((t) => t.id == target.id);
    if (index != -1) {
      _salesTargets[index] = target;
    }
    notifyListeners();
  }

  Future<void> deleteSalesTarget(String targetId) async {
    await StorageService.deleteSalesTarget(targetId);
    _salesTargets.removeWhere((t) => t.id == targetId);
    notifyListeners();
  }

  Future<void> _adjustPointsForTargetUpdate(
      SalesTarget originalTarget, SalesTarget updatedTarget) async {
    final pointsDifference =
        updatedTarget.pointsAwarded - originalTarget.pointsAwarded;

    if (pointsDifference == 0) return; // No change needed

    // Get all employees involved in this target
    final allEmployeeIds = <String>{};
    if (originalTarget.assignedEmployeeId != null) {
      allEmployeeIds.add(originalTarget.assignedEmployeeId!);
    }
    allEmployeeIds.addAll(originalTarget.collaborativeEmployeeIds);

    // Create adjustment transactions for each employee
    for (final employeeId in allEmployeeIds) {
      final transaction = PointsTransaction(
        id: DateTime.now().millisecondsSinceEpoch.toString() + '_' + employeeId,
        userId: employeeId,
        type: PointsTransactionType.adjustment,
        points: pointsDifference, // Can be positive or negative
        description: pointsDifference > 0
            ? 'Points adjustment: Target ${originalTarget.id} increased by ${pointsDifference} points'
            : 'Points adjustment: Target ${originalTarget.id} decreased by ${pointsDifference.abs()} points',
        date: DateTime.now(),
        relatedTargetId: originalTarget.id,
      );

      await StorageService.addPointsTransaction(transaction);
      _pointsTransactions.add(transaction);
    }

    print(
        'DEBUG: Adjusted points for target ${originalTarget.id}: ${pointsDifference > 0 ? '+' : ''}$pointsDifference points');
  }

  Future<void> markTargetAsMissed(String targetId, String adminId) async {
    final targetIndex = _salesTargets.indexWhere((t) => t.id == targetId);
    if (targetIndex != -1) {
      final target = _salesTargets[targetIndex];

      // Mark target as missed with no points awarded
      final updatedTarget = target.copyWith(
        status: TargetStatus.missed,
        isMet: false,
        pointsAwarded: 0,
        isApproved: true,
        approvedBy: adminId,
        approvedAt: DateTime.now(),
      );

      await StorageService.updateSalesTarget(updatedTarget);
      _salesTargets[targetIndex] = updatedTarget;

      print('DEBUG: Target ${targetId} marked as missed by admin ${adminId}');
      notifyListeners();
    }
  }

  List<String> _autoProcessedTargets = [];

  List<String> get autoProcessedTargets => _autoProcessedTargets;

  void clearAutoProcessedTargets() {
    _autoProcessedTargets.clear();
    notifyListeners();
  }

  Future<void> forceProcessAllTargets() async {
    _autoProcessedTargets.clear();

    // Process ALL targets that have actual amounts below target
    for (int i = 0; i < _salesTargets.length; i++) {
      final target = _salesTargets[i];

      // Check if target has actual amount and is below target
      if (target.actualAmount > 0 &&
          target.actualAmount < target.targetAmount) {
        print(
            'DEBUG: Force processing target ${target.id} - actual: ${target.actualAmount}, target: ${target.targetAmount}, current status: ${target.status.name}');

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

        await StorageService.updateSalesTarget(updatedTarget);
        _salesTargets[i] = updatedTarget;

        // Add to processed targets list for dashboard feedback
        _autoProcessedTargets.add(
            'Target \$${target.targetAmount.toStringAsFixed(0)} for ${target.assignedEmployeeName ?? 'Unknown'} marked as missed (${target.actualAmount.toStringAsFixed(0)} < ${target.targetAmount.toStringAsFixed(0)})');

        print(
            'DEBUG: Target ${target.id} force processed - Final status: ${updatedTarget.status.name}, isMet: ${updatedTarget.isMet}');
      }
    }

    notifyListeners();
  }

  Future<void> processExistingTargets() async {
    _autoProcessedTargets.clear();

    // Process existing targets that have actual amounts but are still pending
    for (int i = 0; i < _salesTargets.length; i++) {
      final target = _salesTargets[i];

      // Check if target has actual amount and is below target (regardless of current status)
      if (target.actualAmount > 0 &&
          target.actualAmount < target.targetAmount &&
          (target.status == TargetStatus.pending ||
              target.status == TargetStatus.submitted ||
              (target.status == TargetStatus.met && !target.isMet))) {
        print(
            'DEBUG: Processing existing target ${target.id} - actual: ${target.actualAmount}, target: ${target.targetAmount}');

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

        await StorageService.updateSalesTarget(updatedTarget);
        _salesTargets[i] = updatedTarget;

        // Add to processed targets list for dashboard feedback
        _autoProcessedTargets.add(
            'Target \$${target.targetAmount.toStringAsFixed(0)} for ${target.assignedEmployeeName ?? 'Unknown'} automatically marked as missed (${target.actualAmount.toStringAsFixed(0)} < ${target.targetAmount.toStringAsFixed(0)})');

        print(
            'DEBUG: Target ${target.id} automatically marked as missed - Final status: ${updatedTarget.status.name}, isMet: ${updatedTarget.isMet}');
      }
    }

    notifyListeners();
  }

  // User management methods
  Future<void> addUser(User user) async {
    await StorageService.addUser(user);
    notifyListeners();
  }

  Future<void> updateUser(User user) async {
    await StorageService.updateUser(user);

    // If this is the current user being updated, update the current user reference
    if (_currentUser != null && _currentUser!.id == user.id) {
      _currentUser = user;
      await StorageService.setCurrentUser(user);
    }

    notifyListeners();
  }

  Future<void> deleteUser(String userId) async {
    await StorageService.deleteUser(userId);
    notifyListeners();
  }

  // Workplace management methods
  Future<void> addWorkplace(Workplace workplace) async {
    await StorageService.addWorkplace(workplace);
    notifyListeners();
  }

  Future<void> updateWorkplace(Workplace workplace) async {
    await StorageService.updateWorkplace(workplace);
    notifyListeners();
  }

  Future<void> deleteWorkplace(String workplaceId) async {
    await StorageService.deleteWorkplace(workplaceId);
    notifyListeners();
  }

  Future<void> submitEmployeeSales(
      String targetId, double actualAmount, String employeeId) async {
    final target = _salesTargets.firstWhere((t) => t.id == targetId);
    final user = _currentUser!;

    // Check if target is met
    final isTargetMet = actualAmount >= target.targetAmount;

    if (isTargetMet) {
      // Target is met - create approval request for admin review
      final approvalRequest = ApprovalRequest(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        targetId: targetId,
        submittedBy: employeeId,
        submittedByName: user.name,
        type: ApprovalRequestType.salesSubmission,
        status: ApprovalStatus.pending,
        submittedAt: DateTime.now(),
        newActualAmount: actualAmount,
        previousActualAmount: target.actualAmount,
      );

      await addApprovalRequest(approvalRequest);

      // Update target to show as submitted for approval
      final updatedTarget = target.copyWith(
        actualAmount: actualAmount,
        isSubmitted: true,
        status: TargetStatus.submitted,
      );

      await updateSalesTarget(updatedTarget);
      print(
          'DEBUG: Target ${targetId} met - approval request created and target marked as submitted');
    } else {
      // Target not met - automatically mark as missed with no points
      final updatedTarget = target
          .copyWith(
            actualAmount: actualAmount,
            isSubmitted: true,
          )
          .calculateResults();

      await updateSalesTarget(updatedTarget);
      print(
          'DEBUG: Target ${targetId} not met - automatically marked as missed with no points');
    }
  }

  Future<void> submitTeamChange(String targetId, List<String> newTeamMemberIds,
      List<String> newTeamMemberNames, String employeeId) async {
    final target = _salesTargets.firstWhere((t) => t.id == targetId);
    final user = _currentUser!;

    print('DEBUG: Submitting team change for target $targetId');
    print('DEBUG: Previous team: ${target.collaborativeEmployeeNames}');
    print('DEBUG: New team: $newTeamMemberNames');

    // Create approval request for team change
    final approvalRequest = ApprovalRequest(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      targetId: targetId,
      submittedBy: employeeId,
      submittedByName: user.name,
      type: ApprovalRequestType.teamChange,
      status: ApprovalStatus.pending,
      submittedAt: DateTime.now(),
      newTeamMemberIds: newTeamMemberIds,
      newTeamMemberNames: newTeamMemberNames,
      previousTeamMemberIds: target.collaborativeEmployeeIds,
      previousTeamMemberNames: target.collaborativeEmployeeNames,
    );

    await addApprovalRequest(approvalRequest);
    print('DEBUG: Team change approval request created and submitted');
  }

  Future<void> approveSalesTarget(String targetId, String adminId) async {
    print('DEBUG: Approving target $targetId by admin $adminId');
    final targetIndex = _salesTargets.indexWhere((t) => t.id == targetId);
    if (targetIndex != -1) {
      final target = _salesTargets[targetIndex];
      print(
          'DEBUG: Target found - isSubmitted: ${target.isSubmitted}, isApproved: ${target.isApproved}');
      print(
          'DEBUG: Target details - isMet: ${target.isMet}, percentageAbove: ${target.percentageAboveTarget}, pointsAwarded: ${target.pointsAwarded}');

      // Only approve if target is submitted and not already approved
      if (!target.isSubmitted || target.isApproved) {
        print(
            'DEBUG: Target not eligible for approval - isSubmitted: ${target.isSubmitted}, isApproved: ${target.isApproved}');
        return;
      }

      // Calculate results first to determine if target is met
      final calculatedTarget = target.calculateResults();

      final updatedTarget = calculatedTarget.copyWith(
        isApproved: true,
        status: TargetStatus.approved,
        approvedBy: adminId,
        approvedAt: DateTime.now(),
      );

      await StorageService.updateSalesTarget(updatedTarget);
      _salesTargets[targetIndex] = updatedTarget;

      // Award points to all team members if target is met and points are available
      print(
          'DEBUG: Checking points eligibility - isMet: ${updatedTarget.isMet}, pointsAwarded: ${updatedTarget.pointsAwarded}');
      if (updatedTarget.isMet && updatedTarget.pointsAwarded > 0) {
        print('DEBUG: Awarding points to team members');
        // Get all team members (primary assignee + collaborators)
        final List<String> teamMemberIds = [];
        final List<String> teamMemberNames = [];

        print(
            'DEBUG: Target assignment details - assignedEmployeeId: ${updatedTarget.assignedEmployeeId}, assignedEmployeeName: ${updatedTarget.assignedEmployeeName}');
        print(
            'DEBUG: Target collaborative details - collaborativeEmployeeIds: ${updatedTarget.collaborativeEmployeeIds}, collaborativeEmployeeNames: ${updatedTarget.collaborativeEmployeeNames}');

        if (updatedTarget.assignedEmployeeId != null) {
          teamMemberIds.add(updatedTarget.assignedEmployeeId!);
          teamMemberNames.add(updatedTarget.assignedEmployeeName ?? 'Unknown');
          print(
              'DEBUG: Added primary assignee: ${updatedTarget.assignedEmployeeName} (${updatedTarget.assignedEmployeeId})');
        } else {
          print('DEBUG: No primary assignee found');
        }

        teamMemberIds.addAll(updatedTarget.collaborativeEmployeeIds);
        teamMemberNames.addAll(updatedTarget.collaborativeEmployeeNames);
        print(
            'DEBUG: Added collaborators: ${updatedTarget.collaborativeEmployeeNames}');

        print(
            'DEBUG: Team members to award points to: $teamMemberNames (IDs: $teamMemberIds)');

        // Award points to each team member
        for (int i = 0; i < teamMemberIds.length; i++) {
          final memberId = teamMemberIds[i];
          print(
              'DEBUG: Awarding ${updatedTarget.pointsAwarded} points to member $memberId');

          final transaction = PointsTransaction(
            id: '${DateTime.now().millisecondsSinceEpoch}_$memberId',
            userId: memberId,
            type: PointsTransactionType.earned,
            points: updatedTarget.pointsAwarded,
            description:
                'Sales target exceeded by ${updatedTarget.percentageAboveTarget.toStringAsFixed(1)}% (Team: ${teamMemberNames.join(', ')})',
            date: DateTime.now(),
            relatedTargetId: targetId,
          );

          await StorageService.addPointsTransaction(transaction);
          _pointsTransactions.add(transaction);

          // Update user's total points in storage
          final users = await StorageService.getUsers();
          final userIndex = users.indexWhere((u) => u.id == memberId);
          if (userIndex != -1) {
            final user = users[userIndex];
            print(
                'DEBUG: Updating user ${user.name} points from ${user.totalPoints} to ${user.totalPoints + updatedTarget.pointsAwarded}');
            final updatedUser = user.copyWith(
              totalPoints: user.totalPoints + updatedTarget.pointsAwarded,
            );
            users[userIndex] = updatedUser;
            await StorageService.saveUsers(users);

            // Update current user if it's the same user
            if (_currentUser != null && _currentUser!.id == memberId) {
              _currentUser = updatedUser;
              print(
                  'DEBUG: Updated current user points to ${_currentUser!.totalPoints}');
            }
          } else {
            print('DEBUG: User with ID $memberId not found');
          }
        }
      }

      notifyListeners();
    }
  }

  Future<void> addPointsTransaction(PointsTransaction transaction) async {
    await StorageService.addPointsTransaction(transaction);
    _pointsTransactions.add(transaction);

    // Update user's total points in storage
    final users = await StorageService.getUsers();
    final userIndex = users.indexWhere((u) => u.id == transaction.userId);
    if (userIndex != -1) {
      final user = users[userIndex];
      final pointsChange = transaction.type == PointsTransactionType.earned
          ? transaction.points
          : -transaction.points;
      final updatedUser = user.copyWith(
        totalPoints: user.totalPoints + pointsChange,
      );
      users[userIndex] = updatedUser;
      await StorageService.saveUsers(users);

      // Update current user if it's the same user
      if (_currentUser != null && _currentUser!.id == transaction.userId) {
        _currentUser = updatedUser;
      }
    }

    notifyListeners();
  }

  Future<void> addBonus(Bonus bonus) async {
    await StorageService.addBonus(bonus);
    _bonuses.add(bonus);
    notifyListeners();
  }

  // Award points to admin when added as team member to a store
  Future<void> awardAdminTeamParticipationPoints(
      String adminId, String workplaceName, String targetId) async {
    const int adminParticipationPoints =
        5; // Points for being added as team member

    final transaction = PointsTransaction(
      id: '${DateTime.now().millisecondsSinceEpoch}_admin_team_$adminId',
      userId: adminId,
      type: PointsTransactionType.earned,
      points: adminParticipationPoints,
      description: 'Added as team member to $workplaceName',
      date: DateTime.now(),
      relatedTargetId: targetId,
    );

    await StorageService.addPointsTransaction(transaction);
    _pointsTransactions.add(transaction);

    // Update admin's total points
    final users = await StorageService.getUsers();
    final userIndex = users.indexWhere((u) => u.id == adminId);
    if (userIndex != -1) {
      final user = users[userIndex];
      final updatedUser = user.copyWith(
        totalPoints: user.totalPoints + adminParticipationPoints,
      );
      users[userIndex] = updatedUser;
      await StorageService.saveUsers(users);

      // Update current user if it's the same admin
      if (_currentUser != null && _currentUser!.id == adminId) {
        _currentUser = updatedUser;
      }
    }

    notifyListeners();
  }

  Future<void> updateBonus(Bonus bonus) async {
    await StorageService.updateBonus(bonus);
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
    print('DEBUG: Redeeming bonus $bonusId for user $userId');

    final bonusIndex = _bonuses.indexWhere((b) => b.id == bonusId);
    if (bonusIndex == -1) {
      print('DEBUG: Bonus not found');
      return false;
    }

    final bonus = _bonuses[bonusIndex];
    final user = _currentUser;

    if (user == null) {
      print('DEBUG: No current user');
      return false;
    }

    if (user.totalPoints < bonus.pointsRequired) {
      print(
          'DEBUG: Insufficient points. User has ${user.totalPoints}, needs ${bonus.pointsRequired}');
      return false;
    }

    if (bonus.status != BonusStatus.available) {
      print('DEBUG: Bonus not available. Status: ${bonus.status}');
      return false;
    }

    // Update bonus status
    final updatedBonus = bonus.copyWith(
      status: BonusStatus.redeemed,
      redeemedBy: userId,
      redeemedAt: DateTime.now(),
    );

    _bonuses[bonusIndex] = updatedBonus;
    await StorageService.updateBonus(updatedBonus);

    // Deduct points from user
    final pointsTransaction = PointsTransaction(
      id: '${DateTime.now().millisecondsSinceEpoch}_redeem_$bonusId',
      userId: userId,
      type: PointsTransactionType.redeemed,
      points: bonus.pointsRequired,
      description: 'Redeemed ${bonus.name}',
      date: DateTime.now(),
    );

    await StorageService.addPointsTransaction(pointsTransaction);
    _pointsTransactions.add(pointsTransaction);

    // Update user's total points
    final updatedUser = user.copyWith(
      totalPoints: user.totalPoints - bonus.pointsRequired,
    );
    _currentUser = updatedUser;
    await StorageService.updateUser(updatedUser);

    print(
        'DEBUG: Bonus redeemed successfully. User points: ${updatedUser.totalPoints}');
    notifyListeners();
    return true;
  }

  Future<List<User>> getUsers() async {
    return await StorageService.getUsers();
  }

  Future<List<Workplace>> getWorkplaces() async {
    return await StorageService.getWorkplaces();
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
    final users = await StorageService.getUsers();
    final userIndex = users.indexWhere((u) => u.id == userId);

    if (userIndex == -1) {
      print('DEBUG: User not found for points update');
      return;
    }

    final user = users[userIndex];
    final newTotalPoints = user.totalPoints + pointsChange;

    // Ensure points don't go below 0
    if (newTotalPoints < 0) {
      print('DEBUG: Cannot reduce points below 0');
      return;
    }

    // Update user's total points
    final updatedUser = user.copyWith(totalPoints: newTotalPoints);
    users[userIndex] = updatedUser;
    await StorageService.saveUsers(users);

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

    await StorageService.addPointsTransaction(transaction);

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
    print(
        'DEBUG: Adding approval request - Type: ${request.type.name}, Target: ${request.targetId}');
    await StorageService.addApprovalRequest(request);
    _approvalRequests = await StorageService.getApprovalRequests();
    print(
        'DEBUG: Approval request added. Total requests: ${_approvalRequests.length}');
    notifyListeners();
  }

  Future<void> updateApprovalRequest(ApprovalRequest request) async {
    await StorageService.updateApprovalRequest(request);
    _approvalRequests = await StorageService.getApprovalRequests();
    notifyListeners();
  }

  Future<void> deleteApprovalRequest(String requestId) async {
    await StorageService.deleteApprovalRequest(requestId);
    _approvalRequests = await StorageService.getApprovalRequests();
    notifyListeners();
  }

  Future<void> approveRequest(ApprovalRequest request) async {
    final updatedRequest = request.copyWith(
      status: ApprovalStatus.approved,
      reviewedAt: DateTime.now(),
      reviewedBy: _currentUser?.id,
      reviewedByName: _currentUser?.name,
    );

    await StorageService.updateApprovalRequest(updatedRequest);

    // Apply the approved changes
    if (request.type == ApprovalRequestType.salesSubmission) {
      await _applySalesSubmission(request);
    } else if (request.type == ApprovalRequestType.teamChange) {
      await _applyTeamChange(request);
    }

    _approvalRequests = await StorageService.getApprovalRequests();
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

    await StorageService.updateApprovalRequest(updatedRequest);
    _approvalRequests = await StorageService.getApprovalRequests();
    notifyListeners();
  }

  Future<void> _applySalesSubmission(ApprovalRequest request) async {
    final target = _salesTargets.firstWhere((t) => t.id == request.targetId);

    // Calculate the updated target with new actual amount
    final calculatedTarget = target
        .copyWith(
          actualAmount: request.newActualAmount!,
        )
        .calculateResults();

    // Mark as approved
    final updatedTarget = calculatedTarget.copyWith(
      isApproved: true,
      status: TargetStatus.approved,
      approvedBy: _currentUser?.id,
      approvedAt: DateTime.now(),
    );

    await updateSalesTarget(updatedTarget);

    // Award points to team members if target is met
    if (updatedTarget.isMet) {
      await _awardPointsForTargetCompletion(updatedTarget);
    } else {
      // Target was not met - mark as missed with no points
      print(
          'DEBUG: Target ${updatedTarget.id} was not met. Marking as missed with no points awarded.');
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
      await updateUserPoints(
        target.assignedEmployeeId!,
        target.pointsAwarded,
        'Target completed: \$${target.targetAmount.toStringAsFixed(0)}',
      );
    }

    // Award points to team members
    for (int i = 0; i < target.collaborativeEmployeeIds.length; i++) {
      final employeeId = target.collaborativeEmployeeIds[i];
      await updateUserPoints(
        employeeId,
        target.pointsAwarded,
        'Team target completed: \$${target.targetAmount.toStringAsFixed(0)}',
      );
    }

    // Award admin team participation points
    if (_currentUser != null && target.assignedWorkplaceName != null) {
      await awardAdminTeamParticipationPoints(
        _currentUser!.id,
        target.assignedWorkplaceName!,
        target.id,
      );
    }
  }
}
