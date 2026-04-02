class AppConfig {
  AppConfig._();

  // ── Dev / staging / prod switch via --dart-define ─────────────────────────
  static const String env = String.fromEnvironment('ENV', defaultValue: 'dev');

  // ── Supabase Configuration ────────────────────────────────────────────────
  // SECURITY: NEVER hardcode real keys. Always use --dart-define at build time.
  // Example: flutter build apk --dart-define=SUPABASE_URL=https://xxx.supabase.co
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
  );

  // ── API Configuration ────────────────────────────────────────────────────
  static String get apiBaseUrl {
    switch (env) {
      case 'prod':
        return 'https://pluto.fastapicloud.dev/api/v1/';
      case 'staging':
        return 'https://pluto.fastapicloud.dev/api/v1/';
      default:
        return 'http://10.0.2.2:8080/api/v1/'; // Android emulator localhost
    }
  }

  static String get wsBaseUrl {
    switch (env) {
      case 'prod':
        return 'wss://pluto.fastapicloud.dev/ws';
      case 'staging':
        return 'wss://pluto.fastapicloud.dev/ws';
      default:
        return 'ws://10.0.2.2:8080/ws'; // Android emulator localhost
    }
  }

  // Google Maps API key (set via --dart-define)
  static const String googleMapsApiKey =
      String.fromEnvironment('GOOGLE_MAPS_KEY');

  // Razorpay key (set via --dart-define)
  static const String razorpayKey =
      String.fromEnvironment('RAZORPAY_KEY');

  // ── Validation ───────────────────────────────────────────────────────────
  static void validateConfig() {
    if (supabaseUrl.isEmpty) {
      throw Exception('SUPABASE_URL must be set via --dart-define');
    }
    if (supabaseAnonKey.isEmpty) {
      throw Exception('SUPABASE_ANON_KEY must be set via --dart-define');
    }
  }
}
