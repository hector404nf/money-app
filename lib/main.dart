import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'firebase_options.dart';
import 'providers/data_provider.dart';
import 'providers/ui_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/lock_screen.dart';
import 'services/notification_service.dart';
import 'services/ad_service.dart';
import 'utils/constants.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'screens/add_transaction_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_ES', null); // Initialize Spanish locale
  await Hive.initFlutter();
  await NotificationService().init();
  await AdService().init();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(const Duration(seconds: 5));
  } catch (_) {}
  final uiProvider = UiProvider();
  await uiProvider.load();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DataProvider()),
        ChangeNotifierProvider<UiProvider>.value(value: uiProvider),
      ],
      child: const MoneyApp(),
    ),
  );
}

class MoneyApp extends StatefulWidget {
  const MoneyApp({super.key});

  @override
  State<MoneyApp> createState() => _MoneyAppState();
}

class _MoneyAppState extends State<MoneyApp> with WidgetsBindingObserver {
  StreamSubscription? _widgetSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkWidgetLaunch();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _widgetSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkBiometricLock();
    }
  }

  void _checkBiometricLock() {
    // Check if biometric is enabled
    // We use a slight delay to ensure the app is fully resumed and context is valid
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted) return;
      try {
         final uiProvider = Provider.of<UiProvider>(context, listen: false);
         if (uiProvider.biometricEnabled && !LockScreen.isShown) {
           // Check if we are already on LockScreen (optional, but good optimization)
           // For now, we just push it. If user cancels, they can't access app anyway (pop disabled).
          // But wait, if they cancel, we need to handle it. 
          // Our LockScreen has no cancel button.
          // But if they just background app again?
          
          navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (_) => const LockScreen(isResume: true),
            ),
          );
        }
      } catch (e) {
        debugPrint('Error checking biometric lock: $e');
      }
    });
  }

  void _checkWidgetLaunch() {
    try {
      HomeWidget.initiallyLaunchedFromHomeWidget().then(_handleWidgetLaunch).catchError((e) {
        debugPrint('Error getting initial widget launch: $e');
      });
      _widgetSubscription = HomeWidget.widgetClicked.listen(_handleWidgetLaunch);
    } catch (e) {
      debugPrint('Error initializing HomeWidget listener: $e');
    }
  }

  void _handleWidgetLaunch(Uri? uri) async {
    if (uri?.host == 'add_expense') {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        // Retry mechanism to ensure Navigator is ready
        for (int i = 0; i < 10; i++) {
          if (navigatorKey.currentState != null) {
            navigatorKey.currentState?.push(
              MaterialPageRoute(builder: (context) => const AddTransactionScreen()),
            );
            return;
          }
          await Future.delayed(const Duration(milliseconds: 300));
        }
      });
    }
  }

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    final ui = Provider.of<UiProvider>(context);
    final baseTextTheme = GoogleFonts.poppinsTextTheme();

    final lightTheme = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: ui.selectedTheme.color,
        primary: ui.selectedTheme.color,
        surface: AppColors.surface,
      ),
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      textTheme: baseTextTheme.apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: ui.selectedTheme.color,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide.none,
        ),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ui.selectedTheme.color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: ui.selectedTheme.color,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
    );

    final darkTheme = ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        brightness: Brightness.dark,
        seedColor: ui.selectedTheme.color,
        primary: ui.selectedTheme.color,
        surface: AppColors.darkSurface,
      ),
      scaffoldBackgroundColor: AppColors.darkBackground,
      textTheme: baseTextTheme.apply(
        bodyColor: AppColors.darkTextPrimary,
        displayColor: AppColors.darkTextPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkBackground,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide.none,
        ),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ui.selectedTheme.color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: ui.selectedTheme.color,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
    );

    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Ikatu',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ui.themeMode,
      home: const SplashScreen(),
    );
  }
}
