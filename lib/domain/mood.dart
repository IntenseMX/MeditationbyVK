import 'package:flutter/material.dart';

/// Mood domain model (UI-agnostic).
/// Colors/gradients and layout constants live in config/moods.dart and theme.
@immutable
class Mood {
  final String id;
  final String name;
  final String tagline;
  final String description;
  final IconData icon;
  final List<String> categoryIds;
  final List<String> tags;

  const Mood({
    required this.id,
    required this.name,
    required this.tagline,
    required this.description,
    required this.icon,
    required this.categoryIds,
    required this.tags,
  });
}


