import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../models/sales_target.dart';
import '../models/bonus.dart';
import '../models/user.dart';
import '../models/country.dart';
import '../models/points_transaction.dart';
import '../widgets/profile_header_widget.dart';

class EmployeeDashboard extends StatefulWidget {
  const EmployeeDashboard({super.key});

  @override
  State<EmployeeDashboard> createState() => _EmployeeDashboardState();
}

class _EmployeeDashboardState extends State<EmployeeDashboard> {
  int _selectedIndex = 0;

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
        final employees =
            snapshot.data!.where((user) => user.role == UserRole.employee).toList();

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: employees.length,
          itemBuilder: (context, index) {
            final employee = employees[index];
            final points = appProvider.getUserTotalPoints(employee.id);
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

  Widget _buildReportsTab(
      List<SalesTarget> targets, List<PointsTransaction> transactions) {
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
                  const Text(
                    'Targets Summary',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text('Total Targets: ${targets.length}'),
                  Text(
                      'Completed: ${targets.where((t) => t.isApproved).length}'),
                  Text(
                      'Pending: ${targets.where((t) => !t.isApproved).length}'),
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
                    'Points Summary',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text('Total Transactions: ${transactions.length}'),
                  Text(
                      'Earned: ${transactions.where((t) => t.type.name == 'earned').length}'),
                  Text(
                      'Spent: ${transactions.where((t) => t.type.name == 'spent').length}'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        final user = appProvider.currentUser!;
        final userPoints = appProvider.getUserTotalPoints(user.id);
        final todaysTargets = appProvider.getTodaysTargetsForEmployee(user.id);
        final allTargets = appProvider.salesTargets;
        final allTransactions = appProvider.pointsTransactions;
        final availableBonuses = appProvider.getAvailableBonuses();
        final redeemedBonuses = appProvider.getUserRedeemedBonuses(user.id);

        return Scaffold(
          appBar: AppBar(
            title: Text('Employee Dashboard'),
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
                onProfileTap: () => setState(() => _selectedIndex = 4), // Navigate to Profile tab
                actionButtons: _getEmployeeActionButtons(context, appProvider),
              ),
              // Main Content
              Expanded(
                child: IndexedStack(
                  index: _selectedIndex,
                  children: [
                    _buildOverviewTab(userPoints, todaysTargets, user.id),
                    _buildTargetsTab(appProvider, allTargets),
                    _buildBonusesTab(
                        availableBonuses, redeemedBonuses, user.id, userPoints),
                    _buildReportsTab(allTargets, allTransactions),
                    _buildProfileTab(user, appProvider),
                  ],
                ),
              ),
            ],
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (index) => setState(() => _selectedIndex = index),
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
                icon: Icon(Icons.track_changes),
                label: 'Targets',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.card_giftcard),
                label: 'Bonuses',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.analytics),
                label: 'Reports',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOverviewTab(
      int userPoints, List<SalesTarget> todaysTargets, String userId) {
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
                  Text(
                    'Your Points',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$userPoints',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Today\'s Sales Targets',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          if (todaysTargets.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'No sales targets set for today',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ),
            )
          else
            ...todaysTargets.map((target) => _buildTargetCard(target, userId)),
        ],
      ),
    );
  }

  Widget _buildTargetCard(SalesTarget target, String userId) {
    final progress = target.targetAmount > 0
        ? target.actualAmount / target.targetAmount
        : 0.0;
    final isMet = target.isMet;
    final percentageAbove = target.percentageAboveTarget;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
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
            LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                isMet ? Colors.green : Colors.orange,
              ),
            ),
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
                      : target.isApproved
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
                                    'Approved & Points Awarded',
                                    style: TextStyle(
                                      color: Colors.green[700],
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
                                    'Pending Admin Approval',
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
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: transaction.type.name == 'earned'
                  ? Colors.green
                  : Colors.orange,
              child: Icon(
                transaction.type.name == 'earned' ? Icons.add : Icons.remove,
                color: Colors.white,
              ),
            ),
            title: Text(transaction.description),
            subtitle: Text(
                DateFormat('MMM dd, yyyy - HH:mm').format(transaction.date)),
            trailing: Text(
              '${transaction.type.name == 'earned' ? '+' : '-'}${transaction.points}',
              style: TextStyle(
                color: transaction.type.name == 'earned'
                    ? Colors.green
                    : Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBonusesTab(List<Bonus> availableBonuses,
      List<Bonus> redeemedBonuses, String userId, int userPoints) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            tabs: const [
              Tab(text: 'Available'),
              Tab(text: 'Redeemed'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildAvailableBonuses(availableBonuses, userPoints, userId),
                _buildRedeemedBonuses(redeemedBonuses),
              ],
            ),
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
              child: Icon(
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
      text: selectedCountry != null && user.phoneNumber != null
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
                              '${country.phonePrefix}',
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

  List<ActionButton> _getEmployeeActionButtons(BuildContext context, AppProvider appProvider) {
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
        icon: Icons.analytics,
        label: 'Reports',
        color: Colors.green,
        onTap: () => setState(() => _selectedIndex = 3),
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
                      u.role == UserRole.employee && u.id != widget.userId)
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
        ElevatedButton(
          onPressed: () {
            print('DEBUG: Dialog Save - Selected IDs: $selectedEmployeeIds');
            print(
                'DEBUG: Dialog Save - Selected Names: $selectedEmployeeNames');

            final user = context.read<AppProvider>().currentUser!;
            context.read<AppProvider>().submitTeamChange(
                  widget.target.id,
                  List<String>.from(selectedEmployeeIds),
                  List<String>.from(selectedEmployeeNames),
                  user.id,
                );

            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Team change submitted for admin approval!'),
                backgroundColor: Colors.orange,
              ),
            );
          },
          child: const Text('Submit for Approval'),
        ),
      ],
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
              Navigator.pop(context);
              appProvider.logout();
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
