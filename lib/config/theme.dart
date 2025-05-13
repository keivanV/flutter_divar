import 'package:flutter/material.dart';

final ThemeData appTheme = ThemeData(
  primaryColor: const Color(0xFFE53935), // قرمز دیوار
  colorScheme: const ColorScheme.light(
    primary: Color(0xFFE53935),
    secondary: Color(0xFFFFB300),
    surface: Colors.white,
  ),
  scaffoldBackgroundColor: Colors.grey[100],
  fontFamily: 'Vazir',
  textTheme: const TextTheme(
    headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
    bodyMedium: TextStyle(fontSize: 16),
    labelMedium: TextStyle(fontSize: 14, color: Colors.grey),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFFE53935),
    foregroundColor: Colors.white,
    elevation: 2,
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    selectedItemColor: Color(0xFFE53935),
    unselectedItemColor: Colors.grey,
    showUnselectedLabels: true,
  ),
  cardTheme: CardTheme(
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ),
);
