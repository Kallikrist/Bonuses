import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../models/company_subscription.dart';
import '../models/subscription_tier.dart';
import '../models/payment_record.dart';
import '../services/storage_service.dart';

class AdminSubscriptionScreen extends StatefulWidget {
  final AppProvider appProvider;

  const AdminSubscriptionScreen({super.key, required this.appProvider});

  @override
  State<AdminSubscriptionScreen> createState() =>
      _AdminSubscriptionScreenState();
}

class _AdminSubscriptionScreenState extends State<AdminSubscriptionScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscription Management'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _loadSubscriptionData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  const Text(
                    'Error loading subscription data',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final data = snapshot.data!;
          final subscription = data['subscription'] as CompanySubscription?;
          final tier = data['tier'] as SubscriptionTier?;
          final payments = data['payments'] as List<PaymentRecord>;
          final allTiers = data['allTiers'] as List<SubscriptionTier>;

          if (subscription == null || tier == null) {
            return _buildNoSubscription(allTiers);
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCurrentPlanCard(subscription, tier),
                const SizedBox(height: 24),
                _buildPlanFeatures(tier),
                const SizedBox(height: 24),
                _buildAvailablePlans(allTiers, tier),
                const SizedBox(height: 24),
                _buildPaymentHistory(payments),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<Map<String, dynamic>> _loadSubscriptionData() async {
    final currentUser = widget.appProvider.currentUser;
    if (currentUser == null) {
      throw Exception('No user logged in');
    }

    final companyId = currentUser.primaryCompanyId;
    if (companyId == null) {
      throw Exception('No company selected');
    }

    final subscription =
        await StorageService.getSubscriptionByCompanyId(companyId);
    final allTiers = SubscriptionTier.defaultTiers;
    final tier = subscription != null
        ? allTiers.firstWhere((t) => t.id == subscription.tierId,
            orElse: () => allTiers.first)
        : null;
    final payments = subscription != null
        ? await StorageService.getPaymentsBySubscriptionId(subscription.id)
        : <PaymentRecord>[];

    return {
      'subscription': subscription,
      'tier': tier,
      'payments': payments,
      'allTiers': allTiers,
    };
  }

  Widget _buildNoSubscription(List<SubscriptionTier> allTiers) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.subscriptions_outlined,
                size: 80, color: Colors.grey[400]),
            const SizedBox(height: 24),
            const Text(
              'No Active Subscription',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'Contact your platform administrator to set up a subscription plan for your company.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 32),
            const Text(
              'Available Plans:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...allTiers.where((t) => t.isActive).map((tier) => Card(
                  margin: const EdgeInsets.only(bottom: 12),
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
                    title: Text(tier.name,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(tier.description),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentPlanCard(
      CompanySubscription subscription, SubscriptionTier tier) {
    final statusColor = subscription.status == SubscriptionStatus.active
        ? Colors.green
        : subscription.status == SubscriptionStatus.trial
            ? Colors.amber
            : Colors.red;

    return Card(
      elevation: 4,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepPurple, Colors.deepPurple.shade300],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Current Plan',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tier.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    subscription.status
                        .toString()
                        .split('.')
                        .last
                        .toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildPlanInfoItem(
                    'Price',
                    '\$${subscription.currentPrice.toStringAsFixed(2)}/${subscription.billingInterval == BillingInterval.monthly ? 'mo' : 'yr'}',
                    Icons.attach_money,
                  ),
                ),
                Expanded(
                  child: _buildPlanInfoItem(
                    'Next Billing',
                    DateFormat('MMM dd, yyyy')
                        .format(subscription.nextBillingDate),
                    Icons.calendar_today,
                  ),
                ),
              ],
            ),
            if (subscription.isTrial) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.access_time,
                        color: Colors.white, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Trial ends in ${subscription.daysUntilTrialEnds} days',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showChangePlanDialog(subscription, tier),
                    icon: const Icon(Icons.upgrade),
                    label: const Text('Change Plan'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.deepPurple,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showBillingDialog(subscription),
                    icon: const Icon(Icons.receipt),
                    label: const Text('Billing'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white),
                      padding: const EdgeInsets.symmetric(vertical: 12),
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

  Widget _buildPlanInfoItem(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white70, size: 16),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildPlanFeatures(SubscriptionTier tier) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Plan Features',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildFeatureItem(
              'Employees',
              tier.maxEmployees == -1
                  ? 'Unlimited'
                  : '${tier.maxEmployees} employees',
              tier.maxEmployees == -1,
            ),
            _buildFeatureItem(
              'Workplaces',
              tier.maxWorkplaces == -1
                  ? 'Unlimited'
                  : '${tier.maxWorkplaces} locations',
              tier.maxWorkplaces == -1,
            ),
            _buildFeatureItem(
              'Bonuses',
              tier.maxBonuses == -1
                  ? 'Unlimited'
                  : '${tier.maxBonuses} bonuses',
              tier.maxBonuses == -1,
            ),
            const Divider(height: 24),
            ...tier.features.map((feature) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle,
                          color: Colors.green[600], size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child:
                            Text(feature, style: const TextStyle(fontSize: 14)),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String label, String value, bool isUnlimited) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
          Row(
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isUnlimited ? Colors.green[700] : Colors.deepPurple,
                ),
              ),
              if (isUnlimited)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Icon(Icons.all_inclusive,
                      color: Colors.green[700], size: 20),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvailablePlans(
      List<SubscriptionTier> allTiers, SubscriptionTier currentTier) {
    final otherTiers =
        allTiers.where((t) => t.id != currentTier.id && t.isActive).toList();

    if (otherTiers.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Available Plans',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...otherTiers.map((tier) => Card(
              margin: const EdgeInsets.only(bottom: 12),
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
                title: Text(tier.name,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(tier.description),
                trailing: Icon(
                  tier.monthlyPrice > currentTier.monthlyPrice
                      ? Icons.arrow_upward
                      : Icons.arrow_downward,
                  color: tier.monthlyPrice > currentTier.monthlyPrice
                      ? Colors.green
                      : Colors.orange,
                ),
              ),
            )),
      ],
    );
  }

  Widget _buildPaymentHistory(List<PaymentRecord> payments) {
    if (payments.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.receipt_long, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 12),
                Text(
                  'No payment history yet',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Payment History',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Card(
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: payments.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final payment = payments[index];
              final statusColor = payment.status == PaymentStatus.completed
                  ? Colors.green
                  : payment.status == PaymentStatus.failed
                      ? Colors.red
                      : Colors.orange;

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: statusColor.withOpacity(0.2),
                  child: Icon(
                    payment.status == PaymentStatus.completed
                        ? Icons.check_circle
                        : payment.status == PaymentStatus.failed
                            ? Icons.error
                            : Icons.pending,
                    color: statusColor,
                  ),
                ),
                title: Text(
                  '\$${payment.amount.toStringAsFixed(2)} ${payment.currency}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  DateFormat('MMM dd, yyyy').format(payment.date),
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        payment.status.toString().split('.').last.toUpperCase(),
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (payment.invoiceId != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          payment.invoiceId!,
                          style:
                              const TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showChangePlanDialog(
      CompanySubscription subscription, SubscriptionTier currentTier) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Subscription Plan'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'To change your subscription plan, please contact our support team or your platform administrator.',
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 16),
              Text(
                'They will help you:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              SizedBox(height: 8),
              Text('• Upgrade or downgrade your plan',
                  style: TextStyle(fontSize: 13)),
              Text('• Change billing frequency',
                  style: TextStyle(fontSize: 13)),
              Text('• Update payment methods', style: TextStyle(fontSize: 13)),
              Text('• Answer any questions', style: TextStyle(fontSize: 13)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Contact feature coming soon'),
                ),
              );
            },
            icon: const Icon(Icons.email),
            label: const Text('Contact Support'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showBillingDialog(CompanySubscription subscription) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Billing Information'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBillingRow(
                  'Billing Interval',
                  subscription.billingInterval == BillingInterval.monthly
                      ? 'Monthly'
                      : 'Yearly'),
              _buildBillingRow('Current Price',
                  '\$${subscription.currentPrice.toStringAsFixed(2)}'),
              _buildBillingRow(
                'Next Billing Date',
                DateFormat('MMMM dd, yyyy')
                    .format(subscription.nextBillingDate),
              ),
              _buildBillingRow(
                'Payment Method',
                subscription.paymentMethod.toString().split('.').last,
              ),
              if (subscription.isTrial)
                _buildBillingRow(
                  'Trial Ends',
                  DateFormat('MMMM dd, yyyy').format(subscription.trialEndsAt!),
                ),
              const Divider(height: 24),
              const Text(
                'To update billing information, please contact support.',
                style: TextStyle(fontSize: 13, color: Colors.grey),
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

  Widget _buildBillingRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),
        ],
      ),
    );
  }
}
