import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/joined_member.dart';
import '../models/payment.dart';
import '../providers/app_data_provider.dart';
import '../services/excel_service.dart';
import '../theme/app_theme.dart';
import 'add_edit_member_screen.dart';
import 'renewal_flow_screen.dart';
import 'add_payment_screen.dart';

class MemberProfileScreen extends StatefulWidget {
  final String memberId;

  const MemberProfileScreen({
    super.key,
    required this.memberId,
  });

  @override
  State<MemberProfileScreen> createState() => _MemberProfileScreenState();
}

class _MemberProfileScreenState extends State<MemberProfileScreen> {
  late String _currentMemberId;
  bool _isLoading = true;
  JoinedMember? _joinedMember;
  List<Payment> _payments = [];

  @override
  void initState() {
    super.initState();
    _currentMemberId = widget.memberId;
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    final data = await ExcelService().getMemberProfileDetails(_currentMemberId);
    if (mounted) {
      if (data != null) {
        setState(() {
          _joinedMember = data['joinedMember'] as JoinedMember;
          _payments = data['payments'] as List<Payment>;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final provider = context.read<AppDataProvider>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Member?'),
        content: Text(
          'Are you sure you want to delete ${_joinedMember?.member.name ?? 'this member'}?\n\n'
          'This will permanently remove their member record, membership history, and all payment records.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: AppTheme.onError,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await provider.deleteMember(widget.memberId);

      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Member deleted successfully.'),
            backgroundColor: AppTheme.primaryContainer,
          ),
        );
        navigator.pop(); // Go back to list
      }
    }
  }

  Widget _buildAvatar() {
    final photoPath = _joinedMember?.member.photoPath ?? '';
    if (photoPath.isNotEmpty && File(photoPath).existsSync()) {
      return CircleAvatar(
        radius: 40,
        backgroundImage: FileImage(File(photoPath)),
      );
    }
    return CircleAvatar(
      radius: 40,
      backgroundColor: AppTheme.surfaceContainerHigh,
      child: Text(
        _joinedMember?.member.initials ?? '?',
        style: AppTheme.displayStat.copyWith(
          fontSize: 28,
          color: AppTheme.onSurface,
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    final status = _joinedMember?.status ?? 'Active';
    Color bg = AppTheme.statusActiveBg;
    Color text = AppTheme.statusActiveText;

    if (status == 'Expiring Soon') {
      bg = AppTheme.statusExpiringBg;
      text = AppTheme.statusExpiring;
    } else if (status == 'Expired') {
      bg = AppTheme.statusExpiredBg;
      text = AppTheme.statusExpired;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
      ),
      child: Text(
        status,
        style: AppTheme.labelSm.copyWith(
          color: text,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy');

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          _joinedMember?.member.name ?? 'Member Profile',
          style: AppTheme.headlineMd.copyWith(color: AppTheme.onSurface),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: AppTheme.primary),
            onPressed: _joinedMember == null
                ? null
                : () async {
                    final updatedId = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddEditMemberScreen(
                          memberId: _currentMemberId,
                        ),
                      ),
                    );
                    if (updatedId is String && updatedId.isNotEmpty) {
                      _currentMemberId = updatedId;
                    }
                    _loadProfile();
                  },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppTheme.error),
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : _joinedMember == null
              ? const Center(child: Text('Member not found.'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Header Card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                          boxShadow: AppTheme.cardShadow,
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                _buildAvatar(),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _joinedMember!.member.name,
                                        style: AppTheme.headlineLg,
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          _buildStatusBadge(),
                                          const SizedBox(width: 8),
                                          Text(
                                            'ID: ${_joinedMember!.member.memberId}',
                                            style: AppTheme.labelSm.copyWith(
                                              color: AppTheme.onSurfaceVariant,
                                              letterSpacing: 0,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Actions Row
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () async {
                                      final updatedId = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => AddEditMemberScreen(
                                            memberId: _currentMemberId,
                                          ),
                                        ),
                                      );
                                      if (updatedId is String && updatedId.isNotEmpty) {
                                        _currentMemberId = updatedId;
                                      }
                                      _loadProfile();
                                    },
                                    icon: const Icon(Icons.edit, size: 16),
                                    label: const Text('Edit'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.surfaceContainerLow,
                                      foregroundColor: AppTheme.onSurface,
                                      elevation: 0,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => RenewalFlowScreen(
                                            preSelectedMemberId: _currentMemberId,
                                          ),
                                        ),
                                      );
                                      _loadProfile();
                                    },
                                    icon: const Icon(Icons.autorenew, size: 16),
                                    label: const Text('Renew'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primary,
                                      foregroundColor: AppTheme.onPrimary,
                                      elevation: 1,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Personal Info Card
                      Container(
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
                                const Icon(Icons.person, color: AppTheme.primary, size: 20),
                                const SizedBox(width: 8),
                                Text('Personal Info', style: AppTheme.headlineMd),
                              ],
                            ),
                            const Divider(height: 24),
                            _buildInfoRow('Mobile Phone', _joinedMember!.member.mobileNumber),
                            const SizedBox(height: 12),
                            _buildInfoRow('Address', _joinedMember!.member.address.isNotEmpty ? _joinedMember!.member.address : 'Not specified'),
                            const SizedBox(height: 12),
                            _buildInfoRow(
                              'Joining Date',
                              _joinedMember!.member.joiningDate != null
                                  ? dateFormat.format(_joinedMember!.member.joiningDate!)
                                  : 'Not specified',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Membership Details Card
                      Container(
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
                                const Icon(Icons.card_membership, color: AppTheme.primary, size: 20),
                                const SizedBox(width: 8),
                                Text('Membership Details', style: AppTheme.headlineMd),
                              ],
                            ),
                            const Divider(height: 24),
                            _buildInfoRow('Current Plan', _joinedMember!.planName),
                            const SizedBox(height: 12),
                            _buildInfoRow(
                              'Start Date',
                              _joinedMember!.currentMembership?.startDate != null
                                  ? dateFormat.format(_joinedMember!.currentMembership!.startDate!)
                                  : '-',
                            ),
                            const SizedBox(height: 12),
                            _buildInfoRow(
                              'Expiry Date',
                              _joinedMember!.currentMembership?.expiryDate != null
                                  ? dateFormat.format(_joinedMember!.currentMembership!.expiryDate!)
                                  : '-',
                              valueColor: _joinedMember!.isExpired || _joinedMember!.isExpiringSoon
                                  ? AppTheme.tertiary
                                  : AppTheme.onSurface,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Payment Summary Card
                      Container(
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
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.account_balance_wallet, color: AppTheme.primary, size: 20),
                                    const SizedBox(width: 8),
                                    Text('Billing Cycle', style: AppTheme.headlineMd),
                                  ],
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline, color: AppTheme.primary),
                                  onPressed: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => AddPaymentScreen(
                                          preSelectedMemberId: widget.memberId,
                                        ),
                                      ),
                                    );
                                    _loadProfile();
                                  },
                                  tooltip: 'Collect Payment',
                                ),
                              ],
                            ),
                            const Divider(height: 16),
                            Text(
                              'TOTAL FEE',
                              style: AppTheme.labelSm,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '₹${_joinedMember!.totalFee.toStringAsFixed(2)}',
                              style: AppTheme.displayStat,
                            ),
                            const SizedBox(height: 12),

                            // Progress Bar
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: _joinedMember!.totalFee > 0
                                    ? (_joinedMember!.totalPaid / _joinedMember!.totalFee).clamp(0.0, 1.0)
                                    : 0,
                                minHeight: 8,
                                backgroundColor: AppTheme.surfaceContainerHigh,
                                valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
                              ),
                            ),
                            const SizedBox(height: 8),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Paid: ₹${_joinedMember!.totalPaid.toStringAsFixed(2)}',
                                  style: AppTheme.bodyMd.copyWith(
                                    color: AppTheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  'Remaining: ₹${_joinedMember!.remainingAmount.toStringAsFixed(2)}',
                                  style: AppTheme.bodyMd.copyWith(
                                    color: _joinedMember!.remainingAmount > 0
                                        ? AppTheme.tertiary
                                        : AppTheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Payment History List
                      Container(
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                          boxShadow: AppTheme.cardShadow,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  const Icon(Icons.history, color: AppTheme.primary, size: 20),
                                  const SizedBox(width: 8),
                                  Text('Payment History', style: AppTheme.headlineMd),
                                ],
                              ),
                            ),
                            const Divider(height: 1),

                            if (_payments.isEmpty)
                              Padding(
                                padding: const EdgeInsets.all(24),
                                child: Center(
                                  child: Text(
                                    'No payment records found.',
                                    style: AppTheme.bodyMd.copyWith(
                                      color: AppTheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              )
                            else
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _payments.length,
                                separatorBuilder: (context, index) => const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final p = _payments[index];
                                  return ListTile(
                                    title: Text(
                                      '₹${p.amountPaid.toStringAsFixed(2)} - ${p.method}',
                                      style: AppTheme.bodyMd.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    subtitle: Text(
                                      p.date != null
                                          ? dateFormat.format(p.date!)
                                          : 'No date',
                                      style: AppTheme.labelSm.copyWith(
                                        letterSpacing: 0,
                                        color: AppTheme.onSurfaceVariant,
                                      ),
                                    ),
                                    trailing: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.statusActiveBg,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'Paid',
                                        style: AppTheme.labelSm.copyWith(
                                          color: AppTheme.statusActiveText,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTheme.bodyMd.copyWith(color: AppTheme.onSurfaceVariant),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: AppTheme.bodyMd.copyWith(
              fontWeight: FontWeight.w600,
              color: valueColor ?? AppTheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}
