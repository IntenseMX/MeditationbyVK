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
  static const Duration long4 = Duration(milliseconds: 1200);   // Maximum emphasis

  // Legacy durations (remapped to Material 3, slowed 50%)
  static const Duration fast = short4;          // 300ms
  static const Duration normal = medium2;       // 450ms
  static const Duration slow = long2;           // 750ms
  static const Duration screenTransition = long4; // 900ms (calm pacing)

  // Custom meditation-specific durations
  static const Duration verySlow = Duration(milliseconds: 800);
  static const Duration extraSlow = Duration(milliseconds: 1200);
  static const Duration ctaReveal = Duration(milliseconds: 1350);

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
  static const double breathingCircleMaxScale = 1.1;
  static const double breathingCircleMinScale = 0.6;

  // Play button defaults
  static const double playButtonSize = 80.0;
  static const double playButtonScale = 0.9;

  // Gradient animation
  static const double gradientOpacity = 0.15;

  // Stagger delay between items
  static const Duration staggerDelay = Duration(milliseconds: 50);

  // Player screen glassmorphism card
  static const double cardMargin = 20.0;
  static const double cardOpacity = 0.85;
  static const double cardCornerRadius = 32.0;
  static const double cardBlurSigma = 20.0;
  static const double cardShadowOpacity = 0.1;
  static const double cardBlurRadius = 40.0;
  static const double cardSpreadRadius = 5.0;
  static const double cardPadding = 24.0;

  // Waveform slider
  static const double waveformBarWidth = 2.0;
  static const int waveformBarCount = 50;
  static const Duration waveformTransition = Duration(milliseconds: 150);

  // Control buttons
  static const double skipButtonSize = 60.0;
  static const double controlButtonSize = 48.0;
}

/// Player screen animation configuration
class PlayerAnimationConfig {
  // Background gradient cycle (slower for calm feel)
  static const Duration gradientCycle = Duration(seconds: 20);
  
  // Card entrance animation
  static const Duration cardEntrance = AnimationDurations.medium4; // 600ms
  static const Curve cardEntranceCurve = AnimationCurves.entrance;
  
  // Image scale animation
  static const Duration imageScale = AnimationDurations.normal; // 450ms
  static const Curve imageScaleCurve = AnimationCurves.entrance;
  
  // Control button animations
  static const Duration buttonPress = AnimationDurations.fast; // 300ms
  static const Curve buttonPressCurve = AnimationCurves.standardEasing;
}

/// Splash-specific animation configuration to avoid magic numbers
class SplashAnimationConfig {
  // Background motion
  static const Duration gradientCycle = Duration(milliseconds: 12000);
  static const Duration parallaxPeriod = Duration(milliseconds: 18000);

  // CTA fallback (show after delay regardless of data readiness)
  static const Duration ctaFallbackDelay = Duration(milliseconds: 4000);

  // Glow pulse
  static const Duration glowPulse = Duration(milliseconds: 5000);

  // Particles
  static const int particleCount = 12;
  static const double particleMinSize = 1.5;
  static const double particleMaxSize = 3.0;
  static const double particleMaxOffset = 0.04; // as fraction of screen
  static const double particleBaseOpacity = 0.10;
  static const Duration particleDriftPeriod = Duration(milliseconds: 16000);

  // Shimmer
  static const Duration shimmerSweep = Duration(milliseconds: 3500);
  static const double shimmerWidth = 0.25; // fraction of text width

  // CTA stagger
  static const Duration ctaStagger = Duration(milliseconds: 120);
  static const Duration ctaItemDuration = Duration(milliseconds: 450);
}

/// Coordinated exit for Splash → Home (no magic numbers in widgets)
class SplashExitConfig {
  // Master timeline
  static const Duration exit = Duration(milliseconds: 900);

  // Logo
  static const double logoPopScale = 1.08; // quick pop before shrink
  static const double logoEndScale = 0.84;
  static const double logoLiftY = -8.0; // subtle lift

  // Glow
  static const double glowEndScale = 1.2;
  static const double glowEndOpacity = 0.0;

  // Title/tagline
  static const double titleEndOpacity = 0.0;
  static const double subtitleEndOpacity = 0.0;
  static const double textExitDy = 0.06; // fraction of screen height

  // CTAs
  static const Duration ctaExit = Duration(milliseconds: 225);
}

/// Player layout configuration (avoid magic numbers in widgets)
class PlayerLayoutConfig {
  // Base estimated content height (title, controls, times, slider, spacing)
  static const double baseContentHeight = 400.0;

  // When estimated content exceeds this ratio of available height, enable scroll
  static const double scrollThresholdRatio = 0.6;

  // Clamp text scale used for estimation to avoid extreme expansion
  static const double minTextScale = 1.0;
  static const double maxTextScale = 2.0;

  // Portrait flex breakpoints (by height) for image/content split
  static const double smallHeightBreakpoint = 650.0;
  static const double largeHeightBreakpoint = 900.0;

  // Content card maximum width (tablet/desktop)
  static const double maxContentWidth = 500.0;

  // Image size constraints for portrait dynamic sizing
  static const double minImageSize = 240.0;
  static const double maxImageSize = 500.0;

  // Gap between image and content
  static const double contentGap = 24.0;
}

/// Category grid UI tuning (centralizes sizes to avoid magic numbers)
class CategoryGridConfig {
  // Grid outer padding
  static const double gridPaddingH = 20.0;
  static const double gridPaddingV = 16.0;

  // Unified grid spacing
  static const double gridSpacing = 9.0;

  // Preferred tile width to derive column count responsively
  static const double preferredTileWidth = 112.0; // ~3 columns on ~390dp screens

  // Grid item shape
  static const double childAspectRatio = 1.00;

  // Card content padding
  static const double cardPadding = 9.0;

  // Leading icon sizing
  static const double iconContainerSize = 27.0;
  static const double iconSize = 18.0;

  // Fixed layout regions to hard-center icon independent of text
  static const double iconRegionHeight = 42.0;
  static const double titleAreaHeight = 18.0;
  static const double iconTitleGap = 6.0;

  // Typography
  static const double titleFontSize = 12.0;
  static const double subtitleFontSize = 10.0;

  // Minimum text lane width (dp) to allow 3 columns without truncation
  static const double minTitleTextWidthDp = 82.0;
}