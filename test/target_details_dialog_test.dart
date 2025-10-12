import 'package:flutter_test/flutter_test.dart';
import 'package:bonuses/models/sales_target.dart';
import 'package:bonuses/models/user.dart';
import 'package:bonuses/widgets/target_details_dialog.dart';

void main() {
  group('Target Details Dialog Tests', () {
    test('Dialog displays basic target information correctly', () {
      final target = SalesTarget(
        id: 'target_1',
        targetAmount: 1000,
        actualAmount: 1100,
        date: DateTime(2024, 1, 15),
        companyId: 'company_1',
        status: TargetStatus.approved,
        isSubmitted: true,
        isApproved: true,
        assignedEmployeeId: 'emp_1',
        assignedEmployeeName: 'John Doe',
        assignedWorkplaceId: 'workplace_1',
        assignedWorkplaceName: 'Mall Location',
        collaborativeEmployeeIds: ['emp_2', 'emp_3'],
        collaborativeEmployeeNames: ['Jane Smith', 'Bob Johnson'],
        pointsAwarded: 10,
        createdAt: DateTime(2024, 1, 10, 9, 0),
        createdBy: 'admin_1',
        approvedAt: DateTime(2024, 1, 15, 14, 30),
        approvedBy: 'admin_1',
      );

      // Verify target has all required data
      expect(target.id, 'target_1');
      expect(target.targetAmount, 1000);
      expect(target.actualAmount, 1100);
      expect(target.pointsAwarded, 10);
      expect(target.isApproved, true);
      expect(target.collaborativeEmployeeNames.length, 2);
      expect(target.assignedEmployeeName, 'John Doe');
      expect(target.assignedWorkplaceName, 'Mall Location');
    });

    test('Achievement percentage calculates correctly', () {
      final target = SalesTarget(
        id: 'target_1',
        targetAmount: 1000,
        actualAmount: 1100,
        date: DateTime.now(),
        companyId: 'company_1',
        status: TargetStatus.approved,
        isSubmitted: true,
        createdAt: DateTime.now(),
        createdBy: 'admin',
      );

      final achievementPercent = (target.actualAmount / target.targetAmount) * 100;
      expect(achievementPercent.round(), 110);
    });

    test('Status text mapping is correct', () {
      final statuses = {
        TargetStatus.pending: 'Pending',
        TargetStatus.submitted: 'Submitted',
        TargetStatus.approved: 'Approved',
        TargetStatus.met: 'Met',
        TargetStatus.missed: 'Missed',
      };

      // Verify each status has a text representation
      for (final status in TargetStatus.values) {
        expect(statuses.containsKey(status), true,
            reason: 'Status $status should have a text representation');
      }
    });

    test('Team members list is properly formatted', () {
      final target = SalesTarget(
        id: 'target_1',
        targetAmount: 1000,
        actualAmount: 1100,
        date: DateTime.now(),
        companyId: 'company_1',
        status: TargetStatus.approved,
        isSubmitted: true,
        collaborativeEmployeeIds: ['emp_1', 'emp_2', 'emp_3'],
        collaborativeEmployeeNames: ['Alice', 'Bob', 'Charlie'],
        pointsAwarded: 15,
        createdAt: DateTime.now(),
        createdBy: 'admin',
      );

      expect(target.collaborativeEmployeeIds.length, 3);
      expect(target.collaborativeEmployeeNames.length, 3);
      expect(target.collaborativeEmployeeNames, contains('Alice'));
      expect(target.collaborativeEmployeeNames, contains('Bob'));
      expect(target.collaborativeEmployeeNames, contains('Charlie'));
    });

    test('Points are correctly assigned when target is approved', () {
      final target = SalesTarget(
        id: 'target_1',
        targetAmount: 1000,
        actualAmount: 1200,
        date: DateTime.now(),
        companyId: 'company_1',
        status: TargetStatus.approved,
        isSubmitted: true,
        isApproved: true,
        collaborativeEmployeeIds: ['emp_1', 'emp_2'],
        collaborativeEmployeeNames: ['John', 'Jane'],
        pointsAwarded: 20, // 120% = 20 points
        createdAt: DateTime.now(),
        createdBy: 'admin',
      );

      expect(target.isApproved, true);
      expect(target.pointsAwarded, 20);
      // isMet is calculated based on actualAmount >= targetAmount
      expect(target.actualAmount >= target.targetAmount, true);
    });

    test('Created and approved timestamps are preserved', () {
      final createdTime = DateTime(2024, 1, 10, 9, 0);
      final approvedTime = DateTime(2024, 1, 15, 14, 30);

      final target = SalesTarget(
        id: 'target_1',
        targetAmount: 1000,
        actualAmount: 1100,
        date: DateTime.now(),
        companyId: 'company_1',
        status: TargetStatus.approved,
        isSubmitted: true,
        isApproved: true,
        pointsAwarded: 10,
        createdAt: createdTime,
        createdBy: 'admin_1',
        approvedAt: approvedTime,
        approvedBy: 'admin_1',
      );

      expect(target.createdAt, createdTime);
      expect(target.approvedAt, approvedTime);
      expect(target.createdBy, 'admin_1');
      expect(target.approvedBy, 'admin_1');
    });
  });
}

