import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'dart:io';
import 'package:flutter/material.dart';
import '../models/account.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        // Handle notification tap
      },
    );

    _isInitialized = true;
  }

  Future<bool> requestPermissions() async {
    if (Platform.isIOS) {
      final bool? result = await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
      return result ?? false;
    } else if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      final bool? granted = await androidImplementation?.requestNotificationsPermission();
      return granted ?? false;
    }
    return false;
  }

  // Channel IDs for different notification types
  static const String _channelPaymentReminders = 'payment_reminders';
  static const String _channelDailySummary = 'daily_summary';
  static const String _channelNightlyReminder = 'nightly_reminder';
  static const String _channelBudgetAlerts = 'budget_alerts';
  static const String _channelAchievements = 'achievements';
  static const String _channelCardReminders = 'card_reminders';

  Future<void> scheduleCardClosingReminder({
    required Account account,
  }) async {
    if (!_isInitialized) return;
    if (account.type != AccountType.card) return;
    if (account.closingDay == null) return;

    final int notificationId = account.id.hashCode;
    final now = DateTime.now();
    
    // Calculate next closing date (approximate for monthly recurrence)
    // We target 2 days before closing
    final int warningDays = 2;
    
    // Determine the day to schedule (closingDay - 2)
    // Handle wrap around if closing day is 1 or 2 (e.g. 1 - 2 = -1 -> end of previous month)
    // But for recurring monthly notification, we need a fixed day.
    // If closingDay is 1, we want notification on 29/30/31 of previous month?
    // matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime works on specific day.
    // If closingDay=5, notificationDay=3. It will fire on 3rd of every month.
    // If closingDay=1, notificationDay would be effectively "Day 29/30/31".
    // This is tricky for recurrence.
    // Simplified approach: If closingDay <= 2, schedule for day 28.
    // Else closingDay - 2.
    
    int notificationDay = account.closingDay! - warningDays;
    if (notificationDay < 1) notificationDay = 28; // Fallback to 28th to be safe
    
    // Construct the next occurrence
    DateTime scheduledDate = DateTime(now.year, now.month, notificationDay, 9, 0);
    if (scheduledDate.isBefore(now)) {
       scheduledDate = scheduledDate.add(const Duration(days: 1)); // Try next day? No, next month.
       // Actually for zonedSchedule with matchDateTimeComponents, the date just needs to be in the future
       // to start the sequence.
       if (scheduledDate.isBefore(now)) {
           // If today is 5th and we schedule for 3rd, we must schedule for next month's 3rd.
           scheduledDate = DateTime(now.year, now.month + 1, notificationDay, 9, 0);
       }
    }

    await flutterLocalNotificationsPlugin.zonedSchedule(
      notificationId,
      'Cierre de Tarjeta: ${account.name}',
      'Tu tarjeta cierra el día ${account.closingDay}. ¡Revisa tus gastos!',
      tz.TZDateTime.from(scheduledDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelCardReminders,
          'Recordatorios de Tarjetas',
          channelDescription: 'Avisos de cierre y vencimiento de tarjetas',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
    );
  }

  Future<void> scheduleCardDueReminder({
    required Account account,
  }) async {
    if (!_isInitialized) return;
    if (account.type != AccountType.card) return;
    if (account.dueDay == null) return;

    final int notificationId = account.id.hashCode + 1; // Different ID from closing
    final now = DateTime.now();
    
    // Warn 2 days before due date
    final int warningDays = 2;
    
    int notificationDay = account.dueDay! - warningDays;
    if (notificationDay < 1) notificationDay = 28; // Fallback
    
    DateTime scheduledDate = DateTime(now.year, now.month, notificationDay, 9, 0);
    if (scheduledDate.isBefore(now)) {
       scheduledDate = DateTime(now.year, now.month + 1, notificationDay, 9, 0);
    }

    await flutterLocalNotificationsPlugin.zonedSchedule(
      notificationId,
      'Vencimiento de Tarjeta: ${account.name}',
      'Tu tarjeta vence el día ${account.dueDay}. ¡No olvides pagar!',
      tz.TZDateTime.from(scheduledDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelCardReminders,
          'Recordatorios de Tarjetas',
          channelDescription: 'Avisos de cierre y vencimiento de tarjetas',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
    );
  }

  Future<void> schedulePaymentReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    if (!_isInitialized) return;
    if (scheduledDate.isBefore(DateTime.now())) return;

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelPaymentReminders,
          'Recordatorios de Pagos',
          channelDescription: 'Notificaciones para pagos programados y vencimientos',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Schedule daily morning summary (e.g., 9 AM)
  Future<void> scheduleDailySummary({
    required TimeOfDay time,
    required String summary,
  }) async {
    if (!_isInitialized) return;

    final now = DateTime.now();
    var scheduledDate = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    // If time has passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await flutterLocalNotificationsPlugin.zonedSchedule(
      1000, // Fixed ID for daily summary
      'Resumen Diario 📊',
      summary,
      tz.TZDateTime.from(scheduledDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelDailySummary,
          'Resumen Diario',
          channelDescription: 'Resumen matutino de tus finanzas',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // Repeat daily
    );
  }

  /// Schedule nightly reminder to log expenses (e.g., 8 PM)
  Future<void> scheduleNightlyReminder({
    required TimeOfDay time,
  }) async {
    if (!_isInitialized) return;

    final now = DateTime.now();
    var scheduledDate = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await flutterLocalNotificationsPlugin.zonedSchedule(
      1001, // Fixed ID for nightly reminder
      '¿Registraste tus gastos de hoy? 📝',
      'No olvides agregar tus movimientos del día',
      tz.TZDateTime.from(scheduledDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelNightlyReminder,
          'Recordatorio Nocturno',
          channelDescription: 'Recordatorio para registrar gastos diarios',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // Repeat daily
    );
  }

  /// Send budget alert when category reaches threshold
  Future<void> sendBudgetAlert({
    required String categoryName,
    required double percentage,
    required double spent,
    required double limit,
  }) async {
    if (!_isInitialized) return;

    String emoji = '⚠️';
    String title = 'Alerta de Presupuesto';
    String body;

    if (percentage >= 100) {
      emoji = '🚨';
      title = '¡Presupuesto Excedido!';
      body = '$categoryName: Gastaste ₲$spent de ₲$limit (${percentage.toInt()}%)';
    } else if (percentage >= 80) {
      body = '$categoryName está al ${percentage.toInt()}% del límite mensual';
    } else {
      return; // Don't send if under 80%
    }

    await flutterLocalNotificationsPlugin.show(
      categoryName.hashCode, // Unique ID per category
      '$emoji $title',
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelBudgetAlerts,
          'Alertas de Presupuesto',
          channelDescription: 'Notificaciones cuando te acercas al límite de presupuesto',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  /// Send weekly summary (e.g., Sunday night)
  Future<void> sendWeeklySummary({
    required double thisWeekSavings,
    required double lastWeekSavings,
  }) async {
    if (!_isInitialized) return;

    final difference = thisWeekSavings - lastWeekSavings;
    String emoji = difference >= 0 ? '🎉' : '📉';
    String comparison;

    if (difference > 0) {
      comparison = 'Ahorraste ₲${difference.abs().toInt()} más que la semana pasada';
    } else if (difference < 0) {
      comparison = 'Ahorraste ₲${difference.abs().toInt()} menos que la semana pasada';
    } else {
      comparison = 'Mismo ahorro que la semana pasada';
    }

    await flutterLocalNotificationsPlugin.show(
      1002, // Fixed ID for weekly summary
      '$emoji Resumen Semanal',
      comparison,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelDailySummary,
          'Resumen Semanal',
          channelDescription: 'Resumen de tus finanzas semanales',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  /// Send achievement unlocked notification
  Future<void> sendAchievementNotification({
    required String achievementTitle,
    required String achievementDescription,
  }) async {
    if (!_isInitialized) return;

    await flutterLocalNotificationsPlugin.show(
      achievementTitle.hashCode,
      '🏆 ¡Logro Desbloqueado!',
      '$achievementTitle: $achievementDescription',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelAchievements,
          'Logros',
          channelDescription: 'Notificaciones de logros desbloqueados',
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  Future<void> cancelNotification(int id) async {
    if (!_isInitialized) return;
    await flutterLocalNotificationsPlugin.cancel(id);
  }

  Future<void> cancelAll() async {
    if (!_isInitialized) return;
    await flutterLocalNotificationsPlugin.cancelAll();
  }

  /// Cancel specific recurring notifications
  Future<void> cancelDailySummary() async {
    await cancelNotification(1000);
  }

  Future<void> cancelNightlyReminder() async {
    await cancelNotification(1001);
  }
}
