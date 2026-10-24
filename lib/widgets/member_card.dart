import 'dart:io';
import 'package:flutter/material.dart';
import '../models/joined_member.dart';
import '../theme/app_theme.dart';

class MemberCard extends StatelessWidget {
  final JoinedMember joinedMember;
  final VoidCallback onTap;

  const MemberCard({
    super.key,
    required this.joinedMember,
    required this.onTap,
  });

  Widget _buildAvatar() {
    final photoPath = joinedMember.member.photoPath;
    if (photoPath.isNotEmpty && File(photoPath).existsSync()) {
      return CircleAvatar(
        radius: 24,
        backgroundImage: FileImage(File(photoPath)),
      );
    }

    return CircleAvatar(
      radius: 24,
      backgroundColor: AppTheme.surfaceContainerHigh,
      child: Text(
        joinedMember.member.initials,
        style: AppTheme.headlineMd.copyWith(
          fontSize: 16,
          color: AppTheme.onSurface,
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    Color bg;
    Color text;
    String label = joinedMember.status;

    if (joinedMember.isActive) {
      bg = AppTheme.statusActiveBg;
      text = AppTheme.statusActiveText;
    } else if (joinedMember.isExpiringSoon) {
      bg = AppTheme.statusExpiringBg;
      text = AppTheme.statusExpiring;
    } else {
      bg = AppTheme.statusExpiredBg;
      text = AppTheme.statusExpired;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: text,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTheme.labelSm.copyWith(
              color: text,
              fontWeight: FontWeight.w600,
              fontSize: 11,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: AppTheme.cardShadow,
        border: Border.all(
          color: AppTheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.stackMd),
            child: Row(
              children: [
                _buildAvatar(),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              joinedMember.member.name,
                              style: AppTheme.bodyLg.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppTheme.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildStatusBadge(),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ID: ${joinedMember.member.memberId} • ${joinedMember.member.mobileNumber}',
                        style: AppTheme.bodyMd.copyWith(
                          color: AppTheme.onSurfaceVariant,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.card_membership,
                            size: 14,
                            color: AppTheme.primary.withValues(alpha: 0.8),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            joinedMember.planName,
                            style: AppTheme.labelSm.copyWith(
                              color: AppTheme.primary,
                              letterSpacing: 0,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (joinedMember.remainingAmount > 0) ...[
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.tertiaryContainer.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Due: ₹${joinedMember.remainingAmount.toStringAsFixed(0)}',
                                style: AppTheme.labelSm.copyWith(
                                  color: AppTheme.tertiary,
                                  fontSize: 11,
                                  letterSpacing: 0,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right,
                  color: AppTheme.outline,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
