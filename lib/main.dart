import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/app_provider.dart';
import 'screens/login_screen.dart';
import 'screens/employee_dashboard.dart';
import 'screens/admin_dashboard.dart';
import 'screens/onboarding_screen.dart';

void main() {
  runApp(const BonusesApp());
}

class BonusesApp extends StatelessWidget {
  const BonusesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AppProvider(),
      child: MaterialApp(
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
        home: const AppWrapper(),
        debugShowCheckedModeBanner: false,
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

  @override
  void initState() {
    super.initState();
    _checkOnboardingStatus();
  }

  Future<void> _checkOnboardingStatus() async {
    final appProvider = context.read<AppProvider>();
    final isComplete = await appProvider.isOnboardingComplete();
    setState(() {
      _isOnboardingComplete = isComplete;
      _isCheckingOnboarding = false;
    });

    if (isComplete) {
      appProvider.initialize();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingOnboarding) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (!_isOnboardingComplete) {
      return const OnboardingScreen();
    }

    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        if (appProvider.isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
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
