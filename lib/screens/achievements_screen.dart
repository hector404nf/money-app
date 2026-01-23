import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/data_provider.dart';
import '../models/achievement.dart';
import '../utils/constants.dart';
import '../utils/icon_helper.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DataProvider>(context);
    final achievements = provider.achievements;
    
    // Sort: Unlocked first, then by date desc, then Locked
    final sortedAchievements = List<Achievement>.from(achievements);
    sortedAchievements.sort((a, b) {
        if (a.isUnlocked && !b.isUnlocked) return -1;
        if (!a.isUnlocked && b.isUnlocked) return 1;
        if (a.isUnlocked && b.isUnlocked) {
            return b.unlockedAt!.compareTo(a.unlockedAt!);
        }
        return 0;
    });

    final unlockedCount = achievements.where((a) => a.isUnlocked).length;
    final totalCount = achievements.length;
    final progress = totalCount > 0 ? unlockedCount / totalCount : 0.0;

    return Scaffold(
      appBar: AppBar(title: const Text('Logros y Medallas')),
      body: Column(
        children: [
            // Header with Progress
            Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
                ),
                child: Column(
                    children: [
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                                Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                        Text(
                                            '$unlockedCount / $totalCount',
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 32,
                                                fontWeight: FontWeight.bold,
                                            ),
                                        ),
                                        const Text(
                                            'Logros Desbloqueados',
                                            style: TextStyle(
                                                color: Colors.white70,
                                                fontSize: 14,
                                            ),
                                        ),
                                    ],
                                ),
                                Icon(Icons.emoji_events, size: 48, color: Colors.white.withOpacity(0.8)),
                            ],
                        ),
                        const SizedBox(height: 16),
                        LinearProgressIndicator(
                            value: progress,
                            backgroundColor: Colors.black12,
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                    ],
                ),
            ),
            
            Expanded(
                child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.80,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                    ),
                    itemCount: sortedAchievements.length,
                    itemBuilder: (context, index) {
                        return _AchievementCard(achievement: sortedAchievements[index]);
                    },
                ),
            ),
        ],
      ),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  final Achievement achievement;

  const _AchievementCard({required this.achievement});

  @override
  Widget build(BuildContext context) {
    final isUnlocked = achievement.isUnlocked;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
        decoration: BoxDecoration(
            color: isDark ? theme.cardTheme.color : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                ),
            ],
            border: isUnlocked ? Border.all(color: AppColors.primary.withOpacity(0.3), width: 2) : null,
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
                Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        color: isUnlocked ? AppColors.primary.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                        shape: BoxShape.circle,
                    ),
                    child: Icon(
                        IconHelper.getIconByName(achievement.iconName),
                        size: 32,
                        color: isUnlocked ? AppColors.primary : Colors.grey,
                    ),
                ),
                const SizedBox(height: 12),
                Text(
                    achievement.title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isUnlocked ? (isDark ? Colors.white : Colors.black87) : Colors.grey,
                    ),
                ),
                const SizedBox(height: 4),
                Text(
                    achievement.description,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 12,
                        color: isUnlocked ? (isDark ? Colors.white70 : Colors.black54) : Colors.grey,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                ),
                if (isUnlocked && achievement.unlockedAt != null) ...[
                    const Spacer(),
                    Text(
                        DateFormat('dd/MM/yyyy').format(achievement.unlockedAt!),
                        style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                        ),
                    ),
                ],
            ],
        ),
    );
  }
}
