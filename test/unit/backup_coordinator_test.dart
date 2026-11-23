import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:lycoris/core/storage/hive_adapters.dart';
import 'package:lycoris/features/sync/data/backup_coordinator.dart';
import 'package:lycoris/features/sync/data/drive_sync_service.dart';
import 'package:lycoris/features/sync/data/offline_backup_service.dart';
import 'package:lycoris/features/sync/data/settings_repository.dart';
import 'package:lycoris/features/tracker/domain/models/game_entry.dart';
import 'package:lycoris/features/tracker/domain/models/game_status.dart';
import 'package:lycoris/features/tracker/domain/models/storefront.dart';

void main() {
  group('BackupCoordinator Tests', () {
    late Directory tempHiveDir;
    late Directory tempBackupDir;
    late Box<GameEntry> gamesBox;
    late Box<dynamic> settingsBox;
    late SettingsRepository settingsRepo;
    late OfflineBackupService offlineService;
    late DriveSyncService driveService;
    late BackupCoordinator coordinator;

    setUp(() async {
      tempHiveDir = await Directory.systemTemp.createTemp('hive_coord_test_');
      tempBackupDir = await Directory.systemTemp.createTemp('user_coord_backup_');

      Hive.init(tempHiveDir.path);
      if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(StorefrontAdapter());
      if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(GameStatusAdapter());
      if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(AdditionalExpenseAdapter());
      if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(GameEntryAdapter());

      gamesBox = await Hive.openBox<GameEntry>('coord_games_box');
      settingsBox = await Hive.openBox<dynamic>('coord_settings_box');
      settingsRepo = SettingsRepository(settingsBox);
      offlineService = OfflineBackupService();
      driveService = DriveSyncService();

      coordinator = BackupCoordinator(
        settingsRepo: settingsRepo,
        offlineService: offlineService,
        driveService: driveService,
        gamesBox: gamesBox,
      );
    });

    tearDown(() async {
      coordinator.dispose();
      await gamesBox.close();
      await settingsBox.close();
      await Hive.deleteBoxFromDisk('coord_games_box');
      await Hive.deleteBoxFromDisk('coord_settings_box');
      if (await tempHiveDir.exists()) await tempHiveDir.delete(recursive: true);
      if (await tempBackupDir.exists()) await tempBackupDir.delete(recursive: true);
    });

    test('triggerBackupNow performs 2-stage backup when folder is configured', () async {
      // Without folder, returns false
      expect(await coordinator.triggerBackupNow(), isFalse);

      // Configure folder path
      await settingsRepo.setBackupDirectoryPath(tempBackupDir.path);

      final game = GameEntry(
        id: 'igdb_50_steam',
        igdbId: 50,
        title: 'Dark Souls',
        genres: ['Action', 'RPG'],
        storefront: Storefront.steam,
        status: GameStatus.completed,
        addedAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );
      await gamesBox.put(game.id, game);

      final success = await coordinator.triggerBackupNow();
      expect(success, isTrue);
      expect(settingsRepo.lastOfflineBackupAt, isNotNull);
      expect(settingsRepo.lastOfflineBackupStatus, contains('successfully'));

      final currentFile = File('${tempBackupDir.path}/${OfflineBackupService.currentBackupFileName}');
      expect(await currentFile.exists(), isTrue);
    });

    test('pauseAutoBackup suppresses backup cycles during batch operations', () async {
      await settingsRepo.setBackupDirectoryPath(tempBackupDir.path);
      coordinator.initialize();

      coordinator.pauseAutoBackup();

      final game = GameEntry(
        id: 'igdb_99_steam',
        igdbId: 99,
        title: 'Sekiro',
        genres: ['Action', 'Souls-like'],
        storefront: Storefront.steam,
        status: GameStatus.completed,
        addedAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      // Mutate box while paused
      await gamesBox.put(game.id, game);

      // Wait past debounce duration
      await Future<void>.delayed(const Duration(milliseconds: 1700));

      final currentFile = File('${tempBackupDir.path}/${OfflineBackupService.currentBackupFileName}');
      expect(await currentFile.exists(), isFalse);

      // Resume with triggerImmediate = true
      coordinator.resumeAutoBackup(triggerImmediate: true);
      await Future<void>.delayed(const Duration(milliseconds: 200));

      expect(await currentFile.exists(), isTrue);
    });
  });
}
