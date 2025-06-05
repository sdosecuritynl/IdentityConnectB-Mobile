import 'package:flutter/material.dart';

class AppTheme {
  // Brand Colors
  static const Color primaryBlue = Color(0xFF0066CC);
  static const Color accentBlue = Color(0xFF00A3FF);
  static const Color textDark = Color(0xFF1A1F36);
  static const Color textGrey = Color(0xFF6B7280);

  // Common Styles
  static const TextStyle titleLarge = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: primaryBlue,
    letterSpacing: -0.5,
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    color: textDark,
    letterSpacing: -0.5,
  );

  static const TextStyle bodyText = TextStyle(
    fontSize: 15,
    color: textGrey,
    height: 1.5,
    letterSpacing: -0.3,
  );

  static const TextStyle buttonText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.5,
  );

  // Common Decorations
  static BoxDecoration cardDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(
      color: primaryBlue.withOpacity(0.1),
      width: 1,
    ),
  );

  static BoxDecoration buttonDecoration = BoxDecoration(
    borderRadius: BorderRadius.circular(30),
    boxShadow: [
      BoxShadow(
        color: primaryBlue.withOpacity(0.3),
        spreadRadius: 0,
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ],
  );

  static ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: primaryBlue,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(vertical: 16),
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(30),
    ),
  );

  static InputDecoration textFieldDecoration = InputDecoration(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: textGrey.withOpacity(0.2)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: textGrey.withOpacity(0.2)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: primaryBlue),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    filled: true,
    fillColor: Colors.white,
  );

  // Header Shadow
  static List<BoxShadow> headerShadow = [
    BoxShadow(
      color: textGrey.withOpacity(0.1),
      offset: const Offset(0, 2),
      blurRadius: 4,
    ),
  ];
} 