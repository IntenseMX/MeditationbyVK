import 'package:flutter/material.dart';

/// Animation duration constants for consistent pacing across the app
/// Aligned with Material 3 motion system for emphasized easing (50% slower for calm UX)
class AnimationDurations {
  // Material 3 emphasized durations (paired with emphasized easing) - slowed 50%
  static const Duration short1 = Duration(milliseconds: 75);   // Micro interactions
  static const Duration short2 = Duration(milliseconds: 150);  // Small elements
  static const Duration short3 = Duration(milliseconds: 225);  // Quick transitions
  static const Duration short4 = Duration(milliseconds: 300);  // Standard micro

  static const Duration medium1 = Duration(milliseconds: 375); // Default transitions
  static const Duration medium2 = Duration(milliseconds: 450); // Standard UI changes
  static const Duration medium3 = Duration(milliseconds: 525); // Moderate emphasis
  static const Duration medium4 = Duration(milliseconds: 600); // Full emphasis

  static const Duration long1 = Duration(milliseconds: 675);   // Complex transitions
  static const Duration long2 = Duration(milliseconds: 750);   // Extended emphasis
  static const Duration long3 = Duration(milliseconds: 825);   // Very emphasized
  static const Duration long4 = Duration(milliseconds: 900);   // Maximum emphasis

  // Legacy durations (remapped to Material 3, slowed 50%)
  static const Duration fast = short4;          // 300ms
  static const Duration normal = medium2;       // 450ms
  static const Duration slow = long2;           // 750ms
  static const Duration screenTransition = medium4; // 600ms

  // Custom meditation-specific durations
  static const Duration verySlow = Duration(milliseconds: 800);
  static const Duration extraSlow = Duration(milliseconds: 1200);

  // Breathing animations (kept custom for meditation UX)
  static const Duration breatheIn = Duration(milliseconds: 4000);
  static const Duration hold = Duration(milliseconds: 2000);
  static const Duration breatheOut = Duration(milliseconds: 4000);
}

/// Reusable animation curves for consistent feel
class AnimationCurves {
  // Material 3 official motion curves (manual definitions for compatibility)
  static const Curve standardEasing = Cubic(0.2, 0.0, 0.0, 1.0); // Material 3 standard
  static const Curve emphasized = Cubic(0.05, 0.7, 0.1, 1.0); // Material 3 emphasized
  static const Curve emphasizedDecelerate = Cubic(0.3, 0.0, 0.8, 0.15); // Material 3 decelerate
  static const Curve emphasizedAccelerate = Cubic(0.3, 0.0, 0.8, 0.15); // Material 3 accelerate

  // Legacy curves for compatibility
  static const Curve easeIn = Curves.easeInCubic;
  static const Curve easeOut = Curves.easeOutCubic;

  // Entrance/Exit curves using Material 3
  static const Curve entrance = emphasized; // Use emphasized for entrances
  static const Curve exit = Curves.easeInCubic;

  // Bouncy curves (use sparingly)
  static const Curve bounce = Curves.elasticOut;
  static const Curve sharp = Curves.easeInOutQuad;

  // Breathing curves - smooth wave-like motion
  static const Curve breathe = Curves.easeInOutSine;
}

/// Common animation configurations
class AnimationConfig {
  // Breathing circle defaults
  static const double breathingCircleBaseSize = 100.0;
  static const double breathingCircleMaxScale = 1.3;
  static const double breathingCircleMinScale = 0.8;

  // Play button defaults
  static const double playButtonSize = 80.0;
  static const double playButtonScale = 0.9;

  // Gradient animation
  static const double gradientOpacity = 0.15;

  // Stagger delay between items
  static const Duration staggerDelay = Duration(milliseconds: 50);
}
