import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/sales_target.dart';
import '../models/user.dart';
import '../models/workplace.dart';
import '../models/points_transaction.dart';
import '../providers/app_provider.dart';
import '../models/approval_request.dart';

class TargetProfileScreen extends StatefulWidget {
  final SalesTarget target;

  const TargetProfileScreen({super.key, required this.target});

  @override
  State<TargetProfileScreen> createState() => _TargetProfileScreenState();
}

class _TargetProfileScreenState extends State<TargetProfileScreen> {
  late SalesTarget _currentTarget;

  @override
  void initState() {
    super.initState();
    _currentTarget = widget.target;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Target Profile'),
      ),
      body: Consumer<AppProvider>(
        builder: (context, app, _) {
          // Update current target from app state
          final updatedTarget = app.salesTargets.firstWhere(
            (t) => t.id == _currentTarget.id,
            orElse: () => _currentTarget,
          );
          if (updatedTarget != _currentTarget) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              setState(() {
                _currentTarget = updatedTarget;
              });
            });
          }

          final dateStr = DateFormat('MMM d, yyyy').format(_currentTarget.date);
          final statusColor = _statusColor(_currentTarget.status);
          final percent = _currentTarget.targetAmount > 0
              ? ((_currentTarget.actualAmount / _currentTarget.targetAmount) *
                      100)
                  .clamp(0, 100000)
                  .toDouble()
              : 0.0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      backgroundColor: statusColor,
                      child: Icon(
                        _statusIcon(_currentTarget.status),
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _currentTarget.assignedWorkplaceName ??
                                'No Workplace',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            dateStr,
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                          const SizedBox(height: 4),
                          Chip(
                            label:
                                Text(_currentTarget.status.name.toUpperCase()),
                            backgroundColor: statusColor.withOpacity(0.15),
                            labelStyle: TextStyle(color: statusColor),
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // KPIs
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _kpiRow(
                            'Employee',
                            _currentTarget.assignedEmployeeName ??
                                'No Employee'),
                        _kpiRow('Target',
                            _currentTarget.targetAmount.toStringAsFixed(0)),
                        _kpiRow('Actual',
                            _currentTarget.actualAmount.toStringAsFixed(0)),
                        _kpiRow('Progress', '${percent.toStringAsFixed(0)}%'),
                        if (_currentTarget.pointsAwarded > 0)
                          _kpiRow('Points',
                              _currentTarget.pointsAwarded.toString()),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Performance Chart (moved above team members)
                _ExpandableSectionWidget(
                  title: 'Performance Trend (Last 2 Years)',
                  icon: Icons.trending_up,
                  iconColor: Colors.blue[600]!,
                  initiallyExpanded: true,
                  children: [
                    _buildPerformanceChart(app),
                  ],
                ),

                const SizedBox(height: 16),

                // Team Members Section (if any)
                if (_currentTarget.collaborativeEmployeeIds.isNotEmpty) ...[
                  _ExpandableSectionWidget(
                    title:
                        'Team Members (${_currentTarget.collaborativeEmployeeIds.length})',
                    icon: Icons.group,
                    iconColor: Colors.purple,
                    initiallyExpanded: true,
                    children: [
                      _buildTeamMembersContent(app),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

                // Points History Section (if approved)
                if (_currentTarget.isApproved &&
                    _currentTarget.pointsAwarded > 0) ...[
                  _ExpandableSectionWidget(
                    title: 'Points History',
                    icon: Icons.history,
                    iconColor: Colors.green,
                    initiallyExpanded: false,
                    children: [
                      _buildPointsHistoryContent(app),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

                // Adjustments History (Admin View)
                if (app.currentUser?.role == UserRole.admin) ...[
                  _ExpandableSectionWidget(
                    title: 'Adjustments History',
                    icon: Icons.tune,
                    iconColor: Colors.orange,
                    initiallyExpanded: false,
                    children: [
                      _buildAdjustmentsHistoryContent(app),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

                // Actions
                Builder(builder: (context) {
                  final currentUser = app.currentUser;
                  final isAdmin = currentUser?.role == UserRole.admin;
                  final isMember = currentUser != null &&
                      (_currentTarget.assignedEmployeeId == currentUser.id ||
                          _currentTarget.collaborativeEmployeeIds
                              .contains(currentUser.id));

                  return Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      if (isAdmin) ...[
                        OutlinedButton.icon(
                          onPressed: () => _showEditTargetDialog(context, app),
                          icon: const Icon(Icons.edit),
                          label: const Text('Edit'),
                        ),
                        if (_currentTarget.isSubmitted &&
                            !_currentTarget.isApproved)
                          ElevatedButton.icon(
                            onPressed: () async {
                              try {
                                final pending = app.approvalRequests.firstWhere(
                                  (r) =>
                                      r.targetId == _currentTarget.id &&
                                      r.type ==
                                          ApprovalRequestType.salesSubmission &&
                                      r.status == ApprovalStatus.pending,
                                );
                                await app.approveRequest(pending);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Submission approved')),
                                );
                              } catch (_) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content:
                                          Text('No pending submission found')),
                                );
                              }
                            },
                            icon: const Icon(Icons.check_circle),
                            label: const Text('Approve'),
                          ),
                      ] else if (currentUser != null && !isMember) ...[
                        ElevatedButton.icon(
                          onPressed: () async {
                            // Request to join target as team member
                            final newIds = <String>{
                              ..._currentTarget.collaborativeEmployeeIds,
                            }..add(currentUser.id);
                            final newNames = <String>{
                              ..._currentTarget.collaborativeEmployeeNames,
                            }..add(currentUser.name);

                            await app.submitTeamChange(
                              _currentTarget.id,
                              newIds.toList(),
                              newNames.toList(),
                              currentUser.id,
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Join request sent for approval'),
                              ),
                            );
                          },
                          icon: const Icon(Icons.group_add),
                          label: const Text('Request to Join'),
                        ),
                      ] else if (currentUser != null && isMember) ...[
                        ElevatedButton.icon(
                          onPressed: () {
                            _showSubmitSalesDialog(
                                context, _currentTarget, app);
                          },
                          icon: const Icon(Icons.upload),
                          label: const Text('Submit Sales'),
                        ),
                      ],
                    ],
                  );
                }),

                const SizedBox(height: 24),

                // Recent activity placeholder (submissions/approvals/team changes)
                Text(
                  'Recent Activity',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Builder(builder: (context) {
                  final items = app.approvalRequests
                      .where((r) => r.targetId == _currentTarget.id)
                      .toList()
                    ..sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
                  if (items.isEmpty) {
                    return Text(
                      'No recent activity',
                      style: TextStyle(color: Colors.grey[600]),
                    );
                  }
                  return Column(
                    children: items
                        .map(
                          (r) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(
                              r.type == ApprovalRequestType.salesSubmission
                                  ? Icons.point_of_sale
                                  : Icons.group_add,
                              color: Colors.blueGrey,
                            ),
                            title: Text(r.type.name),
                            subtitle: Text(
                                '${DateFormat('MMM d, yyyy – HH:mm').format(r.submittedAt)} • ${r.status.name}'),
                          ),
                        )
                        .toList(),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _kpiRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.black54),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Color _statusColor(TargetStatus status) {
    switch (status) {
      case TargetStatus.pending:
      case TargetStatus.submitted:
        return Colors.blue;
      case TargetStatus.missed:
        return Colors.red;
      case TargetStatus.met:
      case TargetStatus.approved:
        return Colors.green;
    }
  }

  IconData _statusIcon(TargetStatus status) {
    switch (status) {
      case TargetStatus.pending:
        return Icons.pending;
      case TargetStatus.met:
        return Icons.check_circle;
      case TargetStatus.missed:
        return Icons.cancel;
      case TargetStatus.submitted:
        return Icons.hourglass_empty;
      case TargetStatus.approved:
        return Icons.verified;
    }
  }

  void _showEditTargetDialog(BuildContext context, AppProvider app) {
    final targetAmountController =
        TextEditingController(text: _currentTarget.targetAmount.toString());
    final actualAmountController =
        TextEditingController(text: _currentTarget.actualAmount.toString());
    User? selectedEmployee;
    Workplace? selectedWorkplace;
    DateTime selectedDate = _currentTarget.date;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Edit Target'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Date Picker
                  GestureDetector(
                    onTap: () async {
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate:
                            DateTime.now().subtract(const Duration(days: 365)),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (pickedDate != null) {
                        setState(() {
                          selectedDate = pickedDate;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today,
                              color: Colors.grey.shade600),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat('MMM d, yyyy').format(selectedDate),
                            style: const TextStyle(color: Colors.black87),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Target Amount
                  TextField(
                    controller: targetAmountController,
                    decoration: const InputDecoration(
                      labelText: 'Target Amount',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),

                  // Actual Amount
                  TextField(
                    controller: actualAmountController,
                    decoration: const InputDecoration(
                      labelText: 'Actual Sales Amount',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),

                  // Employee Dropdown
                  FutureBuilder<List<User>>(
                    future: app.getUsers(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Container(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            'Error loading users: ${snapshot.error}',
                            style: const TextStyle(color: Colors.red),
                          ),
                        );
                      }
                      if (snapshot.hasData) {
                        final allUsers = snapshot.data!;
                        final users = allUsers
                            .where((u) =>
                                u.role == UserRole.employee ||
                                u.role == UserRole.admin)
                            .toList();

                        // Set initial selected employee
                        if (selectedEmployee == null &&
                            _currentTarget.assignedEmployeeId != null) {
                          selectedEmployee = users.firstWhere(
                            (u) => u.id == _currentTarget.assignedEmployeeId,
                            orElse: () => users.first,
                          );
                        }

                        // Ensure selectedEmployee matches exactly one item in the filtered list
                        final validSelectedEmployee = selectedEmployee !=
                                    null &&
                                users.any(
                                    (user) => user.id == selectedEmployee!.id)
                            ? users.firstWhere(
                                (user) => user.id == selectedEmployee!.id)
                            : null;

                        return DropdownButtonFormField<User>(
                          value: validSelectedEmployee,
                          decoration:
                              const InputDecoration(labelText: 'Employee'),
                          items: users
                              .map((user) => DropdownMenuItem(
                                    value: user,
                                    child: Text(
                                        '${user.name} (${user.role.name})'),
                                  ))
                              .toList(),
                          onChanged: (User? user) =>
                              setState(() => selectedEmployee = user),
                        );
                      }
                      return Container(
                        padding: const EdgeInsets.all(8.0),
                        child: const CircularProgressIndicator(),
                      );
                    },
                  ),

                  // Workplace Dropdown
                  FutureBuilder<List<Workplace>>(
                    future: app.getWorkplaces(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Container(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            'Error loading workplaces: ${snapshot.error}',
                            style: const TextStyle(color: Colors.red),
                          ),
                        );
                      }
                      if (snapshot.hasData) {
                        final workplaces = snapshot.data!;

                        // Set initial selected workplace
                        if (selectedWorkplace == null &&
                            _currentTarget.assignedWorkplaceId != null) {
                          selectedWorkplace = workplaces.firstWhere(
                            (w) => w.id == _currentTarget.assignedWorkplaceId,
                            orElse: () => workplaces.first,
                          );
                        }

                        // Ensure selectedWorkplace matches exactly one item in the workplaces list
                        final validSelectedWorkplace =
                            selectedWorkplace != null &&
                                    workplaces.any((workplace) =>
                                        workplace.id == selectedWorkplace!.id)
                                ? workplaces.firstWhere((workplace) =>
                                    workplace.id == selectedWorkplace!.id)
                                : null;

                        return DropdownButtonFormField<Workplace>(
                          value: validSelectedWorkplace,
                          decoration:
                              const InputDecoration(labelText: 'Workplace'),
                          items: workplaces
                              .map((workplace) => DropdownMenuItem(
                                    value: workplace,
                                    child: Text(workplace.name),
                                  ))
                              .toList(),
                          onChanged: (Workplace? workplace) =>
                              setState(() => selectedWorkplace = workplace),
                        );
                      }
                      return Container(
                        padding: const EdgeInsets.all(8.0),
                        child: const CircularProgressIndicator(),
                      );
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final currentUser = app.currentUser;
                  if (targetAmountController.text.isNotEmpty &&
                      actualAmountController.text.isNotEmpty &&
                      selectedEmployee != null &&
                      selectedWorkplace != null &&
                      currentUser != null) {
                    final targetAmount =
                        double.tryParse(targetAmountController.text);
                    final actualAmount =
                        double.tryParse(actualAmountController.text);

                    if (targetAmount != null &&
                        targetAmount > 0 &&
                        actualAmount != null &&
                        actualAmount >= 0) {
                      // Recalculate target status based on new target amount vs new actual amount
                      final isTargetMet = actualAmount >= targetAmount;

                      // Only mark as missed if the date has passed
                      final now = DateTime.now();
                      final dateHasPassed = selectedDate
                          .isBefore(DateTime(now.year, now.month, now.day));

                      TargetStatus newStatus;
                      if (isTargetMet) {
                        newStatus = TargetStatus.met;
                      } else if (dateHasPassed) {
                        newStatus = TargetStatus.missed;
                      } else {
                        newStatus = TargetStatus.pending;
                      }

                      final percentageAbove = isTargetMet
                          ? ((actualAmount - targetAmount) / targetAmount) * 100
                          : 0.0;

                      // Calculate points based on admin-configured rules if target is met
                      int pointsAwarded = 0;
                      if (isTargetMet) {
                        final effectivePercent = 100.0 + percentageAbove;
                        final targetRules =
                            app.getPointsRules(_currentTarget.companyId);
                        print(
                            'DEBUG: Target edit - effectivePercent: $effectivePercent, percentageAbove: $percentageAbove');
                        print(
                            'DEBUG: Target edit - actualAmount: $actualAmount, targetAmount: $targetAmount');
                        print(
                            'DEBUG: Target edit - pointsRules: ${targetRules.entries.length} custom rules');
                        print(
                            'DEBUG: Target edit - legacy rules - 200%: ${targetRules.pointsForDoubleTarget}, 110%: ${targetRules.pointsForTenPercentAbove}, 100%: ${targetRules.pointsForMet}');
                        pointsAwarded = app.getPointsForEffectivePercent(
                            effectivePercent, _currentTarget.companyId);
                        print(
                            'DEBUG: Target edit - pointsAwarded: $pointsAwarded');
                      }

                      final updatedTarget = _currentTarget.copyWith(
                        date: selectedDate,
                        targetAmount: targetAmount,
                        actualAmount: actualAmount,
                        assignedEmployeeId: selectedEmployee!.id,
                        assignedEmployeeName: selectedEmployee!.name,
                        assignedWorkplaceId: selectedWorkplace!.id,
                        assignedWorkplaceName: selectedWorkplace!.name,
                        isMet: isTargetMet,
                        status: newStatus,
                        percentageAboveTarget: percentageAbove,
                        pointsAwarded: pointsAwarded,
                      );

                      await app.updateSalesTarget(updatedTarget);

                      // Award points to team members if target is met and points are available
                      if (isTargetMet && pointsAwarded > 0) {
                        // Get all team members (primary assignee + collaborators)
                        final List<String> teamMemberIds = [];
                        final List<String> teamMemberNames = [];

                        if (updatedTarget.assignedEmployeeId != null) {
                          teamMemberIds.add(updatedTarget.assignedEmployeeId!);
                          teamMemberNames.add(
                              updatedTarget.assignedEmployeeName ?? 'Unknown');
                        }

                        // Add collaborative team members
                        teamMemberIds
                            .addAll(updatedTarget.collaborativeEmployeeIds);
                        teamMemberNames
                            .addAll(updatedTarget.collaborativeEmployeeNames);

                        // Award points to each team member
                        for (int i = 0; i < teamMemberIds.length; i++) {
                          final memberId = teamMemberIds[i];

                          final transaction = PointsTransaction(
                            id: '${DateTime.now().millisecondsSinceEpoch}_edit_${memberId}_${updatedTarget.id}',
                            userId: memberId,
                            type: PointsTransactionType.earned,
                            points: pointsAwarded,
                            description:
                                'Target completed: ${updatedTarget.assignedWorkplaceName ?? 'Unknown Store'} - ${updatedTarget.date.day}/${updatedTarget.date.month}/${updatedTarget.date.year}',
                            date: DateTime.now(),
                            relatedTargetId: updatedTarget.id,
                          );

                          await app.addPointsTransaction(transaction);
                        }
                      }

                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(isTargetMet && pointsAwarded > 0
                              ? 'Target updated successfully! $pointsAwarded points awarded to team members.'
                              : 'Target updated successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Please enter valid target and actual amounts'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  } else if (currentUser == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Error: No user logged in'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please fill all fields'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: const Text('Update'),
              ),
            ],
          );
        },
      ),
    );
  }

  // Lightweight submit sales dialog scoped to Target Profile screen
  void _showSubmitSalesDialog(
      BuildContext context, SalesTarget target, AppProvider app) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Submit Sales'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Target: ${target.targetAmount.toStringAsFixed(0)}'),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Your Actual Sales',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(controller.text);
              final user = app.currentUser;
              if (amount == null || amount < 0 || user == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Enter a valid amount'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              await app.submitEmployeeSales(target.id, amount, user.id);
              if (context.mounted) Navigator.pop(context);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(amount >= target.targetAmount
                        ? 'Sales submitted — target met (awaiting approval)'
                        : 'Sales submitted for review'),
                  ),
                );
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceChart(AppProvider app) {
    // Filter similar to previous logic, but render with the same simple bar style
    final filteredTargets = app.salesTargets.where((target) {
      if (_currentTarget.assignedWorkplaceId != target.assignedWorkplaceId) {
        return false;
      }
      if (target.date.month != _currentTarget.date.month ||
          target.date.day != _currentTarget.date.day) {
        return false;
      }
      return true;
    }).toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    if (filteredTargets.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Text(
            'No historical data available',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    // Determine scale
    final maxValue = filteredTargets
        .map((t) =>
            t.targetAmount > t.actualAmount ? t.targetAmount : t.actualAmount)
        .fold<double>(0, (prev, el) => el > prev ? el : prev);

    // Build simple, rounded bars similar to weekly chart
    final labels = filteredTargets
        .map((t) => t.date.year.toString().substring(2))
        .toList();

    return Container(
      height: 220,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (int i = 0; i < filteredTargets.length; i++)
              Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Bars group (Target + Actual), aligned to bottom
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Target (blue) with value label
                      Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            filteredTargets[i].targetAmount.toStringAsFixed(0),
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.blue[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: 16,
                            height: (filteredTargets[i].targetAmount /
                                    maxValue *
                                    150)
                                .clamp(8, 150),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 6),
                      // Actual (met=green / missed=red) with value label
                      Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            filteredTargets[i].actualAmount.toStringAsFixed(0),
                            style: TextStyle(
                              fontSize: 10,
                              color: filteredTargets[i].actualAmount >=
                                      filteredTargets[i].targetAmount
                                  ? Colors.green[700]
                                  : Colors.red[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: 16,
                            height: (filteredTargets[i].actualAmount /
                                    maxValue *
                                    150)
                                .clamp(8, 150),
                            decoration: BoxDecoration(
                              color: filteredTargets[i].actualAmount >=
                                      filteredTargets[i].targetAmount
                                  ? Colors.green
                                  : Colors.red,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    labels[i],
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamMembersContent(AppProvider app) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...List.generate(
          _currentTarget.collaborativeEmployeeNames.length,
          (index) {
            final name = _currentTarget.collaborativeEmployeeNames[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.purple.shade200),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.purple.shade100,
                    radius: 16,
                    child: Text(
                      name[0].toUpperCase(),
                      style: TextStyle(
                        color: Colors.purple.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  if (_currentTarget.isApproved &&
                      _currentTarget.pointsAwarded > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '+${_currentTarget.pointsAwarded} pts',
                        style: TextStyle(
                          color: Colors.purple.shade700,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPointsHistoryContent(AppProvider app) {
    return FutureBuilder<List<PointsTransaction>>(
      future: _getTargetPointsTransactions(app),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Text(
            'No points history available',
            style: TextStyle(color: Colors.grey),
          );
        }

        final transactions = snapshot.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...transactions.map((tx) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          tx.type == PointsTransactionType.earned
                              ? Icons.add_circle
                              : tx.type == PointsTransactionType.adjustment
                                  ? Icons.tune
                                  : Icons.remove_circle,
                          color: tx.type == PointsTransactionType.earned
                              ? Colors.green
                              : tx.type == PointsTransactionType.adjustment
                                  ? Colors.orange
                                  : Colors.red,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            tx.description,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Text(
                          '${tx.type == PointsTransactionType.redeemed || tx.points < 0 ? '-' : '+'}${tx.points.abs()} pts',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: tx.type == PointsTransactionType.earned
                                ? Colors.green
                                : tx.type == PointsTransactionType.adjustment
                                    ? Colors.orange
                                    : Colors.red,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('MMM dd, yyyy • h:mm a').format(tx.date),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        );
      },
    );
  }

  Widget _buildAdjustmentsHistoryContent(AppProvider app) {
    return FutureBuilder<List<PointsTransaction>>(
      future: _getAllTargetTransactions(app),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Text(
            'Loading adjustments...',
            style: TextStyle(color: Colors.grey),
          );
        }

        final transactions = snapshot.data!;
        final adjustments = transactions
            .where((t) => t.type == PointsTransactionType.adjustment)
            .toList();

        if (adjustments.isEmpty) {
          return const Text(
            'No adjustments found',
            style: TextStyle(color: Colors.grey),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...adjustments.map((tx) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            tx.description,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Text(
                          '${tx.points < 0 ? '' : '+'}${tx.points} pts',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: tx.points < 0 ? Colors.red : Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    FutureBuilder<String>(
                      future: _getUserName(tx.userId, app),
                      builder: (context, userSnapshot) {
                        return Text(
                          'User: ${userSnapshot.data ?? tx.userId} • ${DateFormat('MMM dd, h:mm a').format(tx.date)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        );
      },
    );
  }

  Future<List<PointsTransaction>> _getTargetPointsTransactions(
      AppProvider app) async {
    final allTransactions = await app.getAllPointsTransactions();
    return allTransactions
        .where((t) => t.relatedTargetId == _currentTarget.id)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  Future<List<PointsTransaction>> _getAllTargetTransactions(
      AppProvider app) async {
    final allTransactions = await app.getAllPointsTransactions();
    return allTransactions
        .where((t) => t.relatedTargetId == _currentTarget.id)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  Future<String> _getUserName(String userId, AppProvider app) async {
    final users = await app.getUsers();
    final user = users.firstWhere(
      (u) => u.id == userId,
      orElse: () => User(
        id: userId,
        name: 'Unknown User',
        email: '',
        role: UserRole.employee,
        primaryCompanyId: '',
        companyIds: [],
        companyRoles: {},
        createdAt: DateTime.now(),
      ),
    );
    return user.name;
  }
}

class _ExpandableSectionWidget extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final List<Widget> children;
  final bool initiallyExpanded;

  const _ExpandableSectionWidget({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.children,
    this.initiallyExpanded = false,
  });

  @override
  State<_ExpandableSectionWidget> createState() =>
      _ExpandableSectionWidgetState();
}

class _ExpandableSectionWidgetState extends State<_ExpandableSectionWidget> {
  late bool isExpanded;

  @override
  void initState() {
    super.initState();
    isExpanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => isExpanded = !isExpanded),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(widget.icon, color: widget.iconColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.keyboard_arrow_down),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            child: isExpanded
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: widget.children,
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
