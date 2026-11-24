// lib/services/backup_service.dart
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import '../models/backup_data.dart';

/// File-picker based storage access (Android Storage Access Framework).
class BackupService {
  static const int _maxBytes = 25 * 1024 * 1024;

  /// Returns the saved location, or null when the user cancelled.
  /// Throws on failure so callers never report a false success.
  Future<String?> saveBytes(
    Uint8List bytes, {
    required String fileName,
    required String extension,
  }) async {
    return FilePicker.platform.saveFile(
      dialogTitle: 'Save file',
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: [extension],
      bytes: bytes,
    );
  }

  /// Returns the picked file's text, or null when cancelled.
  Future<String?> pickFileText() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: false,
      withData: true,
    );
    if (result == null || result.files.isEmpty) {
      return null;
    }
    final file = result.files.single;
    Uint8List? bytes = file.bytes;
    if (!kIsWeb && bytes == null && file.path != null) {
      bytes = await File(file.path!).readAsBytes();
    }
    if (bytes == null) {
      throw const BackupException('Could not read the selected file.');
    }
    if (bytes.length > _maxBytes) {
      throw const BackupException('That file is too large to be a Habit Buddy backup.');
    }
    try {
      return utf8.decode(bytes);
    } on FormatException {
      throw const BackupException('The selected file is not a text backup file.');
    }
  }
}