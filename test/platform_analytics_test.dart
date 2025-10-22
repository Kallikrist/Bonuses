import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bonuses/services/storage_service.dart';
import 'package:bonuses/models/company.dart';
import 'package:bonuses/models/company_subscription.dart';
import 'package:bonuses/models/subscription_tier.dart';
import 'package:bonuses/models/user.dart';
import 'package:bonuses/models/sales_target.dart';
import 'package:bonuses/models/points_transaction.dart';
import 'package:bonuses/models/platform_metrics.dart';

void main() {
  group('Platform Analytics Tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    group('PlatformMetrics Calculations', () {
      test('Metrics calculate correctly with sample data', () async {
        // Create test companies
        final company1 = Company(
          id: 'company_1',
          name: 'Company 1',
          contactEmail: 'admin1@test.com',
          adminUserId: 'admin1',
          createdAt: DateTime.now().subtract(const Duration(days: 60)),
          isActive: true,
        );
        final company2 = Company(
          id: 'company_2',
          name: 'Company 2',
          contactEmail: 'admin2@test.com',
          adminUserId: 'admin2',
          createdAt: DateTime.now().subtract(const Duration(days: 30)),
          isActive: true,
        );
        final company3 = Company(
          id: 'company_3',
          name: 'Company 3',
          contactEmail: 'admin3@test.com',
          adminUserId: 'admin3',
          createdAt: DateTime.now().subtract(const Duration(days: 5)),
          isActive: true,
        );

        await StorageService.addCompany(company1);
        await StorageService.addCompany(company2);
        await StorageService.addCompany(company3);

        // Create subscriptions
        final now = DateTime.now();
        final sub1 = CompanySubscription(
          id: 'sub_1',
          companyId: 'company_1',
          tierId: 'tier_professional',
          startDate: now.subtract(const Duration(days: 60)),
          status: SubscriptionStatus.active,
          paymentMethod: PaymentMethod.creditCard,
          billingInterval: BillingInterval.monthly,
          nextBillingDate: now.add(const Duration(days: 30)),
          currentPrice: 99,
          gracePeriodDays: 7,
          createdAt: now.subtract(const Duration(days: 60)),
          updatedAt: now,
        );
        final sub2 = CompanySubscription(
          id: 'sub_2',
          companyId: 'company_2',
          tierId: 'tier_starter',
          startDate: now.subtract(const Duration(days: 30)),
          status: SubscriptionStatus.active,
          paymentMethod: PaymentMethod.creditCard,
          billingInterval: BillingInterval.monthly,
          nextBillingDate: now.add(const Duration(days: 30)),
          currentPrice: 29,
          gracePeriodDays: 7,
          createdAt: now.subtract(const Duration(days: 30)),
          updatedAt: now,
        );
        final sub3 = CompanySubscription(
          id: 'sub_3',
          companyId: 'company_3',
          tierId: 'tier_free',
          startDate: now.subtract(const Duration(days: 5)),
          status: SubscriptionStatus.trial,
          paymentMethod: PaymentMethod.none,
          billingInterval: BillingInterval.monthly,
          nextBillingDate: now.add(const Duration(days: 9)),
          currentPrice: 0,
          trialEndsAt: now.add(const Duration(days: 9)),
          gracePeriodDays: 7,
          createdAt: now.subtract(const Duration(days: 5)),
          updatedAt: now,
        );

        await StorageService.addSubscription(sub1);
        await StorageService.addSubscription(sub2);
        await StorageService.addSubscription(sub3);

        // Create users
        final admin1 = User(
          id: 'admin1',
          name: 'Admin 1',
          email: 'admin1@test.com',
          phoneNumber: '+1 (555) 111-1111',
          role: UserRole.admin,
          createdAt: now,
          workplaceIds: ['wp1'],
          workplaceNames: ['Workplace 1'],
          companyIds: ['company_1'],
          companyNames: ['Company 1'],
          primaryCompanyId: 'company_1',
          companyRoles: {'company_1': 'admin'},
          companyPoints: {'company_1': 0},
        );
        final employee1 = User(
          id: 'emp1',
          name: 'Employee 1',
          email: 'emp1@test.com',
          phoneNumber: '+1 (555) 222-2222',
          role: UserRole.employee,
          createdAt: now,
          workplaceIds: ['wp1'],
          workplaceNames: ['Workplace 1'],
          companyIds: ['company_1'],
          companyNames: ['Company 1'],
          primaryCompanyId: 'company_1',
          companyRoles: {'company_1': 'employee'},
          companyPoints: {'company_1': 100},
        );
        final employee2 = User(
          id: 'emp2',
          name: 'Employee 2',
          email: 'emp2@test.com',
          phoneNumber: '+1 (555) 333-3333',
          role: UserRole.employee,
          createdAt: now,
          workplaceIds: ['wp2'],
          workplaceNames: ['Workplace 2'],
          companyIds: ['company_2'],
          companyNames: ['Company 2'],
          primaryCompanyId: 'company_2',
          companyRoles: {'company_2': 'employee'},
          companyPoints: {'company_2': 50},
        );

        await StorageService.addUser(admin1);
        await StorageService.addUser(employee1);
        await StorageService.addUser(employee2);

        // Verify metrics
        final companies = await StorageService.getCompanies();
        final users = await StorageService.getUsers();
        final subscriptions = await StorageService.getSubscriptions();

        expect(companies.length, 3);
        expect(users.where((u) => u.role == UserRole.employee).length, 2);
        expect(users.where((u) => u.role == UserRole.admin).length, 1);
        expect(
            subscriptions
                .where((s) => s.status == SubscriptionStatus.active)
                .length,
            2);
        expect(
            subscriptions
                .where((s) => s.status == SubscriptionStatus.trial)
                .length,
            1);

        // Calculate MRR
        final mrr = subscriptions
            .where((s) => s.status == SubscriptionStatus.active)
            .fold<double>(0, (sum, s) => sum + s.currentPrice);
        expect(mrr, 128.0); // 99 + 29
      });

      test('Growth rate calculates correctly', () {
        final metrics = PlatformMetrics(
          totalCompanies: 100,
          activeCompanies: 80,
          trialCompanies: 15,
          suspendedCompanies: 5,
          totalEmployees: 500,
          totalAdmins: 100,
          monthlyRecurringRevenue: 5000,
          totalRevenue: 50000,
          companiesByTier: {},
          revenueHistory: [],
          calculatedAt: DateTime.now(),
          newCompaniesThisMonth: 10,
          churnedCompaniesThisMonth: 2,
          averageRevenuePerCompany: 50,
          totalTargetsCreated: 200,
          totalBonusesRedeemed: 150,
          totalPointsAwarded: 10000,
        );

        expect(metrics.growthRate, 10.0); // (10/100) * 100
        expect(metrics.churnRate, 2.0); // (2/100) * 100
      });

      test('Conversion rate calculates correctly', () {
        final metrics = PlatformMetrics(
          totalCompanies: 100,
          activeCompanies: 80,
          trialCompanies: 20,
          suspendedCompanies: 0,
          totalEmployees: 500,
          totalAdmins: 100,
          monthlyRecurringRevenue: 5000,
          totalRevenue: 50000,
          companiesByTier: {},
          revenueHistory: [],
          calculatedAt: DateTime.now(),
          newCompaniesThisMonth: 10,
          churnedCompaniesThisMonth: 2,
          averageRevenuePerCompany: 50,
          totalTargetsCreated: 200,
          totalBonusesRedeemed: 150,
          totalPointsAwarded: 10000,
        );

        // Conversion = (paid companies / total companies) * 100
        // Paid companies = activeCompanies - trialCompanies = 80 - 20 = 60
        expect(metrics.conversionRate, 60.0); // (60/100) * 100
      });

      test('Handles zero companies correctly', () {
        final metrics = PlatformMetrics(
          totalCompanies: 0,
          activeCompanies: 0,
          trialCompanies: 0,
          suspendedCompanies: 0,
          totalEmployees: 0,
          totalAdmins: 0,
          monthlyRecurringRevenue: 0,
          totalRevenue: 0,
          companiesByTier: {},
          revenueHistory: [],
          calculatedAt: DateTime.now(),
          newCompaniesThisMonth: 0,
          churnedCompaniesThisMonth: 0,
          averageRevenuePerCompany: 0,
          totalTargetsCreated: 0,
          totalBonusesRedeemed: 0,
          totalPointsAwarded: 0,
        );

        expect(metrics.growthRate, 0.0);
        expect(metrics.churnRate, 0.0);
        expect(metrics.conversionRate, 0.0);
      });
    });

    group('Revenue History Tests', () {
      test('RevenueByMonth has correct month name', () {
        final january = RevenueByMonth(
          year: 2024,
          month: 1,
          revenue: 1000,
          paymentCount: 10,
        );
        final december = RevenueByMonth(
          year: 2024,
          month: 12,
          revenue: 1500,
          paymentCount: 15,
        );

        expect(january.monthName, 'Jan');
        expect(december.monthName, 'Dec');
      });

      test('Revenue history can be serialized', () {
        final revenue = RevenueByMonth(
          year: 2024,
          month: 6,
          revenue: 2500,
          paymentCount: 25,
        );

        final json = revenue.toJson();
        final deserialized = RevenueByMonth.fromJson(json);

        expect(deserialized.year, revenue.year);
        expect(deserialized.month, revenue.month);
        expect(deserialized.revenue, revenue.revenue);
        expect(deserialized.paymentCount, revenue.paymentCount);
      });

      test('Can calculate revenue trend over multiple months', () async {
        final company = Company(
          id: 'test_company',
          name: 'Test Company',
          contactEmail: 'admin@test.com',
          adminUserId: 'admin1',
          createdAt: DateTime.now().subtract(const Duration(days: 90)),
          isActive: true,
        );
        await StorageService.addCompany(company);

        final now = DateTime.now();
        final subscription = CompanySubscription(
          id: 'sub_1',
          companyId: 'test_company',
          tierId: 'tier_professional',
          startDate: now.subtract(const Duration(days: 90)),
          status: SubscriptionStatus.active,
          paymentMethod: PaymentMethod.creditCard,
          billingInterval: BillingInterval.monthly,
          nextBillingDate: now.add(const Duration(days: 30)),
          currentPrice: 99,
          gracePeriodDays: 7,
          createdAt: now.subtract(const Duration(days: 90)),
          updatedAt: now,
        );

        await StorageService.addSubscription(subscription);

        final subscriptions = await StorageService.getSubscriptions();
        expect(subscriptions.length, 1);
        expect(subscriptions.first.currentPrice, 99);
      });
    });

    group('Platform Activity Metrics', () {
      test('Counts targets correctly', () async {
        final company = Company(
          id: 'test_company',
          name: 'Test Company',
          contactEmail: 'admin@test.com',
          adminUserId: 'admin1',
          createdAt: DateTime.now(),
          isActive: true,
        );
        await StorageService.addCompany(company);

        final target1 = SalesTarget(
          id: 'target_1',
          date: DateTime.now(),
          targetAmount: 1000,
          createdBy: 'admin1',
          createdAt: DateTime.now(),
          status: TargetStatus.pending,
          assignedWorkplaceId: 'wp1',
          assignedWorkplaceName: 'Test Workplace',
          companyId: 'test_company',
        );
        final target2 = SalesTarget(
          id: 'target_2',
          date: DateTime.now(),
          targetAmount: 2000,
          createdBy: 'admin1',
          createdAt: DateTime.now(),
          status: TargetStatus.submitted,
          assignedWorkplaceId: 'wp1',
          assignedWorkplaceName: 'Test Workplace',
          companyId: 'test_company',
        );

        await StorageService.addSalesTarget(target1);
        await StorageService.addSalesTarget(target2);

        final targets = await StorageService.getSalesTargets();
        expect(targets.length, 2);
      });

      test('Counts points awarded correctly', () async {
        final transaction1 = PointsTransaction(
          id: 'trans_1',
          userId: 'user_1',
          points: 50,
          type: PointsTransactionType.earned,
          description: 'Target completed',
          date: DateTime.now(),
          companyId: 'test_company',
        );
        final transaction2 = PointsTransaction(
          id: 'trans_2',
          userId: 'user_1',
          points: 30,
          type: PointsTransactionType.earned,
          description: 'Bonus earned',
          date: DateTime.now(),
          companyId: 'test_company',
        );
        final transaction3 = PointsTransaction(
          id: 'trans_3',
          userId: 'user_1',
          points: 20,
          type: PointsTransactionType.redeemed,
          description: 'Bonus redeemed',
          date: DateTime.now(),
          companyId: 'test_company',
        );

        await StorageService.addPointsTransaction(transaction1);
        await StorageService.addPointsTransaction(transaction2);
        await StorageService.addPointsTransaction(transaction3);

        final transactions = await StorageService.getTransactions();
        final pointsAwarded = transactions
            .where((t) => t.type == PointsTransactionType.earned)
            .fold<int>(0, (sum, t) => sum + t.points);
        final bonusesRedeemed = transactions
            .where((t) => t.type == PointsTransactionType.redeemed)
            .length;

        expect(pointsAwarded, 80); // 50 + 30
        expect(bonusesRedeemed, 1);
      });
    });

    group('Tier Distribution Tests', () {
      test('Calculates tier distribution correctly', () async {
        final companies = [
          Company(
            id: 'company_1',
            name: 'Company 1',
            contactEmail: 'admin1@test.com',
            adminUserId: 'admin1',
            createdAt: DateTime.now(),
            isActive: true,
          ),
          Company(
            id: 'company_2',
            name: 'Company 2',
            contactEmail: 'admin2@test.com',
            adminUserId: 'admin2',
            createdAt: DateTime.now(),
            isActive: true,
          ),
          Company(
            id: 'company_3',
            name: 'Company 3',
            contactEmail: 'admin3@test.com',
            adminUserId: 'admin3',
            createdAt: DateTime.now(),
            isActive: true,
          ),
        ];

        for (final company in companies) {
          await StorageService.addCompany(company);
        }

        final now = DateTime.now();
        final subscriptions = [
          CompanySubscription(
            id: 'sub_1',
            companyId: 'company_1',
            tierId: 'tier_professional',
            startDate: now,
            status: SubscriptionStatus.active,
            paymentMethod: PaymentMethod.creditCard,
            billingInterval: BillingInterval.monthly,
            nextBillingDate: now.add(const Duration(days: 30)),
            currentPrice: 99,
            gracePeriodDays: 7,
            createdAt: now,
            updatedAt: now,
          ),
          CompanySubscription(
            id: 'sub_2',
            companyId: 'company_2',
            tierId: 'tier_starter',
            startDate: now,
            status: SubscriptionStatus.active,
            paymentMethod: PaymentMethod.creditCard,
            billingInterval: BillingInterval.monthly,
            nextBillingDate: now.add(const Duration(days: 30)),
            currentPrice: 29,
            gracePeriodDays: 7,
            createdAt: now,
            updatedAt: now,
          ),
          CompanySubscription(
            id: 'sub_3',
            companyId: 'company_3',
            tierId: 'tier_starter',
            startDate: now,
            status: SubscriptionStatus.active,
            paymentMethod: PaymentMethod.creditCard,
            billingInterval: BillingInterval.monthly,
            nextBillingDate: now.add(const Duration(days: 30)),
            currentPrice: 29,
            gracePeriodDays: 7,
            createdAt: now,
            updatedAt: now,
          ),
        ];

        for (final sub in subscriptions) {
          await StorageService.addSubscription(sub);
        }

        // Calculate tier distribution
        final companiesByTier = <String, int>{};
        for (final tier in SubscriptionTier.defaultTiers) {
          final subs = await StorageService.getSubscriptions();
          companiesByTier[tier.id] =
              subs.where((s) => s.tierId == tier.id).length;
        }

        expect(companiesByTier['tier_starter'], 2);
        expect(companiesByTier['tier_professional'], 1);
        expect(companiesByTier['tier_free'], 0);
        expect(companiesByTier['tier_enterprise'], 0);
      });
    });

    group('Revenue Calculations', () {
      test('MRR calculates correctly', () async {
        final company1 = Company(
          id: 'company_1',
          name: 'Company 1',
          contactEmail: 'admin1@test.com',
          adminUserId: 'admin1',
          createdAt: DateTime.now(),
          isActive: true,
        );
        final company2 = Company(
          id: 'company_2',
          name: 'Company 2',
          contactEmail: 'admin2@test.com',
          adminUserId: 'admin2',
          createdAt: DateTime.now(),
          isActive: true,
        );

        await StorageService.addCompany(company1);
        await StorageService.addCompany(company2);

        final now = DateTime.now();
        final sub1 = CompanySubscription(
          id: 'sub_1',
          companyId: 'company_1',
          tierId: 'tier_professional',
          startDate: now,
          status: SubscriptionStatus.active,
          paymentMethod: PaymentMethod.creditCard,
          billingInterval: BillingInterval.monthly,
          nextBillingDate: now.add(const Duration(days: 30)),
          currentPrice: 99,
          gracePeriodDays: 7,
          createdAt: now,
          updatedAt: now,
        );
        final sub2 = CompanySubscription(
          id: 'sub_2',
          companyId: 'company_2',
          tierId: 'tier_starter',
          startDate: now,
          status: SubscriptionStatus.active,
          paymentMethod: PaymentMethod.creditCard,
          billingInterval: BillingInterval.monthly,
          nextBillingDate: now.add(const Duration(days: 30)),
          currentPrice: 29,
          gracePeriodDays: 7,
          createdAt: now,
          updatedAt: now,
        );

        await StorageService.addSubscription(sub1);
        await StorageService.addSubscription(sub2);

        final subscriptions = await StorageService.getSubscriptions();
        final mrr = subscriptions
            .where((s) => s.status == SubscriptionStatus.active)
            .fold<double>(0, (sum, s) => sum + s.currentPrice);

        expect(mrr, 128.0); // 99 + 29
      });

      test('Trial subscriptions do not count toward MRR', () async {
        final company = Company(
          id: 'company_1',
          name: 'Company 1',
          contactEmail: 'admin1@test.com',
          adminUserId: 'admin1',
          createdAt: DateTime.now(),
          isActive: true,
        );
        await StorageService.addCompany(company);

        final now = DateTime.now();
        final trialSub = CompanySubscription(
          id: 'sub_1',
          companyId: 'company_1',
          tierId: 'tier_free',
          startDate: now,
          status: SubscriptionStatus.trial,
          paymentMethod: PaymentMethod.none,
          billingInterval: BillingInterval.monthly,
          nextBillingDate: now.add(const Duration(days: 14)),
          currentPrice: 0,
          trialEndsAt: now.add(const Duration(days: 14)),
          gracePeriodDays: 7,
          createdAt: now,
          updatedAt: now,
        );

        await StorageService.addSubscription(trialSub);

        final subscriptions = await StorageService.getSubscriptions();
        final mrr = subscriptions
            .where((s) => s.status == SubscriptionStatus.active)
            .fold<double>(0, (sum, s) => sum + s.currentPrice);

        expect(mrr, 0.0); // Trial doesn't count
      });

      test('Average revenue per company calculates correctly', () {
        final metrics = PlatformMetrics(
          totalCompanies: 10,
          activeCompanies: 8,
          trialCompanies: 2,
          suspendedCompanies: 0,
          totalEmployees: 50,
          totalAdmins: 10,
          monthlyRecurringRevenue: 500,
          totalRevenue: 5000,
          companiesByTier: {},
          revenueHistory: [],
          calculatedAt: DateTime.now(),
          newCompaniesThisMonth: 2,
          churnedCompaniesThisMonth: 1,
          averageRevenuePerCompany: 50,
          totalTargetsCreated: 100,
          totalBonusesRedeemed: 75,
          totalPointsAwarded: 5000,
        );

        expect(metrics.averageRevenuePerCompany, 50.0); // 500 / 10
      });
    });

    group('PlatformMetrics Serialization', () {
      test('PlatformMetrics can be serialized and deserialized', () {
        final metrics = PlatformMetrics(
          totalCompanies: 100,
          activeCompanies: 80,
          trialCompanies: 15,
          suspendedCompanies: 5,
          totalEmployees: 500,
          totalAdmins: 100,
          monthlyRecurringRevenue: 5000,
          totalRevenue: 50000,
          companiesByTier: {
            'tier_free': 15,
            'tier_starter': 40,
            'tier_professional': 30,
            'tier_enterprise': 15,
          },
          revenueHistory: [
            RevenueByMonth(
                year: 2024, month: 1, revenue: 4000, paymentCount: 80),
            RevenueByMonth(
                year: 2024, month: 2, revenue: 4500, paymentCount: 85),
          ],
          calculatedAt: DateTime.now(),
          newCompaniesThisMonth: 10,
          churnedCompaniesThisMonth: 2,
          averageRevenuePerCompany: 50,
          totalTargetsCreated: 200,
          totalBonusesRedeemed: 150,
          totalPointsAwarded: 10000,
        );

        final json = metrics.toJson();
        final deserialized = PlatformMetrics.fromJson(json);

        expect(deserialized.totalCompanies, metrics.totalCompanies);
        expect(deserialized.activeCompanies, metrics.activeCompanies);
        expect(deserialized.monthlyRecurringRevenue,
            metrics.monthlyRecurringRevenue);
        expect(
            deserialized.revenueHistory.length, metrics.revenueHistory.length);
        expect(deserialized.companiesByTier['tier_starter'], 40);
      });
    });

    group('Edge Cases', () {
      test('Handles empty revenue history', () {
        final metrics = PlatformMetrics(
          totalCompanies: 5,
          activeCompanies: 5,
          trialCompanies: 0,
          suspendedCompanies: 0,
          totalEmployees: 25,
          totalAdmins: 5,
          monthlyRecurringRevenue: 500,
          totalRevenue: 2000,
          companiesByTier: {},
          revenueHistory: [],
          calculatedAt: DateTime.now(),
          newCompaniesThisMonth: 1,
          churnedCompaniesThisMonth: 0,
          averageRevenuePerCompany: 100,
          totalTargetsCreated: 50,
          totalBonusesRedeemed: 25,
          totalPointsAwarded: 2500,
        );

        expect(metrics.revenueHistory, isEmpty);
        expect(metrics.totalCompanies, 5);
      });

      test('Handles all suspended companies', () {
        final metrics = PlatformMetrics(
          totalCompanies: 10,
          activeCompanies: 0,
          trialCompanies: 0,
          suspendedCompanies: 10,
          totalEmployees: 0,
          totalAdmins: 10,
          monthlyRecurringRevenue: 0,
          totalRevenue: 0,
          companiesByTier: {},
          revenueHistory: [],
          calculatedAt: DateTime.now(),
          newCompaniesThisMonth: 0,
          churnedCompaniesThisMonth: 10,
          averageRevenuePerCompany: 0,
          totalTargetsCreated: 0,
          totalBonusesRedeemed: 0,
          totalPointsAwarded: 0,
        );

        expect(metrics.suspendedCompanies, 10);
        expect(metrics.activeCompanies, 0);
        expect(metrics.churnRate, 100.0); // All churned
      });

      test('Handles very large numbers', () {
        final metrics = PlatformMetrics(
          totalCompanies: 10000,
          activeCompanies: 9500,
          trialCompanies: 400,
          suspendedCompanies: 100,
          totalEmployees: 500000,
          totalAdmins: 10000,
          monthlyRecurringRevenue: 950000,
          totalRevenue: 10000000,
          companiesByTier: {},
          revenueHistory: [],
          calculatedAt: DateTime.now(),
          newCompaniesThisMonth: 1000,
          churnedCompaniesThisMonth: 50,
          averageRevenuePerCompany: 95,
          totalTargetsCreated: 100000,
          totalBonusesRedeemed: 75000,
          totalPointsAwarded: 5000000,
        );

        expect(metrics.totalCompanies, 10000);
        expect(metrics.monthlyRecurringRevenue, 950000);
        expect(metrics.growthRate, 10.0); // (1000/10000) * 100
      });
    });

    group('Monthly New Companies', () {
      test('Counts new companies this month correctly', () async {
        final now = DateTime.now();
        final startOfMonth = DateTime(now.year, now.month, 1);

        final oldCompany = Company(
          id: 'old_company',
          name: 'Old Company',
          contactEmail: 'old@test.com',
          adminUserId: 'admin1',
          createdAt: startOfMonth.subtract(const Duration(days: 5)),
          isActive: true,
        );
        final newCompany = Company(
          id: 'new_company',
          name: 'New Company',
          contactEmail: 'new@test.com',
          adminUserId: 'admin2',
          createdAt: startOfMonth.add(const Duration(days: 2)),
          isActive: true,
        );

        await StorageService.addCompany(oldCompany);
        await StorageService.addCompany(newCompany);

        final companies = await StorageService.getCompanies();
        final newCompaniesThisMonth =
            companies.where((c) => c.createdAt.isAfter(startOfMonth)).length;

        expect(newCompaniesThisMonth, 1);
      });
    });

    group('Subscription Status Metrics', () {
      test('Counts different subscription statuses correctly', () async {
        final companies = List.generate(
          5,
          (index) => Company(
            id: 'company_$index',
            name: 'Company $index',
            contactEmail: 'admin$index@test.com',
            adminUserId: 'admin$index',
            createdAt: DateTime.now(),
            isActive: true,
          ),
        );

        for (final company in companies) {
          await StorageService.addCompany(company);
        }

        final now = DateTime.now();
        final subscriptions = [
          CompanySubscription(
            id: 'sub_0',
            companyId: 'company_0',
            tierId: 'tier_starter',
            startDate: now,
            status: SubscriptionStatus.active,
            paymentMethod: PaymentMethod.creditCard,
            billingInterval: BillingInterval.monthly,
            nextBillingDate: now.add(const Duration(days: 30)),
            currentPrice: 29,
            gracePeriodDays: 7,
            createdAt: now,
            updatedAt: now,
          ),
          CompanySubscription(
            id: 'sub_1',
            companyId: 'company_1',
            tierId: 'tier_starter',
            startDate: now,
            status: SubscriptionStatus.active,
            paymentMethod: PaymentMethod.creditCard,
            billingInterval: BillingInterval.monthly,
            nextBillingDate: now.add(const Duration(days: 30)),
            currentPrice: 29,
            gracePeriodDays: 7,
            createdAt: now,
            updatedAt: now,
          ),
          CompanySubscription(
            id: 'sub_2',
            companyId: 'company_2',
            tierId: 'tier_free',
            startDate: now,
            status: SubscriptionStatus.trial,
            paymentMethod: PaymentMethod.none,
            billingInterval: BillingInterval.monthly,
            nextBillingDate: now.add(const Duration(days: 14)),
            currentPrice: 0,
            trialEndsAt: now.add(const Duration(days: 14)),
            gracePeriodDays: 7,
            createdAt: now,
            updatedAt: now,
          ),
          CompanySubscription(
            id: 'sub_3',
            companyId: 'company_3',
            tierId: 'tier_starter',
            startDate: now,
            status: SubscriptionStatus.pastDue,
            paymentMethod: PaymentMethod.creditCard,
            billingInterval: BillingInterval.monthly,
            nextBillingDate: now.subtract(const Duration(days: 5)),
            currentPrice: 29,
            gracePeriodDays: 7,
            createdAt: now,
            updatedAt: now,
          ),
          CompanySubscription(
            id: 'sub_4',
            companyId: 'company_4',
            tierId: 'tier_starter',
            startDate: now,
            status: SubscriptionStatus.suspended,
            paymentMethod: PaymentMethod.creditCard,
            billingInterval: BillingInterval.monthly,
            nextBillingDate: now.add(const Duration(days: 30)),
            currentPrice: 29,
            gracePeriodDays: 7,
            createdAt: now,
            updatedAt: now,
          ),
        ];

        for (final sub in subscriptions) {
          await StorageService.addSubscription(sub);
        }

        final allSubs = await StorageService.getSubscriptions();
        final activeCount =
            allSubs.where((s) => s.status == SubscriptionStatus.active).length;
        final trialCount =
            allSubs.where((s) => s.status == SubscriptionStatus.trial).length;
        final pastDueCount =
            allSubs.where((s) => s.status == SubscriptionStatus.pastDue).length;
        final suspendedCount = allSubs
            .where((s) => s.status == SubscriptionStatus.suspended)
            .length;

        expect(activeCount, 2);
        expect(trialCount, 1);
        expect(pastDueCount, 1);
        expect(suspendedCount, 1);
      });
    });
  });
}
