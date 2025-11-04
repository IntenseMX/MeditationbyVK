import 'package:flutter/material.dart';
import '../core/theme.dart';

// Opacity tuning for themed surfaces and outlines (mobile-optimized)
const double kSurfaceVariantOpacity = 0.18;    // subtle cards/sheets (reduced for mobile compositor)
const double kOnSurfaceVariantOpacity = 0.75;  // labels on subtle surfaces
const double kOutlineOpacityDefault = 0.12;    // thin borders

// Tints to make themes visibly different in light/dark (mobile-first values, increased for visibility)
const double kLightBackgroundTint = 0.50;      // primary over surface (light scaffold) - stronger tint for visibility
const double kDarkBackgroundTint  = 0.32;      // primary over surface (dark scaffold) - increased for visibility
const double kLightSurfaceTint    = 0.35;      // primary over surface (light cards/sheets) - stronger tint
const double kDarkSurfaceTint     = 0.10;      // primary over surface (dark cards/sheets) - increased for visibility

class ThemePreset {
  final String key;
  final String name;
  final ColorScheme light;
  final ColorScheme dark;
  final AppColors lightExtension;
  final AppColors darkExtension;
  final List<Color> previewGradient;

  const ThemePreset({
    required this.key,
    required this.name,
    required this.light,
    required this.dark,
    required this.lightExtension,
    required this.darkExtension,
    required this.previewGradient,
  });
}

// Helper to build a color scheme with background tinting
ColorScheme _cs({
  required Brightness b,
  required Color primary,
  required Color onPrimary,
  required Color secondary,
  required Color onSecondary,
  required Color surface,
  required Color onSurface,
  Color? tertiary,
  Color? onTertiary,
  Color? background,
  Color? onBackground,
  Color? surfaceVariant,
  Color? onSurfaceVariant,
  Color? outline,
  Color? shadow,
  Color? error,
  Color? onError,
  Color? inverseSurface,
  Color? onInverseSurface,
  Color? inversePrimary,
}) {
  final Color t = tertiary ?? secondary;
  final Color ot = onTertiary ?? onSecondary;
  final bool isLight = b == Brightness.light;

  final Color bg = background ??
      (isLight
          ? Color.alphaBlend(primary.withOpacity(kLightBackgroundTint), surface)
          : Color.alphaBlend(primary.withOpacity(kDarkBackgroundTint), surface));

  // Also tint the surface so cards/sheets follow the theme more visibly
  final Color tintedSurface = Color.alphaBlend(
    primary.withOpacity(isLight ? kLightSurfaceTint : kDarkSurfaceTint),
    surface,
  );

  final Color obg = onBackground ?? onSurface;

  return ColorScheme(
    brightness: b,
    primary: primary,
    onPrimary: onPrimary,
    secondary: secondary,
    onSecondary: onSecondary,
    tertiary: t,
    onTertiary: ot,
    error: error ?? const Color(0xFFBA1A1A),
    onError: onError ?? Colors.white,
    background: bg,
    onBackground: obg,
    surface: tintedSurface,
    onSurface: onSurface,
    surfaceVariant: surfaceVariant ?? tintedSurface.withOpacity(kSurfaceVariantOpacity),
    onSurfaceVariant: onSurfaceVariant ?? onSurface.withOpacity(kOnSurfaceVariantOpacity),
    outline: outline ?? onSurface.withOpacity(kOutlineOpacityDefault),
    shadow: shadow ?? Colors.black,
    inverseSurface: inverseSurface ?? onSurface,
    onInverseSurface: onInverseSurface ?? surface,
    inversePrimary: inversePrimary ?? secondary,
  );
}

// 12 luxury presets (background/surface/primary/secondary all differ)
final List<ThemePreset> kThemePresets = [
  // 01 Emerald Teal
  ThemePreset(
    key: 'emerald_teal',
    name: 'Emerald Teal',
    light: _cs(
      b: Brightness.light,
      primary: const Color(0xFF0F9171),
      onPrimary: const Color(0xFF0D2D25),
      secondary: const Color(0xFFCFA17A),
      onSecondary: const Color(0xFF3A2A1D),
      surface: const Color(0xFFF2F6F5),
      onSurface: Color.alphaBlend(
        const Color(0xFF0F9171).withOpacity(0.30),
        const Color(0xFF172321),
      ),
      tertiary: const Color(0xFF4EB5A5),
      onTertiary: const Color(0xFF0E2B27),
    ),
    dark: _cs(
      b: Brightness.dark,
      primary: const Color(0xFF2FC1A2),
      onPrimary: const Color(0xFF0A1D19),
      secondary: const Color(0xFFE1B789),
      onSecondary: const Color(0xFF2A1E15),
      surface: const Color(0xFF111A19),
      onSurface: Color.alphaBlend(
        const Color(0xFF2FC1A2).withOpacity(0.20),
        const Color(0xFFE9F2F0),
      ),
      tertiary: const Color(0xFF60D0BF),
      onTertiary: const Color(0xFF081C19),
    ),
    lightExtension: const AppColors(
      pop: Color(0xFFD00000),
      onPop: AppTheme.white,
      textOnGradient: Colors.white,
      statusSuccess: Color(0xFF2E7D32),
      statusWarning: Color(0xFFF57C00),
    ),
    darkExtension: const AppColors(
      pop: Color(0xFFD00000),
      onPop: AppTheme.white,
      textOnGradient: Colors.white,
      statusSuccess: Color(0xFF81C784),
      statusWarning: Color(0xFFFFB74D),
    ),
    previewGradient: const [Color(0xFF0F9171), Color(0xFF4EB5A5)],
  ),

  // 02 Royal Blue
  ThemePreset(
    key: 'royal_blue',
    name: 'Royal Blue',
    light: _cs(
      b: Brightness.light,
      primary: const Color(0xFF0A62B6),
      onPrimary: const Color(0xFFFFFFFF),
      secondary: const Color(0xFF95A8C8),
      onSecondary: const Color(0xFF0E2449),
      surface: const Color(0xFFF5F7FB),
      onSurface: Color.alphaBlend(
        const Color(0xFF0A62B6).withOpacity(0.30),
        const Color(0xFF111827),
      ),
      tertiary: const Color(0xFF133C85),
      onTertiary: const Color(0xFFE6ECFA),
    ),
    dark: _cs(
      b: Brightness.dark,
      primary: const Color(0xFF4B8DF7),
      onPrimary: const Color(0xFF091321),
      secondary: const Color(0xFFB9C6E6),
      onSecondary: const Color(0xFF0A1D38),
      surface: const Color(0xFF0E1420),
      onSurface: Color.alphaBlend(
        const Color(0xFF4B8DF7).withOpacity(0.20),
        const Color(0xFFE7ECF6),
      ),
      tertiary: const Color(0xFF2B61CF),
      onTertiary: const Color(0xFF071224),
    ),
    lightExtension: const AppColors(
      pop: Color(0xFFD00000),
      onPop: AppTheme.white,
      textOnGradient: Colors.white,
      statusSuccess: Color(0xFF2E7D32),
      statusWarning: Color(0xFFF57C00),
    ),
    darkExtension: const AppColors(
      pop: Color(0xFFD00000),
      onPop: AppTheme.white,
      textOnGradient: Colors.white,
      statusSuccess: Color(0xFF81C784),
      statusWarning: Color(0xFFFFB74D),
    ),
    previewGradient: const [Color(0xFF0A62B6), Color(0xFF133C85)],
  ),

  // 03 Aqua Cyan
  ThemePreset(
    key: 'aqua_cyan',
    name: 'Aqua Cyan',
    light: _cs(
      b: Brightness.light,
      primary: const Color(0xFF00A3B8),
      onPrimary: const Color(0xFF072125),
      secondary: const Color(0xFF6DE0DC),
      onSecondary: const Color(0xFF072422),
      surface: const Color(0xFFF1FBFB),
      onSurface: Color.alphaBlend(
        const Color(0xFF00A3B8).withOpacity(0.30),
        const Color(0xFF0E2022),
      ),
      tertiary: const Color(0xFF06C4D4),
      onTertiary: const Color(0xFF052226),
    ),
    dark: _cs(
      b: Brightness.dark,
      primary: const Color(0xFF40D7E2),
      onPrimary: const Color(0xFF041417),
      secondary: const Color(0xFF8AF0ED),
      onSecondary: const Color(0xFF031716),
      surface: const Color(0xFF0C1617),
      onSurface: Color.alphaBlend(
        const Color(0xFF40D7E2).withOpacity(0.20),
        const Color(0xFFEAF7F7),
      ),
      tertiary: const Color(0xFF23E1EE),
      onTertiary: const Color(0xFF021214),
    ),
    lightExtension: const AppColors(
      pop: Color(0xFFD00000),
      onPop: AppTheme.white,
      textOnGradient: Colors.black,
      statusSuccess: Color(0xFF2E7D32),
      statusWarning: Color(0xFFF57C00),
    ),
    darkExtension: const AppColors(
      pop: Color(0xFFD00000),
      onPop: AppTheme.white,
      textOnGradient: Colors.white,
      statusSuccess: Color(0xFF81C784),
      statusWarning: Color(0xFFFFB74D),
    ),
    previewGradient: const [Color(0xFF00A3B8), Color(0xFF06C4D4)],
  ),

  // 04 Steel Red
  ThemePreset(
    key: 'steel_red',
    name: 'Steel Red',
    light: _cs(
      b: Brightness.light,
      primary: const Color(0xFF08333C),
      onPrimary: const Color(0xFFE7EFF2),
      secondary: const Color(0xFF5D202A),
      onSecondary: const Color(0xFFF5E6EB),
      surface: const Color(0xFFF2F4F6),
      onSurface: Color.alphaBlend(
        const Color(0xFF08333C).withOpacity(0.30),
        const Color(0xFF141A1E),
      ),
      tertiary: const Color(0xFF91222B),
      onTertiary: const Color(0xFFFBECEE),
    ),
    dark: _cs(
      b: Brightness.dark,
      primary: const Color(0xFF37545B),
      onPrimary: const Color(0xFFE9F1F3),
      secondary: const Color(0xFFB53643),
      onSecondary: const Color(0xFF2B0D12),
      surface: const Color(0xFF0E1416),
      onSurface: Color.alphaBlend(
        const Color(0xFF37545B).withOpacity(0.20),
        const Color(0xFFE8EEF0),
      ),
      tertiary: const Color(0xFFD44E5B),
      onTertiary: const Color(0xFF28090C),
    ),
    lightExtension: const AppColors(
      pop: Color(0xFFD00000),
      onPop: AppTheme.white,
      textOnGradient: Colors.white,
      statusSuccess: Color(0xFF2E7D32),
      statusWarning: Color(0xFFF57C00),
    ),
    darkExtension: const AppColors(
      pop: Color(0xFFD00000),
      onPop: AppTheme.white,
      textOnGradient: Colors.white,
      statusSuccess: Color(0xFF81C784),
      statusWarning: Color(0xFFFFB74D),
    ),
    previewGradient: const [Color(0xFF5D202A), Color(0xFF91222B)],
  ),

  // 05 Forest Green
  ThemePreset(
    key: 'forest_green',
    name: 'Forest Green',
    light: _cs(
      b: Brightness.light,
      primary: const Color(0xFF1E6A3D),
      onPrimary: const Color(0xFFEAF6EF),
      secondary: const Color(0xFFA7C56A),
      onSecondary: const Color(0xFF1E2A12),
      surface: const Color(0xFFF5FBF3),
      onSurface: Color.alphaBlend(
        const Color(0xFF1E6A3D).withOpacity(0.30),
        const Color(0xFF141F18),
      ),
      tertiary: const Color(0xFF2E8B57),
      onTertiary: const Color(0xFFEAF7F0),
    ),
    dark: _cs(
      b: Brightness.dark,
      primary: const Color(0xFF4CB278),
      onPrimary: const Color(0xFF0B1510),
      secondary: const Color(0xFFB7D985),
      onSecondary: const Color(0xFF16210F),
      surface: const Color(0xFF0F1612),
      onSurface: Color.alphaBlend(
        const Color(0xFF4CB278).withOpacity(0.20),
        const Color(0xFFE8F2EB),
      ),
      tertiary: const Color(0xFF62C08A),
      onTertiary: const Color(0xFF08150F),
    ),
    lightExtension: const AppColors(
      pop: Color(0xFFD00000),
      onPop: AppTheme.white,
      textOnGradient: Colors.white,
      statusSuccess: Color(0xFF2E7D32),
      statusWarning: Color(0xFFF57C00),
    ),
    darkExtension: const AppColors(
      pop: Color(0xFFD00000),
      onPop: AppTheme.white,
      textOnGradient: Colors.white,
      statusSuccess: Color(0xFF81C784),
      statusWarning: Color(0xFFFFB74D),
    ),
    previewGradient: const [Color(0xFF1E6A3D), Color(0xFF2E8B57)],
  ),

  // 06 Mauve Gray
  ThemePreset(
    key: 'mauve_gray',
    name: 'Mauve Gray',
    light: _cs(
      b: Brightness.light,
      primary: const Color(0xFF8A7C9A),
      onPrimary: const Color(0xFF201C26),
      secondary: const Color(0xFFC9B8D6),
      onSecondary: const Color(0xFF2C2335),
      surface: const Color(0xFFFCFAFD),
      onSurface: Color.alphaBlend(
        const Color(0xFF8A7C9A).withOpacity(0.30),
        const Color(0xFF1A171D),
      ),
      tertiary: const Color(0xFFAA97B5),
      onTertiary: const Color(0xFF261F2C),
    ),
    dark: _cs(
      b: Brightness.dark,
      primary: const Color(0xFFB7A6C4),
      onPrimary: const Color(0xFF1B1620),
      secondary: const Color(0xFFD7C9E1),
      onSecondary: const Color(0xFF221B2A),
      surface: const Color(0xFF15121A),
      onSurface: Color.alphaBlend(
        const Color(0xFFB7A6C4).withOpacity(0.20),
        const Color(0xFFF1ECF5),
      ),
      tertiary: const Color(0xFFCBBADA),
      onTertiary: const Color(0xFF1F1A23),
    ),
    lightExtension: const AppColors(
      pop: Color(0xFFD00000),
      onPop: AppTheme.white,
      textOnGradient: Colors.white,
      statusSuccess: Color(0xFF2E7D32),
      statusWarning: Color(0xFFF57C00),
    ),
    darkExtension: const AppColors(
      pop: Color(0xFFD00000),
      onPop: AppTheme.white,
      textOnGradient: Colors.white,
      statusSuccess: Color(0xFF81C784),
      statusWarning: Color(0xFFFFB74D),
    ),
    previewGradient: const [Color(0xFF8A7C9A), Color(0xFFAA97B5)],
  ),

  // 07 Indigo Plum
  ThemePreset(
    key: 'indigo_plum',
    name: 'Indigo Plum',
    light: _cs(
      b: Brightness.light,
      primary: const Color(0xFF3A3D7C),
      onPrimary: const Color(0xFFECECF8),
      secondary: const Color(0xFF8D93F4),
      onSecondary: const Color(0xFF191B39),
      surface: const Color(0xFFF6F7FB),
      onSurface: Color.alphaBlend(
        const Color(0xFF3A3D7C).withOpacity(0.30),
        const Color(0xFF141624),
      ),
      tertiary: const Color(0xFF523F7C),
      onTertiary: const Color(0xFFEFEAF7),
    ),
    dark: _cs(
      b: Brightness.dark,
      primary: const Color(0xFF7076F8),
      onPrimary: const Color(0xFF0E1030),
      secondary: const Color(0xFFA4A9FA),
      onSecondary: const Color(0xFF0D0F25),
      surface: const Color(0xFF101225),
      onSurface: Color.alphaBlend(
        const Color(0xFF7076F8).withOpacity(0.20),
        const Color(0xFFE7E9FA),
      ),
      tertiary: const Color(0xFF6A58A7),
      onTertiary: const Color(0xFF0D0A1A),
    ),
    lightExtension: const AppColors(
      pop: Color(0xFFD00000),
      onPop: AppTheme.white,
      textOnGradient: Colors.white,
      statusSuccess: Color(0xFF2E7D32),
      statusWarning: Color(0xFFF57C00),
    ),
    darkExtension: const AppColors(
      pop: Color(0xFFD00000),
      onPop: AppTheme.white,
      textOnGradient: Colors.white,
      statusSuccess: Color(0xFF81C784),
      statusWarning: Color(0xFFFFB74D),
    ),
    previewGradient: const [Color(0xFF3A3D7C), Color(0xFF6A58A7)],
  ),

  // 08 Crimson Rose
  ThemePreset(
    key: 'crimson_rose',
    name: 'Crimson Rose',
    light: _cs(
      b: Brightness.light,
      primary: const Color(0xFF9E065C),
      onPrimary: const Color(0xFFFFF2FA),
      secondary: const Color(0xFFE85B9C),
      onSecondary: const Color(0xFF2F0B1F),
      surface: const Color(0xFFFFF5F9),
      onSurface: Color.alphaBlend(
        const Color(0xFF9E065C).withOpacity(0.30),
        const Color(0xFF2A0E1C),
      ),
      tertiary: const Color(0xFFB41452),
      onTertiary: const Color(0xFFFFEEF5),
    ),
    dark: _cs(
      b: Brightness.dark,
      primary: const Color(0xFFE36BB1),
      onPrimary: const Color(0xFF230616),
      secondary: const Color(0xFFF38EC6),
      onSecondary: const Color(0xFF240816),
      surface: const Color(0xFF1A0E16),
      onSurface: Color.alphaBlend(
        const Color(0xFFE36BB1).withOpacity(0.20),
        const Color(0xFFF9E9F2),
      ),
      tertiary: const Color(0xFFCF2C67),
      onTertiary: const Color(0xFF1E0612),
    ),
    lightExtension: const AppColors(
      pop: Color(0xFFD00000),
      onPop: AppTheme.white,
      textOnGradient: Colors.white,
      statusSuccess: Color(0xFF2E7D32),
      statusWarning: Color(0xFFF57C00),
    ),
    darkExtension: const AppColors(
      pop: Color(0xFFD00000),
      onPop: AppTheme.white,
      textOnGradient: Colors.white,
      statusSuccess: Color(0xFF81C784),
      statusWarning: Color(0xFFFFB74D),
    ),
    previewGradient: const [Color(0xFF9E065C), Color(0xFFB41452)],
  ),

  // 09 Ivory Gold
  ThemePreset(
    key: 'ivory_gold',
    name: 'Ivory Gold',
    light: _cs(
      b: Brightness.light,
      primary: const Color(0xFFF0DDD0),
      onPrimary: const Color(0xFF3A2B20),
      secondary: const Color(0xFFFDCBA2),
      onSecondary: const Color(0xFF3B2A1E),
      surface: const Color(0xFFFFFAF5),
      onSurface: Color.alphaBlend(
        const Color(0xFFF0DDD0).withOpacity(0.30),
        const Color(0xFF2C241D),
      ),
      tertiary: const Color(0xFFE8B98E),
      onTertiary: const Color(0xFF3C2C21),
    ),
    dark: _cs(
      b: Brightness.dark,
      primary: const Color(0xFFF6E7DB),
      onPrimary: const Color(0xFF2A1F18),
      secondary: const Color(0xFFF7D7B6),
      onSecondary: const Color(0xFF2B1F17),
      surface: const Color(0xFF191410),
      onSurface: Color.alphaBlend(
        const Color(0xFFF6E7DB).withOpacity(0.20),
        const Color(0xFFFFF4EB),
      ),
      tertiary: const Color(0xFFEAC7A5),
      onTertiary: const Color(0xFF261C15),
    ),
    lightExtension: const AppColors(
      pop: Color(0xFFD00000),
      onPop: AppTheme.white,
      textOnGradient: Colors.black,
      statusSuccess: Color(0xFF2E7D32),
      statusWarning: Color(0xFFF57C00),
    ),
    darkExtension: const AppColors(
      pop: Color(0xFFD00000),
      onPop: AppTheme.white,
      textOnGradient: Colors.white,
      statusSuccess: Color(0xFF81C784),
      statusWarning: Color(0xFFFFB74D),
    ),
    previewGradient: const [Color(0xFFF0DDD0), Color(0xFFFDCBA2)],
  ),

  // 10 Copper Rust
  ThemePreset(
    key: 'copper_rust',
    name: 'Copper Rust',
    light: _cs(
      b: Brightness.light,
      primary: const Color(0xFF7A2E1D),
      onPrimary: const Color(0xFFFFEDE7),
      secondary: const Color(0xFFDC7844),
      onSecondary: const Color(0xFF3A180F),
      surface: const Color(0xFFFCF6F3),
      onSurface: Color.alphaBlend(
        const Color(0xFF7A2E1D).withOpacity(0.30),
        const Color(0xFF261712),
      ),
      tertiary: const Color(0xFFB35433),
      onTertiary: const Color(0xFFFFEDE7),
    ),
    dark: _cs(
      b: Brightness.dark,
      primary: const Color(0xFFC1694B),
      onPrimary: const Color(0xFF2B140E),
      secondary: const Color(0xFFE6895F),
      onSecondary: const Color(0xFF2D130D),
      surface: const Color(0xFF1A110E),
      onSurface: Color.alphaBlend(
        const Color(0xFFC1694B).withOpacity(0.20),
        const Color(0xFFF8ECE7),
      ),
      tertiary: const Color(0xFFD77D59),
      onTertiary: const Color(0xFF240F0B),
    ),
    lightExtension: const AppColors(
      pop: Color(0xFFD00000),
      onPop: AppTheme.white,
      textOnGradient: Colors.white,
      statusSuccess: Color(0xFF2E7D32),
      statusWarning: Color(0xFFF57C00),
    ),
    darkExtension: const AppColors(
      pop: Color(0xFFD00000),
      onPop: AppTheme.white,
      textOnGradient: Colors.white,
      statusSuccess: Color(0xFF81C784),
      statusWarning: Color(0xFFFFB74D),
    ),
    previewGradient: const [Color(0xFF7A2E1D), Color(0xFFDC7844)],
  ),

  // 11 Cyan Slate
  ThemePreset(
    key: 'cyan_slate',
    name: 'Cyan Slate',
    light: _cs(
      b: Brightness.light,
      primary: const Color(0xFF0E4150),
      onPrimary: const Color(0xFFE6F6FA),
      secondary: const Color(0xFF74E7E1),
      onSecondary: const Color(0xFF0C2727),
      surface: const Color(0xFFF1F8FA),
      onSurface: Color.alphaBlend(
        const Color(0xFF0E4150).withOpacity(0.30),
        const Color(0xFF122025),
      ),
      tertiary: const Color(0xFF3D88A1),
      onTertiary: const Color(0xFFE8F4F8),
    ),
    dark: _cs(
      b: Brightness.dark,
      primary: const Color(0xFF4E9FB6),
      onPrimary: const Color(0xFF0C1A1F),
      secondary: const Color(0xFF8CF1EB),
      onSecondary: const Color(0xFF061617),
      surface: const Color(0xFF0E171B),
      onSurface: Color.alphaBlend(
        const Color(0xFF4E9FB6).withOpacity(0.20),
        const Color(0xFFE7F2F6),
      ),
      tertiary: const Color(0xFF65BED7),
      onTertiary: const Color(0xFF09161B),
    ),
    lightExtension: const AppColors(
      pop: Color(0xFFD00000),
      onPop: AppTheme.white,
      textOnGradient: Colors.white,
      statusSuccess: Color(0xFF2E7D32),
      statusWarning: Color(0xFFF57C00),
    ),
    darkExtension: const AppColors(
      pop: Color(0xFFD00000),
      onPop: AppTheme.white,
      textOnGradient: Colors.white,
      statusSuccess: Color(0xFF81C784),
      statusWarning: Color(0xFFFFB74D),
    ),
    previewGradient: const [Color(0xFF0E4150), Color(0xFF3D88A1)],
  ),

  // 12 Royal Purple
  ThemePreset(
    key: 'royal_purple',
    name: 'Royal Purple',
    light: _cs(
      b: Brightness.light,
      primary: const Color(0xFF6A1FA1),
      onPrimary: const Color(0xFFF7ECFF),
      secondary: const Color(0xFFB36AE8),
      onSecondary: const Color(0xFF2C1340),
      surface: const Color(0xFFF9F4FE),
      onSurface: Color.alphaBlend(
        const Color(0xFF6A1FA1).withOpacity(0.30),
        const Color(0xFF1F152A),
      ),
      tertiary: const Color(0xFF8C2CD0),
      onTertiary: const Color(0xFFF5E9FF),
    ),
    dark: _cs(
      b: Brightness.dark,
      primary: const Color(0xFFC995FF),
      onPrimary: const Color(0xFF240B36),
      secondary: const Color(0xFFD7B2FF),
      onSecondary: const Color(0xFF200A2F),
      surface: const Color(0xFF170F23),
      onSurface: Color.alphaBlend(
        const Color(0xFFC995FF).withOpacity(0.20),
        const Color(0xFFF4EAFE),
      ),
      tertiary: const Color(0xFFB475F6),
      onTertiary: const Color(0xFF1E0B2D),
    ),
    lightExtension: const AppColors(
      pop: Color(0xFFD00000),
      onPop: AppTheme.white,
      textOnGradient: Colors.white,
      statusSuccess: Color(0xFF2E7D32),
      statusWarning: Color(0xFFF57C00),
    ),
    darkExtension: const AppColors(
      pop: Color(0xFFD00000),
      onPop: AppTheme.white,
      textOnGradient: Colors.white,
      statusSuccess: Color(0xFF81C784),
      statusWarning: Color(0xFFFFB74D),
    ),
    previewGradient: const [Color(0xFF6A1FA1), Color(0xFF8C2CD0)],
  ),

  // 13 Winter Wonderland
  ThemePreset(
    key: 'winter_wonderland',
    name: 'Winter Wonderland',
    light: _cs(
      b: Brightness.light,
      primary: const Color(0xFF446B95), // Arctic Sky
      onPrimary: Colors.white,
      secondary: const Color(0xFF98B9D4), // Powder Blue
      onSecondary: const Color(0xFF15263A),
      surface: const Color(0xFFF3F7FB),
      onSurface: Color.alphaBlend(
        const Color(0xFF446B95).withOpacity(0.30),
        const Color(0xFF111827),
      ),
      tertiary: const Color(0xFF6895BC), // Ice Lake
      onTertiary: const Color(0xFFEAF2FA),
    ),
    dark: _cs(
      b: Brightness.dark,
      primary: const Color(0xFF98B9D4), // brighter for dark
      onPrimary: const Color(0xFF0A141D),
      secondary: const Color(0xFFD0DFEB), // Frosted Mist
      onSecondary: const Color(0xFF0D1A24),
      surface: const Color(0xFF0F1419),
      onSurface: Color.alphaBlend(
        const Color(0xFF98B9D4).withOpacity(0.20),
        const Color(0xFFE6EEF6),
      ),
      tertiary: const Color(0xFF6895BC),
      onTertiary: const Color(0xFF08131C),
    ),
    lightExtension: const AppColors(
      pop: Color(0xFFD00000),
      onPop: AppTheme.white,
      textOnGradient: Colors.white,
      statusSuccess: Color(0xFF2E7D32),
      statusWarning: Color(0xFFF57C00),
    ),
    darkExtension: const AppColors(
      pop: Color(0xFFD00000),
      onPop: AppTheme.white,
      textOnGradient: Colors.white,
      statusSuccess: Color(0xFF81C784),
      statusWarning: Color(0xFFFFB74D),
    ),
    previewGradient: const [Color(0xFF446B95), Color(0xFF6895BC)],
  ),

  // 14 Burgundy Luxe
  ThemePreset(
    key: 'burgundy_luxe',
    name: 'Burgundy Luxe',
    light: _cs(
      b: Brightness.light,
      primary: const Color(0xFF390517), // Burgundy
      onPrimary: const Color(0xFFFFF2F5),
      secondary: const Color(0xFFA38560), // Gold Tan
      onSecondary: const Color(0xFF2D2317),
      surface: const Color(0xFFFBF7F4),
      onSurface: Color.alphaBlend(
        const Color(0xFF390517).withOpacity(0.30),
        const Color(0xFF211517),
      ),
      tertiary: const Color(0xFF6B1A2F),
      onTertiary: const Color(0xFFFFEEF2),
    ),
    dark: _cs(
      b: Brightness.dark,
      primary: const Color(0xFFD16A83), // lifted burgundy
      onPrimary: const Color(0xFF270812),
      secondary: const Color(0xFFC7A27A), // soft gold
      onSecondary: const Color(0xFF231A10),
      surface: const Color(0xFF1A1214),
      onSurface: Color.alphaBlend(
        const Color(0xFFD16A83).withOpacity(0.20),
        const Color(0xFFF7E9EC),
      ),
      tertiary: const Color(0xFF8C2C44),
      onTertiary: const Color(0xFF220910),
    ),
    lightExtension: const AppColors(
      pop: Color(0xFFD00000),
      onPop: AppTheme.white,
      textOnGradient: Colors.white,
      statusSuccess: Color(0xFF2E7D32),
      statusWarning: Color(0xFFF57C00),
    ),
    darkExtension: const AppColors(
      pop: Color(0xFFD00000),
      onPop: AppTheme.white,
      textOnGradient: Colors.white,
      statusSuccess: Color(0xFF81C784),
      statusWarning: Color(0xFFFFB74D),
    ),
    previewGradient: const [Color(0xFF390517), Color(0xFFA38560)],
  ),

  // 15 Racing Green Gold
  ThemePreset(
    key: 'racing_green_gold',
    name: 'Racing Green Gold',
    light: _cs(
      b: Brightness.light,
      primary: const Color(0xFF16302B), // Deep Racing Green
      onPrimary: const Color(0xFFE8F2EF),
      secondary: const Color(0xFFA38560), // Gold Tan
      onSecondary: const Color(0xFF2C2317),
      surface: const Color(0xFFF4F6F4),
      onSurface: Color.alphaBlend(
        const Color(0xFF16302B).withOpacity(0.30),
        const Color(0xFF121A16),
      ),
      tertiary: const Color(0xFF03110D),
      onTertiary: const Color(0xFFE6EFEC),
    ),
    dark: _cs(
      b: Brightness.dark,
      primary: const Color(0xFF4F7D6F),
      onPrimary: const Color(0xFF0B1512),
      secondary: const Color(0xFFC1A07A),
      onSecondary: const Color(0xFF221A10),
      surface: const Color(0xFF101713),
      onSurface: Color.alphaBlend(
        const Color(0xFF4F7D6F).withOpacity(0.20),
        const Color(0xFFE6F2EE),
      ),
      tertiary: const Color(0xFF0C1F19),
      onTertiary: const Color(0xFFE5EEEA),
    ),
    lightExtension: const AppColors(
      pop: Color(0xFFD00000),
      onPop: AppTheme.white,
      textOnGradient: Colors.white,
      statusSuccess: Color(0xFF2E7D32),
      statusWarning: Color(0xFFF57C00),
    ),
    darkExtension: const AppColors(
      pop: Color(0xFFD00000),
      onPop: AppTheme.white,
      textOnGradient: Colors.white,
      statusSuccess: Color(0xFF81C784),
      statusWarning: Color(0xFFFFB74D),
    ),
    previewGradient: const [Color(0xFF16302B), Color(0xFFA38560)],
  ),
];

ThemeData buildThemeFromPreset(ThemePreset preset, {required bool isDark}) {
  final scheme = isDark ? preset.dark : preset.light;
  final ext = isDark ? preset.darkExtension : preset.lightExtension;

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.background,
    appBarTheme: AppBarThemeData(
      centerTitle: true,
      elevation: 0,
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      iconTheme: IconThemeData(color: scheme.onSurface),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: scheme.onSurface,
        side: BorderSide(color: scheme.outline, width: 1.5),
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: scheme.secondary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    cardTheme: CardThemeData(
      color: scheme.surface,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outline.withOpacity(0.3)),
      ),
    ),
    dividerTheme: DividerThemeData(
      color: scheme.outline.withOpacity(0.3),
      thickness: 1,
    ),
    inputDecorationTheme: InputDecorationThemeData(
      filled: true,
      fillColor: scheme.surfaceVariant.withOpacity(0.5),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: scheme.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: scheme.outline.withOpacity(0.5)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: scheme.primary, width: 2),
      ),
      errorBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: Color(0xFFBA1A1A)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: scheme.surfaceVariant.withOpacity(0.3),
      selectedColor: scheme.primary,
      labelStyle: TextStyle(color: scheme.onSurface),
      secondaryLabelStyle: TextStyle(color: scheme.onSurface),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: scheme.surface,
      selectedItemColor: scheme.primary,
      unselectedItemColor: scheme.outline,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: scheme.primary,
      foregroundColor: scheme.onPrimary,
      elevation: 4,
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: scheme.primary,
      circularTrackColor: scheme.surfaceVariant,
    ),
    extensions: <ThemeExtension<dynamic>>[ext],
  );
}

