import 'package:flutter/material.dart';

final ThemeData appTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFF0F172A), // Slate 900
    brightness: Brightness.light,
    primary: const Color(0xFF2563EB), // Blue 600
    onPrimary: Colors.white,
    primaryContainer: const Color(0xFFDBEAFE),
    onPrimaryContainer: const Color(0xFF1E40AF),
    secondary: const Color(0xFF10B981), // Emerald 500
    onSecondary: Colors.white,
    secondaryContainer: const Color(0xFFD1FAE5),
    onSecondaryContainer: const Color(0xFF065F46),
    tertiary: const Color(0xFFF59E0B), // Amber 500
    surface: const Color(0xFFF8FAFC), // Slate 50
    onSurface: const Color(0xFF0F172A),
    error: const Color(0xFFEF4444), // Red 500
  ),
  scaffoldBackgroundColor: const Color(0xFFF8FAFC),
  appBarTheme: const AppBarTheme(
    centerTitle: false,
    elevation: 0,
    backgroundColor: Colors.transparent,
    foregroundColor: Color(0xFF0F172A),
    titleTextStyle: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: Color(0xFF0F172A),
      letterSpacing: -0.5,
    ),
    iconTheme: IconThemeData(color: Color(0xFF475569)), // Slate 600
  ),
  cardTheme: CardThemeData(
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: const BorderSide(color: Color(0xFFE2E8F0)), // Slate 200
    ),
    color: Colors.white,
    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    labelStyle: const TextStyle(color: Color(0xFF64748B)), // Slate 500
    floatingLabelStyle: const TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.w600),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: const Color(0xFF2563EB),
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      textStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.2,
      ),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: const Color(0xFF2563EB),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      textStyle: const TextStyle(fontWeight: FontWeight.w600),
    ),
  ),
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: const Color(0xFF0F172A),
    foregroundColor: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    elevation: 4,
  ),
  textTheme: const TextTheme(
    displaySmall: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
    titleLarge: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
    titleMedium: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
    bodyLarge: TextStyle(color: Color(0xFF334155)),
    bodyMedium: TextStyle(color: Color(0xFF475569)),
  ),
);

final ThemeData appDarkTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFF3B82F6), // Blue 500
    brightness: Brightness.dark,
    primary: const Color(0xFF3B82F6),
    onPrimary: Colors.white,
    primaryContainer: const Color(0xFF1E40AF),
    onPrimaryContainer: const Color(0xFFDBEAFE),
    secondary: const Color(0xFF10B981),
    onSecondary: Colors.white,
    surface: const Color(0xFF0F172A), // Slate 900
    onSurface: const Color(0xFFF8FAFC),
    background: const Color(0xFF020617), // Slate 950
    error: const Color(0xFFF87171),
  ),
  scaffoldBackgroundColor: const Color(0xFF020617),
  appBarTheme: const AppBarTheme(
    centerTitle: false,
    elevation: 0,
    backgroundColor: Colors.transparent,
    foregroundColor: Color(0xFFF8FAFC),
    titleTextStyle: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: Color(0xFFF8FAFC),
      letterSpacing: -0.5,
    ),
    iconTheme: IconThemeData(color: Color(0xFF94A3B8)), // Slate 400
  ),
  cardTheme: CardThemeData(
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: const BorderSide(color: Color(0xFF1E293B)), // Slate 800
    ),
    color: const Color(0xFF0F172A),
    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFF1E293B),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFF334155)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFF334155)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
    floatingLabelStyle: const TextStyle(color: Color(0xFF3B82F6), fontWeight: FontWeight.w600),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: const Color(0xFF3B82F6),
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      textStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.2,
      ),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: const Color(0xFF3B82F6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      textStyle: const TextStyle(fontWeight: FontWeight.w600),
    ),
  ),
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: const Color(0xFF3B82F6),
    foregroundColor: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    elevation: 4,
  ),
  textTheme: const TextTheme(
    displaySmall: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFF1F5F9)),
    titleLarge: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFF1F5F9)),
    titleMedium: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFFE2E8F0)),
    bodyLarge: TextStyle(color: Color(0xFFCBD5E1)),
    bodyMedium: TextStyle(color: Color(0xFF94A3B8)),
  ),
);
