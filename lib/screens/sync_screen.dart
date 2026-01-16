import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/data_provider.dart';
import '../providers/ui_provider.dart';
import '../utils/constants.dart';
import '../services/update_service.dart';
import '../services/notification_service.dart';
import 'categories_screen.dart';

// Keeps existing SyncScreen for direct navigation if needed, or as a detail view
class SyncScreen extends StatelessWidget {
  const SyncScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ui = Provider.of<UiProvider>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Sincronización',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: theme.textTheme.titleLarge?.color,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: _SyncContent(),
      ),
    );
  }
}

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final ui = Provider.of<UiProvider>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
            icon: Icons.system_update,
            title: 'Actualizaciones',
            subtitle: 'Verificar nueva versión',
            onTap: () {
              UpdateService().checkForUpdates(context, manualCheck: true);
            },
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
            icon: Icons.dark_mode_outlined,
            title: 'Modo oscuro',
             trailing: Switch(
              value: ui.themeMode == ThemeMode.dark,
              onChanged: (v) {
                if (v) {
                  ui.setThemeMode(ThemeMode.dark);
                } else {
                  ui.setThemeMode(ThemeMode.light);
                }
              },
              activeColor: AppColors.primary,
            ),
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconBgColor ?? (isDark ? Colors.grey.shade800 : Colors.grey.shade50),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor ?? (isDark ? Colors.white70 : AppColors.textSecondary),
                    size: 22,
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
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: textColor ?? theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.white60 : AppColors.textSecondary.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) trailing!,
                if (trailing == null && onTap != null)
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

class _SyncContent extends StatelessWidget {
  const _SyncContent();

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DataProvider>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              AppShadows.soft,
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: provider.isCloudSignedIn
                      ? AppColors.income.withOpacity(0.1)
                      : (isDark ? Colors.grey.shade800 : Colors.grey.shade100),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.cloud_outlined,
                  size: 40,
                  color: provider.isCloudSignedIn ? AppColors.income : Colors.grey,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                provider.isCloudSignedIn ? 'Conectado' : 'No conectado',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                provider.isCloudSignedIn
                    ? (provider.cloudUserEmail ?? 'Cuenta sin email')
                    : 'Inicia sesión para respaldar tus datos',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        if (!provider.isCloudSignedIn)
          FilledButton.icon(
            onPressed: provider.isCloudSyncing
                ? null
                : () async {
                    await _run(context, () => provider.signInWithGoogle());
                  },
            icon: const Icon(Icons.login),
            label: const Text('INICIAR SESIÓN CON GOOGLE'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
              shadowColor: AppColors.primary.withOpacity(0.4),
              textStyle: const TextStyle(fontWeight: FontWeight.bold),
            ),
          )
        else ...[
          OutlinedButton.icon(
            onPressed: provider.isCloudSyncing
                ? null
                : () async {
                    await _run(context, () => provider.uploadToCloud());
                  },
            icon: const Icon(Icons.cloud_upload_outlined),
            label: const Text('SUBIR A LA NUBE'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              side: const BorderSide(color: AppColors.primary, width: 1.5),
              foregroundColor: AppColors.primary,
              textStyle: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: provider.isCloudSyncing
                ? null
                : () async {
                    await _run(context, () => provider.downloadFromCloud(replaceLocal: true));
                  },
            icon: const Icon(Icons.cloud_download_outlined),
            label: const Text('BAJAR Y REEMPLAZAR LOCAL'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              side: const BorderSide(color: AppColors.primary, width: 1.5),
              foregroundColor: AppColors.primary,
              textStyle: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.tonalIcon(
            onPressed: provider.isCloudSyncing
                ? null
                : () async {
                    await _run(context, () => provider.signOutCloud());
                  },
            icon: const Icon(Icons.logout),
            label: const Text('CERRAR SESIÓN'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              backgroundColor: isDark ? Colors.red.withOpacity(0.1) : Colors.red.shade50,
              foregroundColor: Colors.red,
              textStyle: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
        const SizedBox(height: 24),
        if (provider.isCloudSyncing)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
          ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? Colors.amber.withOpacity(0.1) : Colors.amber.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isDark ? Colors.amber.withOpacity(0.3) : Colors.amber.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.amber.shade800),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Necesitas configurar Firebase para que la sincronización funcione.',
                  style: TextStyle(color: isDark ? Colors.white70 : const Color(0xFF616161), fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

Future<void> _run(BuildContext context, Future<void> Function() action) async {
  try {
    await action();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Operación completada')),
    );
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(e.toString())),
    );
  }
}
