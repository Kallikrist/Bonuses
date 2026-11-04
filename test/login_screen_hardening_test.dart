import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:bonuses/providers/app_provider.dart';
import 'package:bonuses/screens/login_screen.dart';

void main() {
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

  testWidgets('login has no demo passwords or unauthenticated reset chrome',
      (tester) async {
    await tester.pumpWidget(loginApp());
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Create Company'), findsOneWidget);

    expect(find.text('Demo Accounts:'), findsNothing);
    expect(find.textContaining('password123'), findsNothing);
    expect(find.textContaining('utilif123'), findsNothing);
    expect(find.text('🔄 Reset Demo Data'), findsNothing);
    expect(find.text('Reset Demo Data'), findsNothing);
    expect(find.text('🔑 Reset Password for User'), findsNothing);
    expect(find.text('Reset Password for User'), findsNothing);
    expect(find.text('👥 Debug Users'), findsNothing);
    expect(find.text('🧪 Test Supabase Integration'), findsNothing);
  });

  testWidgets('login uses theme colors in dark mode', (tester) async {
    await tester.pumpWidget(loginApp(mode: ThemeMode.dark));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);

    final card = tester.widget<Card>(find.byType(Card));
    final darkScheme = ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.dark,
    );
    expect(card.color, darkScheme.surface);

    final subtitle = tester.widget<Text>(
      find.text('Track sales targets and earn points!'),
    );
    expect(subtitle.style?.color, darkScheme.onSurfaceVariant);
  });
}
