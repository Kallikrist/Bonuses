import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import 'onboarding_screen.dart';
import '../services/supabase_service.dart';
import '../services/storage_service.dart';
import '../models/user.dart';
import '../models/company.dart';
import '../models/bonus.dart';
import '../models/sales_target.dart';
import '../models/points_transaction.dart';
import '../models/workplace.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await context.read<AppProvider>().login(
            _emailController.text.trim(),
            _passwordController.text,
          );

      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid email or password'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.primaryContainer,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.emoji_events,
                          size: 64,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Bonuses App',
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Track sales targets and earn points!',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                        ),
                        const SizedBox(height: 32),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!value.contains('@')) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Password',
                            prefixIcon: Icon(Icons.lock),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white)
                                : const Text('Login'),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          alignment: WrapAlignment.center,
                          children: [
                            Text(
                              'Don\'t have an account?',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const OnboardingScreen(),
                                  ),
                                );
                              },
                              child: const Text('Create Company'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue[200]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Demo Accounts:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[800],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Flexible(
                                child: Text(
                                  'Admin Store: admin@store.com / password123\nAdmin Utilif: admin@utilif.com / utilif123\nEmployee: john.doe@example.com / password123\nSuper Admin: superadmin@platform.com / password123',
                                  style: TextStyle(color: Colors.blue[700]),
                                  softWrap: true,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Reset Demo Data Button
                        ElevatedButton(
                          onPressed: _resetDemoData,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('🔄 Reset Demo Data'),
                        ),
                        const SizedBox(height: 16),
                        // Test Supabase Integration Button
                        ElevatedButton(
                          onPressed: _testSupabaseIntegration,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('🧪 Test Supabase Integration'),
                        ),
                        const SizedBox(height: 8),
                        // Debug Users Button
                        ElevatedButton(
                          onPressed: _debugUsers,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('👥 Debug Users'),
                        ),
                        const SizedBox(height: 8),
                        // Test Create Jon2 Employee Button
                        ElevatedButton(
                          onPressed: _testCreateJon2Employee,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('🧪 Test Create Jon2 Employee'),
                        ),
                        const SizedBox(height: 8),
                        // Test Create Bonus Button
                        ElevatedButton(
                          onPressed: _testCreateBonus,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('🧪 Test Create Bonus'),
                        ),

                        // Comprehensive Database Test Button
                        ElevatedButton(
                          onPressed: _runComprehensiveDatabaseTest,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('🔬 Comprehensive DB Test'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _resetDemoData() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Resetting demo data...'),
            ],
          ),
        ),
      );

      // Clear all data and reinitialize
      await StorageService.clearAllData();
      await StorageService.initializeSampleData();

      Navigator.of(context).pop(); // Close loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Demo data reset successfully! Try logging in now.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Failed to reset demo data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _debugUsers() async {
    try {
      final users = await StorageService.getUsers();
      String debugInfo = 'Current Users (${users.length}):\n\n';

      for (final user in users) {
        final password = await StorageService.getPassword(user.id);
        debugInfo += '${user.email}:\n';
        debugInfo += '  ID: ${user.id}\n';
        debugInfo += '  Name: ${user.name}\n';
        debugInfo += '  Role: ${user.role}\n';
        debugInfo += '  Password: $password\n';
        debugInfo += '  Companies: ${user.companyNames.join(", ")}\n\n';
      }

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Current Users'),
          content: SingleChildScrollView(
            child: Text(debugInfo),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Debug failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _testSupabaseIntegration() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Testing Supabase integration...'),
            ],
          ),
        ),
      );

      // Test user creation
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final testUser = User(
        id: 'test_user_$timestamp',
        email: 'test_$timestamp@example.com',
        name: 'Test User $timestamp',
        role: UserRole.admin,
        companyIds: ['test_company_$timestamp'],
        companyNames: ['Test Company $timestamp'],
        companyPoints: {},
        companyRoles: {},
        createdAt: DateTime.now(),
      );

      await SupabaseService.createUser(testUser);
      print('✅ Test user created in Supabase: ${testUser.email}');

      // Test company creation
      final testCompany = Company(
        id: 'test_company_$timestamp',
        name: 'Test Company $timestamp',
        address: '123 Test St',
        adminUserId: testUser.id,
        contactEmail: 'admin_$timestamp@test.com',
        contactPhone: '123-456-7890',
        createdAt: DateTime.now(),
      );

      await SupabaseService.createCompany(testCompany);
      print('✅ Test company created in Supabase: ${testCompany.name}');

      Navigator.of(context).pop(); // Close loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Supabase test passed! Check logs for details.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Supabase test failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _testCreateJon2Employee() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Creating Jon2 employee...'),
            ],
          ),
        ),
      );

      // Create Jon2 employee
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final jon2User = User(
        id: 'jon2_$timestamp',
        email: 'jon2@example.com',
        name: 'Jon2',
        phoneNumber: '123-456-7890',
        role: UserRole.employee,
        companyIds: ['demo_company_utilif'], // Use existing company
        companyNames: ['Utilif'],
        companyPoints: {},
        companyRoles: {},
        primaryCompanyId: 'demo_company_utilif',
        totalPoints: 0,
        createdAt: DateTime.now(),
      );

      // Create user in Supabase
      await SupabaseService.createUser(jon2User);
      print('✅ Jon2 user created in Supabase: ${jon2User.email}');

      // Also create in local storage for immediate access
      await StorageService.addUser(jon2User);
      await StorageService.savePassword(jon2User.id, 'password123');
      print('✅ Jon2 user created in local storage: ${jon2User.email}');

      Navigator.of(context).pop(); // Close loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              '✅ Jon2 employee created successfully! Check the employee list.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Failed to create Jon2 employee: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _testCreateBonus() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Creating test bonus...'),
            ],
          ),
        ),
      );

      // Create test bonus with minimal required fields
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final randomSuffix = (timestamp % 10000).toString(); // Add random suffix
      final testBonus = Bonus(
        id: 'test_bonus_${timestamp}_$randomSuffix', // Make ID more unique
        name: 'Test Bonus Elko',
        description: 'Test bonus created via button',
        pointsRequired: 100,
        status: BonusStatus.available,
        createdAt: DateTime.now(),
        companyId: 'demo_company_utilif', // Use existing company
      );

      // Create bonus in Supabase
      print('DEBUG: Attempting to create bonus in Supabase...');
      print('DEBUG: Bonus data: ${testBonus.toJson()}');

      // Try raw JSON approach first
      final rawData = {
        'id':
            'test_bonus_raw_${timestamp}_$randomSuffix', // Make ID more unique
        'title': 'Test Bonus Raw',
        'description': 'Test bonus created with raw JSON',
        'points_required': 100, // Use int, not double
        'company_id': 'demo_company_utilif',
      };

      print('DEBUG: Raw data: $rawData');
      await SupabaseService.createBonusRaw(rawData);
      print('✅ Raw bonus created in Supabase');

      // Also try the model approach
      await SupabaseService.createBonus(testBonus);
      print('✅ Test bonus created in Supabase: ${testBonus.name}');

      // Also create in local storage for immediate access
      print('DEBUG: Attempting to create bonus in local storage...');
      await StorageService.addBonus(testBonus);
      print('✅ Test bonus created in local storage: ${testBonus.name}');

      Navigator.of(context).pop(); // Close loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              '✅ Test bonus created successfully! Check the bonuses list.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Failed to create test bonus: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _runComprehensiveDatabaseTest() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Running comprehensive database tests...'),
            ],
          ),
        ),
      );

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final randomSuffix = (timestamp % 10000).toString();
      final testPrefix = 'test_${timestamp}_$randomSuffix';

      print('🔬 Starting Comprehensive Database Test...');
      print('🔬 Test Prefix: $testPrefix');

      List<String> testResults = [];

      // Test 1: User Creation
      try {
        print('🔬 Test 1: Creating test user...');
        final testUser = User(
          id: '${testPrefix}_user',
          name: 'Test User $randomSuffix',
          email: 'testuser$randomSuffix@test.com',
          role: UserRole.employee,
          createdAt: DateTime.now(),
          phoneNumber: '+1234567890',
          primaryCompanyId: '${testPrefix}_company',
          workplaceIds: ['${testPrefix}_workplace'],
          workplaceNames: ['Test Workplace'],
          totalPoints: 0,
          companyPoints: {},
          companyRoles: {},
        );

        await StorageService.addUser(testUser);
        testResults.add('✅ User Creation: SUCCESS');
        print('✅ User created successfully');
      } catch (e) {
        testResults.add('❌ User Creation: FAILED - $e');
        print('❌ User creation failed: $e');
      }

      // Test 2: Company Creation
      try {
        print('🔬 Test 2: Creating test company...');
        final testCompany = Company(
          id: '${testPrefix}_company',
          name: 'Test Company $randomSuffix',
          adminUserId: '${testPrefix}_user',
          createdAt: DateTime.now(),
          contactEmail: 'admin$randomSuffix@testcompany.com',
          contactPhone: '+1234567890',
          address: '123 Test Street, Test City',
          employeeCount: '1',
        );

        await StorageService.addCompany(testCompany);
        testResults.add('✅ Company Creation: SUCCESS');
        print('✅ Company created successfully');
      } catch (e) {
        testResults.add('❌ Company Creation: FAILED - $e');
        print('❌ Company creation failed: $e');
      }

      // Test 3: Workplace Creation
      try {
        print('🔬 Test 3: Creating test workplace...');
        final testWorkplace = Workplace(
          id: '${testPrefix}_workplace',
          name: 'Test Workplace $randomSuffix',
          address: '456 Test Avenue, Test City',
          createdAt: DateTime.now(),
          companyId: '${testPrefix}_company',
        );

        await StorageService.addWorkplace(testWorkplace);
        testResults.add('✅ Workplace Creation: SUCCESS');
        print('✅ Workplace created successfully');
      } catch (e) {
        testResults.add('❌ Workplace Creation: FAILED - $e');
        print('❌ Workplace creation failed: $e');
      }

      // Test 4: Bonus Creation
      try {
        print('🔬 Test 4: Creating test bonus...');
        final testBonus = Bonus(
          id: '${testPrefix}_bonus',
          name: 'Test Bonus $randomSuffix',
          description: 'Test bonus for database testing',
          pointsRequired: 50,
          status: BonusStatus.available,
          createdAt: DateTime.now(),
          companyId: '${testPrefix}_company',
        );

        await StorageService.addBonus(testBonus);
        testResults.add('✅ Bonus Creation: SUCCESS');
        print('✅ Bonus created successfully');
      } catch (e) {
        testResults.add('❌ Bonus Creation: FAILED - $e');
        print('❌ Bonus creation failed: $e');
      }

      // Test 5: Sales Target Creation
      try {
        print('🔬 Test 5: Creating test sales target...');
        final testTarget = SalesTarget(
          id: '${testPrefix}_target',
          date: DateTime.now(),
          targetAmount: 1000.0,
          createdAt: DateTime.now(),
          createdBy: '${testPrefix}_user',
          assignedEmployeeId: '${testPrefix}_user',
          assignedEmployeeName: 'Test User $randomSuffix',
          assignedWorkplaceId: '${testPrefix}_workplace',
          assignedWorkplaceName: 'Test Workplace $randomSuffix',
          companyId: '${testPrefix}_company',
          status: TargetStatus.pending,
        );

        await StorageService.addSalesTarget(testTarget);
        testResults.add('✅ Sales Target Creation: SUCCESS');
        print('✅ Sales target created successfully');
      } catch (e) {
        testResults.add('❌ Sales Target Creation: FAILED - $e');
        print('❌ Sales target creation failed: $e');
      }

      // Test 6: Points Transaction Creation
      try {
        print('🔬 Test 6: Creating test points transaction...');
        final testTransaction = PointsTransaction(
          id: '${testPrefix}_transaction',
          userId: '${testPrefix}_user',
          points: 25,
          type: PointsTransactionType.earned,
          description: 'Test points transaction for database testing',
          date: DateTime.now(),
          companyId: '${testPrefix}_company',
        );

        await StorageService.addPointsTransaction(testTransaction);
        testResults.add('✅ Points Transaction Creation: SUCCESS');
        print('✅ Points transaction created successfully');
      } catch (e) {
        testResults.add('❌ Points Transaction Creation: FAILED - $e');
        print('❌ Points transaction creation failed: $e');
      }

      // Test 7: Data Retrieval Test
      try {
        print('🔬 Test 7: Testing data retrieval...');
        final users = await StorageService.getUsers();
        final companies = await StorageService.getCompanies();
        final bonuses = await StorageService.getBonuses();
        final targets = await StorageService.getSalesTargets();
        final transactions = await StorageService.getPointsTransactions();
        final workplaces = await StorageService.getWorkplaces();

        print('🔬 Retrieved data counts:');
        print('  - Users: ${users.length}');
        print('  - Companies: ${companies.length}');
        print('  - Bonuses: ${bonuses.length}');
        print('  - Sales Targets: ${targets.length}');
        print('  - Points Transactions: ${transactions.length}');
        print('  - Workplaces: ${workplaces.length}');

        testResults.add('✅ Data Retrieval: SUCCESS');
        print('✅ Data retrieval successful');
      } catch (e) {
        testResults.add('❌ Data Retrieval: FAILED - $e');
        print('❌ Data retrieval failed: $e');
      }

      Navigator.of(context).pop(); // Close loading dialog

      // Show results
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('🔬 Database Test Results'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: testResults
                  .map((result) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(result),
                      ))
                  .toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );

      print('🔬 Comprehensive Database Test Completed');
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Database test failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
