import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';

import 'excel_service.dart';

class BackupService {
  static final BackupService _instance = BackupService._internal();
  factory BackupService() => _instance;
  BackupService._internal();

  /// Export the current gym_data.xlsx via Android share sheet
  Future<void> exportData(BuildContext context) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/gym_data.xlsx');

      if (!await file.exists()) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No data file found to export.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      await ExcelService().updateLastBackupTimestamp();

      final timestamp = DateFormat('yyyy-MM-dd_HHmm').format(DateTime.now());
      await Share.shareXFiles(
        [XFile(file.path, name: 'gym_data_$timestamp.xlsx')],
        subject: 'Gym Data Backup - $timestamp',
        text: 'Gym Management App data backup exported on $timestamp',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Import/restore from a user-selected .xlsx file
  Future<bool> importData(BuildContext context) async {
    try {
      // Show confirmation dialog
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Restore Data?'),
          content: const Text(
            'This will replace ALL existing data with the imported file. '
            'A backup of your current data will be saved automatically.\n\n'
            'Are you sure you want to continue?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Replace Data'),
            ),
          ],
        ),
      );

      if (confirmed != true) return false;

      // Pick file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty || result.files.single.path == null) {
        return false;
      }

      final importedFile = File(result.files.single.path!);
      final dir = await getApplicationDocumentsDirectory();
      final currentFile = File('${dir.path}/gym_data.xlsx');

      // Backup current file before overwriting
      if (await currentFile.exists()) {
        final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
        final backupPath = '${dir.path}/gym_data_backup_$timestamp.xlsx';
        await currentFile.copy(backupPath);
      }

      // Copy imported file to app directory
      await importedFile.copy(currentFile.path);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data restored successfully!'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }

      return true;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }
  }
}
