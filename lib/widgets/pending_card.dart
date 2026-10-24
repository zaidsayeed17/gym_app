import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PendingCard extends StatelessWidget {
  final double amount;
  final VoidCallback? onViewAll;

  const PendingCard({
    super.key,
    required this.amount,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.stackLg),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: AppTheme.cardShadow,
        border: const Border(
          left: BorderSide(
            color: AppTheme.tertiary,
            width: 4,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PENDING PAYMENTS',
            style: AppTheme.labelSm,
          ),
          const SizedBox(height: 16),
          Text(
            '₹${amount.toStringAsFixed(2)}',
            style: AppTheme.displayStat,
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: onViewAll,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'View all pending',
                  style: AppTheme.labelSm.copyWith(
                    color: AppTheme.tertiary,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.arrow_forward,
                  size: 14,
                  color: AppTheme.tertiary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
