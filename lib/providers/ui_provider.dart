import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class UiProvider extends ChangeNotifier {
  static const _boxName = 'settings';
  static const _themeKey = 'themeMode';
  static const _notificationsKey = 'notificationsEnabled';
  static const _seenOnboardingKey = 'seenOnboarding';
  static const _paydayDayKey = 'paydayDay';
  static const _forcedSavingsKey = 'forcedSavingsMode';
  static const _visitedDebtSnowballKey = 'visitedDebtSnowball';

  ThemeMode _themeMode = ThemeMode.system;
  bool _notificationsEnabled = true;
  bool _seenOnboarding = false;
  int? _paydayDay;
  bool _forcedSavingsMode = false;
  bool _visitedDebtSnowball = false;

  ThemeMode get themeMode => _themeMode;
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
      default:
        value = 'system';
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
}

