import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../screens/renewal_flow_screen.dart';

class ExpiringSoonList extends StatelessWidget {
  final List<Map<String, dynamic>> members;
  final VoidCallback? onViewAll;

  const ExpiringSoonList({
    super.key,
    required this.members,
    this.onViewAll,
  });

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(AppTheme.stackMd),
            decoration: const BoxDecoration(
              color: AppTheme.surfaceBright,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppTheme.radiusLg),
              ),
              border: Border(
                bottom: BorderSide(color: AppTheme.outlineVariant, width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Expiring Soon',
                  style: AppTheme.headlineMd,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.tertiaryContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '7 Days',
                    style: AppTheme.labelSm.copyWith(
                      color: AppTheme.tertiary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Member list
          if (members.isEmpty)
            Padding(
              padding: const EdgeInsets.all(AppTheme.stackLg),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 40,
                      color: AppTheme.primary.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No memberships expiring soon',
                      style: AppTheme.bodyMd.copyWith(
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: members.length,
              separatorBuilder: (context, index) => const Divider(
                height: 1,
                indent: 16,
                endIndent: 16,
                color: AppTheme.outlineVariant,
              ),
              itemBuilder: (context, index) {
                final member = members[index];
                final name = member['name'] as String? ?? '';
                final daysLeft = member['daysLeft'] as int? ?? 0;
                final initials = _getInitials(name);

                final memberId = member['memberId'] as String? ?? '';

                return ListTile(
                  onTap: () {
                    if (memberId.isNotEmpty) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RenewalFlowScreen(
                            preSelectedMemberId: memberId,
                          ),
                        ),
                      );
                    }
                  },
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.stackMd,
                    vertical: 4,
                  ),
                  leading: CircleAvatar(
                    radius: 20,
                    backgroundColor: AppTheme.surfaceContainerHigh,
                    child: Text(
                      initials,
                      style: AppTheme.headlineMd.copyWith(fontSize: 14),
                    ),
                  ),
                  title: Text(
                    name,
                    style: AppTheme.bodyMd.copyWith(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    daysLeft == 0
                        ? 'Expires today'
                        : daysLeft == 1
                            ? 'Expires in 1 day'
                            : 'Expires in $daysLeft days',
                    style: AppTheme.labelSm.copyWith(
                      color: daysLeft <= 2 ? AppTheme.error : AppTheme.tertiary,
                    ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(
                      Icons.autorenew,
                      color: AppTheme.primary,
                    ),
                    onPressed: () {
                      if (memberId.isNotEmpty) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RenewalFlowScreen(
                              preSelectedMemberId: memberId,
                            ),
                          ),
                        );
                      }
                    },
                    tooltip: 'Renew membership',
                  ),
                );
              },
            ),
          // View All footer
          if (members.isNotEmpty)
            InkWell(
              onTap: onViewAll,
              child: Container(
                padding: const EdgeInsets.all(AppTheme.stackSm),
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: AppTheme.outlineVariant, width: 1),
                  ),
                ),
                child: Center(
                  child: Text(
                    'View All',
                    style: AppTheme.labelSm.copyWith(color: AppTheme.primary),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
