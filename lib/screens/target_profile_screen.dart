import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

import '../models/sales_target.dart';
import '../providers/app_provider.dart';
import '../models/approval_request.dart';

class TargetProfileScreen extends StatelessWidget {
  final SalesTarget target;

  const TargetProfileScreen({super.key, required this.target});

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('MMM d, yyyy').format(target.date);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Target Profile'),
      ),
      body: Consumer<AppProvider>(
        builder: (context, app, _) {
          final statusColor = _statusColor(target.status);
          final percent = target.targetAmount > 0
              ? ((target.actualAmount / target.targetAmount) * 100).clamp(0, 100000).toDouble()
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
                        _statusIcon(target.status),
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            target.assignedWorkplaceName ?? 'No Workplace',
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
                            label: Text(target.status.name.toUpperCase()),
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
                        _kpiRow('Employee', target.assignedEmployeeName ?? 'No Employee'),
                        _kpiRow('Target', target.targetAmount.toStringAsFixed(0)),
                        _kpiRow('Actual', target.actualAmount.toStringAsFixed(0)),
                        _kpiRow('Progress', '${percent.toStringAsFixed(0)}%'),
                        if (target.pointsAwarded > 0)
                          _kpiRow('Points', target.pointsAwarded.toString()),
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
                      onPressed: () {
                        // Navigate to existing edit flow if available
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Edit target coming soon')),
                        );
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit'),
                    ),
                    if (target.isSubmitted && !target.isApproved)
                      ElevatedButton.icon(
                        onPressed: () async {
                          try {
                            final pending = app.approvalRequests.firstWhere(
                              (r) => r.targetId == target.id &&
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
                  'Performance Trend (Last 12 Months)',
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
                      .where((r) => r.targetId == target.id)
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

  Widget _buildPerformanceChart(AppProvider app) {
    final historyData = app.getTargetHistory(
      employeeId: target.assignedEmployeeId,
      workplaceId: target.assignedWorkplaceId,
      monthsBack: 12,
    );

    if (historyData.isEmpty) {
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

    // Prepare chart data
    final spots = <FlSpot>[];
    final targetSpots = <FlSpot>[];
    final labels = <String>[];

    for (int i = 0; i < historyData.length; i++) {
      final data = historyData[i];
      final month = data['month'] as String;
      final actual = data['actualTotal'] as double;
      final target = data['targetTotal'] as double;
      
      spots.add(FlSpot(i.toDouble(), actual));
      targetSpots.add(FlSpot(i.toDouble(), target));
      
      // Format month label (e.g., "Jan", "Feb")
      final monthParts = month.split('-');
      final monthNum = int.parse(monthParts[1]);
      final monthName = DateFormat('MMM').format(DateTime(2024, monthNum));
      labels.add(monthName);
    }

    return Container(
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
            // Target line
            LineChartBarData(
              spots: targetSpots,
              isCurved: true,
              color: Colors.blue,
              barWidth: 2,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
            ),
            // Actual line
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: Colors.green,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: true),
            ),
          ],
        ),
      ),
    );
  }
}


