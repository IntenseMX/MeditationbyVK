import 'package:flutter/material.dart';

class AppTheme {
  // Shrine Pink Material Design Palette
  static const Color shrinePink100 = Color(0xFFFEDBD0);    // Primary Light
  static const Color shrinePink300 = Color(0xFFFBB8AC);    // Primary variant
  static const Color shrinePink400 = Color(0xFFEAA4A4);    // Additional shade

  static const Color shrineBrown900 = Color(0xFF442C2E);   // Primary Dark
  static const Color shrineBrown600 = Color(0xFF7D5260);    // Additional shade

  static const Color shrineSecondary50 = Color(0xFFFEEAE6); // Secondary Light
  static const Color shrineSecondary100 = Color(0xFFFEDCC8); // Secondary variant

  // Support colors
  static const Color shrineWhite = Color(0xFFFFFBFA);      // Off-white
  static const Color shrineGrey = Color(0xFF9E9E9E);       // Grey for disabled states
  static const Color shrineBlack = Color(0xFF212121);      // Near black for text
  static const Color white = Colors.white;                   // Pure white

  // Backward compatibility aliases (map old names to new Shrine Pink colors)
  static const Color deepCrimson = shrinePink100;           // Old primary -> Shrine Pink
  static const Color amberBrown = shrineBrown600;           // Old secondary -> Brown shade
  static const Color agedGold = shrinePink300;              // Old accent -> Pink variant
  static const Color warmSandBeige = shrineWhite;           // Old background -> White
  static const Color richTaupe = shrinePink300;             // Old divider -> Pink variant
  static const Color softCharcoal = shrineBrown900;         // Old text -> Brown dark

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: shrinePink100,
      onPrimary: shrineBrown900,
      secondary: shrineSecondary50,
      onSecondary: shrineBrown900,
      tertiary: shrinePink300,
      onTertiary: shrineBrown900,
      error: Color(0xFFBA1A1A),
      onError: white,
      background: shrineWhite,
      onBackground: shrineBrown900,
      surface: shrineWhite,
      onSurface: shrineBrown900,
      surfaceVariant: shrineSecondary50,
      onSurfaceVariant: shrineBrown600,
      outline: shrinePink300,
      shadow: shrineGrey,
      inverseSurface: shrineBrown900,
      onInverseSurface: shrineWhite,
      inversePrimary: shrinePink300,
    ),
    scaffoldBackgroundColor: shrineWhite,
    appBarTheme: AppBarTheme(
      centerTitle: true,
      elevation: 0,
      backgroundColor: shrineWhite,
      foregroundColor: shrineBrown900,
      iconTheme: const IconThemeData(color: shrineBrown900),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: shrinePink100,
        foregroundColor: shrineBrown900,
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 2,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: shrineBrown900,
        side: const BorderSide(color: shrinePink300, width: 1.5),
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: shrineBrown600,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    cardTheme: CardThemeData(
      color: shrineWhite,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: shrinePink300.withOpacity(0.3)),
      ),
    ),
    dividerTheme: DividerThemeData(
      color: shrinePink300.withOpacity(0.3),
      thickness: 1,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: shrineSecondary50.withOpacity(0.5),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: shrinePink300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: shrinePink300.withOpacity(0.5)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: shrinePink100, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFBA1A1A)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: shrineSecondary50.withOpacity(0.3),
      selectedColor: shrinePink100,
      labelStyle: const TextStyle(color: shrineBrown900),
      secondaryLabelStyle: const TextStyle(color: shrineBrown900),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: shrineWhite,
      selectedItemColor: shrinePink100,
      unselectedItemColor: shrineGrey,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: shrinePink100,
      foregroundColor: shrineBrown900,
      elevation: 4,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: shrinePink100,
      circularTrackColor: shrineSecondary50,
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme(
      brightness: Brightness.dark,
      primary: shrinePink300,
      onPrimary: shrineBrown900,
      secondary: shrineBrown600,
      onSecondary: shrineWhite,
      tertiary: shrinePink400,
      onTertiary: shrineWhite,
      error: const Color(0xFFFFB4AB),
      onError: const Color(0xFF690005),
      background: shrineBrown900,
      onBackground: shrineWhite,
      surface: const Color(0xFF2A2122),
      onSurface: shrineWhite,
      surfaceVariant: shrineBrown600,
      onSurfaceVariant: shrineSecondary50,
      outline: shrinePink400,
      shadow: Colors.black,
      inverseSurface: shrineWhite,
      onInverseSurface: shrineBrown900,
      inversePrimary: shrinePink100,
    ),
    scaffoldBackgroundColor: shrineBrown900,
    appBarTheme: AppBarTheme(
      centerTitle: true,
      elevation: 0,
      backgroundColor: shrineBrown900,
      foregroundColor: shrineWhite,
      iconTheme: const IconThemeData(color: shrineWhite),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: shrinePink300,
        foregroundColor: shrineBrown900,
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 2,
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: shrineBrown900,
      selectedItemColor: shrinePink300,
      unselectedItemColor: shrineGrey,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
  );
}