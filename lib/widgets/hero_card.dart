import 'package:flutter/material.dart';
import '../utils/constants.dart';

class HeroCard extends StatelessWidget {
  final double amount;
  final VoidCallback? onTap;

  const HeroCard({
    super.key,
    required this.amount,
    this.onTap,
  });

  String _formatCurrency(double amount) {
    return '₲ ${amount.abs().toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
  }

  @override
  Widget build(BuildContext context) {
    final isNegative = amount < 0;
    
    return Container(
      width: double.infinity,
      height: 220, // Altura fija para asegurar espacio para el decorado
      decoration: BoxDecoration(
        gradient: isNegative ? AppGradients.error : AppGradients.primary,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (isNegative ? AppColors.expense : AppColors.primary).withOpacity(0.15),
            offset: const Offset(0, 4),
            blurRadius: 20,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // Decorative Icon
              Positioned(
                right: -20,
                top: -20,
                child: Transform.rotate(
                  angle: -0.2, // ~12 grados
                  child: Icon(
                    Icons.account_balance_wallet,
                    size: 180,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),
              
              // Content
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Label superior
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isNegative ? Icons.trending_down : Icons.trending_up, 
                            color: Colors.white, 
                            size: 16
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isNegative ? 'Te faltaría' : 'Te sobraría',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (onTap != null) ...[
                            const SizedBox(width: 4),
                            const Icon(Icons.chevron_right, color: Colors.white70, size: 16),
                          ],
                        ],
                      ),
                    ),
                    
                    // Monto Principal
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _formatCurrency(amount),
                          style: Theme.of(context).textTheme.displayMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -1,
                          ),
                        ),
                      ),
                    ),
                    
                    // Footer
                    Column(
                      children: [
                        Divider(color: Colors.white.withOpacity(0.2), height: 12),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Saldo proyectado del mes (incluye pendientes)',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.white.withOpacity(0.8),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
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
