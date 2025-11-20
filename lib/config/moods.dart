import 'package:flutter/material.dart';
import '../domain/mood.dart';

/// Mood configuration and constants (MVP hardcoded data).
class MoodConfig {
  // Carousel card dimensions
  static const double cardWidth = 200.0;
  static const double cardHeight = 230.0;
  static const double iconSize = 64.0;
  static const double titleFontSize = 20.0;
  static const double taglineFontSize = 12.0;

  // Detail header decorative card dimensions
  static const double headerCardWidth = 240.0;
  static const double headerCardHeight = 180.0;

  // Hardcoded MVP moods
  static const List<Mood> moods = <Mood>[
    Mood(
      id: 'calm',
      name: 'Calm Me',
      tagline: 'Calm your mind',
      description:
          'A gentle reset for restless thoughts. Breathe deeper, soften your nervous system, and return to ease.',
      icon: Icons.self_improvement,
      categoryIds: <String>['stress', 'anxiety'],
      tags: <String>['calm', 'reset', 'soothe', 'music'],
    ),
    Mood(
      id: 'focus',
      name: 'Focus',
      tagline: 'Sharpen your focus',
      description:
          'Cut through mental noise and find your flow. Center your attention and channel calm, steady energy.',
      icon: Icons.psychology,
      categoryIds: <String>['focus', 'productivity'],
      tags: <String>['focus', 'flow', 'productivity', 'music'],
    ),
    Mood(
      id: 'sleep',
      name: 'Sleep',
      tagline: 'Sleep well tonight',
      description:
          'Let the day melt away as your body unwinds. Drift into deep, unhurried rest with a quiet mind.',
      icon: Icons.nightlight_round,
      categoryIds: <String>['sleep', 'relaxation'],
      tags: <String>['sleep', 'night', 'unwind', 'music'],
    ),
  ];

  static Mood? findById(String moodId) {
    try {
      return moods.firstWhere((m) => m.id == moodId);
    } catch (_) {
      return null;
    }
  }
}


