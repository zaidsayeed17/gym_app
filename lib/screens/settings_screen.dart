import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../models/gym_settings.dart';
import '../providers/app_data_provider.dart';
import '../services/backup_service.dart';
import '../services/excel_service.dart';
import '../theme/app_theme.dart';
import 'plans_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _excelService = ExcelService();
  final _backupService = BackupService();

  final _gymNameController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _contactController = TextEditingController();
  final _addressController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  String _logoPath = '';
  DateTime? _lastBackupDate;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _gymNameController.dispose();
    _ownerNameController.dispose();
    _contactController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    final settings = await _excelService.getSettings();

    if (mounted) {
      setState(() {
        _gymNameController.text = settings.gymName;
        _ownerNameController.text = settings.ownerName;
        _contactController.text = settings.contactNumber;
        _addressController.text = settings.address;
        _logoPath = settings.logoPath;
        _lastBackupDate = settings.lastBackupDate;
        _isLoading = false;
      });
    }
  }

  Future<void> _pickLogo(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 85);

    if (pickedFile != null) {
      final appDir = await getApplicationDocumentsDirectory();
      final photosDir = Directory('${appDir.path}/photos');
      if (!await photosDir.exists()) {
        await photosDir.create(recursive: true);
      }

      final fileName = 'gym_logo_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedImage = await File(pickedFile.path).copy('${photosDir.path}/$fileName');

      setState(() {
        _logoPath = savedImage.path;
      });
    }
  }

  void _showLogoPickerOptions() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppTheme.primary),
              title: const Text('Take Photo with Camera'),
              onTap: () {
                Navigator.pop(ctx);
                _pickLogo(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppTheme.primary),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(ctx);
                _pickLogo(ImageSource.gallery);
              },
            ),
            if (_logoPath.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: AppTheme.error),
                title: const Text('Remove Logo'),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() => _logoPath = '');
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveProfileSettings() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final updatedSettings = GymSettings(
        gymName: _gymNameController.text.trim(),
        ownerName: _ownerNameController.text.trim(),
        contactNumber: _contactController.text.trim(),
        address: _addressController.text.trim(),
        logoPath: _logoPath,
        lastBackupDate: _lastBackupDate,
      );

      await _excelService.saveSettings(updatedSettings);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gym profile settings saved successfully!'),
            backgroundColor: AppTheme.primaryContainer,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving settings: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          'App Settings',
          style: AppTheme.headlineMd.copyWith(color: AppTheme.onSurface),
        ),
        backgroundColor: AppTheme.surface,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Gym Profile Card
                  Text('GYM PROFILE INFORMATION', style: AppTheme.labelSm),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                      boxShadow: AppTheme.cardShadow,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Logo Picker Avatar
                          Center(
                            child: Stack(
                              children: [
                                CircleAvatar(
                                  radius: 40,
                                  backgroundColor: AppTheme.primaryContainer.withValues(alpha: 0.2),
                                  backgroundImage: _logoPath.isNotEmpty && File(_logoPath).existsSync()
                                      ? FileImage(File(_logoPath))
                                      : null,
                                  child: _logoPath.isEmpty
                                      ? const Icon(Icons.fitness_center, size: 40, color: AppTheme.primary)
                                      : null,
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: InkWell(
                                    onTap: _showLogoPickerOptions,
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: const BoxDecoration(
                                        color: AppTheme.primary,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          TextFormField(
                            controller: _gymNameController,
                            style: AppTheme.bodyMd,
                            decoration: const InputDecoration(
                              labelText: 'Gym Name *',
                              prefixIcon: Icon(Icons.business),
                              border: OutlineInputBorder(),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Gym name is required';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),

                          TextFormField(
                            controller: _ownerNameController,
                            style: AppTheme.bodyMd,
                            decoration: const InputDecoration(
                              labelText: 'Owner Name',
                              prefixIcon: Icon(Icons.person),
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 14),

                          TextFormField(
                            controller: _contactController,
                            keyboardType: TextInputType.phone,
                            style: AppTheme.bodyMd,
                            decoration: const InputDecoration(
                              labelText: 'Contact Phone Number',
                              prefixIcon: Icon(Icons.phone),
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 14),

                          TextFormField(
                            controller: _addressController,
                            maxLines: 2,
                            style: AppTheme.bodyMd,
                            decoration: const InputDecoration(
                              labelText: 'Gym Address',
                              prefixIcon: Icon(Icons.location_on),
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 20),

                          SizedBox(
                            width: double.infinity,
                            height: 46,
                            child: ElevatedButton.icon(
                              onPressed: _isSaving ? null : _saveProfileSettings,
                              icon: _isSaving
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                    )
                                  : const Icon(Icons.save),
                              label: const Text('Save Gym Profile'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primary,
                                foregroundColor: AppTheme.onPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 2. Navigation Shortcuts Card
                  Text('MANAGEMENT SHORTCUTS', style: AppTheme.labelSm),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                      boxShadow: AppTheme.cardShadow,
                    ),
                    child: ListTile(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const PlansScreen()),
                        );
                      },
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryContainer.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.event_note, color: AppTheme.primary),
                      ),
                      title: Text(
                        'Membership Plans Management',
                        style: AppTheme.bodyLg.copyWith(fontWeight: FontWeight.bold),
                      ),
                      subtitle: const Text('Add, edit, or customize gym plans'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: AppTheme.primary),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 3. Data Backup & Restore Section
                  Text('EXCEL DATA MANAGEMENT', style: AppTheme.labelSm),
                  const SizedBox(height: 8),
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
                            const Icon(Icons.storage, color: AppTheme.primary, size: 22),
                            const SizedBox(width: 10),
                            Text('Local Excel File Storage', style: AppTheme.headlineMd),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'All data is stored locally in gym_data.xlsx. You can backup or transfer your database anytime.',
                          style: AppTheme.bodyMd.copyWith(color: AppTheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 14),

                        // Last Backup Timestamp Banner
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.access_time, size: 16, color: AppTheme.onSurfaceVariant),
                              const SizedBox(width: 8),
                              Text(
                                _lastBackupDate != null
                                    ? 'Last backed up: ${dateFormat.format(_lastBackupDate!)}'
                                    : 'Last backed up: Never backed up',
                                style: AppTheme.labelSm.copyWith(
                                  color: AppTheme.onSurfaceVariant,
                                  letterSpacing: 0,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  await _backupService.exportData(context);
                                  await _loadSettings();
                                },
                                icon: const Icon(Icons.share),
                                label: const Text('Backup Data'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  final provider = context.read<AppDataProvider>();
                                  final messenger = ScaffoldMessenger.of(context);
                                  final restored = await _backupService.importData(context);
                                  if (restored) {
                                    await provider.initialize();
                                    await _loadSettings();
                                    messenger.showSnackBar(
                                      const SnackBar(
                                        content: Text('Data restored successfully!'),
                                        backgroundColor: AppTheme.primaryContainer,
                                      ),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.file_upload),
                                label: const Text('Restore Data'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // App Version Footer
                  Center(
                    child: Column(
                      children: [
                        Text(
                          'Indian Fitness Gym App',
                          style: AppTheme.bodyMd.copyWith(fontWeight: FontWeight.bold, color: AppTheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Version 1.0.0 • Offline Single-Owner App',
                          style: AppTheme.labelSm.copyWith(color: AppTheme.outline),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }
}
