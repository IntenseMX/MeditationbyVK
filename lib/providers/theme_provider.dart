import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/theme_presets.dart';

// Simple notifier for theme mode
const String _kThemeModeKey = 'theme_mode_v1';

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.light; // default explicit light to avoid system-dark surprises

  void toggleTheme() {
    final next = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    setTheme(next);
  }

  void setTheme(ThemeMode mode) {
    state = mode;
    _persist(mode);
  }

  Future<void> _persist(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kThemeModeKey, mode.name);
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  () => ThemeModeNotifier(),
);

// Provider for checking if dark mode is enabled
final isDarkModeProvider = Provider<bool>((ref) {
  final themeMode = ref.watch(themeModeProvider);
  return themeMode == ThemeMode.dark;
});

// Selected theme preset key persistence
const String _kSelectedThemeKey = 'selected_theme_key_v1';

class ThemeSelectionState {
  final String selectedKey;
  const ThemeSelectionState(this.selectedKey);
}

class ThemeSelectionNotifier extends Notifier<ThemeSelectionState> {
  @override
  ThemeSelectionState build() {
    // Default to first preset
    return const ThemeSelectionState('emerald_teal');
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final key = prefs.getString(_kSelectedThemeKey);
    if (key != null && kThemePresets.any((p) => p.key == key)) {
      state = ThemeSelectionState(key);
    }

    // Load persisted theme mode and apply globally so presets don't default to light
    final modeStr = prefs.getString(_kThemeModeKey);
    if (modeStr != null) {
      final ThemeMode mode = ThemeMode.values.firstWhere(
        (m) => m.name == modeStr,
        orElse: () => ThemeMode.system,
      );
      ref.read(themeModeProvider.notifier).setTheme(mode);
    }
  }

  Future<void> select(String key) async {
    if (kThemePresets.any((p) => p.key == key)) {
      state = ThemeSelectionState(key);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kSelectedThemeKey, key);
    }
  }

  ThemePreset get currentPreset =>
      kThemePresets.firstWhere((p) => p.key == state.selectedKey, orElse: () => kThemePresets.first);
}

final themeSelectionProvider = NotifierProvider<ThemeSelectionNotifier, ThemeSelectionState>(
  () => ThemeSelectionNotifier(),
);

// Expose ready-to-use ThemeData for MaterialApp
final currentLightThemeProvider = Provider<ThemeData>((ref) {
  final sel = ref.watch(themeSelectionProvider);
  final preset = kThemePresets.firstWhere((p) => p.key == sel.selectedKey, orElse: () => kThemePresets.first);
  return buildThemeFromPreset(preset, isDark: false);
});

final currentDarkThemeProvider = Provider<ThemeData>((ref) {
  final sel = ref.watch(themeSelectionProvider);
  final preset = kThemePresets.firstWhere((p) => p.key == sel.selectedKey, orElse: () => kThemePresets.first);
  return buildThemeFromPreset(preset, isDark: true);
});