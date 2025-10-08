import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../models/sales_target.dart';
import '../models/bonus.dart';
import '../models/user.dart';
import '../models/company.dart';
import '../models/country.dart';
import '../models/points_transaction.dart';
import '../widgets/profile_header_widget.dart';
import '../widgets/target_card_widget.dart';
import 'admin_dashboard.dart'; // Import for EmployeeProfileScreen and EmployeesListScreen
import 'messaging_screen.dart';

class EmployeeDashboard extends StatefulWidget {
  const EmployeeDashboard({super.key});

  @override
  State<EmployeeDashboard> createState() => _EmployeeDashboardState();
}

class _EmployeeDashboardState extends State<EmployeeDashboard> {
  int _selectedIndex = 0;
  DateTime _selectedDate = DateTime.now();
  bool _showAvailableBonuses = true; // toggle between available and redeemed

  Widget _buildTargetsTab(AppProvider appProvider, List<SalesTarget> targets) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: targets.length,
      itemBuilder: (context, index) {
        final target = targets[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text('Target: \$${target.targetAmount}'),
            subtitle:
                Text('Date: ${DateFormat('MMM dd, yyyy').format(target.date)}'),
            trailing: Text(
              target.isApproved ? 'Completed' : 'Pending',
              style: TextStyle(
                color: target.isApproved ? Colors.green : Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmployeesTab(AppProvider appProvider) {
    return FutureBuilder<List<User>>(
      future: appProvider.getUsers(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final employees = snapshot.data!
            .where((user) => user.role == UserRole.employee)
            .toList();

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: employees.length,
          itemBuilder: (context, index) {
            final employee = employees[index];
            // Get company-specific points
            final points = employee.primaryCompanyId != null
                ? appProvider.getUserCompanyPoints(
                    employee.id, employee.primaryCompanyId!)
                : 0;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue,
                  child: Text(employee.name[0].toUpperCase()),
                ),
                title: Text(employee.name),
                subtitle: Text(employee.email),
                trailing: Text(
                  '$points points',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildWorkplacesTab(AppProvider appProvider) {
    final workplaces = appProvider.workplaces;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: workplaces.length,
      itemBuilder: (context, index) {
        final workplace = workplaces[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: const Icon(Icons.business, color: Colors.blue),
            title: Text(workplace.name),
            subtitle: Text(workplace.address),
          ),
        );
      },
    );
  }

  Widget _buildReportsTab(List<SalesTarget> targets,
      List<PointsTransaction> transactions, AppProvider appProvider) {
    final user = appProvider.currentUser!;
    final userPoints = user.primaryCompanyId != null
        ? appProvider.getUserCompanyPoints(user.id, user.primaryCompanyId!)
        : 0;

    // Calculate employee-specific metrics
    final employeeTargets = targets
        .where((t) =>
            t.assignedEmployeeId == user.id ||
            t.collaborativeEmployeeIds.contains(user.id))
        .toList();
    final completedTargets =
        employeeTargets.where((t) => t.isApproved).toList();
    final teamParticipationPoints = transactions
        .where((t) => t.description.contains('Added as team member'))
        .fold<int>(0, (sum, t) => sum + t.points);
    final totalEarnedPoints = transactions
        .where((t) => t.type.name == 'earned')
        .fold<int>(0, (sum, t) => sum + t.points);
    final totalSpentPoints = transactions
        .where((t) => t.type.name == 'spent')
        .fold<int>(0, (sum, t) => sum + t.points);
    final totalRevenue = employeeTargets.fold<double>(
        0, (sum, target) => sum + target.actualAmount);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Settings & Analytics',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Personal Settings Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.person, color: Colors.blue[600]),
                      const SizedBox(width: 8),
                      Text(
                        'Personal Settings',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSettingsItem(
                    Icons.person_outline,
                    'Edit Profile',
                    'Update your personal information',
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EmployeeProfileScreen(
                          employee: user,
                          appProvider: appProvider,
                          showBackButton: true,
                        ),
                      ),
                    ),
                  ),
                  _buildSettingsItem(
                    Icons.people_outline,
                    'View Employees',
                    'See all employees in my company',
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EmployeesListScreen(
                          appProvider: appProvider,
                          filterCompanyId: user.primaryCompanyId,
                          readOnly:
                              true, // Employees can only view, not add/import/delete
                          customTitle: 'Company Employees',
                        ),
                      ),
                    ),
                  ),
                  _buildSettingsItem(
                    Icons.logout,
                    'Logout',
                    'Sign out of your account',
                    () => _showLogoutDialog(context, appProvider),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Analytics Section
          Text(
            'Analytics',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),

          // Summary Cards
          Row(
            children: [
              Expanded(
                child: _buildAnalyticsCard(
                  'My Targets',
                  employeeTargets.length.toString(),
                  Icons.track_changes,
                  Colors.blue,
                  subtitle: '${completedTargets.length} completed',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildAnalyticsCard(
                  'My Points',
                  userPoints.toString(),
                  Icons.stars,
                  Colors.orange,
                  subtitle: 'Current balance',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildAnalyticsCard(
                  'Total Revenue',
                  '\$${totalRevenue.toStringAsFixed(0)}',
                  Icons.attach_money,
                  Colors.green,
                  subtitle: 'From my targets',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildAnalyticsCard(
                  'Transactions',
                  transactions.length.toString(),
                  Icons.swap_horiz,
                  Colors.purple,
                  subtitle: 'Points activity',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Team Participation Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.group_add, color: Colors.green[600]),
                      const SizedBox(width: 8),
                      Text(
                        'Team Participation',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildAnalyticsCard(
                          'Team Points',
                          teamParticipationPoints.toString(),
                          Icons.stars,
                          Colors.green,
                          subtitle: 'From team participation',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildAnalyticsCard(
                          'Team Count',
                          transactions
                              .where((t) => t.description
                                  .contains('Added as team member'))
                              .length
                              .toString(),
                          Icons.group,
                          Colors.blue,
                          subtitle: 'Times added to teams',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Points Breakdown Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.analytics, color: Colors.purple[600]),
                      const SizedBox(width: 8),
                      Text(
                        'Points Breakdown',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildAnalyticsCard(
                          'Earned',
                          totalEarnedPoints.toString(),
                          Icons.trending_up,
                          Colors.green,
                          subtitle: 'Total points earned',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildAnalyticsCard(
                          'Spent',
                          totalSpentPoints.toString(),
                          Icons.trending_down,
                          Colors.red,
                          subtitle: 'Total points spent',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Weekly Performance Chart
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.bar_chart, color: Colors.blue[600]),
                      const SizedBox(width: 8),
                      Text(
                        'My Weekly Performance',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildWeeklyPerformanceChart(
                      _getThisWeekTargets(employeeTargets)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsItem(
      IconData icon, String title, String subtitle, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(icon, color: Colors.blue[600], size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnalyticsCard(
      String title, String value, IconData icon, Color color,
      {String? subtitle}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: color.withOpacity(0.7),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWeeklyPerformanceChart(List<SalesTarget> thisWeekTargets) {
    if (thisWeekTargets.isEmpty) {
      return Container(
        height: 200,
        child: Center(
          child: Text(
            'No targets this week',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
      );
    }

    // Group targets by day
    final Map<int, List<SalesTarget>> targetsByDay = {};
    for (final target in thisWeekTargets) {
      final day = target.date.day;
      targetsByDay.putIfAbsent(day, () => []).add(target);
    }

    // Get the days of the week
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final days =
        List.generate(7, (index) => startOfWeek.add(Duration(days: index)));

    return Container(
      height: 200,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: days.map((day) {
          final dayTargets = targetsByDay[day.day] ?? [];
          final maxHeight = 150.0;
          final height = dayTargets.isEmpty
              ? 20.0
              : (dayTargets.length / 5.0 * maxHeight).clamp(20.0, maxHeight);

          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                width: 30,
                height: height,
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Center(
                  child: Text(
                    dayTargets.length.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                DateFormat('E').format(day),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  List<SalesTarget> _getThisWeekTargets(List<SalesTarget> targets) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));

    return targets.where((target) {
      final targetDate = target.date;
      return targetDate
              .isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
          targetDate.isBefore(endOfWeek.add(const Duration(days: 1)));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        final user = appProvider.currentUser!;
        // Get company-specific points
        final userPoints = user.primaryCompanyId != null
            ? appProvider.getUserCompanyPoints(user.id, user.primaryCompanyId!)
            : 0;
        // Check if selected date is today
        final isToday = _selectedDate.year == DateTime.now().year &&
            _selectedDate.month == DateTime.now().month &&
            _selectedDate.day == DateTime.now().day;

        // Use getTodaysTargetsForEmployee for today (includes all company targets)
        // For other dates, filter manually by date and company
        final selectedDateTargets = isToday
            ? appProvider.getTodaysTargetsForEmployee(user.id)
            : appProvider.salesTargets.where((target) {
                final isSelectedDate = target.date.year == _selectedDate.year &&
                    target.date.month == _selectedDate.month &&
                    target.date.day == _selectedDate.day;

                if (!isSelectedDate) return false;

                // Only show targets from the same company
                final currentCompanyId = user.primaryCompanyId;
                if (target.companyId != currentCompanyId) return false;

                // Show all company targets (so employees can join them)
                return true;
              }).toList();
        final allTargets = appProvider.salesTargets;
        final allTransactions = appProvider.pointsTransactions;
        // Available bonuses are company-specific, redeemed bonuses are global
        final availableBonuses = appProvider.getAvailableBonuses();
        final redeemedBonuses = appProvider.getUserRedeemedBonuses(
            user.id, null); // null = show all companies

        return Scaffold(
          appBar: AppBar(
            title: const Text('Employee Dashboard'),
            backgroundColor: Colors.transparent,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () => _showLogoutDialog(context, appProvider),
              ),
            ],
          ),
          body: Column(
            children: [
              // Profile Header with Action Buttons
              FutureBuilder<List<Company>>(
                future: appProvider.getCompanies(),
                builder: (context, snapshot) {
                  final allCompanies = snapshot.data ?? [];
                  final userCompanies = allCompanies
                      .where((c) => user.companyIds.contains(c.id))
                      .toList();

                  return ProfileHeaderWidget(
                    userName: user.name,
                    userEmail: user.email,
                    onProfileTap: () => setState(
                        () => _selectedIndex = 4), // Navigate to Profile tab
                    actionButtons:
                        _getEmployeeActionButtons(context, appProvider),
                    salesTargets: allTargets,
                    userCompanies: userCompanies,
                    currentCompanyId: user.primaryCompanyId,
                    onDateSelected: (selectedDate) {
                      setState(() {
                        _selectedDate = selectedDate;
                      });
                    },
                    onCompanyChanged: (newCompanyId) async {
                      final updatedUser = user.copyWith(
                        primaryCompanyId: newCompanyId,
                      );
                      await appProvider.updateUser(updatedUser);
                      setState(() {}); // Refresh UI
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'Switched to ${userCompanies.firstWhere((c) => c.id == newCompanyId).name}'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                  );
                },
              ),
              // Main Content
              Expanded(
                child: IndexedStack(
                  index: _selectedIndex,
                  children: [
                    _buildOverviewTab(
                        userPoints, selectedDateTargets, user.id, appProvider),
                    _buildTargetsTab(appProvider, allTargets),
                    _buildBonusesTab(availableBonuses, redeemedBonuses, user.id,
                        userPoints, appProvider),
                    _buildReportsTab(allTargets, allTransactions, appProvider),
                  ],
                ),
              ),
            ],
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _selectedIndex == 0
                ? 0
                : _selectedIndex == 1
                    ? 0 // Targets (index 1) - show Overview as selected
                    : _selectedIndex == 2
                        ? 1 // Bonuses (index 2) -> bottom nav index 1
                        : 2, // Reports (index 3) -> bottom nav index 2
            onTap: (index) {
              setState(() {
                // Map bottom nav index to actual tab index
                _selectedIndex = index == 0
                    ? 0 // Overview
                    : index == 1
                        ? 2 // Bonuses (skip Targets at index 1)
                        : 3; // Reports
              });
            },
            backgroundColor: Colors.white,
            selectedItemColor: Colors.grey[800],
            unselectedItemColor: Colors.grey[800],
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.normal,
              color: Colors.black,
            ),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.dashboard),
                label: 'Overview',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.card_giftcard),
                label: 'Bonuses',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.analytics),
                label: 'Settings',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOverviewTab(
      int userPoints,
      List<SalesTarget> selectedDateTargets,
      String userId,
      AppProvider appProvider) {
    final isToday = _selectedDate.year == DateTime.now().year &&
        _selectedDate.month == DateTime.now().month &&
        _selectedDate.day == DateTime.now().day;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date Navigation Card
          Card(
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.calendar_today, color: Colors.blue.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isToday
                                  ? 'Today\'s Targets'
                                  : 'Targets for Selected Date',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
                              ),
                            ),
                            Text(
                              DateFormat('EEEE, MMM dd, yyyy')
                                  .format(_selectedDate),
                              style: TextStyle(
                                color: Colors.blue.shade600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _selectedDate =
                                _selectedDate.subtract(const Duration(days: 1));
                          });
                        },
                        icon: const Icon(Icons.chevron_left, size: 16),
                        label: const Text('Previous'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade100,
                          foregroundColor: Colors.blue.shade700,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _selectedDate = DateTime.now();
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isToday
                              ? Colors.blue.shade700
                              : Colors.blue.shade100,
                          foregroundColor:
                              isToday ? Colors.white : Colors.blue.shade700,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                        ),
                        child: const Text('Today'),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _selectedDate =
                                _selectedDate.add(const Duration(days: 1));
                          });
                        },
                        icon: const Icon(Icons.chevron_right, size: 16),
                        label: const Text('Next'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade100,
                          foregroundColor: Colors.blue.shade700,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isToday
                ? 'Today\'s Sales Targets'
                : 'Sales Targets - ${DateFormat('MMM dd').format(_selectedDate)}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          if (selectedDateTargets.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  isToday
                      ? 'No sales targets set for today'
                      : 'No sales targets for selected date',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ),
            )
          else
            ...selectedDateTargets.map((target) => TargetCard(
                  target: target,
                  appProvider: appProvider,
                  currentUserId: userId,
                  isAdminView: false,
                  onAddCollaborators: () =>
                      _showAddCollaboratorsDialog(context, target, userId),
                  onSubmitSales: () => _showSubmitSalesDialog(context, target),
                  onJoinAsTeamMember: () => _joinTargetAsTeamMember(
                      context, target, userId, appProvider),
                )),
        ],
      ),
    );
  }

  Widget _buildProgressBar(SalesTarget target, double progress, bool isMet) {
    final percentageAbove = target.percentageAboveTarget;
    final isApproved = target.isApproved;
    final hasBonus = percentageAbove >= 10.0;

    // If target is approved and met, show green bar with purple bonus section
    if (isApproved && isMet) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final barWidth = constraints.maxWidth;
          final bonusWidth = barWidth * 0.1; // 10% of the progress bar width

          return Stack(
            children: [
              // Base green progress bar
              LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                backgroundColor: Colors.grey[300],
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
              ),
              // Purple bonus section (10% of the bar) if target exceeded by 10%+
              if (hasBonus)
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: bonusWidth,
                    decoration: BoxDecoration(
                      color: Colors.purple,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
            ],
          );
        },
      );
    }

    // Default progress bar for non-approved targets
    return LinearProgressIndicator(
      value: progress.clamp(0.0, 1.0),
      backgroundColor: Colors.grey[300],
      valueColor: AlwaysStoppedAnimation<Color>(
        isMet ? Colors.green : Colors.orange,
      ),
    );
  }

  Widget _buildTargetCard(SalesTarget target, String userId) {
    final progress = target.targetAmount > 0
        ? target.actualAmount / target.targetAmount
        : 0.0;
    final isMet = target.isMet;
    final percentageAbove = target.percentageAboveTarget;

    // Check if target is approved
    final isApproved =
        target.isApproved || target.status == TargetStatus.approved;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isApproved ? Colors.green[50] : null,
      shape: isApproved
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.green[400]!, width: 2),
            )
          : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      target.assignedEmployeeId == userId
                          ? 'Your Personal Target'
                          : target.assignedWorkplaceId != null
                              ? 'Your Workplace Target'
                              : 'Company Target',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (target.assignedEmployeeId == userId)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Assigned to You',
                          style: TextStyle(
                            color: Colors.blue[700],
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    else if (target.assignedWorkplaceId != null)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Workplace: ${target.assignedWorkplaceName ?? 'Unknown'}',
                          style: TextStyle(
                            color: Colors.green[700],
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      DateFormat('MMM dd, yyyy').format(target.date),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (target.assignedWorkplaceName != null)
                      Text(
                        target.assignedWorkplaceName!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.green[700],
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '\$${target.actualAmount.toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: isMet ? Colors.green : Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  'of \$${target.targetAmount.toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildProgressBar(target, progress, isMet),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${(progress * 100).toStringAsFixed(1)}%',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (isMet && percentageAbove >= 10)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '+${target.pointsAwarded} points',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            if (target.collaborativeEmployeeNames.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Team Members:',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: target.collaborativeEmployeeNames
                          .map(
                            (name) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blue[100],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                name,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.blue[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                if (!target.isSubmitted) ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          _showAddCollaboratorsDialog(context, target, userId),
                      icon: const Icon(Icons.group_add, size: 16),
                      label: const Text('Add Team'),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: !target.isSubmitted
                      ? ElevatedButton.icon(
                          onPressed: () =>
                              _showSubmitSalesDialog(context, target),
                          icon: const Icon(Icons.upload, size: 16),
                          label: const Text('Submit Sales'),
                        )
                      : target.isApproved ||
                              target.status == TargetStatus.approved
                          ? Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.green[100],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.green),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_circle,
                                      color: Colors.green[700], size: 16),
                                  const SizedBox(width: 8),
                                  Text(
                                    target.pointsAwarded > 0
                                        ? 'Approved & +${target.pointsAwarded} Points Earned'
                                        : 'Approved - No Points Awarded',
                                    style: TextStyle(
                                      color: Colors.green[700],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : target.status == TargetStatus.submitted
                              ? Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.blue[100],
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.blue),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.upload,
                                          color: Colors.blue[700], size: 16),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Submitted for Approval',
                                        style: TextStyle(
                                          color: Colors.blue[700],
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.orange[100],
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.orange),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.pending_actions,
                                          color: Colors.orange[700], size: 16),
                                      const SizedBox(width: 8),
                                      Text(
                                        target.isSubmitted
                                            ? 'Pending Admin Approval'
                                            : 'Awaiting Submission',
                                        style: TextStyle(
                                          color: Colors.orange[700],
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPointsTab(AppProvider appProvider, String userId) {
    final userTransactions = appProvider.getUserPointsTransactions(userId);

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: userTransactions.length,
      itemBuilder: (context, index) {
        final transaction = userTransactions[index];
        // Consider adjustment transactions with positive points as "earned" for display
        final isEarned = transaction.type.name == 'earned' ||
            (transaction.type.name == 'adjustment' && transaction.points > 0);

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isEarned ? Colors.green : Colors.orange,
              child: Icon(
                isEarned ? Icons.add : Icons.remove,
                color: Colors.white,
              ),
            ),
            title: Text(transaction.description),
            subtitle: Text(
                DateFormat('MMM dd, yyyy - HH:mm').format(transaction.date)),
            trailing: Text(
              '${isEarned ? '+' : '-'}${transaction.points}',
              style: TextStyle(
                color: isEarned ? Colors.green : Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBonusesTab(
      List<Bonus> availableBonuses,
      List<Bonus> redeemedBonuses,
      String userId,
      int userPoints,
      AppProvider appProvider) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Points Summary Card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purple.shade400, Colors.purple.shade600],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.stars,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Your Points',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '$userPoints',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                // Claimable / total circle with overflow support (>100%)
                Builder(builder: (context) {
                  final totalAvailable = availableBonuses.length;
                  final claimableCount = availableBonuses
                      .where((b) => userPoints >= b.pointsRequired)
                      .length;
                  // Progress based on cheapest bonus threshold
                  final cheapestRequired = availableBonuses.isEmpty
                      ? 0
                      : availableBonuses
                          .map((b) => b.pointsRequired)
                          .reduce((a, b) => a < b ? a : b);
                  final rawProgress = cheapestRequired == 0
                      ? 0.0
                      : userPoints / cheapestRequired;
                  final baseProgress = rawProgress.clamp(0.0, 1.0);
                  final overflowProgress = (rawProgress - 1.0) > 0
                      ? (rawProgress - 1.0).clamp(0.0, 1.0)
                      : 0.0;
                  return Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 48,
                          height: 48,
                          child: CircularProgressIndicator(
                            value: baseProgress,
                            strokeWidth: 5,
                            color: Colors.white,
                            backgroundColor: Colors.white.withOpacity(0.25),
                          ),
                        ),
                        if (overflowProgress > 0)
                          SizedBox(
                            width: 40,
                            height: 40,
                            child: CircularProgressIndicator(
                              value: overflowProgress,
                              strokeWidth: 4,
                              color: Colors.white70,
                              backgroundColor: Colors.white.withOpacity(0.15),
                            ),
                          ),
                        Text(
                          '$claimableCount/$totalAvailable',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),

          // Toggle header
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _showAvailableBonuses
                        ? 'Available Bonuses'
                        : 'Your Claimed Bonuses',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ChoiceChip(
                        label: const Text('Available'),
                        selected: _showAvailableBonuses,
                        onSelected: (v) =>
                            setState(() => _showAvailableBonuses = true),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Redeemed'),
                        selected: !_showAvailableBonuses,
                        onSelected: (v) =>
                            setState(() => _showAvailableBonuses = false),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Available Bonuses Section (toggle)
          if (_showAvailableBonuses)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  ...availableBonuses.map((bonus) =>
                      _buildSimpleBonusCard(bonus, userPoints, userId, false)),
                ],
              ),
            ),

          if (_showAvailableBonuses) const SizedBox(height: 24),

          // Claimed Bonuses Section (toggle)
          if (!_showAvailableBonuses)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  redeemedBonuses.isEmpty
                      ? Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Column(
                              children: [
                                Icon(Icons.card_giftcard,
                                    size: 48, color: Colors.grey),
                                SizedBox(height: 12),
                                Text(
                                  'No bonuses claimed yet',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Start earning points to claim bonuses!',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        )
                      : Column(
                          children: redeemedBonuses
                              .map((bonus) => _buildSimpleBonusCard(
                                  bonus, userPoints, userId, true, appProvider))
                              .toList(),
                        ),
                ],
              ),
            ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSimpleBonusCard(
      Bonus bonus, int userPoints, String userId, bool isRedeemed,
      [AppProvider? appProvider]) {
    final canRedeem = !isRedeemed && userPoints >= bonus.pointsRequired;
    final pointsNeeded = bonus.pointsRequired - userPoints;
    final progress = (userPoints / bonus.pointsRequired).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isRedeemed
              ? Colors.green.withOpacity(0.3)
              : canRedeem
                  ? Colors.purple.withOpacity(0.3)
                  : Colors.grey.withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Circular progress indicator
          SizedBox(
            width: 48,
            height: 48,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 48,
                  height: 48,
                  child: CircularProgressIndicator(
                    value: isRedeemed ? 1.0 : progress,
                    strokeWidth: 6,
                    color: isRedeemed
                        ? Colors.green
                        : canRedeem
                            ? Colors.purple
                            : Colors.grey,
                    backgroundColor: Colors.grey.withOpacity(0.15),
                  ),
                ),
                Text(
                  isRedeemed ? '100%' : '${(progress * 100).floor()}%',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isRedeemed
                        ? Colors.green
                        : canRedeem
                            ? Colors.purple
                            : Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bonus.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  bonus.description,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.stars, size: 16, color: Colors.orange),
                    const SizedBox(width: 4),
                    Text(
                      '${bonus.pointsRequired} points',
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                    if (!isRedeemed) ...[
                      const SizedBox(width: 8),
                      Text(
                        '${userPoints.clamp(0, bonus.pointsRequired)} / ${bonus.pointsRequired}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    if (isRedeemed) ...[
                      const SizedBox(width: 12),
                      const Icon(Icons.check, size: 16, color: Colors.green),
                      const SizedBox(width: 4),
                      const Text(
                        'Claimed',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ],
                ),
                // Show secret code if available for redeemed bonuses
                if (isRedeemed && appProvider != null) ...[
                  Builder(builder: (context) {
                    // Find the transaction that includes the secret code for this bonus
                    final transactions =
                        appProvider.getUserPointsTransactions(userId);
                    final relevantTransaction = transactions
                        .where((t) =>
                            t.type == PointsTransactionType.redeemed &&
                            t.description.contains('Redeemed ${bonus.name}'))
                        .firstOrNull;

                    final secretCodeRegex =
                        RegExp(r'Secret Code: (.+?)(?:\s*$)');
                    final secretCodeMatch = relevantTransaction != null
                        ? secretCodeRegex
                            .firstMatch(relevantTransaction.description)
                        : null;
                    final hasSecretCode = secretCodeMatch != null;
                    final secretCode = secretCodeMatch?.group(1);

                    if (hasSecretCode) {
                      return Column(
                        children: [
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              border: Border.all(color: Colors.orange.shade200),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.security,
                                    size: 16, color: Colors.orange.shade700),
                                const SizedBox(width: 4),
                                Text(
                                  'Secret Code: $secretCode',
                                  style: TextStyle(
                                    color: Colors.orange.shade700,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }
                    return const SizedBox.shrink();
                  }),
                ],
              ],
            ),
          ),

          // Action Button or Status
          if (isRedeemed)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                'Claimed',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            )
          else if (canRedeem)
            ElevatedButton(
              onPressed: () => _redeemBonus(context, bonus, userId),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: const Text(
                'Claim',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Need $pointsNeeded',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'more points',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildAvailableBonuses(
      List<Bonus> bonuses, int userPoints, String userId) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: bonuses.length,
      itemBuilder: (context, index) {
        final bonus = bonuses[index];
        final canRedeem = userPoints >= bonus.pointsRequired;

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: canRedeem ? Colors.blue : Colors.grey,
              child: const Icon(
                Icons.card_giftcard,
                color: Colors.white,
              ),
            ),
            title: Text(bonus.name),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(bonus.description),
                const SizedBox(height: 4),
                Text(
                  '${bonus.pointsRequired} points required',
                  style: TextStyle(
                    color: canRedeem ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            trailing: canRedeem
                ? ElevatedButton(
                    onPressed: () => _redeemBonus(context, bonus, userId),
                    child: const Text('Redeem'),
                  )
                : Text(
                    'Need ${bonus.pointsRequired - userPoints} more',
                    style: const TextStyle(color: Colors.grey),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildRedeemedBonuses(List<Bonus> bonuses) {
    if (bonuses.isEmpty) {
      return const Center(
        child: Text('No redeemed bonuses yet'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: bonuses.length,
      itemBuilder: (context, index) {
        final bonus = bonuses[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.green,
              child: Icon(Icons.check, color: Colors.white),
            ),
            title: Text(bonus.name),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Redeemed on ${DateFormat('MMM dd, yyyy').format(bonus.redeemedAt!)}',
                ),
                if (bonus.giftCardCode != null) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      border: Border.all(color: Colors.blue.shade200),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.card_giftcard,
                            size: 16, color: Colors.blue.shade700),
                        const SizedBox(width: 4),
                        Text(
                          'Code: ${bonus.giftCardCode}',
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (bonus.secretCode != null) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      border: Border.all(color: Colors.orange.shade200),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.security,
                            size: 16, color: Colors.orange.shade700),
                        const SizedBox(width: 4),
                        Text(
                          'Secret Code: ${bonus.secretCode}',
                          style: TextStyle(
                            color: Colors.orange.shade700,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            trailing: Text(
              '-${bonus.pointsRequired} points',
              style: const TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }

  void _redeemBonus(BuildContext context, Bonus bonus, String userId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Redeem ${bonus.name}?'),
        content: Text('This will cost you ${bonus.pointsRequired} points.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              final appProvider = context.read<AppProvider>();
              final success = await appProvider.redeemBonus(bonus.id, userId);

              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${bonus.name} redeemed successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'Failed to redeem ${bonus.name}. Check your points.'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Redeem'),
          ),
        ],
      ),
    );
  }

  void _showSubmitSalesDialog(BuildContext context, SalesTarget target) {
    final salesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Submit Sales'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Target: \$${target.targetAmount.toStringAsFixed(0)}'),
            const SizedBox(height: 16),
            TextField(
              controller: salesController,
              decoration: const InputDecoration(
                labelText: 'Your Actual Sales (\$)',
                border: OutlineInputBorder(),
                hintText: 'Enter your sales amount',
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
            onPressed: () {
              final actualAmount = double.tryParse(salesController.text);
              if (actualAmount != null && actualAmount >= 0) {
                final user = context.read<AppProvider>().currentUser!;
                context.read<AppProvider>().submitEmployeeSales(
                      target.id,
                      actualAmount,
                      user.id,
                    );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(actualAmount >= target.targetAmount
                        ? 'Great job! You met your target! Sales submitted for admin approval.'
                        : 'Sales submitted. Target not met - no points awarded.'),
                    backgroundColor: actualAmount >= target.targetAmount
                        ? Colors.green
                        : Colors.red,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid sales amount'),
                    backgroundColor: Colors.red,
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

  void _showAddCollaboratorsDialog(
      BuildContext context, SalesTarget target, String userId) {
    showDialog(
      context: context,
      builder: (context) =>
          _AddCollaboratorsDialog(target: target, userId: userId),
    );
  }

  void _joinTargetAsTeamMember(BuildContext context, SalesTarget target,
      String userId, AppProvider appProvider) async {
    // Get current user
    final users = await appProvider.getUsers();
    final currentUser = users.firstWhere((u) => u.id == userId);

    // Confirm joining
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Join Target as Team Member'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Do you want to join this sales target as a team member?',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Target: \$${target.targetAmount.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Assigned to: ${target.assignedEmployeeName ?? 'Unassigned'}',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                  if (target.assignedWorkplaceName != null)
                    Text(
                      'Workplace: ${target.assignedWorkplaceName}',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  if (target.collaborativeEmployeeNames.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Current team: ${target.collaborativeEmployeeNames.join(', ')}',
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.person_add, size: 18),
            label: const Text('Join Team'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Add current user as a collaborator (prevent duplicates)
      final updatedCollaboratorIds = [
        ...target.collaborativeEmployeeIds,
        if (!target.collaborativeEmployeeIds.contains(userId)) userId,
      ];
      final updatedCollaboratorNames = [
        ...target.collaborativeEmployeeNames,
        if (!target.collaborativeEmployeeIds.contains(userId)) currentUser.name,
      ];

      // Remove duplicates
      final uniqueIds = updatedCollaboratorIds.toSet().toList();
      final uniqueNames = updatedCollaboratorNames.toSet().toList();

      final updatedTarget = target.copyWith(
        collaborativeEmployeeIds: uniqueIds,
        collaborativeEmployeeNames: uniqueNames,
      );

      await appProvider.updateSalesTarget(updatedTarget);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('You joined the target as a team member!'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'View',
              textColor: Colors.white,
              onPressed: () {
                // Could navigate to target details
              },
            ),
          ),
        );
      }

      // Refresh the view
      setState(() {});
    }
  }

  void _showLogoutDialog(BuildContext context, AppProvider appProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              appProvider.logout();
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileTab(User user, AppProvider appProvider) {
    // Reuse the EmployeeProfileScreen for consistency
    return EmployeeProfileScreen(
      employee: user,
      appProvider: appProvider,
      showBackButton:
          false, // No back button when viewing own profile from tab bar
      companyContext:
          user.primaryCompanyId, // Use user's current company context
    );
  }

  Widget _buildProfileTabOld(User user, AppProvider appProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.blue,
                        child: Text(
                          user.name.isNotEmpty
                              ? user.name[0].toUpperCase()
                              : 'U',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.name,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user.email,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user.workplaceNames.isNotEmpty
                                  ? user.workplaceNames.join(', ')
                                  : 'No workplace assigned',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Account Settings',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.person),
                    title: const Text('Edit Profile'),
                    subtitle: const Text('Update your name and email'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () =>
                        _showEditProfileDialog(context, user, appProvider),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.lock),
                    title: const Text('Change Password'),
                    subtitle: const Text('Update your password'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () =>
                        _showChangePasswordDialog(context, user, appProvider),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.red),
                    title: const Text('Logout',
                        style: TextStyle(color: Colors.red)),
                    subtitle: const Text('Sign out of your account'),
                    trailing:
                        const Icon(Icons.arrow_forward_ios, color: Colors.red),
                    onTap: () => _showLogoutDialog(context, appProvider),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditProfileDialog(
      BuildContext context, User user, AppProvider appProvider) {
    final nameController = TextEditingController(text: user.name);
    final emailController = TextEditingController(text: user.email);

    // Determine selected country from existing phone number
    Country? selectedCountry = Country.countries.first; // Default to US
    if (user.phoneNumber != null && user.phoneNumber!.isNotEmpty) {
      selectedCountry = Country.getCountryByPhonePrefix(user.phoneNumber!) ??
          Country.countries.first;
    }

    // Set phone controller with only the local number part
    final phoneController = TextEditingController(
      text: user.phoneNumber != null
          ? selectedCountry.formatLocalPhoneNumber(user.phoneNumber!)
          : '',
    );

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Edit Profile'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      // Flag display area
                      Container(
                        width: 50,
                        height: 56,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Center(
                          child: Text(
                            selectedCountry?.flag ?? '',
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: Autocomplete<Country>(
                          initialValue: TextEditingValue(
                              text: selectedCountry?.phonePrefix ?? ''),
                          displayStringForOption: (Country country) =>
                              country.phonePrefix,
                          optionsBuilder: (TextEditingValue textEditingValue) {
                            if (textEditingValue.text.isEmpty) {
                              return Country.countries;
                            }
                            return Country.countries.where((Country country) {
                              final searchText =
                                  textEditingValue.text.toLowerCase();
                              return country.name
                                      .toLowerCase()
                                      .contains(searchText) ||
                                  country.phonePrefix
                                      .toLowerCase()
                                      .contains(searchText) ||
                                  country.code
                                      .toLowerCase()
                                      .contains(searchText);
                            });
                          },
                          onSelected: (Country country) {
                            setState(() {
                              selectedCountry = country;
                              // Update phone number to show only local part when country changes
                              if (phoneController.text.isNotEmpty) {
                                final currentNumber = phoneController.text
                                    .replaceAll(RegExp(r'[^\d]'), '');
                                if (currentNumber.isNotEmpty) {
                                  phoneController.text = selectedCountry!
                                      .formatLocalPhoneNumber(currentNumber);
                                }
                              }
                            });
                          },
                          fieldViewBuilder: (BuildContext context,
                              TextEditingController textEditingController,
                              FocusNode focusNode,
                              VoidCallback onFieldSubmitted) {
                            return TextFormField(
                              controller: textEditingController,
                              focusNode: focusNode,
                              decoration: InputDecoration(
                                labelText: 'Country',
                                border: const OutlineInputBorder(),
                                suffixIcon: selectedCountry != null
                                    ? IconButton(
                                        icon: const Icon(Icons.clear),
                                        onPressed: () {
                                          setState(() {
                                            selectedCountry = null;
                                            textEditingController.clear();
                                          });
                                        },
                                      )
                                    : null,
                              ),
                              onFieldSubmitted: (String value) {
                                onFieldSubmitted();
                              },
                            );
                          },
                          optionsViewBuilder: (BuildContext context,
                              AutocompleteOnSelected<Country> onSelected,
                              Iterable<Country> options) {
                            return Align(
                              alignment: Alignment.topLeft,
                              child: Material(
                                elevation: 4.0,
                                child: ConstrainedBox(
                                  constraints:
                                      const BoxConstraints(maxHeight: 200),
                                  child: ListView.builder(
                                    padding: EdgeInsets.zero,
                                    shrinkWrap: true,
                                    itemCount: options.length,
                                    itemBuilder:
                                        (BuildContext context, int index) {
                                      final Country country =
                                          options.elementAt(index);
                                      return ListTile(
                                        leading: Text(
                                          country.flag,
                                          style: const TextStyle(fontSize: 20),
                                        ),
                                        title: Text(
                                            '${country.name} (${country.phonePrefix})'),
                                        onTap: () {
                                          onSelected(country);
                                        },
                                      );
                                    },
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: phoneController,
                          decoration: const InputDecoration(
                            labelText: 'Phone Number',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.phone,
                          onChanged: (value) {
                            if (value.isNotEmpty && selectedCountry != null) {
                              phoneController.text = selectedCountry!
                                  .formatLocalPhoneNumber(value);
                            }
                          },
                        ),
                      ),
                    ],
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
                onPressed: () {
                  final name = nameController.text.trim();
                  final email = emailController.text.trim();
                  final phoneNumber = phoneController.text.trim();

                  if (name.isNotEmpty && email.isNotEmpty) {
                    // Format phone number with selected country prefix
                    String? formattedPhoneNumber;
                    if (phoneNumber.isNotEmpty && selectedCountry != null) {
                      formattedPhoneNumber =
                          selectedCountry!.formatPhoneNumber(phoneNumber);
                    }

                    final updatedUser = user.copyWith(
                      name: name,
                      email: email,
                      phoneNumber: formattedPhoneNumber,
                    );

                    appProvider.updateUser(updatedUser);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Profile updated successfully!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please fill in all required fields'),
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

  void _showChangePasswordDialog(
      BuildContext context, User user, AppProvider appProvider) {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPasswordController,
              decoration: const InputDecoration(
                labelText: 'Current Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: newPasswordController,
              decoration: const InputDecoration(
                labelText: 'New Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmPasswordController,
              decoration: const InputDecoration(
                labelText: 'Confirm New Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final currentPassword = currentPasswordController.text;
              final newPassword = newPasswordController.text;
              final confirmPassword = confirmPasswordController.text;

              if (currentPassword.isEmpty ||
                  newPassword.isEmpty ||
                  confirmPassword.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please fill in all fields'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              if (newPassword != confirmPassword) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('New passwords do not match'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              if (newPassword.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content:
                        Text('Password must be at least 6 characters long'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              // For demo purposes, we'll just show success message
              // In a real app, you would update the password in the authentication system
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Password updated successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  List<ActionButton> _getEmployeeActionButtons(
      BuildContext context, AppProvider appProvider) {
    return [
      ActionButton(
        icon: Icons.calendar_today,
        label: 'Calendar',
        color: Colors.blue,
        onTap: () => setState(() => _selectedIndex = 0),
      ),
      ActionButton(
        icon: Icons.track_changes,
        label: 'Targets',
        color: Colors.orange,
        onTap: () => setState(() => _selectedIndex = 1),
      ),
      ActionButton(
        icon: Icons.card_giftcard,
        label: 'Bonuses',
        color: Colors.purple,
        onTap: () => setState(() => _selectedIndex = 2),
      ),
      ActionButton(
        icon: Icons.message,
        label: 'Messages',
        color: Colors.green,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const MessagingScreen(),
          ),
        ),
      ),
      ActionButton(
        icon: Icons.person,
        label: 'Profile',
        color: Colors.teal,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EmployeeProfileScreen(
              employee: appProvider.currentUser!,
              appProvider: appProvider,
              showBackButton:
                  true, // Show back button when navigating from action button
            ),
          ),
        ),
      ),
    ];
  }
}

class _AddCollaboratorsDialog extends StatefulWidget {
  final SalesTarget target;
  final String userId;

  const _AddCollaboratorsDialog({
    required this.target,
    required this.userId,
  });

  @override
  State<_AddCollaboratorsDialog> createState() =>
      _AddCollaboratorsDialogState();
}

class _AddCollaboratorsDialogState extends State<_AddCollaboratorsDialog> {
  late List<String> selectedEmployeeIds;
  late List<String> selectedEmployeeNames;

  @override
  void initState() {
    super.initState();
    selectedEmployeeIds = List.from(widget.target.collaborativeEmployeeIds);
    selectedEmployeeNames = List.from(widget.target.collaborativeEmployeeNames);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Team Members'),
      content: SizedBox(
        width: double.maxFinite,
        child: FutureBuilder<List<User>>(
          future: context.read<AppProvider>().getUsers(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              final employees = snapshot.data!
                  .where((u) =>
                      (u.role == UserRole.employee ||
                          u.role == UserRole.admin) &&
                      u.id != widget.userId)
                  .toList();

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Select employees who worked with you on this target:',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: employees.length,
                      itemBuilder: (context, index) {
                        final employee = employees[index];
                        final isSelected =
                            selectedEmployeeIds.contains(employee.id);

                        return CheckboxListTile(
                          title: Text(employee.name),
                          subtitle: Text(employee.workplaceNames.isNotEmpty
                              ? employee.workplaceNames.join(', ')
                              : 'No workplace'),
                          value: isSelected,
                          tristate: false,
                          onChanged: (bool? value) {
                            print(
                                'DEBUG: Checkbox changed for ${employee.name}: $value');
                            setState(() {
                              if (value == true) {
                                if (!selectedEmployeeIds
                                    .contains(employee.id)) {
                                  selectedEmployeeIds.add(employee.id);
                                  selectedEmployeeNames.add(employee.name);
                                }
                              } else {
                                selectedEmployeeIds.remove(employee.id);
                                selectedEmployeeNames.remove(employee.name);
                              }
                              print(
                                  'DEBUG: Selected IDs: $selectedEmployeeIds');
                              print(
                                  'DEBUG: Selected Names: $selectedEmployeeNames');
                            });
                          },
                        );
                      },
                    ),
                  ),
                ],
              );
            }
            return const CircularProgressIndicator();
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        Consumer<AppProvider>(
          builder: (context, appProvider, child) {
            final user = appProvider.currentUser!;
            final isAssignedEmployee =
                widget.target.assignedEmployeeId == user.id;

            return ElevatedButton(
              onPressed: () {
                print(
                    'DEBUG: Dialog Save - Selected IDs: $selectedEmployeeIds');
                print(
                    'DEBUG: Dialog Save - Selected Names: $selectedEmployeeNames');

                context.read<AppProvider>().submitTeamChange(
                      widget.target.id,
                      List<String>.from(selectedEmployeeIds),
                      List<String>.from(selectedEmployeeNames),
                      user.id,
                    );

                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isAssignedEmployee
                        ? 'Team members updated successfully!'
                        : 'Team change submitted for admin approval!'),
                    backgroundColor:
                        isAssignedEmployee ? Colors.green : Colors.orange,
                  ),
                );
              },
              child: Text(isAssignedEmployee ? 'Done' : 'Submit for Approval'),
            );
          },
        ),
      ],
    );
  }
}
