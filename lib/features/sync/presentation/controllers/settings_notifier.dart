import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/storage/hive_registrar.dart';
import '../../../search/data/igdb_cache_service.dart';
import '../../../search/data/igdb_service.dart';
import '../../../tracker/presentation/controllers/library_notifier.dart';
import '../../data/backup_coordinator.dart';
import '../../data/drive_sync_service.dart';
import '../../data/offline_backup_service.dart';
import '../../data/settings_repository.dart';
export 'exchange_rates_notifier.dart';

final igdbCacheServiceProvider = Provider<IGDBCacheService>((ref) {
  return IGDBCacheService();
});

final igdbServiceProvider = Provider<IGDBService>((ref) {
  final settingsRepo = ref.watch(settingsRepositoryProvider);
  final cacheService = ref.watch(igdbCacheServiceProvider);
  final useDevApi = settingsRepo.useDeveloperApi;
  return IGDBService(
    workerProxyUrl: settingsRepo.workerProxyUrl,
    twitchClientId: useDevApi ? settingsRepo.twitchClientId : null,
    twitchClientSecret: useDevApi ? settingsRepo.getDecryptedTwitchClientSecret() : null,
    cacheService: cacheService,
  );
});

final driveSyncServiceProvider = Provider<DriveSyncService>((ref) {
  return DriveSyncService();
});

// Backward compatibility alias
final driveVaultServiceProvider = driveSyncServiceProvider;

final offlineBackupServiceProvider = Provider<OfflineBackupService>((ref) {
  return OfflineBackupService();
});

final backupCoordinatorProvider = Provider<BackupCoordinator>((ref) {
  final settingsRepo = ref.watch(settingsRepositoryProvider);
  final offlineService = ref.watch(offlineBackupServiceProvider);
  final driveService = ref.watch(driveSyncServiceProvider);
  final coordinator = BackupCoordinator(
    settingsRepo: settingsRepo,
    offlineService: offlineService,
    driveService: driveService,
    gamesBox: HiveRegistrar.gamesBox,
  );
  ref.onDispose(() => coordinator.dispose());
  return coordinator;
});

class SettingsState {
  final String workerProxyUrl;
  final String twitchClientId;
  final String twitchBearerToken;
  final bool hasTwitchClientSecret;
  final bool useDeveloperApi;
  final String primaryCurrency;
  final DateTime? lastSyncedAt;
  final bool isSyncing;
  final String? syncStatusMessage;

  // Google Drive Authentication state
  final bool isGoogleDriveSignedIn;
  final String? googleUserEmail;

  // Offline JSON Backup state
  final String? backupDirectoryPath;
  final DateTime? lastOfflineBackupAt;
  final bool isOfflineBackingUp;
  final String? offlineBackupStatusMessage;
  final OfflineBackupInfo? offlineBackupInfo;

  const SettingsState({
    required this.workerProxyUrl,
    required this.twitchClientId,
    required this.twitchBearerToken,
    this.hasTwitchClientSecret = false,
    this.useDeveloperApi = false,
    required this.primaryCurrency,
    this.lastSyncedAt,
    this.isSyncing = false,
    this.syncStatusMessage,
    this.isGoogleDriveSignedIn = false,
    this.googleUserEmail,
    this.backupDirectoryPath,
    this.lastOfflineBackupAt,
    this.isOfflineBackingUp = false,
    this.offlineBackupStatusMessage,
    this.offlineBackupInfo,
  });

  SettingsState copyWith({
    String? workerProxyUrl,
    String? twitchClientId,
    String? twitchBearerToken,
    bool? hasTwitchClientSecret,
    bool? useDeveloperApi,
    String? primaryCurrency,
    DateTime? lastSyncedAt,
    bool? isSyncing,
    String? syncStatusMessage,
    bool? isGoogleDriveSignedIn,
    String? googleUserEmail,
    String? backupDirectoryPath,
    bool clearBackupDirectoryPath = false,
    DateTime? lastOfflineBackupAt,
    bool? isOfflineBackingUp,
    String? offlineBackupStatusMessage,
    OfflineBackupInfo? offlineBackupInfo,
  }) {
    return SettingsState(
      workerProxyUrl: workerProxyUrl ?? this.workerProxyUrl,
      twitchClientId: twitchClientId ?? this.twitchClientId,
      twitchBearerToken: twitchBearerToken ?? this.twitchBearerToken,
      hasTwitchClientSecret: hasTwitchClientSecret ?? this.hasTwitchClientSecret,
      useDeveloperApi: useDeveloperApi ?? this.useDeveloperApi,
      primaryCurrency: primaryCurrency ?? this.primaryCurrency,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      isSyncing: isSyncing ?? this.isSyncing,
      syncStatusMessage: syncStatusMessage,
      isGoogleDriveSignedIn: isGoogleDriveSignedIn ?? this.isGoogleDriveSignedIn,
      googleUserEmail: googleUserEmail ?? this.googleUserEmail,
      backupDirectoryPath: clearBackupDirectoryPath
          ? null
          : (backupDirectoryPath ?? this.backupDirectoryPath),
      lastOfflineBackupAt: lastOfflineBackupAt ?? this.lastOfflineBackupAt,
      isOfflineBackingUp: isOfflineBackingUp ?? this.isOfflineBackingUp,
      offlineBackupStatusMessage: offlineBackupStatusMessage,
      offlineBackupInfo: offlineBackupInfo ?? this.offlineBackupInfo,
    );
  }
}

final settingsNotifierProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  final settingsRepo = ref.watch(settingsRepositoryProvider);
  final driveService = ref.watch(driveSyncServiceProvider);
  final offlineService = ref.watch(offlineBackupServiceProvider);
  final coordinator = ref.watch(backupCoordinatorProvider);
  return SettingsNotifier(settingsRepo, driveService, offlineService, coordinator);
});

class SettingsNotifier extends StateNotifier<SettingsState> {
  final SettingsRepository _settingsRepo;
  final DriveSyncService _driveService;
  final OfflineBackupService _offlineService;
  final BackupCoordinator _coordinator;

  SettingsNotifier(
    this._settingsRepo,
    this._driveService,
    this._offlineService,
    this._coordinator,
  ) : super(SettingsState(
          workerProxyUrl: _settingsRepo.workerProxyUrl,
          twitchClientId: _settingsRepo.twitchClientId,
          twitchBearerToken: _settingsRepo.twitchBearerToken,
          hasTwitchClientSecret: _settingsRepo.hasTwitchClientSecret,
          useDeveloperApi: _settingsRepo.useDeveloperApi,
          primaryCurrency: _settingsRepo.primaryCurrency,
          lastSyncedAt: _settingsRepo.lastSyncedAt,
          backupDirectoryPath: _settingsRepo.backupDirectoryPath,
          lastOfflineBackupAt: _settingsRepo.lastOfflineBackupAt,
          offlineBackupStatusMessage: _settingsRepo.lastOfflineBackupStatus,
        )) {
    _initAuthState();
    refreshBackupInfo();
  }

  Future<void> _initAuthState() async {
    final signedIn = await _driveService.isSignedIn();
    state = state.copyWith(
      isGoogleDriveSignedIn: signedIn,
      googleUserEmail: _driveService.currentUserEmail,
    );
  }

  Future<void> refreshBackupInfo() async {
    final path = _settingsRepo.backupDirectoryPath;
    if (path != null && path.isNotEmpty) {
      final info = await _offlineService.getBackupInfo(path);
      state = state.copyWith(
        backupDirectoryPath: path,
        offlineBackupInfo: info,
        lastOfflineBackupAt: _settingsRepo.lastOfflineBackupAt,
      );
    } else {
      state = state.copyWith(
        clearBackupDirectoryPath: true,
        offlineBackupInfo: OfflineBackupInfo.empty,
      );
    }
  }

  Future<void> updateUseDeveloperApi(bool value) async {
    await _settingsRepo.setUseDeveloperApi(value);
    state = state.copyWith(useDeveloperApi: value);
  }

  Future<void> updateWorkerProxyUrl(String url) async {
    await _settingsRepo.setWorkerProxyUrl(url);
    state = state.copyWith(workerProxyUrl: _settingsRepo.workerProxyUrl);
  }

  Future<void> resetWorkerProxyUrl() async {
    await _settingsRepo.resetWorkerProxyUrl();
    state = state.copyWith(workerProxyUrl: _settingsRepo.workerProxyUrl);
  }

  Future<void> updateTwitchCredentials({
    required String clientId,
    String? clientSecret,
  }) async {
    await _settingsRepo.setTwitchClientId(clientId);
    if (clientSecret != null && clientSecret.trim().isNotEmpty) {
      await _settingsRepo.setTwitchClientSecret(clientSecret.trim());
    }
    state = state.copyWith(
      twitchClientId: _settingsRepo.twitchClientId,
      hasTwitchClientSecret: _settingsRepo.hasTwitchClientSecret,
    );
  }

  Future<void> clearTwitchCredentials() async {
    await _settingsRepo.clearTwitchCredentials();
    state = state.copyWith(
      twitchClientId: '',
      twitchBearerToken: '',
      hasTwitchClientSecret: false,
    );
  }

  Future<void> updatePrimaryCurrency(String currency) async {
    await _settingsRepo.setPrimaryCurrency(currency);
    state = state.copyWith(primaryCurrency: currency);
  }

  // Google Drive Authentication Management
  Future<bool> signInGoogleDrive() async {
    state = state.copyWith(isSyncing: true, syncStatusMessage: 'Signing in to Google...');
    final success = await _driveService.signInInteractive();
    final email = _driveService.currentUserEmail;
    state = state.copyWith(
      isSyncing: false,
      isGoogleDriveSignedIn: success,
      googleUserEmail: email,
      syncStatusMessage: success ? 'Signed in as $email' : 'Sign-in was canceled or failed.',
    );
    return success;
  }

  Future<void> signOutGoogleDrive() async {
    await _driveService.signOut();
    state = state.copyWith(
      isGoogleDriveSignedIn: false,
      googleUserEmail: null,
      syncStatusMessage: 'Signed out of Google Drive.',
    );
  }

  Future<bool> backupToDrive() async {
    state = state.copyWith(isSyncing: true, syncStatusMessage: 'Backing up to Google Drive...');
    final success = await _driveService.backupToDrive(
      HiveRegistrar.gamesBox,
      interactiveIfNeeded: true,
    );
    final now = DateTime.now();
    final signedIn = await _driveService.isSignedIn();
    final email = _driveService.currentUserEmail;

    if (success) {
      await _settingsRepo.setLastSyncedAt(now);
      state = state.copyWith(
        isSyncing: false,
        lastSyncedAt: now,
        isGoogleDriveSignedIn: signedIn,
        googleUserEmail: email,
        syncStatusMessage: 'Backup completed successfully!',
      );
    } else {
      state = state.copyWith(
        isSyncing: false,
        isGoogleDriveSignedIn: signedIn,
        googleUserEmail: email,
        syncStatusMessage: 'Google Drive backup failed. Sign-in canceled or offline.',
      );
    }
    return success;
  }

  Future<int> restoreFromDrive() async {
    state = state.copyWith(isSyncing: true, syncStatusMessage: 'Restoring from Google Drive...');
    _coordinator.pauseAutoBackup();
    try {
      final restoredCount = await _driveService.restoreFromDrive(
        HiveRegistrar.gamesBox,
        interactiveIfNeeded: true,
      );
      final now = DateTime.now();
      await _settingsRepo.setLastSyncedAt(now);
      final signedIn = await _driveService.isSignedIn();

      state = state.copyWith(
        isSyncing: false,
        lastSyncedAt: now,
        isGoogleDriveSignedIn: signedIn,
        googleUserEmail: _driveService.currentUserEmail,
        syncStatusMessage: 'Restored $restoredCount entries via LWW merge.',
      );
      return restoredCount;
    } finally {
      _coordinator.resumeAutoBackup(triggerImmediate: true);
      await refreshBackupInfo();
    }
  }

  // Offline JSON Backup Management
  Future<bool> setBackupDirectory(String? path) async {
    if (path == null || path.trim().isEmpty) {
      await _settingsRepo.setBackupDirectoryPath(null);
      await refreshBackupInfo();
      return true;
    }

    final isWritable = await _offlineService.verifyDirectoryWritable(path.trim());
    if (!isWritable) {
      state = state.copyWith(
        offlineBackupStatusMessage: 'Selected directory is not writable. Please choose another.',
      );
      return false;
    }

    await _settingsRepo.setBackupDirectoryPath(path.trim());
    await refreshBackupInfo();

    // Trigger an immediate initial backup to verify and establish current backup file
    await triggerOfflineBackupNow();
    return true;
  }

  Future<void> clearBackupDirectory() async {
    await _settingsRepo.setBackupDirectoryPath(null);
    await refreshBackupInfo();
  }

  Future<bool> triggerOfflineBackupNow() async {
    final path = _settingsRepo.backupDirectoryPath;
    if (path == null || path.isEmpty) return false;

    state = state.copyWith(
      isOfflineBackingUp: true,
      offlineBackupStatusMessage: 'Creating 2-stage JSON backup...',
    );

    final success = await _coordinator.triggerBackupNow();
    await refreshBackupInfo();

    state = state.copyWith(
      isOfflineBackingUp: false,
      lastOfflineBackupAt: _settingsRepo.lastOfflineBackupAt,
      offlineBackupStatusMessage: success
          ? 'Backup created successfully in folder!'
          : 'Failed to create offline backup.',
    );
    return success;
  }

  Future<int> restoreFromOfflineFile(String filePath, {String? fileName, String? folderUri}) async {
    state = state.copyWith(
      isOfflineBackingUp: true,
      offlineBackupStatusMessage: 'Restoring entries from offline file...',
    );

    _coordinator.pauseAutoBackup();
    try {
      final count = await _offlineService.restoreFromFile(
        filePath: filePath,
        box: HiveRegistrar.gamesBox,
        driveSyncService: _driveService,
        fileName: fileName,
        folderUri: folderUri,
      );

      state = state.copyWith(
        isOfflineBackingUp: false,
        offlineBackupStatusMessage: 'Restored $count entries from file.',
      );
      return count;
    } finally {
      _coordinator.resumeAutoBackup(triggerImmediate: true);
      await refreshBackupInfo();
    }
  }

  String exportToJson() {
    return _driveService.createBackupPayload(HiveRegistrar.gamesBox);
  }

  Future<int> importFromJson(String jsonString) async {
    state = state.copyWith(isSyncing: true, syncStatusMessage: 'Importing JSON payload...');
    _coordinator.pauseAutoBackup();
    try {
      final count = await _driveService.mergeBackupPayload(jsonString, HiveRegistrar.gamesBox);
      state = state.copyWith(
        isSyncing: false,
        syncStatusMessage: 'Imported $count entries via LWW merge.',
      );
      return count;
    } finally {
      _coordinator.resumeAutoBackup(triggerImmediate: true);
      await refreshBackupInfo();
    }
  }
}
