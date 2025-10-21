import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/app_provider.dart';
import 'screens/login_screen.dart';
import 'screens/employee_dashboard.dart';
import 'screens/admin_dashboard.dart';
import 'screens/onboarding_screen.dart';
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

        if (appProvider.isAdmin) {
          return const AdminDashboard();
        } else {
          return const EmployeeDashboard();
        }
      },
    );
  }
}
