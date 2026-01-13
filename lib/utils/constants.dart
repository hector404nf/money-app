import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors
  static const primary = Color(0xFF004D40); // 174 100% 15%
  static const secondary = Color(0xFF00BFA5); // 168 100% 37%
  
  // UI Colors
  static const background = Color(0xFFF5F7FA); // 216 33% 97%
  static const surface = Color(0xFFFFFFFF); // 0 0% 100%
  static const textPrimary = Color(0xFF293241); // 220 20% 20%
  static const textSecondary = Color(0xFF737B8C); // 220 10% 50%
  
  // Semantic Colors
  static const income = Color(0xFF4CAF50); // 122 39% 49%
  static const expense = Color(0xFFE53935); // 4 82% 56%
  static const transfer = Color(0xFF1976D2); // 210 79% 46%
}

class AppTextStyles {
  static const amountBig = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
  );
  
  static const amountMedium = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
  );
}

class AppShadows {
  static BoxShadow get soft => BoxShadow(
    color: AppColors.primary.withOpacity(0.15),
    offset: const Offset(0, 4),
    blurRadius: 20,
  );
}

class AppGradients {
  static const primary = LinearGradient(
    colors: [AppColors.primary, AppColors.secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
