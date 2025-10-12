import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/sales_target.dart';
import '../models/user.dart';
import '../models/points_transaction.dart';
import '../providers/app_provider.dart';

class TargetDetailsDialog extends StatelessWidget {
  final SalesTarget target;
  final AppProvider appProvider;
  final bool isAdminView;

  const TargetDetailsDialog({
    super.key,
    required this.target,
    required this.appProvider,
    this.isAdminView = false,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: target.isApproved
                      ? [Colors.green.shade400, Colors.green.shade600]
                      : [Colors.blue.shade400, Colors.blue.shade600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Icon(
                    target.isApproved
                        ? Icons.check_circle
                        : Icons.track_changes,
                    color: Colors.white,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Target Details',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          DateFormat('MMMM dd, yyyy').format(target.date),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sales Performance Section
                    _buildSection(
                      'Sales Performance',
                      Icons.trending_up,
                      Colors.blue,
                      [
                        _buildInfoRow(
                          'Target Amount',
                          '\$${target.targetAmount.toStringAsFixed(0)}',
                          Icons.flag,
                        ),
                        _buildInfoRow(
                          'Actual Sales',
                          '\$${target.actualAmount.toStringAsFixed(0)}',
                          Icons.attach_money,
                        ),
                        if (target.actualAmount > 0)
                          _buildInfoRow(
                            'Achievement',
                            '${((target.actualAmount / target.targetAmount) * 100).toStringAsFixed(1)}%',
                            target.isMet ? Icons.check_circle : Icons.warning,
                            valueColor:
                                target.isMet ? Colors.green : Colors.orange,
                          ),
                        _buildInfoRow(
                          'Points Awarded',
                          '${target.pointsAwarded} pts',
                          Icons.stars,
                          valueColor: Colors.purple,
                        ),
                        _buildInfoRow(
                          'Status',
                          _getStatusText(target.status),
                          _getStatusIcon(target.status),
                          valueColor: _getStatusColor(target.status),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Assignment Section
                    _buildSection(
                      'Assignment Details',
                      Icons.assignment_ind,
                      Colors.green,
                      [
                        if (target.assignedEmployeeName != null)
                          _buildInfoRow(
                            'Assigned To',
                            target.assignedEmployeeName!,
                            Icons.person,
                          ),
                        if (target.assignedWorkplaceName != null)
                          _buildInfoRow(
                            'Workplace',
                            target.assignedWorkplaceName!,
                            Icons.store,
                          ),
                        if (target.companyId != null)
                          FutureBuilder<String>(
                            future: _getCompanyName(target.companyId!),
                            builder: (context, snapshot) {
                              if (snapshot.hasData) {
                                return _buildInfoRow(
                                  'Company',
                                  snapshot.data!,
                                  Icons.business,
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                      ],
                    ),

                    // Team Members Section (if any)
                    if (target.collaborativeEmployeeIds.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _buildTeamMembersSection(),
                    ],

                    // Approval/Creation Info Section
                    const SizedBox(height: 20),
                    _buildSection(
                      'Timeline',
                      Icons.history,
                      Colors.orange,
                      [
                        _buildInfoRow(
                          'Created',
                          DateFormat('MMM dd, yyyy • h:mm a')
                              .format(target.createdAt),
                          Icons.add_circle,
                        ),
                        FutureBuilder<String>(
                          future: _getUserName(target.createdBy),
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              return _buildInfoRow(
                                'Created By',
                                snapshot.data!,
                                Icons.person_outline,
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                        if (target.isApproved && target.approvedAt != null) ...[
                          const Divider(height: 16),
                          _buildInfoRow(
                            'Approved',
                            DateFormat('MMM dd, yyyy • h:mm a')
                                .format(target.approvedAt!),
                            Icons.check_circle,
                            valueColor: Colors.green,
                          ),
                          if (target.approvedBy != null)
                            FutureBuilder<String>(
                              future: _getUserName(target.approvedBy!),
                              builder: (context, snapshot) {
                                if (snapshot.hasData) {
                                  return _buildInfoRow(
                                    'Approved By',
                                    snapshot.data!,
                                    Icons.admin_panel_settings,
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                        ],
                      ],
                    ),

                    // Points History Section (if approved)
                    if (target.isApproved && target.pointsAwarded > 0) ...[
                      const SizedBox(height: 20),
                      _buildPointsHistorySection(),
                    ],

                    // Adjustments History
                    if (isAdminView) ...[
                      const SizedBox(height: 20),
                      _buildAdjustmentsHistorySection(),
                    ],
                  ],
                ),
              ),
            ),

            // Footer Actions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
      String title, IconData icon, Color color, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
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
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon,
      {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 14,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: valueColor ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamMembersSection() {
    return _buildSection(
      'Team Members (${target.collaborativeEmployeeIds.length})',
      Icons.group,
      Colors.purple,
      [
        ...List.generate(
          target.collaborativeEmployeeNames.length,
          (index) {
            final name = target.collaborativeEmployeeNames[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
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
                  if (target.isApproved && target.pointsAwarded > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '+${target.pointsAwarded} pts',
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

  Widget _buildPointsHistorySection() {
    return FutureBuilder<List<PointsTransaction>>(
      future: _getTargetPointsTransactions(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final transactions = snapshot.data!;
        return _buildSection(
          'Points History (${transactions.length} transactions)',
          Icons.history,
          Colors.green,
          [
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

  Widget _buildAdjustmentsHistorySection() {
    return FutureBuilder<List<PointsTransaction>>(
      future: _getAllTargetTransactions(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final transactions = snapshot.data!;
        final adjustments = transactions
            .where((t) => t.type == PointsTransactionType.adjustment)
            .toList();

        if (adjustments.isEmpty) {
          return const SizedBox.shrink();
        }

        return _buildSection(
          'Adjustments History (${adjustments.length})',
          Icons.tune,
          Colors.orange,
          [
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
                      future: _getUserName(tx.userId),
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

  Future<List<PointsTransaction>> _getTargetPointsTransactions() async {
    final allTransactions = await appProvider.getAllPointsTransactions();
    return allTransactions.where((t) => t.relatedTargetId == target.id).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  Future<List<PointsTransaction>> _getAllTargetTransactions() async {
    final allTransactions = await appProvider.getAllPointsTransactions();
    return allTransactions.where((t) => t.relatedTargetId == target.id).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  Future<String> _getUserName(String userId) async {
    final users = await appProvider.getUsers();
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

  Future<String> _getCompanyName(String companyId) async {
    final companies = await appProvider.getCompanies();
    try {
      final company = companies.firstWhere((c) => c.id == companyId);
      return company.name;
    } catch (e) {
      return 'Unknown Company';
    }
  }

  String _getStatusText(TargetStatus status) {
    switch (status) {
      case TargetStatus.pending:
        return 'Pending';
      case TargetStatus.submitted:
        return 'Submitted';
      case TargetStatus.approved:
        return 'Approved';
      case TargetStatus.met:
        return 'Met';
      case TargetStatus.missed:
        return 'Missed';
    }
  }

  IconData _getStatusIcon(TargetStatus status) {
    switch (status) {
      case TargetStatus.pending:
        return Icons.hourglass_empty;
      case TargetStatus.submitted:
        return Icons.send;
      case TargetStatus.approved:
        return Icons.verified;
      case TargetStatus.met:
        return Icons.check_circle;
      case TargetStatus.missed:
        return Icons.cancel;
    }
  }

  Color _getStatusColor(TargetStatus status) {
    switch (status) {
      case TargetStatus.pending:
        return Colors.grey;
      case TargetStatus.submitted:
        return Colors.blue;
      case TargetStatus.approved:
        return Colors.green;
      case TargetStatus.met:
        return Colors.green;
      case TargetStatus.missed:
        return Colors.red;
    }
  }
}
