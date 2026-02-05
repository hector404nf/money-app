import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/data_provider.dart';
import '../providers/ui_provider.dart';
import '../utils/constants.dart';
import '../services/notification_service.dart';
import 'sync_screen.dart';
import 'categories_screen.dart';
import 'email_import_screen.dart';
import 'excel_import_screen.dart';
import 'notification_settings_screen.dart';
import 'subscriptions_screen.dart';
import 'purchase_simulator_screen.dart';
import 'debt_snowball_screen.dart';
import 'achievements_screen.dart';
import 'challenges_screen.dart';
import 'events_screen.dart';
import 'category_rules_screen.dart';

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final ui = Provider.of<UiProvider>(context);
    final theme = Theme.of(context);

    return SafeArea(
      top: true,
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Header: "Ajustes"
          Text(
            'Ajustes',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.titleLarge?.color,
                ),
          ),
          const SizedBox(height: 24),

          // User Profile Card (Handles Sync Status)
          const _UserProfileCard(),
          const SizedBox(height: 32),

          // CUENTA Section
          const _SectionHeader(title: 'CUENTA'),
          _SettingsTile(
            icon: Icons.person_outline,
            title: 'Perfil',
            subtitle: 'usuario@email.com',
            onTap: () {
               Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SyncScreen()),
              );
            },
          ),
          _SettingsTile(
            icon: Icons.lock_outline,
            title: 'Seguridad',
            subtitle: 'Contraseña, 2FA',
            onTap: () {},
          ),
           _SettingsTile(
            icon: Icons.credit_card_outlined,
            title: 'Suscripción',
            subtitle: 'Plan Gratuito',
            onTap: () {},
          ),
          const SizedBox(height: 24),

          // PREFERENCIAS Section
          const _SectionHeader(title: 'HERRAMIENTAS'),
          _SettingsTile(
            icon: Icons.emoji_events_outlined,
            title: 'Logros y Medallas',
            subtitle: 'Tu progreso gamificado',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AchievementsScreen()),
              );
            },
          ),
          _SettingsTile(
            icon: Icons.flag_outlined,
            title: 'Retos de Ahorro',
            subtitle: 'Desafíos para mejorar tus finanzas',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ChallengesScreen()),
              );
            },
          ),
          _SettingsTile(
            icon: Icons.subscriptions_outlined,
            title: 'Mis Suscripciones',
            subtitle: 'Netflix, Spotify, Gym...',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SubscriptionsScreen()),
              );
            },
          ),
          _SettingsTile(
            icon: Icons.flight_takeoff,
            title: 'Modo Viaje / Eventos',
            subtitle: 'Gestionar viajes y monedas',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const EventsScreen()),
              );
            },
          ),
          _SettingsTile(
            icon: Icons.shopping_bag_outlined,
            title: 'Simulador de Compras',
            subtitle: '¿Puedo comprarlo?',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PurchaseSimulatorScreen()),
              );
            },
          ),
          _SettingsTile(
            icon: Icons.snowshoeing,
            title: 'Bola de Nieve (Deudas)',
            subtitle: 'Plan para salir de deudas',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const DebtSnowballScreen()),
              );
            },
          ),
          _SettingsTile(
            icon: Icons.email_outlined,
            title: 'Importar desde correo (MVP)',
            subtitle: 'Leer correos recientes y proponer movimientos',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const EmailImportScreen()),
              );
            },
          ),
          const SizedBox(height: 24),

          const _SectionHeader(title: 'PREFERENCIAS'),
          _SettingsTile(
            icon: Icons.category_outlined,
            title: 'Categorías',
            subtitle: 'Gestionar categorías e iconos',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CategoriesScreen()),
              );
            },
          ),
          _SettingsTile(
            icon: Icons.rule,
            title: 'Reglas de Categorización',
            subtitle: 'Asignación automática por texto',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CategoryRulesScreen()),
              );
            },
          ),
          _SettingsTile(
            icon: Icons.savings_outlined,
            title: 'Modo Ahorro Forzado',
            subtitle: 'Alerta si excedes el presupuesto',
            trailing: Switch(
              value: ui.forcedSavingsMode,
              onChanged: (v) => ui.setForcedSavingsMode(v),
              activeColor: AppColors.primary,
            ),
          ),
          _SettingsTile(
            icon: Icons.notifications_none_outlined,
            title: 'Notificaciones',
            trailing: Switch(
              value: ui.notificationsEnabled,
              onChanged: (v) async {
                if (v) {
                  final granted = await NotificationService().requestPermissions();
                  if (granted) {
                    ui.setNotificationsEnabled(true);
                  } else {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Se requieren permisos para notificaciones')),
                      );
                    }
                  }
                } else {
                  ui.setNotificationsEnabled(false);
                  NotificationService().cancelAll();
                }
              },
              activeColor: AppColors.primary,
            ),
          ),
          _SettingsTile(
            icon: Icons.tune,
            title: 'Configurar notificaciones',
            subtitle: 'Resumen diario y recordatorios',
            onTap: () {
              if (!ui.notificationsEnabled) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Activa notificaciones para configurar')),
                );
                return;
              }
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NotificationSettingsScreen()),
              );
            },
          ),
          _SettingsTile(
            icon: Icons.payments_outlined,
            title: 'Ciclo de cobro',
            subtitle: ui.paydayDay != null
                ? 'Cobro el día ${ui.paydayDay} de cada mes'
                : 'Configurar día de cobro',
            onTap: () {
              final currentDay = ui.paydayDay ?? DateTime.now().day;
              int tempDay = currentDay.clamp(1, 31);
              showModalBottomSheet(
                context: context,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                builder: (context) {
                  final theme = Theme.of(context);
                  final isDark = theme.brightness == Brightness.dark;
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                    child: StatefulBuilder(
                      builder: (context, setState) {
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: Container(
                                width: 40,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.grey[700] : Colors.grey[300],
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Día de cobro',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Selecciona el día aproximado en que cobrás cada mes. Esto se usa para calcular cuántos días faltan y tu gasto diario recomendado.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<int>(
                                    value: tempDay,
                                    decoration: const InputDecoration(
                                      labelText: 'Día del mes',
                                      border: OutlineInputBorder(),
                                    ),
                                    items: List.generate(
                                      31,
                                      (index) {
                                        final day = index + 1;
                                        return DropdownMenuItem(
                                          value: day,
                                          child: Text(day.toString()),
                                        );
                                      },
                                    ),
                                    onChanged: (value) {
                                      if (value == null) return;
                                      setState(() {
                                        tempDay = value;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () async {
                                  await ui.setPaydayDay(tempDay);
                                  if (context.mounted) {
                                    Navigator.pop(context);
                                  }
                                },
                                child: const Text('Guardar'),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  );
                },
              );
            },
          ),
          _SettingsTile(
            icon: Icons.savings_outlined,
            title: 'Modo Ahorro Forzado',
            subtitle: ui.forcedSavingsMode ? 'Activado' : 'Desactivado',
             trailing: Switch(
              value: ui.forcedSavingsMode,
              onChanged: (v) {
                ui.setForcedSavingsMode(v);
              },
            ),
          ),
          _SettingsTile(
            icon: Icons.palette_outlined,
            title: 'Tema y Apariencia',
            subtitle: '${ui.selectedTheme.displayName} • ${ui.themeMode == ThemeMode.system ? "Automático" : (ui.themeMode == ThemeMode.dark ? "Oscuro" : "Claro")}',
            onTap: () => _showThemeDialog(context, ui),
          ),
          _SettingsTile(
            icon: Icons.language_outlined,
            title: 'Idioma',
            subtitle: 'Español',
            onTap: () {},
          ),
          const SizedBox(height: 24),

           // DATOS Section
          const _SectionHeader(title: 'DATOS'),
          _SettingsTile(
            icon: Icons.table_view_outlined,
            title: 'Importar desde Excel',
            subtitle: 'Cargar movimientos desde archivo',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ExcelImportScreen()),
              );
            },
          ),
          _SettingsTile(
            icon: Icons.download_outlined,
            title: 'Exportar datos',
            subtitle: 'CSV, PDF',
            onTap: () {},
          ),
          _SettingsTile(
            icon: Icons.delete_outline,
            title: 'Eliminar todos los datos',
            textColor: Colors.red,
            iconColor: Colors.red,
            iconBgColor: Colors.red.withOpacity(0.1),
            onTap: () {},
          ),
          const SizedBox(height: 24),

           // SOPORTE Section
          const _SectionHeader(title: 'SOPORTE'),
          _SettingsTile(
            icon: Icons.help_outline,
            title: 'Centro de ayuda',
            onTap: () {},
          ),
           _SettingsTile(
            icon: Icons.logout_outlined,
            title: 'Cerrar sesión',
            textColor: Colors.red,
            iconColor: Colors.red,
            iconBgColor: Colors.red.withOpacity(0.1),
            onTap: () {
               // Sign out logic
               final provider = Provider.of<DataProvider>(context, listen: false);
               if (provider.isCloudSignedIn) {
                 provider.signOutCloud();
               }
            },
          ),
          
          const SizedBox(height: 40),
          Center(
            child: Text(
              'Money App v1.0.0',
              style: TextStyle(color: AppColors.textSecondary.withOpacity(0.5)),
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  void _showThemeDialog(BuildContext context, UiProvider ui) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Tema y Apariencia'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Modo', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                RadioListTile<ThemeMode>(
                  title: const Text('Automático (Sistema)'),
                  value: ThemeMode.system,
                  groupValue: ui.themeMode,
                  onChanged: (v) {
                    if (v != null) ui.setThemeMode(v);
                    Navigator.pop(context);
                  },
                ),
                RadioListTile<ThemeMode>(
                  title: const Text('Claro'),
                  value: ThemeMode.light,
                  groupValue: ui.themeMode,
                  onChanged: (v) {
                    if (v != null) ui.setThemeMode(v);
                    Navigator.pop(context);
                  },
                ),
                RadioListTile<ThemeMode>(
                  title: const Text('Oscuro'),
                  value: ThemeMode.dark,
                  groupValue: ui.themeMode,
                  onChanged: (v) {
                    if (v != null) ui.setThemeMode(v);
                    Navigator.pop(context);
                  },
                ),
                const Divider(),
                const Text('Color de Acento', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: AppTheme.values.map((theme) {
                    final isSelected = ui.selectedTheme == theme;
                    return GestureDetector(
                      onTap: () {
                        ui.setTheme(theme);
                      },
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: theme.color,
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(
                                  color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
                                  width: 3,
                                )
                              : null,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, color: Colors.white)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }
}

class _UserProfileCard extends StatelessWidget {
  const _UserProfileCard();

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DataProvider>(context);
    final user = provider.cloudUserEmail;
    final isConnected = provider.isCloudSignedIn;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          AppShadows.soft,
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: isConnected ? AppColors.primary : (isDark ? Colors.grey.shade800 : Colors.grey.shade300),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              isConnected && user != null && user.isNotEmpty ? user[0].toUpperCase() : '?',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isConnected ? 'Usuario Conectado' : 'Invitado',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isConnected ? (user ?? 'Sin email') : 'Inicia sesión para sincronizar',
                  style: TextStyle(
                    color: isDark ? Colors.white60 : AppColors.textSecondary,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              // Open sync screen
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SyncScreen()),
              );
            },
            child: Text(
              isConnected ? 'Editar' : 'Entrar',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: TextStyle(
          color: isDark ? Colors.white70 : AppColors.textSecondary.withOpacity(0.7),
          fontWeight: FontWeight.bold,
          fontSize: 12,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? textColor;
  final Color? iconColor;
  final Color? iconBgColor;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.textColor,
    this.iconColor,
    this.iconBgColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: iconBgColor ?? (isDark ? Colors.grey.shade800 : Colors.grey.shade100),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor ?? (isDark ? Colors.white70 : AppColors.textSecondary),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: textColor ?? theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: TextStyle(
                            color: isDark ? Colors.white54 : AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null)
                  trailing!
                else
                  Icon(
                    Icons.chevron_right,
                    color: isDark ? Colors.white30 : Colors.grey.shade300,
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
