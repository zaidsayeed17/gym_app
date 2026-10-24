import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../models/member.dart';
import '../models/membership.dart';
import '../models/payment.dart';
import '../models/plan.dart';
import '../providers/app_data_provider.dart';
import '../services/excel_service.dart';
import '../theme/app_theme.dart';

class AddEditMemberScreen extends StatefulWidget {
  final String? memberId; // null = Add mode, non-null = Edit mode

  const AddEditMemberScreen({
    super.key,
    this.memberId,
  });

  bool get isEdit => memberId != null;

  @override
  State<AddEditMemberScreen> createState() => _AddEditMemberScreenState();
}

class _AddEditMemberScreenState extends State<AddEditMemberScreen> {
  final _formKey = GlobalKey<FormState>();
  final _excelService = ExcelService();

  bool _isLoading = true;
  bool _isDirty = false;
  bool _isSaving = false;

  // Controllers
  final _memberIdController = TextEditingController();
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _addressController = TextEditingController();
  final _totalFeeController = TextEditingController();
  final _amountPaidController = TextEditingController();

  // Selected values
  String _photoPath = '';
  DateTime _joiningDate = DateTime.now();
  DateTime _startDate = DateTime.now();
  DateTime _expiryDate = DateTime.now().add(const Duration(days: 30));

  List<Plan> _plans = [];
  Plan? _selectedPlan;
  String _paymentMethod = 'Cash';

  // For edit mode tracking
  String _originalMemberId = '';
  String _existingMembershipId = '';

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _memberIdController.dispose();
    _nameController.dispose();
    _mobileController.dispose();
    _addressController.dispose();
    _totalFeeController.dispose();
    _amountPaidController.dispose();
    super.dispose();
  }

  void _markDirty() {
    if (!_isDirty) setState(() => _isDirty = true);
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);

    _plans = await _excelService.getAllPlans();

    if (widget.isEdit) {
      final data = await _excelService.getMemberProfileDetails(widget.memberId!);
      if (data != null) {
        final jm = data['joinedMember'];
        _originalMemberId = jm.member.memberId;
        _memberIdController.text = jm.member.memberId;
        _nameController.text = jm.member.name;
        _mobileController.text = jm.member.mobileNumber;
        _addressController.text = jm.member.address;
        _photoPath = jm.member.photoPath;
        _joiningDate = jm.member.joiningDate ?? DateTime.now();

        if (jm.currentMembership != null) {
          _existingMembershipId = jm.currentMembership!.membershipId;
          _startDate = jm.currentMembership!.startDate ?? DateTime.now();
          _expiryDate = jm.currentMembership!.expiryDate ?? DateTime.now();
          _totalFeeController.text = jm.currentMembership!.totalFee.toStringAsFixed(0);

          final matchingPlan = _plans.where((p) => p.planId == jm.currentMembership!.planId).toList();
          if (matchingPlan.isNotEmpty) {
            _selectedPlan = matchingPlan.first;
          }
        }
      }
    } else {
      // Auto-suggest next Member ID on Add Mode
      final existingJoined = await _excelService.getJoinedMembers();
      final count = existingJoined.length + 1;
      _memberIdController.text = 'M${count.toString().padLeft(3, '0')}';

      // Default initializations for Add Mode
      if (_plans.isNotEmpty) {
        _selectedPlan = _plans.first;
        _totalFeeController.text = _selectedPlan!.price.toStringAsFixed(0);
        _amountPaidController.text = _selectedPlan!.price.toStringAsFixed(0);
        _recalculateExpiryDate();
      }
    }

    setState(() => _isLoading = false);
  }

  void _recalculateExpiryDate() {
    if (_selectedPlan == null) return;
    final months = _selectedPlan!.durationMonths;
    setState(() {
      _expiryDate = DateTime(
        _startDate.year,
        _startDate.month + months,
        _startDate.day,
      );
    });
  }

  void _onPlanChanged(Plan? plan) {
    if (plan == null) return;
    _markDirty();
    setState(() {
      _selectedPlan = plan;
      _totalFeeController.text = plan.price.toStringAsFixed(0);
      if (!widget.isEdit) {
        _amountPaidController.text = plan.price.toStringAsFixed(0);
      }
    });
    _recalculateExpiryDate();
  }

  void _onStartDateChanged(DateTime date) {
    _markDirty();
    setState(() {
      _startDate = date;
    });
    _recalculateExpiryDate();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: source, maxWidth: 800, maxHeight: 800);
      if (picked != null) {
        final dir = await getApplicationDocumentsDirectory();
        final photosDir = Directory('${dir.path}/photos');
        if (!await photosDir.exists()) {
          await photosDir.create(recursive: true);
        }
        final fileName = 'member_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final savedImage = await File(picked.path).copy('${photosDir.path}/$fileName');

        _markDirty();
        setState(() {
          _photoPath = savedImage.path;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick photo: $e')),
        );
      }
    }
  }

  double get _computedRemaining {
    final fee = double.tryParse(_totalFeeController.text) ?? 0.0;
    final paid = double.tryParse(_amountPaidController.text) ?? 0.0;
    return (fee - paid).clamp(0.0, double.infinity);
  }

  Future<bool> _onWillPop() async {
    if (!_isDirty) return true;

    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Discard Unsaved Changes?'),
        content: const Text('You have unsaved changes. Are you sure you want to go back?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Stay'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: AppTheme.onError,
            ),
            child: const Text('Discard'),
          ),
        ],
      ),
    );

    return shouldPop ?? false;
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPlan == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a membership plan.')),
      );
      return;
    }

    final provider = context.read<AppDataProvider>();
    final enteredMemberId = _memberIdController.text.trim();

    // Check uniqueness
    final isTaken = await _excelService.isMemberIdExists(
      enteredMemberId,
      excludeMemberId: widget.isEdit ? _originalMemberId : null,
    );
    if (isTaken) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Member ID "$enteredMemberId" is already in use. Please enter a unique ID.'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
      return;
    }

    setState(() => _isSaving = true);

    try {
      final totalFee = double.tryParse(_totalFeeController.text) ?? _selectedPlan!.price;
      final amountPaid = double.tryParse(_amountPaidController.text) ?? 0.0;

      final member = Member(
        memberId: enteredMemberId,
        name: _nameController.text.trim(),
        mobileNumber: _mobileController.text.trim(),
        address: _addressController.text.trim(),
        photoPath: _photoPath,
        joiningDate: _joiningDate,
      );

      final membership = Membership(
        membershipId: _existingMembershipId,
        memberId: enteredMemberId,
        planId: _selectedPlan!.planId,
        startDate: _startDate,
        expiryDate: _expiryDate,
        totalFee: totalFee,
        status: 'Active',
      );

      if (widget.isEdit) {
        await provider.updateMember(
          member: member,
          membership: membership,
          oldMemberId: _originalMemberId,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Member details updated successfully!'),
              backgroundColor: AppTheme.primaryContainer,
            ),
          );
          Navigator.pop(context);
        }
      } else {
        // Add Mode
        Payment? payment;
        if (amountPaid > 0) {
          payment = Payment(
            paymentId: '',
            memberId: '',
            membershipId: '',
            date: DateTime.now(),
            amountPaid: amountPaid,
            remainingAmount: (totalFee - amountPaid).clamp(0.0, double.infinity),
            method: _paymentMethod,
          );
        }

        await provider.addMember(
          member: member,
          membership: membership,
          payment: payment,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('New Member registered successfully!'),
              backgroundColor: AppTheme.primaryContainer,
            ),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving member: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _buildPhotoPicker() {
    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 46,
                backgroundColor: AppTheme.surfaceContainerHigh,
                backgroundImage: _photoPath.isNotEmpty && File(_photoPath).existsSync()
                    ? FileImage(File(_photoPath))
                    : null,
                child: _photoPath.isEmpty || !File(_photoPath).existsSync()
                    ? const Icon(Icons.person, size: 48, color: AppTheme.onSurfaceVariant)
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppTheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt, color: AppTheme.onPrimary, size: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton.icon(
                onPressed: () => _pickImage(ImageSource.camera),
                icon: const Icon(Icons.camera_alt, size: 16),
                label: const Text('Camera'),
              ),
              TextButton.icon(
                onPressed: () => _pickImage(ImageSource.gallery),
                icon: const Icon(Icons.photo_library, size: 16),
                label: const Text('Gallery'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy');

    return PopScope(
      canPop: !_isDirty,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final navigator = Navigator.of(context);
        final shouldPop = await _onWillPop();
        if (shouldPop) {
          navigator.pop(result);
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          title: Text(
            widget.isEdit ? 'Edit Member' : 'Add New Member',
            style: AppTheme.headlineMd.copyWith(color: AppTheme.onSurface),
          ),
          backgroundColor: AppTheme.surface,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
            : Form(
                key: _formKey,
                onChanged: _markDirty,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section 1: Personal Info
                      _buildSectionHeader('PERSONAL INFORMATION', Icons.person_outline),
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
                            _buildPhotoPicker(),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _memberIdController,
                              style: AppTheme.bodyMd,
                              textCapitalization: TextCapitalization.characters,
                              decoration: const InputDecoration(
                                labelText: 'Member ID *',
                                prefixIcon: Icon(Icons.badge),
                                hintText: 'e.g. M001',
                                border: OutlineInputBorder(),
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Member ID is required';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _nameController,
                              style: AppTheme.bodyMd,
                              decoration: const InputDecoration(
                                labelText: 'Full Name *',
                                prefixIcon: Icon(Icons.person),
                                border: OutlineInputBorder(),
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Full name is required';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _mobileController,
                              keyboardType: TextInputType.phone,
                              style: AppTheme.bodyMd,
                              decoration: const InputDecoration(
                                labelText: 'Mobile Number *',
                                prefixIcon: Icon(Icons.phone),
                                border: OutlineInputBorder(),
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Mobile number is required';
                                }
                                if (val.trim().length < 10) {
                                  return 'Enter a valid 10-digit mobile number';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _addressController,
                              style: AppTheme.bodyMd,
                              maxLines: 2,
                              decoration: const InputDecoration(
                                labelText: 'Address (Optional)',
                                prefixIcon: Icon(Icons.home),
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 16),
                            InkWell(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _joiningDate,
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime(2100),
                                );
                                if (picked != null) {
                                  _markDirty();
                                  setState(() => _joiningDate = picked);
                                }
                              },
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Joining Date',
                                  prefixIcon: Icon(Icons.calendar_today),
                                  border: OutlineInputBorder(),
                                ),
                                child: Text(dateFormat.format(_joiningDate)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Section 2: Membership Info
                      _buildSectionHeader('MEMBERSHIP PLAN', Icons.card_membership),
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
                            DropdownButtonFormField<Plan>(
                              initialValue: _selectedPlan,
                              decoration: const InputDecoration(
                                labelText: 'Select Plan *',
                                prefixIcon: Icon(Icons.event_note),
                                border: OutlineInputBorder(),
                              ),
                              items: _plans.map((p) {
                                return DropdownMenuItem<Plan>(
                                  value: p,
                                  child: Text('${p.planName} (${p.durationMonths} Mo) - ₹${p.price.toStringAsFixed(0)}'),
                                );
                              }).toList(),
                              onChanged: _onPlanChanged,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: InkWell(
                                    onTap: () async {
                                      final picked = await showDatePicker(
                                        context: context,
                                        initialDate: _startDate,
                                        firstDate: DateTime(2000),
                                        lastDate: DateTime(2100),
                                      );
                                      if (picked != null) {
                                        _onStartDateChanged(picked);
                                      }
                                    },
                                    child: InputDecorator(
                                      decoration: const InputDecoration(
                                        labelText: 'Start Date',
                                        prefixIcon: Icon(Icons.play_arrow),
                                        border: OutlineInputBorder(),
                                      ),
                                      child: Text(dateFormat.format(_startDate)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: InputDecorator(
                                    decoration: const InputDecoration(
                                      labelText: 'Expiry Date (Auto)',
                                      prefixIcon: Icon(Icons.flag),
                                      border: OutlineInputBorder(),
                                      fillColor: AppTheme.surfaceContainerLow,
                                      filled: true,
                                    ),
                                    child: Text(
                                      dateFormat.format(_expiryDate),
                                      style: AppTheme.bodyMd.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.primary,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _totalFeeController,
                              keyboardType: TextInputType.number,
                              style: AppTheme.bodyMd,
                              decoration: const InputDecoration(
                                labelText: 'Total Membership Fee (₹)',
                                prefixIcon: Icon(Icons.currency_rupee),
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (_) {
                                _markDirty();
                                setState(() {});
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Section 3: Initial Payment Info (Add Mode Only)
                      if (!widget.isEdit) ...[
                        _buildSectionHeader('INITIAL PAYMENT', Icons.payments_outlined),
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
                                style: AppTheme.bodyMd,
                                decoration: const InputDecoration(
                                  labelText: 'Amount Paid Now (₹)',
                                  prefixIcon: Icon(Icons.payment),
                                  border: OutlineInputBorder(),
                                ),
                                onChanged: (_) {
                                  _markDirty();
                                  setState(() {});
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
                                  if (val != null) {
                                    _markDirty();
                                    setState(() => _paymentMethod = val);
                                  }
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
                                    color: _computedRemaining > 0
                                        ? AppTheme.tertiary
                                        : AppTheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Save Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: _isSaving ? null : _submitForm,
                          icon: _isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: AppTheme.onPrimary,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.save),
                          label: Text(
                            widget.isEdit ? 'Save Changes' : 'Register Member',
                            style: AppTheme.headlineMd.copyWith(
                              color: AppTheme.onPrimary,
                              fontSize: 16,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: AppTheme.onPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: AppTheme.labelSm.copyWith(
            color: AppTheme.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
