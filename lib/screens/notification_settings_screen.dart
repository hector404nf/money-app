import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import '../models/category.dart';
import '../models/transaction.dart';
import '../providers/data_provider.dart';
import '../services/notification_service.dart';
import '../utils/constants.dart';

/// Screen for configuring notification preferences
class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  final NotificationService _notificationService = NotificationService();
  late Box<dynamic> _settingsBox;
  
  // Settings state
  bool _dailySummaryEnabled = false;
  TimeOfDay _dailySummaryTime = const TimeOfDay(hour: 9, minute: 0);
  
  bool _nightlyReminderEnabled = false;
  TimeOfDay _nightlyReminderTime = const TimeOfDay(hour: 20, minute: 0);
  
  bool _budgetAlertsEnabled = true;
  bool _achievementNotificationsEnabled = true;
  bool _weeklySummaryEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _settingsBox = await Hive.openBox('notification_settings');
    
    setState(() {
      _dailySummaryEnabled = _settingsBox.get('daily_summary_enabled', defaultValue: false);
      _nightlyReminderEnabled = _settingsBox.get('nightly_reminder_enabled', defaultValue: false);
      _budgetAlertsEnabled = _settingsBox.get('budget_alerts_enabled', defaultValue: true);
      _achievementNotificationsEnabled = _settingsBox.get('achievement_notifications_enabled', defaultValue: true);
      _weeklySummaryEnabled = _settingsBox.get('weekly_summary_enabled', defaultValue: false);
      
      // Load times
      final dailyHour = _settingsBox.get('daily_summary_hour', defaultValue: 9);
      final dailyMinute = _settingsBox.get('daily_summary_minute', defaultValue: 0);
      _dailySummaryTime = TimeOfDay(hour: dailyHour, minute: dailyMinute);
      
      final nightlyHour = _settingsBox.get('nightly_reminder_hour', defaultValue: 20);
      final nightlyMinute = _settingsBox.get('nightly_reminder_minute', defaultValue: 0);
      _nightlyReminderTime = TimeOfDay(hour: nightlyHour, minute: nightlyMinute);
    });
  }

  Future<void> _saveSettings() async {
    await _settingsBox.put('daily_summary_enabled', _dailySummaryEnabled);
    await _settingsBox.put('nightly_reminder_enabled', _nightlyReminderEnabled);
    await _settingsBox.put('budget_alerts_enabled', _budgetAlertsEnabled);
    await _settingsBox.put('achievement_notifications_enabled', _achievementNotificationsEnabled);
    await _settingsBox.put('weekly_summary_enabled', _weeklySummaryEnabled);
    
    await _settingsBox.put('daily_summary_hour', _dailySummaryTime.hour);
    await _settingsBox.put('daily_summary_minute', _dailySummaryTime.minute);
    await _settingsBox.put('nightly_reminder_hour', _nightlyReminderTime.hour);
    await _settingsBox.put('nightly_reminder_minute', _nightlyReminderTime.minute);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _buildYesterdaySummary(DataProvider provider) {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    final yesterdayDate = DateTime(yesterday.year, yesterday.month, yesterday.day);

    double spent = 0;
    double income = 0;
    int expenseCount = 0;
    int incomeCount = 0;

    for (final tx in provider.transactions) {
      if (tx.status != TransactionStatus.pagado) continue;
      if (!_isSameDay(tx.date, yesterdayDate)) continue;

      Category? category;
      try {
        category = provider.categories.firstWhere((c) => c.id == tx.categoryId);
      } catch (_) {
        category = null;
      }
      if (category?.isTransferLike == true) continue;

      if (tx.amount < 0) {
        spent += tx.amount.abs();
        expenseCount++;
      } else if (tx.amount > 0) {
        income += tx.amount;
        incomeCount++;
      }
    }

    final balance = provider.calculateTotalBalance();
    if (spent == 0 && income == 0) {
      return 'Ayer no registraste movimientos. Balance: ${AppColors.formatCurrency(balance)}';
    }

    final spentText = spent > 0 ? 'Gastaste ${AppColors.formatCurrency(spent)} ($expenseCount)' : null;
    final incomeText = income > 0 ? 'Ingresaste ${AppColors.formatCurrency(income)} ($incomeCount)' : null;

    final parts = <String>[
      if (spentText != null) spentText,
      if (incomeText != null) incomeText,
      'Balance: ${AppColors.formatCurrency(balance)}',
    ];
    return parts.join(' · ');
  }

  Future<void> _pickTime(BuildContext context, TimeOfDay initialTime, Function(TimeOfDay) onPicked) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
    
    if (picked != null) {
      onPicked(picked);
      await _saveSettings();
    }
  }

  Future<void> _toggleDailySummary(bool value) async {
    final provider = Provider.of<DataProvider>(context, listen: false);
    setState(() => _dailySummaryEnabled = value);
    await _saveSettings();
    
    if (value) {
      await _notificationService.scheduleDailySummary(
        time: _dailySummaryTime,
        summary: _buildYesterdaySummary(provider),
      );
    } else {
      await _notificationService.cancelDailySummary();
    }
  }

  Future<void> _toggleNightlyReminder(bool value) async {
    setState(() => _nightlyReminderEnabled = value);
    await _saveSettings();
    
    if (value) {
      await _notificationService.scheduleNightlyReminder(time: _nightlyReminderTime);
    } else {
      await _notificationService.cancelNightlyReminder();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = Provider.of<DataProvider>(context, listen: false);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurar Notificaciones'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header info
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.notifications_active, color: theme.colorScheme.primary, size: 32),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Configura las notificaciones que quieres recibir para mantenerte al día con tus finanzas.',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Daily Summary
          Text('Resúmenes Automáticos', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Resumen Diario Matutino'),
                  subtitle: Text(
                    _dailySummaryEnabled
                        ? 'Todos los días a las ${_dailySummaryTime.format(context)}'
                        : 'Recibe un resumen de tus gastos de ayer',
                  ),
                  secondary: const Icon(Icons.wb_sunny),
                  value: _dailySummaryEnabled,
                  onChanged: _toggleDailySummary,
                ),
                if (_dailySummaryEnabled)
                  ListTile(
                    leading: const SizedBox(width: 40),
                    title: const Text('Hora del resumen'),
                    trailing: TextButton(
                      onPressed: () => _pickTime(context, _dailySummaryTime, (time) {
                        setState(() => _dailySummaryTime = time);
                        if (_dailySummaryEnabled) {
                          _notificationService.scheduleDailySummary(
                            time: time,
                            summary: _buildYesterdaySummary(provider),
                          );
                        }
                      }),
                      child: Text(_dailySummaryTime.format(context)),
                    ),
                  ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Resumen Semanal'),
                  subtitle: const Text('Los domingos por la noche'),
                  secondary: const Icon(Icons.calendar_today),
                  value: _weeklySummaryEnabled,
                  onChanged: (value) async {
                    setState(() => _weeklySummaryEnabled = value);
                    await _saveSettings();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Reminders
          Text('Recordatorios', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: SwitchListTile(
              title: const Text('Recordatorio Nocturno'),
              subtitle: Text(
                _nightlyReminderEnabled
                    ? 'Cada noche a las ${_nightlyReminderTime.format(context)}'
                    : 'Te recordamos registrar tus gastos del día',
              ),
              secondary: const Icon(Icons.bedtime),
              value: _nightlyReminderEnabled,
              onChanged: _toggleNightlyReminder,
            ),
          ),
          if (_nightlyReminderEnabled)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                leading: const SizedBox(width: 40),
                title: const Text('Hora del recordatorio'),
                trailing: TextButton(
                  onPressed: () => _pickTime(context, _nightlyReminderTime, (time) {
                    setState(() => _nightlyReminderTime = time);
                    if (_nightlyReminderEnabled) {
                      _notificationService.scheduleNightlyReminder(time: time);
                    }
                  }),
                  child: Text(_nightlyReminderTime.format(context)),
                ),
              ),
            ),
          const SizedBox(height: 24),
          
          // Alerts
          Text('Alertas', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Alertas de Presupuesto'),
                  subtitle: const Text('Cuando te acerques al límite de una categoría'),
                  secondary: const Icon(Icons.warning_amber),
                  value: _budgetAlertsEnabled,
                  onChanged: (value) async {
                    setState(() => _budgetAlertsEnabled = value);
                    await _saveSettings();
                  },
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Logros Desbloqueados'),
                  subtitle: const Text('Cuando consigas un nuevo logro'),
                  secondary: const Icon(Icons.emoji_events),
                  value: _achievementNotificationsEnabled,
                  onChanged: (value) async {
                    setState(() => _achievementNotificationsEnabled = value);
                    await _saveSettings();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Test notification button
          OutlinedButton.icon(
            onPressed: () async {
              await _notificationService.sendAchievementNotification(
                achievementTitle: 'Configuración Completa',
                achievementDescription: '¡Configuraste las notificaciones correctamente!',
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Notificación de prueba enviada')),
                );
              }
            },
            icon: const Icon(Icons.send),
            label: const Text('Enviar Notificación de Prueba'),
          ),
          const SizedBox(height: 8),
          Text(
            'Nota: Asegúrate de que los permisos de notificación estén habilitados en la configuración de tu dispositivo.',
            style: theme.textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
