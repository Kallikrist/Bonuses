/// Compile-time configuration loaded from `--dart-define` values.
///
/// Credentials are never hardcoded. Provide them when running:
/// `flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...`
/// Optional Stripe publishable key (client-safe). The Stripe **secret** key
/// must not be passed to the app; it lives in the `stripe-secret` Edge Function.
/// `--dart-define=STRIPE_PUBLISHABLE_KEY=...`
class AppConfig {
  AppConfig._();

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  static const String stripePublishableKey = String.fromEnvironment(
    'STRIPE_PUBLISHABLE_KEY',
    defaultValue: '',
  );

  static const bool demoMode = bool.fromEnvironment(
    'DEMO_MODE',
    defaultValue: true,
  );

  static const bool debugMode = bool.fromEnvironment(
    'DEBUG_MODE',
    defaultValue: true,
  );

  /// True only when both credentials are present and are not placeholders.
  static bool get isSupabaseConfigured {
    if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
      return false;
    }
    if (supabaseUrl == 'https://your-project.supabase.co' ||
        supabaseAnonKey == 'your_supabase_anon_key_here') {
      return false;
    }
    return true;
  }

  /// Secret-key Stripe calls stay on the local mock path unless demo is off
  /// and Supabase is configured. The Edge Function then holds `STRIPE_SECRET_KEY`.
  static bool get useMockStripe => demoMode || !isSupabaseConfigured;
}
