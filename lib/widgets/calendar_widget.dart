import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/sales_target.dart';
import '../models/user.dart';
import '../models/workplace.dart';
import '../models/approval_request.dart';
import '../providers/app_provider.dart';

class CalendarPage extends StatefulWidget {
  final DateTime? selectedDate;
  final Function(DateTime)? onDateSelected;
  final List<DateTime>? highlightedDates;
  final String? title;
  final List<SalesTarget>? salesTargets;

  const CalendarPage({
    super.key,
    this.selectedDate,
    this.onDateSelected,
    this.highlightedDates,
    this.title,
    this.salesTargets,
  });

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  late DateTime _currentMonth;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _currentMonth = widget.selectedDate ?? DateTime.now();
    _selectedDate = widget.selectedDate ?? DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(widget.title ?? 'Calendar'),
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back),
            ),
            actions: [
              IconButton(
                onPressed: () => _showCalendarOptions(context),
                icon: const Icon(Icons.more_vert),
                tooltip: 'Calendar Options',
              ),
              if (widget.onDateSelected != null)
                TextButton(
                  onPressed: () {
                    widget.onDateSelected?.call(_selectedDate);
                    Navigator.of(context).pop();
                  },
                  child: const Text('Select'),
                ),
            ],
          ),
          body: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Calendar
                Expanded(
                  flex: 1,
                  child: _buildCalendar(context),
                ),

                // Sales Targets for selected date
                Expanded(
                  flex: 2,
                  child: _buildSalesTargets(context),
                ),
              ],
            ),
          ),
          // Floating action buttons for admins
          floatingActionButton: appProvider.isAdmin ? _buildAdminFABs(context, appProvider) : null,
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        );
      },
    );
  }

  Widget _buildCalendar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Month Navigation
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: _previousMonth,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.chevron_left,
                      color: Colors.grey,
                      size: 16,
                    ),
                  ),
                ),
                Text(
                  DateFormat('MMMM yyyy').format(_currentMonth),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                GestureDetector(
                  onTap: _nextMonth,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.chevron_right,
                      color: Colors.grey,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Days of Week Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                  .map(
                    (day) => Expanded(
                      child: Center(
                        child: Text(
                          day,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),

          const SizedBox(height: 8),

          // Calendar Grid
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildCalendarGrid(context),
            ),
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid(BuildContext context) {
    final firstDayOfMonth =
        DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastDayOfMonth =
        DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    final firstDayOfWeek = (firstDayOfMonth.weekday - 1) % 7; // Monday = 0

    final daysInMonth = lastDayOfMonth.day;
    final totalCells = firstDayOfWeek + daysInMonth;
    final rows = (totalCells / 7).ceil();

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1.2,
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
      ),
      itemCount: rows * 7,
      itemBuilder: (context, index) {
        final dayIndex = index - firstDayOfWeek;

        if (dayIndex < 0 || dayIndex >= daysInMonth) {
          return const SizedBox(); // Empty cell
        }

        final day = dayIndex + 1;
        final date = DateTime(_currentMonth.year, _currentMonth.month, day);
        final isSelected = _isSameDay(date, _selectedDate);
        final isToday = _isSameDay(date, DateTime.now());
        final isHighlighted =
            widget.highlightedDates?.any((d) => _isSameDay(d, date)) ?? false;
        final hasSalesTarget = _hasSalesTargetForDate(date);
        final targetStatus = _getTargetStatusForDate(date);

        return _buildDayCell(context, date, day, isSelected, isToday,
            isHighlighted, hasSalesTarget, targetStatus);
      },
    );
  }

  Widget _buildDayCell(
      BuildContext context,
      DateTime date,
      int day,
      bool isSelected,
      bool isToday,
      bool isHighlighted,
      bool hasSalesTarget,
      TargetStatus? targetStatus) {
    return GestureDetector(
      onTap: () => _selectDate(date),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF007AFF)
              : isToday
                  ? const Color(0xFF007AFF).withOpacity(0.1)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          children: [
            Center(
              child: Text(
                day.toString(),
                style: TextStyle(
                  fontSize: 15,
                  color: isSelected
                      ? Colors.white
                      : isToday
                          ? const Color(0xFF007AFF)
                          : Colors.black87,
                  fontWeight:
                      isSelected || isToday ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
            // Dot indicators for highlighted dates and sales targets
            if ((isHighlighted || hasSalesTarget) && !isSelected)
              Positioned(
                bottom: 4,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: _getDotColorForTargetStatus(
                          targetStatus, isHighlighted),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    });
  }

  void _selectDate(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
  }

  Widget _buildSalesTargets(BuildContext context) {
    final salesTargets =
        _getSalesTargetsForDate(_selectedDate, widget.salesTargets ?? []);

    return Container(
      margin: const EdgeInsets.only(top: 20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Sales Targets - ${DateFormat('MMM dd, yyyy').format(_selectedDate)}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),

          // Sales targets list
          Expanded(
            child: salesTargets.isEmpty
                ? Center(
                    child: Text(
                      'No sales targets for this date',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: salesTargets.length,
                    itemBuilder: (context, index) {
                      final target = salesTargets[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: _getTargetColorFromStatus(target.status),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${target.assignedEmployeeName ?? 'Unassigned'} - ${target.assignedWorkplaceName ?? 'No Workplace'}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Target: \$${target.targetAmount.toStringAsFixed(0)} | Actual: \$${target.actualAmount.toStringAsFixed(0)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  if (target
                                      .collaborativeEmployeeNames.isNotEmpty)
                                    Text(
                                      'Collaborators: ${target.collaborativeEmployeeNames.join(', ')}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getTargetColorFromStatus(target.status)
                                    .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _getStatusText(target.status),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      _getTargetColorFromStatus(target.status),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  List<SalesTarget> _getSalesTargetsForDate(
      DateTime date, List<SalesTarget> allTargets) {
    // Filter targets for the selected date
    return allTargets.where((target) {
      return _isSameDay(target.date, date);
    }).toList();
  }

  Color _getTargetColorFromStatus(TargetStatus status) {
    switch (status) {
      case TargetStatus.met:
        return Colors.green;
      case TargetStatus.pending:
        return Colors.blue;
      case TargetStatus.submitted:
        return Colors.orange;
      case TargetStatus.approved:
        return Colors.green;
      case TargetStatus.missed:
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  String _getStatusText(TargetStatus status) {
    switch (status) {
      case TargetStatus.pending:
        return 'Pending';
      case TargetStatus.met:
        return 'Met';
      case TargetStatus.missed:
        return 'Missed';
      case TargetStatus.submitted:
        return 'Submitted';
      case TargetStatus.approved:
        return 'Approved';
      default:
        return 'Unknown';
    }
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  bool _hasSalesTargetForDate(DateTime date) {
    if (widget.salesTargets == null || widget.salesTargets!.isEmpty) {
      return false;
    }

    return widget.salesTargets!.any((target) => _isSameDay(target.date, date));
  }

  TargetStatus? _getTargetStatusForDate(DateTime date) {
    if (widget.salesTargets == null || widget.salesTargets!.isEmpty) {
      return null;
    }

    final targetsForDate = widget.salesTargets!
        .where((target) => _isSameDay(target.date, date))
        .toList();

    if (targetsForDate.isEmpty) {
      return null;
    }

    // If all targets are pending, return pending
    if (targetsForDate
        .every((target) => target.status == TargetStatus.pending)) {
      return TargetStatus.pending;
    }

    // If all targets are approved/succeeded, return approved
    if (targetsForDate.every((target) =>
        target.status == TargetStatus.approved ||
        target.status == TargetStatus.met)) {
      return TargetStatus.approved;
    }

    // If any target is submitted (waiting for approval), return submitted
    if (targetsForDate
        .any((target) => target.status == TargetStatus.submitted)) {
      return TargetStatus.submitted;
    }

    // If any target is approved but not all, return submitted (mixed state)
    if (targetsForDate.any((target) =>
        target.status == TargetStatus.approved ||
        target.status == TargetStatus.met)) {
      return TargetStatus.submitted;
    }

    // Default to pending if there are targets but unclear status
    return TargetStatus.pending;
  }

  Color _getDotColorForTargetStatus(
      TargetStatus? targetStatus, bool isHighlighted) {
    // If it's just a highlighted date (no sales target), use blue
    if (targetStatus == null && isHighlighted) {
      return const Color(0xFF007AFF); // Blue for highlighted dates
    }

    // If there's no target status, use blue (shouldn't happen with hasSalesTarget check)
    if (targetStatus == null) {
      return const Color(0xFF007AFF); // Blue
    }

    // Color code based on target status
    switch (targetStatus) {
      case TargetStatus.pending:
        return Colors.blue; // Blue for pending targets
      case TargetStatus.submitted:
        return Colors.orange; // Yellow/Orange for waiting approval
      case TargetStatus.approved:
      case TargetStatus.met:
        return Colors.green; // Green for succeeded/approved
      case TargetStatus.missed:
        return Colors.red; // Red for missed targets
      default:
        return Colors.blue; // Default to blue
    }
  }

  void _showCalendarOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // Title
            const Text(
              'Calendar Options',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 20),

            // Options
            _buildOptionTile(
              context,
              icon: Icons.today,
              title: 'Go to Today',
              subtitle: 'Jump to current date',
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _selectedDate = DateTime.now();
                  _currentMonth = DateTime.now();
                });
              },
            ),

            _buildOptionTile(
              context,
              icon: Icons.calendar_month,
              title: 'Browse Months',
              subtitle: 'View extended calendar',
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement extended calendar view
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Extended calendar view coming soon!'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF007AFF).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: const Color(0xFF007AFF),
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey[600],
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
    );
  }

  void _showAddTargetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AddTargetDialog(
        selectedDate: _selectedDate,
        onTargetAdded: () {
          // Refresh the calendar to show the new target
          setState(() {});
        },
      ),
    );
  }

  Widget _buildAdminFABs(BuildContext context, AppProvider appProvider) {
    // Get targets for the selected date
    final selectedDateTargets = _getSalesTargetsForDate(_selectedDate, widget.salesTargets ?? []);
    
    // Find met targets that need approval
    final metTargetsToApprove = selectedDateTargets.where((target) => 
      target.actualAmount >= target.targetAmount &&  // Met the target
      !target.isApproved && 
      target.status != TargetStatus.approved &&
      target.actualAmount > 0
    ).toList();

    // If there are met targets to approve, show both buttons
    if (metTargetsToApprove.isNotEmpty) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Approve All button
          FloatingActionButton.extended(
            onPressed: () => _approveAllMetTargets(context, metTargetsToApprove, appProvider),
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.check_circle),
            label: Text('Approve All (${metTargetsToApprove.length})'),
            heroTag: "approve_all",
          ),
          const SizedBox(height: 12),
          // Add Target button
          FloatingActionButton(
            onPressed: () => _showAddTargetDialog(context),
            backgroundColor: const Color(0xFF007AFF),
            heroTag: "add_target",
            child: const Icon(
              Icons.add,
              color: Colors.white,
            ),
          ),
        ],
      );
    } else {
      // Only show Add Target button
      return FloatingActionButton(
        onPressed: () => _showAddTargetDialog(context),
        backgroundColor: const Color(0xFF007AFF),
        child: const Icon(
          Icons.add,
          color: Colors.white,
        ),
      );
    }
  }

  void _approveAllMetTargets(BuildContext context, List<SalesTarget> targets, AppProvider appProvider) async {
    if (targets.isEmpty) return;

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve All Met Targets'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('This will approve ${targets.length} met targets for ${DateFormat('MMM dd, yyyy').format(_selectedDate)}:'),
            const SizedBox(height: 12),
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              child: SingleChildScrollView(
                child: Column(
                  children: targets.map((target) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${target.assignedEmployeeName ?? 'Unassigned'}: \$${target.actualAmount.toStringAsFixed(0)}/\$${target.targetAmount.toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  )).toList(),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Approve All', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      int approvedCount = 0;

      for (final target in targets) {
        // Find pending approval request for this target
        final pendingRequest = appProvider.approvalRequests.firstWhere(
          (request) => request.targetId == target.id && 
                       request.status == ApprovalStatus.pending,
          orElse: () => throw Exception('No pending approval request found for ${target.id}'),
        );

        // Use the existing approval system
        await appProvider.approveRequest(pendingRequest);
        approvedCount++;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully approved $approvedCount targets!'),
          backgroundColor: Colors.green,
        ),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error approving targets: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class AddTargetDialog extends StatefulWidget {
  final DateTime selectedDate;
  final VoidCallback onTargetAdded;

  const AddTargetDialog({
    super.key,
    required this.selectedDate,
    required this.onTargetAdded,
  });

  @override
  State<AddTargetDialog> createState() => _AddTargetDialogState();
}

class _AddTargetDialogState extends State<AddTargetDialog> {
  final _formKey = GlobalKey<FormState>();
  final _targetAmountController = TextEditingController();
  final _employeeController = TextEditingController();
  final _workplaceController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  User? _selectedEmployee;
  Workplace? _selectedWorkplace;
  List<User> _availableEmployees = [];
  List<Workplace> _availableWorkplaces = [];
  List<User> _selectedCollaborators = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.selectedDate;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final appProvider = Provider.of<AppProvider>(context, listen: false);
    _availableEmployees = await appProvider.getUsers();
    _availableWorkplaces = await appProvider.getWorkplaces();

    // Filter to show employees and admins (admins can participate as team members)
    _availableEmployees = _availableEmployees
        .where((user) => user.role == UserRole.employee || user.role == UserRole.admin)
        .toList();

    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _targetAmountController.dispose();
    _employeeController.dispose();
    _workplaceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Sales Target'),
      content: SizedBox(
        width: double.maxFinite,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Date Selection
                      const Text(
                        'Target Date',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                DateFormat('MMM dd, yyyy')
                                    .format(_selectedDate),
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: _selectDate,
                            icon: const Icon(Icons.calendar_today),
                            tooltip: 'Select Date',
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Target Amount
                      const Text(
                        'Target Amount (\$)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _targetAmountController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          hintText: 'Enter target amount',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter target amount';
                          }
                          final amount = double.tryParse(value);
                          if (amount == null || amount <= 0) {
                            return 'Please enter a valid amount';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Employee Selection
                      const Text(
                        'Assigned Employee',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<User>(
                        value: _selectedEmployee,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Select employee',
                        ),
                        items: _availableEmployees.map((employee) {
                          return DropdownMenuItem<User>(
                            value: employee,
                            child: Text(employee.name),
                          );
                        }).toList(),
                        onChanged: (User? value) {
                          setState(() {
                            _selectedEmployee = value;
                            if (value != null) {
                              _employeeController.text = value.name;
                              // Auto-select workplace if employee has one
                              if (value.workplaceIds.isNotEmpty) {
                                _selectedWorkplace =
                                    _availableWorkplaces.firstWhere(
                                  (wp) => wp.id == value.workplaceIds.first,
                                  orElse: () => _availableWorkplaces.first,
                                );
                                _workplaceController.text =
                                    _selectedWorkplace?.name ?? '';
                              }
                            }
                          });
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Please select an employee';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Workplace Selection
                      const Text(
                        'Workplace',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<Workplace>(
                        value: _selectedWorkplace,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Select workplace',
                        ),
                        items: _availableWorkplaces.map((workplace) {
                          return DropdownMenuItem<Workplace>(
                            value: workplace,
                            child: Text(workplace.name),
                          );
                        }).toList(),
                        onChanged: (Workplace? value) {
                          setState(() {
                            _selectedWorkplace = value;
                            if (value != null) {
                              _workplaceController.text = value.name;
                            }
                          });
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Please select a workplace';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Collaborators Selection
                      const Text(
                        'Team Members (Optional)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_selectedCollaborators.isEmpty)
                              Text(
                                'No team members selected',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              )
                            else
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children:
                                    _selectedCollaborators.map((collaborator) {
                                  return Chip(
                                    label: Text(collaborator.name),
                                    onDeleted: () {
                                      setState(() {
                                        _selectedCollaborators
                                            .remove(collaborator);
                                      });
                                    },
                                    deleteIcon:
                                        const Icon(Icons.close, size: 16),
                                  );
                                }).toList(),
                              ),
                            const SizedBox(height: 8),
                            TextButton.icon(
                              onPressed: _selectCollaborators,
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text('Add Team Members'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _addTarget,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF007AFF),
            foregroundColor: Colors.white,
          ),
          child: const Text('Add Target'),
        ),
      ],
    );
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  Future<void> _selectCollaborators() async {
    final availableCollaborators = _availableEmployees
        .where((emp) => emp.id != _selectedEmployee?.id)
        .toList();

    final selected = await showDialog<List<User>>(
      context: context,
      builder: (context) => MultiSelectDialog(
        title: 'Select Team Members',
        items: availableCollaborators,
        selectedItems: _selectedCollaborators,
      ),
    );

    if (selected != null) {
      setState(() {
        _selectedCollaborators = selected;
      });
    }
  }

  Future<void> _addTarget() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      final currentUser = appProvider.currentUser;

      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to add targets')),
        );
        return;
      }

      final target = SalesTarget(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        date: _selectedDate,
        targetAmount: double.parse(_targetAmountController.text),
        createdAt: DateTime.now(),
        createdBy: currentUser.id,
        assignedEmployeeId: _selectedEmployee!.id,
        assignedEmployeeName: _selectedEmployee!.name,
        assignedWorkplaceId: _selectedWorkplace!.id,
        assignedWorkplaceName: _selectedWorkplace!.name,
        collaborativeEmployeeIds:
            _selectedCollaborators.map((e) => e.id).toList(),
        collaborativeEmployeeNames:
            _selectedCollaborators.map((e) => e.name).toList(),
      );

      await appProvider.addSalesTarget(target);

      if (mounted) {
        Navigator.pop(context);
        widget.onTargetAdded();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Target added for ${_selectedEmployee!.name}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding target: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

class MultiSelectDialog extends StatefulWidget {
  final String title;
  final List<User> items;
  final List<User> selectedItems;

  const MultiSelectDialog({
    super.key,
    required this.title,
    required this.items,
    required this.selectedItems,
  });

  @override
  State<MultiSelectDialog> createState() => _MultiSelectDialogState();
}

class _MultiSelectDialogState extends State<MultiSelectDialog> {
  late List<User> _selectedItems;

  @override
  void initState() {
    super.initState();
    _selectedItems = List.from(widget.selectedItems);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: widget.items.length,
          itemBuilder: (context, index) {
            final item = widget.items[index];
            final isSelected =
                _selectedItems.any((selected) => selected.id == item.id);

            return CheckboxListTile(
              title: Text(item.name),
              subtitle: Text(item.email),
              value: isSelected,
              onChanged: (bool? value) {
                setState(() {
                  if (value == true) {
                    _selectedItems.add(item);
                  } else {
                    _selectedItems
                        .removeWhere((selected) => selected.id == item.id);
                  }
                });
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _selectedItems),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF007AFF),
            foregroundColor: Colors.white,
          ),
          child: const Text('Done'),
        ),
      ],
    );
  }

}
