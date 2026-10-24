import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_data_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/stat_card.dart';
import '../widgets/collection_card.dart';
import '../widgets/pending_card.dart';
import '../widgets/expiring_soon_list.dart';
import '../widgets/empty_state.dart';
import 'add_edit_member_screen.dart';
import 'payments_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppDataProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(
              color: AppTheme.primary,
            ),
          );
        }

        final stats = provider.dashboardStats;
        final totalMembers = stats['totalMembers'] as int? ?? 0;

        // Show empty state if no members at all
        if (totalMembers == 0) {
          return RefreshIndicator(
            onRefresh: provider.refreshDashboard,
            color: AppTheme.primary,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  EmptyState(
                    title: 'No members yet',
                    subtitle: 'Add your first member to get started tracking memberships, payments, and more.',
                    icon: Icons.fitness_center,
                    actionLabel: 'Add Member',
                    onAction: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AddEditMemberScreen(),
                        ),
                      );
                      provider.refreshDashboard();
                    },
                  ),
                ],
              ),
            ),
          );
        }

        final activeMembers = stats['activeMembers'] as int? ?? 0;
        final expiringSoon = stats['expiringSoon'] as int? ?? 0;
        final expiredMembers = stats['expiredMembers'] as int? ?? 0;
        final todaysCollection = (stats['todaysCollection'] as num?)?.toDouble() ?? 0.0;
        final pendingPayments = (stats['pendingPayments'] as num?)?.toDouble() ?? 0.0;
        final newThisMonth = stats['newThisMonth'] as int? ?? 0;

        return RefreshIndicator(
          onRefresh: provider.refreshDashboard,
          color: AppTheme.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Stats Grid — 2 columns
                Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        title: 'Total Members',
                        value: totalMembers.toString(),
                        icon: Icons.groups,
                        iconColor: AppTheme.primary,
                        iconBgColor: AppTheme.primaryContainer.withValues(alpha: 0.2),
                        subtitle: '+$newThisMonth this month',
                        subtitleIcon: Icons.trending_up,
                        subtitleColor: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StatCard(
                        title: 'Active Members',
                        value: activeMembers.toString(),
                        icon: Icons.directions_run,
                        iconColor: AppTheme.primary,
                        iconBgColor: AppTheme.primaryContainer.withValues(alpha: 0.2),
                        subtitle: totalMembers > 0
                            ? '${((activeMembers / totalMembers) * 100).round()}% Active'
                            : '0% Active',
                        subtitleIcon: Icons.check_circle,
                        subtitleColor: AppTheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        title: 'Expiring Soon',
                        value: expiringSoon.toString(),
                        icon: Icons.warning_amber_rounded,
                        iconColor: AppTheme.tertiary,
                        iconBgColor: AppTheme.tertiaryContainer.withValues(alpha: 0.2),
                        subtitle: 'Next 7 days',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StatCard(
                        title: 'Expired Members',
                        value: expiredMembers.toString(),
                        icon: Icons.person_off,
                        iconColor: AppTheme.error,
                        iconBgColor: AppTheme.errorContainer.withValues(alpha: 0.5),
                        subtitle: 'Action required',
                        subtitleColor: AppTheme.error,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Today's Collection
                CollectionCard(
                  amount: todaysCollection,
                  progress: provider.collectionProgress,
                  percentage: provider.collectionPercentage,
                ),
                const SizedBox(height: 16),

                // Pending Payments
                PendingCard(
                  amount: pendingPayments,
                  onViewAll: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PaymentsScreen()),
                    );
                  },
                ),
                const SizedBox(height: 20),

                // Expiring Soon List
                ExpiringSoonList(
                  members: provider.expiringSoonMembers,
                  onViewAll: () {
                    // TODO: Navigate to Members with expiring filter
                  },
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }
}
