import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bonuses/providers/app_provider.dart';
import 'package:bonuses/screens/login_screen.dart';
import 'package:bonuses/screens/onboarding_screen.dart';

const _removedLoginChrome = [
  'Demo Accounts:',
  'password123',
  'utilif123',
  'Reset Demo Data',
  'Reset Password for User',
  'Reset Password',
  'Debug Users',
  'Test Supabase Integration',
  'Test Create Jon2 Employee',
  'Test Create Bonus',
  'Comprehensive DB Test',
  'Check Password Status',
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late String loginSource;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  setUpAll(() {
    loginSource = File('lib/screens/login_screen.dart').readAsStringSync();
  });

  Widget loginApp({ThemeMode mode = ThemeMode.light}) {
    return ChangeNotifierProvider(
      create: (_) => AppProvider(),
      child: MaterialApp(
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.light,
          ),
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.dark,
          ),
        ),
        themeMode: mode,
        home: const LoginScreen(),
      ),
    );
  }

  ColorScheme schemeFor(Brightness brightness) {
    return ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: brightness,
    );
  }

  test('login_screen.dart has no unauthenticated reset or hardcoded demo colors',
      () {
    expect(loginSource.contains('_resetPasswordForUser'), isFalse);
    expect(loginSource.contains('_resetDemoData'), isFalse);
    expect(loginSource.contains('StorageService'), isFalse);
    expect(loginSource.contains('savePassword'), isFalse);
    expect(loginSource.contains('Colors.blue'), isFalse);
    expect(loginSource.contains('Colors.grey'), isFalse);
    expect(loginSource.contains('Colors.white'), isFalse);
    expect(loginSource.contains('colorScheme'), isTrue);

    for (final chrome in _removedLoginChrome) {
      expect(
        loginSource.contains(chrome),
        isFalse,
        reason: 'logged-out login source must not contain "$chrome"',
      );
    }
  });

  testWidgets('login has no demo passwords or unauthenticated reset chrome',
      (tester) async {
    await tester.pumpWidget(loginApp());
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Create Company'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.byType(ElevatedButton), findsOneWidget);

    for (final chrome in _removedLoginChrome) {
      expect(
        find.textContaining(chrome),
        findsNothing,
        reason: 'logged-out login must not show "$chrome"',
      );
    }
  });

  testWidgets('failed login does not offer unauthenticated password reset',
      (tester) async {
    await tester.pumpWidget(loginApp());
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'nobody@example.com',
    );
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'password123',
    );
    await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Invalid email or password'), findsOneWidget);
    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.textContaining('Reset Password'), findsNothing);
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('Create Company remains on the logged-out screen',
      (tester) async {
    await tester.pumpWidget(loginApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Create Company'));
    await tester.pumpAndSettle();

    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(find.text('Welcome to Bonuses'), findsOneWidget);
  });

  testWidgets('login uses theme colors in light mode', (tester) async {
    await tester.pumpWidget(loginApp());
    await tester.pumpAndSettle();
    _expectThemedLoginChrome(tester, schemeFor(Brightness.light));
  });

  testWidgets('login uses theme colors in dark mode', (tester) async {
    await tester.pumpWidget(loginApp(mode: ThemeMode.dark));
    await tester.pumpAndSettle();
    _expectThemedLoginChrome(tester, schemeFor(Brightness.dark));
  });
}

void _expectThemedLoginChrome(WidgetTester tester, ColorScheme expected) {
  expect(find.byType(LoginScreen), findsOneWidget);
  expect(find.text('Login'), findsOneWidget);

  final card = tester.widget<Card>(find.byType(Card));
  expect(card.color, expected.surface);

  final subtitle = tester.widget<Text>(
    find.text('Track sales targets and earn points!'),
  );
  expect(subtitle.style?.color, expected.onSurfaceVariant);

  final loginButton = tester.widget<ElevatedButton>(
    find.widgetWithText(ElevatedButton, 'Login'),
  );
  expect(
    loginButton.style?.backgroundColor?.resolve(const <WidgetState>{}),
    expected.primary,
  );
  expect(
    loginButton.style?.foregroundColor?.resolve(const <WidgetState>{}),
    expected.onPrimary,
  );
}
