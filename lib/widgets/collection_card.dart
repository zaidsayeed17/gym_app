import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CollectionCard extends StatelessWidget {
  final double amount;
  final double progress;
  final int percentage;

  const CollectionCard({
    super.key,
    required this.amount,
    required this.progress,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.stackLg),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "TODAY'S COLLECTION",
            style: AppTheme.labelSm,
          ),
          const SizedBox(height: 16),
          Text(
            '₹${amount.toStringAsFixed(2)}',
            style: AppTheme.displayStat,
          ),
          const SizedBox(height: 12),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppTheme.surfaceContainerHigh,
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
            ),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '$percentage% of daily goal',
              style: AppTheme.labelSm,
            ),
          ),
        ],
      ),
    );
  }
}
