import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class QuickActions extends StatelessWidget {
  final VoidCallback? onAddMember;
  final VoidCallback? onRenew;

  const QuickActions({
    super.key,
    this.onAddMember,
    this.onRenew,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: onAddMember,
            icon: const Icon(Icons.person_add, size: 18),
            label: const Text('Add Member'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: AppTheme.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              elevation: 1,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onRenew,
            icon: const Icon(Icons.autorenew, size: 18),
            label: const Text('Renew'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.onSurface,
              side: const BorderSide(color: AppTheme.outline),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
