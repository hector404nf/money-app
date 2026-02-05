import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/data_provider.dart';
import '../providers/ui_provider.dart';
import '../utils/constants.dart';
import '../services/notification_service.dart';
import '../services/biometric_service.dart';
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

// Keeps existing SyncScreen for direct navigation if needed, or as a detail view
class SyncScreen extends StatelessWidget {
  const SyncScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
