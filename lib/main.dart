import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/app_provider.dart';
import 'models/user.dart';
import 'models/company.dart';
import 'screens/login_screen.dart';
import 'screens/employee_dashboard.dart';
import 'screens/admin_dashboard.dart';
import 'screens/super_admin_dashboard.dart';
import 'screens/onboarding_screen.dart';
import 'screens/company_selection_screen.dart';
import 'widgets/branded_splash_screen.dart';

void main() {
  runApp(const BonusesApp());
}

class BonusesApp extends StatelessWidget {
  const BonusesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AppProvider(),
      child: Consumer<AppProvider>(
        builder: (context, appProvider, child) {
          return MaterialApp(
            title: 'Bonuses App',
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.blue,
                brightness: Brightness.light,
              ),
              useMaterial3: true,
              appBarTheme: const AppBarTheme(
                centerTitle: true,
                elevation: 0,
              ),
            ),
            darkTheme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.blue,
                brightness: Brightness.dark,
              ),
              useMaterial3: true,
              appBarTheme: const AppBarTheme(
                centerTitle: true,
                elevation: 0,
              ),
            ),
            themeMode:
                appProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            home: const AppWrapper(),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}

class AppWrapper extends StatefulWidget {
  const AppWrapper({super.key});

  @override
  State<AppWrapper> createState() => _AppWrapperState();
}

class _AppWrapperState extends State<AppWrapper> {
  bool _isCheckingOnboarding = true;
  bool _isOnboardingComplete = false;
  String? _companyName;

  @override
  void initState() {
    super.initState();
    _checkOnboardingStatus();
  }

  Future<void> _checkOnboardingStatus() async {
    final appProvider = context.read<AppProvider>();
    final isComplete = await appProvider.isOnboardingComplete();

    if (isComplete) {
      // Initialize the app provider first
      await appProvider.initialize();

      // Get the company name after initialization
      final companyName = await _getCompanyName(appProvider);

      setState(() {
        _companyName = companyName;
      });

      // Add a delay to show the splash screen (for demo purposes)
      // You can remove this delay in production
      await Future.delayed(const Duration(seconds: 8));
    } else {
      // Add a delay to show the splash screen even for onboarding
      await Future.delayed(const Duration(seconds: 8));
    }

    setState(() {
      _isOnboardingComplete = isComplete;
      _isCheckingOnboarding = false;
    });
  }

  Future<String?> _getCompanyName(AppProvider appProvider) async {
    try {
      // Check if current user is super admin
      final currentUser = appProvider.currentUser;
      if (currentUser != null && currentUser.role == UserRole.superAdmin) {
        return 'Bonuses'; // Super admin sees app name
      }

      // Try to get the current user's company name from their companyNames list
      final users = await appProvider.getUsers();
      if (users.isNotEmpty) {
        final user = users.first;
        if (user.primaryCompanyId != null && user.companyNames.isNotEmpty) {
          // Find the index of the primaryCompanyId in companyIds and get the corresponding name
          final primaryCompanyId = user.primaryCompanyId!;
          final companyIndex = user.companyIds.indexOf(primaryCompanyId);
          if (companyIndex != -1 && companyIndex < user.companyNames.length) {
            return user.companyNames[companyIndex];
          }
        }
      }
      // Fallback to first company if available
      final companies = await appProvider.getCompanies();
      if (companies.isNotEmpty) {
        return companies.first.name;
      }
    } catch (e) {
      print('Error getting company name: $e');
      // If we can't get the company name, use a default
      return 'Utilif';
    }
    return 'Utilif';
  }

  Future<List<Company>> _getUserActiveCompanies(AppProvider appProvider) async {
    try {
      final user = appProvider.currentUser!;
      final allCompanies = await appProvider.getCompanies();

      // Filter to only active companies that the user has access to
      return allCompanies.where((company) {
        return user.companyIds.contains(company.id) && company.isActive;
      }).toList();
    } catch (e) {
      print('Error getting user active companies: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingOnboarding) {
      return BrandedSplashScreen(
        companyName: _companyName ?? 'Loading...',
        showProgress: true,
      );
    }

    if (!_isOnboardingComplete) {
      return const OnboardingScreen();
    }

    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        if (appProvider.isLoading) {
          return BrandedSplashScreen(
            companyName: _companyName ?? 'Bonuses',
            showProgress: true,
          );
        }

        if (appProvider.currentUser == null) {
          return const LoginScreen();
        }

        // For company status check, we'll use a FutureBuilder to handle async operations
        if (appProvider.currentUser!.role != UserRole.superAdmin &&
            appProvider.currentUser!.email != 'superadmin@platform.com') {
          return FutureBuilder<List<Company>>(
            future: _getUserActiveCompanies(appProvider),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return BrandedSplashScreen(
                  companyName: _companyName ?? 'Loading...',
                  showProgress: true,
                );
              }

              if (snapshot.hasError ||
                  snapshot.data == null ||
                  snapshot.data!.isEmpty) {
                // No active companies, show suspension screen
                return _buildCompanySuspendedScreen('No Active Companies');
              }

              final activeCompanies = snapshot.data!;
              final user = appProvider.currentUser!;

              // Check if user's primary company is active
              final primaryCompany = activeCompanies.firstWhere(
                (c) => c.id == user.primaryCompanyId,
                orElse: () => activeCompanies.first,
              );

              // If user's primary company is active, proceed with it
              if (primaryCompany.id == user.primaryCompanyId) {
                // User's primary company is active, proceed normally
                return _buildDashboardForUser(user.role);
              }

              // Primary company is not active
              if (activeCompanies.length == 1) {
                // User has only one active company, automatically switch to it
                final singleCompany = activeCompanies.first;
                WidgetsBinding.instance.addPostFrameCallback((_) async {
                  final updatedUser =
                      user.copyWith(primaryCompanyId: singleCompany.id);
                  await appProvider.updateUser(updatedUser);
                });
                return _buildDashboardForUser(user.role);
              }

              // User has multiple active companies but primary is not active
              // Show selection screen
              return CompanySelectionScreen(user: user);
            },
          );
        }

        // Super admin or no company check needed
        return _buildDashboardForUser(appProvider.currentUser!.role);
      },
    );
  }

  Widget _buildDashboardForUser(UserRole role) {
    switch (role) {
      case UserRole.superAdmin:
        return const SuperAdminDashboard();
      case UserRole.admin:
        return const AdminDashboard();
      case UserRole.employee:
        return const EmployeeDashboard();
    }
  }

  Widget _buildCompanySuspendedScreen(String companyName) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.red.shade50,
              Colors.orange.shade50,
            ],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Suspension Icon
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.block,
                    size: 80,
                    color: Colors.red.shade600,
                  ),
                ),
                const SizedBox(height: 32),

                // Title
                Text(
                  'Account Suspended',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                  ),
                ),
                const SizedBox(height: 16),

                // Company Name
                Text(
                  companyName,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Colors.red.shade600,
                  ),
                ),
                const SizedBox(height: 24),

                // Message
                Text(
                  'Your company account has been suspended by the platform administrator. Please contact your administrator or platform support for assistance.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade700,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 48),

                // Logout Button
                ElevatedButton.icon(
                  onPressed: () async {
                    final appProvider =
                        Provider.of<AppProvider>(context, listen: false);
                    await appProvider.logout();
                    // Navigate back to login
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                          builder: (context) => const LoginScreen()),
                    );
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Return to Login'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
