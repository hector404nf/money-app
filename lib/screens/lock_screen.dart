import 'package:flutter/material.dart';
import '../services/biometric_service.dart';
import 'home_screen.dart';
import '../utils/constants.dart';

class LockScreen extends StatefulWidget {
  final bool isResume;
  static bool isShown = false;

  const LockScreen({super.key, this.isResume = false});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  bool _isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    LockScreen.isShown = true;
    // Delay slightly to ensure UI is ready
    Future.delayed(const Duration(milliseconds: 300), _authenticate);
  }

  @override
  void dispose() {
    LockScreen.isShown = false;
    super.dispose();
  }

  Future<void> _authenticate() async {
    if (_isAuthenticating) return;
    setState(() => _isAuthenticating = true);

    try {
      final authenticated = await BiometricService.authenticate();
      if (authenticated && mounted) {
        if (widget.isResume) {
          Navigator.of(context).pop();
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isAuthenticating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.lock_outline_rounded, 
                size: 80, 
                color: AppColors.primary
              ),
              const SizedBox(height: 24),
              const Text(
                'Money App Bloqueado',
                style: TextStyle(
                  fontSize: 24, 
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Autentícate para continuar',
                style: TextStyle(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 48),
              ElevatedButton.icon(
                onPressed: _authenticate,
                icon: const Icon(Icons.fingerprint),
                label: const Text('Desbloquear'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
