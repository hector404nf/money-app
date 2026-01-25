import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/ui_provider.dart';
import '../utils/constants.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPageData> _pages = [
    OnboardingPageData(
      title: 'Control Total',
      description: 'Gestiona tus ingresos y gastos de forma sencilla e intuitiva. Tu dinero, bajo control.',
      icon: Icons.account_balance_wallet,
    ),
    OnboardingPageData(
      title: 'Metas de Ahorro',
      description: 'Define objetivos financieros y alcanza tus sueños paso a paso. Nosotros te ayudamos a lograrlos.',
      icon: Icons.savings,
    ),
    OnboardingPageData(
      title: 'Automatización',
      description: 'Olvídate de registrar tus pagos fijos. Configura transacciones recurrentes y relájate.',
      icon: Icons.update,
    ),
    OnboardingPageData(
      title: 'Privacidad',
      description: 'Tus datos son solo tuyos. Funcionamos 100% offline para garantizar tu seguridad.',
      icon: Icons.security,
    ),
  ];

  void _onNext() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _finishOnboarding();
    }
  }
  
  void _onSkip() {
    _finishOnboarding();
  }

  void _finishOnboarding() {
    context.read<UiProvider>().completeOnboarding();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
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
              Color(0xFF1A1D21),
              Color(0xFF121418),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header with Skip
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Only show Skip if not on the last page
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 300),
                      opacity: _currentPage < _pages.length - 1 ? 1.0 : 0.0,
                      child: TextButton(
                        onPressed: _currentPage < _pages.length - 1 ? _onSkip : null,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white70,
                        ),
                        child: Text(
                          'Saltar',
                          style: GoogleFonts.lato(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // PageView
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemCount: _pages.length,
                  itemBuilder: (context, index) {
                    return _OnboardingPage(data: _pages[index]);
                  },
                ),
              ),
              
              // Bottom Controls
              Container(
                padding: const EdgeInsets.all(32.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Indicators
                    Row(
                      children: List.generate(
                        _pages.length,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.only(right: 8),
                          height: 8,
                          width: _currentPage == index ? 32 : 8,
                          decoration: BoxDecoration(
                            color: _currentPage == index
                                ? AppColors.secondary
                                : Colors.white24,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                    
                    // Next/Finish Button
                    FloatingActionButton(
                      onPressed: _onNext,
                      backgroundColor: AppColors.secondary,
                      elevation: 0,
                      child: Icon(
                        _currentPage == _pages.length - 1
                            ? Icons.check
                            : Icons.arrow_forward,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OnboardingPageData {
  final String title;
  final String description;
  final IconData icon;

  OnboardingPageData({
    required this.title,
    required this.description,
    required this.icon,
  });
}

class _OnboardingPage extends StatelessWidget {
  final OnboardingPageData data;

  const _OnboardingPage({required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon Container with Glow
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary.withOpacity(0.3),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.2),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Icon(
              data.icon,
              size: 80,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(height: 60),
          
          // Title
          Text(
            data.title,
            style: GoogleFonts.montserrat(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          
          // Description
          Text(
            data.description,
            style: GoogleFonts.lato(
              fontSize: 16,
              color: Colors.white70,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
