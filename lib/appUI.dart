
import 'package:flutter/material.dart';

class AppTheme {
  static const mainOrange = Color(0xFFFF9800);
  static const paleOrange = Color(0xFFFFF3E0);
  static const lightOrange = Color(0xFFFFECB3);
  static const background = Color(0xFFFAFAFA);
  static const cardBorder = Color(0xFFE0E0E0);
  static const textPrimary = Color(0xFF424242);
  static const textSecondary = Color(0xFF757575);

  static const headingStyle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: textPrimary,
  );

  static const subheadingStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: textSecondary,
  );

  static const bodyStyle = TextStyle(
    fontSize: 14,
    color: textSecondary,
  );

  static const captionStyle = TextStyle(
    fontSize: 12,
    color: Color(0xFF9E9E9E),
  );

  static final cardDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: cardBorder),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 5,
        offset: const Offset(0, 2),
      ),
    ],
  );
}