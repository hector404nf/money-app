import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/ui_provider.dart';

/// Theme definitions for Money App
class AppThemes {
  /// Get ThemeData for a specific app theme
  static ThemeData getTheme(AppTheme appTheme, bool isDark) {
    switch (appTheme) {
      case AppTheme.oceanBlue:
        return _oceanBlueTheme(isDark);
      case AppTheme.dark:
        return _darkTheme();
      case AppTheme.cherryBlossom:
        return _cherryBlossomTheme(isDark);
      case AppTheme.professionalGrey:
        return _professionalGreyTheme(isDark);
      case AppTheme.sunsetOrange:
        return _sunsetOrangeTheme(isDark);
      case AppTheme.forestGreen:
        return _forestGreenTheme(isDark);
    }
  }

  /// Ocean Blue Theme (Original)
  static ThemeData _oceanBlueTheme(bool isDark) {
    if (isDark) {
      return ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFF00BFA5),
          secondary: const Color(0xFF004D40),
          surface: const Color(0xFF1E2228),
          background: const Color(0xFF121418),
          error: const Color(0xFFE53935),
        ),
        scaffoldBackgroundColor: const Color(0xFF121418),
        textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
        cardTheme: CardThemeData(
          color: const Color(0xFF1E2228),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: const Color(0xFF1E2228),
          elevation: 0,
          titleTextStyle: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
        ),
      );
    }
    
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF004D40),
        secondary: Color(0xFF00BFA5),
        surface: Color(0xFFFFFFFF),
        background: Color(0xFFF5F7FA),
        error: Color(0xFFE53935),
      ),
      scaffoldBackgroundColor: const Color(0xFFF5F7FA),
      textTheme: GoogleFonts.poppinsTextTheme(ThemeData.light().textTheme),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF004D40),
        elevation: 0,
        titleTextStyle: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600, color: const Color(0xFF004D40)),
      ),
    );
  }

  /// Dark Theme
  static ThemeData _darkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: const Color(0xFFBB86FC),
        secondary: const Color(0xFF03DAC6),
        surface: const Color(0xFF1F1F1F),
        background: const Color(0xFF121212),
        error: const Color(0xFFCF6679),
      ),
      scaffoldBackgroundColor: const Color(0xFF121212),
      textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
      cardTheme: CardThemeData(
        color: const Color(0xFF1F1F1F),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF1F1F1F),
        elevation: 0,
        titleTextStyle: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
      ),
    );
  }

  /// Cherry Blossom Theme
  static ThemeData _cherryBlossomTheme(bool isDark) {
    if (isDark) {
      return ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFFFF80AB),
          secondary: const Color(0xFFFF4081),
          surface: const Color(0xFF2D1B2E),
          background: const Color(0xFF1A0E1B),
          error: const Color(0xFFFF5252),
        ),
        scaffoldBackgroundColor: const Color(0xFF1A0E1B),
        textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
        cardTheme: CardThemeData(
          color: const Color(0xFF2D1B2E),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: const Color(0xFF2D1B2E),
          elevation: 0,
          titleTextStyle: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
        ),
      );
    }
    
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: Color(0xFFF06292),
        secondary: Color(0xFFFF80AB),
        surface: Color(0xFFFFFFFF),
        background: Color(0xFFFFF0F5),
        error: Color(0xFFE53935),
      ),
      scaffoldBackgroundColor: const Color(0xFFFFF0F5),
      textTheme: GoogleFonts.poppinsTextTheme(ThemeData.light().textTheme),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFFF06292),
        elevation: 0,
        titleTextStyle: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600, color: const Color(0xFFF06292)),
      ),
    );
  }

  /// Professional Grey Theme
  static ThemeData _professionalGreyTheme(bool isDark) {
    if (isDark) {
      return ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFF90A4AE),
          secondary: const Color(0xFF78909C),
          surface: const Color(0xFF263238),
          background: const Color(0xFF1C1C1E),
          error: const Color(0xFFE57373),
        ),
        scaffoldBackgroundColor: const Color(0xFF1C1C1E),
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
        cardTheme: CardThemeData(
          color: const Color(0xFF263238),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: const Color(0xFF263238),
          elevation: 0,
          titleTextStyle: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
        ),
      );
    }
    
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF546E7A),
        secondary: Color(0xFF90A4AE),
        surface: Color(0xFFFFFFFF),
        background: Color(0xFFF5F5F5),
        error: Color(0xFFD32F2F),
      ),
      scaffoldBackgroundColor: const Color(0xFFF5F5F5),
      textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF546E7A),
        elevation: 0,
        titleTextStyle: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600, color: const Color(0xFF546E7A)),
      ),
    );
  }

  /// Sunset Orange Theme
  static ThemeData _sunsetOrangeTheme(bool isDark) {
    if (isDark) {
      return ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFFFF9800),
          secondary: const Color(0xFFFFB74D),
          surface: const Color(0xFF2E1F1A),
          background: const Color(0xFF1A1411),
          error: const Color(0xFFEF5350),
        ),
        scaffoldBackgroundColor: const Color(0xFF1A1411),
        textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
        cardTheme: CardThemeData(
          color: const Color(0xFF2E1F1A),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: const Color(0xFF2E1F1A),
          elevation: 0,
          titleTextStyle: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
        ),
      );
    }
    
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: Color(0xFFFF6F00),
        secondary: Color(0xFFFF9800),
        surface: Color(0xFFFFFFFF),
        background: Color(0xFFFFF8E1),
        error: Color(0xFFD84315),
      ),
      scaffoldBackgroundColor: const Color(0xFFFFF8E1),
      textTheme: GoogleFonts.poppinsTextTheme(ThemeData.light().textTheme),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFFFF6F00),
        elevation: 0,
        titleTextStyle: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600, color: const Color(0xFFFF6F00)),
      ),
    );
  }

  /// Forest Green Theme
  static ThemeData _forestGreenTheme(bool isDark) {
    if (isDark) {
      return ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFF66BB6A),
          secondary: const Color(0xFF81C784),
          surface: const Color(0xFF1B2A1F),
          background: const Color(0xFF0F1712),
          error: const Color(0xFFEF5350),
        ),
        scaffoldBackgroundColor: const Color(0xFF0F1712),
        textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
        cardTheme: CardThemeData(
          color: const Color(0xFF1B2A1F),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: const Color(0xFF1B2A1F),
          elevation: 0,
          titleTextStyle: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
        ),
      );
    }
    
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF388E3C),
        secondary: Color(0xFF66BB6A),
        surface: Color(0xFFFFFFFF),
        background: Color(0xFFF1F8E9),
        error: Color(0xFFC62828),
      ),
      scaffoldBackgroundColor: const Color(0xFFF1F8E9),
      textTheme: GoogleFonts.poppinsTextTheme(ThemeData.light().textTheme),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF388E3C),
        elevation: 0,
        titleTextStyle: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600, color: const Color(0xFF388E3C)),
      ),
    );
  }
}
