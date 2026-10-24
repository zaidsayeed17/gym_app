import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/joined_member.dart';
import '../models/plan.dart';
import '../providers/app_data_provider.dart';
import '../services/excel_service.dart';
import '../theme/app_theme.dart';
import 'receipt_screen.dart';

class RenewalFlowScreen extends StatefulWidget {
  final String? preSelectedMemberId;

  const RenewalFlowScreen({
    super.key,
    this.preSelectedMemberId,
  });

  @override
  State<RenewalFlowScreen> createState() => _RenewalFlowScreenState();
}

class _RenewalFlowScreenState extends State<RenewalFlowScreen> {
  final _excelService = ExcelService();
  final _searchController = TextEditingController();
  final _totalFeeController = TextEditingController();
  final _amountPaidController = TextEditingController();

  int _currentStep = 1; // 1: Select Member, 2: Select Plan, 3: Payment, 4: Summary, 5: Success
  bool _isLoading = true;
  bool _isSaving = false;

  List<JoinedMember> _allMembers = [];
  List<Plan> _plans = [];

  JoinedMember? _selectedMember;
  Plan? _selectedPlan;
  String _paymentMethod = 'Cash';

  DateTime _newStartDate = DateTime.now();
  DateTime _newExpiryDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _totalFeeController.dispose();
    _amountPaidController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    _allMembers = await _excelService.getJoinedMembers();
    _plans = await _excelService.getAllPlans();

    if (widget.preSelectedMemberId != null) {
      final matching = _allMembers.where((m) => m.member.memberId == widget.preSelectedMemberId).toList();
      if (matching.isNotEmpty) {
        _selectMember(matching.first);
      }
    }

    setState(() => _isLoading = false);
  }

  void _selectMember(JoinedMember jm) {
    _selectedMember = jm;
    _selectedPlan = jm.currentPlan ?? (_plans.isNotEmpty ? _plans.first : null);

    if (_selectedPlan != null) {
      _totalFeeController.text = _selectedPlan!.price.toStringAsFixed(0);
      _amountPaidController.text = _selectedPlan!.price.toStringAsFixed(0);
    }

    _calculateDates();
    setState(() {
      _currentStep = 2;
    });
  }

  void _calculateDates() {
    if (_selectedMember == null || _selectedPlan == null) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final currentExpiry = _selectedMember!.currentMembership?.expiryDate;

    if (currentExpiry != null && !currentExpiry.isBefore(today)) {
      // Active or Expiring Soon -> new start is current expiry
      _newStartDate = currentExpiry;
    } else {
      // Expired or no prior expiry -> new start is today
      _newStartDate = today;
    }

    final months = _selectedPlan!.durationMonths;
    _newExpiryDate = DateTime(
      _newStartDate.year,
      _newStartDate.month + months,
      _newStartDate.day,
    );
  }

  void _onPlanChanged(Plan? plan) {
    if (plan == null) return;
    setState(() {
      _selectedPlan = plan;
      _totalFeeController.text = plan.price.toStringAsFixed(0);
      _amountPaidController.text = plan.price.toStringAsFixed(0);
    });
    _calculateDates();
  }

  double get _computedRemaining {
    final fee = double.tryParse(_totalFeeController.text) ?? 0.0;
    final paid = double.tryParse(_amountPaidController.text) ?? 0.0;
    return (fee - paid).clamp(0.0, double.infinity);
  }

  Future<void> _confirmRenewal() async {
    if (_selectedMember == null || _selectedPlan == null) return;

    setState(() => _isSaving = true);

    try {
      final totalFee = double.tryParse(_totalFeeController.text) ?? _selectedPlan!.price;
      final amountPaid = double.tryParse(_amountPaidController.text) ?? 0.0;

      final provider = context.read<AppDataProvider>();
      await provider.renewMembership(
        memberId: _selectedMember!.member.memberId,
        planId: _selectedPlan!.planId,
        startDate: _newStartDate,
        expiryDate: _newExpiryDate,
        totalFee: totalFee,
        amountPaid: amountPaid,
        paymentMethod: _paymentMethod,
      );

      setState(() {
        _currentStep = 5; // Success
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error renewing membership: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ─── Step 1: Member Picker Widget ───
  Widget _buildStep1MemberPicker() {
    final query = _searchController.text.toLowerCase();
    final filtered = _allMembers.where((m) {
      if (query.isEmpty) return true;
      return m.member.name.toLowerCase().contains(query) ||
          m.member.mobileNumber.contains(query) ||
          m.member.memberId.toLowerCase().contains(query);
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Search by name, mobile, or member ID...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: AppTheme.surfaceContainerLowest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
            ),
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? const Center(child: Text('No members found.'))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final jm = filtered[index];
                    final dateFormat = DateFormat('dd MMM yyyy');
                    final expiryStr = jm.currentMembership?.expiryDate != null
                        ? dateFormat.format(jm.currentMembership!.expiryDate!)
                        : 'No expiry';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.surfaceContainerHigh,
                          child: Text(jm.member.initials),
                        ),
                        title: Text(jm.member.name, style: AppTheme.bodyLg.copyWith(fontWeight: FontWeight.bold)),
                        subtitle: Text('ID: ${jm.member.memberId} • ${jm.planName} • Exp: $expiryStr'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: AppTheme.primary),
                        onTap: () => _selectMember(jm),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ─── Step 2: Select Plan Widget ───
  Widget _buildStep2SelectPlan() {
    final dateFormat = DateFormat('dd MMM yyyy');
    final oldExpiryStr = _selectedMember?.currentMembership?.expiryDate != null
        ? dateFormat.format(_selectedMember!.currentMembership!.expiryDate!)
        : 'N/A';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Member Summary Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppTheme.surfaceContainerHigh,
                  child: Text(_selectedMember?.member.initials ?? '?'),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_selectedMember?.member.name ?? '', style: AppTheme.headlineMd),
                      Text(
                        'Current: ${_selectedMember?.planName ?? 'None'} (Exp: $oldExpiryStr)',
                        style: AppTheme.bodyMd.copyWith(color: AppTheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Plan Dropdown
          Text('SELECT RENEWAL PLAN', style: AppTheme.labelSm),
          const SizedBox(height: 8),
          DropdownButtonFormField<Plan>(
            initialValue: _selectedPlan,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.event_note),
              border: OutlineInputBorder(),
              filled: true,
              fillColor: AppTheme.surfaceContainerLowest,
            ),
            items: _plans.map((p) {
              return DropdownMenuItem<Plan>(
                value: p,
                child: Text('${p.planName} (${p.durationMonths} Mo) - ₹${p.price.toStringAsFixed(0)}'),
              );
            }).toList(),
            onChanged: _onPlanChanged,
          ),
          const SizedBox(height: 20),

          // Live Expiry Calculation Box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryContainer.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_month, color: AppTheme.primary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Membership Extension',
                      style: AppTheme.bodyLg.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Start Date', style: AppTheme.labelSm),
                        const SizedBox(height: 2),
                        Text(dateFormat.format(_newStartDate), style: AppTheme.bodyMd.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const Icon(Icons.arrow_forward, color: AppTheme.primary, size: 20),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('New Expiry Date', style: AppTheme.labelSm),
                        const SizedBox(height: 2),
                        Text(
                          dateFormat.format(_newExpiryDate),
                          style: AppTheme.bodyMd.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Fee Field
          TextFormField(
            controller: _totalFeeController,
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Renewal Fee (₹)',
              prefixIcon: Icon(Icons.currency_rupee),
              border: OutlineInputBorder(),
              filled: true,
              fillColor: AppTheme.surfaceContainerLowest,
            ),
          ),
          const SizedBox(height: 24),

          // Next Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () => setState(() => _currentStep = 3),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: AppTheme.onPrimary,
              ),
              child: const Text('Proceed to Payment'),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Step 3: Payment Details Widget ───
  Widget _buildStep3PaymentDetails() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('RENEWAL PAYMENT', style: AppTheme.labelSm),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Column(
              children: [
                TextFormField(
                  controller: _amountPaidController,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Amount Paid Now (₹)',
                    prefixIcon: Icon(Icons.payment),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _paymentMethod,
                  decoration: const InputDecoration(
                    labelText: 'Payment Method',
                    prefixIcon: Icon(Icons.account_balance_wallet),
                    border: OutlineInputBorder(),
                  ),
                  items: ['Cash', 'UPI', 'Card'].map((m) {
                    return DropdownMenuItem<String>(
                      value: m,
                      child: Text(m),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _paymentMethod = val);
                  },
                ),
                const SizedBox(height: 16),
                InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Remaining Balance (Auto)',
                    prefixIcon: Icon(Icons.pending_actions),
                    border: OutlineInputBorder(),
                    fillColor: AppTheme.surfaceContainerLow,
                    filled: true,
                  ),
                  child: Text(
                    '₹${_computedRemaining.toStringAsFixed(2)}',
                    style: AppTheme.bodyMd.copyWith(
                      fontWeight: FontWeight.w700,
                      color: _computedRemaining > 0 ? AppTheme.tertiary : AppTheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _currentStep = 2),
                  child: const Text('Back'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => setState(() => _currentStep = 4),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: AppTheme.onPrimary,
                  ),
                  child: const Text('Review Summary'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Step 4: Summary & Confirmation Widget ───
  Widget _buildStep4Summary() {
    final dateFormat = DateFormat('dd MMM yyyy');
    final totalFee = double.tryParse(_totalFeeController.text) ?? 0.0;
    final amountPaid = double.tryParse(_amountPaidController.text) ?? 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('CONFIRM RENEWAL', style: AppTheme.labelSm),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Column(
              children: [
                _buildSummaryRow('Member ID', _selectedMember?.member.memberId ?? ''),
                const Divider(height: 20),
                _buildSummaryRow('Member Name', _selectedMember?.member.name ?? ''),
                const Divider(height: 20),
                _buildSummaryRow('New Plan', _selectedPlan?.planName ?? ''),
                const Divider(height: 20),
                _buildSummaryRow('Start Date', dateFormat.format(_newStartDate)),
                const Divider(height: 20),
                _buildSummaryRow('New Expiry Date', dateFormat.format(_newExpiryDate), isHighlight: true),
                const Divider(height: 20),
                _buildSummaryRow('Total Fee', '₹${totalFee.toStringAsFixed(2)}'),
                const Divider(height: 20),
                _buildSummaryRow('Amount Paid', '₹${amountPaid.toStringAsFixed(2)} ($_paymentMethod)'),
                const Divider(height: 20),
                _buildSummaryRow('Remaining Due', '₹${_computedRemaining.toStringAsFixed(2)}'),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isSaving ? null : () => setState(() => _currentStep = 3),
                  child: const Text('Back'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _confirmRenewal,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: AppTheme.onPrimary,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Confirm Renewal'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Step 5: Success Widget ───
  Widget _buildStep5Success() {
    final dateFormat = DateFormat('dd MMM yyyy');

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: AppTheme.statusActiveBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle, size: 64, color: AppTheme.statusActiveText),
            ),
            const SizedBox(height: 24),
            Text('Renewal Successful!', style: AppTheme.headlineLg),
            const SizedBox(height: 8),
            Text(
              '${_selectedMember?.member.name}\'s membership is now active until ${dateFormat.format(_newExpiryDate)}.',
              style: AppTheme.bodyLg.copyWith(color: AppTheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      if (_selectedMember != null) {
                        final payments = await _excelService.getAllPayments();
                        final memberPays = payments.where((p) => p.memberId == _selectedMember!.member.memberId).toList();
                        memberPays.sort((a, b) => (b.date ?? DateTime.now()).compareTo(a.date ?? DateTime.now()));

                        if (memberPays.isNotEmpty && mounted) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ReceiptScreen(
                                paymentId: memberPays.first.paymentId,
                              ),
                            ),
                          );
                        } else if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('No payment recorded for this renewal.')),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.receipt_long),
                    label: const Text('View Receipt'),
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

  Widget _buildSummaryRow(String label, String value, {bool isHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTheme.bodyMd.copyWith(color: AppTheme.onSurfaceVariant)),
        Text(
          value,
          style: AppTheme.bodyLg.copyWith(
            fontWeight: FontWeight.bold,
            color: isHighlight ? AppTheme.primary : AppTheme.onSurface,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          _currentStep == 5 ? 'Renewal Success' : 'Renew Membership',
          style: AppTheme.headlineMd.copyWith(color: AppTheme.onSurface),
        ),
        backgroundColor: AppTheme.surface,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : Builder(
              builder: (context) {
                switch (_currentStep) {
                  case 1:
                    return _buildStep1MemberPicker();
                  case 2:
                    return _buildStep2SelectPlan();
                  case 3:
                    return _buildStep3PaymentDetails();
                  case 4:
                    return _buildStep4Summary();
                  case 5:
                    return _buildStep5Success();
                  default:
                    return const SizedBox();
                }
              },
            ),
    );
  }
}
