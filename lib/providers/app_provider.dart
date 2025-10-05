import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../models/sales_target.dart';
import '../models/points_transaction.dart';
import '../models/bonus.dart';
import '../models/workplace.dart';
import '../models/company.dart';
import '../models/approval_request.dart';
import '../services/storage_service.dart';
import '../services/auth_service.dart';
import '../models/points_rules.dart';

class AppProvider with ChangeNotifier {
  User? _currentUser;
  List<SalesTarget> _salesTargets = [];
  List<PointsTransaction> _pointsTransactions = [];
  List<Bonus> _bonuses = [];
  List<Workplace> _workplaces = [];
  List<Company> _companies = [];
  List<ApprovalRequest> _approvalRequests = [];
  bool _isLoading = false;
  Map<String, PointsRules> _companyPointsRules = {};

  User? get currentUser => _currentUser;
  List<SalesTarget> get salesTargets => _salesTargets;
  List<PointsTransaction> get pointsTransactions => _pointsTransactions;
  List<Bonus> get bonuses => _bonuses;
  List<Workplace> get workplaces => _workplaces;
  List<Company> get companies => _companies;
  List<ApprovalRequest> get approvalRequests => _approvalRequests;
  bool get isLoading => _isLoading;

  // Check if user is admin for their current company (company-specific role)
  bool get isAdmin {
    if (_currentUser == null) {
      print('DEBUG: isAdmin - No current user');
      return false;
    }
    final primaryCompanyId = _currentUser!.primaryCompanyId;
    print(
        'DEBUG: isAdmin - User: ${_currentUser!.name}, Primary Company ID: $primaryCompanyId');
    print('DEBUG: isAdmin - Company Roles: ${_currentUser!.companyRoles}');

    if (primaryCompanyId != null) {
      // Check company-specific role
      final role = _currentUser!.getRoleForCompany(primaryCompanyId);
      print('DEBUG: isAdmin - Role for company $primaryCompanyId: $role');
      return role == UserRole.admin;
    }
    // Fallback to global role
    print('DEBUG: isAdmin - Using global role: ${_currentUser!.role}');
    return _currentUser!.role == UserRole.admin;
  }

  bool get isEmployee => !isAdmin;

  // Get points rules for a specific company (or current company if not specified)
  PointsRules getPointsRules([String? companyId]) {
    final targetCompanyId = companyId ?? _currentUser?.primaryCompanyId;
    if (targetCompanyId == null) {
      return PointsRules.defaults();
    }
    return _companyPointsRules[targetCompanyId] ?? PointsRules.defaults();
  }

  // For backward compatibility
  PointsRules get pointsRules => getPointsRules();

  // Onboarding state
  Future<bool> isOnboardingComplete() async {
    return await StorageService.isOnboardingComplete();
  }

  Future<void> setOnboardingComplete() async {
    await StorageService.setOnboardingComplete();
  }

  Future<void> initialize() async {
    _setLoading(true);
    try {
      // Only initialize sample data if onboarding is NOT complete
      final onboardingComplete = await StorageService.isOnboardingComplete();
      if (!onboardingComplete) {
        // Only clear data if no users exist (first time running)
        final existingUsers = await StorageService.getUsers();
        if (existingUsers.isEmpty) {
          await StorageService.clearAllData();
        }
        await StorageService.initializeSampleData();
      }
      await _loadData();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _loadData() async {
    _currentUser = await StorageService.getCurrentUser();
    print('DEBUG: _loadData - Loaded current user: ${_currentUser?.name}');
    print('DEBUG: _loadData - User companies: ${_currentUser?.companyIds}');
    print('DEBUG: _loadData - User roles: ${_currentUser?.companyRoles}');
    print(
        'DEBUG: _loadData - Primary company: ${_currentUser?.primaryCompanyId}');

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
    _companies = await StorageService.getCompanies();
    _approvalRequests = await StorageService.getApprovalRequests();
    _companyPointsRules = await StorageService.getCompanyPointsRules();

    // Process existing targets that should be marked as missed
    await processExistingTargets();

    notifyListeners();
  }

  Future<void> updatePointsRules(PointsRules rules, [String? companyId]) async {
    final targetCompanyId = companyId ?? _currentUser?.primaryCompanyId;
    if (targetCompanyId == null) return;

    _companyPointsRules[targetCompanyId] = rules;
    await StorageService.setCompanyPointsRules(_companyPointsRules);
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

  Future<void> updateSalesTargetForApproval(SalesTarget target) async {
    // Update target without triggering points adjustment (used during approval)
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

    // Skip adjustment if target is being approved (status change from submitted to approved)
    // or if target is already approved and being edited
    // or if target is being edited and has points (admin editing)
    if ((originalTarget.status == TargetStatus.submitted &&
            updatedTarget.status == TargetStatus.approved) ||
        (originalTarget.status == TargetStatus.approved &&
            updatedTarget.status == TargetStatus.approved) ||
        (originalTarget.pointsAwarded > 0 &&
            updatedTarget.pointsAwarded == 0)) {
      print('DEBUG: Skipping points adjustment for approval/editing process');
      return;
    }

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
  Future<void> updateWorkplace(Workplace workplace) async {
    await StorageService.updateWorkplace(workplace);
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
      // Pre-calc points preview using current rules (supports custom thresholds)
      final effectivePercent = (actualAmount / target.targetAmount) * 100.0;
      final prePoints =
          getPointsForEffectivePercent(effectivePercent, target.companyId);

      final updatedTarget = target.copyWith(
        actualAmount: actualAmount,
        isSubmitted: true,
        status: TargetStatus.submitted,
        pointsAwarded: prePoints,
      );

      await updateSalesTargetForApproval(updatedTarget);
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

      await updateSalesTargetForApproval(updatedTarget);
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

    // Check if the current user is the assigned employee for this target
    if (target.assignedEmployeeId == user.id) {
      // The assigned employee is adding team members - directly update the target
      print(
          'DEBUG: Assigned employee adding team members - updating target directly');

      final updatedTarget = target.copyWith(
        collaborativeEmployeeIds: newTeamMemberIds,
        collaborativeEmployeeNames: newTeamMemberNames,
      );

      await StorageService.updateSalesTarget(updatedTarget);

      // Update the local list
      final index = _salesTargets.indexWhere((t) => t.id == targetId);
      if (index != -1) {
        _salesTargets[index] = updatedTarget;
      }

      notifyListeners();
      print('DEBUG: Target updated directly with new team members');
    } else {
      // Different user changing team - requires approval
      print('DEBUG: Non-assigned user changing team - sending for approval');

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

      // Determine points based on admin-configured rules (custom rules supported)
      int awarded = 0;
      if (calculatedTarget.isMet) {
        final effectivePercent = 100.0 + calculatedTarget.percentageAboveTarget;
        awarded = getPointsForEffectivePercent(
            effectivePercent, calculatedTarget.companyId);
      }

      final updatedTarget = calculatedTarget.copyWith(
        isApproved: true,
        status: TargetStatus.approved,
        approvedBy: adminId,
        approvedAt: DateTime.now(),
        pointsAwarded: awarded,
      );

      // Update target directly without triggering _adjustPointsForTargetUpdate
      await updateSalesTargetForApproval(updatedTarget);

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
          final idx = users.indexWhere((u) => u.id == memberId);
          if (idx != -1) {
            final user = users[idx];
            users[idx] = user.copyWith(
              totalPoints: user.totalPoints + updatedTarget.pointsAwarded,
            );
            await StorageService.saveUsers(users);
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

  Future<void> deleteBonus(String bonusId) async {
    await StorageService.deleteBonus(bonusId);
    _bonuses.removeWhere((b) => b.id == bonusId);
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

    // Get the current company context for points calculation
    final companyId = user.primaryCompanyId;

    // Use company-specific points for accurate calculation
    final currentPoints = companyId != null
        ? getUserCompanyPoints(userId, companyId)
        : getUserTotalPoints(userId);

    print(
        'DEBUG: Redeeming in company: $companyId, User has $currentPoints points, Needs ${bonus.pointsRequired}');

    if (currentPoints < bonus.pointsRequired) {
      print(
          'DEBUG: Insufficient points. User has $currentPoints, needs ${bonus.pointsRequired}');
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

    // Deduct points from user with company context
    final secretCodeMessage = updatedBonus.secretCode?.isNotEmpty == true
        ? ' (Secret Code: ${updatedBonus.secretCode})'
        : '';

    final pointsTransaction = PointsTransaction(
      id: '${DateTime.now().millisecondsSinceEpoch}_redeem_$bonusId',
      userId: userId,
      type: PointsTransactionType.redeemed,
      points: bonus.pointsRequired,
      description: 'Redeemed ${bonus.name}${secretCodeMessage}',
      date: DateTime.now(),
      companyId: companyId, // Add company context to transaction
    );

    await StorageService.addPointsTransaction(pointsTransaction);
    _pointsTransactions.add(pointsTransaction);

    // Points are now calculated from transactions, so no need to update user.totalPoints directly
    final newTotalPoints = companyId != null
        ? getUserCompanyPoints(userId, companyId)
        : getUserTotalPoints(userId);

    print(
        'DEBUG: Bonus redeemed successfully. User points in company $companyId: $newTotalPoints');
    notifyListeners();
    return true;
  }

  Future<List<User>> getUsers() async {
    return await StorageService.getUsers();
  }

  Future<List<Workplace>> getWorkplaces() async {
    return await StorageService.getWorkplaces();
  }

  // Get target history for charting - returns monthly aggregated data
  List<Map<String, dynamic>> getTargetHistory({
    String? employeeId,
    String? workplaceId,
    int monthsBack = 12,
  }) {
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month - monthsBack, 1);

    // Filter targets by criteria
    var filteredTargets = _salesTargets.where((target) {
      if (target.date.isBefore(startDate)) return false;
      if (employeeId != null && target.assignedEmployeeId != employeeId)
        return false;
      if (workplaceId != null && target.assignedWorkplaceId != workplaceId)
        return false;
      return true;
    }).toList();

    // Group by month and aggregate
    final Map<String, Map<String, dynamic>> monthlyData = {};

    for (final target in filteredTargets) {
      final monthKey =
          '${target.date.year}-${target.date.month.toString().padLeft(2, '0')}';

      if (!monthlyData.containsKey(monthKey)) {
        monthlyData[monthKey] = {
          'month': monthKey,
          'targetTotal': 0.0,
          'actualTotal': 0.0,
          'targetCount': 0,
          'metCount': 0,
        };
      }

      final data = monthlyData[monthKey]!;
      data['targetTotal'] =
          (data['targetTotal'] as double) + target.targetAmount;
      data['actualTotal'] =
          (data['actualTotal'] as double) + target.actualAmount;
      data['targetCount'] = (data['targetCount'] as int) + 1;
      if (target.actualAmount >= target.targetAmount) {
        data['metCount'] = (data['metCount'] as int) + 1;
      }
    }

    // Convert to list and sort by month
    final result = monthlyData.values.toList();
    result
        .sort((a, b) => (a['month'] as String).compareTo(b['month'] as String));

    return result;
  }

  Future<void> addWorkplace(Workplace workplace) async {
    await StorageService.addWorkplace(workplace);
    _workplaces.add(workplace);
    notifyListeners();
  }

  Future<void> deleteWorkplace(String id) async {
    try {
      // Get workplace before deleting to find its name
      final placeToDelete = _workplaces.firstWhere((w) => w.id == id);

      await StorageService.deleteWorkplace(id);
      _workplaces.removeWhere((w) => w.id == id);

      // Load users and remove workplace-conditional workplace names
      final users = await StorageService.getUsers();
      final needToUpdate = users
          .where((user) => user.workplaceNames.contains(placeToDelete.name))
          .toList();

      for (var user in needToUpdate) {
        final withoutPlaceName = user.workplaceNames
            .where((name) => name != placeToDelete.name)
            .toList();
        if (withoutPlaceName.length != user.workplaceNames.length) {
          await StorageService.updateUser(
              user.copyWith(workplaceNames: withoutPlaceName));
        }
      }

      notifyListeners();
    } catch (e) {
      print("Error deleting workplace: $e");
    }
  }

  // Company management methods
  Future<List<Company>> getCompanies() async {
    return await StorageService.getCompanies();
  }

  Future<void> addCompany(Company company) async {
    await StorageService.addCompany(company);
    _companies.add(company);
    notifyListeners();
  }

  Future<void> updateCompany(Company company) async {
    await StorageService.updateCompany(company);
    final index = _companies.indexWhere((c) => c.id == company.id);
    if (index != -1) {
      _companies[index] = company;
    }
    notifyListeners();
  }

  Future<void> deleteCompany(String id) async {
    try {
      await StorageService.deleteCompany(id);
      _companies.removeWhere((c) => c.id == id);

      // Remove company from users
      final users = await StorageService.getUsers();
      for (var user in users) {
        if (user.companyIds.contains(id)) {
          final updatedUser = user.copyWith(
            companyIds: user.companyIds.where((cid) => cid != id).toList(),
            primaryCompanyId:
                user.primaryCompanyId == id ? null : user.primaryCompanyId,
          );
          await StorageService.updateUser(updatedUser);
        }
      }

      notifyListeners();
    } catch (e) {
      print("Error deleting company: $e");
    }
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
      String userId, int pointsChange, String description,
      {String? companyId}) async {
    // Get all users
    final users = await StorageService.getUsers();
    final userIndex = users.indexWhere((u) => u.id == userId);

    if (userIndex == -1) {
      print('DEBUG: User not found for points update');
      return;
    }

    final user = users[userIndex];

    // Calculate current points from transactions for this specific company
    final currentPoints = companyId != null
        ? getUserCompanyPoints(userId, companyId)
        : getUserTotalPoints(userId);
    final newTotalPoints = currentPoints + pointsChange;

    print(
        'DEBUG: updateUserPoints - User: ${user.name}, Company: $companyId, Current points: $currentPoints, Change: $pointsChange, New total: $newTotalPoints');

    // Ensure points don't go below 0
    if (newTotalPoints < 0) {
      print('DEBUG: Cannot reduce points below 0 for company $companyId');
      return;
    }

    // Create a points transaction with company context
    final transaction = PointsTransaction(
      id: '${DateTime.now().millisecondsSinceEpoch}_admin_adjust_$userId',
      userId: userId,
      type: pointsChange > 0
          ? PointsTransactionType.earned
          : PointsTransactionType.redeemed,
      points: pointsChange.abs(),
      description: description,
      date: DateTime.now(),
      companyId: companyId,
    );

    await StorageService.addPointsTransaction(transaction);

    // Update local data
    _pointsTransactions.add(transaction);

    // Update user's companyPoints map
    final updatedUser = user.setCompanyPoints(
      companyId ?? 'global',
      newTotalPoints,
    );
    users[userIndex] = updatedUser;
    await StorageService.saveUsers(users);

    // Update current user if it's the same user
    if (_currentUser != null && _currentUser!.id == userId) {
      _currentUser = updatedUser;
    }

    notifyListeners();
  }

  // Helper method to get points for a specific company from transactions
  int getUserCompanyPoints(String userId, String companyId) {
    final userTransactions = _pointsTransactions
        .where((t) => t.userId == userId && t.companyId == companyId);
    int points = 0;
    for (final transaction in userTransactions) {
      if (transaction.type == PointsTransactionType.earned ||
          transaction.type == PointsTransactionType.bonus ||
          transaction.type == PointsTransactionType.adjustment) {
        points += transaction.points;
      } else if (transaction.type == PointsTransactionType.redeemed) {
        points -= transaction.points;
      }
    }
    return points;
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

    // Determine points based on admin-configured rules (custom rules supported)
    int awarded = 0;
    if (calculatedTarget.isMet) {
      final effectivePercent = 100.0 + calculatedTarget.percentageAboveTarget;
      awarded = getPointsForEffectivePercent(
          effectivePercent, calculatedTarget.companyId);
    }

    // Mark as approved with correct points
    final updatedTarget = calculatedTarget.copyWith(
      isApproved: true,
      status: TargetStatus.approved,
      approvedBy: _currentUser?.id,
      approvedAt: DateTime.now(),
      pointsAwarded: awarded,
    );

    await updateSalesTargetForApproval(updatedTarget);

    // Award points to team members if target is met
    if (updatedTarget.isMet && updatedTarget.pointsAwarded > 0) {
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
    await updateSalesTargetForApproval(updatedTarget);
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

  int getPointsForEffectivePercent(double effectivePercent,
      [String? companyId]) {
    final rules = getPointsRules(companyId);
    print(
        'DEBUG: Calculating points for ${effectivePercent}% in company $companyId');
    print('DEBUG: Custom rules entries: ${rules.entries.length}');

    if (rules.entries.isNotEmpty) {
      final sorted = [...rules.entries]..sort((a, b) =>
          b.thresholdPercent.compareTo(a.thresholdPercent)); // Sort descending
      print(
          'DEBUG: Sorted rules: ${sorted.map((e) => '${e.thresholdPercent}% -> ${e.points}pts').join(', ')}');

      for (final e in sorted) {
        print(
            'DEBUG: Checking rule ${e.thresholdPercent}% -> ${e.points}pts (effective: ${effectivePercent}%)');
        if (effectivePercent >= e.thresholdPercent) {
          print('DEBUG: Matched rule ${e.thresholdPercent}% -> ${e.points}pts');
          return e.points; // Return the first (highest) threshold that matches
        }
      }
      print('DEBUG: No custom rule matched, returning 0');
      return 0; // No threshold met
    }

    print(
        'DEBUG: Using legacy rules - 200%: ${rules.pointsForDoubleTarget}, 110%: ${rules.pointsForTenPercentAbove}, 100%: ${rules.pointsForMet}');
    if (effectivePercent >= 200.0) {
      print('DEBUG: Using 200% rule: ${rules.pointsForDoubleTarget} points');
      return rules.pointsForDoubleTarget;
    }
    if (effectivePercent >= 110.0) {
      print('DEBUG: Using 110% rule: ${rules.pointsForTenPercentAbove} points');
      return rules.pointsForTenPercentAbove;
    }
    if (effectivePercent >= 100.0) {
      print('DEBUG: Using 100% rule: ${rules.pointsForMet} points');
      return rules.pointsForMet;
    }
    print('DEBUG: No rule matched, returning 0');
    return 0;
  }
}
