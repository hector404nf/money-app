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

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoFadeAnimation;
  late Animation<double> _textFadeAnimation;
  late Animation<Offset> _textSlideAnimation;
  late Animation<double> _sloganFadeAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    // Logo: Scale up slightly and fade in
    _logoScaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );
    _logoFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );

    // Text: Slide up and fade in
    _textSlideAnimation = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.8, curve: Curves.easeOutCubic),
      ),
    );
    _textFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.6, curve: Curves.easeIn),
      ),
    );

    // Slogan: Fade in last
    _sloganFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.6, 1.0, curve: Curves.easeIn),
      ),
    );

    _controller.forward();

    // Navigate after animation + buffer
    Timer(const Duration(milliseconds: 3500), _navigateToNextScreen);
  }

  void _navigateToNextScreen() {
    if (!mounted) return;
    final uiProvider = context.read<UiProvider>();
    
    // Smooth transition
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => 
          uiProvider.seenOnboarding ? const HomeScreen() : const OnboardingScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1A1D21), // Slightly lighter than pure black
              Color(0xFF121418), // Dark background
              Color(0xFF0D1012), // Deep dark
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated Logo
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Opacity(
                    opacity: _logoFadeAnimation.value,
                    child: Transform.scale(
                      scale: _logoScaleAnimation.value,
                      child: Container(
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.2),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                          ],
                          shape: BoxShape.circle,
                        ),
                        child: Image.asset(
                          'assets/images/Gemini_Generated_Image_27gsm627gsm627gs.png',
                          width: 160,
                          height: 160,
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),
              
              // Animated App Name
              SlideTransition(
                position: _textSlideAnimation,
                child: FadeTransition(
                  opacity: _textFadeAnimation,
                  child: Column(
                    children: [
                      Text(
                        'Ikatu',
                        style: GoogleFonts.montserrat(
                          fontSize: 52,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 2.0,
                          shadows: [
                            Shadow(
                              color: AppColors.primary.withOpacity(0.5),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Animated Slogan
                      FadeTransition(
                        opacity: _sloganFadeAnimation,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: Colors.white.withOpacity(0.05),
                          ),
                          child: Text(
                            'Tu camino al control financiero',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.lato(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: AppColors.secondary,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 60),
              
              // Custom Loading Indicator (Subtle)
              FadeTransition(
                opacity: _sloganFadeAnimation,
                child: const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
