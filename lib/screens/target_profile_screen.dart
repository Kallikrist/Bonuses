import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

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
              ? ((_currentTarget.actualAmount / _currentTarget.targetAmount) * 100).clamp(0, 100000).toDouble()
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
                            _currentTarget.assignedWorkplaceName ?? 'No Workplace',
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
                            label: Text(_currentTarget.status.name.toUpperCase()),
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
                        _kpiRow('Employee', _currentTarget.assignedEmployeeName ?? 'No Employee'),
                        _kpiRow('Target', _currentTarget.targetAmount.toStringAsFixed(0)),
                        _kpiRow('Actual', _currentTarget.actualAmount.toStringAsFixed(0)),
                        _kpiRow('Progress', '${percent.toStringAsFixed(0)}%'),
                        if (_currentTarget.pointsAwarded > 0)
                          _kpiRow('Points', _currentTarget.pointsAwarded.toString()),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Actions
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _showEditTargetDialog(context, app),
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit'),
                    ),
                    if (_currentTarget.isSubmitted && !_currentTarget.isApproved)
                      ElevatedButton.icon(
                        onPressed: () async {
                          try {
                            final pending = app.approvalRequests.firstWhere(
                              (r) => r.targetId == _currentTarget.id &&
                                      r.type == ApprovalRequestType.salesSubmission &&
                                      r.status == ApprovalStatus.pending,
                            );
                            await app.approveRequest(pending);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Submission approved')),
                            );
                          } catch (_) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('No pending submission found')),
                            );
                          }
                        },
                        icon: const Icon(Icons.check_circle),
                        label: const Text('Approve'),
                      ),
                  ],
                ),

                const SizedBox(height: 24),

                // Performance Chart
                Text(
                  'Performance Trend (Last 2 Years)',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                _buildPerformanceChart(app),

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
    final targetAmountController = TextEditingController(text: _currentTarget.targetAmount.toString());
    final actualAmountController = TextEditingController(text: _currentTarget.actualAmount.toString());
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
                        firstDate: DateTime.now().subtract(const Duration(days: 365)),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (pickedDate != null) {
                        setState(() {
                          selectedDate = pickedDate;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, color: Colors.grey.shade600),
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
                            .where((u) => u.role == UserRole.employee || u.role == UserRole.admin)
                            .toList();

                        // Set initial selected employee
                        if (selectedEmployee == null && _currentTarget.assignedEmployeeId != null) {
                          selectedEmployee = users.firstWhere(
                            (u) => u.id == _currentTarget.assignedEmployeeId,
                            orElse: () => users.first,
                          );
                        }

                        // Ensure selectedEmployee matches exactly one item in the filtered list
                        final validSelectedEmployee = selectedEmployee != null &&
                            users.any((user) => user.id == selectedEmployee!.id)
                            ? users.firstWhere((user) => user.id == selectedEmployee!.id)
                            : null;

                        return DropdownButtonFormField<User>(
                          value: validSelectedEmployee,
                          decoration: const InputDecoration(labelText: 'Employee'),
                          items: users
                              .map((user) => DropdownMenuItem(
                                    value: user,
                                    child: Text('${user.name} (${user.role.name})'),
                                  ))
                              .toList(),
                          onChanged: (User? user) => setState(() => selectedEmployee = user),
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
                        if (selectedWorkplace == null && _currentTarget.assignedWorkplaceId != null) {
                          selectedWorkplace = workplaces.firstWhere(
                            (w) => w.id == _currentTarget.assignedWorkplaceId,
                            orElse: () => workplaces.first,
                          );
                        }

                        // Ensure selectedWorkplace matches exactly one item in the workplaces list
                        final validSelectedWorkplace = selectedWorkplace != null &&
                            workplaces.any((workplace) => workplace.id == selectedWorkplace!.id)
                            ? workplaces.firstWhere((workplace) => workplace.id == selectedWorkplace!.id)
                            : null;

                        return DropdownButtonFormField<Workplace>(
                          value: validSelectedWorkplace,
                          decoration: const InputDecoration(labelText: 'Workplace'),
                          items: workplaces
                              .map((workplace) => DropdownMenuItem(
                                    value: workplace,
                                    child: Text(workplace.name),
                                  ))
                              .toList(),
                          onChanged: (Workplace? workplace) => setState(() => selectedWorkplace = workplace),
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
                    final targetAmount = double.tryParse(targetAmountController.text);
                    final actualAmount = double.tryParse(actualAmountController.text);

                    if (targetAmount != null && targetAmount > 0 && 
                        actualAmount != null && actualAmount >= 0) {
                      // Recalculate target status based on new target amount vs new actual amount
                      final isTargetMet = actualAmount >= targetAmount;
                      final newStatus = isTargetMet ? TargetStatus.met : TargetStatus.missed;
                      final percentageAbove = isTargetMet
                          ? ((actualAmount - targetAmount) / targetAmount) * 100
                          : 0.0;

                      // Calculate points based on admin-configured rules if target is met
                      int pointsAwarded = 0;
                      if (isTargetMet) {
                        final effectivePercent = 100.0 + percentageAbove;
                        print('DEBUG: Target edit - effectivePercent: $effectivePercent, percentageAbove: $percentageAbove');
                        print('DEBUG: Target edit - actualAmount: $actualAmount, targetAmount: $targetAmount');
                        print('DEBUG: Target edit - pointsRules: ${app.pointsRules.entries.length} custom rules');
                        print('DEBUG: Target edit - legacy rules - 200%: ${app.pointsRules.pointsForDoubleTarget}, 110%: ${app.pointsRules.pointsForTenPercentAbove}, 100%: ${app.pointsRules.pointsForMet}');
                        pointsAwarded = app.getPointsForEffectivePercent(effectivePercent);
                        print('DEBUG: Target edit - pointsAwarded: $pointsAwarded');
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
                          teamMemberNames.add(updatedTarget.assignedEmployeeName ?? 'Unknown');
                        }

                        // Add collaborative team members
                        teamMemberIds.addAll(updatedTarget.collaborativeEmployeeIds);
                        teamMemberNames.addAll(updatedTarget.collaborativeEmployeeNames);

                        // Award points to each team member
                        for (int i = 0; i < teamMemberIds.length; i++) {
                          final memberId = teamMemberIds[i];
                          
                          final transaction = PointsTransaction(
                            id: '${DateTime.now().millisecondsSinceEpoch}_edit_${memberId}_${updatedTarget.id}',
                            userId: memberId,
                            type: PointsTransactionType.earned,
                            points: pointsAwarded,
                            description: 'Target completed: ${updatedTarget.assignedWorkplaceName ?? 'Unknown Store'} - ${updatedTarget.date.day}/${updatedTarget.date.month}/${updatedTarget.date.year}',
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
                            ? 'Target updated successfully! ${pointsAwarded} points awarded to team members.'
                            : 'Target updated successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter valid target and actual amounts'),
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

  Widget _buildPerformanceChart(AppProvider app) {
    // Get individual targets instead of monthly aggregations
    final now = DateTime.now();
    final startDate = DateTime(now.year - 2, now.month, 1);
    
    final filteredTargets = app.salesTargets.where((target) {
      if (target.date.isBefore(startDate)) return false;
      if (_currentTarget.assignedEmployeeId != null && target.assignedEmployeeId != _currentTarget.assignedEmployeeId) return false;
      if (_currentTarget.assignedWorkplaceId != null && target.assignedWorkplaceId != _currentTarget.assignedWorkplaceId) return false;
      return true;
    }).toList();

    // Sort by date
    filteredTargets.sort((a, b) => a.date.compareTo(b.date));

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

    // Prepare chart data - show individual targets
    final spots = <FlSpot>[];
    final targetSpots = <FlSpot>[];
    final labels = <String>[];

    for (int i = 0; i < filteredTargets.length; i++) {
      final target = filteredTargets[i];
      
      spots.add(FlSpot(i.toDouble(), target.actualAmount));
      targetSpots.add(FlSpot(i.toDouble(), target.targetAmount));
      
      // Format date label to show just the year (24, 25)
      final year = target.date.year;
      final yearShort = year.toString().substring(2);
      labels.add(yearShort);
    }

    return Column(
      children: [
        // Legend
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 12,
              height: 2,
              color: Colors.blue,
            ),
            const SizedBox(width: 8),
            const Text('Target', style: TextStyle(fontSize: 12)),
            const SizedBox(width: 16),
            Container(
              width: 12,
              height: 2,
              color: Colors.green,
            ),
            const SizedBox(width: 8),
            const Text('Actual', style: TextStyle(fontSize: 12)),
          ],
        ),
        const SizedBox(height: 8),
        // Chart
        Container(
          height: 200,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: LineChart(
        LineChartData(
          gridData: FlGridData(show: true),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(fontSize: 10),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= 0 && value.toInt() < labels.length) {
                    // Show year labels (24, 25) for each target
                    return Text(
                      labels[value.toInt()],
                      style: const TextStyle(fontSize: 10),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: true),
          lineBarsData: [
            // Target points (blue dots)
            LineChartBarData(
              spots: targetSpots,
              isCurved: false,
              color: Colors.blue,
              barWidth: 0,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 6,
                    color: Colors.blue,
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  );
                },
              ),
            ),
            // Actual points (green dots)
            LineChartBarData(
              spots: spots,
              isCurved: false,
              color: Colors.green,
              barWidth: 0,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 6,
                    color: Colors.green,
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ),
      ],
    );
  }
}


