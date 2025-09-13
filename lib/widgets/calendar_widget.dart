import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CalendarPage extends StatefulWidget {
  final DateTime? selectedDate;
  final Function(DateTime)? onDateSelected;
  final List<DateTime>? highlightedDates;
  final String? title;

  const CalendarPage({
    super.key,
    this.selectedDate,
    this.onDateSelected,
    this.highlightedDates,
    this.title,
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
        backgroundColor: Colors.transparent,
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
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Calendar
            Expanded(
              flex: 2,
              child: _buildCalendar(context),
            ),
            
            // Dates List
            Expanded(
              flex: 1,
              child: _buildDatesList(context),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildCalendar(BuildContext context) {
    return Column(
      children: [
        // Month Navigation
        _buildMonthNavigation(context),
        const SizedBox(height: 16),
        
        // Days of Week Header
        _buildDaysOfWeekHeader(context),
        const SizedBox(height: 8),
        
        // Calendar Grid
        Expanded(
          child: _buildCalendarGrid(context),
        ),
      ],
    );
  }

  Widget _buildMonthNavigation(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: _previousMonth,
          icon: const Icon(Icons.chevron_left),
          style: IconButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            shape: const CircleBorder(),
          ),
        ),
        Text(
          DateFormat('MMMM yyyy').format(_currentMonth),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        IconButton(
          onPressed: _nextMonth,
          icon: const Icon(Icons.chevron_right),
          style: IconButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            shape: const CircleBorder(),
          ),
        ),
      ],
    );
  }

  Widget _buildDaysOfWeekHeader(BuildContext context) {
    const daysOfWeek = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    
    return Row(
      children: daysOfWeek.map((day) => 
        Expanded(
          child: Center(
            child: Text(
              day,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
          ),
        ),
      ).toList(),
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
        
        return _buildDayCell(context, date, day, isSelected, isToday, isHighlighted);
      },
    );
  }

  Widget _buildDayCell(BuildContext context, DateTime date, int day, bool isSelected, bool isToday, bool isHighlighted) {
    return GestureDetector(
      onTap: () => _selectDate(date),
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: isSelected 
              ? Theme.of(context).colorScheme.primary
              : isHighlighted
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isToday && !isSelected
              ? Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                )
              : null,
        ),
        child: Center(
          child: Text(
            day.toString(),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isSelected 
                  ? Colors.white
                  : isToday
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurface,
              fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.normal,
            ),
          ),
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

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  Widget _buildDatesList(BuildContext context) {
    final lastDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;
    
    // Generate list of all dates in the month
    final dates = List.generate(daysInMonth, (index) => 
      DateTime(_currentMonth.year, _currentMonth.month, index + 1)
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: Text(
            'All Dates in ${DateFormat('MMMM yyyy').format(_currentMonth)}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        
        // Scrollable dates list
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey[200]!,
                width: 1,
              ),
            ),
            child: ListView.builder(
              padding: const EdgeInsets.all(2),
              itemCount: dates.length,
              itemBuilder: (context, index) {
                final date = dates[index];
                final isSelected = _isSameDay(date, _selectedDate);
                final isToday = _isSameDay(date, DateTime.now());
                final isHighlighted = widget.highlightedDates?.any((d) => _isSameDay(d, date)) ?? false;
                
                return _buildDateListItem(context, date, isSelected, isToday, isHighlighted);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateListItem(BuildContext context, DateTime date, bool isSelected, bool isToday, bool isHighlighted) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 1),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _selectDate(date),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected 
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                  : isHighlighted
                      ? Theme.of(context).colorScheme.primary.withOpacity(0.05)
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: isToday && !isSelected
                  ? Border.all(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                      width: 1,
                    )
                  : null,
            ),
            child: Row(
              children: [
                // Date number
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? Theme.of(context).colorScheme.primary
                        : isToday
                            ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                            : Colors.grey[200],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      date.day.toString(),
                      style: TextStyle(
                        color: isSelected 
                            ? Colors.white
                            : isToday
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.onSurface,
                        fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.normal,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Date details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('EEEE').format(date), // Day of week
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isSelected 
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        DateFormat('MMM dd, yyyy').format(date),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Selection indicator
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  )
                else if (isToday)
                  Icon(
                    Icons.today,
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}