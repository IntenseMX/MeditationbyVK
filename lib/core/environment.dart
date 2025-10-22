class EnvConfig {
  // Toggle via --dart-define=USE_EMULATOR=true|false (defaults to false)
  static const bool useEmulator = (const String.fromEnvironment('USE_EMULATOR', defaultValue: 'false') == 'true');

  // Firebase Emulator Configuration
  static const String host = 'localhost';
  static const int firestorePort = 8080;
  static const int authPort = 9099;
  static const int storagePort = 9199;

  // Environment
  static const bool isDevelopment = true;
  static const bool isProduction = !isDevelopment;

  // Feature Flags
  static const bool enableAnalytics = false; // Disable in dev
  static const bool enableCrashlytics = false; // Disable in dev
}