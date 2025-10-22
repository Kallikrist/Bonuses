import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/user.dart';
import '../models/company.dart';
import '../models/subscription_tier.dart';
import '../models/company_subscription.dart';
import '../models/platform_metrics.dart';
import '../models/sales_target.dart';
import '../models/points_transaction.dart';
import '../models/payment_record.dart';
import '../services/storage_service.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class SuperAdminDashboard extends StatefulWidget {
  const SuperAdminDashboard({super.key});

  @override
  State<SuperAdminDashboard> createState() => _SuperAdminDashboardState();
}

class _SuperAdminDashboardState extends State<SuperAdminDashboard> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Platform Administration'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildOverviewTab(),
          _buildCompaniesTab(),
          _buildSubscriptionsTab(),
          _buildAnalyticsTab(),
          _buildSettingsTab(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Overview',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.business),
            label: 'Companies',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.subscriptions),
            label: 'Subscriptions',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Analytics',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        return FutureBuilder<Map<String, dynamic>>(
          future: _getPlatformOverview(appProvider),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData) {
              return const Center(
                child: Text('Error loading platform data'),
              );
            }

            final data = snapshot.data!;
            final totalCompanies = data['totalCompanies'] as int;
            final activeCompanies = data['activeCompanies'] as int;
            final totalEmployees = data['totalEmployees'] as int;
            final monthlyRevenue = data['monthlyRevenue'] as double;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Platform Stats Cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Total Companies',
                          totalCompanies.toString(),
                          Icons.business,
                          Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          'Active Companies',
                          activeCompanies.toString(),
                          Icons.business_center,
                          Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Total Employees',
                          totalEmployees.toString(),
                          Icons.people,
                          Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          'Monthly Revenue',
                          '\$${monthlyRevenue.toStringAsFixed(0)}',
                          Icons.attach_money,
                          Colors.purple,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Recent Activity
                  Text(
                    'Recent Activity',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
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
                            'Platform Status: Operational',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'All systems are running normally. No issues detected.',
                            style: TextStyle(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCompaniesTab() {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        return FutureBuilder<List<Company>>(
          future: appProvider.getCompanies(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Text('No companies found'),
              );
            }

            final companies = snapshot.data!;

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: companies.length,
              itemBuilder: (context, index) {
                final company = companies[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          company.isActive ? Colors.green : Colors.red,
                      child: Text(
                        company.name[0].toUpperCase(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Row(
                      children: [
                        Expanded(child: Text(company.name)),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: company.isActive
                                ? Colors.green.shade100
                                : Colors.red.shade100,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color:
                                  company.isActive ? Colors.green : Colors.red,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            company.isActive ? 'Active' : 'Suspended',
                            style: TextStyle(
                              color: company.isActive
                                  ? Colors.green.shade700
                                  : Colors.red.shade700,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ID: ${company.id}'),
                        if (company.contactEmail != null)
                          Text('Email: ${company.contactEmail}'),
                        Text(
                            'Created: ${company.createdAt.toString().split(' ')[0]}'),
                      ],
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        // Handle company actions
                        _handleCompanyAction(value, company);
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'view',
                          child: Text('View Details'),
                        ),
                        if (company.isActive)
                          const PopupMenuItem(
                            value: 'suspend',
                            child: Text('Suspend'),
                          )
                        else
                          const PopupMenuItem(
                            value: 'activate',
                            child: Text('Activate'),
                          ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Delete',
                              style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildSubscriptionsTab() {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        return FutureBuilder<Map<String, dynamic>>(
          future: _getSubscriptionsData(appProvider),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData) {
              return const Center(
                child: Text('Error loading subscriptions'),
              );
            }

            final data = snapshot.data!;
            final subscriptions =
                data['subscriptions'] as List<CompanySubscription>;
            final companies = data['companies'] as List<Company>;
            final tiers = data['tiers'] as List<SubscriptionTier>;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with stats
                  _buildSubscriptionStats(subscriptions),
                  const SizedBox(height: 24),

                  // Available Tiers
                  _buildAvailableTiers(tiers),
                  const SizedBox(height: 24),

                  // Subscriptions List
                  _buildSubscriptionsList(
                      subscriptions, companies, tiers, appProvider),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSubscriptionStats(List<CompanySubscription> subscriptions) {
    final activeCount = subscriptions
        .where((s) => s.status == SubscriptionStatus.active)
        .length;
    final trialCount =
        subscriptions.where((s) => s.status == SubscriptionStatus.trial).length;
    final pastDueCount = subscriptions
        .where((s) => s.status == SubscriptionStatus.pastDue)
        .length;
    final totalRevenue = subscriptions
        .where((s) => s.status == SubscriptionStatus.active)
        .fold<double>(0, (sum, s) => sum + s.currentPrice);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Subscription Overview',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Active',
                    activeCount.toString(),
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Trial',
                    trialCount.toString(),
                    Icons.access_time,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Past Due',
                    pastDueCount.toString(),
                    Icons.warning,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'MRR',
                    '\$${totalRevenue.toStringAsFixed(0)}',
                    Icons.attach_money,
                    Colors.purple,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailableTiers(List<SubscriptionTier> tiers) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Available Plans',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: () => _showManageTiersDialog(),
                  icon: const Icon(Icons.settings),
                  label: const Text('Manage Plans'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: tiers.map((tier) => _buildTierCard(tier)).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTierCard(SubscriptionTier tier) {
    return Container(
      width: 250,
      margin: const EdgeInsets.only(right: 12),
      child: Card(
        elevation: 2,
        color: tier.isActive ? null : Colors.grey[200],
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    tier.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (!tier.isActive)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Inactive',
                        style: TextStyle(color: Colors.white, fontSize: 10),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                tier.description,
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '\$${tier.monthlyPrice.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                  const Text('/mo', style: TextStyle(color: Colors.grey)),
                ],
              ),
              if (tier.yearlyPrice != null) ...[
                const SizedBox(height: 4),
                Text(
                  '\$${tier.yearlyPrice!.toStringAsFixed(0)}/yr',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
              const SizedBox(height: 12),
              ...tier.features.take(3).map((feature) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Icon(Icons.check, size: 16, color: Colors.green[600]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            feature,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  )),
              if (tier.features.length > 3)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '+${tier.features.length - 3} more',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubscriptionsList(
    List<CompanySubscription> subscriptions,
    List<Company> companies,
    List<SubscriptionTier> tiers,
    AppProvider appProvider,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Active Subscriptions',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showCreateSubscriptionDialog(
                      companies, tiers, appProvider),
                  icon: const Icon(Icons.add),
                  label: const Text('New Subscription'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (subscriptions.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text(
                    'No subscriptions yet',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: subscriptions.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final subscription = subscriptions[index];
                  final company = companies.firstWhere(
                    (c) => c.id == subscription.companyId,
                    orElse: () => Company(
                      id: '',
                      name: 'Unknown',
                      adminUserId: '',
                      createdAt: DateTime.now(),
                    ),
                  );
                  final tier = tiers.firstWhere(
                    (t) => t.id == subscription.tierId,
                    orElse: () => SubscriptionTier.free,
                  );

                  return _buildSubscriptionListItem(
                    subscription,
                    company,
                    tier,
                    appProvider,
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionListItem(
    CompanySubscription subscription,
    Company company,
    SubscriptionTier tier,
    AppProvider appProvider,
  ) {
    final statusColor = _getStatusColor(subscription.status);
    final statusIcon = _getStatusIcon(subscription.status);

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: statusColor.withOpacity(0.2),
        child: Icon(statusIcon, color: statusColor),
      ),
      title: Text(
        company.name,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Plan: ${tier.name} (${subscription.billingInterval.name})'),
          Text('\$${subscription.currentPrice}/month'),
          if (subscription.isTrial && subscription.daysUntilTrialEnds != null)
            Text(
              'Trial ends in ${subscription.daysUntilTrialEnds} days',
              style: const TextStyle(color: Colors.orange),
            ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              subscription.status.name.toUpperCase(),
              style: TextStyle(
                color: statusColor,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) => _handleSubscriptionAction(
              value,
              subscription,
              company,
              tier,
              appProvider,
            ),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'view',
                child: Row(
                  children: [
                    Icon(Icons.visibility, size: 18),
                    SizedBox(width: 8),
                    Text('View Details'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'change_plan',
                child: Row(
                  children: [
                    Icon(Icons.swap_horiz, size: 18),
                    SizedBox(width: 8),
                    Text('Change Plan'),
                  ],
                ),
              ),
              if (subscription.status != SubscriptionStatus.cancelled)
                const PopupMenuItem(
                  value: 'cancel',
                  child: Row(
                    children: [
                      Icon(Icons.cancel, size: 18, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Cancel Subscription'),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(SubscriptionStatus status) {
    switch (status) {
      case SubscriptionStatus.active:
        return Colors.green;
      case SubscriptionStatus.trial:
        return Colors.blue;
      case SubscriptionStatus.pastDue:
        return Colors.orange;
      case SubscriptionStatus.suspended:
        return Colors.red;
      case SubscriptionStatus.cancelled:
      case SubscriptionStatus.expired:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(SubscriptionStatus status) {
    switch (status) {
      case SubscriptionStatus.active:
        return Icons.check_circle;
      case SubscriptionStatus.trial:
        return Icons.access_time;
      case SubscriptionStatus.pastDue:
        return Icons.warning;
      case SubscriptionStatus.suspended:
        return Icons.block;
      case SubscriptionStatus.cancelled:
      case SubscriptionStatus.expired:
        return Icons.cancel;
    }
  }

  Future<Map<String, dynamic>> _getSubscriptionsData(
      AppProvider appProvider) async {
    final subscriptions = await StorageService.getSubscriptions();
    final companies = await appProvider.getCompanies();
    final tiers = SubscriptionTier.defaultTiers;

    return {
      'subscriptions': subscriptions,
      'companies': companies,
      'tiers': tiers,
    };
  }

  void _showManageTiersDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Manage Subscription Tiers'),
        content: SizedBox(
          width: 600,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Available subscription tiers are currently using default values. '
                  'Custom tier management will be available in a future update.',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Current Tiers:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),
                ...SubscriptionTier.defaultTiers.map((tier) => Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.deepPurple,
                          child: Text(
                            '\$${tier.monthlyPrice.toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(tier.name),
                        subtitle: Text(
                          '${tier.maxEmployees == -1 ? "Unlimited" : tier.maxEmployees} employees, '
                          '${tier.maxWorkplaces == -1 ? "Unlimited" : tier.maxWorkplaces} workplaces',
                        ),
                        trailing: tier.isActive
                            ? const Chip(
                                label: Text('Active'),
                                backgroundColor: Colors.green,
                                labelStyle: TextStyle(
                                    color: Colors.white, fontSize: 11),
                              )
                            : const Chip(
                                label: Text('Inactive'),
                                backgroundColor: Colors.grey,
                                labelStyle: TextStyle(
                                    color: Colors.white, fontSize: 11),
                              ),
                      ),
                    )),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showCreateSubscriptionDialog(
    List<Company> companies,
    List<SubscriptionTier> tiers,
    AppProvider appProvider,
  ) async {
    // Filter companies that don't have active subscriptions
    final subscriptions = await StorageService.getSubscriptions();
    final companiesWithoutSub = companies.where((company) {
      return !subscriptions.any((sub) =>
          sub.companyId == company.id &&
          (sub.status == SubscriptionStatus.active ||
              sub.status == SubscriptionStatus.trial));
    }).toList();

    if (!mounted) return;

    String? selectedCompanyId;
    String? selectedTierId = tiers.first.id;
    BillingInterval selectedInterval = BillingInterval.monthly;
    PaymentMethod selectedPaymentMethod = PaymentMethod.creditCard;
    SubscriptionStatus selectedStatus = SubscriptionStatus.trial;
    int trialDays = 14;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final selectedTier = tiers.firstWhere(
            (t) => t.id == selectedTierId,
            orElse: () => tiers.first,
          );

          final price = selectedInterval == BillingInterval.monthly
              ? selectedTier.monthlyPrice
              : (selectedTier.yearlyPrice ?? selectedTier.monthlyPrice * 12);

          return AlertDialog(
            title: const Text('Create New Subscription'),
            content: SizedBox(
              width: 500,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Company Selection
                    const Text(
                      'Select Company',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    if (companiesWithoutSub.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          border: Border.all(color: Colors.orange),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.orange[700]),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'All companies already have active subscriptions',
                                style: TextStyle(fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      DropdownButtonFormField<String>(
                        value: selectedCompanyId,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Choose a company',
                        ),
                        items: companiesWithoutSub.map((company) {
                          return DropdownMenuItem(
                            value: company.id,
                            child: Text(company.name),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => selectedCompanyId = value);
                        },
                      ),
                    const SizedBox(height: 20),

                    // Subscription Tier
                    const Text(
                      'Subscription Tier',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: selectedTierId,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      items: tiers.where((t) => t.isActive).map((tier) {
                        return DropdownMenuItem(
                          value: tier.id,
                          child: Row(
                            children: [
                              Text(tier.name),
                              const SizedBox(width: 8),
                              Text(
                                '- \$${tier.monthlyPrice.toStringAsFixed(0)}/mo',
                                style: const TextStyle(
                                    color: Colors.grey, fontSize: 12),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => selectedTierId = value);
                      },
                    ),
                    const SizedBox(height: 20),

                    // Billing Interval
                    const Text(
                      'Billing Interval',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    SegmentedButton<BillingInterval>(
                      segments: const [
                        ButtonSegment(
                          value: BillingInterval.monthly,
                          label: Text('Monthly'),
                          icon: Icon(Icons.calendar_month),
                        ),
                        ButtonSegment(
                          value: BillingInterval.yearly,
                          label: Text('Yearly'),
                          icon: Icon(Icons.calendar_today),
                        ),
                      ],
                      selected: {selectedInterval},
                      onSelectionChanged: (Set<BillingInterval> newSelection) {
                        setState(() {
                          selectedInterval = newSelection.first;
                        });
                      },
                    ),
                    const SizedBox(height: 20),

                    // Status
                    const Text(
                      'Initial Status',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<SubscriptionStatus>(
                      value: selectedStatus,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: SubscriptionStatus.trial,
                          child: Row(
                            children: [
                              Icon(Icons.access_time,
                                  size: 16, color: Colors.amber),
                              SizedBox(width: 8),
                              Text('Trial'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: SubscriptionStatus.active,
                          child: Row(
                            children: [
                              Icon(Icons.check_circle,
                                  size: 16, color: Colors.green),
                              SizedBox(width: 8),
                              Text('Active'),
                            ],
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() => selectedStatus = value!);
                      },
                    ),
                    const SizedBox(height: 20),

                    // Trial Days (only show if status is trial)
                    if (selectedStatus == SubscriptionStatus.trial) ...[
                      const Text(
                        'Trial Duration (days)',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        initialValue: trialDays.toString(),
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          suffixText: 'days',
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          final parsed = int.tryParse(value);
                          if (parsed != null && parsed > 0) {
                            trialDays = parsed;
                          }
                        },
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Payment Method
                    const Text(
                      'Payment Method',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<PaymentMethod>(
                      value: selectedPaymentMethod,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: PaymentMethod.creditCard,
                          child: Row(
                            children: [
                              Icon(Icons.credit_card, size: 16),
                              SizedBox(width: 8),
                              Text('Credit Card'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: PaymentMethod.debitCard,
                          child: Row(
                            children: [
                              Icon(Icons.credit_card, size: 16),
                              SizedBox(width: 8),
                              Text('Debit Card'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: PaymentMethod.bankTransfer,
                          child: Row(
                            children: [
                              Icon(Icons.account_balance, size: 16),
                              SizedBox(width: 8),
                              Text('Bank Transfer'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: PaymentMethod.paypal,
                          child: Row(
                            children: [
                              Icon(Icons.payment, size: 16),
                              SizedBox(width: 8),
                              Text('PayPal'),
                            ],
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() => selectedPaymentMethod = value!);
                      },
                    ),
                    const SizedBox(height: 20),

                    // Summary
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Summary',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildSummaryRow(
                              'Tier:', selectedTier.name, Colors.blue),
                          _buildSummaryRow(
                            'Price:',
                            '\$${price.toStringAsFixed(2)}/${selectedInterval == BillingInterval.monthly ? "mo" : "yr"}',
                            Colors.green,
                          ),
                          if (selectedStatus == SubscriptionStatus.trial)
                            _buildSummaryRow(
                              'Trial:',
                              '$trialDays days free',
                              Colors.amber,
                            ),
                          _buildSummaryRow(
                            'Next Billing:',
                            _formatNextBillingDate(
                                selectedStatus, trialDays, selectedInterval),
                            Colors.grey[700]!,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: selectedCompanyId == null
                    ? null
                    : () async {
                        try {
                          final now = DateTime.now();
                          final startDate = now;
                          final nextBillingDate =
                              selectedStatus == SubscriptionStatus.trial
                                  ? now.add(Duration(days: trialDays))
                                  : selectedInterval == BillingInterval.monthly
                                      ? now.add(const Duration(days: 30))
                                      : now.add(const Duration(days: 365));

                          final newSubscription = CompanySubscription(
                            id: 'sub_${DateTime.now().millisecondsSinceEpoch}',
                            companyId: selectedCompanyId!,
                            tierId: selectedTierId!,
                            startDate: startDate,
                            status: selectedStatus,
                            paymentMethod: selectedPaymentMethod,
                            billingInterval: selectedInterval,
                            nextBillingDate: nextBillingDate,
                            currentPrice: price,
                            gracePeriodDays: 7,
                            createdAt: now,
                            updatedAt: now,
                            trialEndsAt:
                                selectedStatus == SubscriptionStatus.trial
                                    ? now.add(Duration(days: trialDays))
                                    : null,
                          );

                          await StorageService.addSubscription(newSubscription);

                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Subscription created successfully for ${companiesWithoutSub.firstWhere((c) => c.id == selectedCompanyId).name}',
                                ),
                                backgroundColor: Colors.green,
                              ),
                            );
                            // Refresh the view
                            setState(() {});
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content:
                                    Text('Error creating subscription: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Create Subscription'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: Colors.black87),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  String _formatNextBillingDate(
      SubscriptionStatus status, int trialDays, BillingInterval interval) {
    final now = DateTime.now();
    final date = status == SubscriptionStatus.trial
        ? now.add(Duration(days: trialDays))
        : interval == BillingInterval.monthly
            ? now.add(const Duration(days: 30))
            : now.add(const Duration(days: 365));
    return DateFormat('MMM dd, yyyy').format(date);
  }

  void _handleSubscriptionAction(
    String action,
    CompanySubscription subscription,
    Company company,
    SubscriptionTier tier,
    AppProvider appProvider,
  ) {
    switch (action) {
      case 'view':
        _showSubscriptionDetails(subscription, company, tier);
        break;
      case 'change_plan':
        _showChangePlanDialog(subscription, company, appProvider);
        break;
      case 'cancel':
        _confirmCancelSubscription(subscription, company, appProvider);
        break;
    }
  }

  void _showSubscriptionDetails(
    CompanySubscription subscription,
    Company company,
    SubscriptionTier tier,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${company.name} Subscription'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Plan', tier.name),
              _buildDetailRow('Status', subscription.status.name.toUpperCase()),
              _buildDetailRow(
                'Billing',
                '\$${subscription.currentPrice}/${subscription.billingInterval.name}',
              ),
              _buildDetailRow(
                'Start Date',
                DateFormat('MMM d, yyyy').format(subscription.startDate),
              ),
              _buildDetailRow(
                'Next Billing',
                DateFormat('MMM d, yyyy').format(subscription.nextBillingDate),
              ),
              if (subscription.trialEndsAt != null)
                _buildDetailRow(
                  'Trial Ends',
                  DateFormat('MMM d, yyyy').format(subscription.trialEndsAt!),
                ),
              _buildDetailRow(
                  'Payment Method', subscription.paymentMethod.name),
              const Divider(),
              const SizedBox(height: 8),
              const Text(
                'Plan Features:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...tier.features.map((feature) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.check, size: 16, color: Colors.green),
                        const SizedBox(width: 8),
                        Expanded(child: Text(feature)),
                      ],
                    ),
                  )),
              const Divider(),
              const SizedBox(height: 16),
              const Text(
                'Payment History:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              FutureBuilder<List<PaymentRecord>>(
                future:
                    StorageService.getPaymentsBySubscriptionId(subscription.id),
                builder: (context, paymentSnapshot) {
                  if (paymentSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  final payments = paymentSnapshot.data ?? [];

                  if (payments.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(
                        child: Text(
                          'No payment history',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: [
                      ...payments.take(5).map((payment) => Card(
                            color: payment.isSuccessful
                                ? Colors.green.withOpacity(0.1)
                                : Colors.red.withOpacity(0.1),
                            child: ListTile(
                              dense: true,
                              leading: Icon(
                                payment.isSuccessful
                                    ? Icons.check_circle
                                    : Icons.error,
                                color: payment.isSuccessful
                                    ? Colors.green
                                    : Colors.red,
                                size: 20,
                              ),
                              title: Text(
                                '\$${payment.amount.toStringAsFixed(2)}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                DateFormat('MMM d, yyyy').format(payment.date),
                                style: const TextStyle(fontSize: 11),
                              ),
                              trailing: Text(
                                payment.status.name,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: payment.isSuccessful
                                      ? Colors.green
                                      : Colors.red,
                                ),
                              ),
                            ),
                          )),
                      if (payments.length > 5)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Center(
                            child: Text(
                              '+${payments.length - 5} more payments',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  void _showChangePlanDialog(
    CompanySubscription subscription,
    Company company,
    AppProvider appProvider,
  ) {
    // TODO: Implement change plan dialog
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Change plan for ${company.name} - Coming soon'),
      ),
    );
  }

  void _confirmCancelSubscription(
    CompanySubscription subscription,
    Company company,
    AppProvider appProvider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Subscription?'),
        content: Text(
          'Are you sure you want to cancel the subscription for ${company.name}? '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No, Keep Active'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement cancel subscription
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Subscription cancelled for ${company.name}'),
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        return FutureBuilder<PlatformMetrics>(
          future: _calculatePlatformMetrics(appProvider),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData) {
              return const Center(
                child: Text('Error loading analytics'),
              );
            }

            final metrics = snapshot.data!;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Key Metrics Cards
                  _buildKeyMetricsCards(metrics),
                  const SizedBox(height: 24),

                  // Revenue Chart
                  _buildRevenueChart(metrics),
                  const SizedBox(height: 24),

                  // Growth Metrics
                  _buildGrowthMetrics(metrics),
                  const SizedBox(height: 24),

                  // Tier Distribution
                  _buildTierDistribution(metrics),
                  const SizedBox(height: 24),

                  // Platform Activity
                  _buildPlatformActivity(metrics),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildKeyMetricsCards(PlatformMetrics metrics) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Key Platform Metrics',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildMetricCard(
                  'Total Companies',
                  metrics.totalCompanies.toString(),
                  Icons.business,
                  Colors.blue,
                ),
                _buildMetricCard(
                  'Active Companies',
                  metrics.activeCompanies.toString(),
                  Icons.verified,
                  Colors.green,
                ),
                _buildMetricCard(
                  'Total Employees',
                  metrics.totalEmployees.toString(),
                  Icons.people,
                  Colors.purple,
                ),
                _buildMetricCard(
                  'MRR',
                  '\$${metrics.monthlyRecurringRevenue.toStringAsFixed(0)}',
                  Icons.attach_money,
                  Colors.orange,
                ),
                _buildMetricCard(
                  'Total Revenue',
                  '\$${metrics.totalRevenue.toStringAsFixed(0)}',
                  Icons.account_balance,
                  Colors.teal,
                ),
                _buildMetricCard(
                  'Avg Revenue/Company',
                  '\$${metrics.averageRevenuePerCompany.toStringAsFixed(0)}',
                  Icons.trending_up,
                  Colors.indigo,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      width: 180,
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 24),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueChart(PlatformMetrics metrics) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Revenue Trend (Last 12 Months)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 300,
              child: metrics.revenueHistory.isEmpty
                  ? const Center(
                      child: Text(
                        'No revenue data available',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : LineChart(
                      LineChartData(
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: 500,
                          getDrawingHorizontalLine: (value) {
                            return FlLine(
                              color: Colors.grey[300]!,
                              strokeWidth: 1,
                            );
                          },
                        ),
                        titlesData: FlTitlesData(
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 30,
                              getTitlesWidget: (value, meta) {
                                final index = value.toInt();
                                if (index < 0 ||
                                    index >= metrics.revenueHistory.length) {
                                  return const Text('');
                                }
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    metrics.revenueHistory[index].monthName,
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                );
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 50,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  '\$${value.toInt()}',
                                  style: const TextStyle(fontSize: 10),
                                );
                              },
                            ),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: List.generate(
                              metrics.revenueHistory.length,
                              (index) => FlSpot(
                                index.toDouble(),
                                metrics.revenueHistory[index].revenue,
                              ),
                            ),
                            isCurved: true,
                            color: Colors.deepPurple,
                            barWidth: 3,
                            dotData: const FlDotData(show: true),
                            belowBarData: BarAreaData(
                              show: true,
                              color: Colors.deepPurple.withOpacity(0.1),
                            ),
                          ),
                        ],
                        minY: 0,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrowthMetrics(PlatformMetrics metrics) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Growth & Performance',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildProgressCard(
                    'Growth Rate',
                    metrics.growthRate,
                    '%',
                    Colors.green,
                    Icons.trending_up,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildProgressCard(
                    'Churn Rate',
                    metrics.churnRate,
                    '%',
                    Colors.red,
                    Icons.trending_down,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildProgressCard(
                    'Conversion Rate',
                    metrics.conversionRate,
                    '%',
                    Colors.blue,
                    Icons.swap_horiz,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCard(
    String title,
    double value,
    String suffix,
    Color color,
    IconData icon,
  ) {
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
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${value.toStringAsFixed(1)}$suffix',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: (value / 100).clamp(0.0, 1.0),
            backgroundColor: color.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ],
      ),
    );
  }

  Widget _buildTierDistribution(PlatformMetrics metrics) {
    final tiers = SubscriptionTier.defaultTiers;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Subscription Tier Distribution',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...tiers.map((tier) {
              final count = metrics.companiesByTier[tier.id] ?? 0;
              final percentage = metrics.totalCompanies > 0
                  ? (count / metrics.totalCompanies) * 100
                  : 0.0;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          tier.name,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Text(
                          '$count companies (${percentage.toStringAsFixed(0)}%)',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: percentage / 100,
                      backgroundColor: Colors.grey[200],
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.deepPurple),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildPlatformActivity(PlatformMetrics metrics) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Platform Activity',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildActivityRow(
              'Total Targets Created',
              metrics.totalTargetsCreated.toString(),
              Icons.flag,
              Colors.blue,
            ),
            const Divider(),
            _buildActivityRow(
              'Total Bonuses Redeemed',
              metrics.totalBonusesRedeemed.toString(),
              Icons.card_giftcard,
              Colors.orange,
            ),
            const Divider(),
            _buildActivityRow(
              'Total Points Awarded',
              metrics.totalPointsAwarded.toString(),
              Icons.stars,
              Colors.purple,
            ),
            const Divider(),
            _buildActivityRow(
              'Active Subscriptions',
              metrics.activeCompanies.toString(),
              Icons.subscriptions,
              Colors.green,
            ),
            const Divider(),
            _buildActivityRow(
              'Trial Subscriptions',
              metrics.trialCompanies.toString(),
              Icons.access_time,
              Colors.amber,
            ),
            if (metrics.suspendedCompanies > 0) ...[
              const Divider(),
              _buildActivityRow(
                'Suspended Companies',
                metrics.suspendedCompanies.toString(),
                Icons.block,
                Colors.red,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActivityRow(
      String label, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 15),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Future<PlatformMetrics> _calculatePlatformMetrics(
      AppProvider appProvider) async {
    final companies = await appProvider.getCompanies();
    final users = await StorageService.getUsers();
    final subscriptions = await StorageService.getSubscriptions();
    final targets = await StorageService.getSalesTargets();
    final transactions = await StorageService.getTransactions();

    // Calculate basic counts
    final totalCompanies = companies.length;
    final activeSubscriptions = subscriptions
        .where((s) => s.status == SubscriptionStatus.active)
        .length;
    final trialSubscriptions =
        subscriptions.where((s) => s.status == SubscriptionStatus.trial).length;
    final suspendedSubscriptions = subscriptions
        .where((s) => s.status == SubscriptionStatus.suspended)
        .length;

    final totalEmployees =
        users.where((u) => u.role == UserRole.employee).length;
    final totalAdmins = users.where((u) => u.role == UserRole.admin).length;

    // Calculate revenue
    final mrr = subscriptions
        .where((s) => s.status == SubscriptionStatus.active)
        .fold<double>(0, (sum, s) => sum + s.currentPrice);

    // For total revenue, we'll use a simplified calculation
    final totalRevenue = subscriptions.fold<double>(
      0,
      (sum, s) {
        final monthsSinceStart =
            DateTime.now().difference(s.startDate).inDays ~/ 30;
        return sum + (s.currentPrice * monthsSinceStart.clamp(0, 12));
      },
    );

    // Calculate companies by tier
    final companiesByTier = <String, int>{};
    for (final tier in SubscriptionTier.defaultTiers) {
      companiesByTier[tier.id] =
          subscriptions.where((s) => s.tierId == tier.id).length;
    }

    // Calculate revenue history (last 12 months)
    final revenueHistory = <RevenueByMonth>[];
    final now = DateTime.now();
    for (int i = 11; i >= 0; i--) {
      final targetDate = DateTime(now.year, now.month - i, 1);
      final monthRevenue = subscriptions.where((s) {
        final isInMonth =
            s.startDate.isBefore(targetDate.add(const Duration(days: 31))) &&
                (s.endDate == null || s.endDate!.isAfter(targetDate));
        return isInMonth && s.status == SubscriptionStatus.active;
      }).fold<double>(0, (sum, s) => sum + s.currentPrice);

      final paymentCount = subscriptions.where((s) {
        final isInMonth =
            s.startDate.isBefore(targetDate.add(const Duration(days: 31))) &&
                (s.endDate == null || s.endDate!.isAfter(targetDate));
        return isInMonth && s.status == SubscriptionStatus.active;
      }).length;

      revenueHistory.add(RevenueByMonth(
        year: targetDate.year,
        month: targetDate.month,
        revenue: monthRevenue,
        paymentCount: paymentCount,
      ));
    }

    // Calculate new companies this month
    final startOfMonth = DateTime(now.year, now.month, 1);
    final newCompaniesThisMonth =
        companies.where((c) => c.createdAt.isAfter(startOfMonth)).length;

    // Calculate churned companies (cancelled subscriptions this month)
    final churnedCompaniesThisMonth = subscriptions
        .where((s) =>
            s.status == SubscriptionStatus.cancelled &&
            s.endDate != null &&
            s.endDate!.isAfter(startOfMonth))
        .length;

    // Calculate average revenue per company
    final averageRevenuePerCompany =
        totalCompanies > 0 ? mrr / totalCompanies : 0.0;

    // Platform activity metrics
    final totalTargetsCreated = targets.length;
    final totalPointsAwarded = transactions
        .where((t) => t.type == PointsTransactionType.earned)
        .fold<int>(0, (sum, t) => sum + t.points);
    final totalBonusesRedeemed = transactions
        .where((t) => t.type == PointsTransactionType.redeemed)
        .length;

    return PlatformMetrics(
      totalCompanies: totalCompanies,
      activeCompanies: activeSubscriptions,
      trialCompanies: trialSubscriptions,
      suspendedCompanies: suspendedSubscriptions,
      totalEmployees: totalEmployees,
      totalAdmins: totalAdmins,
      monthlyRecurringRevenue: mrr,
      totalRevenue: totalRevenue,
      companiesByTier: companiesByTier,
      revenueHistory: revenueHistory,
      calculatedAt: DateTime.now(),
      newCompaniesThisMonth: newCompaniesThisMonth,
      churnedCompaniesThisMonth: churnedCompaniesThisMonth,
      averageRevenuePerCompany: averageRevenuePerCompany,
      totalTargetsCreated: totalTargetsCreated,
      totalBonusesRedeemed: totalBonusesRedeemed,
      totalPointsAwarded: totalPointsAwarded,
    );
  }

  Widget _buildSettingsTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Platform Settings',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 24),

          // Logout Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.logout,
                        color: Colors.red[600],
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Account Management',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Sign out of the platform administration dashboard.',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final appProvider = context.read<AppProvider>();
                        await appProvider.logout();
                      },
                      icon: const Icon(Icons.logout),
                      label: const Text('Logout'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Additional Settings Placeholder
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.settings,
                        color: Colors.grey[600],
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Platform Configuration',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Additional platform settings will be available here.',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
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
          ],
        ),
      ),
    );
  }

  Future<Map<String, dynamic>> _getPlatformOverview(
      AppProvider appProvider) async {
    final companies = await appProvider.getCompanies();
    final users = await appProvider.getUsers();

    final totalCompanies = companies.length;
    final activeCompanies = companies.where((c) => c.isActive).length;
    final totalEmployees =
        users.where((u) => u.role == UserRole.employee).length;

    // Mock monthly revenue calculation
    final monthlyRevenue =
        totalCompanies * 99.0; // Assuming $99/month per company

    return {
      'totalCompanies': totalCompanies,
      'activeCompanies': activeCompanies,
      'totalEmployees': totalEmployees,
      'monthlyRevenue': monthlyRevenue,
    };
  }

  void _handleCompanyAction(String action, Company company) {
    switch (action) {
      case 'view':
        _showCompanyDetails(company);
        break;
      case 'suspend':
        _suspendCompany(company);
        break;
      case 'activate':
        _activateCompany(company);
        break;
      case 'delete':
        _deleteCompany(company);
        break;
    }
  }

  void _showCompanyDetails(Company company) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(company.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ID: ${company.id}'),
            Text('Status: ${company.isActive ? 'Active' : 'Inactive'}'),
            if (company.contactEmail != null)
              Text('Email: ${company.contactEmail}'),
            if (company.contactPhone != null)
              Text('Phone: ${company.contactPhone}'),
            if (company.address != null) Text('Address: ${company.address}'),
            Text('Created: ${company.createdAt.toString().split(' ')[0]}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _suspendCompany(Company company) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Suspend Company'),
        content: Text(
          'Are you sure you want to suspend ${company.name}? This will prevent all users from accessing the platform.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await Provider.of<AppProvider>(context, listen: false)
                    .suspendCompany(company.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${company.name} has been suspended'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error suspending company: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Suspend'),
          ),
        ],
      ),
    );
  }

  void _activateCompany(Company company) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Activate Company'),
        content: Text(
          'Are you sure you want to activate ${company.name}? This will restore access to the platform for all users.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await Provider.of<AppProvider>(context, listen: false)
                    .activateCompany(company.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${company.name} has been activated'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error activating company: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Activate'),
          ),
        ],
      ),
    );
  }

  void _deleteCompany(Company company) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Company'),
        content: Text(
          'Are you sure you want to permanently delete ${company.name}? This action cannot be undone and will remove all associated data.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await Provider.of<AppProvider>(context, listen: false)
                    .deleteCompany(company.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${company.name} has been deleted'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting company: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
