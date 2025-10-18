class AppConstants {
  // App Info
  static const String appName = 'Meditation by VK';
  static const String appVersion = '1.0.0';

  // API & Network
  static const Duration networkTimeout = Duration(seconds: 30);
  static const int maxRetries = 3;

  // UI Constants
  static const double defaultPadding = 16.0;
  static const double defaultRadius = 12.0;
  static const Duration animationDuration = Duration(milliseconds: 300);

  // Meditation Settings
  static const int minMeditationDuration = 60; // seconds
  static const int maxMeditationDuration = 3600; // 1 hour

  // Cache Keys
  static const String userCacheKey = 'user_data';
  static const String settingsCacheKey = 'app_settings';
  static const String progressCacheKey = 'user_progress';
}