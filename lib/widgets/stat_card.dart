import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final String? subtitle;
  final IconData? subtitleIcon;
  final Color? subtitleColor;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.iconColor = AppTheme.primary,
    Color? iconBgColor,
    this.subtitle,
    this.subtitleIcon,
    this.subtitleColor,
  }) : iconBgColor = iconBgColor ?? const Color(0x3310B981);

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
          // Header: title + icon
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  style: AppTheme.labelSm,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Value
          Text(
            value,
            style: AppTheme.displayStat,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                if (subtitleIcon != null) ...[
                  Icon(
                    subtitleIcon,
                    size: 14,
                    color: subtitleColor ?? AppTheme.primary,
                  ),
                  const SizedBox(width: 4),
                ],
                Expanded(
                  child: Text(
                    subtitle!,
                    style: AppTheme.labelSm.copyWith(
                      color: subtitleColor ?? AppTheme.primary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
