import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'target_profile_screen.dart';
import 'import_targets_screen.dart';
import 'import_employees_screen.dart';
import 'companies_list_screen.dart';
import '../providers/app_provider.dart';
import '../models/sales_target.dart';
import '../models/bonus.dart';
import '../models/points_transaction.dart';
import '../models/user.dart';
import '../models/workplace.dart';
import '../models/company.dart';
import '../models/approval_request.dart';
import '../models/points_rules.dart';
import '../services/storage_service.dart';
import '../widgets/profile_header_widget.dart';
import '../widgets/target_card_widget.dart';
import 'import_bonuses_screen.dart';
import 'messaging_screen.dart';
import 'chat_screen.dart';

class EmployeePerformance {
  final String employeeId;
  final String employeeName;
  final int totalTargets;
  final int completedTargets;
  final double totalTargetAmount;
  final double totalActualAmount;
  final int totalPoints;

  EmployeePerformance({
    required this.employeeId,
    required this.employeeName,
    required this.totalTargets,
    required this.completedTargets,
    required this.totalTargetAmount,
    required this.totalActualAmount,
    required this.totalPoints,
  });
}

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;
  String _selectedTimePeriod = 'all';
  DateTime _selectedDate = DateTime.now();
  bool _showAvailableBonuses = true; // toggle between available and redeemed

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        final user = appProvider.currentUser!;
        final selectedDateTargets = appProvider.salesTargets.where((target) {
          return target.date.year == _selectedDate.year &&
              target.date.month == _selectedDate.month &&
              target.date.day == _selectedDate.day;
        }).toList();
        final allTargets = appProvider.salesTargets;
        final allBonuses = appProvider.bonuses;
        final allTransactions = appProvider.pointsTransactions;

        return Scaffold(
          appBar: AppBar(
            title: Text('Admin Dashboard'),
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
              ProfileHeaderWidget(
                userName: user.name,
                userEmail: user.email,
                onProfileTap: () => setState(
                    () => _selectedIndex = 3), // Navigate to Profile tab
                actionButtons: _getAdminActionButtons(context, appProvider),
                salesTargets: allTargets,
                selectedDate: _selectedDate,
                onDateSelected: (selectedDate) {
                  setState(() {
                    _selectedDate = selectedDate;
                  });
                },
              ),
              // Main Content
              Expanded(
                child: _getCurrentTab(_selectedIndex, selectedDateTargets,
                    allTargets, allTransactions, appProvider, allBonuses),
              ),
            ],
          ),
          floatingActionButton: _getFloatingActionButton(
              context, appProvider, selectedDateTargets),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Container(
                height: 80,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(0, Icons.dashboard, 'Dashboard'),
                    _buildNavItem(1, Icons.card_giftcard, 'Bonuses'),
                    _buildNavItem(2, Icons.settings, 'Settings'),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAdminSimpleBonusCard(BuildContext context, Bonus bonus,
      int userPoints, String userId, AppProvider appProvider) {
    final canRedeem = userPoints >= bonus.pointsRequired;
    final pointsNeeded = bonus.pointsRequired - userPoints;
    final progress = (userPoints / bonus.pointsRequired).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: canRedeem
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
                    value: progress,
                    strokeWidth: 6,
                    color: canRedeem ? Colors.purple : Colors.grey,
                    backgroundColor: Colors.grey.withOpacity(0.15),
                  ),
                ),
                Text(
                  '${(progress * 100).floor()}%',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: canRedeem ? Colors.purple : Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
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
                    Icon(Icons.stars, size: 16, color: Colors.orange),
                    const SizedBox(width: 4),
                    Text(
                      '${bonus.pointsRequired} points',
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${userPoints.clamp(0, bonus.pointsRequired)} / ${bonus.pointsRequired}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (canRedeem)
            ElevatedButton(
              onPressed: () async {
                final success = await appProvider.redeemBonus(bonus.id, userId);
                if (!context.mounted) return;
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Claimed "${bonus.name}"'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Insufficient points to claim'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              },
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

  Widget _buildAdminSimpleRedeemedCard(
      BuildContext context, PointsTransaction t) {
    // Parse description to check if it contains a secret code
    final secretCodeRegex = RegExp(r'Secret Code: (.+?)(?:\s*$)');
    final secretCodeMatch = secretCodeRegex.firstMatch(t.description);
    final hasSecretCode = secretCodeMatch != null;
    final secretCode = secretCodeMatch?.group(1);

    // Clean description - remove the secret code part from end
    final cleanedDescription =
        t.description.replaceAll(RegExp(r'\s*\(Secret Code: .+?\)$'), '');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
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
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Main bonus name
                Text(
                  cleanedDescription,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                // Points info row
                Row(
                  children: [
                    Icon(Icons.stars, size: 16, color: Colors.orange),
                    const SizedBox(width: 4),
                    Text(
                      '${t.points.abs()} points',
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      DateFormat('MMM dd, yyyy').format(t.date),
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                // Secret code section
                if (hasSecretCode) ...[
                  const SizedBox(height: 8),
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
              ],
            ),
          ),
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
          ),
        ],
      ),
    );
  }

  Widget _getCurrentTab(
      int index,
      List<SalesTarget> selectedDateTargets,
      List<SalesTarget> allTargets,
      List<PointsTransaction> allTransactions,
      AppProvider appProvider,
      List<Bonus> allBonuses) {
    switch (index) {
      case 0:
        return _buildDashboardTab(selectedDateTargets, allTargets,
            allTransactions, appProvider, allBonuses);
      case 1:
        return _buildBonusesTab(appProvider, allBonuses);
      case 2:
        return _buildSettingsTab(
            appProvider, allTargets, allTransactions, allBonuses);
      default:
        return _buildDashboardTab(selectedDateTargets, allTargets,
            allTransactions, appProvider, allBonuses);
    }
  }

  Widget _buildDashboardTab(
      List<SalesTarget> selectedDateTargets,
      List<SalesTarget> allTargets,
      List<PointsTransaction> allTransactions,
      AppProvider appProvider,
      List<Bonus> allBonuses) {
    final isToday = _selectedDate.year == DateTime.now().year &&
        _selectedDate.month == DateTime.now().month &&
        _selectedDate.day == DateTime.now().day;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date Selector
          Card(
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
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
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _selectedDate =
                                _selectedDate.subtract(const Duration(days: 1));
                          });
                        },
                        icon: const Icon(Icons.chevron_left),
                        tooltip: 'Previous Day',
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.blue.shade100,
                          foregroundColor: Colors.blue.shade700,
                        ),
                      ),
                      const SizedBox(width: 8),
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
                              horizontal: 12, vertical: 8),
                        ),
                        child: const Text('Today'),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _selectedDate =
                                _selectedDate.add(const Duration(days: 1));
                          });
                        },
                        icon: const Icon(Icons.chevron_right),
                        tooltip: 'Next Day',
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.blue.shade100,
                          foregroundColor: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Auto-processed targets feedback
          if (appProvider.autoProcessedTargets.isNotEmpty) ...[
            _buildAutoProcessedTargetsCard(appProvider),
            const SizedBox(height: 16),
          ],
          // Analytics Section (only show for today)
          if (isToday) ...[
            _buildAnalyticsSection(selectedDateTargets, allTargets,
                allTransactions, allBonuses, appProvider),
            const SizedBox(height: 24),
          ],
          Text(
            isToday
                ? 'Today\'s Targets'
                : 'Targets for ${DateFormat('MMM dd').format(_selectedDate)}',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          if (selectedDateTargets.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(isToday
                    ? 'No targets for today'
                    : 'No targets for selected date'),
              ),
            )
          else
            ...selectedDateTargets.map((target) => Dismissible(
                  key: Key('target_${target.id}'),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.delete,
                          color: Colors.white,
                          size: 28,
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Delete',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  confirmDismiss: (direction) async {
                    // Use existing delete dialog
                    bool? shouldDelete = false;
                    await showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete Target'),
                        content: Text(
                            'Are you sure you want to delete this target for \$${target.targetAmount.toStringAsFixed(0)}?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              shouldDelete = true;
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red),
                            child: const Text('Delete',
                                style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    );
                    return shouldDelete;
                  },
                  onDismissed: (direction) async {
                    await appProvider.deleteSalesTarget(target.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Target deleted successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  child: TargetCard(
                    target: target,
                    appProvider: appProvider,
                    isAdminView: true,
                    onEdit: () =>
                        _showEditTargetDialog(context, target, appProvider),
                    onQuickApprove: () => _showQuickApproveDialog(
                        context,
                        appProvider.approvalRequests
                            .where((request) =>
                                request.targetId == target.id &&
                                request.status == ApprovalStatus.pending)
                            .toList(),
                        appProvider),
                    onFixPoints: () =>
                        _showFixPointsDialog(context, target, appProvider),
                    onAdjustPoints: () => _showTargetPointsAdjustmentDialog(
                        context, target, appProvider),
                  ),
                )),
        ],
      ),
    );
  }

  Widget _buildAnalyticsSection(
      List<SalesTarget> todaysTargets,
      List<SalesTarget> allTargets,
      List<PointsTransaction> allTransactions,
      List<Bonus> allBonuses,
      AppProvider appProvider) {
    // Calculate analytics
    final today = DateTime.now();
    final thisWeekTargets = allTargets.where((target) {
      final targetDate = target.date;
      final weekStart = today.subtract(Duration(days: today.weekday - 1));
      final weekEnd = weekStart.add(const Duration(days: 6));
      return targetDate.isAfter(weekStart.subtract(const Duration(days: 1))) &&
          targetDate.isBefore(weekEnd.add(const Duration(days: 1)));
    }).toList();

    final completedTargets = allTargets.where((target) => target.isMet).length;
    final completionRate = allTargets.isNotEmpty
        ? (completedTargets / allTargets.length) * 100
        : 0.0;

    final totalTargetAmount =
        allTargets.fold<double>(0, (sum, target) => sum + target.targetAmount);
    final totalActualAmount =
        allTargets.fold<double>(0, (sum, target) => sum + target.actualAmount);

    final totalPointsEarned = allTransactions
        .where(
            (transaction) => transaction.type == PointsTransactionType.earned)
        .fold<int>(0, (sum, transaction) => sum + transaction.points);

    final totalPointsRedeemed = allTransactions
        .where(
            (transaction) => transaction.type == PointsTransactionType.redeemed)
        .fold<int>(0, (sum, transaction) => sum + transaction.points);

    final adminTeamParticipationPoints = allTransactions
        .where((transaction) =>
            transaction.type == PointsTransactionType.earned &&
            transaction.description.contains('Added as team member'))
        .fold<int>(0, (sum, transaction) => sum + transaction.points);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Analytics Overview',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),

        // Top row - Key metrics
        Row(
          children: [
            Expanded(
              child: _buildAnalyticsCard(
                'Today\'s Targets',
                todaysTargets.length.toString(),
                Icons.today,
                Colors.blue,
                subtitle:
                    '${todaysTargets.where((t) => t.isMet).length} completed',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildAnalyticsCard(
                'This Week',
                thisWeekTargets.length.toString(),
                Icons.calendar_view_week,
                Colors.green,
                subtitle:
                    '${thisWeekTargets.where((t) => t.isMet).length} completed',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Second row - Performance metrics
        Row(
          children: [
            Expanded(
              child: _buildAnalyticsCard(
                'Completion Rate',
                '${completionRate.toStringAsFixed(1)}%',
                Icons.trending_up,
                completionRate >= 70
                    ? Colors.green
                    : completionRate >= 50
                        ? Colors.orange
                        : Colors.red,
                subtitle: '$completedTargets of ${allTargets.length} targets',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildAnalyticsCard(
                'Total Revenue',
                '\$${totalActualAmount.toStringAsFixed(0)}',
                Icons.attach_money,
                Colors.purple,
                subtitle: 'Target: \$${totalTargetAmount.toStringAsFixed(0)}',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Third row - Points metrics
        Row(
          children: [
            Expanded(
              child: _buildAnalyticsCard(
                'Points Earned',
                totalPointsEarned.toString(),
                Icons.stars,
                Colors.amber,
                subtitle: 'Total earned',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildAnalyticsCard(
                'Points Redeemed',
                totalPointsRedeemed.toString(),
                Icons.card_giftcard,
                Colors.teal,
                subtitle: 'Total redeemed',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildAnalyticsCard(
      String title, String value, IconData icon, Color color,
      {String? subtitle}) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.grey,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyPerformanceChart(List<SalesTarget> weekTargets) {
    if (weekTargets.isEmpty) {
      return Container(
        height: 100,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Text(
            'No data for this week',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    // Group targets by day
    final Map<int, List<SalesTarget>> targetsByDay = {};
    for (final target in weekTargets) {
      final day = target.date.weekday;
      targetsByDay.putIfAbsent(day, () => []).add(target);
    }

    return Container(
      height: 100,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(7, (index) {
          final day = index + 1;
          final dayTargets = targetsByDay[day] ?? [];
          final completedCount = dayTargets.where((t) => t.isMet).length;
          final totalCount = dayTargets.length;
          final height =
              totalCount > 0 ? (completedCount / totalCount) * 80 : 0.0;

          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                width: 30,
                height: height,
                decoration: BoxDecoration(
                  color: height > 0.7
                      ? Colors.green
                      : height > 0.4
                          ? Colors.orange
                          : Colors.red,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _getDayAbbreviation(day),
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
          );
        }),
      ),
    );
  }

  String _getDayAbbreviation(int day) {
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return days[day - 1];
  }

  List<SalesTarget> _getThisWeekTargets(List<SalesTarget> allTargets) {
    final today = DateTime.now();
    return allTargets.where((target) {
      final targetDate = target.date;
      final weekStart = today.subtract(Duration(days: today.weekday - 1));
      final weekEnd = weekStart.add(const Duration(days: 6));
      return targetDate.isAfter(weekStart.subtract(const Duration(days: 1))) &&
          targetDate.isBefore(weekEnd.add(const Duration(days: 1)));
    }).toList();
  }

  List<SalesTarget> _filterTargetsByTimePeriod(
      List<SalesTarget> targets, String timePeriod, DateTime now) {
    switch (timePeriod) {
      case 'today':
        final today = DateTime(now.year, now.month, now.day);
        final tomorrow = today.add(const Duration(days: 1));
        return targets
            .where((target) =>
                target.date
                    .isAfter(today.subtract(const Duration(milliseconds: 1))) &&
                target.date.isBefore(tomorrow))
            .toList();
      case 'week':
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        final weekEnd = weekStart.add(const Duration(days: 6));
        return targets
            .where((target) =>
                target.date
                    .isAfter(weekStart.subtract(const Duration(days: 1))) &&
                target.date.isBefore(weekEnd.add(const Duration(days: 1))))
            .toList();
      case 'month':
        final monthStart = DateTime(now.year, now.month, 1);
        final monthEnd = DateTime(now.year, now.month + 1, 1);
        return targets
            .where((target) =>
                target.date.isAfter(
                    monthStart.subtract(const Duration(milliseconds: 1))) &&
                target.date.isBefore(monthEnd))
            .toList();
      case 'year':
        final yearStart = DateTime(now.year, 1, 1);
        final yearEnd = DateTime(now.year + 1, 1, 1);
        return targets
            .where((target) =>
                target.date.isAfter(
                    yearStart.subtract(const Duration(milliseconds: 1))) &&
                target.date.isBefore(yearEnd))
            .toList();
      default:
        return targets;
    }
  }

  List<PointsTransaction> _filterTransactionsByTimePeriod(
      List<PointsTransaction> transactions, String timePeriod, DateTime now) {
    switch (timePeriod) {
      case 'today':
        final today = DateTime(now.year, now.month, now.day);
        final tomorrow = today.add(const Duration(days: 1));
        return transactions
            .where((transaction) =>
                transaction.date
                    .isAfter(today.subtract(const Duration(milliseconds: 1))) &&
                transaction.date.isBefore(tomorrow))
            .toList();
      case 'week':
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        final weekEnd = weekStart.add(const Duration(days: 6));
        return transactions
            .where((transaction) =>
                transaction.date
                    .isAfter(weekStart.subtract(const Duration(days: 1))) &&
                transaction.date.isBefore(weekEnd.add(const Duration(days: 1))))
            .toList();
      case 'month':
        final monthStart = DateTime(now.year, now.month, 1);
        final monthEnd = DateTime(now.year, now.month + 1, 1);
        return transactions
            .where((transaction) =>
                transaction.date.isAfter(
                    monthStart.subtract(const Duration(milliseconds: 1))) &&
                transaction.date.isBefore(monthEnd))
            .toList();
      case 'year':
        final yearStart = DateTime(now.year, 1, 1);
        final yearEnd = DateTime(now.year + 1, 1, 1);
        return transactions
            .where((transaction) =>
                transaction.date.isAfter(
                    yearStart.subtract(const Duration(milliseconds: 1))) &&
                transaction.date.isBefore(yearEnd))
            .toList();
      default:
        return transactions;
    }
  }

  Widget _buildTopPerformersWithToggle(List<SalesTarget> allTargets,
      List<PointsTransaction> allTransactions, AppProvider appProvider) {
    return Column(
      children: [
        // Time Period Toggle
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.people, color: Colors.blue[600]),
                    const SizedBox(width: 8),
                    Text(
                      'Top Performers',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const Spacer(),
                    Text(
                      'Time Period:',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildTimePeriodChip('all', 'All Time'),
                      const SizedBox(width: 8),
                      _buildTimePeriodChip('today', 'Today'),
                      const SizedBox(width: 8),
                      _buildTimePeriodChip('week', 'This Week'),
                      const SizedBox(width: 8),
                      _buildTimePeriodChip('month', 'This Month'),
                      const SizedBox(width: 8),
                      _buildTimePeriodChip('year', 'This Year'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Top Performers Content
        _buildEmployeePerformanceSection(
            allTargets, allTransactions, appProvider,
            timePeriod: _selectedTimePeriod),
      ],
    );
  }

  Widget _buildTimePeriodChip(String period, String label) {
    final isSelected = _selectedTimePeriod == period;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedTimePeriod = period;
          });
        }
      },
      selectedColor: Colors.blue[100],
      checkmarkColor: Colors.blue[700],
      labelStyle: TextStyle(
        color: isSelected ? Colors.blue[700] : Colors.grey[600],
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  Widget _buildEmployeePerformanceSection(List<SalesTarget> allTargets,
      List<PointsTransaction> allTransactions, AppProvider appProvider,
      {String timePeriod = 'all'}) {
    // Filter targets and transactions based on time period
    final now = DateTime.now();
    final filteredTargets =
        _filterTargetsByTimePeriod(allTargets, timePeriod, now);
    final filteredTransactions =
        _filterTransactionsByTimePeriod(allTransactions, timePeriod, now);

    // Calculate employee performance
    final Map<String, EmployeePerformance> employeeStats = {};

    for (final target in filteredTargets) {
      if (target.assignedEmployeeId != null) {
        final employeeId = target.assignedEmployeeId!;
        if (!employeeStats.containsKey(employeeId)) {
          employeeStats[employeeId] = EmployeePerformance(
            employeeId: employeeId,
            employeeName: target.assignedEmployeeName ?? 'Unknown',
            totalTargets: 0,
            completedTargets: 0,
            totalTargetAmount: 0,
            totalActualAmount: 0,
            totalPoints: 0,
          );
        }

        final stats = employeeStats[employeeId]!;
        employeeStats[employeeId] = EmployeePerformance(
          employeeId: employeeId,
          employeeName: stats.employeeName,
          totalTargets: stats.totalTargets + 1,
          completedTargets: stats.completedTargets + (target.isMet ? 1 : 0),
          totalTargetAmount: stats.totalTargetAmount + target.targetAmount,
          totalActualAmount: stats.totalActualAmount + target.actualAmount,
          totalPoints: stats.totalPoints,
        );
      }
    }

    // Add points from transactions (earned and adjustment points only)
    for (final transaction in filteredTransactions) {
      if ((transaction.type == PointsTransactionType.earned ||
              transaction.type == PointsTransactionType.adjustment) &&
          employeeStats.containsKey(transaction.userId)) {
        final stats = employeeStats[transaction.userId]!;
        employeeStats[transaction.userId] = EmployeePerformance(
          employeeId: stats.employeeId,
          employeeName: stats.employeeName,
          totalTargets: stats.totalTargets,
          completedTargets: stats.completedTargets,
          totalTargetAmount: stats.totalTargetAmount,
          totalActualAmount: stats.totalActualAmount,
          totalPoints: stats.totalPoints + transaction.points,
        );
      }
    }

    final sortedEmployees = employeeStats.values.toList()
      ..sort((a, b) => b.totalPoints.compareTo(a.totalPoints));

    final topPerformers = sortedEmployees.take(3).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (topPerformers.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'No employee data available',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ...topPerformers.asMap().entries.map((entry) {
                final index = entry.key;
                final employee = entry.value;
                final completionRate = employee.totalTargets > 0
                    ? (employee.completedTargets / employee.totalTargets) * 100
                    : 0.0;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: index == 0
                        ? Colors.amber[50]
                        : index == 1
                            ? Colors.grey[100]
                            : Colors.brown[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: index == 0
                          ? Colors.amber[300]!
                          : index == 1
                              ? Colors.grey[300]!
                              : Colors.brown[300]!,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Rank indicator
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: index == 0
                              ? Colors.amber[400]
                              : index == 1
                                  ? Colors.grey[400]
                                  : Colors.brown[400],
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Employee info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              employee.employeeName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 16,
                              runSpacing: 4,
                              children: [
                                Consumer<AppProvider>(
                                  builder: (context, provider, child) {
                                    final earnedPoints =
                                        provider.getUserEarnedPoints(
                                            employee.employeeId);
                                    final currentPoints =
                                        provider.getUserTotalPoints(
                                            employee.employeeId);
                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.stars,
                                                size: 16,
                                                color: Colors.amber[600]),
                                            const SizedBox(width: 4),
                                            Text(
                                              '$earnedPoints pts awarded',
                                              style: TextStyle(
                                                color: Colors.amber[600],
                                                fontWeight: FontWeight.w600,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.account_balance_wallet,
                                                size: 16,
                                                color: Colors.blue[600]),
                                            const SizedBox(width: 4),
                                            Text(
                                              '$currentPoints current',
                                              style: TextStyle(
                                                color: Colors.blue[600],
                                                fontWeight: FontWeight.w600,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    );
                                  },
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.check_circle,
                                        size: 16, color: Colors.green[600]),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${employee.completedTargets}/${employee.totalTargets}',
                                      style: TextStyle(
                                        color: Colors.green[600],
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 16,
                              runSpacing: 4,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.trending_up,
                                        size: 16, color: Colors.blue[600]),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${completionRate.toStringAsFixed(1)}%',
                                      style: TextStyle(
                                        color: Colors.blue[600],
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.attach_money,
                                        size: 16, color: Colors.purple[600]),
                                    const SizedBox(width: 4),
                                    Text(
                                      '\$${employee.totalActualAmount.toStringAsFixed(0)}',
                                      style: TextStyle(
                                        color: Colors.purple[600],
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
          ],
        ),
      ),
    );
  }

  void _showCompanySettings(
      BuildContext context, AppProvider appProvider) async {
    final companies = await appProvider.getCompanies();
    final currentUser = appProvider.currentUser!;

    // Check if admin already has a company
    final userCompany =
        companies.where((c) => c.adminUserId == currentUser.id).firstOrNull;

    if (userCompany != null) {
      // Show company details with edit option
      _showCompanyDetailsDialog(context, appProvider, userCompany);
    } else {
      // Show create company dialog
      _showCreateCompanyDialog(context, appProvider);
    }
  }

  void _showCompanyDetailsDialog(
      BuildContext context, AppProvider appProvider, Company company) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Company Settings'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCompanyInfoRow('Company Name', company.name),
              if (company.address != null && company.address!.isNotEmpty)
                _buildCompanyInfoRow('Address', company.address!),
              if (company.contactEmail != null &&
                  company.contactEmail!.isNotEmpty)
                _buildCompanyInfoRow('Contact Email', company.contactEmail!),
              if (company.contactPhone != null &&
                  company.contactPhone!.isNotEmpty)
                _buildCompanyInfoRow('Contact Phone', company.contactPhone!),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showEditCompanyDialog(context, appProvider, company);
            },
            child: const Text('Edit'),
          ),
        ],
      ),
    );
  }

  Widget _buildCompanyInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateCompanyDialog(BuildContext context, AppProvider appProvider) {
    final nameController = TextEditingController();
    final addressController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Register Your Company'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Company Name *',
                  border: OutlineInputBorder(),
                  hintText: 'Enter company name',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  border: OutlineInputBorder(),
                  hintText: 'Enter company address',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Contact Email',
                  border: OutlineInputBorder(),
                  hintText: 'company@example.com',
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Contact Phone',
                  border: OutlineInputBorder(),
                  hintText: '+1234567890',
                ),
                keyboardType: TextInputType.phone,
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
              if (nameController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a company name')),
                );
                return;
              }

              final newCompany = Company(
                id: 'company_${DateTime.now().millisecondsSinceEpoch}',
                name: nameController.text.trim(),
                address: addressController.text.trim().isEmpty
                    ? null
                    : addressController.text.trim(),
                contactEmail: emailController.text.trim().isEmpty
                    ? null
                    : emailController.text.trim(),
                contactPhone: phoneController.text.trim().isEmpty
                    ? null
                    : phoneController.text.trim(),
                adminUserId: appProvider.currentUser!.id,
                createdAt: DateTime.now(),
              );

              await appProvider.addCompany(newCompany);

              // Update current user to have this as their primary company
              final updatedUser = appProvider.currentUser!.copyWith(
                companyIds: [newCompany.id],
                companyNames: [newCompany.name],
                primaryCompanyId: newCompany.id,
              );
              await appProvider.updateUser(updatedUser);

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'Company "${newCompany.name}" created successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Create Company'),
          ),
        ],
      ),
    );
  }

  void _showEditCompanyDialog(
      BuildContext context, AppProvider appProvider, Company company) {
    final nameController = TextEditingController(text: company.name);
    final addressController =
        TextEditingController(text: company.address ?? '');
    final emailController =
        TextEditingController(text: company.contactEmail ?? '');
    final phoneController =
        TextEditingController(text: company.contactPhone ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Company'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Company Name *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Contact Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Contact Phone',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
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
              if (nameController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a company name')),
                );
                return;
              }

              final updatedCompany = company.copyWith(
                name: nameController.text.trim(),
                address: addressController.text.trim().isEmpty
                    ? null
                    : addressController.text.trim(),
                contactEmail: emailController.text.trim().isEmpty
                    ? null
                    : emailController.text.trim(),
                contactPhone: phoneController.text.trim().isEmpty
                    ? null
                    : phoneController.text.trim(),
              );

              await appProvider.updateCompany(updatedCompany);

              // Update company name in user's list if it changed
              if (updatedCompany.name != company.name) {
                final currentUser = appProvider.currentUser!;
                if (currentUser.companyNames.contains(company.name)) {
                  final updatedNames = currentUser.companyNames
                      .map<String>((name) =>
                          name == company.name ? updatedCompany.name : name)
                      .toList();
                  final updatedUser =
                      currentUser.copyWith(companyNames: updatedNames);
                  await appProvider.updateUser(updatedUser);
                }
              }

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Company updated successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }

  void _showLoadDemoDataDialog(BuildContext context, AppProvider appProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Load Demo Data'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('This will add demo users and data for testing:'),
            SizedBox(height: 8),
            Text('• John Doe (Admin)'),
            Text('• Jane Smith (Employee)'),
            Text('• Karl Kristjansson (Employee)'),
            Text('• Sample bonuses, targets, and workplaces'),
            SizedBox(height: 16),
            Text(
              'Your existing data will NOT be deleted.',
              style: TextStyle(fontWeight: FontWeight.bold),
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
              Navigator.pop(context);
              // Show loading indicator
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(
                  child: CircularProgressIndicator(),
                ),
              );

              // Load demo data
              await StorageService.initializeSampleData();
              await appProvider.initialize();

              if (context.mounted) {
                Navigator.pop(context); // Close loading
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Demo data loaded successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Load Demo Data'),
          ),
        ],
      ),
    );
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
              appProvider.logout();
              Navigator.pop(context);
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _navigateToEmployeeProfile(
      BuildContext context, User employee, AppProvider appProvider) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            EmployeeProfileScreen(employee: employee, appProvider: appProvider),
      ),
    );
  }

  void _navigateToStoreProfile(
      BuildContext context, Workplace workplace, AppProvider appProvider) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            StoreProfileScreen(workplace: workplace, appProvider: appProvider),
      ),
    );
  }

  void _showEditEmployeeDialog(
      BuildContext context, User employee, AppProvider appProvider) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Employee Profile',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    iconSize: 28,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Profile Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.blue[600],
                      child: Text(
                        employee.name[0].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            employee.name,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            employee.email,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.green[100],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.stars,
                                    size: 16, color: Colors.green[700]),
                                const SizedBox(width: 4),
                                Text(
                                  '${employee.totalPoints} points',
                                  style: TextStyle(
                                    color: Colors.green[700],
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Remove Employee'),
                            content: Text(
                                'Are you sure you want to remove ${employee.name}? This cannot be undone.'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context, true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Remove'),
                              ),
                            ],
                          ),
                        );
                        if (confirmed == true) {
                          await appProvider.deleteUser(employee.id);
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Removed ${employee.name}'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.delete),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      label: const Text('Remove'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Profile Information
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildEmployeeProfileCard(
                        'Personal Information',
                        [
                          _buildEmployeeProfileField(
                            Icons.person,
                            'Full Name',
                            employee.name,
                            () => _showEditEmployeeFieldDialog(
                                context, 'Name', employee.name, (newValue) {
                              // Update name logic here
                              _updateEmployeeField(context, employee, 'name',
                                  newValue, appProvider);
                            }),
                          ),
                          _buildEmployeeProfileField(
                            Icons.email,
                            'Email Address',
                            employee.email,
                            () => _showEditEmployeeFieldDialog(
                                context, 'Email', employee.email, (newValue) {
                              // Update email logic here
                              _updateEmployeeField(context, employee, 'email',
                                  newValue, appProvider);
                            }),
                          ),
                          _buildEmployeeProfileField(
                            Icons.phone,
                            'Phone Number',
                            employee.phoneNumber ?? 'Not set',
                            () => _showEditEmployeeFieldDialog(
                                context,
                                'Phone Number',
                                employee.phoneNumber ?? '', (newValue) {
                              // Update phone logic here
                              _updateEmployeeField(context, employee,
                                  'phoneNumber', newValue, appProvider);
                            }),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildEmployeeProfileCard(
                        'Performance & Points',
                        [
                          _buildEmployeeProfileField(
                            Icons.stars,
                            'Total Points',
                            '${employee.totalPoints} points',
                            null, // Read-only
                          ),
                          _buildEmployeeProfileField(
                            Icons.work,
                            'Role',
                            employee.role.name.toUpperCase(),
                            null, // Read-only
                          ),
                          _buildEmployeeProfileField(
                            Icons.calendar_today,
                            'Member Since',
                            'Recently joined', // You can add a join date field to User model
                            null, // Read-only
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildEmployeeProfileCard(
                        'Actions',
                        [
                          _buildEmployeeProfileField(
                            Icons.lock_reset,
                            'Reset Password',
                            'Send password reset email',
                            () => _showResetPasswordDialog(
                                context, employee, appProvider),
                          ),
                          _buildEmployeeProfileField(
                            Icons.stars,
                            'Adjust Points',
                            'Add or remove points',
                            () => _showAdjustPointsDialog(
                                context, employee, appProvider),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditWorkplaceDialog(
      BuildContext context, Workplace workplace, AppProvider appProvider) {
    // Simple edit dialog for now
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Workplace'),
        content: Text('Edit functionality for ${workplace.name}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showEditBonusDialog(BuildContext context, Bonus bonus) {
    // Simple edit dialog for now
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Bonus'),
        content: Text('Edit functionality for ${bonus.name}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeProfileCard(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildEmployeeProfileField(
      IconData icon, String label, String value, VoidCallback? onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
                      label,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                Icon(Icons.arrow_forward_ios,
                    size: 16, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditEmployeeFieldDialog(BuildContext context, String fieldName,
      String currentValue, Function(String) onSave) {
    final controller = TextEditingController(text: currentValue);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit $fieldName'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: fieldName,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              onSave(controller.text);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _updateEmployeeField(BuildContext context, User employee, String field,
      String newValue, AppProvider appProvider) async {
    try {
      User updatedEmployee;

      switch (field) {
        case 'name':
          updatedEmployee = employee.copyWith(name: newValue);
          break;
        case 'email':
          updatedEmployee = employee.copyWith(email: newValue);
          break;
        case 'phoneNumber':
          updatedEmployee = employee.copyWith(phoneNumber: newValue);
          break;
        default:
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Unknown field: $field'),
              backgroundColor: Colors.red,
            ),
          );
          return;
      }

      // Update the employee in the database
      await appProvider.updateUser(updatedEmployee);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$field updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating $field: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showResetPasswordDialog(
      BuildContext context, User employee, AppProvider appProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Password'),
        content: Text('Send password reset email to ${employee.email}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content:
                      Text('Password reset email sent to ${employee.email}'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  void _showAdjustPointsDialog(
      BuildContext context, User employee, AppProvider appProvider) {
    final pointsController = TextEditingController();
    String selectedAction = 'add';

    // Get admin's current company ID for company-specific points
    final adminCompanyId = appProvider.currentUser?.primaryCompanyId;
    final currentPoints = adminCompanyId != null
        ? employee.getCompanyPoints(adminCompanyId)
        : employee.totalPoints;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Adjust Points'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Current points: $currentPoints'),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedAction,
                decoration: const InputDecoration(
                  labelText: 'Action',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'add', child: Text('Add Points')),
                  DropdownMenuItem(
                      value: 'remove', child: Text('Remove Points')),
                ],
                onChanged: (value) {
                  setState(() {
                    selectedAction = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: pointsController,
                decoration: const InputDecoration(
                  labelText: 'Points Amount',
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
            TextButton(
              onPressed: () async {
                final points = int.tryParse(pointsController.text);
                print(
                    'DEBUG: UI - Entered points: $points, Action: $selectedAction, Company: $adminCompanyId');
                if (points != null && points > 0) {
                  Navigator.pop(context);

                  // Calculate the points change (positive for add, negative for remove)
                  final pointsChange =
                      selectedAction == 'add' ? points : -points;
                  print('DEBUG: UI - Calculated pointsChange: $pointsChange');
                  final description = selectedAction == 'add'
                      ? 'Admin added $points points'
                      : 'Admin removed $points points';

                  try {
                    // Update the employee's points for the current company
                    await appProvider.updateUserPoints(
                        employee.id, pointsChange, description,
                        companyId: adminCompanyId);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            '${selectedAction == 'add' ? 'Added' : 'Removed'} $points points for ${employee.name}'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error updating points: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }

  void _showChangeProfilePictureDialog(
      BuildContext context, AppProvider appProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Profile Picture'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                // Implement camera functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Camera functionality coming soon')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                // Implement gallery functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Gallery functionality coming soon')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Remove Photo'),
              onTap: () {
                Navigator.pop(context);
                // Implement remove photo functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Photo removed')),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showEditFieldDialog(BuildContext context, String fieldName,
      String currentValue, Function(String) onSave) {
    final controller = TextEditingController(text: currentValue);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit $fieldName'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: fieldName,
            border: const OutlineInputBorder(),
          ),
          keyboardType: fieldName == 'Email'
              ? TextInputType.emailAddress
              : fieldName == 'Phone Number'
                  ? TextInputType.phone
                  : TextInputType.text,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                onSave(controller.text);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$fieldName updated successfully')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(
      BuildContext context, AppProvider appProvider) {
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
              if (newPasswordController.text ==
                      confirmPasswordController.text &&
                  newPasswordController.text.isNotEmpty) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Password changed successfully')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Passwords do not match')),
                );
              }
            },
            child: const Text('Change Password'),
          ),
        ],
      ),
    );
  }

  void _showTwoFactorDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Two-Factor Authentication'),
        content: const Text(
            'Two-factor authentication is not yet implemented. This feature will be available in a future update.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.blue[600] : Colors.grey[600],
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.blue[600] : Colors.grey[600],
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<ActionButton> _getAdminActionButtons(
      BuildContext context, AppProvider appProvider) {
    return [
      ActionButton(
        icon: Icons.calendar_today,
        label: 'Calendar',
        color: Colors.blue,
        onTap: () => setState(() => _selectedIndex = 0),
      ),
      ActionButton(
        icon: Icons.card_giftcard,
        label: 'Import Bonuses',
        color: Colors.purple,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ImportBonusesScreen(appProvider: appProvider),
          ),
        ),
      ),
      ActionButton(
        icon: Icons.settings,
        label: 'Settings',
        color: Colors.orange,
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
        color: Colors.green,
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

  Widget _buildBonusesTab(AppProvider appProvider, List<Bonus> allBonuses) {
    final user = appProvider.currentUser!;
    final currentCompanyId = user.primaryCompanyId;

    // Filter available bonuses by current company
    final availableBonuses = allBonuses
        .where((b) =>
            b.status == BonusStatus.available &&
            b.companyId == currentCompanyId)
        .toList();

    // Redeemed bonuses can be global (from all companies)
    final redeemedByCurrentUser = appProvider.pointsTransactions
        .where((t) =>
            t.userId == user.id && t.type == PointsTransactionType.redeemed)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bonuses Management',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Admin Points Balance Card (Employee-style gradient)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
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
                      Consumer<AppProvider>(
                        builder: (context, provider, child) {
                          final currentPoints =
                              provider.getUserTotalPoints(user.id);
                          return Text(
                            '$currentPoints',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                // Claimable / total circle with overflow support (>100%)
                Builder(builder: (context) {
                  final totalAvailable = availableBonuses.length;
                  final currentPoints = appProvider.getUserTotalPoints(user.id);
                  final claimableCount = availableBonuses
                      .where((b) => currentPoints >= b.pointsRequired)
                      .length;
                  final cheapestRequired = availableBonuses.isEmpty
                      ? 0
                      : availableBonuses
                          .map((b) => b.pointsRequired)
                          .reduce((a, b) => a < b ? a : b);
                  final rawProgress = cheapestRequired == 0
                      ? 0.0
                      : currentPoints / cheapestRequired;
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
          const SizedBox(height: 16),

          // Toggle and summary
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.card_giftcard, color: Colors.purple[600]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _showAvailableBonuses
                              ? 'Available Bonuses'
                              : 'Redeemed Bonuses',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.purple[50],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ChoiceChip(
                              label: const Text('Available'),
                              selected: _showAvailableBonuses,
                              onSelected: (v) => setState(() {
                                _showAvailableBonuses = true;
                              }),
                            ),
                            const SizedBox(width: 8),
                            ChoiceChip(
                              label: const Text('Redeemed'),
                              selected: !_showAvailableBonuses,
                              onSelected: (v) => setState(() {
                                _showAvailableBonuses = false;
                              }),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_showAvailableBonuses)
                    Text(
                      'Available: ${availableBonuses.length}',
                      style: Theme.of(context).textTheme.titleLarge,
                    )
                  else
                    Text(
                      'Redeemed: ${redeemedByCurrentUser.length}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Bonuses List (toggle)
          if (_showAvailableBonuses && availableBonuses.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.card_giftcard,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No bonuses available',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Create bonuses for employees to redeem',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else if (_showAvailableBonuses)
            ...availableBonuses.map((bonus) => _buildAdminSimpleBonusCard(
                  context,
                  bonus,
                  appProvider.getUserTotalPoints(user.id),
                  user.id,
                  appProvider,
                )),
          if (!_showAvailableBonuses && redeemedByCurrentUser.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.card_giftcard, color: Colors.grey[400]),
                    const SizedBox(width: 12),
                    Text(
                      'No redeemed bonuses yet',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            )
          else if (!_showAvailableBonuses)
            ...redeemedByCurrentUser
                .map((t) => _buildAdminSimpleRedeemedCard(context, t))
                .toList(),
        ],
      ),
    );
  }

  Widget _buildSettingsTab(
      AppProvider appProvider,
      List<SalesTarget> allTargets,
      List<PointsTransaction> allTransactions,
      List<Bonus> allBonuses) {
    // Calculate admin team participation points
    final adminTeamParticipationPoints = allTransactions
        .where((t) => t.description.contains('Added as team member'))
        .fold<int>(0, (sum, t) => sum + t.points);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Settings & Analytics',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Settings Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.settings, color: Colors.blue[600]),
                      const SizedBox(width: 8),
                      Text(
                        'Settings',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSettingsItem(
                    Icons.business_center,
                    'Manage Companies',
                    'View and manage all companies',
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            CompaniesListScreen(appProvider: appProvider),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildSettingsItem(
                    Icons.people_outline,
                    'Manage Employees',
                    'View all employees in a new dedicated window',
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EmployeesListScreen(
                          appProvider: appProvider,
                          filterCompanyId: appProvider.currentUser
                              ?.primaryCompanyId, // Filter by admin's current company
                        ),
                      ),
                    ),
                  ),
                  _buildSettingsItem(
                    Icons.business,
                    'Manage Workplaces',
                    'View all workplaces in a dedicated window',
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            WorkplacesListScreen(appProvider: appProvider),
                      ),
                    ),
                  ),
                  _buildSettingsItem(
                    Icons.upload_file,
                    'Import Targets',
                    'Bulk import targets from Excel or CSV file',
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ImportTargetsScreen(),
                      ),
                    ),
                  ),
                  _buildSettingsItem(
                    Icons.view_list,
                    'Manage Targets',
                    'View and manage all targets in a dedicated window',
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            TargetListScreen(appProvider: appProvider),
                      ),
                    ),
                  ),
                  _buildSettingsItem(
                    Icons.rule,
                    'Points Rules',
                    'Configure how many points are awarded for different target achievements',
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              PointsRulesScreen(appProvider: appProvider),
                        ),
                      );
                    },
                  ),
                  _buildSettingsItemWithBadge(
                    Icons.approval,
                    'Pending Approvals',
                    'Review and approve sales submissions and team changes',
                    () => _showApprovalsManagement(appProvider),
                    appProvider.approvalRequests
                        .where((r) => r.status == ApprovalStatus.pending)
                        .length,
                  ),
                  _buildSettingsItem(
                    Icons.science,
                    'Load Demo Data',
                    'Load sample users, targets, and bonuses for testing',
                    () => _showLoadDemoDataDialog(context, appProvider),
                  ),
                  _buildDarkModeToggle(appProvider),
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
                  'Total Targets',
                  allTargets.length.toString(),
                  Icons.track_changes,
                  Colors.blue,
                  subtitle:
                      '${allTargets.where((t) => t.isMet).length} completed',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildAnalyticsCard(
                  'Total Transactions',
                  allTransactions.length.toString(),
                  Icons.swap_horiz,
                  Colors.green,
                  subtitle: 'Points activity',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildAnalyticsCard(
                  'Total Bonuses',
                  allBonuses.length.toString(),
                  Icons.card_giftcard,
                  Colors.purple,
                  subtitle: 'Available rewards',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildAnalyticsCard(
                  'Total Revenue',
                  '\$${allTargets.fold<double>(0, (sum, target) => sum + target.actualAmount).toStringAsFixed(0)}',
                  Icons.attach_money,
                  Colors.orange,
                  subtitle: 'Actual sales',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Admin Team Participation Card
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
                        'Admin Team Participation',
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
                          adminTeamParticipationPoints.toString(),
                          Icons.stars,
                          Colors.green,
                          subtitle: 'From team participation',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildAnalyticsCard(
                          'Team Count',
                          allTransactions
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
                        'Weekly Performance',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildWeeklyPerformanceChart(_getThisWeekTargets(allTargets)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Top Performers Section
          _buildTopPerformersWithToggle(
              allTargets, allTransactions, appProvider),
        ],
      ),
    );
  }

  Widget _buildProfileTab(AppProvider appProvider) {
    final user = appProvider.currentUser!;

    // Reuse the EmployeeProfileScreen for consistency
    return EmployeeProfileScreen(
      employee: user,
      appProvider: appProvider,
      showBackButton:
          false, // No back button when viewing own profile from tab bar
    );
  }

  Widget _buildProfileInfoCard(String title, List<Widget> fields) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            ...fields,
          ],
        ),
      ),
    );
  }

  Widget _buildProfileField(
      IconData icon, String label, String value, VoidCallback? onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
                      label,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                Icon(Icons.arrow_forward_ios,
                    size: 16, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDarkModeToggle(AppProvider appProvider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.dark_mode),
        title: const Text('Dark Mode'),
        subtitle: Text(appProvider.isDarkMode ? 'Enabled' : 'Disabled'),
        trailing: Switch(
          value: appProvider.isDarkMode,
          onChanged: (value) => appProvider.toggleDarkMode(),
          activeColor: Colors.blue[600],
        ),
      ),
    );
  }

  Widget _buildSettingsItem(
      IconData icon, String title, String subtitle, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  Widget _buildSettingsItemWithBadge(IconData icon, String title,
      String subtitle, VoidCallback onTap, int badgeCount) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Stack(
          children: [
            Icon(icon),
            if (badgeCount > 0)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    badgeCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  Widget _buildTargetCardWithApproval(
      SalesTarget target, AppProvider appProvider) {
    final pendingRequests = appProvider.approvalRequests
        .where((request) =>
            request.targetId == target.id &&
            request.status == ApprovalStatus.pending)
        .toList();

    // Calculate progress
    final progress = target.targetAmount > 0
        ? (target.actualAmount / target.targetAmount).clamp(0.0, 1.0)
        : 0.0;
    final actualPercentage = target.targetAmount > 0
        ? (target.actualAmount / target.targetAmount * 100).round()
        : 0;
    final isOverTarget = target.actualAmount > target.targetAmount;

    // Check if target is approved or met
    final isApproved = target.isApproved ||
        target.status == TargetStatus.approved ||
        target.status == TargetStatus.met;

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
            // Header Row
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: pendingRequests.isNotEmpty
                      ? Colors.orange
                      : target.isMet
                          ? Colors.green
                          : Colors.blue,
                  child: Icon(
                    pendingRequests.isNotEmpty
                        ? Icons.pending
                        : target.isMet
                            ? Icons.check
                            : Icons.track_changes,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (target.assignedWorkplaceName != null) ...[
                        Text(
                          'Store: ${target.assignedWorkplaceName}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(height: 4),
                      ],
                      Text(
                        'Target: \$${target.targetAmount.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Employee: ${target.assignedEmployeeName ?? 'Unassigned'}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      if (target.collaborativeEmployeeNames.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Team: ${target.collaborativeEmployeeNames.join(', ')}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Action Buttons
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (pendingRequests.isNotEmpty) ...[
                      IconButton(
                        icon:
                            const Icon(Icons.check_circle, color: Colors.green),
                        onPressed: () => _showQuickApproveDialog(
                            context, pendingRequests, appProvider),
                        tooltip: 'Quick Approve',
                      ),
                    ],
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () =>
                          _showEditTargetDialog(context, target, appProvider),
                      tooltip: 'Edit Target',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () =>
                          _showDeleteTargetDialog(context, target, appProvider),
                      tooltip: 'Delete Target',
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Progress Section
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sales vs Target Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Sales: \$${target.actualAmount.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'Target: \$${target.targetAmount.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isApproved
                            ? Colors.green
                            : isOverTarget
                                ? Colors.green
                                : actualPercentage >= 80
                                    ? Colors.orange
                                    : Colors.blue,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$actualPercentage%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Progress Bar
                _buildProgressBar(target, progress, target.isMet),

                const SizedBox(height: 8),

                // Status and Pending Approvals
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Date: ${DateFormat('MMM dd, yyyy').format(target.date)}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 4),

                // Pending Approvals Status
                if (pendingRequests.isNotEmpty || target.isMet) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (pendingRequests.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${pendingRequests.length} Pending',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ] else if (target.isMet) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'COMPLETED',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),

                  // Feedback Section (similar to employee dashboard)
                  if (isApproved) ...[
                    const SizedBox(height: 8),
                    Container(
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
                    ),
                  ] else if (target.status == TargetStatus.submitted) ...[
                    const SizedBox(height: 8),
                    Container(
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
                          Icon(Icons.upload, color: Colors.blue[700], size: 16),
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
                    ),
                  ],
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showTargetsManagement(AppProvider appProvider) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.95,
          height: MediaQuery.of(context).size.height * 0.9,
          padding: const EdgeInsets.all(16),
          child: Consumer<AppProvider>(
            builder: (context, provider, child) {
              return Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Manage Targets',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _buildTargetsManagementTab(provider),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _showAddEmployeeDialog(BuildContext context, AppProvider appProvider) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final passwordController = TextEditingController();

    // Auto-assign to admin's current active company
    final currentCompanyId = appProvider.currentUser?.primaryCompanyId;

    showDialog(
      context: context,
      builder: (context) => FutureBuilder<List<Company>>(
        future: appProvider.getCompanies(),
        builder: (context, snapshot) {
          final companies = snapshot.data ?? [];
          final currentCompany = companies.firstWhere(
            (c) => c.id == currentCompanyId,
            orElse: () => Company(
              id: '',
              name: 'Unknown Company',
              address: '',
              createdAt: DateTime.now(),
              adminUserId: '',
            ),
          );

          return AlertDialog(
            title: const Text('Add Employee'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Name'),
                  ),
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  TextField(
                    controller: phoneController,
                    decoration: const InputDecoration(labelText: 'Phone'),
                    keyboardType: TextInputType.phone,
                  ),
                  TextField(
                    controller: passwordController,
                    decoration: const InputDecoration(labelText: 'Password'),
                    obscureText: true,
                  ),
                  const SizedBox(height: 16),
                  // Show current company (non-editable)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.business,
                            color: Colors.blue.shade700, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Will be added to:',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                currentCompany.name,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
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
                  if (nameController.text.isNotEmpty &&
                      emailController.text.isNotEmpty &&
                      phoneController.text.isNotEmpty &&
                      passwordController.text.isNotEmpty &&
                      currentCompanyId != null) {
                    final user = User(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      name: nameController.text,
                      email: emailController.text,
                      phoneNumber: phoneController.text,
                      role: UserRole.employee,
                      createdAt: DateTime.now(),
                      totalPoints: 0,
                      companyIds: [currentCompanyId],
                      companyNames: [currentCompany.name],
                      primaryCompanyId: currentCompanyId,
                    );
                    await appProvider.addUser(user);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            'Employee added successfully to ${currentCompany.name}'),
                      ),
                    );
                  }
                },
                child: const Text('Add'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddWorkplaceDialog(BuildContext context, AppProvider appProvider) {
    final nameController = TextEditingController();
    final locationController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Workplace'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: locationController,
              decoration: const InputDecoration(labelText: 'Location'),
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
              if (nameController.text.isNotEmpty &&
                  locationController.text.isNotEmpty) {
                final workplace = Workplace(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: nameController.text,
                  address: locationController.text,
                  createdAt: DateTime.now(),
                );
                await appProvider.addWorkplace(workplace);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Workplace added successfully')),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showAddTargetDialog(BuildContext context, AppProvider appProvider) {
    final targetController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    Workplace? selectedWorkplace;
    User? selectedEmployee;
    List<User> employees = [];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          // Load employees when dialog opens
          if (employees.isEmpty) {
            appProvider.getUsers().then((users) {
              setState(() {
                employees = users
                    .where((user) =>
                        user.role == UserRole.employee ||
                        user.role == UserRole.admin)
                    .toList();
              });
            });
          }

          return AlertDialog(
            title: const Text('Add Target'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: targetController,
                    decoration:
                        const InputDecoration(labelText: 'Target Amount'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<Workplace>(
                    value: selectedWorkplace,
                    decoration: const InputDecoration(labelText: 'Workplace'),
                    items: appProvider.workplaces.map((workplace) {
                      return DropdownMenuItem(
                        value: workplace,
                        child: Text(workplace.name),
                      );
                    }).toList(),
                    onChanged: (workplace) =>
                        setState(() => selectedWorkplace = workplace),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<User>(
                    value: selectedEmployee,
                    decoration: const InputDecoration(labelText: 'Employee'),
                    items: employees.map((user) {
                      return DropdownMenuItem(
                        value: user,
                        child: Text(user.name),
                      );
                    }).toList(),
                    onChanged: (user) =>
                        setState(() => selectedEmployee = user),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    title: Text(
                        'Date: ${DateFormat('yyyy-MM-dd').format(selectedDate)}'),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        setState(() => selectedDate = date);
                      }
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
                  if (targetController.text.isNotEmpty &&
                      selectedWorkplace != null &&
                      selectedEmployee != null) {
                    final target = SalesTarget(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      date: selectedDate,
                      targetAmount: double.parse(targetController.text),
                      actualAmount: 0,
                      createdAt: DateTime.now(),
                      createdBy: appProvider.currentUser!.id,
                      assignedEmployeeId: selectedEmployee!.id,
                      assignedEmployeeName: selectedEmployee!.name,
                      assignedWorkplaceId: selectedWorkplace!.id,
                      assignedWorkplaceName: selectedWorkplace!.name,
                      collaborativeEmployeeIds: [],
                      collaborativeEmployeeNames: [],
                    );
                    await appProvider.addSalesTarget(target);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Target added successfully')),
                    );
                  }
                },
                child: const Text('Add'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTargetsManagementTab(AppProvider appProvider) {
    return FutureBuilder<List<SalesTarget>>(
      future: Future.value(appProvider.salesTargets),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No targets found'));
        }

        final targets = snapshot.data!;
        return Column(
          children: [
            // Header with Add Target button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'All Targets (${targets.length})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showAddTargetDialog(context, appProvider),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Target'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Targets List
            Expanded(
              child: ListView.builder(
                itemCount: targets.length,
                itemBuilder: (context, index) {
                  final target = targets[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _getTargetStatusColor(target),
                        child: Icon(
                          _getTargetStatusIcon(target),
                          color: Colors.white,
                        ),
                      ),
                      title: Text(
                        'Target: \$${target.targetAmount.toStringAsFixed(0)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              'Employee: ${target.assignedEmployeeName ?? 'Unassigned'}'),
                          Text(
                              'Workplace: ${target.assignedWorkplaceName ?? 'Unassigned'}'),
                          if (target.collaborativeEmployeeNames.isNotEmpty)
                            Text(
                                'Team: ${target.collaborativeEmployeeNames.join(', ')}'),
                          Text(
                              'Date: ${DateFormat('MMM dd, yyyy').format(target.date)}'),
                          Text('Status: ${_getTargetStatusText(target)}'),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Only show "Mark as Missed" button for pending targets that are not met
                          if (target.status == TargetStatus.pending &&
                              !target.isMet)
                            IconButton(
                              icon: const Icon(Icons.cancel,
                                  color: Colors.orange),
                              onPressed: () => _showMarkAsMissedDialog(
                                  context, target, appProvider),
                              tooltip: 'Mark as Missed',
                            ),
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _showEditTargetDialog(
                                context, target, appProvider),
                            tooltip: 'Edit Target',
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _showDeleteTargetDialog(
                                context, target, appProvider),
                            tooltip: 'Delete Target',
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  void _showEditTargetDialog(
      BuildContext context, SalesTarget target, AppProvider appProvider) {
    final targetAmountController =
        TextEditingController(text: target.targetAmount.toString());
    final actualAmountController =
        TextEditingController(text: target.actualAmount.toString());
    String? selectedEmployeeId = target.assignedEmployeeId;
    String? selectedWorkplaceId = target.assignedWorkplaceId;
    List<String> selectedTeamMemberIds =
        List.from(target.collaborativeEmployeeIds);
    DateTime selectedDate = target.date;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Target'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Target Amount
                TextField(
                  controller: targetAmountController,
                  decoration: const InputDecoration(
                    labelText: 'Target Amount (\$)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),

                // Actual Amount
                TextField(
                  controller: actualAmountController,
                  decoration: const InputDecoration(
                    labelText: 'Actual Amount (\$)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),

                // Date Picker
                ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: const Text('Target Date'),
                  subtitle:
                      Text(DateFormat('MMM dd, yyyy').format(selectedDate)),
                  trailing: const Icon(Icons.arrow_drop_down),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (date != null) {
                      setState(() {
                        selectedDate = date;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Employee Selection
                FutureBuilder<List<User>>(
                  future: appProvider.getUsers(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      final employees = snapshot.data!
                          .where((u) =>
                              u.role == UserRole.employee ||
                              u.role == UserRole.admin)
                          .toList();
                      return DropdownButtonFormField<String?>(
                        value: selectedEmployeeId,
                        decoration: const InputDecoration(
                          labelText: 'Assigned Employee',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('No Employee Assigned'),
                          ),
                          ...employees
                              .map((employee) => DropdownMenuItem<String?>(
                                    value: employee.id,
                                    child: Text(employee.name),
                                  )),
                        ],
                        onChanged: (value) {
                          setState(() {
                            selectedEmployeeId = value;
                            print(
                                'DEBUG: Employee dropdown changed to: $value');
                            // If no employee assigned, clear team members
                            if (value == null) {
                              selectedTeamMemberIds.clear();
                              print(
                                  'DEBUG: Cleared team members - no employee assigned');
                            }
                          });
                        },
                      );
                    }
                    return const CircularProgressIndicator();
                  },
                ),
                const SizedBox(height: 16),

                // Workplace Selection
                FutureBuilder<List<Workplace>>(
                  future: appProvider.getWorkplaces(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      final workplaces = snapshot.data!;
                      return DropdownButtonFormField<String?>(
                        value: selectedWorkplaceId,
                        decoration: const InputDecoration(
                          labelText: 'Assigned Workplace',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('No Workplace Assigned'),
                          ),
                          ...workplaces
                              .map((workplace) => DropdownMenuItem<String?>(
                                    value: workplace.id,
                                    child: Text(workplace.name),
                                  )),
                        ],
                        onChanged: (value) {
                          setState(() {
                            selectedWorkplaceId = value;
                          });
                        },
                      );
                    }
                    return const CircularProgressIndicator();
                  },
                ),
                const SizedBox(height: 16),

                // Team Members Selection
                FutureBuilder<List<User>>(
                  future: appProvider.getUsers(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      final employees = snapshot.data!
                          .where((u) =>
                              u.role == UserRole.employee ||
                              u.role == UserRole.admin)
                          .toList();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Team Members (Optional)',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: employees.map((employee) {
                              final isSelected =
                                  selectedTeamMemberIds.contains(employee.id);
                              return FilterChip(
                                label: Text(employee.name),
                                selected: isSelected,
                                selectedColor: Colors.blue.shade100,
                                checkmarkColor: Colors.blue.shade700,
                                backgroundColor: Colors.grey.shade200,
                                onSelected: (selected) {
                                  setState(() {
                                    if (selected) {
                                      if (!selectedTeamMemberIds
                                          .contains(employee.id)) {
                                        selectedTeamMemberIds.add(employee.id);
                                      }
                                    } else {
                                      selectedTeamMemberIds.remove(employee.id);
                                    }
                                    print(
                                        'DEBUG: Team members selected: $selectedTeamMemberIds');
                                  });
                                },
                              );
                            }).toList(),
                          ),
                        ],
                      );
                    }
                    return const CircularProgressIndicator();
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
            TextButton(
              onPressed: () async {
                final targetAmount =
                    double.tryParse(targetAmountController.text);
                final actualAmount =
                    double.tryParse(actualAmountController.text);

                if (targetAmount == null || targetAmount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Please enter a valid target amount')),
                  );
                  return;
                }

                if (actualAmount == null || actualAmount < 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Please enter a valid actual amount')),
                  );
                  return;
                }

                // Get employee and workplace names
                final users = await appProvider.getUsers();
                final workplaces = await appProvider.getWorkplaces();

                final assignedEmployee = users.firstWhere(
                  (u) => u.id == selectedEmployeeId,
                  orElse: () => User(
                    id: '',
                    name: '',
                    email: '',
                    role: UserRole.employee,
                    createdAt: DateTime.now(),
                  ),
                );

                final assignedWorkplace = workplaces.firstWhere(
                  (w) => w.id == selectedWorkplaceId,
                  orElse: () => Workplace(
                      id: '', name: '', address: '', createdAt: DateTime.now()),
                );

                final teamMembers = users
                    .where((u) => selectedTeamMemberIds.contains(u.id))
                    .toList();

                // Remove duplicates from team member IDs
                final uniqueTeamMemberIds =
                    selectedTeamMemberIds.toSet().toList();
                final uniqueTeamMembers = users
                    .where((u) => uniqueTeamMemberIds.contains(u.id))
                    .toList();

                print(
                    'DEBUG: Updating target - employeeId: $selectedEmployeeId, workplaceId: $selectedWorkplaceId');
                print(
                    'DEBUG: Updating target - team member IDs: $uniqueTeamMemberIds');

                // Create updated target with recalculated status
                final baseUpdatedTarget = target.copyWith(
                  targetAmount: targetAmount,
                  actualAmount: actualAmount,
                  date: selectedDate,
                  assignedEmployeeId: selectedEmployeeId,
                  assignedEmployeeName:
                      selectedEmployeeId != null ? assignedEmployee.name : null,
                  assignedWorkplaceId: selectedWorkplaceId,
                  assignedWorkplaceName: selectedWorkplaceId != null
                      ? assignedWorkplace.name
                      : null,
                  collaborativeEmployeeIds: uniqueTeamMemberIds,
                  collaborativeEmployeeNames:
                      uniqueTeamMembers.map((u) => u.name).toList(),
                );

                // Smart status calculation logic
                final actualAmountChanged = actualAmount != target.actualAmount;
                final targetAmountChanged = targetAmount != target.targetAmount;

                SalesTarget updatedTarget;
                if (actualAmountChanged && actualAmount > 0) {
                  // Only recalculate status when actual sales amount changes AND there's actual activity
                  updatedTarget = baseUpdatedTarget.calculateResults();
                } else if (actualAmountChanged && actualAmount == 0) {
                  // If sales are reset to 0, set back to pending (target not started)
                  updatedTarget = baseUpdatedTarget.copyWith(
                    status: TargetStatus.pending,
                    isMet: false,
                    pointsAwarded: 0,
                  );
                } else {
                  // Keep existing status if actual amount didn't change or other details changed
                  // This prevents marking targets as "missed" just for changing target amount or other details
                  updatedTarget = baseUpdatedTarget;
                }

                // If the target is met and has points, recalculate points using the rules
                if (updatedTarget.isMet && updatedTarget.actualAmount > 0) {
                  final effectivePercent = (updatedTarget.actualAmount /
                          updatedTarget.targetAmount) *
                      100;
                  final calculatedPoints = appProvider
                      .getPointsForEffectivePercent(effectivePercent);

                  // When admin directly sets a met target, mark it as approved
                  final finalUpdatedTarget = updatedTarget.copyWith(
                    pointsAwarded: calculatedPoints,
                    status: TargetStatus.approved,
                    isApproved: true,
                    approvedBy: appProvider.currentUser?.id,
                    approvedAt: DateTime.now(),
                  );
                  await appProvider.updateSalesTarget(finalUpdatedTarget);
                } else {
                  // Update the target
                  await appProvider.updateSalesTarget(updatedTarget);
                }

                // Verify the target was updated correctly
                final verifyTarget = appProvider.salesTargets
                    .firstWhere((t) => t.id == target.id);
                print(
                    'DEBUG: After update - target employeeId: ${verifyTarget.assignedEmployeeId}, employeeName: ${verifyTarget.assignedEmployeeName}');

                if (context.mounted) {
                  Navigator.pop(context);
                }

                // Force UI refresh
                if (mounted) {
                  setState(() {});
                }

                // Check for team member changes
                final originalTeamMembers =
                    target.collaborativeEmployeeIds.toSet();
                final updatedTeamMembers =
                    verifyTarget.collaborativeEmployeeIds.toSet();
                final teamMembersRemoved =
                    originalTeamMembers.difference(updatedTeamMembers);
                final teamMembersAdded =
                    updatedTeamMembers.difference(originalTeamMembers);
                final teamMembersChanged = teamMembersRemoved.isNotEmpty ||
                    teamMembersAdded.isNotEmpty;

                // Show appropriate feedback based on status change
                String message;
                Color backgroundColor = Colors.green;

                if (teamMembersChanged) {
                  if (teamMembersRemoved.isNotEmpty &&
                      teamMembersAdded.isNotEmpty) {
                    message =
                        'Team members updated - points adjusted automatically';
                  } else if (teamMembersRemoved.isNotEmpty) {
                    message =
                        'Team member(s) removed - points withdrawn automatically';
                  } else {
                    message =
                        'Team member(s) added - points awarded automatically';
                  }
                  backgroundColor = Colors.orange;
                } else if (!actualAmountChanged && !targetAmountChanged) {
                  message = 'Target details updated (no status change)';
                  backgroundColor = Colors.blue;
                } else if (targetAmountChanged && !actualAmountChanged) {
                  message = 'Target amount updated (status preserved)';
                  backgroundColor = Colors.blue;
                } else if (actualAmountChanged && actualAmount == 0) {
                  message = 'Sales reset - target back to pending';
                  backgroundColor = Colors.blue;
                } else if (actualAmountChanged &&
                    updatedTarget.status == TargetStatus.missed) {
                  message = 'Sales updated and marked as missed (below target)';
                  backgroundColor = Colors.orange;
                } else if (actualAmountChanged &&
                    updatedTarget.status == TargetStatus.met) {
                  message = 'Sales updated and marked as completed';
                  backgroundColor = Colors.green;
                } else if (updatedTarget.status == TargetStatus.approved) {
                  message = 'Target updated and approved';
                  backgroundColor = Colors.green;
                } else {
                  message = 'Target updated successfully';
                  backgroundColor = Colors.green;
                }

                // Add points adjustment information
                final pointsDifference =
                    updatedTarget.pointsAwarded - target.pointsAwarded;
                if (pointsDifference != 0) {
                  if (pointsDifference > 0) {
                    message +=
                        '\n+${pointsDifference} points awarded to employees';
                  } else {
                    message +=
                        '\n${pointsDifference.abs()} points withdrawn from employees';
                    backgroundColor = Colors.orange;
                  }
                }

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(message),
                    backgroundColor: backgroundColor,
                    duration: const Duration(seconds: 4),
                  ),
                );
              },
              child: const Text('Update'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _showDeleteTargetDialog(context, target, appProvider);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete Target'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteTargetDialog(
      BuildContext context, SalesTarget target, AppProvider appProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Target'),
        content: Text(
            'Are you sure you want to delete this target for \$${target.targetAmount.toStringAsFixed(0)}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await appProvider.deleteSalesTarget(target.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Target deleted successfully')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildAutoProcessedTargetsCard(AppProvider appProvider) {
    return Card(
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_fix_high, color: Colors.orange.shade700),
                const SizedBox(width: 8),
                Text(
                  'Auto-Processed Targets',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade700,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => appProvider.clearAutoProcessedTargets(),
                  tooltip: 'Dismiss',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'The following targets were automatically marked as missed (below target, no points awarded):',
              style: TextStyle(color: Colors.orange.shade600),
            ),
            const SizedBox(height: 8),
            ...appProvider.autoProcessedTargets.map((message) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Icon(Icons.cancel, size: 16, color: Colors.red.shade600),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          message,
                          style: TextStyle(color: Colors.orange.shade700),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  String _getTargetStatusText(SalesTarget target) {
    switch (target.status) {
      case TargetStatus.met:
        return 'Completed';
      case TargetStatus.missed:
        return 'Missed';
      case TargetStatus.pending:
        return target.isMet ? 'Completed' : 'Pending';
      case TargetStatus.submitted:
        return 'Submitted';
      case TargetStatus.approved:
        return target.isMet ? 'Completed' : 'Missed';
      default:
        return 'Pending';
    }
  }

  Color _getTargetStatusColor(SalesTarget target) {
    switch (target.status) {
      case TargetStatus.met:
        return Colors.green;
      case TargetStatus.missed:
        return Colors.red;
      case TargetStatus.pending:
        return target.isMet ? Colors.green : Colors.orange;
      case TargetStatus.submitted:
        return Colors.blue;
      case TargetStatus.approved:
        return target.isMet ? Colors.green : Colors.red;
      default:
        return Colors.orange;
    }
  }

  IconData _getTargetStatusIcon(SalesTarget target) {
    switch (target.status) {
      case TargetStatus.met:
        return Icons.check;
      case TargetStatus.missed:
        return Icons.cancel;
      case TargetStatus.pending:
        return target.isMet ? Icons.check : Icons.track_changes;
      case TargetStatus.submitted:
        return Icons.send;
      case TargetStatus.approved:
        return target.isMet ? Icons.check : Icons.cancel;
      default:
        return Icons.track_changes;
    }
  }

  void _showMarkAsMissedDialog(
      BuildContext context, SalesTarget target, AppProvider appProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark Target as Missed'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to mark this target as missed?'),
            const SizedBox(height: 8),
            Text('Target: \$${target.targetAmount.toStringAsFixed(0)}'),
            Text('Employee: ${target.assignedEmployeeName ?? 'Unassigned'}'),
            const SizedBox(height: 8),
            const Text('This will:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const Text('• Mark the target as missed'),
            const Text('• Award no points to the employee'),
            const Text('• Close the target permanently'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await appProvider.markTargetAsMissed(
                  target.id, appProvider.currentUser!.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Target marked as missed'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Mark as Missed'),
          ),
        ],
      ),
    );
  }

  void _showApprovalsManagement(AppProvider appProvider) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.95,
          height: MediaQuery.of(context).size.height * 0.9,
          padding: const EdgeInsets.all(16),
          child: Consumer<AppProvider>(
            builder: (context, provider, child) {
              return Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Pending Approvals',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _buildApprovalsManagementTab(provider),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget? _getFloatingActionButton(BuildContext context,
      AppProvider appProvider, List<SalesTarget> selectedDateTargets) {
    // No floating action button needed
    return null;
  }

  Widget _buildApprovalsManagementTab(AppProvider appProvider) {
    final pendingRequests = appProvider.approvalRequests
        .where((request) => request.status == ApprovalStatus.pending)
        .toList();

    if (pendingRequests.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 64, color: Colors.green),
            SizedBox(height: 16),
            Text(
              'No Pending Approvals',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'All requests have been reviewed',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: pendingRequests.length,
      itemBuilder: (context, index) {
        final request = pendingRequests[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      request.type == ApprovalRequestType.salesSubmission
                          ? Icons.attach_money
                          : Icons.group,
                      color: request.type == ApprovalRequestType.salesSubmission
                          ? Colors.green
                          : Colors.blue,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        request.type == ApprovalRequestType.salesSubmission
                            ? 'Sales Submission'
                            : 'Team Change Request',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'PENDING',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Submitted by: ${request.submittedByName}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  'Date: ${DateFormat('MMM dd, yyyy - HH:mm').format(request.submittedAt)}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 12),
                if (request.type == ApprovalRequestType.salesSubmission) ...[
                  _buildSalesSubmissionDetails(request),
                ] else ...[
                  _buildTeamChangeDetails(request),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            _showRejectDialog(context, request, appProvider),
                        icon: const Icon(Icons.close, color: Colors.white),
                        label: const Text('Reject'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            _approveRequest(context, request, appProvider),
                        icon: const Icon(Icons.check, color: Colors.white),
                        label: const Text('Approve'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSalesSubmissionDetails(ApprovalRequest request) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sales Details:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
            'Previous Amount: \$${request.previousActualAmount?.toStringAsFixed(2) ?? '0.00'}'),
        Text(
            'New Amount: \$${request.newActualAmount?.toStringAsFixed(2) ?? '0.00'}'),
        Text(
            'Difference: \$${(request.newActualAmount! - (request.previousActualAmount ?? 0)).toStringAsFixed(2)}'),
      ],
    );
  }

  Widget _buildTeamChangeDetails(ApprovalRequest request) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Team Changes:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        if (request.previousTeamMemberNames?.isNotEmpty == true) ...[
          Text('Previous Team: ${request.previousTeamMemberNames!.join(', ')}'),
        ] else ...[
          const Text('Previous Team: No team members'),
        ],
        if (request.newTeamMemberNames?.isNotEmpty == true) ...[
          Text('New Team: ${request.newTeamMemberNames!.join(', ')}'),
        ] else ...[
          const Text('New Team: No team members'),
        ],
      ],
    );
  }

  void _approveRequest(
      BuildContext context, ApprovalRequest request, AppProvider appProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Request'),
        content: Text(
            'Are you sure you want to approve this ${request.type == ApprovalRequestType.salesSubmission ? 'sales submission' : 'team change'}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await appProvider.approveRequest(request);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Request approved successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(
      BuildContext context, ApprovalRequest request, AppProvider appProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Request'),
        content: Text(
            'Are you sure you want to reject this ${request.type == ApprovalRequestType.salesSubmission ? 'sales submission' : 'team change'}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await appProvider.rejectRequest(request, '');
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Request rejected'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  void _showQuickApproveDialog(BuildContext context,
      List<ApprovalRequest> requests, AppProvider appProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quick Approve'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'You have ${requests.length} pending approval${requests.length > 1 ? 's' : ''} for this target:'),
            const SizedBox(height: 16),
            ...requests.map((request) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              request.type ==
                                      ApprovalRequestType.salesSubmission
                                  ? Icons.attach_money
                                  : Icons.group,
                              color: request.type ==
                                      ApprovalRequestType.salesSubmission
                                  ? Colors.green
                                  : Colors.blue,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                request.type ==
                                        ApprovalRequestType.salesSubmission
                                    ? 'Sales Submission'
                                    : 'Team Change',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('Submitted by: ${request.submittedByName}'),
                        Text(
                            'Date: ${DateFormat('MMM dd, HH:mm').format(request.submittedAt)}'),
                        if (request.type ==
                            ApprovalRequestType.salesSubmission) ...[
                          const SizedBox(height: 4),
                          Text(
                              'Amount: \$${request.newActualAmount?.toStringAsFixed(2) ?? '0.00'}'),
                        ] else ...[
                          const SizedBox(height: 4),
                          if (request.newTeamMemberNames?.isNotEmpty == true)
                            Text(
                                'New Team: ${request.newTeamMemberNames!.join(', ')}')
                          else
                            const Text('New Team: No team members'),
                        ],
                      ],
                    ),
                  ),
                )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Approve all requests
              for (final request in requests) {
                await appProvider.approveRequest(request);
              }
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      '${requests.length} request${requests.length > 1 ? 's' : ''} approved successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Approve All'),
          ),
        ],
      ),
    );
  }

  void _showFixPointsDialog(
      BuildContext context, SalesTarget target, AppProvider appProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Award Points Retroactively'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This will award points to all team members for this already-approved target.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Text('Target: \$${target.targetAmount.toStringAsFixed(0)}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('Points: ${target.pointsAwarded}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Team Members (${target.collaborativeEmployeeIds.length}):'),
            ...target.collaborativeEmployeeNames
                .map((name) => Text('  • $name'))
                .toList(),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This should only be used if points were not awarded initially.',
                      style: TextStyle(fontSize: 12, color: Colors.orange),
                    ),
                  ),
                ],
              ),
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
              await appProvider.retroactivelyAwardPointsForTarget(target.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Points awarded successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Award Points'),
          ),
        ],
      ),
    );
  }

  void _showTargetPointsAdjustmentDialog(
      BuildContext context, SalesTarget target, AppProvider appProvider) {
    final targetController =
        TextEditingController(text: target.targetAmount.toStringAsFixed(0));

    // Calculate what the current effective percent is
    final currentEffectivePercent = target.targetAmount > 0
        ? (target.actualAmount / target.targetAmount) * 100.0
        : 0.0;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          // Calculate preview of new points based on current input
          final newTargetText = targetController.text.trim();
          final newTarget =
              double.tryParse(newTargetText) ?? target.targetAmount;
          final newEffectivePercent =
              newTarget > 0 ? (target.actualAmount / newTarget) * 100.0 : 0.0;
          final newPoints = newEffectivePercent >= 100.0
              ? appProvider.getPointsForEffectivePercent(
                  newEffectivePercent, target.companyId)
              : 0;
          final pointsDiff = newPoints - target.pointsAwarded;

          return AlertDialog(
            title: const Text('Adjust Target & Recalculate Points'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'If the target was set incorrectly, enter the correct target amount. Points will be automatically recalculated based on actual sales vs. the new target.',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  Text(
                      'Actual Sales: \$${target.actualAmount.toStringAsFixed(0)}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.green)),
                  const Divider(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Current:',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey)),
                            Text(
                                'Target: \$${target.targetAmount.toStringAsFixed(0)}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            Text(
                                '${currentEffectivePercent.toStringAsFixed(1)}% achieved',
                                style: const TextStyle(fontSize: 12)),
                            Text('${target.pointsAwarded} points',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue)),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward, color: Colors.grey),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('New:',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey)),
                            Text('Target: \$${newTarget.toStringAsFixed(0)}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            Text(
                                '${newEffectivePercent.toStringAsFixed(1)}% achieved',
                                style: const TextStyle(fontSize: 12)),
                            Text('$newPoints points',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: pointsDiff > 0
                                        ? Colors.green
                                        : pointsDiff < 0
                                            ? Colors.red
                                            : Colors.blue)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: targetController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Corrected Target Amount (\$)',
                      border: OutlineInputBorder(),
                      hintText: 'Enter correct target',
                    ),
                    onChanged: (_) =>
                        setState(() {}), // Rebuild to update preview
                  ),
                  const SizedBox(height: 8),
                  Text(
                      'Team Members (${target.collaborativeEmployeeIds.length}):',
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.bold)),
                  ...target.collaborativeEmployeeNames
                      .map((name) => Text('  • $name',
                          style: const TextStyle(fontSize: 12)))
                      .toList(),
                  if (pointsDiff != 0) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: (pointsDiff > 0 ? Colors.green : Colors.orange)
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color:
                                pointsDiff > 0 ? Colors.green : Colors.orange),
                      ),
                      child: Row(
                        children: [
                          Icon(
                              pointsDiff > 0
                                  ? Icons.add_circle
                                  : Icons.remove_circle,
                              color:
                                  pointsDiff > 0 ? Colors.green : Colors.orange,
                              size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              pointsDiff > 0
                                  ? 'Each team member will receive +$pointsDiff points'
                                  : 'Each team member will lose ${pointsDiff.abs()} points',
                              style: TextStyle(
                                fontSize: 12,
                                color: pointsDiff > 0
                                    ? Colors.green
                                    : Colors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
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
                  final newTargetText = targetController.text.trim();
                  if (newTargetText.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter a valid target amount'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  final newTarget = double.tryParse(newTargetText);
                  if (newTarget == null || newTarget <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter a valid positive number'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  await appProvider.recalculateAndAdjustPoints(
                      target.id, newTarget);
                  Navigator.pop(context);

                  final pointsDiff = newPoints - target.pointsAwarded;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(pointsDiff == 0
                          ? 'Target updated to \$${newTarget.toStringAsFixed(0)}'
                          : 'Target corrected! Points adjusted: ${pointsDiff > 0 ? '+' : ''}$pointsDiff per team member'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                child: const Text('Recalculate & Adjust'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProgressBar(SalesTarget target, double progress, bool isMet) {
    final percentageAbove = target.percentageAboveTarget;
    final isApproved =
        target.isApproved || target.status == TargetStatus.approved;
    final hasBonus =
        percentageAbove > 0.0; // Any amount above target shows purple

    // If target is approved and met, show green bar with purple bonus section
    if (isApproved && isMet) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final barWidth = constraints.maxWidth;
          // Purple section width is proportional to how much target is exceeded
          // Cap it at 50% of bar width to prevent it from being too large
          final bonusWidth = barWidth * (percentageAbove / 100).clamp(0.0, 0.5);

          return Stack(
            children: [
              // Base green progress bar
              LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                backgroundColor: Colors.grey[300],
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                minHeight: 8,
              ),
              // Purple bonus section proportional to target exceedance
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
        isApproved
            ? Colors.green
            : isMet
                ? Colors.green
                : progress >= 0.8
                    ? Colors.orange
                    : Colors.blue,
      ),
      minHeight: 8,
    );
  }
}

class EmployeeProfileScreen extends StatefulWidget {
  final User employee;
  final AppProvider appProvider;
  final bool showBackButton; // Whether to show back button in AppBar
  final String?
      companyContext; // Optional: which company context to show points for
  final bool readOnly; // If true, hide all edit functionality

  const EmployeeProfileScreen({
    Key? key,
    required this.employee,
    required this.appProvider,
    this.showBackButton = true, // Default to true for backwards compatibility
    this.companyContext, // Optional company context
    this.readOnly = false, // Default to false (editable)
  }) : super(key: key);

  @override
  State<EmployeeProfileScreen> createState() => _EmployeeProfileScreenState();
}

class _EmployeeProfileScreenState extends State<EmployeeProfileScreen> {
  late User currentEmployee;

  @override
  void initState() {
    super.initState();
    currentEmployee = widget.employee;
  }

  // Check if current user is admin in the company context
  bool _isAdminInContext() {
    final currentUser = widget.appProvider.currentUser;
    if (currentUser == null) return false;

    // Get the company context - use provided context or current user's primary company
    final contextCompanyId =
        widget.companyContext ?? currentUser.primaryCompanyId;
    if (contextCompanyId == null) return false;

    // Check if current user has admin role in this company
    final role = currentUser.getRoleForCompany(contextCompanyId);
    return role == UserRole.admin;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          '${currentEmployee.name} Profile',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue[700],
        elevation: 0,
        leading: widget.showBackButton
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              )
            : null, // No back button when viewing own profile from tab bar
        automaticallyImplyLeading:
            widget.showBackButton, // Prevent default back button
        actions: widget.readOnly ? [] : [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: () {
              // TODO: Implement edit functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Edit functionality coming soon')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.blue[700]!, Colors.blue[600]!],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.white,
                      child: Text(
                        currentEmployee.name[0].toUpperCase(),
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      currentEmployee.name,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      currentEmployee.email,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.stars,
                              color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          Consumer<AppProvider>(
                            builder: (context, provider, child) {
                              // Get company-specific points based on company context or admin's current company
                              final companyId = widget.companyContext ??
                                  provider.currentUser?.primaryCompanyId;
                              final currentPoints = companyId != null
                                  ? provider.getUserCompanyPoints(
                                      currentEmployee.id, companyId)
                                  : 0;
                              return Text(
                                '$currentPoints points',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Profile Content
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  _buildProfileSection(
                    'Personal Information',
                    Icons.person,
                    [
                      _buildProfileField(
                        Icons.person,
                        'Full Name',
                        currentEmployee.name,
                        widget.readOnly
                            ? null
                            : () => _showEditFieldDialog(
                                    'Name', currentEmployee.name,
                                    (newValue) async {
                                  try {
                                    final updatedEmployee = currentEmployee
                                        .copyWith(name: newValue);
                                    await widget.appProvider
                                        .updateUser(updatedEmployee);
                                    setState(() {
                                      currentEmployee = updatedEmployee;
                                    });
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content:
                                            Text('Error updating name: $e'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }),
                      ),
                      _buildProfileField(
                        Icons.email,
                        'Email Address',
                        currentEmployee.email,
                        widget.readOnly
                            ? null
                            : () => _showEditFieldDialog(
                                    'Email', currentEmployee.email,
                                    (newValue) async {
                                  try {
                                    final updatedEmployee = currentEmployee
                                        .copyWith(email: newValue);
                                    await widget.appProvider
                                        .updateUser(updatedEmployee);
                                    setState(() {
                                      currentEmployee = updatedEmployee;
                                    });
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content:
                                            Text('Error updating email: $e'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }),
                      ),
                      _buildProfileField(
                        Icons.phone,
                        'Phone Number',
                        currentEmployee.phoneNumber ?? 'Not set',
                        widget.readOnly
                            ? null
                            : () => _showEditFieldDialog('Phone Number',
                                    currentEmployee.phoneNumber ?? '',
                                    (newValue) async {
                                  try {
                                    final updatedEmployee = currentEmployee
                                        .copyWith(phoneNumber: newValue);
                                    await widget.appProvider
                                        .updateUser(updatedEmployee);
                                    setState(() {
                                      currentEmployee = updatedEmployee;
                                    });
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content:
                                            Text('Error updating phone: $e'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }),
                      ),
                      // Add message button if not viewing own profile
                      if (widget.appProvider.currentUser?.id !=
                          currentEmployee.id)
                        _buildMessageButton(),
                      // Add gift points button if not viewing own profile
                      if (widget.appProvider.currentUser?.id !=
                          currentEmployee.id)
                        _buildGiftPointsButton(),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildProfileSection(
                    'Performance & Statistics',
                    Icons.analytics,
                    [
                      Consumer<AppProvider>(
                        builder: (context, provider, child) {
                          // Get company-specific points based on company context or admin's current company
                          final companyId = widget.companyContext ??
                              provider.currentUser?.primaryCompanyId;
                          final currentPoints = companyId != null
                              ? provider.getUserCompanyPoints(
                                  currentEmployee.id, companyId)
                              : 0;
                          return _buildProfileField(
                            Icons.stars,
                            'Points',
                            '$currentPoints points',
                            null,
                          );
                        },
                      ),
                      Consumer<AppProvider>(
                        builder: (context, provider, child) {
                          // Get company-specific role
                          final companyId = widget.companyContext ??
                              provider.currentUser?.primaryCompanyId;
                          final currentRole = companyId != null
                              ? currentEmployee.getRoleForCompany(companyId)
                              : currentEmployee.role;
                          // Check if viewing own profile
                          final isOwnProfile =
                              provider.currentUser?.id == currentEmployee.id;
                          return _buildRoleDropdownField(
                            Icons.work,
                            'Role',
                            currentRole,
                            companyId, // Pass company ID for context
                            isOwnProfile, // Pass flag to disable editing own role
                          );
                        },
                      ),
                      Consumer<AppProvider>(
                        builder: (context, provider, child) {
                          return _buildCompanyDropdownField(
                            Icons.business,
                            'Company',
                            currentEmployee,
                            provider,
                          );
                        },
                      ),
                      _buildProfileField(
                        Icons.calendar_today,
                        'Member Since',
                        'Recently joined',
                        null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildProfileSection(
                    'Workplace Assignments',
                    Icons.business,
                    [
                      if (currentEmployee.workplaceNames.isNotEmpty)
                        _buildProfileField(
                          Icons.location_on,
                          'Works at',
                          currentEmployee.workplaceNames.join(', '),
                          null,
                        )
                      else
                        _buildProfileField(
                          Icons.location_off,
                          'No workplace assigned',
                          'This employee is not assigned to any workplace',
                          null,
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Always show Points History
                  _buildProfileSection(
                    'Points & History',
                    Icons.history,
                    [
                      _buildProfileField(
                        Icons.history,
                        'Points History',
                        'View points transactions',
                        () => _showPointsHistoryDialog(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Only show Administrative Actions if current user is admin in this company context
                  if (_isAdminInContext())
                    _buildProfileSection(
                      'Administrative Actions',
                      Icons.admin_panel_settings,
                      [
                        _buildProfileField(
                          Icons.lock_reset,
                          'Reset Password',
                          'Send password reset email',
                          () => _showResetPasswordDialog(),
                        ),
                        _buildProfileField(
                          Icons.stars,
                          'Adjust Points',
                          'Add or remove points',
                          () => _showAdjustPointsDialog(),
                        ),
                        _buildProfileField(
                          Icons.notifications,
                          'Send Notification',
                          'Send message to employee',
                          () => _showSendNotificationDialog(),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection(
      String title, IconData icon, List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.blue[600], size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildProfileField(
      IconData icon, String label, String value, VoidCallback? onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: onTap != null ? Colors.grey[50] : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.blue[600], size: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                Icon(Icons.arrow_forward_ios,
                    size: 16, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageButton() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: _sendMessageToEmployee,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            children: [
              Icon(Icons.message, color: Colors.blue[600], size: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Message',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Send a message',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
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

  Widget _buildGiftPointsButton() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: _showGiftPointsDialog,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            children: [
              Icon(Icons.card_giftcard, color: Colors.blue[600], size: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gift Points',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Send points as a gift',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
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

  void _showGiftPointsDialog() {
    final currentUser = widget.appProvider.currentUser;
    if (currentUser == null) return;

    // Get the company context for points
    final companyId = widget.companyContext ?? currentUser.primaryCompanyId;
    if (companyId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No company context available'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Get sender's current points in this company
    final senderPoints = widget.appProvider.getUserCompanyPoints(
      currentUser.id,
      companyId,
    );

    final pointsController = TextEditingController();
    final messageController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Gift Points'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Send points to ${currentEmployee.name}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your available points: $senderPoints',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: pointsController,
                decoration: const InputDecoration(
                  labelText: 'Points to gift',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.stars),
                  hintText: 'Enter amount',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: messageController,
                decoration: const InputDecoration(
                  labelText: 'Message (optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.note),
                  hintText: 'Add a note',
                ),
                maxLines: 3,
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
              final points = int.tryParse(pointsController.text);
              if (points == null || points <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid positive number'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              if (points > senderPoints) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('You don\'t have enough points'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              // Deduct points from sender and add to recipient
              final giftMessage = messageController.text.isNotEmpty
                  ? ': ${messageController.text}'
                  : '';

              await widget.appProvider.updateUserPoints(
                currentUser.id,
                -points,
                'Gifted to ${currentEmployee.name}$giftMessage',
                companyId: companyId,
              );

              await widget.appProvider.updateUserPoints(
                currentEmployee.id,
                points,
                'Gift from ${currentUser.name}$giftMessage',
                companyId: companyId,
              );

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'Gifted $points points to ${currentEmployee.name}!'),
                    backgroundColor: Colors.green,
                  ),
                );
                setState(() {}); // Refresh the UI
              }
            },
            child: const Text('Send Gift'),
          ),
        ],
      ),
    );
  }

  void _showEditFieldDialog(
      String fieldName, String currentValue, Function(String) onSave) {
    final controller = TextEditingController(text: currentValue);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit $fieldName'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: fieldName,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              onSave(controller.text);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$fieldName updated successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _sendMessageToEmployee() {
    // Navigate to chat screen with this employee
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          recipient: currentEmployee,
        ),
      ),
    );
  }

  void _showQuickEditDialog() {
    UserRole selectedRole = currentEmployee.role;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit User Role'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                  'Current role: ${_getRoleDisplayName(currentEmployee.role)}'),
              const SizedBox(height: 16),
              DropdownButtonFormField<UserRole>(
                value: selectedRole,
                decoration: const InputDecoration(
                  labelText: 'New Role',
                  border: OutlineInputBorder(),
                ),
                items: UserRole.values.map((role) {
                  return DropdownMenuItem(
                    value: role,
                    child: Text(_getRoleDisplayName(role)),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      selectedRole = value;
                    });
                  }
                },
              ),
              if (selectedRole != currentEmployee.role) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: selectedRole == UserRole.admin
                        ? Colors.purple.shade50
                        : Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        selectedRole == UserRole.admin
                            ? Icons.admin_panel_settings
                            : Icons.person,
                        color: selectedRole == UserRole.admin
                            ? Colors.purple
                            : Colors.blue,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'New permissions: ${_getRoleDescription(selectedRole)}',
                          style: TextStyle(
                            color: selectedRole == UserRole.admin
                                ? Colors.purple.shade700
                                : Colors.blue.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            if (selectedRole != currentEmployee.role)
              ElevatedButton(
                onPressed: () async {
                  try {
                    Navigator.pop(context);

                    // Update the employee's role
                    final updatedEmployee =
                        currentEmployee.copyWith(role: selectedRole);
                    await widget.appProvider.updateUser(updatedEmployee);

                    // Update the local currentEmployee instance
                    setState(() {
                      currentEmployee = updatedEmployee;
                    });

                    // Show success message
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '${currentEmployee.name} role changed to ${_getRoleDisplayName(selectedRole)}',
                        ),
                        backgroundColor: selectedRole == UserRole.admin
                            ? Colors.purple
                            : Colors.green,
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error updating role: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: selectedRole == UserRole.admin
                      ? Colors.purple
                      : Colors.blue,
                ),
                child: Text(
                  'Update Role',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getRoleDisplayName(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'Administrator';
      case UserRole.employee:
        return 'Employee';
    }
  }

  String _getRoleDescription(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'Full admin access - can manage all users, targets, bonuses, and system settings';
      case UserRole.employee:
        return 'Employee access - can view and update their own targets and redeem bonuses';
    }
  }

  Widget _buildRoleDropdownField(IconData icon, String label,
      UserRole currentRole, String? companyId, bool isOwnProfile) {
    // If viewing own profile or in read-only mode, show read-only field instead of dropdown
    if (isOwnProfile || widget.readOnly) {
      return _buildProfileField(
        icon,
        label,
        _getRoleDisplayName(currentRole),
        null, // No tap action - read-only
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: null, // Let the dropdown handle the interaction
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
                      label,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    DropdownButtonHideUnderline(
                      child: DropdownButton<UserRole>(
                        value: currentRole,
                        icon: Icon(Icons.arrow_drop_down,
                            color: Colors.grey[400]),
                        isExpanded: true,
                        items: UserRole.values.map((role) {
                          return DropdownMenuItem<UserRole>(
                            value: role,
                            child: Row(
                              children: [
                                Icon(
                                  role == UserRole.admin
                                      ? Icons.admin_panel_settings
                                      : Icons.person,
                                  size: 16,
                                  color: role == UserRole.admin
                                      ? Colors.purple
                                      : Colors.blue,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _getRoleDisplayName(role),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (UserRole? newRole) {
                          if (newRole != null && newRole != currentRole) {
                            // Show confirmation dialog when a different role is selected
                            _showRoleChangeConfirmation(newRole, companyId);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompanyDropdownField(
      IconData icon, String label, User employee, AppProvider provider) {
    // If in read-only mode, show as a simple read-only field
    if (widget.readOnly) {
      return FutureBuilder<List<Company>>(
        future: provider.getCompanies(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return _buildProfileField(icon, label, 'Loading...', null);
          }

          final companies = snapshot.data!;
          final company = companies.firstWhere(
            (c) => c.id == employee.primaryCompanyId,
            orElse: () => Company(
                id: '',
                name: 'No company',
                address: null,
                contactEmail: null,
                contactPhone: null,
                adminUserId: '',
                createdAt: DateTime.now()),
          );

          return _buildProfileField(
            icon,
            label,
            company.name,
            null, // No tap action - read-only
          );
        },
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  FutureBuilder<List<Company>>(
                    future: provider.getCompanies(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Text('Loading...');
                      }

                      final allCompanies = snapshot.data!;
                      final currentCompanyId = employee.primaryCompanyId;
                      final currentUser = provider.currentUser;

                      // Determine which companies to show
                      final List<Company> displayCompanies;

                      // If viewing own profile, show ALL user's companies
                      if (currentUser?.id == employee.id) {
                        displayCompanies = allCompanies
                            .where((c) => employee.companyIds.contains(c.id))
                            .toList();
                      } else {
                        // If viewing another employee, only show shared companies
                        displayCompanies = allCompanies.where((company) {
                          final employeeInCompany =
                              employee.companyIds.contains(company.id);
                          final adminInCompany =
                              currentUser?.companyIds.contains(company.id) ??
                                  false;
                          return employeeInCompany && adminInCompany;
                        }).toList();
                      }

                      return DropdownButtonHideUnderline(
                        child: DropdownButton<String?>(
                          value: displayCompanies
                                  .any((c) => c.id == currentCompanyId)
                              ? currentCompanyId
                              : null,
                          icon: Icon(Icons.arrow_drop_down,
                              color: Colors.grey[400]),
                          isExpanded: true,
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Row(
                                children: [
                                  Icon(Icons.business_outlined,
                                      size: 16, color: Colors.grey),
                                  SizedBox(width: 8),
                                  Text(
                                    'None',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ...displayCompanies.map((company) {
                              return DropdownMenuItem<String?>(
                                value: company.id,
                                child: Row(
                                  children: [
                                    const Icon(Icons.business,
                                        size: 16, color: Colors.blue),
                                    const SizedBox(width: 8),
                                    Text(
                                      company.name,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                          onChanged: (String? newCompanyId) {
                            if (newCompanyId != currentCompanyId) {
                              _showCompanyChangeConfirmation(employee,
                                  newCompanyId, displayCompanies, provider);
                            }
                          },
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCompanyChangeConfirmation(User employee, String? newCompanyId,
      List<Company> companies, AppProvider provider) {
    final newCompany = newCompanyId != null
        ? companies.firstWhere((c) => c.id == newCompanyId)
        : null;

    final oldCompanyName =
        employee.companyNames.isNotEmpty ? employee.companyNames.first : 'None';
    final newCompanyName = newCompany?.name ?? 'None';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Company Change'),
        content: Text(
          'Change company from "$oldCompanyName" to "$newCompanyName"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Only update the primary company, keep all existing companies
              final updatedEmployee = employee.copyWith(
                primaryCompanyId: newCompany?.id,
              );

              await provider.updateUser(updatedEmployee);
              setState(() {
                currentEmployee = updatedEmployee;
              });

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Switched to $newCompanyName'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _showRoleChangeConfirmation(UserRole newRole, String? companyId) {
    // Get current role for the company context
    final currentRole = companyId != null
        ? currentEmployee.getRoleForCompany(companyId)
        : currentEmployee.role;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Role Change'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  currentRole == UserRole.admin
                      ? Icons.admin_panel_settings
                      : Icons.person,
                  color: currentRole == UserRole.admin
                      ? Colors.purple
                      : Colors.blue,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(_getRoleDisplayName(currentRole)),
                const Text(' → '),
                Icon(
                  newRole == UserRole.admin
                      ? Icons.admin_panel_settings
                      : Icons.person,
                  color:
                      newRole == UserRole.admin ? Colors.purple : Colors.blue,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(_getRoleDisplayName(newRole)),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: newRole == UserRole.admin
                    ? Colors.purple.shade50
                    : Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: newRole == UserRole.admin
                      ? Colors.purple.shade200
                      : Colors.blue.shade200,
                ),
              ),
              child: Text(
                _getRoleDescription(newRole),
                style: TextStyle(
                  color: newRole == UserRole.admin
                      ? Colors.purple.shade700
                      : Colors.blue.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Are you sure you want to change this user\'s role? This will affect their permissions immediately.',
              style: TextStyle(fontWeight: FontWeight.w500),
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
              try {
                Navigator.pop(context);

                // Update the employee's role for this company
                User updatedEmployee;
                if (companyId != null) {
                  // Update company-specific role
                  updatedEmployee =
                      currentEmployee.setRoleForCompany(companyId, newRole);
                } else {
                  // Update global role (fallback)
                  updatedEmployee = currentEmployee.copyWith(role: newRole);
                }

                await widget.appProvider.updateUser(updatedEmployee);

                // Update the local currentEmployee instance
                setState(() {
                  currentEmployee = updatedEmployee;
                });

                // Show success message
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '${currentEmployee.name} role changed to ${_getRoleDisplayName(newRole)} successfully${companyId != null ? ' for this company' : ''}',
                    ),
                    backgroundColor: newRole == UserRole.admin
                        ? Colors.purple
                        : Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error updating role: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  newRole == UserRole.admin ? Colors.purple : Colors.blue,
            ),
            child: const Text(
              'Confirm Role Change',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showResetPasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Password'),
        content: Text('Send password reset email to ${currentEmployee.email}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'Password reset email sent to ${currentEmployee.email}'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  void _showAdjustPointsDialog() {
    final pointsController = TextEditingController();
    String selectedAction = 'add';

    // Get company ID from context or admin's current company
    final adminCompanyId = widget.companyContext ??
        widget.appProvider.currentUser?.primaryCompanyId;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Adjust Points'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Consumer<AppProvider>(
                builder: (context, provider, child) {
                  final currentPoints = adminCompanyId != null
                      ? provider.getUserCompanyPoints(
                          currentEmployee.id, adminCompanyId)
                      : 0;
                  return Text('Current points: $currentPoints');
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedAction,
                decoration: const InputDecoration(
                  labelText: 'Action',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'add', child: Text('Add Points')),
                  DropdownMenuItem(
                      value: 'remove', child: Text('Remove Points')),
                ],
                onChanged: (value) {
                  setState(() {
                    selectedAction = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: pointsController,
                decoration: const InputDecoration(
                  labelText: 'Points Amount',
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
            TextButton(
              onPressed: () async {
                final points = int.tryParse(pointsController.text);
                print(
                    'DEBUG: UI - Entered points: $points, Action: $selectedAction, Company: $adminCompanyId');
                if (points != null && points > 0) {
                  Navigator.pop(context);

                  // Calculate the points change (positive for add, negative for remove)
                  final pointsChange =
                      selectedAction == 'add' ? points : -points;
                  print('DEBUG: UI - Calculated pointsChange: $pointsChange');
                  final description = selectedAction == 'add'
                      ? 'Admin added $points points'
                      : 'Admin removed $points points';

                  try {
                    // Update the employee's points for the current company
                    await widget.appProvider.updateUserPoints(
                        currentEmployee.id, pointsChange, description,
                        companyId: adminCompanyId);

                    // Refresh the employee data from the provider
                    final updatedUsers = await StorageService.getUsers();
                    final updatedEmployee = updatedUsers.firstWhere(
                      (user) => user.id == currentEmployee.id,
                      orElse: () => currentEmployee,
                    );

                    // Update the local employee object with fresh data
                    setState(() {
                      currentEmployee = updatedEmployee;
                    });

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            '${selectedAction == 'add' ? 'Added' : 'Removed'} $points points for ${currentEmployee.name}'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error updating points: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }

  void _showSendNotificationDialog() {
    final messageController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Notification'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Send a message to ${currentEmployee.name}'),
            const SizedBox(height: 16),
            TextField(
              controller: messageController,
              decoration: const InputDecoration(
                labelText: 'Message',
                border: OutlineInputBorder(),
                hintText: 'Enter your message here...',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (messageController.text.isNotEmpty) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content:
                        Text('Notification sent to ${currentEmployee.name}'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  void _showPointsHistoryDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Points History - ${currentEmployee.name}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    iconSize: 28,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Current Points Summary
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Consumer<AppProvider>(
                      builder: (context, provider, child) {
                        // Get the company context for filtering
                        final companyId = widget.companyContext ??
                            provider.currentUser?.primaryCompanyId;

                        final currentPoints = companyId != null
                            ? provider.getUserCompanyPoints(
                                currentEmployee.id, companyId)
                            : provider.getUserTotalPoints(currentEmployee.id);

                        // Calculate earned and spent from company-filtered transactions
                        final companyTransactions = provider.pointsTransactions
                            .where((t) =>
                                t.userId == currentEmployee.id &&
                                (companyId == null || t.companyId == companyId))
                            .toList();

                        final totalEarned =
                            companyTransactions.fold(0, (sum, t) {
                          if (t.type == PointsTransactionType.earned ||
                              t.type == PointsTransactionType.adjustment) {
                            return sum + t.points;
                          }
                          return sum;
                        });

                        final totalSpent =
                            companyTransactions.fold(0, (sum, t) {
                          if (t.type == PointsTransactionType.redeemed ||
                              t.type == PointsTransactionType.bonus) {
                            return sum + t.points;
                          }
                          return sum;
                        });

                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildPointsSummaryCard(
                              'Current Points',
                              '$currentPoints',
                              Icons.stars,
                              Colors.blue,
                            ),
                            _buildPointsSummaryCard(
                              'Total Earned',
                              '$totalEarned',
                              Icons.trending_up,
                              Colors.green,
                            ),
                            _buildPointsSummaryCard(
                              'Total Spent',
                              '$totalSpent',
                              Icons.trending_down,
                              Colors.red,
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Points History List
              Expanded(
                child: FutureBuilder<List<PointsTransaction>>(
                  future: Future.value(widget.appProvider.pointsTransactions),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(
                          child: Text('No points history found'));
                    }

                    // Get the company context for filtering
                    final companyId = widget.companyContext ??
                        widget.appProvider.currentUser?.primaryCompanyId;

                    // Filter transactions for this employee AND company
                    final employeeTransactions = snapshot.data!
                        .where((t) =>
                            t.userId == currentEmployee.id &&
                            (companyId == null || t.companyId == companyId))
                        .toList()
                      ..sort((a, b) => b.date
                          .compareTo(a.date)); // Sort by date, newest first

                    if (employeeTransactions.isEmpty) {
                      return const Center(
                          child: Text('No points history for this employee'));
                    }

                    // Calculate totals from actual transactions
                    final totalEarned = employeeTransactions
                        .where((t) =>
                            t.type == PointsTransactionType.earned ||
                            (t.type == PointsTransactionType.adjustment &&
                                t.points > 0))
                        .fold<int>(0, (sum, t) => sum + t.points);

                    final totalSpent = employeeTransactions
                        .where((t) =>
                            t.type == PointsTransactionType.redeemed ||
                            (t.type == PointsTransactionType.adjustment &&
                                t.points < 0))
                        .fold<int>(0, (sum, t) => sum + t.points.abs());

                    return Column(
                      children: [
                        // Updated Summary with real calculations
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Consumer<AppProvider>(
                                builder: (context, provider, child) {
                                  // Get company-specific points
                                  final companyId = widget.companyContext ??
                                      provider.currentUser?.primaryCompanyId;
                                  final currentPoints = companyId != null
                                      ? provider.getUserCompanyPoints(
                                          currentEmployee.id, companyId)
                                      : 0;
                                  return _buildPointsSummaryCard(
                                    'Current Points',
                                    '$currentPoints',
                                    Icons.stars,
                                    Colors.blue,
                                  );
                                },
                              ),
                              _buildPointsSummaryCard(
                                'Total Earned',
                                '$totalEarned',
                                Icons.trending_up,
                                Colors.green,
                              ),
                              _buildPointsSummaryCard(
                                'Total Spent',
                                '$totalSpent',
                                Icons.trending_down,
                                Colors.red,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Transaction List
                        Expanded(
                          child: ListView.builder(
                            itemCount: employeeTransactions.length,
                            itemBuilder: (context, index) {
                              final transaction = employeeTransactions[index];
                              return _buildPointsTransactionCard(
                                  transaction, index);
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPointsSummaryCard(
      String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildPointsTransactionCard(PointsTransaction transaction, int index) {
    // Consider adjustment transactions with positive points as "earned" for display
    final isEarned = transaction.type == PointsTransactionType.earned ||
        (transaction.type == PointsTransactionType.adjustment &&
            transaction.points > 0);
    final isRedeemed = transaction.type == PointsTransactionType.redeemed ||
        (transaction.type == PointsTransactionType.adjustment &&
            transaction.points < 0);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Transaction Icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isEarned ? Colors.green[100] : Colors.red[100],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                isEarned ? Icons.add : Icons.remove,
                color: isEarned ? Colors.green[600] : Colors.red[600],
                size: 20,
              ),
            ),
            const SizedBox(width: 16),

            // Transaction Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.description,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(transaction.date),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (transaction.relatedTargetId != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Target ID: ${transaction.relatedTargetId}',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Points Amount
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isEarned ? '+' : '-'}${transaction.points}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isEarned ? Colors.green[600] : Colors.red[600],
                  ),
                ),
                Text(
                  'points',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  int _calculateTotalEarned() {
    // This will be calculated from actual transactions in the dialog
    return 0; // Placeholder, will be calculated dynamically
  }

  int _calculateTotalSpent() {
    // This will be calculated from actual transactions in the dialog
    return 0; // Placeholder, will be calculated dynamically
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

class StoreProfileScreen extends StatefulWidget {
  final Workplace workplace;
  final AppProvider appProvider;

  const StoreProfileScreen({
    Key? key,
    required this.workplace,
    required this.appProvider,
  }) : super(key: key);

  @override
  State<StoreProfileScreen> createState() => _StoreProfileScreenState();
}

class _StoreProfileScreenState extends State<StoreProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.workplace.name} Profile'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _loadStoreAnalytics(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final analytics = snapshot.data ?? {};
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStoreHeader(),
                const SizedBox(height: 24),
                _buildAnalyticsSection(analytics),
                const SizedBox(height: 24),
                _buildEmployeesSection(analytics),
                const SizedBox(height: 24),
                _buildTargetsSection(analytics),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStoreHeader() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[700]!, Colors.blue[500]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.business,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.workplace.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.workplace.address,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsSection(Map<String, dynamic> analytics) {
    final totalPointsHanded = analytics['totalPointsHanded'] ?? 0;
    final pointsFromStoreTargets = analytics['pointsFromStoreTargets'] ?? 0;
    final totalTargets = analytics['totalTargets'] ?? 0;
    final completedTargets = analytics['completedTargets'] ?? 0;
    final completionRate = analytics['completionRate'] ?? 0.0;
    final totalEmployees = analytics['totalEmployees'] ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Store Analytics',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildAnalyticsCard(
                'Total Points Handed',
                totalPointsHanded.toString(),
                Icons.stars,
                Colors.amber,
                subtitle: 'To all employees',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildAnalyticsCard(
                'Points from Store',
                pointsFromStoreTargets.toString(),
                Icons.store,
                Colors.orange,
                subtitle: 'From this store\'s targets',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildAnalyticsCard(
                'Total Employees',
                totalEmployees.toString(),
                Icons.people,
                Colors.blue,
                subtitle: 'Active staff',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildAnalyticsCard(
                'This Week',
                '${analytics['thisWeekTargets'] ?? 0}',
                Icons.calendar_today,
                Colors.purple,
                subtitle: 'Targets set',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildAnalyticsCard(
                'Targets Completed',
                '$completedTargets/$totalTargets',
                Icons.check_circle,
                Colors.green,
                subtitle:
                    '${completionRate.toStringAsFixed(1)}% completion rate',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(), // Empty space for layout balance
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAnalyticsCard(
      String title, String value, IconData icon, Color color,
      {String? subtitle}) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.grey,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmployeesSection(Map<String, dynamic> analytics) {
    final employees = analytics['employees'] as List<User>? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Store Employees',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        if (employees.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: Text('No employees assigned to this store'),
              ),
            ),
          )
        else
          ...employees
              .map((employee) => Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue[100],
                        child: Text(
                          employee.name.isNotEmpty
                              ? employee.name[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            color: Colors.blue[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(employee.name),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(employee.email),
                          if (employee.workplaceNames.isNotEmpty)
                            Text(
                              'Works at: ${employee.workplaceNames.join(', ')}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.blue,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                        ],
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${employee.totalPoints} pts',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.amber,
                            ),
                          ),
                          Text(
                            employee.role == UserRole.employee
                                ? 'Employee'
                                : 'Admin',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ))
              .toList(),
      ],
    );
  }

  Widget _buildTargetsSection(Map<String, dynamic> analytics) {
    final thisWeekTargets =
        analytics['thisWeekTargetsList'] as List<SalesTarget>? ?? [];
    final thisMonthTargets =
        analytics['thisMonthTargetsList'] as List<SalesTarget>? ?? [];
    final thisYearTargets =
        analytics['thisYearTargetsList'] as List<SalesTarget>? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Target Performance',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildTargetPeriodCard('This Week', thisWeekTargets),
        const SizedBox(height: 12),
        _buildTargetPeriodCard('This Month', thisMonthTargets),
        const SizedBox(height: 12),
        _buildTargetPeriodCard('This Year', thisYearTargets),
      ],
    );
  }

  Widget _buildTargetPeriodCard(String period, List<SalesTarget> targets) {
    final completed = targets.where((t) => t.isMet).length;
    final total = targets.length;
    final completionRate = total > 0 ? (completed / total) * 100 : 0.0;
    final totalAmount =
        targets.fold<double>(0, (sum, t) => sum + t.targetAmount);
    final actualAmount =
        targets.fold<double>(0, (sum, t) => sum + t.actualAmount);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  period,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '$completed/$total',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: completed == total ? Colors.green : Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: total > 0 ? completed / total : 0,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                completed == total ? Colors.green : Colors.orange,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${completionRate.toStringAsFixed(1)}% completion',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  '\$${actualAmount.toStringAsFixed(0)} / \$${totalAmount.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<Map<String, dynamic>> _loadStoreAnalytics() async {
    try {
      // Get all data
      final users = await StorageService.getUsers();
      final targets = await StorageService.getSalesTargets();
      final transactions = await StorageService.getPointsTransactions();

      // Filter data for this workplace - employees who work at this location
      final storeEmployees = users
          .where((user) => user.workplaceIds.contains(widget.workplace.id))
          .toList();

      final storeTargets = targets
          .where((target) => target.assignedWorkplaceId == widget.workplace.id)
          .toList();

      // Calculate time periods
      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final monthStart = DateTime(now.year, now.month, 1);
      final yearStart = DateTime(now.year, 1, 1);

      final thisWeekTargets = storeTargets.where((target) {
        return target.date.isAfter(weekStart.subtract(const Duration(days: 1)));
      }).toList();

      final thisMonthTargets = storeTargets.where((target) {
        return target.date
            .isAfter(monthStart.subtract(const Duration(days: 1)));
      }).toList();

      final thisYearTargets = storeTargets.where((target) {
        return target.date.isAfter(yearStart.subtract(const Duration(days: 1)));
      }).toList();

      // Calculate total points handed to employees
      final employeeIds = storeEmployees.map((e) => e.id).toList();
      final totalPointsHanded = transactions
          .where((t) =>
              employeeIds.contains(t.userId) &&
              t.type == PointsTransactionType.earned)
          .fold<int>(0, (sum, t) => sum + t.points);

      // Calculate points earned specifically from this store's targets
      final storeTargetIds = storeTargets.map((t) => t.id).toList();
      final pointsFromStoreTargets = transactions
          .where((t) =>
              employeeIds.contains(t.userId) &&
              t.type == PointsTransactionType.earned &&
              t.description.contains('Target completed'))
          .fold<int>(0, (sum, t) => sum + t.points);

      // Calculate completion rates
      final completedTargets = storeTargets.where((t) => t.isMet).length;
      final completionRate = storeTargets.isNotEmpty
          ? (completedTargets / storeTargets.length) * 100
          : 0.0;

      return {
        'totalPointsHanded': totalPointsHanded,
        'pointsFromStoreTargets': pointsFromStoreTargets,
        'totalTargets': storeTargets.length,
        'completedTargets': completedTargets,
        'completionRate': completionRate,
        'totalEmployees': storeEmployees.length,
        'employees': storeEmployees,
        'thisWeekTargets': thisWeekTargets.length,
        'thisWeekTargetsList': thisWeekTargets,
        'thisMonthTargetsList': thisMonthTargets,
        'thisYearTargetsList': thisYearTargets,
      };
    } catch (e) {
      print('Error loading store analytics: $e');
      return {};
    }
  }

  void _showPointsRulesDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Configure Points Rules'),
          content:
              const Text('Points Rules configuration dialog is now working!'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  // Swipe-to-delete helper methods
  Future<bool?> _showDeleteConfirmDialog(
      BuildContext context, SalesTarget target) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Target'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Are you sure you want to delete this target?'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Target: \$${target.targetAmount.toStringAsFixed(0)}'),
                  Text(
                      'Employee: ${target.assignedEmployeeName ?? 'Unassigned'}'),
                  Text(
                      'Date: ${DateFormat('MMM dd, yyyy').format(target.date)}'),
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
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _deleteTarget(SalesTarget target, AppProvider appProvider) async {
    try {
      await appProvider.deleteSalesTarget(target.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Target for \$${target.targetAmount.toStringAsFixed(0)} deleted'),
          backgroundColor: Colors.green,
          action: SnackBarAction(
            label: 'Undo',
            textColor: Colors.white,
            onPressed: () {
              // TODO: Implement undo functionality if needed
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Undo not yet implemented'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting target: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class PointsRulesScreen extends StatefulWidget {
  final AppProvider appProvider;

  const PointsRulesScreen({required this.appProvider, super.key});

  @override
  State<PointsRulesScreen> createState() => _PointsRulesScreenState();
}

class _PointsRulesScreenState extends State<PointsRulesScreen> {
  late TextEditingController percentController;
  late TextEditingController pointsController;
  late TextEditingController pointValueController;
  late TextEditingController currencySymbolController;

  int? editingIndex;

  @override
  void initState() {
    super.initState();
    percentController = TextEditingController();
    pointsController = TextEditingController();
    pointValueController = TextEditingController(
      text: widget.appProvider.pointsRules.pointValue.toStringAsFixed(0),
    );
    currencySymbolController = TextEditingController(
      text: widget.appProvider.pointsRules.currencySymbol,
    );
  }

  @override
  void dispose() {
    percentController.dispose();
    pointsController.dispose();
    pointValueController.dispose();
    currencySymbolController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        final rules = appProvider.pointsRules;
        final currentCompanyId = appProvider.currentUser?.primaryCompanyId;

        return FutureBuilder<List<Company>>(
          future: appProvider.getCompanies(),
          builder: (context, companySnapshot) {
            final currentCompany = companySnapshot.data?.firstWhere(
              (c) => c.id == currentCompanyId,
              orElse: () => Company(
                id: '',
                name: 'Unknown',
                address: '',
                createdAt: DateTime.now(),
                adminUserId: '',
              ),
            );

            return Scaffold(
              appBar: AppBar(
                title: Text(
                    'Points Rules${currentCompany != null && currentCompany.id.isNotEmpty ? ' - ${currentCompany.name}' : ''}'),
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Currency Value Section
                    Text(
                      'Point Currency Value',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Define how much 1 point is worth in your local currency',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: TextField(
                                    controller: pointValueController,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                            decimal: true),
                                    decoration: const InputDecoration(
                                      labelText: 'Value per Point',
                                      border: OutlineInputBorder(),
                                      hintText: 'e.g., 100',
                                    ),
                                    onChanged: (value) {
                                      final newValue = double.tryParse(value);
                                      if (newValue != null &&
                                          newValue > 0 &&
                                          currentCompanyId != null) {
                                        appProvider.updatePointsRules(
                                          appProvider
                                              .getPointsRules(currentCompanyId)
                                              .copyWith(pointValue: newValue),
                                          currentCompanyId,
                                        );
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextField(
                                    controller: currencySymbolController,
                                    decoration: const InputDecoration(
                                      labelText: 'Currency',
                                      border: OutlineInputBorder(),
                                      hintText: 'ISK',
                                    ),
                                    onChanged: (value) {
                                      if (value.isNotEmpty &&
                                          currentCompanyId != null) {
                                        appProvider.updatePointsRules(
                                          appProvider
                                              .getPointsRules(currentCompanyId)
                                              .copyWith(currencySymbol: value),
                                          currentCompanyId,
                                        );
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.info_outline,
                                      color: Colors.blue[700]),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '1 point = ${rules.pointValue.toStringAsFixed(0)} ${rules.currencySymbol}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue[700],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Custom Rules Section
                    Text(
                      'Custom Rules',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                    ),
                    const SizedBox(height: 12),
                    // Add new custom rule
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Text(
                              'Add New Rule',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: percentController,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                            decimal: true),
                                    decoration: const InputDecoration(
                                      labelText:
                                          'Custom threshold % (e.g. 125)',
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextField(
                                    controller: pointsController,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      labelText: 'Points (e.g. 25)',
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                ElevatedButton(
                                  onPressed: () {
                                    final p = double.tryParse(
                                        percentController.text.trim());
                                    final pts = int.tryParse(
                                        pointsController.text.trim());
                                    if (p != null &&
                                        pts != null &&
                                        currentCompanyId != null) {
                                      final updatedEntries =
                                          List<PointsRuleEntry>.from(
                                              rules.entries)
                                            ..add(PointsRuleEntry(
                                                thresholdPercent: p,
                                                points: pts))
                                            ..sort((a, b) => a.thresholdPercent
                                                .compareTo(b.thresholdPercent));
                                      appProvider.updatePointsRules(
                                        appProvider
                                            .getPointsRules(currentCompanyId)
                                            .copyWith(entries: updatedEntries),
                                        currentCompanyId,
                                      );
                                      percentController.clear();
                                      pointsController.clear();
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                'Custom rule added successfully!')),
                                      );
                                    }
                                  },
                                  child: const Text('Add Rule'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Existing rules',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (rules.entries.isEmpty)
                              const Text('No custom rules added yet.')
                            else
                              ...rules.entries.asMap().entries.map((entry) {
                                final i = entry.key;
                                final e = entry.value;
                                final isEditing = editingIndex == i;

                                return Column(
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: isEditing
                                              ? TextField(
                                                  controller:
                                                      TextEditingController(
                                                          text: e
                                                              .thresholdPercent
                                                              .toStringAsFixed(
                                                                  0)),
                                                  keyboardType:
                                                      const TextInputType
                                                          .numberWithOptions(
                                                          decimal: true),
                                                  onChanged: (value) {
                                                    final newPercent =
                                                        double.tryParse(value);
                                                    if (newPercent != null &&
                                                        currentCompanyId !=
                                                            null) {
                                                      final updatedEntries =
                                                          List<PointsRuleEntry>.from(
                                                              rules.entries);
                                                      updatedEntries[i] =
                                                          PointsRuleEntry(
                                                        thresholdPercent:
                                                            newPercent,
                                                        points: e.points,
                                                      );
                                                      appProvider
                                                          .updatePointsRules(
                                                        appProvider
                                                            .getPointsRules(
                                                                currentCompanyId)
                                                            .copyWith(
                                                                entries:
                                                                    updatedEntries),
                                                        currentCompanyId,
                                                      );
                                                    }
                                                  },
                                                )
                                              : Text(
                                                  '${e.thresholdPercent.toStringAsFixed(0)}% → ${e.points} pts',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall,
                                                ),
                                        ),
                                        if (isEditing)
                                          Expanded(
                                            child: TextField(
                                              controller: TextEditingController(
                                                  text: e.points.toString()),
                                              keyboardType:
                                                  TextInputType.number,
                                              onChanged: (value) {
                                                final newPoints =
                                                    int.tryParse(value);
                                                if (newPoints != null &&
                                                    currentCompanyId != null) {
                                                  final updatedEntries = List<
                                                          PointsRuleEntry>.from(
                                                      rules.entries);
                                                  updatedEntries[i] =
                                                      PointsRuleEntry(
                                                    thresholdPercent:
                                                        e.thresholdPercent,
                                                    points: newPoints,
                                                  );
                                                  appProvider.updatePointsRules(
                                                    appProvider
                                                        .getPointsRules(
                                                            currentCompanyId)
                                                        .copyWith(
                                                            entries:
                                                                updatedEntries),
                                                    currentCompanyId,
                                                  );
                                                }
                                              },
                                            ),
                                          ),
                                        IconButton(
                                          icon: Icon(
                                              isEditing
                                                  ? Icons.check
                                                  : Icons.edit,
                                              size: 18),
                                          tooltip: isEditing ? 'Save' : 'Edit',
                                          onPressed: () {
                                            setState(() {
                                              editingIndex =
                                                  isEditing ? null : i;
                                            });
                                          },
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete,
                                              size: 18),
                                          tooltip: 'Remove',
                                          onPressed: () {
                                            if (currentCompanyId == null)
                                              return;
                                            final updated =
                                                List<PointsRuleEntry>.from(
                                                    rules.entries)
                                                  ..removeAt(i);
                                            appProvider.updatePointsRules(
                                              appProvider
                                                  .getPointsRules(
                                                      currentCompanyId)
                                                  .copyWith(entries: updated),
                                              currentCompanyId,
                                            );
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                  content: Text(
                                                      'Rule deleted successfully!')),
                                            );
                                          },
                                        )
                                      ],
                                    ),
                                  ],
                                );
                              }).toList(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// TargetListScreen - A new screen to manage targets with selection functionality
class TargetListScreen extends StatefulWidget {
  final AppProvider appProvider;

  const TargetListScreen({super.key, required this.appProvider});

  @override
  State<TargetListScreen> createState() => _TargetListScreenState();
}

class _TargetListScreenState extends State<TargetListScreen> {
  Set<String> _selectedTargetIds = <String>{};
  bool _isSelectionMode = false;
  List<String> _allTargetIds = [];
  String? _selectedWorkplaceId; // Filter by workplace

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedTargetIds.clear();
      }
    });
  }

  void _selectAllTargets() {
    setState(() {
      _selectedTargetIds = _allTargetIds.toSet();
    });
  }

  void _deselectAllTargets() {
    setState(() {
      _selectedTargetIds.clear();
    });
  }

  void _toggleSelectAll() {
    if (_selectedTargetIds.length == _allTargetIds.length &&
        _allTargetIds.isNotEmpty) {
      _deselectAllTargets();
    } else {
      _selectAllTargets();
    }
  }

  void _toggleTargetSelection(String targetId) {
    setState(() {
      if (_selectedTargetIds.contains(targetId)) {
        _selectedTargetIds.remove(targetId);
      } else {
        _selectedTargetIds.add(targetId);
      }
    });
  }

  void _showDeleteSelectedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Selected Targets'),
        content: Text(
          'Are you sure you want to delete ${_selectedTargetIds.length} selected targets? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final selectedCount = _selectedTargetIds.length;

              try {
                // Delete selected targets
                for (String targetId in List.from(_selectedTargetIds)) {
                  await widget.appProvider.deleteSalesTarget(targetId);
                }

                Navigator.pop(context);
                _toggleSelectionMode(); // Exit selection mode

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content:
                        Text('$selectedCount targets deleted successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error deleting targets: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showWorkplaceFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter by Workplace'),
        content: FutureBuilder<List<Workplace>>(
          future: widget.appProvider.getWorkplaces(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const CircularProgressIndicator();
            }

            final workplaces = snapshot.data!;

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: workplaces
                  .map((workplace) => ListTile(
                        title: Text(workplace.name),
                        leading: Radio<String>(
                          value: workplace.id,
                          groupValue: _selectedWorkplaceId,
                          onChanged: (value) {
                            setState(() {
                              _selectedWorkplaceId = value;
                            });
                            Navigator.pop(context);
                          },
                        ),
                        onTap: () {
                          setState(() {
                            _selectedWorkplaceId = workplace.id;
                          });
                          Navigator.pop(context);
                        },
                      ))
                  .toList(),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showAddTargetDialog() {
    final targetAmountController = TextEditingController();
    User? selectedEmployee;
    Workplace? selectedWorkplace;
    DateTime? selectedDate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Add Target'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () async {
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: selectedDate ?? DateTime.now(),
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
                            selectedDate != null
                                ? "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}"
                                : 'Select Date',
                            style: TextStyle(
                              color: selectedDate != null
                                  ? Colors.black87
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  TextField(
                    controller: targetAmountController,
                    decoration: const InputDecoration(
                      labelText: 'Target Amount',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  FutureBuilder<List<User>>(
                    future: widget.appProvider.getUsers(),
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
                        // Filter to show both employees and admins for assignment
                        final users = allUsers
                            .where((u) =>
                                u.role == UserRole.employee ||
                                u.role == UserRole.admin)
                            .toList();

                        // Show shortcut to add employee if no users available
                        if (users.isEmpty) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'No employees found. Create one?',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.pop(context); // Close this dialog
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => EmployeesListScreen(
                                          appProvider: widget.appProvider),
                                    ),
                                  ).then((_) {
                                    // Reopen target dialog when returning
                                    _showAddTargetDialog();
                                  });
                                },
                                icon: const Icon(Icons.person_add),
                                label: const Text('Manage Employees'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
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
                  FutureBuilder<List<Workplace>>(
                    future: widget.appProvider.getWorkplaces(),
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

                        // Show shortcut to add workplace if no workplaces available
                        if (workplaces.isEmpty) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'No workplaces found. Create one?',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.pop(context); // Close this dialog
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          WorkplacesListScreen(
                                              appProvider: widget.appProvider),
                                    ),
                                  ).then((_) {
                                    // Reopen target dialog when returning
                                    _showAddTargetDialog();
                                  });
                                },
                                icon: const Icon(Icons.business),
                                label: const Text('Manage Workplaces'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
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
                  final currentUser = widget.appProvider.currentUser;
                  if (selectedDate != null &&
                      targetAmountController.text.isNotEmpty &&
                      selectedEmployee != null &&
                      selectedWorkplace != null &&
                      currentUser != null) {
                    final amount = double.tryParse(targetAmountController.text);

                    if (amount != null) {
                      final target = SalesTarget(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        date: selectedDate!,
                        targetAmount: amount,
                        createdAt: DateTime.now(),
                        createdBy: currentUser.id,
                        assignedEmployeeId: selectedEmployee!.id,
                        assignedEmployeeName: selectedEmployee!.name,
                        assignedWorkplaceId: selectedWorkplace!.id,
                        assignedWorkplaceName: selectedWorkplace!.name,
                      );

                      await widget.appProvider.addSalesTarget(target);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Target added successfully')),
                      );
                    }
                  } else if (currentUser == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Error: No user logged in'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: const Text('Add'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Targets List'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (!_isSelectionMode)
            IconButton(
              icon: Icon(_selectedWorkplaceId == null
                  ? Icons.filter_list
                  : Icons.filter_list_off),
              tooltip: _selectedWorkplaceId == null
                  ? 'Filter by Workplace'
                  : 'Clear Filter',
              onPressed: () {
                if (_selectedWorkplaceId != null) {
                  setState(() {
                    _selectedWorkplaceId = null;
                  });
                } else {
                  _showWorkplaceFilterDialog();
                }
              },
            ),
          _isSelectionMode
              ? IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _toggleSelectionMode,
                  tooltip: 'Cancel Selection',
                )
              : IconButton(
                  icon: const Icon(Icons.checklist),
                  onPressed: _toggleSelectionMode,
                  tooltip: 'Select Targets',
                ),
        ],
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, child) {
          // Apply workplace filter if selected
          final targets = _selectedWorkplaceId == null
              ? provider.salesTargets
              : provider.salesTargets
                  .where((t) => t.assignedWorkplaceId == _selectedWorkplaceId)
                  .toList();

          // Update target IDs for selection
          _allTargetIds = targets.map((t) => t.id).toList();

          return Column(
            children: [
              // Select All and selection count bar
              if (_isSelectionMode)
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  color: Colors.blue.shade50,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: _toggleSelectAll,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                        ),
                        child: Text(
                          (_selectedTargetIds.length == _allTargetIds.length &&
                                  _allTargetIds.isNotEmpty)
                              ? 'Deselect All'
                              : 'Select All',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        '${_selectedTargetIds.length} Selected',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              // Targets list
              Expanded(
                child: ListView.builder(
                  padding: _isSelectionMode
                      ? const EdgeInsets.symmetric(horizontal: 16, vertical: 8)
                      : const EdgeInsets.all(16),
                  itemCount: targets.length,
                  itemBuilder: (context, index) {
                    final target = targets[index];
                    final isSelected = _selectedTargetIds.contains(target.id);

                    return Card(
                      color: isSelected ? Colors.blue.shade50 : Colors.white,
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        onTap: () {
                          if (_isSelectionMode) {
                            _toggleTargetSelection(target.id);
                          } else {
                            _navigateToTarget(target);
                          }
                        },
                        leading: CircleAvatar(
                          backgroundColor: _getStatusColor(target.status),
                          child: Icon(
                            _getStatusIcon(target.status),
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          '${target.assignedWorkplaceName ?? 'No Workplace'} • ${DateFormat('MMM d, yyyy').format(target.date)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                'Employee: ${target.assignedEmployeeName ?? 'No Employee'}'),
                            Text(
                                'Target: ${target.targetAmount.toStringAsFixed(0)}'),
                            Text(
                                'Actual: ${target.actualAmount.toStringAsFixed(0)}'),
                            Text(
                                'Workplace: ${target.assignedWorkplaceName ?? 'No Workplace'}'),
                            Text('Status: ${_getStatusText(target.status)}'),
                          ],
                        ),
                        trailing: _isSelectionMode
                            ? ElevatedButton(
                                onPressed: () =>
                                    _toggleTargetSelection(target.id),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isSelected
                                      ? Colors.blue
                                      : Colors.grey.shade300,
                                  foregroundColor: isSelected
                                      ? Colors.white
                                      : Colors.black87,
                                  minimumSize: const Size(40, 32),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                ),
                                child: Text(
                                  isSelected ? 'Selected' : 'Select',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              )
                            : IconButton(
                                icon: const Icon(Icons.arrow_forward_ios),
                                onPressed: () => _navigateToTarget(target),
                              ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: _isSelectionMode
          ? (_selectedTargetIds.isNotEmpty
              ? FloatingActionButton(
                  onPressed: _showDeleteSelectedDialog,
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  child: const Icon(Icons.delete_forever),
                )
              : null)
          : Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FloatingActionButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ImportTargetsScreen(),
                      ),
                    );
                  },
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  heroTag: 'import',
                  child: const Icon(Icons.upload_file),
                ),
                const SizedBox(width: 16),
                FloatingActionButton(
                  onPressed: _showAddTargetDialog,
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  heroTag: 'add',
                  child: const Icon(Icons.add),
                ),
              ],
            ),
    );
  }

  Color _getStatusColor(TargetStatus status) {
    switch (status) {
      case TargetStatus.pending:
        return Colors.blue; // pending -> blue
      case TargetStatus.submitted:
        return Colors.blue; // submitted -> blue
      case TargetStatus.missed:
        return Colors.red; // missed -> red
      case TargetStatus.met:
        return Colors.green; // achieved -> green
      case TargetStatus.approved:
        return Colors.green; // approved -> green
    }
  }

  IconData _getStatusIcon(TargetStatus status) {
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

  String _getStatusText(TargetStatus status) {
    return status.name.toUpperCase();
  }

  void _navigateToTarget(SalesTarget target) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TargetProfileScreen(target: target),
      ),
    );
  }
}

class EmployeesListScreen extends StatefulWidget {
  final AppProvider appProvider;
  final String?
      filterCompanyId; // Optional: filter to show only employees from this company
  final String? customTitle; // Optional: custom title for the screen
  final bool readOnly; // Optional: if true, hide add/import/delete buttons

  const EmployeesListScreen({
    super.key,
    required this.appProvider,
    this.filterCompanyId,
    this.customTitle,
    this.readOnly = false,
  });

  @override
  State<EmployeesListScreen> createState() => _EmployeesListScreenState();
}

class _EmployeesListScreenState extends State<EmployeesListScreen> {
  Set<String> _selectedEmployeeIds = <String>{};
  bool _isSelectionMode = false;
  List<String> _allEmployeeIds = [];
  String? _filterRole; // Filter by role (admin/employee)
  String _searchQuery = ''; // Search by name
  final TextEditingController _searchController = TextEditingController();

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedEmployeeIds.clear();
      }
    });
  }

  void _selectAllEmployees() {
    setState(() {
      _selectedEmployeeIds = _allEmployeeIds.toSet();
      // Exclude current admin if they exist
      final currentUserId = widget.appProvider.currentUser?.id;
      if (currentUserId != null) {
        _selectedEmployeeIds.remove(currentUserId);
      }
    });
  }

  void _deselectAllEmployees() {
    setState(() {
      _selectedEmployeeIds.clear();
    });
  }

  void _toggleSelectAll() {
    if (_selectedEmployeeIds.length == _allEmployeeIds.length &&
        _allEmployeeIds.isNotEmpty) {
      _deselectAllEmployees();
    } else {
      _selectAllEmployees();
    }
  }

  void _toggleEmployeeSelection(String employeeId) {
    setState(() {
      if (_selectedEmployeeIds.contains(employeeId)) {
        _selectedEmployeeIds.remove(employeeId);
      } else {
        _selectedEmployeeIds.add(employeeId);
      }
    });
  }

  void _showDeleteSelectedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Selected Employees'),
        content: Text(
          'Are you sure you want to delete ${_selectedEmployeeIds.length} selected employees? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final selectedCount = _selectedEmployeeIds.length;

              try {
                // Delete selected employees
                for (String employeeId in List.from(_selectedEmployeeIds)) {
                  await widget.appProvider.deleteUser(employeeId);
                }

                Navigator.pop(context);
                _toggleSelectionMode(); // Exit selection mode

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content:
                        Text('$selectedCount employees deleted successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error deleting employees: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddEmployeeDialog() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        // Initialize with admin's current company
        String? selectedCompanyId =
            widget.appProvider.currentUser?.primaryCompanyId;

        return StatefulBuilder(
          builder: (context, setState) => FutureBuilder<List<Company>>(
            future: widget.appProvider.getCompanies(),
            builder: (context, snapshot) {
              final allCompanies = snapshot.data ?? [];
              final currentUser = widget.appProvider.currentUser;

              // Filter companies to only show those where the current user is a member
              final companies = allCompanies.where((company) {
                return currentUser != null &&
                    currentUser.companyIds.contains(company.id);
              }).toList();

              // Validate selectedCompanyId is in the filtered list
              if (selectedCompanyId != null &&
                  !companies.any((c) => c.id == selectedCompanyId)) {
                selectedCompanyId = null;
              }

              return AlertDialog(
                title: const Text('Add Employee'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(labelText: 'Name'),
                      ),
                      TextField(
                        controller: emailController,
                        decoration: const InputDecoration(labelText: 'Email'),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      TextField(
                        controller: phoneController,
                        decoration: const InputDecoration(labelText: 'Phone'),
                        keyboardType: TextInputType.phone,
                      ),
                      TextField(
                        controller: passwordController,
                        decoration:
                            const InputDecoration(labelText: 'Password'),
                        obscureText: true,
                      ),
                      const SizedBox(height: 16),
                      // Replaced dropdown with informational card that uses admin's current company
                      Builder(builder: (context) {
                        final currentCompanyId =
                            widget.appProvider.currentUser?.primaryCompanyId;
                        final company = companies.firstWhere(
                          (c) => c.id == currentCompanyId,
                          orElse: () => Company(
                            id: '',
                            name: 'Unknown Company',
                            address: '',
                            createdAt: DateTime.now(),
                            adminUserId: '',
                          ),
                        );
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.business,
                                  color: Colors.blue.shade700, size: 24),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Will be added to:',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      company.name,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue.shade900,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
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
                      if (nameController.text.isNotEmpty &&
                          emailController.text.isNotEmpty &&
                          phoneController.text.isNotEmpty &&
                          passwordController.text.isNotEmpty) {
                        final currentCompanyId =
                            widget.appProvider.currentUser?.primaryCompanyId;
                        final selectedCompany = companies.firstWhere(
                          (c) => c.id == currentCompanyId,
                          orElse: () => Company(
                            id: '',
                            name: 'Unknown Company',
                            address: '',
                            createdAt: DateTime.now(),
                            adminUserId: '',
                          ),
                        );

                        final companyIds = currentCompanyId != null
                            ? [currentCompanyId]
                            : <String>[];
                        final companyNames = currentCompanyId != null
                            ? [selectedCompany.name]
                            : <String>[];

                        final user = User(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          name: nameController.text,
                          email: emailController.text,
                          phoneNumber: phoneController.text,
                          role: UserRole.employee,
                          createdAt: DateTime.now(),
                          totalPoints: 0,
                          companyIds: companyIds,
                          companyNames: companyNames,
                          primaryCompanyId: currentCompanyId,
                        );
                        await widget.appProvider.addUser(user);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Employee added successfully' +
                                (selectedCompany != null
                                    ? ' to ${selectedCompany.name}'
                                    : '')),
                          ),
                        );
                      }
                    },
                    child: const Text('Add'),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  void _showRoleFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter by Role'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String?>(
              title: const Text('All Roles'),
              value: null,
              groupValue: _filterRole,
              onChanged: (value) {
                setState(() {
                  _filterRole = value;
                });
                Navigator.pop(context);
              },
            ),
            const Divider(),
            RadioListTile<String?>(
              title: const Text('Admins Only'),
              value: 'admin',
              groupValue: _filterRole,
              onChanged: (value) {
                setState(() {
                  _filterRole = value;
                });
                Navigator.pop(context);
              },
            ),
            RadioListTile<String?>(
              title: const Text('Employees Only'),
              value: 'employee',
              groupValue: _filterRole,
              onChanged: (value) {
                setState(() {
                  _filterRole = value;
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.customTitle ?? 'Employees List'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Show role filter icon when not in selection mode
          if (!_isSelectionMode)
            IconButton(
              icon: Icon(
                _filterRole != null ? Icons.filter_alt : Icons.filter_list,
              ),
              onPressed: _showRoleFilterDialog,
              tooltip: 'Filter by Role',
            ),
          // Hide selection mode toggle when in read-only mode
          if (!widget.readOnly)
            _isSelectionMode
                ? IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _toggleSelectionMode,
                    tooltip: 'Cancel Selection',
                  )
                : IconButton(
                    icon: const Icon(Icons.checklist),
                    onPressed: _toggleSelectionMode,
                    tooltip: 'Select Employees',
                  ),
        ],
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, child) {
          // Force fresh data each time Consumer rebuilds
          return FutureBuilder<List<User>>(
            key: ValueKey(provider
                .pointsTransactions.length), // Changes when points update
            future: provider.getUsers(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              var employees = snapshot.data!
                  .where((u) =>
                      u.role == UserRole.employee || u.role == UserRole.admin)
                  .toList();

              // Always filter by current company
              final activeCompanyFilter = widget.filterCompanyId ??
                  provider.currentUser?.primaryCompanyId;

              if (activeCompanyFilter != null) {
                employees = employees
                    .where((u) => u.companyIds.contains(activeCompanyFilter))
                    .toList();
              }

              // Filter by role if role filter is active
              if (_filterRole != null) {
                final targetRole =
                    _filterRole == 'admin' ? UserRole.admin : UserRole.employee;
                employees = employees
                    .where((u) =>
                        u.getRoleForCompany(activeCompanyFilter) == targetRole)
                    .toList();
              }

              // Filter by search query
              if (_searchQuery.isNotEmpty) {
                employees = employees
                    .where((u) =>
                        u.name
                            .toLowerCase()
                            .contains(_searchQuery.toLowerCase()) ||
                        u.email
                            .toLowerCase()
                            .contains(_searchQuery.toLowerCase()))
                    .toList();
              }

              // Update employee IDs for selection
              final currentUserId = widget.appProvider.currentUser?.id;
              _allEmployeeIds = employees
                  .where((e) => e.id != currentUserId)
                  .map((e) => e.id)
                  .toList();

              return Column(
                children: [
                  // Search bar
                  if (!_isSelectionMode)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search by name or email...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    setState(() {
                                      _searchController.clear();
                                      _searchQuery = '';
                                    });
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                      ),
                    ),
                  // Select All and selection count bar
                  if (_isSelectionMode)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      color: Colors.blue.shade50,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: _toggleSelectAll,
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.blue,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                            ),
                            child: Text(
                              (_selectedEmployeeIds.length ==
                                          _allEmployeeIds.length &&
                                      _allEmployeeIds.isNotEmpty)
                                  ? 'Deselect All'
                                  : 'Select All',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            '${_selectedEmployeeIds.length} Selected',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  // Employee list
                  Expanded(
                    child: ListView.builder(
                      padding: _isSelectionMode
                          ? const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8)
                          : const EdgeInsets.all(16),
                      itemCount: employees.length,
                      itemBuilder: (context, index) {
                        final employee = employees[index];
                        // Get company-specific points based on active filter
                        final displayCompanyId = activeCompanyFilter ??
                            provider.currentUser?.primaryCompanyId;
                        final userPoints = displayCompanyId != null
                            ? provider.getUserCompanyPoints(
                                employee.id, displayCompanyId)
                            : 0;
                        final isSelected =
                            _selectedEmployeeIds.contains(employee.id);
                        final isCurrentUser =
                            widget.appProvider.currentUser?.id == employee.id;

                        return Card(
                          color:
                              isSelected ? Colors.blue.shade50 : Colors.white,
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            onTap: () {
                              if (_isSelectionMode && !isCurrentUser) {
                                _toggleEmployeeSelection(employee.id);
                              } else if (!_isSelectionMode) {
                                // Navigate to employee profile/detail view
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EmployeeProfileScreen(
                                      employee: employee,
                                      appProvider: provider,
                                      companyContext:
                                          displayCompanyId, // Pass the company context
                                      readOnly: widget
                                          .readOnly, // Pass read-only mode from parent
                                    ),
                                  ),
                                );
                              }
                            },
                            leading: CircleAvatar(
                              backgroundColor: employee.role == UserRole.admin
                                  ? Colors.purple
                                  : Colors.blue,
                              child: Text(
                                employee.name.isNotEmpty
                                    ? employee.name[0].toUpperCase()
                                    : 'E',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            title: Text(
                              employee.name,
                              style: TextStyle(
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: isSelected
                                    ? Colors.blue.shade700
                                    : Colors.black87,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(employee.email),
                                Text(
                                  employee.role == UserRole.admin
                                      ? 'Admin • $userPoints points'
                                      : '$userPoints points',
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.blue.shade600
                                        : Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            trailing: _isSelectionMode && !isCurrentUser
                                ? ElevatedButton(
                                    onPressed: () =>
                                        _toggleEmployeeSelection(employee.id),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isSelected
                                          ? Colors.blue
                                          : Colors.grey.shade300,
                                      foregroundColor: isSelected
                                          ? Colors.white
                                          : Colors.black87,
                                      minimumSize: const Size(40, 32),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 8),
                                    ),
                                    child: Text(
                                      isSelected ? 'Selected' : 'Select',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  )
                                : _isSelectionMode && isCurrentUser
                                    ? Container(
                                        width: 40,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade200,
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: const Center(
                                          child: Icon(Icons.lock,
                                              size: 16, color: Colors.grey),
                                        ),
                                      )
                                    : Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            employee.role == UserRole.admin
                                                ? Icons.admin_panel_settings
                                                : Icons.person,
                                            color:
                                                employee.role == UserRole.admin
                                                    ? Colors.purple
                                                    : Colors.blue,
                                          ),
                                          const SizedBox(width: 8),
                                          const Icon(
                                            Icons.arrow_forward_ios,
                                            size: 16,
                                            color: Colors.grey,
                                          ),
                                        ],
                                      ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
      floatingActionButton: widget.readOnly
          ? null
          : _isSelectionMode
              ? (_selectedEmployeeIds.isNotEmpty
                  ? FloatingActionButton(
                      onPressed: _showDeleteSelectedDialog,
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      child: const Icon(Icons.delete),
                    )
                  : null)
              : Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    FloatingActionButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ImportEmployeesScreen(
                              appProvider: widget.appProvider,
                            ),
                          ),
                        );
                      },
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      heroTag: 'import_employees',
                      child: const Icon(Icons.upload_file),
                    ),
                    const SizedBox(width: 16),
                    FloatingActionButton(
                      onPressed: _showAddEmployeeDialog,
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      heroTag: 'add_employee',
                      child: const Icon(Icons.person_add),
                    ),
                  ],
                ),
    );
  }
}

class WorkplacesListScreen extends StatefulWidget {
  final AppProvider appProvider;
  const WorkplacesListScreen({super.key, required this.appProvider});

  @override
  State<WorkplacesListScreen> createState() => _WorkplacesListScreenState();
}

class _WorkplacesListScreenState extends State<WorkplacesListScreen> {
  Set<String> _selectedWorkplaceIds = <String>{};
  bool _isSelectionMode = false;
  List<String> _allWorkplaceIds = [];

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedWorkplaceIds.clear();
      }
    });
  }

  void _selectAllWorkplaces() {
    setState(() {
      _selectedWorkplaceIds = _allWorkplaceIds.toSet();
    });
  }

  void _deselectAllWorkplaces() {
    setState(() {
      _selectedWorkplaceIds.clear();
    });
  }

  void _toggleSelectAll() {
    if (_selectedWorkplaceIds.length == _allWorkplaceIds.length &&
        _allWorkplaceIds.isNotEmpty) {
      _deselectAllWorkplaces();
    } else {
      _selectAllWorkplaces();
    }
  }

  void _toggleWorkplaceSelection(String workplaceId) {
    setState(() {
      if (_selectedWorkplaceIds.contains(workplaceId)) {
        _selectedWorkplaceIds.remove(workplaceId);
      } else {
        _selectedWorkplaceIds.add(workplaceId);
      }
    });
  }

  void _showDeleteSelectedDialog() {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('Delete Selected Workplaces'),
        content: Text(
          'Are you sure you want to delete ${_selectedWorkplaceIds.length} selected workplaces? This action cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final count = _selectedWorkplaceIds.length;
              try {
                for (String id in List.from(_selectedWorkplaceIds)) {
                  await widget.appProvider.deleteWorkplace(id);
                }
                setState(() {
                  _selectedWorkplaceIds.clear();
                  _isSelectionMode = false;
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$count workplaces deleted'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Couldn\'t delete workplaces: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAddWorkplaceDialog() {
    final nameController = TextEditingController();
    final addressController = TextEditingController();

    showDialog(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Add Workplace'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Workplace Name'),
              ),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(labelText: 'Address'),
                maxLines: 3,
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
              if (nameController.text.isNotEmpty &&
                  addressController.text.isNotEmpty) {
                final newWorkplace = Workplace(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: nameController.text,
                  address: addressController.text,
                  createdAt: DateTime.now(),
                  companyId: widget.appProvider.currentUser?.primaryCompanyId,
                );
                await widget.appProvider.addWorkplace(newWorkplace);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Workplace added')));
              }
            },
            child: Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext c) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Workplaces List'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(c),
        ),
        actions: [
          _isSelectionMode
              ? IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _toggleSelectionMode,
                )
              : IconButton(
                  icon: const Icon(Icons.checklist),
                  onPressed: _toggleSelectionMode,
                ),
        ],
      ),
      floatingActionButton: _isSelectionMode
          ? _selectedWorkplaceIds.isNotEmpty
              ? FloatingActionButton(
                  onPressed: _showDeleteSelectedDialog,
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  child: const Icon(Icons.delete),
                )
              : null
          : FloatingActionButton(
              onPressed: _showAddWorkplaceDialog,
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              child: const Icon(Icons.business),
            ),
      body: Consumer<AppProvider>(builder: (context, provider, child) {
        return FutureBuilder<List<Workplace>>(
          key: ValueKey(provider.workplaces.length),
          future: provider.getWorkplaces(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final allWorkplaces = snapshot.data!;
            final currentUser = provider.currentUser;

            // Filter workplaces to only show those from the currently active company
            final workplaces = allWorkplaces.where((workplace) {
              return currentUser != null &&
                  workplace.companyId == currentUser.primaryCompanyId;
            }).toList();

            _allWorkplaceIds = workplaces.map((w) => w.id).toList();

            return Column(
              children: [
                // Select All and count bar
                if (_isSelectionMode)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    color: Colors.blue.shade50,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: _toggleSelectAll,
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.blue,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                          ),
                          child: Text(
                            (_selectedWorkplaceIds.length ==
                                        _allWorkplaceIds.length &&
                                    _allWorkplaceIds.isNotEmpty)
                                ? 'Deselect All'
                                : 'Select All',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          '${_selectedWorkplaceIds.length} Selected',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                // Workplace list
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: workplaces.length,
                    itemBuilder: (context, index) {
                      final workplace = workplaces[index];
                      final isSelected =
                          _selectedWorkplaceIds.contains(workplace.id);

                      return Card(
                        color: isSelected ? Colors.blue.shade50 : Colors.white,
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          onTap: () {
                            if (_isSelectionMode) {
                              _toggleWorkplaceSelection(workplace.id);
                            } else {
                              // Navigate to existing Store Profile screen instead of new WorkplaceProfileScreen
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => StoreProfileScreen(
                                    workplace: workplace,
                                    appProvider: widget.appProvider,
                                  ),
                                ),
                              );
                            }
                          },
                          leading: CircleAvatar(
                            backgroundColor: Colors.orange,
                            child: Icon(Icons.business, color: Colors.white),
                          ),
                          title: Text(
                            workplace.name,
                            style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color: isSelected
                                  ? Colors.blue.shade700
                                  : Colors.black87,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                workplace.address,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.blue.shade600
                                      : Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                'Created: ${DateFormat('MMM dd, yyyy').format(workplace.createdAt)}',
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.blue.shade600
                                      : Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          trailing: _isSelectionMode
                              ? ElevatedButton(
                                  onPressed: () =>
                                      _toggleWorkplaceSelection(workplace.id),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isSelected
                                        ? Colors.blue
                                        : Colors.grey.shade300,
                                    foregroundColor: isSelected
                                        ? Colors.white
                                        : Colors.black87,
                                    minimumSize: const Size(40, 32),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                  ),
                                  child: Text(
                                    isSelected ? 'Selected' : 'Select',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                )
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.business, color: Colors.orange),
                                    const SizedBox(width: 8),
                                    const Icon(
                                      Icons.arrow_forward_ios,
                                      size: 16,
                                      color: Colors.grey,
                                    ),
                                  ],
                                ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      }),
    );
  }
}
