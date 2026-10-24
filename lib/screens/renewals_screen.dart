import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'renewal_flow_screen.dart';

class RenewalsScreen extends StatelessWidget {
  const RenewalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Membership Renewals',
          style: AppTheme.headlineLg.copyWith(color: AppTheme.onSurface),
        ),
        backgroundColor: AppTheme.surface,
      ),
      backgroundColor: AppTheme.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.primaryContainer.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.autorenew,
                  size: 56,
                  color: AppTheme.primary.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Membership Renewal Flow',
                style: AppTheme.headlineMd,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Renew expiring or expired member subscriptions, extend expiry dates, and record renewal payments.',
                style: AppTheme.bodyMd.copyWith(color: AppTheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const RenewalFlowScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.autorenew),
                label: const Text('Start Renewal Flow'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: AppTheme.onPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
