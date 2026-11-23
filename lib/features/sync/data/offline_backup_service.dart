import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:path/path.dart' as p;
import '../../../core/constants/api_constants.dart';
import '../../tracker/domain/models/game_entry.dart';
import 'drive_sync_service.dart';
import 'saf_storage_service.dart';

class OfflineBackupInfo {
  final bool hasCurrent;
  final DateTime? currentModified;
  final int? currentSizeBytes;
  final bool hasPrevious;
  final DateTime? previousModified;
  final int? previousSizeBytes;

  const OfflineBackupInfo({
    required this.hasCurrent,
    this.currentModified,
    this.currentSizeBytes,
    required this.hasPrevious,
    this.previousModified,
    this.previousSizeBytes,
  });

  bool get hasAnyBackup => hasCurrent || hasPrevious;

  static const OfflineBackupInfo empty = OfflineBackupInfo(
    hasCurrent: false,
    hasPrevious: false,
  );
}

class OfflineBackupService {
  static const String currentBackupFileName = 'lycoris_backup_current.json';
  static const String previousBackupFileName = 'lycoris_backup_previous.json';
  static const String tempBackupFileName = '.lycoris_backup_current.json.tmp';

  /// Generates the standard Lycoris backup JSON string
  String createBackupPayload(Box<GameEntry> box) {
    final entries = box.values.map((e) => e.toJson()).toList();
    return jsonEncode({
      'app': 'Lycoris',
      'schemaVersion': ApiConstants.schemaVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'games': entries,
    });
  }

  /// Verifies that a folder path exists or can be created, and is writable.
  Future<bool> verifyDirectoryWritable(String directoryPath) async {
    if (directoryPath.startsWith('content://')) {
      return await SafStorageService.verifyWritable(directoryPath);
    }

    try {
      final dir = Directory(directoryPath);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      final testFile = File(p.join(directoryPath, '.lycoris_probe_${DateTime.now().millisecondsSinceEpoch}.tmp'));
      await testFile.writeAsString('probe', flush: true);
      await testFile.delete();
      return true;
    } catch (e) {
      debugPrint('Directory write verification failed for "$directoryPath": $e');
      return false;
    }
  }

  /// Performs atomic 2-stage rotation and saves new backup:
  /// 1. Delete previous backup if it exists.
  /// 2. Rename current backup to previous backup.
  /// 3. Write new backup payload to temp file and rename to current backup.
  Future<bool> createBackup({
    required String directoryPath,
    required Box<GameEntry> box,
  }) async {
    final payload = createBackupPayload(box);

    if (directoryPath.startsWith('content://')) {
      return await SafStorageService.rotateAndSaveBackup(
        uri: directoryPath,
        content: payload,
        currentFileName: currentBackupFileName,
        previousFileName: previousBackupFileName,
      );
    }

    try {
      final dir = Directory(directoryPath);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      final previousFile = File(p.join(directoryPath, previousBackupFileName));
      final currentFile = File(p.join(directoryPath, currentBackupFileName));
      final tempFile = File(p.join(directoryPath, tempBackupFileName));

      // 1. Delete previous backup if it exists
      if (await previousFile.exists()) {
        await previousFile.delete();
      }

      // 2. Make latest backup as previous (if current backup exists)
      if (await currentFile.exists()) {
        try {
          await currentFile.rename(previousFile.path);
        } catch (_) {
          await currentFile.copy(previousFile.path);
          await currentFile.delete();
        }
      }

      // 3. Create new backup via temp file
      await tempFile.writeAsString(payload, flush: true);

      try {
        await tempFile.rename(currentFile.path);
      } catch (_) {
        await tempFile.copy(currentFile.path);
        await tempFile.delete();
      }

      return true;
    } catch (e) {
      debugPrint('Failed to create offline 2-stage backup: $e');
      return false;
    }
  }

  /// Inspects directory for current and previous backup files and returns metadata
  Future<OfflineBackupInfo> getBackupInfo(String directoryPath) async {
    if (directoryPath.startsWith('content://')) {
      final info = await SafStorageService.getBackupInfo(
        uri: directoryPath,
        currentFileName: currentBackupFileName,
        previousFileName: previousBackupFileName,
      );
      if (info == null) return OfflineBackupInfo.empty;
      return OfflineBackupInfo(
        hasCurrent: info['hasCurrent'] == true,
        currentSizeBytes: info['currentSize'] as int?,
        currentModified: info['currentModified'] != null
            ? DateTime.fromMillisecondsSinceEpoch(info['currentModified'] as int)
            : null,
        hasPrevious: info['hasPrevious'] == true,
        previousSizeBytes: info['previousSize'] as int?,
        previousModified: info['previousModified'] != null
            ? DateTime.fromMillisecondsSinceEpoch(info['previousModified'] as int)
            : null,
      );
    }

    try {
      final dir = Directory(directoryPath);
      if (!await dir.exists()) {
        return OfflineBackupInfo.empty;
      }

      final currentFile = File(p.join(directoryPath, currentBackupFileName));
      final previousFile = File(p.join(directoryPath, previousBackupFileName));

      final hasCurrent = await currentFile.exists();
      DateTime? currentMod;
      int? currentSize;
      if (hasCurrent) {
        currentMod = await currentFile.lastModified();
        currentSize = await currentFile.length();
      }

      final hasPrevious = await previousFile.exists();
      DateTime? prevMod;
      int? prevSize;
      if (hasPrevious) {
        prevMod = await previousFile.lastModified();
        prevSize = await previousFile.length();
      }

      return OfflineBackupInfo(
        hasCurrent: hasCurrent,
        currentModified: currentMod,
        currentSizeBytes: currentSize,
        hasPrevious: hasPrevious,
        previousModified: prevMod,
        previousSizeBytes: prevSize,
      );
    } catch (_) {
      return OfflineBackupInfo.empty;
    }
  }

  /// Reads and applies LWW delta merge from a specified local backup file
  Future<int> restoreFromFile({
    required String filePath,
    required Box<GameEntry> box,
    required DriveSyncService driveSyncService,
    String? folderUri,
    String? fileName,
  }) async {
    String rawJson;

    if (filePath.startsWith('content://') || (folderUri != null && folderUri.startsWith('content://'))) {
      final uri = folderUri ?? filePath;
      final name = fileName ??
          (filePath.endsWith(previousBackupFileName)
              ? previousBackupFileName
              : currentBackupFileName);
      final content = await SafStorageService.readBackupFile(uri: uri, fileName: name);
      if (content == null || content.isEmpty) return 0;
      rawJson = content;
    } else {
      final file = File(filePath);
      if (!await file.exists()) {
        return 0;
      }
      rawJson = await file.readAsString();
    }

    return await driveSyncService.mergeBackupPayload(rawJson, box);
  }
}
