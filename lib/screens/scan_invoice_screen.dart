import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:money_app/services/ocr_service.dart';
import 'package:money_app/screens/add_transaction_screen.dart';
import 'package:money_app/utils/constants.dart';
import 'package:money_app/providers/ui_provider.dart';
import 'package:provider/provider.dart';

class ScanInvoiceScreen extends StatefulWidget {
  const ScanInvoiceScreen({super.key});

  @override
  State<ScanInvoiceScreen> createState() => _ScanInvoiceScreenState();
}

class _ScanInvoiceScreenState extends State<ScanInvoiceScreen> {
  final _picker = ImagePicker();
  final _ocrService = OcrService();
  bool _isProcessing = false;
  String? _statusMessage;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(source: source);
      if (pickedFile == null) return;

      setState(() {
        _isProcessing = true;
        _statusMessage = 'Procesando imagen...';
      });

      // Process OCR
      final result = await _ocrService.processImage(pickedFile.path);

      if (!mounted) return;

      // Return results
      Navigator.pop(context, result);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _statusMessage = 'Error: $e';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al procesar: $e')),
      );
    }
  }

  @override
  void dispose() {
    _ocrService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ui = Provider.of<UiProvider>(context);
    final themeColor = ui.selectedTheme.color;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Escanear Factura'),
        backgroundColor: themeColor,
      ),
      body: Center(
        child: _isProcessing
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(_statusMessage ?? 'Procesando...'),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.document_scanner_outlined, size: 80, color: themeColor),
                  const SizedBox(height: 24),
                  const Text(
                    'Selecciona una opción para escanear',
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: 200,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Cámara'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: () => _pickImage(ImageSource.camera),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: 200,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Galería'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: themeColor,
                        side: BorderSide(color: themeColor),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: () => _pickImage(ImageSource.gallery),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
