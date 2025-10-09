import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/sales_target.dart';
import '../models/approval_request.dart';
import '../providers/app_provider.dart';

class TargetCard extends StatelessWidget {
  final SalesTarget target;
  final AppProvider appProvider;
  final String? currentUserId;
  final bool isAdminView;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onQuickApprove;
  final VoidCallback? onAddCollaborators;
  final VoidCallback? onSubmitSales;
  final VoidCallback? onJoinAsTeamMember;
  final VoidCallback? onFixPoints;
  final VoidCallback? onAdjustPoints;

  const TargetCard({
    super.key,
    required this.target,
    required this.appProvider,
    this.currentUserId,
    this.isAdminView = false,
    this.onEdit,
    this.onDelete,
    this.onQuickApprove,
    this.onAddCollaborators,
    this.onSubmitSales,
    this.onJoinAsTeamMember,
    this.onFixPoints,
    this.onAdjustPoints,
  });

  @override
  Widget build(BuildContext context) {
    final progress = target.targetAmount > 0
        ? (target.actualAmount / target.targetAmount).clamp(0.0, 1.0)
        : 0.0;
    final actualPercentage = target.targetAmount > 0
        ? (target.actualAmount / target.targetAmount * 100).round()
        : 0;
    final isOverTarget = target.actualAmount > target.targetAmount;
    final isApproved = target.isApproved ||
        target.status == TargetStatus.approved ||
        target.status == TargetStatus.met;
    final isMet = target.isMet;
    final percentageAbove = target.percentageAboveTarget;

    // Get pending requests for admin view
    final pendingRequests = isAdminView
        ? appProvider.approvalRequests
            .where((request) =>
                request.targetId == target.id &&
                request.status == ApprovalStatus.pending)
            .toList()
        : <ApprovalRequest>[];

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
                if (isAdminView) ...[
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
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isAdminView) ...[
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
                      ] else ...[
                        // Employee view header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  target.assignedEmployeeId == currentUserId
                                      ? 'Your Personal Target'
                                      : target.assignedWorkplaceId != null
                                          ? 'Your Workplace Target'
                                          : 'Company Target',
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                                if (target.assignedEmployeeId == currentUserId)
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
                                  DateFormat('MMM dd, yyyy')
                                      .format(target.date),
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                if (target.assignedWorkplaceName != null)
                                  Text(
                                    target.assignedWorkplaceName!,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: Colors.green[700],
                                          fontWeight: FontWeight.w500,
                                        ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                // Action Buttons
                if (isAdminView) ...[
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (pendingRequests.isNotEmpty &&
                          onQuickApprove != null) ...[
                        IconButton(
                          icon: const Icon(Icons.check_circle,
                              color: Colors.green),
                          onPressed: onQuickApprove,
                          tooltip: 'Quick Approve',
                        ),
                      ],
                      if (target.isApproved &&
                          target.pointsAwarded > 0 &&
                          target.collaborativeEmployeeIds.isNotEmpty &&
                          onFixPoints != null) ...[
                        IconButton(
                          icon: const Icon(Icons.refresh, color: Colors.orange),
                          onPressed: onFixPoints,
                          tooltip: 'Retroactively Award Points',
                        ),
                      ],
                      if (target.isApproved &&
                          target.pointsAwarded > 0 &&
                          target.collaborativeEmployeeIds.isNotEmpty &&
                          onAdjustPoints != null) ...[
                        IconButton(
                          icon: const Icon(Icons.tune, color: Colors.blue),
                          onPressed: onAdjustPoints,
                          tooltip: 'Adjust Target & Recalculate Points',
                        ),
                      ],
                      if (onEdit != null) ...[
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: onEdit,
                          tooltip: 'Edit Target',
                        ),
                      ],
                      if (onDelete != null) ...[
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: onDelete,
                          tooltip: 'Delete Target',
                        ),
                      ],
                    ],
                  ),
                ],
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
                      isAdminView
                          ? 'Sales: \$${target.actualAmount.toStringAsFixed(0)}'
                          : '\$${target.actualAmount.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: isAdminView ? 14 : 18,
                        color: isMet ? Colors.green : Colors.orange,
                      ),
                    ),
                    Text(
                      isAdminView
                          ? 'Target: \$${target.targetAmount.toStringAsFixed(0)}'
                          : 'of \$${target.targetAmount.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: isAdminView ? 14 : 16,
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
                _buildProgressBar(target, progress, isMet),

                const SizedBox(height: 8),

                // Status and Additional Info
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (isAdminView) ...[
                      Text(
                        'Date: ${DateFormat('MMM dd, yyyy').format(target.date)}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ] else ...[
                      Text(
                        '${(progress * 100).toStringAsFixed(1)}%',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                    if (!isAdminView && isMet && percentageAbove >= 10) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
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
                  ],
                ),

                // Team Members Section (Employee view only)
                if (!isAdminView &&
                    target.collaborativeEmployeeNames.isNotEmpty) ...[
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
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
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

                const SizedBox(height: 4),

                // Status Badges
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (isAdminView) ...[
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
                      ] else if (isApproved) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green[600],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'APPROVED',
                            style: TextStyle(
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
                  ],
                ),
              ],
            ),

            // Action Buttons (Employee view only)
            if (!isAdminView) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  // Show "Join Target" if user is not part of this target
                  if (!isAdminView &&
                      currentUserId != null &&
                      target.assignedEmployeeId != currentUserId &&
                      !target.collaborativeEmployeeIds
                          .contains(currentUserId) &&
                      onJoinAsTeamMember != null) ...[
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onJoinAsTeamMember,
                        icon: const Icon(Icons.person_add, size: 16),
                        label: Text(target.isSubmitted
                            ? 'Request to Join'
                            : 'Join as Team Member'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: target.isSubmitted
                              ? Colors.orange.shade600
                              : Colors.blue.shade600,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  // Show "Add Team" if user is the assigned employee OR a collaborator
                  if (onAddCollaborators != null &&
                      currentUserId != null &&
                      (target.assignedEmployeeId == currentUserId ||
                          target.collaborativeEmployeeIds
                              .contains(currentUserId))) ...[
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onAddCollaborators,
                        icon: const Icon(Icons.group_add, size: 16),
                        label: Text(target.isSubmitted
                            ? 'Request Team Change'
                            : 'Add Team'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: target.isSubmitted
                              ? Colors.orange.shade600
                              : null,
                          foregroundColor:
                              target.isSubmitted ? Colors.white : null,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  // Show "Submit Sales" only if user is part of the team
                  if (currentUserId != null &&
                      (target.assignedEmployeeId == currentUserId ||
                          target.collaborativeEmployeeIds
                              .contains(currentUserId)))
                    Expanded(
                      child: !target.isSubmitted
                          ? ElevatedButton.icon(
                              onPressed: onSubmitSales,
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
                                  ? GestureDetector(
                                      onTap: isAdminView
                                          ? () => _quickApproveTarget(target)
                                          : null,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: Colors.blue[100],
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border:
                                              Border.all(color: Colors.blue),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.upload,
                                                color: Colors.blue[700],
                                                size: 16),
                                            const SizedBox(width: 8),
                                            Text(
                                              isAdminView
                                                  ? 'Tap to Approve'
                                                  : 'Submitted for Approval',
                                              style: TextStyle(
                                                color: Colors.blue[700],
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                  : target.status == TargetStatus.missed
                                      ? Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 8),
                                              decoration: BoxDecoration(
                                                color: Colors.red[50],
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                border: Border.all(
                                                    color: Colors.red),
                                              ),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Icon(Icons.error_outline,
                                                      color: Colors.red[700],
                                                      size: 16),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    'Missed - No Points Awarded',
                                                    style: TextStyle(
                                                      color: Colors.red[700],
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            ElevatedButton.icon(
                                              onPressed: onSubmitSales,
                                              icon: const Icon(Icons.edit,
                                                  size: 16),
                                              label:
                                                  const Text('Resubmit Sales'),
                                            ),
                                          ],
                                        )
                                      : Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: Colors.orange[100],
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            border: Border.all(
                                                color: Colors.orange),
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.pending_actions,
                                                  color: Colors.orange[700],
                                                  size: 16),
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

            // Feedback Section for Admin View
            if (isAdminView) ...[
              const SizedBox(height: 8),
              if (target.isApproved ||
                  target.status == TargetStatus.approved) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                GestureDetector(
                  onTap: isAdminView ? () => _quickApproveTarget(target) : null,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                          isAdminView
                              ? 'Tap to Approve'
                              : 'Submitted for Approval',
                          style: TextStyle(
                            color: Colors.blue[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar(SalesTarget target, double progress, bool isMet) {
    // Calculate above-target percentage dynamically so it also works
    // immediately after submission (before any persisted fields catch up).
    final double computedAbove = target.targetAmount > 0
        ? ((target.actualAmount - target.targetAmount) / target.targetAmount) *
            100.0
        : 0.0;
    final double percentageAbove = computedAbove > 0 ? computedAbove : 0.0;
    final hasBonus =
        percentageAbove > 0.0; // Any amount above target shows purple
    final reachedTarget = progress >= 1.0;

    // If target is met (>= 100%), show green bar with optional purple bonus section
    if (reachedTarget) {
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

    // Default progress bar for below-target progress (orange)
    return LinearProgressIndicator(
      value: progress.clamp(0.0, 1.0),
      backgroundColor: Colors.grey[300],
      valueColor: const AlwaysStoppedAnimation<Color>(
        Colors.orange,
      ),
      minHeight: 8,
    );
  }

  void _quickApproveTarget(SalesTarget target) async {
    if (!isAdminView) return;

    try {
      // Find the pending approval request for this target
      final pendingRequest = appProvider.approvalRequests.firstWhere(
        (request) =>
            request.targetId == target.id &&
            request.status == ApprovalStatus.pending,
        orElse: () => throw Exception('No pending approval request found'),
      );

      // Use the existing approval system
      await appProvider.approveRequest(pendingRequest);

      print('DEBUG: Target ${target.id} approved via quick approve');
    } catch (e) {
      print('Error quick approving target: $e');
      // If no approval request exists, this might be a direct admin edit
      // In that case, we should still approve the target directly
      if (e.toString().contains('No pending approval request found')) {
        try {
          final effectivePercent = target.targetAmount > 0
              ? (target.actualAmount / target.targetAmount) * 100
              : 0.0;

          final pointsAwarded = effectivePercent >= 100
              ? appProvider.getPointsForEffectivePercent(effectivePercent)
              : 0;

          final approvedTarget = target.copyWith(
            status: TargetStatus.approved,
            isApproved: true,
            approvedBy: appProvider.currentUser?.id,
            approvedAt: DateTime.now(),
            pointsAwarded: pointsAwarded,
            isMet: target.actualAmount >= target.targetAmount,
          );

          await appProvider.updateSalesTarget(approvedTarget);
          print('DEBUG: Target approved directly (no approval request)');
        } catch (directError) {
          print('Error in direct approval: $directError');
        }
      }
    }
  }
}
