import 'package:flutter/foundation.dart';

/// Centralized configuration for in-app subscriptions.
/// Update product identifiers to match App Store Connect and Google Play Console.
class SubscriptionConfig {
  // Single SKU: Monthly subscription unlocking premium meditations
  static const String monthlyProductId = 'com.romaninc.meditation.premium.monthly';

  // For future expansion (keep data-driven pattern)
  static const List<String> productIds = <String>[
    monthlyProductId,
  ];

  // Display fallback if store pricing not yet loaded
  static const String monthlyDisplayPriceFallback = '4.99/month';

  // Feature flags and safe fallbacks
  static const bool enableRestore = true; // iOS typically supports restore

  /// Set to false during development to disable IAP initialization.
  /// Prevents "billing API not supported" spam when stores aren't configured.
  /// Set to true when ready to test with App Store/Play Store.
  static const bool enableIAP = false; // TODO: Set to true before production testing

  static void assertConfigured() {
    assert(productIds.isNotEmpty, 'SubscriptionConfig.productIds must not be empty');
    if (kDebugMode) {
      // Helpful log during development
      // ignore: avoid_print
      print('[SubscriptionConfig] Using productIds: ' + productIds.join(','));
    }
  }
}


