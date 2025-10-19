import 'package:flutter/material.dart';

class AppTheme {
  // Primary Palette
  static const Color deepCrimson = Color(0xFF810000);      // Primary
  static const Color amberBrown = Color(0xFF944111);       // Secondary

  // Accent & Support Colors
  static const Color agedGold = Color(0xFFC2A46C);         // Accent
  static const Color warmSandBeige = Color(0xFFEAE6DA);    // Background
  static const Color richTaupe = Color(0xFFBCA98C);        // Dividers/Shadows
  static const Color softCharcoal = Color(0xFF3B332C);     // Text contrast
  static const Color white = Colors.white;                  // Pure white

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: deepCrimson,
      onPrimary: warmSandBeige,
      secondary: amberBrown,
      onSecondary: warmSandBeige,
      tertiary: agedGold,
      onTertiary: softCharcoal,
      error: Color(0xFFBA1A1A),
      onError: white,
      background: warmSandBeige,
      onBackground: softCharcoal,
      surface: warmSandBeige,
      onSurface: softCharcoal,
      surfaceVariant: richTaupe,
      onSurfaceVariant: softCharcoal,
      outline: richTaupe,
      shadow: richTaupe,
      inverseSurface: softCharcoal,
      onInverseSurface: warmSandBeige,
      inversePrimary: agedGold,
    ),
    scaffoldBackgroundColor: warmSandBeige,
    appBarTheme: AppBarTheme(
      centerTitle: true,
      elevation: 0,
      backgroundColor: warmSandBeige,
      foregroundColor: softCharcoal,
      iconTheme: const IconThemeData(color: softCharcoal),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: deepCrimson,
        foregroundColor: warmSandBeige,
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 2,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: deepCrimson,
        side: const BorderSide(color: deepCrimson, width: 1.5),
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: amberBrown,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    cardTheme: CardThemeData(
      color: warmSandBeige,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: richTaupe.withOpacity(0.3)),
      ),
    ),
    dividerTheme: DividerThemeData(
      color: richTaupe.withOpacity(0.3),
      thickness: 1,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: white.withOpacity(0.5),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: richTaupe),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: richTaupe.withOpacity(0.5)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: deepCrimson, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFBA1A1A)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: richTaupe.withOpacity(0.2),
      selectedColor: deepCrimson,
      labelStyle: const TextStyle(color: softCharcoal),
      secondaryLabelStyle: const TextStyle(color: warmSandBeige),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: warmSandBeige,
      selectedItemColor: deepCrimson,
      unselectedItemColor: richTaupe,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: deepCrimson,
      foregroundColor: warmSandBeige,
      elevation: 4,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: deepCrimson,
      circularTrackColor: richTaupe,
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: deepCrimson,
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: const Color(0xFF1A1A1A),
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
      backgroundColor: Color(0xFF1A1A1A),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: deepCrimson,
        foregroundColor: warmSandBeige,
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 2,
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF1A1A1A),
      selectedItemColor: deepCrimson,
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
  );
}