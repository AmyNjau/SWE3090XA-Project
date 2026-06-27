import 'package:flutter/material.dart';

/// Central design language for the app. A single palette and type scale are
/// reused across every screen so a control learned on one screen looks and
/// behaves the same on another (the consistency goal from the design report).
class AppColors {
  static const Color navy = Color(0xFF1B3A6B); // headers and primary text
  static const Color blue = Color(0xFF2F6FED); // interactive elements/accents
  static const Color lightBlue = Color(0xFFE8F0FE); // highlighted panels
  static const Color chipIdle = Color(0xFFF1F3F6);
  static const Color textPrimary = Color(0xFF1B2733);
  static const Color textMuted = Color(0xFF6B7785);

  // Severity / match colours.
  static const Color high = Color(0xFFE4504D);
  static const Color medium = Color(0xFFE8A33D);
  static const Color low = Color(0xFF2F6FED);

  static Color severityColor(String severity) {
    switch (severity) {
      case 'high':
        return high;
      case 'medium':
        return medium;
      default:
        return low;
    }
  }
}

ThemeData buildAppTheme() {
  final base = ThemeData.light(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: Colors.white,
    colorScheme: base.colorScheme.copyWith(
      primary: AppColors.blue,
      secondary: AppColors.navy,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.navy,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.blue,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(52),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    textTheme: base.textTheme.apply(
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.navy,
    ),
  );
}
