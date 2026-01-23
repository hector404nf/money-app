import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/challenge.dart';
import '../providers/data_provider.dart';
import '../utils/constants.dart';

class ChallengesScreen extends StatelessWidget {
  const ChallengesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DataProvider>(context);
    final challenges = provider.challenges;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Retos de Ahorro'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        itemCount: challenges.length,
        itemBuilder: (context, index) {
          final challenge = challenges[index];
          return _ChallengeCard(challenge: challenge);
        },
      ),
    );
  }
}

class _ChallengeCard extends StatelessWidget {
  final Challenge challenge;

  const _ChallengeCard({required this.challenge});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DataProvider>(context, listen: false);
    
    Color cardColor = Colors.white;
    if (challenge.isActive) {
      cardColor = AppColors.primary.withOpacity(0.1);
    } else if (challenge.isCompleted) {
      cardColor = Colors.green.withOpacity(0.1);
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getIconForType(challenge.type),
                  color: AppColors.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    challenge.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (challenge.isCompleted)
                  const Chip(
                    label: Text('Completado', style: TextStyle(color: Colors.white)),
                    backgroundColor: Colors.green,
                  )
                else if (challenge.isActive)
                  const Chip(
                    label: Text('En Curso', style: TextStyle(color: Colors.white)),
                    backgroundColor: AppColors.primary,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(challenge.description),
            const SizedBox(height: 8),
            Text(
              'Duración: ${challenge.durationDays} días',
              style: TextStyle(color: Colors.grey[600], fontStyle: FontStyle.italic),
            ),
            if (challenge.isActive && challenge.startDate != null) ...[
               const SizedBox(height: 8),
               Text(
                 'Termina: ${_formatDate(challenge.startDate!.add(Duration(days: challenge.durationDays)))}',
                 style: const TextStyle(fontWeight: FontWeight.bold),
               ),
            ],
            const SizedBox(height: 16),
            if (!challenge.isActive && !challenge.isCompleted)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    provider.joinChallenge(challenge.id);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Aceptar Reto'),
                ),
              ),
            if (challenge.isActive)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    // Confirm dialog?
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('¿Abandonar Reto?'),
                        content: const Text('Si abandonas ahora, perderás el progreso.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Cancelar'),
                          ),
                          TextButton(
                            onPressed: () {
                              provider.abandonChallenge(challenge.id);
                              Navigator.pop(ctx);
                            },
                            child: const Text('Abandonar'),
                          ),
                        ],
                      ),
                    );
                  },
                  child: const Text('Abandonar'),
                ),
              ),
             if (challenge.isCompleted)
               SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                     provider.joinChallenge(challenge.id); // Retry/Restart?
                  },
                  child: const Text('Repetir Reto'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'no_small_expense':
        return Icons.money_off;
      case 'save_target':
        return Icons.savings;
      case 'no_category_expense':
        return Icons.restaurant_menu; // Assuming food for now
      default:
        return Icons.star;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
