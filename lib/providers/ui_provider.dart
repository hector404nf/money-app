import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class UiProvider extends ChangeNotifier {
  static const _boxName = 'settings';
  static const _themeKey = 'themeMode';
  static const _selectedThemeKey = 'selectedTheme';
  static const _notificationsKey = 'notificationsEnabled';
  static const _seenOnboardingKey = 'seenOnboarding';
  static const _paydayDayKey = 'paydayDay';
  static const _forcedSavingsKey = 'forcedSavingsMode';
  static const _visitedDebtSnowballKey = 'visitedDebtSnowball';

  ThemeMode _themeMode = ThemeMode.system;
  AppTheme _selectedTheme = AppTheme.oceanBlue;
  bool _notificationsEnabled = true;
  bool _seenOnboarding = false;
  int? _paydayDay;
  bool _forcedSavingsMode = false;
  bool _visitedDebtSnowball = false;

  ThemeMode get themeMode => _themeMode;
  AppTheme get selectedTheme => _selectedTheme;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get seenOnboarding => _seenOnboarding;
  int? get paydayDay => _paydayDay;
  bool get forcedSavingsMode => _forcedSavingsMode;
  bool get visitedDebtSnowball => _visitedDebtSnowball;

  Future<void> load() async {
    final box = await Hive.openBox(_boxName);
    final saved = box.get(_themeKey) as String?;
    _notificationsEnabled = box.get(_notificationsKey, defaultValue: true) as bool;
    _seenOnboarding = box.get(_seenOnboardingKey, defaultValue: false) as bool;
    _paydayDay = box.get(_paydayDayKey) as int?;
    _forcedSavingsMode = box.get(_forcedSavingsKey, defaultValue: false) as bool;
    _visitedDebtSnowball = box.get(_visitedDebtSnowballKey, defaultValue: false) as bool;
    
    // Load selected theme
    final savedTheme = box.get(_selectedThemeKey, defaultValue: 'oceanBlue') as String;
    _selectedTheme = AppTheme.values.firstWhere(
      (theme) => theme.name == savedTheme,
      orElse: () => AppTheme.oceanBlue,
    );
    
    if (saved != null) {
      switch (saved) {
        case 'light':
          _themeMode = ThemeMode.light;
          break;
        case 'dark':
          _themeMode = ThemeMode.dark;
          break;
        default:
          _themeMode = ThemeMode.system;
      }
    }
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final box = await Hive.openBox(_boxName);
    String value;
    switch (mode) {
      case ThemeMode.light:
        value = 'light';
        break;
      case ThemeMode.dark:
        value = 'dark';
        break;
      case ThemeMode.system:
        value = 'system';
        break;
    }
    await box.put(_themeKey, value);
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    _notificationsEnabled = enabled;
    notifyListeners();
    final box = await Hive.openBox(_boxName);
    await box.put(_notificationsKey, enabled);
  }

  Future<void> completeOnboarding() async {
    _seenOnboarding = true;
    notifyListeners();
    final box = await Hive.openBox(_boxName);
    await box.put(_seenOnboardingKey, true);
  }

  Future<void> setPaydayDay(int day) async {
    _paydayDay = day;
    notifyListeners();
    final box = await Hive.openBox(_boxName);
    await box.put(_paydayDayKey, day);
  }

  Future<void> setForcedSavingsMode(bool enabled) async {
    _forcedSavingsMode = enabled;
    notifyListeners();
    final box = await Hive.openBox(_boxName);
    await box.put(_forcedSavingsKey, enabled);
  }

  Future<void> markVisitedDebtSnowball() async {
    if (_visitedDebtSnowball) return;
    _visitedDebtSnowball = true;
    notifyListeners();
    final box = await Hive.openBox(_boxName);
    await box.put(_visitedDebtSnowballKey, true);
  }

  Future<void> setTheme(AppTheme theme) async {
    _selectedTheme = theme;
    notifyListeners();
    final box = await Hive.openBox(_boxName);
    await box.put(_selectedThemeKey, theme.name);
  }
}

/// Available app themes
enum AppTheme {
  oceanBlue,
  dark,
  cherryBlossom,
  professionalGrey,
  sunsetOrange,
  forestGreen,
}

/// Extension to get theme display names
extension AppThemeExtension on AppTheme {
  String get displayName {
    switch (this) {
      case AppTheme.oceanBlue:
        return 'Océano Azul';
      case AppTheme.dark:
        return 'Oscuro';
      case AppTheme.cherryBlossom:
        return 'Flor de Cerezo';
      case AppTheme.professionalGrey:
        return 'Gris Profesional';
      case AppTheme.sunsetOrange:
        return 'Atardecer Naranja';
      case AppTheme.forestGreen:
        return 'Bosque Verde';
    }
  }

  String get description {
    switch (this) {
      case AppTheme.oceanBlue:
        return 'El tema original, tranquilo y confiable';
      case AppTheme.dark:
        return 'Elegante y fácil para la vista';
      case AppTheme.cherryBlossom:
        return 'Suave y delicado';
      case AppTheme.professionalGrey:
        return 'Minimalista y corporativo';
      case AppTheme.sunsetOrange:
        return 'Cálido y energizante';
      case AppTheme.forestGreen:
        return 'Natural y relajante';
    }
  }

  IconData get icon {
    switch (this) {
      case AppTheme.oceanBlue:
        return Icons.water;
      case AppTheme.dark:
        return Icons.dark_mode;
      case AppTheme.cherryBlossom:
        return Icons.local_florist;
      case AppTheme.professionalGrey:
        return Icons.business_center;
      case AppTheme.sunsetOrange:
        return Icons.wb_sunny;
      case AppTheme.forestGreen:
        return Icons.park;
    }
  }
}
