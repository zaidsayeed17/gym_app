import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/joined_payment.dart';
import '../providers/app_data_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state.dart';
import 'add_payment_screen.dart';
import 'receipt_screen.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final provider = context.read<AppDataProvider>();
    _searchController.text = provider.paymentSearchQuery;
    _searchController.addListener(() {
      provider.setPaymentSearchQuery(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildMethodChip(String method, String currentFilter, ValueChanged<String> onSelected) {
    final isSelected = currentFilter == method;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(method),
        selected: isSelected,
        onSelected: (_) => onSelected(method),
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
        radius: 22,
        backgroundImage: FileImage(File(jp.member.photoPath)),
      );
    } else {
      avatarWidget = CircleAvatar(
        radius: 22,
        backgroundColor: AppTheme.surfaceContainerHigh,
        child: Text(
          jp.member.initials,
          style: AppTheme.headlineMd.copyWith(fontSize: 14),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: AppTheme.cardShadow,
        border: Border.all(color: AppTheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ReceiptScreen(paymentId: jp.payment.paymentId),
              ),
            );
          },
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.stackMd),
            child: Row(
              children: [
                avatarWidget,
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  jp.member.name,
                                  style: AppTheme.bodyLg.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.onSurface,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  'ID: ${jp.member.memberId}',
                                  style: AppTheme.labelSm.copyWith(
                                    color: AppTheme.onSurfaceVariant,
                                    letterSpacing: 0,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '+₹${jp.payment.amountPaid.toStringAsFixed(2)}',
                            style: AppTheme.headlineMd.copyWith(
                              color: AppTheme.primary,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(methodIcon, size: 14, color: methodColor),
                              const SizedBox(width: 4),
                              Text(
                                '${jp.payment.method} • $payDate',
                                style: AppTheme.labelSm.copyWith(
                                  color: AppTheme.onSurfaceVariant,
                                  letterSpacing: 0,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                          if (jp.payment.remainingAmount > 0)
                            Text(
                              'Due: ₹${jp.payment.remainingAmount.toStringAsFixed(0)}',
                              style: AppTheme.labelSm.copyWith(
                                color: AppTheme.tertiary,
                                fontSize: 11,
                                letterSpacing: 0,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.receipt_long, color: AppTheme.outline, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM');

    return Consumer<AppDataProvider>(
      builder: (context, provider, _) {
        final filteredList = provider.filteredPayments;
        final totalPayments = provider.allJoinedPayments.length;
        final dateRange = provider.selectedDateRange;

        return Scaffold(
          backgroundColor: AppTheme.background,
          body: Column(
            children: [
              // Search & Filters Header
              Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                color: AppTheme.surface,
                child: Column(
                  children: [
                    // Search bar
                    TextField(
                      controller: _searchController,
                      style: AppTheme.bodyMd.copyWith(color: AppTheme.onSurface),
                      decoration: InputDecoration(
                        hintText: 'Search payments by name, mobile, or member ID...',
                        hintStyle: AppTheme.bodyMd.copyWith(
                          color: AppTheme.onSurfaceVariant.withValues(alpha: 0.7),
                        ),
                        prefixIcon: const Icon(Icons.search, color: AppTheme.onSurfaceVariant),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 20),
                                onPressed: () => _searchController.clear(),
                              )
                            : null,
                        filled: true,
                        fillColor: AppTheme.surfaceContainerLowest,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                          borderSide: const BorderSide(color: AppTheme.outlineVariant),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Filter chips + Date range picker button
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildMethodChip('All', provider.selectedPaymentMethodFilter, provider.setPaymentMethodFilter),
                          _buildMethodChip('Cash', provider.selectedPaymentMethodFilter, provider.setPaymentMethodFilter),
                          _buildMethodChip('UPI', provider.selectedPaymentMethodFilter, provider.setPaymentMethodFilter),
                          _buildMethodChip('Card', provider.selectedPaymentMethodFilter, provider.setPaymentMethodFilter),

                          // Date Range Filter Chip
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ActionChip(
                              avatar: Icon(
                                Icons.date_range,
                                size: 16,
                                color: dateRange != null ? AppTheme.primary : AppTheme.onSurfaceVariant,
                              ),
                              label: Text(
                                dateRange != null
                                    ? '${dateFormat.format(dateRange.start)} - ${dateFormat.format(dateRange.end)}'
                                    : 'Date Range',
                              ),
                              onPressed: () async {
                                final picked = await showDateRangePicker(
                                  context: context,
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime(2100),
                                  initialDateRange: dateRange,
                                );
                                if (picked != null) {
                                  provider.setDateRangeFilter(picked);
                                }
                              },
                              backgroundColor: dateRange != null
                                  ? AppTheme.primaryContainer.withValues(alpha: 0.25)
                                  : AppTheme.surfaceContainer,
                              side: BorderSide(
                                color: dateRange != null
                                    ? AppTheme.primary
                                    : AppTheme.outlineVariant.withValues(alpha: 0.5),
                              ),
                              labelStyle: AppTheme.labelSm.copyWith(
                                color: dateRange != null ? AppTheme.primary : AppTheme.onSurfaceVariant,
                                fontWeight: dateRange != null ? FontWeight.bold : FontWeight.normal,
                                letterSpacing: 0,
                              ),
                            ),
                          ),

                          if (dateRange != null)
                            IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () => provider.setDateRangeFilter(null),
                              tooltip: 'Clear date filter',
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Payments List Content
              Expanded(
                child: provider.isPaymentsLoading
                    ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                    : totalPayments == 0
                        ? EmptyState(
                            title: 'No payments recorded yet',
                            subtitle: 'Tap the + button below to collect your first payment.',
                            icon: Icons.payments_outlined,
                            actionLabel: 'Collect Payment',
                            onAction: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const AddPaymentScreen()),
                              );
                            },
                          )
                        : filteredList.isEmpty
                            ? const EmptyState(
                                title: 'No matching payments',
                                subtitle: 'No payments match current search query or filter options.',
                                icon: Icons.search_off,
                              )
                            : RefreshIndicator(
                                onRefresh: () => provider.loadPayments(),
                                color: AppTheme.primary,
                                child: ListView.builder(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: filteredList.length,
                                  itemBuilder: (context, index) {
                                    return _buildPaymentCard(context, filteredList[index]);
                                  },
                                ),
                              ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddPaymentScreen()),
              );
            },
            backgroundColor: AppTheme.primary,
            foregroundColor: AppTheme.onPrimary,
            icon: const Icon(Icons.add),
            label: Text(
              'Add Payment',
              style: AppTheme.labelSm.copyWith(color: AppTheme.onPrimary),
            ),
          ),
        );
      },
    );
  }
}
