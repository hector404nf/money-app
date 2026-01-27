import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'dashboard_tab.dart';
import 'accounts_tab.dart';
import 'transactions_tab.dart';
import 'add_transaction_screen.dart';
import 'ai_input_screen.dart';
import 'sync_screen.dart';
import '../providers/data_provider.dart';
import '../utils/constants.dart';
import '../services/ad_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  StreamSubscription? _achievementSubscription;

  final List<Widget> _tabs = const [
    DashboardTab(),
    AccountsTab(),
    TransactionsTab(),
    SettingsTab(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<DataProvider>(context, listen: false);
      _achievementSubscription = provider.onAchievementUnlocked.listen((achievement) {
        if (mounted) {
          // ScaffoldMessenger.of(context).showSnackBar(
          //   SnackBar(
          //     content: Row(
          //       children: [
          //         const Icon(Icons.emoji_events, color: Colors.white),
          //         const SizedBox(width: 12),
          //         Expanded(
          //           child: Column(
          //             crossAxisAlignment: CrossAxisAlignment.start,
          //             mainAxisSize: MainAxisSize.min,
          //             children: [
          //               const Text('¡Logro Desbloqueado!',
          //                   style: TextStyle(fontWeight: FontWeight.bold)),
          //               Text(achievement.title),
          //             ],
          //           ),
          //         ),
          //       ],
          //     ),
          //     backgroundColor: AppColors.primary,
          //     duration: const Duration(seconds: 4),
          //     action: SnackBarAction(
          //       label: 'VER',
          //       textColor: Colors.white,
          //       onPressed: () {
          //         Navigator.push(
          //           context,
          //           MaterialPageRoute(
          //               builder: (_) => const AchievementsScreen()),
          //         );
          //       },
          //     ),
          //   ),
          // );
        }
      });
    });
  }

  @override
  void dispose() {
    _achievementSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      // backgroundColor handled by theme
      body: Column(
        children: [
          Expanded(child: _tabs[_currentIndex]),
          if (_currentIndex == 0 || _currentIndex == 2) // Show ads only on Dashboard and Transactions
            SafeArea(
              top: false,
              child: AdService().getBannerWidget(),
            ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        color: theme.cardTheme.color,
        elevation: 10,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: _buildNavItem(0, Icons.home_outlined, Icons.home, 'Inicio')),
              Expanded(child: _buildNavItem(2, Icons.list_alt_outlined, Icons.list_alt, 'Movimientos')),
              const SizedBox(width: 48), // Espacio para el FAB
              Expanded(child: _buildNavItem(1, Icons.account_balance_wallet_outlined, Icons.account_balance_wallet, 'Cuentas')),
              Expanded(child: _buildNavItem(3, Icons.settings_outlined, Icons.settings, 'Ajustes')),
            ],
          ),
        ),
      ),
      floatingActionButton: SizedBox(
        width: 64,
        height: 64,
        child: Tooltip(
          message: 'Toca para manual, mantén para IA',
          child: Material(
            color: AppColors.secondary,
            shape: const CircleBorder(),
            elevation: 4,
            child: InkWell(
              key: const Key('fab_add'),
              customBorder: const CircleBorder(),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddTransactionScreen()),
                );
              },
              onLongPress: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AiInputScreen()),
                );
              },
              child: const Center(
                child: Icon(Icons.add, color: Colors.white, size: 32),
              ),
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildNavItem(int index, IconData icon, IconData activeIcon, String label) {
    final isSelected = _currentIndex == index;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final selectedColor = AppColors.secondary;
    final unselectedColor = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;

    return InkWell(
      onTap: () {
        setState(() => _currentIndex = index);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSelected ? activeIcon : icon,
            color: isSelected ? selectedColor : unselectedColor,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? selectedColor : unselectedColor,
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
