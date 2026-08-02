import 'package:flutter/material.dart';

/// Color palette inspired by Facebook Messenger.
class MessengerTheme {
  // Brand colors
  static const Color primary = Color(0xFF0084FF);   // Messenger blue
  static const Color primaryDark = Color(0xFF0066CC);
  static const Color accent = Color(0xFF0084FF);

  // Surfaces
  static const Color background = Colors.white;
  static const Color chatBackground = Color(0xFFFFFFFF);
  static const Color bubbleMine = Color(0xFF0084FF);
  static const Color bubbleTheirs = Color(0xFFE4E6EB);   // light gray
  static const Color bubbleTheirsText = Color(0xFF050505);
  static const Color bubbleMineText = Colors.white;

  // Text
  static const Color textPrimary = Color(0xFF050505);
  static const Color textSecondary = Color(0xFF65676B);
  static const Color textTertiary = Color(0xFF8A8D91);

  // Strokes / dividers
  static const Color divider = Color(0xFFCED0D4);
  static const Color inputBg = Color(0xFFF2F2F2); // search bar background

  // Status
  static const Color online = Color(0xFF31A24C);
  static const Color unreadBadge = Color(0xFF0084FF);

  // Story gradient (cosmetic)
  static const List<Color> storyGradient = [
    Color(0xFF833AB4),
    Color(0xFFFD1D1D),
    Color(0xFFFCAF45),
  ];
}

ThemeData buildMessengerTheme() {
  return ThemeData(
    useMaterial3: false,
    brightness: Brightness.light,
    primaryColor: MessengerTheme.primary,
    scaffoldBackgroundColor: MessengerTheme.background,
    colorScheme: ColorScheme.fromSeed(
      seedColor: MessengerTheme.primary,
      primary: MessengerTheme.primary,
      secondary: MessengerTheme.primary,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: MessengerTheme.textPrimary,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: MessengerTheme.textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: MessengerTheme.textPrimary),
      bodyMedium: TextStyle(color: MessengerTheme.textPrimary),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      border: InputBorder.none,
      hintStyle: TextStyle(color: MessengerTheme.textTertiary),
    ),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: MessengerTheme.primary,
      selectionColor: MessengerTheme.primary,
    ),
  );
}
