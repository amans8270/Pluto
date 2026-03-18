class AppConfig {
  AppConfig._();

  // ── Dev / staging / prod switch via --dart-define ─────────────────────────
  static const String env = String.fromEnvironment('ENV', defaultValue: 'dev');

  static String get apiBaseUrl {
    switch (env) {
      case 'prod': return 'https://api.pluto.app/api/v1';
      case 'staging': return 'https://api-staging.pluto.app/api/v1';
      default: return 'http://10.0.2.2:8080/api/v1'; // Android emulator
    }
  }

  static String get wsBaseUrl {
    switch (env) {
      case 'prod': return 'wss://api.pluto.app/ws';
      case 'staging': return 'wss://api-staging.pluto.app/ws';
      default: return 'ws://10.0.2.2:8080/ws';
    }
  }

  // Google Maps API key (set via --dart-define or secrets)
  static const String googleMapsApiKey = String.fromEnvironment('GOOGLE_MAPS_KEY', defaultValue: '');

  // Razorpay key
  static const String razorpayKey = String.fromEnvironment('RAZORPAY_KEY', defaultValue: '');
}
