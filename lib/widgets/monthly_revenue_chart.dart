import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class MonthlyRevenueChart extends StatelessWidget {
  final Map<String, double> monthlyData;

  const MonthlyRevenueChart({
    super.key,
    required this.monthlyData,
  });

  String _formatAmount(double amount) {
    if (amount >= 100000) {
      return '₹${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount >= 1000) {
      return '₹${(amount / 1000).toStringAsFixed(1)}k';
    }
    return '₹${amount.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    if (monthlyData.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.bar_chart, color: AppTheme.primary, size: 20),
                const SizedBox(width: 8),
                Text('Monthly Revenue Breakdown', style: AppTheme.headlineMd),
              ],
            ),
            const SizedBox(height: 32),
            Text(
              'No collection data in selected date range.',
              style: AppTheme.bodyMd.copyWith(color: AppTheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
          ],
        ),
      );
    }

    final maxVal = monthlyData.values.reduce(max);
    final chartHeight = 140.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bar_chart, color: AppTheme.primary, size: 20),
              const SizedBox(width: 8),
              Text('Monthly Revenue Breakdown', style: AppTheme.headlineMd),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: chartHeight + 40,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: monthlyData.entries.map((entry) {
                  final amount = entry.value;
                  final heightRatio = maxVal > 0 ? (amount / maxVal) : 0.0;
                  final barHeight = max(12.0, heightRatio * chartHeight);

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Value label above bar
                        Text(
                          _formatAmount(amount),
                          style: AppTheme.labelSm.copyWith(
                            color: AppTheme.primary,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Gradient Bar Container
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 500),
                          width: 32,
                          height: barHeight,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF006C49),
                                Color(0xFF10B981),
                              ],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            ),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(6),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Month label
                        Text(
                          entry.key,
                          style: AppTheme.labelSm.copyWith(
                            color: AppTheme.onSurfaceVariant,
                            fontSize: 10,
                            letterSpacing: 0,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
