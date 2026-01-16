import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../providers/ui_provider.dart';
import '../utils/constants.dart';
import 'home_screen.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Navigate to home or onboarding after 3 seconds
    Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      final uiProvider = context.read<UiProvider>();
      if (uiProvider.seenOnboarding) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const OnboardingScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121418), // Dark background matching native splash
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Image.asset(
              'assets/images/Gemini_Generated_Image_27gsm627gsm627gs.png',
              width: 150,
              height: 150,
            ),
            const SizedBox(height: 24),
            // App Name
            Text(
              'Ikatu',
              style: GoogleFonts.montserrat(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            // Motivational Phrase
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Text(
                'Tu camino al control financiero',
                textAlign: TextAlign.center,
                style: GoogleFonts.lato(
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                  color: AppColors.secondary,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 48),
            // Loading indicator (optional, keeps it alive)
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.secondary),
            ),
          ],
        ),
      ),
    );
  }
}
