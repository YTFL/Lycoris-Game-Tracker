import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../../tracker/domain/models/game_entry.dart';
import 'drive_sync_service.dart';
import 'offline_backup_service.dart';
import 'settings_repository.dart';

class BackupCoordinator {
  final SettingsRepository _settingsRepo;
  final OfflineBackupService _offlineService;
  final DriveSyncService _driveService;
  final Box<GameEntry> _gamesBox;

  StreamSubscription<BoxEvent>? _subscription;
  Timer? _debounceTimer;
  bool _isExecuting = false;
  bool _pendingChange = false;
  bool _isPaused = false;
  bool _isInitialized = false;

  BackupCoordinator({
    required SettingsRepository settingsRepo,
    required OfflineBackupService offlineService,
    required DriveSyncService driveService,
    required Box<GameEntry> gamesBox,
  })  : _settingsRepo = settingsRepo,
        _offlineService = offlineService,
        _driveService = driveService,
        _gamesBox = gamesBox;

  /// Start listening to Hive database mutations
  void initialize() {
    if (_isInitialized) return;
    _isInitialized = true;
    _subscription = _gamesBox.watch().listen((_) {
      _onDatabaseChanged();
    });
  }

  /// Pause automatic backup during batch operations (e.g. restores, clear all)
  void pauseAutoBackup() {
    _isPaused = true;
    _debounceTimer?.cancel();
  }

  /// Resume automatic backup after batch operations
  void resumeAutoBackup({bool triggerImmediate = true}) {
    _isPaused = false;
    if (triggerImmediate) {
      triggerBackupNow();
    }
  }

  void _onDatabaseChanged() {
    if (_isPaused) return;

    final folderPath = _settingsRepo.backupDirectoryPath;
    if (folderPath == null || folderPath.trim().isEmpty) {
      return;
    }

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 1500), () {
      _executeBackupCycle();
    });
  }

  /// Manually trigger immediate 2-stage backup and Drive sync
  Future<bool> triggerBackupNow() async {
    final folderPath = _settingsRepo.backupDirectoryPath;
    if (folderPath == null || folderPath.trim().isEmpty) {
      return false;
    }
    return await _executeBackupCycle();
  }

  Future<bool> _executeBackupCycle() async {
    final folderPath = _settingsRepo.backupDirectoryPath;
    if (folderPath == null || folderPath.trim().isEmpty) {
      return false;
    }

    if (_isExecuting) {
      _pendingChange = true;
      return false;
    }

    _isExecuting = true;
    bool overallSuccess = false;

    try {
      // 1. Create offline 2-stage rotating backup
      final offlineSuccess = await _offlineService.createBackup(
        directoryPath: folderPath,
        box: _gamesBox,
      );

      final now = DateTime.now();

      if (offlineSuccess) {
        await _settingsRepo.setLastOfflineBackupAt(now);
        await _settingsRepo.setLastOfflineBackupStatus('Backup created successfully');
        overallSuccess = true;

        // 2. Automatically create Google Drive backup as well (retaining sign-in state silently)
        final driveSuccess = await _driveService.backupToDrive(
          _gamesBox,
          interactiveIfNeeded: false,
        );

        if (driveSuccess) {
          await _settingsRepo.setLastSyncedAt(now);
        }
      } else {
        await _settingsRepo.setLastOfflineBackupStatus('Failed to write offline backup file');
      }
    } catch (e) {
      debugPrint('BackupCoordinator cycle error: $e');
      await _settingsRepo.setLastOfflineBackupStatus('Error: $e');
    } finally {
      _isExecuting = false;
      if (_pendingChange) {
        _pendingChange = false;
        _onDatabaseChanged();
      }
    }

    return overallSuccess;
  }

  void dispose() {
    _debounceTimer?.cancel();
    _subscription?.cancel();
    _isInitialized = false;
  }
}
