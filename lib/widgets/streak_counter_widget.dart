import 'package:flutter/material.dart';
import '../utils/constants.dart';

/// Widget that displays the current streak of consecutive days with transactions
class StreakCounterWidget extends StatelessWidget {
  final int streakDays;
  final VoidCallback? onTap;

  const StreakCounterWidget({
    super.key,
    required this.streakDays,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasStreak = streakDays > 0;
    final theme = Theme.of(context);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: hasStreak
              ? LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.secondary,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: hasStreak ? null : theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: hasStreak
                  ? AppColors.secondary.withOpacity(0.3)
                  : Colors.black.withOpacity(0.1),
              blurRadius: hasStreak ? 12 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Fire icon with animation
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.8, end: 1.0),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeInOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: child,
                );
              },
              child: Text(
                hasStreak ? '🔥' : '📊',
                style: const TextStyle(fontSize: 32),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  hasStreak ? 'Racha Activa' : 'Sin Racha',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: hasStreak ? Colors.white : theme.textTheme.bodySmall?.color,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$streakDays',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: hasStreak ? Colors.white : theme.textTheme.titleLarge?.color,
                        height: 1,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        streakDays == 1 ? 'día' : 'días',
                        style: TextStyle(
                          fontSize: 14,
                          color: hasStreak ? Colors.white70 : theme.textTheme.bodyMedium?.color,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
