class EnvConfig {
  // Toggle this to switch between emulator and production
  static const bool useEmulator = true; // Enabled for Phase 1.5 local testing

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