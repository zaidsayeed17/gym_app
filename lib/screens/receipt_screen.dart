import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../models/joined_payment.dart';
import '../models/gym_settings.dart';
import '../services/excel_service.dart';
import '../theme/app_theme.dart';

class ReceiptScreen extends StatefulWidget {
  final String paymentId;

  const ReceiptScreen({
    super.key,
    required this.paymentId,
  });

  @override
  State<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends State<ReceiptScreen> {
  bool _isLoading = true;
  JoinedPayment? _joinedPayment;
  GymSettings? _gymSettings;

  @override
  void initState() {
    super.initState();
    _loadReceipt();
  }

  Future<void> _loadReceipt() async {
    setState(() => _isLoading = true);
    final excel = ExcelService();
    final data = await excel.getPaymentReceiptDetails(widget.paymentId);
    final settings = await excel.getSettings();

    if (mounted) {
      setState(() {
        _joinedPayment = data;
        _gymSettings = settings;
        _isLoading = false;
      });
    }
  }

  void _shareReceipt() {
    if (_joinedPayment == null) return;
    final jp = _joinedPayment!;
    final gymName = _gymSettings?.gymName ?? 'INDIAN FITNESS GYM';
    final address = _gymSettings?.address ?? '';
    final contact = _gymSettings?.contactNumber ?? '';

    final dateFormat = DateFormat('dd MMM yyyy');
    final payDate = jp.payment.date != null ? dateFormat.format(jp.payment.date!) : 'N/A';

    final textBuffer = StringBuffer();
    textBuffer.writeln('==================================');
    textBuffer.writeln('       ${gymName.toUpperCase()}');
    if (address.isNotEmpty) textBuffer.writeln('  $address');
    if (contact.isNotEmpty) textBuffer.writeln('  Contact: $contact');
    textBuffer.writeln('        PAYMENT RECEIPT');
    textBuffer.writeln('==================================');
    textBuffer.writeln('Receipt No : ${jp.payment.paymentId}');
    textBuffer.writeln('Date       : $payDate');
    textBuffer.writeln('----------------------------------');
    textBuffer.writeln('Member ID  : ${jp.member.memberId}');
    textBuffer.writeln('Member Name: ${jp.member.name}');
    textBuffer.writeln('Mobile No  : ${jp.member.mobileNumber}');
    textBuffer.writeln('Plan       : ${jp.planName}');
    textBuffer.writeln('----------------------------------');
    textBuffer.writeln('Amount Paid: ₹${jp.payment.amountPaid.toStringAsFixed(2)}');
    textBuffer.writeln('Method     : ${jp.payment.method}');
    textBuffer.writeln('Balance Due: ₹${jp.payment.remainingAmount.toStringAsFixed(2)}');
    textBuffer.writeln('==================================');
    textBuffer.writeln('Thank you for your payment!');

    Share.share(
      textBuffer.toString(),
      subject: 'Payment Receipt - ${jp.payment.paymentId}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy');
    final gymName = _gymSettings?.gymName ?? 'Indian Fitness Gym';
    final gymLogoPath = _gymSettings?.logoPath ?? '';
    final address = _gymSettings?.address ?? '';
    final contact = _gymSettings?.contactNumber ?? '';

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          'Payment Receipt',
          style: AppTheme.headlineMd.copyWith(color: AppTheme.onSurface),
        ),
        backgroundColor: AppTheme.surface,
        actions: [
          if (_joinedPayment != null)
            IconButton(
              icon: const Icon(Icons.share, color: AppTheme.primary),
              onPressed: _shareReceipt,
              tooltip: 'Share Receipt',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : _joinedPayment == null
              ? const Center(child: Text('Receipt not found.'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Printable Receipt Card
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                          boxShadow: AppTheme.cardShadow,
                          border: Border.all(color: AppTheme.outlineVariant),
                        ),
                        child: Column(
                          children: [
                            // Gym Header
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (gymLogoPath.isNotEmpty && File(gymLogoPath).existsSync())
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(
                                      File(gymLogoPath),
                                      width: 36,
                                      height: 36,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                else
                                  const Icon(Icons.fitness_center, color: AppTheme.primary, size: 28),
                                const SizedBox(width: 10),
                                Flexible(
                                  child: Text(
                                    gymName,
                                    style: AppTheme.headlineLg.copyWith(
                                      color: AppTheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                            if (address.isNotEmpty || contact.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                '${address.isNotEmpty ? address : ''}${address.isNotEmpty && contact.isNotEmpty ? ' • ' : ''}${contact.isNotEmpty ? 'Ph: $contact' : ''}',
                                style: AppTheme.labelSm.copyWith(
                                  color: AppTheme.onSurfaceVariant,
                                  fontSize: 11,
                                  letterSpacing: 0,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                            const SizedBox(height: 4),
                            Text(
                              'Official Payment Receipt',
                              style: AppTheme.labelSm.copyWith(
                                color: AppTheme.onSurfaceVariant,
                                letterSpacing: 1,
                              ),
                            ),
                            const Divider(height: 32, thickness: 1),

                            // Receipt No & Date
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('RECEIPT NO', style: AppTheme.labelSm),
                                    const SizedBox(height: 2),
                                    Text(
                                      _joinedPayment!.payment.paymentId,
                                      style: AppTheme.bodyLg.copyWith(fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text('DATE', style: AppTheme.labelSm),
                                    const SizedBox(height: 2),
                                    Text(
                                      _joinedPayment!.payment.date != null
                                          ? dateFormat.format(_joinedPayment!.payment.date!)
                                          : 'N/A',
                                      style: AppTheme.bodyLg.copyWith(fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Member Details Box
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                              ),
                              child: Column(
                                children: [
                                  _buildRow('Member ID', _joinedPayment!.member.memberId),
                                  const SizedBox(height: 6),
                                  _buildRow('Member Name', _joinedPayment!.member.name),
                                  const SizedBox(height: 6),
                                  _buildRow('Mobile Number', _joinedPayment!.member.mobileNumber),
                                  const SizedBox(height: 6),
                                  _buildRow('Plan Name', _joinedPayment!.planName),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Payment Details
                            _buildRow('Payment Method', _joinedPayment!.payment.method),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Amount Paid', style: AppTheme.headlineMd),
                                Text(
                                  '₹${_joinedPayment!.payment.amountPaid.toStringAsFixed(2)}',
                                  style: AppTheme.displayStat.copyWith(
                                    fontSize: 28,
                                    color: AppTheme.primary,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            _buildRow(
                              'Remaining Due Balance',
                              '₹${_joinedPayment!.payment.remainingAmount.toStringAsFixed(2)}',
                              valueColor: _joinedPayment!.payment.remainingAmount > 0
                                  ? AppTheme.tertiary
                                  : AppTheme.primary,
                            ),
                            const SizedBox(height: 24),

                            // Thank You Note
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryContainer.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.check_circle, size: 16, color: AppTheme.primary),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Thank you for your payment!',
                                    style: AppTheme.labelSm.copyWith(
                                      color: AppTheme.primary,
                                      letterSpacing: 0,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _shareReceipt,
                              icon: const Icon(Icons.share),
                              label: const Text('Share Receipt'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => Navigator.pop(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primary,
                                foregroundColor: AppTheme.onPrimary,
                              ),
                              child: const Text('Done'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTheme.bodyMd.copyWith(color: AppTheme.onSurfaceVariant)),
        Text(
          value,
          style: AppTheme.bodyMd.copyWith(
            fontWeight: FontWeight.bold,
            color: valueColor ?? AppTheme.onSurface,
          ),
        ),
      ],
    );
  }
}
