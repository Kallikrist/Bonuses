import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/sales_target.dart';

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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCalendarOptions(context),
        backgroundColor: const Color(0xFF007AFF),
        child: const Icon(
          Icons.add,
          color: Colors.white,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
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
              children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'].map((day) => 
                Expanded(
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
              ).toList(),
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
    final firstDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
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
        final isHighlighted = widget.highlightedDates?.any((d) => _isSameDay(d, date)) ?? false;
        final hasSalesTarget = _hasSalesTargetForDate(date);

        return _buildDayCell(context, date, day, isSelected, isToday, isHighlighted, hasSalesTarget);
      },
    );
  }

  Widget _buildDayCell(BuildContext context, DateTime date, int day, bool isSelected, bool isToday, bool isHighlighted, bool hasSalesTarget) {
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
                  fontWeight: isSelected || isToday ? FontWeight.w600 : FontWeight.w500,
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
                      color: hasSalesTarget 
                          ? Colors.orange  // Orange dot for sales targets
                          : const Color(0xFF007AFF), // Blue dot for highlighted dates
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
    final salesTargets = _getSalesTargetsForDate(_selectedDate, widget.salesTargets ?? []);
    
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
                                  if (target.collaborativeEmployeeNames.isNotEmpty)
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
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getTargetColorFromStatus(target.status).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _getStatusText(target.status),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: _getTargetColorFromStatus(target.status),
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

  List<SalesTarget> _getSalesTargetsForDate(DateTime date, List<SalesTarget> allTargets) {
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
            
            _buildOptionTile(
              context,
              icon: Icons.add_circle_outline,
              title: 'Add Sales Target',
              subtitle: 'Create new target for selected date',
              onTap: () {
                Navigator.pop(context);
                _showAddTargetDialog(context);
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
      builder: (context) => AlertDialog(
        title: const Text('Add Sales Target'),
        content: const Text(
          'This feature will be implemented to add new sales targets for the selected date.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}