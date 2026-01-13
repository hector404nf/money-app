import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:ota_update/ota_update.dart';
import 'package:flutter/material.dart';

class UpdateService {
  // TODO: Reemplaza esto con tu URL real donde alojarás el archivo JSON
  // Ejemplo de JSON:
  // {
  //   "version": "1.0.1",
  //   "url": "https://tu-sitio.com/app-release.apk",
  //   "changelog": "Corrección de errores y mejoras de rendimiento"
  // }
  // TODO: CAMBIA "TU_USUARIO" POR TU NOMBRE DE USUARIO DE GITHUB
  static const String _versionUrl = 'https://raw.githubusercontent.com/TU_USUARIO/money_app/main/version.json';

  Future<void> checkForUpdates(BuildContext context) async {
    try {
      // 1. Obtener versión actual de la app
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      String currentVersion = packageInfo.version;
      
      debugPrint('Versión actual: $currentVersion');

      // 2. Consultar versión remota
      // Nota: Si la URL no existe, esto fallará silenciosamente en el catch
      final response = await http.get(Uri.parse(_versionUrl));
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        String remoteVersion = data['version'];
        String apkUrl = data['url'];
        String changelog = data['changelog'] ?? 'Nueva actualización disponible';

        debugPrint('Versión remota: $remoteVersion');

        // 3. Comparar versiones
        if (_isUpdateAvailable(currentVersion, remoteVersion)) {
          if (context.mounted) {
            _showUpdateDialog(context, remoteVersion, changelog, apkUrl);
          }
        }
      }
    } catch (e) {
      debugPrint('Error verificando actualizaciones: $e');
    }
  }

  bool _isUpdateAvailable(String current, String remote) {
    // Comparación simple de versiones (semver simplificado)
    List<int> c = current.split('.').map(int.parse).toList();
    List<int> r = remote.split('.').map(int.parse).toList();
    
    for (int i = 0; i < c.length && i < r.length; i++) {
      if (r[i] > c[i]) return true;
      if (r[i] < c[i]) return false;
    }
    return false;
  }

  void _showUpdateDialog(BuildContext context, String version, String changelog, String url) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Nueva versión disponible: $version'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Se recomienda actualizar para obtener las últimas mejoras.'),
            const SizedBox(height: 10),
            const Text('Novedades:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(changelog),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Más tarde'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _startUpdate(context, url);
            },
            child: const Text('Actualizar ahora'),
          ),
        ],
      ),
    );
  }

  Future<void> _startUpdate(BuildContext context, String url) async {
    try {
      // Muestra un indicador de progreso simple (o usa un SnackBar)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Descargando actualización... Por favor espera.'),
          duration: Duration(seconds: 2),
        ),
      );

      // Iniciar descarga e instalación OTA
      // android.os.FileUriExposedException fix: Asegúrate de configurar el provider en AndroidManifest si es necesario,
      // pero ota_update generalmente lo maneja internamente.
      OtaUpdate().execute(url, destinationFilename: 'money_app_update.apk').listen(
        (OtaEvent event) {
          debugPrint('OTA Status: ${event.status}, Value: ${event.value}');
          if (event.status == OtaStatus.DOWNLOADING) {
             // Podrías actualizar una barra de progreso aquí si tuvieras un diálogo con estado
          } else if (event.status == OtaStatus.INSTALLING) {
             debugPrint('Instalando actualización...');
          }
        },
      );
    } catch (e) {
      debugPrint('Error en actualización OTA: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar: $e')),
        );
      }
    }
  }
}
