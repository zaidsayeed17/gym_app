import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../models/joined_payment.dart';
import '../models/report_data.dart';
import '../services/excel_service.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state.dart';
import '../widgets/monthly_revenue_chart.dart';
import '../widgets/stat_card.dart';
import 'receipt_screen.dart';

enum ReportPreset { thisMonth, lastMonth, last3Months, thisYear, custom }

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final ExcelService _excelService = ExcelService();

  ReportPreset _selectedPreset = ReportPreset.thisMonth;
  late DateTime _startDate;
  late DateTime _endDate;

  bool _isLoading = true;
  bool _isExporting = false;
  ReportData? _reportData;

  @override
  void initState() {
    super.initState();
    _applyPreset(ReportPreset.thisMonth);
  }

  void _applyPreset(ReportPreset preset) {
    final now = DateTime.now();
    DateTime start;
    DateTime end = DateTime(now.year, now.month, now.day, 23, 59, 59);

    switch (preset) {
      case ReportPreset.thisMonth:
        start = DateTime(now.year, now.month, 1);
        break;
      case ReportPreset.lastMonth:
        final prevMonth = DateTime(now.year, now.month - 1, 1);
        start = prevMonth;
        final lastDayOfPrevMonth = DateTime(now.year, now.month, 0);
        end = DateTime(lastDayOfPrevMonth.year, lastDayOfPrevMonth.month, lastDayOfPrevMonth.day, 23, 59, 59);
        break;
      case ReportPreset.last3Months:
        start = DateTime(now.year, now.month - 2, 1);
        break;
      case ReportPreset.thisYear:
        start = DateTime(now.year, 1, 1);
        break;
      case ReportPreset.custom:
        return; // Handled separately by date range picker
    }

    setState(() {
      _selectedPreset = preset;
      _startDate = start;
      _endDate = end;
    });

    _loadReportData();
  }

  Future<void> _loadReportData() async {
    setState(() => _isLoading = true);
    final data = await _excelService.getReportData(
      startDate: _startDate,
      endDate: _endDate,
    );

    if (mounted) {
      setState(() {
        _reportData = data;
        _isLoading = false;
      });
    }
  }

  Future<void> _exportReport() async {
    if (_reportData == null) return;
    setState(() => _isExporting = true);

    try {
      final file = await _excelService.exportReportToExcel(
        startDate: _startDate,
        endDate: _endDate,
        reportData: _reportData!,
      );

      if (mounted) {
        await Share.shareXFiles(
          [XFile(file.path)],
          subject: 'Indian Fitness Gym - Performance Report',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error exporting report: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Widget _buildPresetChip(String label, ReportPreset preset) {
    final isSelected = _selectedPreset == preset;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => _applyPreset(preset),
        selectedColor: AppTheme.primaryContainer.withValues(alpha: 0.25),
        backgroundColor: AppTheme.surfaceContainer,
        side: BorderSide(
          color: isSelected ? AppTheme.primary : AppTheme.outlineVariant.withValues(alpha: 0.5),
        ),
        labelStyle: AppTheme.labelSm.copyWith(
          color: isSelected ? AppTheme.primary : AppTheme.onSurfaceVariant,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          letterSpacing: 0,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        ),
      ),
    );
  }

  Widget _buildPaymentCard(BuildContext context, JoinedPayment jp) {
    final dateFormat = DateFormat('dd MMM yyyy');
    final payDate = jp.payment.date != null ? dateFormat.format(jp.payment.date!) : 'No Date';

    IconData methodIcon;
    Color methodColor;
    switch (jp.payment.method) {
      case 'UPI':
        methodIcon = Icons.qr_code_2;
        methodColor = const Color(0xFF7C3AED);
        break;
      case 'Card':
        methodIcon = Icons.credit_card;
        methodColor = const Color(0xFF2563EB);
        break;
      case 'Cash':
      default:
        methodIcon = Icons.payments;
        methodColor = AppTheme.primary;
        break;
    }

    Widget avatarWidget;
    if (jp.member.photoPath.isNotEmpty && File(jp.member.photoPath).existsSync()) {
      avatarWidget = CircleAvatar(
        radius: 20,
        backgroundImage: FileImage(File(jp.member.photoPath)),
      );
    } else {
      avatarWidget = CircleAvatar(
        radius: 20,
        backgroundColor: AppTheme.surfaceContainerHigh,
        child: Text(
          jp.member.initials,
          style: AppTheme.headlineMd.copyWith(fontSize: 12),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: AppTheme.cardShadow,
      ),
      child: ListTile(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ReceiptScreen(paymentId: jp.payment.paymentId),
            ),
          );
        },
        leading: avatarWidget,
        title: Text(jp.member.name, style: AppTheme.bodyMd.copyWith(fontWeight: FontWeight.bold)),
        subtitle: Row(
          children: [
            Icon(methodIcon, size: 12, color: methodColor),
            const SizedBox(width: 4),
            Text('$payDate • ${jp.payment.method}', style: AppTheme.labelSm.copyWith(letterSpacing: 0)),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '+₹${jp.payment.amountPaid.toStringAsFixed(2)}',
              style: AppTheme.bodyLg.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.primary,
              ),
            ),
            if (jp.payment.remainingAmount > 0)
              Text(
                'Due: ₹${jp.payment.remainingAmount.toStringAsFixed(0)}',
                style: AppTheme.labelSm.copyWith(color: AppTheme.tertiary, fontSize: 10, letterSpacing: 0),
              ),
          ],
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
          'Business Reports',
          style: AppTheme.headlineMd.copyWith(color: AppTheme.onSurface),
        ),
        backgroundColor: AppTheme.surface,
        actions: [
          IconButton(
            icon: _isExporting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 2),
                  )
                : const Icon(Icons.share, color: AppTheme.primary),
            onPressed: _isExporting ? null : _exportReport,
            tooltip: 'Export Report to Excel',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Presets & Custom Range Bar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            color: AppTheme.surface,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildPresetChip('This Month', ReportPreset.thisMonth),
                  _buildPresetChip('Last Month', ReportPreset.lastMonth),
                  _buildPresetChip('Last 3 Months', ReportPreset.last3Months),
                  _buildPresetChip('This Year', ReportPreset.thisYear),

                  // Custom Range Chip
                  ActionChip(
                    avatar: Icon(
                      Icons.date_range,
                      size: 16,
                      color: _selectedPreset == ReportPreset.custom
                          ? AppTheme.primary
                          : AppTheme.onSurfaceVariant,
                    ),
                    label: Text(
                      _selectedPreset == ReportPreset.custom
                          ? '${dateFormat.format(_startDate)} - ${dateFormat.format(_endDate)}'
                          : 'Custom Range',
                    ),
                    onPressed: () async {
                      final picked = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                        initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
                      );
                      if (picked != null) {
                        setState(() {
                          _selectedPreset = ReportPreset.custom;
                          _startDate = picked.start;
                          _endDate = DateTime(
                            picked.end.year,
                            picked.end.month,
                            picked.end.day,
                            23,
                            59,
                            59,
                          );
                        });
                        _loadReportData();
                      }
                    },
                    backgroundColor: _selectedPreset == ReportPreset.custom
                        ? AppTheme.primaryContainer.withValues(alpha: 0.25)
                        : AppTheme.surfaceContainer,
                    side: BorderSide(
                      color: _selectedPreset == ReportPreset.custom
                          ? AppTheme.primary
                          : AppTheme.outlineVariant.withValues(alpha: 0.5),
                    ),
                    labelStyle: AppTheme.labelSm.copyWith(
                      color: _selectedPreset == ReportPreset.custom
                          ? AppTheme.primary
                          : AppTheme.onSurfaceVariant,
                      fontWeight: _selectedPreset == ReportPreset.custom
                          ? FontWeight.bold
                          : FontWeight.normal,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Main Report Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                : _reportData == null
                    ? const Center(child: Text('Unable to load report metrics.'))
                    : RefreshIndicator(
                        onRefresh: _loadReportData,
                        color: AppTheme.primary,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Period Banner
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryContainer.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.calendar_month, color: AppTheme.primary, size: 18),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Period: ${dateFormat.format(_startDate)} — ${dateFormat.format(_endDate)}',
                                      style: AppTheme.labelSm.copyWith(
                                        color: AppTheme.primary,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Summary Stat Cards 2x2 Grid
                              Row(
                                children: [
                                  Expanded(
                                    child: StatCard(
                                      title: 'Revenue Collected',
                                      value: '₹${_reportData!.totalCollectionInRange.toStringAsFixed(0)}',
                                      icon: Icons.currency_rupee,
                                      iconColor: AppTheme.primary,
                                      iconBgColor: AppTheme.primaryContainer.withValues(alpha: 0.2),
                                      subtitle: '${_reportData!.paymentsCountInRange} Payments',
                                      subtitleColor: AppTheme.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: StatCard(
                                      title: 'Active Members',
                                      value: _reportData!.activeMembersCount.toString(),
                                      icon: Icons.people,
                                      iconColor: AppTheme.primary,
                                      iconBgColor: AppTheme.primaryContainer.withValues(alpha: 0.2),
                                      subtitle: 'As of Today',
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: StatCard(
                                      title: 'Pending Due Balance',
                                      value: '₹${_reportData!.totalPendingBalance.toStringAsFixed(0)}',
                                      icon: Icons.pending_actions,
                                      iconColor: AppTheme.tertiary,
                                      iconBgColor: AppTheme.tertiaryContainer.withValues(alpha: 0.2),
                                      subtitle: 'Current Active',
                                      subtitleColor: AppTheme.tertiary,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: StatCard(
                                      title: 'Expired Members',
                                      value: _reportData!.expiredMembersCount.toString(),
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

                              // Monthly Revenue Bar Chart
                              MonthlyRevenueChart(
                                monthlyData: _reportData!.monthlyRevenueMap,
                              ),
                              const SizedBox(height: 24),

                              // Range-Filtered Payment Transactions Header & List
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Transactions in Period (${_reportData!.paymentsInRange.length})',
                                    style: AppTheme.headlineMd,
                                  ),
                                  TextButton.icon(
                                    onPressed: _isExporting ? null : _exportReport,
                                    icon: const Icon(Icons.file_download, size: 18),
                                    label: const Text('Export Excel'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              _reportData!.paymentsInRange.isEmpty
                                  ? const EmptyState(
                                      title: 'No transactions in selected period',
                                      subtitle: 'Try selecting a broader date range preset.',
                                      icon: Icons.receipt_long_outlined,
                                    )
                                  : ListView.builder(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemCount: _reportData!.paymentsInRange.length,
                                      itemBuilder: (context, index) {
                                        return _buildPaymentCard(context, _reportData!.paymentsInRange[index]);
                                      },
                                    ),
                            ],
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
