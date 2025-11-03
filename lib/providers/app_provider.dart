import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import '../models/user.dart';
import '../models/sales_target.dart';
import '../models/points_transaction.dart';
import '../models/bonus.dart';
import '../models/workplace.dart';
import '../models/company.dart';
import '../models/approval_request.dart';
import '../models/message.dart';
import '../services/storage_service.dart';
import '../services/auth_service.dart';
// Firebase auth service removed - using Supabase now
import '../models/points_rules.dart';

class AppProvider with ChangeNotifier {
  User? _currentUser;
  List<SalesTarget> _salesTargets = [];
  List<PointsTransaction> _pointsTransactions = [];
  List<Bonus> _bonuses = [];
  List<Workplace> _workplaces = [];
  List<Company> _companies = [];
  List<ApprovalRequest> _approvalRequests = [];
  List<Message> _messages = [];
  bool _isLoading = false;
  Map<String, PointsRules> _companyPointsRules = {};
  bool _isDarkMode = false;

  User? get currentUser => _currentUser;
  List<SalesTarget> get salesTargets => _salesTargets;
  List<PointsTransaction> get pointsTransactions => _pointsTransactions;
  List<Bonus> get bonuses => _bonuses;
  List<Workplace> get workplaces => _workplaces;
  List<Company> get companies => _companies;
  List<ApprovalRequest> get approvalRequests => _approvalRequests;
  List<Message> get messages => _messages;
  bool get isLoading => _isLoading;
  bool get isDarkMode => _isDarkMode;

  // Check if user is admin for their current company (company-specific role)
  bool get isAdmin {
    if (_currentUser == null) {
      return false;
    }
    final primaryCompanyId = _currentUser!.primaryCompanyId;

    if (primaryCompanyId != null) {
      // Check company-specific role
      final role = _currentUser!.getRoleForCompany(primaryCompanyId);
      return role == UserRole.admin;
    }
    // Fallback to global role
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
    // Avoid notifying listeners during the initial build phase.
    // Mark loading synchronously without emitting notifications yet.
    _isLoading = true;
    try {
      // Run migrations first (every time app starts)
      await StorageService.runMigrations();

      // Load dark mode preference
      _isDarkMode = await StorageService.getDarkMode();

      // Always ensure demo data exists for testing
      final existingUsers = await StorageService.getUsers();
      print('DEBUG: Found ${existingUsers.length} existing users');

      // Check if demo users exist
      final demoEmails = [
        'admin@store.com',
        'admin@utilif.com',
        'john.doe@example.com',
        'superadmin@platform.com'
      ];
      final hasDemoUsers = demoEmails
          .every((email) => existingUsers.any((user) => user.email == email));

      if (!hasDemoUsers) {
        print('DEBUG: Demo users missing, initializing demo data...');
        await StorageService.initializeSampleData();
        print('DEBUG: Demo data initialized successfully');
      } else {
        print('DEBUG: All demo users exist');
      }
      await _loadData();
    } finally {
      // Defer the final notifyListeners until after first frame to
      // prevent "setState()/markNeedsBuild called during build".
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _setLoading(false);
      });
    }
  }

  Future<void> _loadData() async {
    _currentUser = await StorageService.getCurrentUser();

    // Auto-heal: if current user has no active company but has company memberships,
    // set the primaryCompanyId to the first company and persist the fix.
    if (_currentUser != null &&
        (_currentUser!.primaryCompanyId == null ||
            (_currentUser!.primaryCompanyId?.isEmpty ?? true)) &&
        _currentUser!.companyIds.isNotEmpty) {
      final repairedUser = _currentUser!
          .copyWith(primaryCompanyId: _currentUser!.companyIds.first);
      await StorageService.setCurrentUser(repairedUser);
      await StorageService.updateUser(repairedUser);
      _currentUser = repairedUser;
    }

    // Reconcile with canonical stored user to recover company membership
    if (_currentUser != null) {
      final storedUsers = await StorageService.getUsers();
      final idx = storedUsers.indexWhere((u) => u.id == _currentUser!.id);
      if (idx != -1) {
        final canonical = storedUsers[idx];
        User repaired = _currentUser!;
        bool changed = false;

        // If session user lacks company memberships, adopt from canonical
        if (repaired.companyIds.isEmpty && canonical.companyIds.isNotEmpty) {
          repaired =
              repaired.copyWith(companyIds: List.from(canonical.companyIds));
          changed = true;
        }

        // Ensure primary company is set
        if ((repaired.primaryCompanyId == null ||
                (repaired.primaryCompanyId?.isEmpty ?? true)) &&
            repaired.companyIds.isNotEmpty) {
          repaired =
              repaired.copyWith(primaryCompanyId: repaired.companyIds.first);
          changed = true;
        }

        if (changed) {
          await StorageService.setCurrentUser(repaired);
          await StorageService.updateUser(repaired);
          _currentUser = repaired;
        }
      }
    }

    _salesTargets = await StorageService.getSalesTargets();
    // Removed excessive debug logging for better performance
    // print('DEBUG: Loaded ${_salesTargets.length} targets');
    _pointsTransactions = await StorageService.getPointsTransactions();
    _bonuses = await StorageService.getBonuses();
    _workplaces = await StorageService.getWorkplaces();
    _companies = await StorageService.getCompanies();
    _approvalRequests = await StorageService.getApprovalRequests();
    _messages = await StorageService.getMessages();
    _companyPointsRules = await StorageService.getCompanyPointsRules();

    // Second-chance auto-heal: infer company from targets if still missing
    if (_currentUser != null &&
        (_currentUser!.primaryCompanyId == null ||
            (_currentUser!.primaryCompanyId?.isEmpty ?? true))) {
      final inferred = _salesTargets.firstWhere(
        (t) =>
            t.assignedEmployeeId == _currentUser!.id ||
            t.collaborativeEmployeeIds.contains(_currentUser!.id),
        orElse: () => SalesTarget(
          id: '',
          date: DateTime.now(),
          targetAmount: 0,
          createdAt: DateTime.now(),
          createdBy: '',
        ),
      );
      if (inferred.id.isNotEmpty && (inferred.companyId?.isNotEmpty ?? false)) {
        final repaired = _currentUser!.copyWith(
          primaryCompanyId: inferred.companyId,
          companyIds:
              {..._currentUser!.companyIds, inferred.companyId!}.toList(),
        );
        await StorageService.setCurrentUser(repaired);
        await StorageService.updateUser(repaired);
        _currentUser = repaired;
      }
    }

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
    // Validate that no target already exists for this workplace on this date
    final existingTarget = _salesTargets.firstWhere(
      (existing) =>
          existing.assignedWorkplaceId == target.assignedWorkplaceId &&
          existing.date.year == target.date.year &&
          existing.date.month == target.date.month &&
          existing.date.day == target.date.day,
      orElse: () => SalesTarget(
        id: '',
        date: DateTime.now(),
        targetAmount: 0,
        createdAt: DateTime.now(),
        createdBy: '',
      ),
    );

    if (existingTarget.id.isNotEmpty) {
      throw Exception(
          'A target already exists for ${target.assignedWorkplaceName} on ${DateFormat('MMM dd, yyyy').format(target.date)}. Only one target per workplace per date is allowed.');
    }

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
          target.companyId ?? '',
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

    // Determine if team membership changed
    final originalMembers = <String>{
      if (originalTarget.assignedEmployeeId != null)
        originalTarget.assignedEmployeeId!,
      ...originalTarget.collaborativeEmployeeIds,
    };
    final updatedMembers = <String>{
      if (target.assignedEmployeeId != null) target.assignedEmployeeId!,
      ...target.collaborativeEmployeeIds,
    };
    final membershipChanged = originalMembers.length != updatedMembers.length ||
        !originalMembers.containsAll(updatedMembers) ||
        !updatedMembers.containsAll(originalMembers);

    // Check if points or membership need to be adjusted
    if (originalTarget.pointsAwarded != target.pointsAwarded ||
        membershipChanged) {
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
    print('🟢 UPDATE_FOR_APPROVAL: Updating target ${target.id}');
    print(
        '🟢 UPDATE_FOR_APPROVAL: isSubmitted=${target.isSubmitted}, status=${target.status.name}, actualAmount=${target.actualAmount}');
    await StorageService.updateSalesTarget(target);
    print('🟢 UPDATE_FOR_APPROVAL: StorageService.updateSalesTarget completed');
    final index = _salesTargets.indexWhere((t) => t.id == target.id);
    if (index != -1) {
      _salesTargets[index] = target;
    }
    notifyListeners();
  }

  Future<void> deleteSalesTarget(String targetId) async {
    // Get target before deleting to check if points need to be withdrawn
    final targetIndex = _salesTargets.indexWhere((t) => t.id == targetId);
    if (targetIndex == -1) {
      print(
          'DEBUG: Target $targetId not found in memory, cannot withdraw points');
      // Still try to delete from storage in case it exists there
      final deletedBy = _currentUser?.id ?? 'unknown';
      await StorageService.deleteSalesTarget(targetId, deletedBy);
      return;
    }

    final target = _salesTargets[targetIndex];
    final deletedBy = _currentUser?.id ?? 'unknown';

    // Withdraw points from all team members if points were awarded
    if (target.pointsAwarded > 0 && target.isApproved) {
      print(
          'DEBUG: Withdrawing ${target.pointsAwarded} points from team members for deleted target $targetId');

      // Get all team members (assigned employee + collaborators)
      final List<String> teamMemberIds = [];
      if (target.assignedEmployeeId != null) {
        teamMemberIds.add(target.assignedEmployeeId!);
      }
      teamMemberIds.addAll(target.collaborativeEmployeeIds);

      // Get company ID for the transaction
      final companyId =
          target.companyId ?? _currentUser?.primaryCompanyId ?? '';

      // Create negative adjustment transactions for each team member
      for (final memberId in teamMemberIds) {
        final transaction = PointsTransaction(
          id: '${DateTime.now().millisecondsSinceEpoch}_withdraw_$memberId',
          userId: memberId,
          type: PointsTransactionType.adjustment,
          points: -target.pointsAwarded, // Negative to withdraw
          description:
              'Points withdrawal: Target deleted (was awarded ${target.pointsAwarded} points)',
          date: DateTime.now(),
          relatedTargetId: targetId,
          companyId: companyId,
        );

        await StorageService.addPointsTransaction(transaction);
        _pointsTransactions.add(transaction);
        print(
            'DEBUG: Withdrew ${target.pointsAwarded} points from member $memberId for deleted target $targetId');
      }
    }

    // Perform soft delete
    await StorageService.deleteSalesTarget(targetId, deletedBy);

    // Remove from in-memory list so UI updates immediately
    // (getSalesTargets() will filter it out on next load anyway)
    _salesTargets.removeWhere((t) => t.id == targetId);
    notifyListeners();
  }

  Future<void> _adjustPointsForTargetUpdate(
      SalesTarget originalTarget, SalesTarget updatedTarget) async {
    // Guard: Validate companyId
    if (updatedTarget.companyId == null ||
        updatedTarget.companyId?.isEmpty == true) {
      print(
          'ERROR: _adjustPointsForTargetUpdate called with null/empty companyId for target ${updatedTarget.id}');
      print('WARNING: Skipping points adjustment to prevent data corruption');
      return;
    }

    final pointsDifference =
        updatedTarget.pointsAwarded - originalTarget.pointsAwarded;

    // Determine membership changes
    final originalMembers = <String>{
      if (originalTarget.assignedEmployeeId != null)
        originalTarget.assignedEmployeeId!,
      ...originalTarget.collaborativeEmployeeIds,
    };
    final updatedMembers = <String>{
      if (updatedTarget.assignedEmployeeId != null)
        updatedTarget.assignedEmployeeId!,
      ...updatedTarget.collaborativeEmployeeIds,
    };
    final removedMembers = originalMembers.difference(updatedMembers);
    final addedMembers = updatedMembers.difference(originalMembers);

    // Skip only when transitioning from submitted -> approved (to avoid double-award)
    if (originalTarget.status == TargetStatus.submitted &&
        updatedTarget.status == TargetStatus.approved) {
      print(
          'DEBUG: Skipping adjustment due to submitted -> approved transition');
      return;
    }

    // If target is approved and members were removed, withdraw their previously granted points
    if (updatedTarget.isApproved && removedMembers.isNotEmpty) {
      for (final userId in removedMembers) {
        final withdrawPoints = originalTarget.pointsAwarded;
        if (withdrawPoints != 0) {
          final tx = PointsTransaction(
            id: '${DateTime.now().millisecondsSinceEpoch}_withdraw_$userId',
            userId: userId,
            type: PointsTransactionType.adjustment,
            points: -withdrawPoints,
            description:
                'Points adjustment: Removed from target ${originalTarget.id} (-$withdrawPoints)',
            date: DateTime.now(),
            relatedTargetId: originalTarget.id,
            companyId: updatedTarget.companyId,
          );
          await StorageService.addPointsTransaction(tx);
          _pointsTransactions.add(tx);
          print(
              'DEBUG: Withdrew $withdrawPoints points from removed member $userId for target ${originalTarget.id}');
        }
      }
    }

    // If target is approved and members were added, grant them points (positive adjustment)
    if (updatedTarget.isApproved && addedMembers.isNotEmpty) {
      for (final userId in addedMembers) {
        final grantPoints = updatedTarget.pointsAwarded;
        if (grantPoints != 0) {
          final tx = PointsTransaction(
            id: '${DateTime.now().millisecondsSinceEpoch}_grant_$userId',
            userId: userId,
            type: PointsTransactionType.adjustment,
            points: grantPoints,
            description:
                'Points adjustment: Added to target ${originalTarget.id} (+$grantPoints)',
            date: DateTime.now(),
            relatedTargetId: originalTarget.id,
            companyId: updatedTarget.companyId,
          );
          await StorageService.addPointsTransaction(tx);
          _pointsTransactions.add(tx);
          print(
              'DEBUG: Granted $grantPoints points to newly added member $userId for target ${originalTarget.id}');
        }
      }
    }

    // If no points difference and no membership change, nothing else to do
    if (pointsDifference == 0 &&
        removedMembers.isEmpty &&
        addedMembers.isEmpty) {
      return;
    }

    // Apply difference-based adjustment for all current members when points change
    if (pointsDifference != 0) {
      final affectedMembers = updatedMembers;
      for (final employeeId in affectedMembers) {
        final transaction = PointsTransaction(
          id: '${DateTime.now().millisecondsSinceEpoch}_$employeeId',
          userId: employeeId,
          type: PointsTransactionType.adjustment,
          points: pointsDifference, // Can be positive or negative
          description: pointsDifference > 0
              ? 'Points adjustment: Target ${originalTarget.id} increased by $pointsDifference points'
              : 'Points adjustment: Target ${originalTarget.id} decreased by ${pointsDifference.abs()} points',
          date: DateTime.now(),
          relatedTargetId: originalTarget.id,
          companyId: updatedTarget.companyId,
        );

        await StorageService.addPointsTransaction(transaction);
        _pointsTransactions.add(transaction);
      }

      print(
          'DEBUG: Adjusted points for target ${originalTarget.id}: ${pointsDifference > 0 ? '+' : ''}$pointsDifference points');
    }
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

      print('DEBUG: Target $targetId marked as missed by admin $adminId');
      notifyListeners();
    }
  }

  final List<String> _autoProcessedTargets = [];

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

    // User created in local storage only (Firebase disabled for simplicity)
    print('✅ User created in local storage: ${user.email}');

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
    print(
        '🔵 SUBMIT: Starting submitEmployeeSales for target $targetId with actualAmount=$actualAmount');
    final target = _salesTargets.firstWhere((t) => t.id == targetId);
    final user = _currentUser!;

    // Check if target is met
    final isTargetMet = actualAmount >= target.targetAmount;
    print(
        '🔵 SUBMIT: Target met? $isTargetMet (actual=$actualAmount, target=${target.targetAmount})');

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
      print('🔵 SUBMIT: Approval request created');

      // Update target to show as submitted for approval
      // Pre-calc points preview using current rules (supports custom thresholds)
      final effectivePercent = (actualAmount / target.targetAmount) * 100.0;
      final prePoints =
          getPointsForEffectivePercent(effectivePercent, target.companyId);
      print(
          '🔵 SUBMIT: Calculated prePoints=$prePoints for effectivePercent=$effectivePercent%');

      final updatedTarget = target.copyWith(
        actualAmount: actualAmount,
        isSubmitted: true,
        status: TargetStatus.submitted,
        isMet: true, // Explicitly mark met; approval will finalize points
        pointsAwarded: prePoints,
      );
      print(
          '🔵 SUBMIT: Updated target - isSubmitted=${updatedTarget.isSubmitted}, status=${updatedTarget.status.name}, actualAmount=${updatedTarget.actualAmount}, isMet=${updatedTarget.isMet}');
      print('🔵 SUBMIT: About to call updateSalesTargetForApproval...');

      await updateSalesTargetForApproval(updatedTarget);
      print(
          '✅ SUBMIT: Target $targetId met - approval request created and target marked as submitted');
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
          'DEBUG: Target $targetId not met - automatically marked as missed with no points');
    }
  }

  Future<void> submitTeamChange(String targetId, List<String> newTeamMemberIds,
      List<String> newTeamMemberNames, String employeeId) async {
    final target = _salesTargets.firstWhere((t) => t.id == targetId);
    final user = _currentUser!;

    print('DEBUG: Submitting team change for target $targetId');
    print('DEBUG: Previous team: ${target.collaborativeEmployeeNames}');
    print('DEBUG: New team: $newTeamMemberNames');

    // Check if the target is approved - if so, all team changes require admin approval
    if (target.isApproved || target.status == TargetStatus.approved) {
      print('DEBUG: Target is approved - team changes require admin approval');
      // Continue to approval request flow below
    } else if (target.assignedEmployeeId == user.id) {
      // The assigned employee is adding team members - directly update the target (only if not approved)
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
      return; // Exit early since we updated directly
    }

    // For approved targets or non-assigned employees, require approval
    // Different user changing team - requires approval
    print(
        'DEBUG: Team change requires approval (target approved or user not assigned)');

    // Check if there's already a pending team change request for this target by this user
    final existingRequests = _approvalRequests
        .where(
          (request) =>
              request.targetId == targetId &&
              request.submittedBy == employeeId &&
              request.type == ApprovalRequestType.teamChange &&
              request.status == ApprovalStatus.pending,
        )
        .toList();

    if (existingRequests.isNotEmpty) {
      print(
          'DEBUG: Duplicate team change request detected - skipping creation');
      print('DEBUG: Existing request ID: ${existingRequests.first.id}');
      return;
    }

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
  Future<void> awardAdminTeamParticipationPoints(String adminId,
      String workplaceName, String targetId, String companyId) async {
    const int adminParticipationPoints =
        5; // Points for being added as team member

    if (companyId.isEmpty) {
      print(
          '⚠️ WARNING: Cannot award admin team participation points - companyId is empty');
      return;
    }

    final transaction = PointsTransaction(
      id: '${DateTime.now().millisecondsSinceEpoch}_admin_team_$adminId',
      userId: adminId,
      type: PointsTransactionType.earned,
      points: adminParticipationPoints,
      description: 'Added as team member to $workplaceName',
      date: DateTime.now(),
      relatedTargetId: targetId,
      companyId: companyId,
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
    if (user == null) {
      print('DEBUG: getTodaysTargetsForEmployee - No current user');
      return [];
    }

    final currentCompanyId = user.primaryCompanyId;
    print(
        'DEBUG: getTodaysTargetsForEmployee - EmployeeId: $employeeId, CompanyId: $currentCompanyId');
    print(
        'DEBUG: getTodaysTargetsForEmployee - Total targets in app: ${_salesTargets.length}');

    final result = _salesTargets.where((target) {
      final isToday = target.date.year == today.year &&
          target.date.month == today.month &&
          target.date.day == today.day;

      if (!isToday) return false;

      // Only show targets from the same company (if known). If employee has
      // no active company yet, show all company targets so they can still see
      // their team targets and the session can be healed elsewhere.
      print(
          'DEBUG: Checking target ${target.id}: companyId=${target.companyId} vs employee company=${currentCompanyId}');
      if (currentCompanyId != null && target.companyId != currentCompanyId) {
        print('  -> Filtered out - wrong company');
        return false;
      }

      // Include targets if:
      // 1. Assigned directly to this employee
      if (target.assignedEmployeeId == employeeId) {
        print('  -> INCLUDED - Assigned to employee');
        return true;
      }

      // 2. Employee is already a collaborator
      if (target.collaborativeEmployeeIds.contains(employeeId)) {
        print('  -> INCLUDED - Employee is collaborator');
        return true;
      }

      // 3. Assigned to this employee's workplace (and no specific employee assigned)
      if (user.workplaceIds.contains(target.assignedWorkplaceId) &&
          target.assignedEmployeeId == null) {
        print('  -> INCLUDED - Workplace match');
        return true;
      }

      // 4. Company-wide targets (no employee and no workplace assigned)
      if (target.assignedEmployeeId == null &&
          target.assignedWorkplaceId == null) {
        print('  -> INCLUDED - Company-wide target');
        return true;
      }

      // 5. Targets from the same company that employee can join
      // Show all company targets so employees can join as team members
      print('  -> INCLUDED - Company target available to join');
      return true;
    }).toList();

    print(
        'DEBUG: getTodaysTargetsForEmployee - Returning ${result.length} targets');
    return result;
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

  List<Bonus> getAvailableBonuses([String? companyId]) {
    final targetCompanyId = companyId ?? _currentUser?.primaryCompanyId;
    return _bonuses
        .where((bonus) =>
            bonus.status == BonusStatus.available &&
            bonus.companyId == targetCompanyId)
        .toList();
  }

  List<Bonus> getUserRedeemedBonuses(String userId, [String? companyId]) {
    // If companyId is explicitly passed, use it for filtering
    // If null is explicitly passed (default), show all redeemed bonuses globally
    if (companyId != null) {
      return _bonuses
          .where((bonus) =>
              bonus.redeemedBy == userId && bonus.companyId == companyId)
          .toList();
    }

    // Show all redeemed bonuses across all companies (global view)
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
      description: 'Redeemed ${bonus.name}$secretCodeMessage',
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

  Future<List<PointsTransaction>> getAllPointsTransactions() async {
    return await StorageService.getPointsTransactions();
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
      if (employeeId != null && target.assignedEmployeeId != employeeId) {
        return false;
      }
      if (workplaceId != null && target.assignedWorkplaceId != workplaceId) {
        return false;
      }
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

  // Suspend a company (set isActive to false)
  Future<void> suspendCompany(String companyId) async {
    try {
      final companies = await StorageService.getCompanies();
      final company = companies.firstWhere((c) => c.id == companyId);

      final suspendedCompany = company.copyWith(isActive: false);
      await StorageService.updateCompany(suspendedCompany);

      // Update local list
      final index = _companies.indexWhere((c) => c.id == companyId);
      if (index != -1) {
        _companies[index] = suspendedCompany;
      }

      notifyListeners();
      print('DEBUG: Company $companyId suspended successfully');
    } catch (e) {
      print('Error suspending company: $e');
      rethrow;
    }
  }

  // Activate a company (set isActive to true)
  Future<void> activateCompany(String companyId) async {
    try {
      final companies = await StorageService.getCompanies();
      final company = companies.firstWhere((c) => c.id == companyId);

      final activatedCompany = company.copyWith(isActive: true);
      await StorageService.updateCompany(activatedCompany);

      // Update local list
      final index = _companies.indexWhere((c) => c.id == companyId);
      if (index != -1) {
        _companies[index] = activatedCompany;
      }

      notifyListeners();
      print('DEBUG: Company $companyId activated successfully');
    } catch (e) {
      print('Error activating company: $e');
      rethrow;
    }
  }

  // Get company by ID
  Future<Company?> getCompanyById(String companyId) async {
    try {
      final companies = await StorageService.getCompanies();
      return companies.firstWhere((c) => c.id == companyId);
    } catch (e) {
      print('Error getting company by ID: $e');
      return null;
    }
  }

  // Transfer company ownership to another admin (updates company.adminUserId and roles)
  Future<void> transferCompanyOwnership({
    required String companyId,
    required String newAdminUserId,
  }) async {
    // Load companies
    final companies = await StorageService.getCompanies();
    final companyIndex = companies.indexWhere((c) => c.id == companyId);
    if (companyIndex == -1) return;

    final currentCompany = companies[companyIndex];
    final updatedCompany = currentCompany.copyWith(adminUserId: newAdminUserId);
    companies[companyIndex] = updatedCompany;
    await StorageService.saveCompanies(companies);

    // Ensure new admin has admin role in this company
    final users = await StorageService.getUsers();
    for (final user in users) {
      if (user.id == newAdminUserId) {
        final updatedRoles = Map<String, String>.from(user.companyRoles);
        updatedRoles[companyId] = UserRole.admin.toString().split('.').last;
        final updatedUser = user.copyWith(companyRoles: updatedRoles);
        await StorageService.updateUser(updatedUser);
      }
    }

    // Refresh local cache
    _companies = companies;
    notifyListeners();
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
      {String? companyId, String? relatedTargetId}) async {
    // Guard: Validate companyId
    if (companyId == null || companyId.isEmpty) {
      print(
          'ERROR: updateUserPoints called with null/empty companyId for user $userId');
      print('STACK TRACE: Description: $description');
      // Try to recover by finding user's primary company
      final users = await StorageService.getUsers();
      final user = users.firstWhere((u) => u.id == userId,
          orElse: () => User(
                id: userId,
                name: 'Unknown',
                email: '',
                role: UserRole.employee,
                primaryCompanyId: '',
                companyIds: [],
                companyRoles: {},
                createdAt: DateTime.now(),
              ));
      if (user.primaryCompanyId != null && user.primaryCompanyId!.isNotEmpty) {
        print(
            'WARNING: Recovered companyId from user primary company: ${user.primaryCompanyId}');
        companyId = user.primaryCompanyId;
      } else {
        print(
            'CRITICAL ERROR: Cannot update points - no valid companyId found for user $userId');
        return;
      }
    }

    // At this point companyId is guaranteed to be non-null and non-empty
    final validCompanyId = companyId!;

    // Get all users
    final users = await StorageService.getUsers();
    final userIndex = users.indexWhere((u) => u.id == userId);

    if (userIndex == -1) {
      print('DEBUG: User not found for points update');
      return;
    }

    final user = users[userIndex];

    // Calculate current points from transactions for this specific company
    final currentPoints = getUserCompanyPoints(userId, validCompanyId);
    final newTotalPoints = currentPoints + pointsChange;

    print(
        'DEBUG: updateUserPoints - User: ${user.name}, Company: $validCompanyId, Current points: $currentPoints, Change: $pointsChange, New total: $newTotalPoints');

    // Ensure points don't go below 0
    if (newTotalPoints < 0) {
      print('DEBUG: Cannot reduce points below 0 for company $validCompanyId');
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
      companyId: validCompanyId,
      relatedTargetId: relatedTargetId,
    );

    await StorageService.addPointsTransaction(transaction);

    // Update local data
    _pointsTransactions.add(transaction);

    // Update user's companyPoints map
    final updatedUser = user.setCompanyPoints(
      validCompanyId,
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

    print('DEBUG: getUserCompanyPoints - User: $userId, Company: $companyId');
    print(
        'DEBUG: Found ${userTransactions.length} transactions for this user/company');

    int points = 0;
    for (final transaction in userTransactions) {
      print(
          'DEBUG: Transaction - Type: ${transaction.type.name}, Points: ${transaction.points}, Description: ${transaction.description}');
      if (transaction.type == PointsTransactionType.earned ||
          transaction.type == PointsTransactionType.bonus ||
          transaction.type == PointsTransactionType.adjustment) {
        points += transaction.points;
      } else if (transaction.type == PointsTransactionType.redeemed) {
        points -= transaction.points;
      }
    }

    print('DEBUG: Total points calculated: $points');
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
    print(
        'DEBUG: approveRequest called - requestId: ${request.id}, type: ${request.type.name}');
    print('DEBUG: Target ID: ${request.targetId}');

    final updatedRequest = request.copyWith(
      status: ApprovalStatus.approved,
      reviewedAt: DateTime.now(),
      reviewedBy: _currentUser?.id,
      reviewedByName: _currentUser?.name,
    );

    await StorageService.updateApprovalRequest(updatedRequest);

    // Apply the approved changes
    if (request.type == ApprovalRequestType.salesSubmission) {
      print('DEBUG: Processing sales submission approval');
      await _applySalesSubmission(request);
    } else if (request.type == ApprovalRequestType.teamChange) {
      print('DEBUG: Processing team change approval');
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
    print('DEBUG: _applyTeamChange called for request ${request.id}');
    print('DEBUG: Target ID: ${request.targetId}');
    print('DEBUG: Previous team: ${request.previousTeamMemberNames}');
    print('DEBUG: New team: ${request.newTeamMemberNames}');

    final target = _salesTargets.firstWhere((t) => t.id == request.targetId);
    print(
        'DEBUG: Found target - isApproved: ${target.isApproved}, pointsAwarded: ${target.pointsAwarded}');

    // Guard: Validate companyId before processing team changes
    if (target.companyId == null || target.companyId?.isEmpty == true) {
      print(
          'ERROR: _applyTeamChange called with null/empty companyId for target ${request.targetId}');
      print('WARNING: Cannot apply team changes without valid company context');
      return;
    }

    final updatedTarget = target.copyWith(
      collaborativeEmployeeIds: request.newTeamMemberIds!,
      collaborativeEmployeeNames: request.newTeamMemberNames!,
    );
    await updateSalesTargetForApproval(updatedTarget);

    // If the target was already approved and had points awarded,
    // award points to any new team members who weren't in the previous team
    if (target.isApproved && target.pointsAwarded > 0) {
      final previousTeamIds = Set<String>.from(request.previousTeamMemberIds!);
      final newTeamIds = Set<String>.from(request.newTeamMemberIds!);
      final newlyAddedMembers = newTeamIds.difference(previousTeamIds);

      print(
          'DEBUG: Target was already approved with ${target.pointsAwarded} points');
      print('DEBUG: Previous team: ${request.previousTeamMemberNames}');
      print('DEBUG: New team: ${request.newTeamMemberNames}');
      print('DEBUG: Newly added members: $newlyAddedMembers');

      // Award points to newly added team members with company context
      for (final newMemberId in newlyAddedMembers) {
        await updateUserPoints(
          newMemberId,
          target.pointsAwarded,
          'Added to approved target: \$${target.targetAmount.toStringAsFixed(0)}',
          companyId: target.companyId,
        );
        print(
            'DEBUG: Awarded ${target.pointsAwarded} points to newly added member: $newMemberId in company ${target.companyId}');
      }
    } else {
      print(
          'DEBUG: Team change conditions not met - isApproved: ${target.isApproved}, pointsAwarded: ${target.pointsAwarded}');
    }
  }

  Future<void> _awardPointsForTargetCompletion(SalesTarget target) async {
    print(
        'DEBUG: _awardPointsForTargetCompletion called for target ${target.id}');
    print(
        'DEBUG: Target has ${target.collaborativeEmployeeIds.length} team members');
    print('DEBUG: Points to award: ${target.pointsAwarded}');

    // Guard: Validate companyId
    if (target.companyId == null || target.companyId?.isEmpty == true) {
      print(
          'ERROR: _awardPointsForTargetCompletion called with null/empty companyId for target ${target.id}');
      print('WARNING: Cannot award points without valid company context');
      return;
    }

    // Award points to the assigned employee with company context
    if (target.assignedEmployeeId != null) {
      await updateUserPoints(
        target.assignedEmployeeId!,
        target.pointsAwarded,
        'Target completed: \$${target.targetAmount.toStringAsFixed(0)}',
        companyId: target.companyId,
        relatedTargetId: target.id,
      );
      print(
          'DEBUG: Awarded ${target.pointsAwarded} points to assigned employee: ${target.assignedEmployeeId}');
    }

    // Award points to team members with company context
    for (int i = 0; i < target.collaborativeEmployeeIds.length; i++) {
      final employeeId = target.collaborativeEmployeeIds[i];
      final employeeName = i < target.collaborativeEmployeeNames.length
          ? target.collaborativeEmployeeNames[i]
          : employeeId;
      await updateUserPoints(
        employeeId,
        target.pointsAwarded,
        'Team target completed: \$${target.targetAmount.toStringAsFixed(0)}',
        companyId: target.companyId,
        relatedTargetId: target.id,
      );
      print(
          'DEBUG: Awarded ${target.pointsAwarded} points to team member $employeeName ($employeeId) in company ${target.companyId}');
    }

    // Award admin team participation points
    if (_currentUser != null && target.assignedWorkplaceName != null) {
      await awardAdminTeamParticipationPoints(
        _currentUser!.id,
        target.assignedWorkplaceName!,
        target.id,
        target.companyId ?? '',
      );
    }
  }

  // Manual points correction for already-approved targets
  Future<void> retroactivelyAwardPointsForTarget(String targetId) async {
    print(
        'DEBUG: retroactivelyAwardPointsForTarget called for target $targetId');
    final target = _salesTargets.firstWhere((t) => t.id == targetId);

    // Guard: Validate companyId
    if (target.companyId == null || target.companyId?.isEmpty == true) {
      print(
          'ERROR: retroactivelyAwardPointsForTarget called with null/empty companyId for target $targetId');
      print('WARNING: Cannot award points without valid company context');
      return;
    }

    if (!target.isApproved || target.pointsAwarded == 0) {
      print('DEBUG: Target is not approved or has no points to award');
      return;
    }

    // Check if any team member has already received points for this target
    // by looking for transactions with this target ID or matching description
    final targetAmount = target.targetAmount.toStringAsFixed(0);
    final targetTransactions = _pointsTransactions
        .where((t) =>
            t.relatedTargetId == targetId ||
            (t.description.contains('Team target completed: \$$targetAmount') ||
                t.description.contains('Target completed: \$$targetAmount')))
        .toList();

    if (targetTransactions.isNotEmpty) {
      print(
          'DEBUG: Found ${targetTransactions.length} existing transactions for this target');

      // Check which team members already have transactions
      final usersWithPoints = targetTransactions.map((t) => t.userId).toSet();
      final teamMembers = Set<String>.from(target.collaborativeEmployeeIds);
      if (target.assignedEmployeeId != null) {
        teamMembers.add(target.assignedEmployeeId!);
      }

      final missingUsers = teamMembers.difference(usersWithPoints);

      if (missingUsers.isEmpty) {
        print(
            'DEBUG: All team members have already received points for this target');
        return;
      }

      // Award points only to users who haven't received them yet
      print(
          'DEBUG: Awarding points to ${missingUsers.length} users who haven\'t received them yet');
      for (final userId in missingUsers) {
        final userName = target.collaborativeEmployeeIds.contains(userId)
            ? target.collaborativeEmployeeNames[
                target.collaborativeEmployeeIds.indexOf(userId)]
            : 'Assigned Employee';

        await updateUserPoints(
          userId,
          target.pointsAwarded,
          'Team target completed: \$${target.targetAmount.toStringAsFixed(0)}',
          companyId: target.companyId,
          relatedTargetId: targetId,
        );
        print(
            'DEBUG: Awarded ${target.pointsAwarded} points to $userName ($userId)');
      }
    } else {
      // No transactions exist yet - award to all team members
      print(
          'DEBUG: No existing transactions - awarding ${target.pointsAwarded} points to all team members');
      await _awardPointsForTargetCompletion(target);
    }

    notifyListeners();
  }

  // Recalculate and adjust points for a target based on updated target amount (admin function)
  Future<void> recalculateAndAdjustPoints(
      String targetId, double newTargetAmount) async {
    print(
        'DEBUG: recalculateAndAdjustPoints called for target $targetId with new target: $newTargetAmount');

    final target = _salesTargets.firstWhere((t) => t.id == targetId);

    // Guard: Validate companyId
    if (target.companyId == null || target.companyId?.isEmpty == true) {
      print(
          'ERROR: recalculateAndAdjustPoints called with null/empty companyId for target $targetId');
      print('WARNING: Cannot adjust points without valid company context');
      return;
    }

    if (!target.isApproved) {
      print('DEBUG: Target not approved - cannot adjust points');
      return;
    }

    final currentPoints = target.pointsAwarded;

    // Recalculate points based on actual amount vs new target amount
    final effectivePercent = newTargetAmount > 0
        ? (target.actualAmount / newTargetAmount) * 100.0
        : 0.0;

    final correctPoints = effectivePercent >= 100.0
        ? getPointsForEffectivePercent(effectivePercent, target.companyId)
        : 0;

    final pointsDifference = correctPoints - currentPoints;

    print(
        'DEBUG: Old target: ${target.targetAmount}, New target: $newTargetAmount');
    print('DEBUG: Actual amount: ${target.actualAmount}');
    print('DEBUG: Effective percent: $effectivePercent%');
    print(
        'DEBUG: Current points: $currentPoints, Correct points: $correctPoints, Difference: $pointsDifference');

    if (pointsDifference == 0) {
      print('DEBUG: No points adjustment needed');
      // Still update the target amount
      final updatedTarget = target.copyWith(
          targetAmount: newTargetAmount, pointsAwarded: correctPoints);
      final index = _salesTargets.indexWhere((t) => t.id == targetId);
      if (index != -1) {
        _salesTargets[index] = updatedTarget;
        await StorageService.updateSalesTarget(updatedTarget);
      }
      notifyListeners();
      return;
    }

    // Create adjustment transactions for each team member
    final users = await StorageService.getUsers();
    for (final employeeId in target.collaborativeEmployeeIds) {
      final employee = users.firstWhere((u) => u.id == employeeId,
          orElse: () => User(
                id: employeeId,
                name: 'Unknown',
                email: '',
                role: UserRole.employee,
                totalPoints: 0,
                createdAt: DateTime.now(),
              ));

      // Update user points (this creates the transaction automatically)
      await updateUserPoints(
        employeeId,
        pointsDifference,
        pointsDifference > 0
            ? 'Points correction: +$pointsDifference (target adjusted from \$${target.targetAmount.toStringAsFixed(0)} to \$${newTargetAmount.toStringAsFixed(0)})'
            : 'Points correction: $pointsDifference (target adjusted from \$${target.targetAmount.toStringAsFixed(0)} to \$${newTargetAmount.toStringAsFixed(0)})',
        companyId: target.companyId,
        relatedTargetId: targetId,
      );

      print(
          'DEBUG: Created adjustment for ${employee.name}: ${pointsDifference > 0 ? '+' : ''}$pointsDifference points');
    }

    // Update the target with new target amount and recalculated points
    final updatedTarget = target.copyWith(
      targetAmount: newTargetAmount,
      pointsAwarded: correctPoints,
    );
    final index = _salesTargets.indexWhere((t) => t.id == targetId);
    if (index != -1) {
      _salesTargets[index] = updatedTarget;
      await StorageService.updateSalesTarget(updatedTarget);
    }

    print(
        'DEBUG: Points recalculated and adjusted - target updated from \$${target.targetAmount} to \$${newTargetAmount}, points from $currentPoints to $correctPoints');
    notifyListeners();
  }

  int getPointsForEffectivePercent(double effectivePercent,
      [String? companyId]) {
    final rules = getPointsRules(companyId);
    print(
        'DEBUG: Calculating points for $effectivePercent% in company $companyId');
    print('DEBUG: Custom rules entries: ${rules.entries.length}');

    if (rules.entries.isNotEmpty) {
      final sorted = [...rules.entries]..sort((a, b) =>
          b.thresholdPercent.compareTo(a.thresholdPercent)); // Sort descending
      print(
          'DEBUG: Sorted rules: ${sorted.map((e) => '${e.thresholdPercent}% -> ${e.points}pts').join(', ')}');

      for (final e in sorted) {
        print(
            'DEBUG: Checking rule ${e.thresholdPercent}% -> ${e.points}pts (effective: $effectivePercent%)');
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

  // Messaging methods
  Future<void> sendMessage(String recipientId, String content,
      {String? companyId}) async {
    if (_currentUser == null) return;

    final message = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: _currentUser!.id,
      recipientId: recipientId,
      content: content,
      timestamp: DateTime.now(),
      companyId: companyId,
    );

    await StorageService.addMessage(message);
    _messages.add(message);
    notifyListeners();
  }

  Future<List<Message>> getConversation(String otherUserId) async {
    if (_currentUser == null) return [];
    return await StorageService.getConversation(_currentUser!.id, otherUserId);
  }

  Future<List<User>> getConversationPartners() async {
    if (_currentUser == null) return [];

    final userMessages = _messages
        .where((message) =>
            message.senderId == _currentUser!.id ||
            message.recipientId == _currentUser!.id)
        .toList();

    final Set<String> partnerIds = {};
    for (final message in userMessages) {
      if (message.senderId == _currentUser!.id) {
        partnerIds.add(message.recipientId);
      } else {
        partnerIds.add(message.senderId);
      }
    }

    final users = await StorageService.getUsers();
    return users.where((user) => partnerIds.contains(user.id)).toList();
  }

  Future<int> getUnreadMessageCount() async {
    if (_currentUser == null) return 0;
    return await StorageService.getUnreadMessageCount(_currentUser!.id);
  }

  Future<void> markMessagesAsRead(String senderId) async {
    if (_currentUser == null) return;

    await StorageService.markMessagesAsRead(_currentUser!.id, senderId);

    // Update local messages
    for (int i = 0; i < _messages.length; i++) {
      if (_messages[i].recipientId == _currentUser!.id &&
          _messages[i].senderId == senderId &&
          !_messages[i].isRead) {
        _messages[i] = _messages[i].copyWith(isRead: true);
      }
    }
    notifyListeners();
  }

  Future<List<User>> getCompanyUsers() async {
    if (_currentUser?.primaryCompanyId == null) return [];

    final users = await StorageService.getUsers();
    return users
        .where((user) =>
            user.companyIds.contains(_currentUser!.primaryCompanyId) &&
            user.id != _currentUser!.id)
        .toList();
  }

  // Get users for a specific company (optionally excluding current user)
  Future<List<User>> getCompanyUsersFor(String companyId,
      {bool excludeCurrentUser = true}) async {
    final users = await StorageService.getUsers();
    return users.where((user) {
      final inCompany = user.companyIds.contains(companyId);
      if (!excludeCurrentUser) return inCompany;
      if (_currentUser == null) return inCompany;
      return inCompany && user.id != _currentUser!.id;
    }).toList();
  }

  // Dark mode management
  Future<void> toggleDarkMode() async {
    _isDarkMode = !_isDarkMode;
    await StorageService.setDarkMode(_isDarkMode);
    notifyListeners();
  }

  Future<void> setDarkMode(bool isDark) async {
    _isDarkMode = isDark;
    await StorageService.setDarkMode(_isDarkMode);
    notifyListeners();
  }

  Future<void> loadDarkMode() async {
    _isDarkMode = await StorageService.getDarkMode();
    notifyListeners();
  }
}
