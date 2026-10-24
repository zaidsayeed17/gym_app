import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/joined_member.dart';
import '../providers/app_data_provider.dart';
import '../services/excel_service.dart';
import '../theme/app_theme.dart';

class AddPaymentScreen extends StatefulWidget {
  final String? preSelectedMemberId;

  const AddPaymentScreen({
    super.key,
    this.preSelectedMemberId,
  });

  @override
  State<AddPaymentScreen> createState() => _AddPaymentScreenState();
}

class _AddPaymentScreenState extends State<AddPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _excelService = ExcelService();
  final _searchController = TextEditingController();
  final _amountPaidController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;

  List<JoinedMember> _allMembers = [];
  JoinedMember? _selectedMember;

  String _paymentMethod = 'Cash';
  DateTime _paymentDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _amountPaidController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    _allMembers = await _excelService.getJoinedMembers();

    if (widget.preSelectedMemberId != null) {
      final matching = _allMembers.where((m) => m.member.memberId == widget.preSelectedMemberId).toList();
      if (matching.isNotEmpty) {
        _selectMember(matching.first);
      }
    }

    setState(() => _isLoading = false);
  }

  void _selectMember(JoinedMember jm) {
    setState(() {
      _selectedMember = jm;
      _amountPaidController.text = jm.remainingAmount > 0
          ? jm.remainingAmount.toStringAsFixed(0)
          : '0';
    });
  }

  double get _newRemainingBalance {
    if (_selectedMember == null) return 0.0;
    final paidNow = double.tryParse(_amountPaidController.text) ?? 0.0;
    final currentDue = _selectedMember!.remainingAmount;
    return (currentDue - paidNow).clamp(0.0, double.infinity);
  }

  Future<void> _submitPayment() async {
    if (_selectedMember == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a member to collect payment.')),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    final amountPaid = double.tryParse(_amountPaidController.text) ?? 0.0;
    if (amountPaid <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment amount must be greater than ₹0.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final provider = context.read<AppDataProvider>();
      final paymentId = await provider.addStandalonePayment(
        memberId: _selectedMember!.member.memberId,
        amountPaid: amountPaid,
        paymentMethod: _paymentMethod,
        date: _paymentDate,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment ₹${amountPaid.toStringAsFixed(2)} collected successfully!'),
            backgroundColor: AppTheme.primaryContainer,
          ),
        );
        Navigator.pop(context, paymentId);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error recording payment: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _buildMemberPicker() {
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
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.surfaceContainerHigh,
                          child: Text(jm.member.initials),
                        ),
                        title: Text(jm.member.name, style: AppTheme.bodyLg.copyWith(fontWeight: FontWeight.bold)),
                        subtitle: Text('ID: ${jm.member.memberId} • ${jm.planName} • Due: ₹${jm.remainingAmount.toStringAsFixed(0)}'),
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

  Widget _buildPaymentForm() {
    final dateFormat = DateFormat('dd MMM yyyy');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Member Context Card
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
                    backgroundImage: _selectedMember!.member.photoPath.isNotEmpty &&
                            File(_selectedMember!.member.photoPath).existsSync()
                        ? FileImage(File(_selectedMember!.member.photoPath))
                        : null,
                    child: _selectedMember!.member.photoPath.isEmpty
                        ? Text(_selectedMember!.member.initials)
                        : null,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_selectedMember!.member.name, style: AppTheme.headlineMd),
                        const SizedBox(height: 2),
                        Text(
                          'ID: ${_selectedMember!.member.memberId} • Plan: ${_selectedMember!.planName}',
                          style: AppTheme.bodyMd.copyWith(color: AppTheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              'Paid: ₹${_selectedMember!.totalPaid.toStringAsFixed(0)} / ₹${_selectedMember!.totalFee.toStringAsFixed(0)}',
                              style: AppTheme.labelSm.copyWith(color: AppTheme.primary, letterSpacing: 0),
                            ),
                            const Spacer(),
                            Text(
                              'Due: ₹${_selectedMember!.remainingAmount.toStringAsFixed(0)}',
                              style: AppTheme.labelSm.copyWith(
                                color: _selectedMember!.remainingAmount > 0 ? AppTheme.tertiary : AppTheme.primary,
                                letterSpacing: 0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Text('COLLECT PAYMENT', style: AppTheme.labelSm),
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
                      labelText: 'Amount Paid Now (₹) *',
                      prefixIcon: Icon(Icons.payment),
                      border: OutlineInputBorder(),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Amount paid is required';
                      }
                      final amt = double.tryParse(val);
                      if (amt == null || amt <= 0) {
                        return 'Enter a valid payment amount';
                      }
                      return null;
                    },
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
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _paymentDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() => _paymentDate = picked);
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Payment Date',
                        prefixIcon: Icon(Icons.calendar_today),
                        border: OutlineInputBorder(),
                      ),
                      child: Text(dateFormat.format(_paymentDate)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Updated Balance Due (Auto)',
                      prefixIcon: Icon(Icons.pending_actions),
                      border: OutlineInputBorder(),
                      fillColor: AppTheme.surfaceContainerLow,
                      filled: true,
                    ),
                    child: Text(
                      '₹${_newRemainingBalance.toStringAsFixed(2)}',
                      style: AppTheme.bodyMd.copyWith(
                        fontWeight: FontWeight.bold,
                        color: _newRemainingBalance > 0 ? AppTheme.tertiary : AppTheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _submitPayment,
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: const Text('Record Payment'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: AppTheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          'Add Payment',
          style: AppTheme.headlineMd.copyWith(color: AppTheme.onSurface),
        ),
        backgroundColor: AppTheme.surface,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : _selectedMember == null
              ? _buildMemberPicker()
              : _buildPaymentForm(),
    );
  }
}
