import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:lycoris/core/storage/hive_adapters.dart';
import 'package:lycoris/features/sync/data/drive_sync_service.dart';
import 'package:lycoris/features/sync/data/offline_backup_service.dart';
import 'package:lycoris/features/tracker/domain/models/additional_expense.dart';
import 'package:lycoris/features/tracker/domain/models/game_entry.dart';
import 'package:lycoris/features/tracker/domain/models/game_status.dart';
import 'package:lycoris/features/tracker/domain/models/storefront.dart';

void main() {
  group('OfflineBackupService 2-Stage Rotation Tests', () {
    late Directory tempHiveDir;
    late Directory tempBackupDir;
    late Box<GameEntry> gamesBox;
    late OfflineBackupService backupService;
    late DriveSyncService driveService;

    setUp(() async {
      tempHiveDir = await Directory.systemTemp.createTemp('hive_backup_test_');
      tempBackupDir = await Directory.systemTemp.createTemp('user_backup_dir_');

      Hive.init(tempHiveDir.path);
      if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(StorefrontAdapter());
      if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(GameStatusAdapter());
      if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(AdditionalExpenseAdapter());
      if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(GameEntryAdapter());

      gamesBox = await Hive.openBox<GameEntry>('test_games_box');
      backupService = OfflineBackupService();
      driveService = DriveSyncService();
    });

    tearDown(() async {
      await gamesBox.close();
      await Hive.deleteBoxFromDisk('test_games_box');
      if (await tempHiveDir.exists()) await tempHiveDir.delete(recursive: true);
      if (await tempBackupDir.exists()) await tempBackupDir.delete(recursive: true);
    });

    test('verifyDirectoryWritable confirms valid directory and detects errors', () async {
      final isWritable = await backupService.verifyDirectoryWritable(tempBackupDir.path);
      expect(isWritable, isTrue);

      final nonExistentNested = Directory('${tempBackupDir.path}/nested/backup/folder');
      final nestedWritable = await backupService.verifyDirectoryWritable(nonExistentNested.path);
      expect(nestedWritable, isTrue);
      expect(await nonExistentNested.exists(), isTrue);
    });

    test('2-stage rotation maintains exactly previous and current backups across mutations', () async {
      final game1 = GameEntry(
        id: 'igdb_1_steam',
        igdbId: 1,
        title: 'Chrono Trigger',
        genres: ['RPG'],
        storefront: Storefront.steam,
        status: GameStatus.completed,
        addedAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      final game2 = GameEntry(
        id: 'igdb_2_steam',
        igdbId: 2,
        title: 'Final Fantasy VII',
        genres: ['RPG'],
        storefront: Storefront.steam,
        status: GameStatus.playing,
        addedAt: DateTime(2026, 1, 2),
        updatedAt: DateTime(2026, 1, 2),
      );

      final game3 = GameEntry(
        id: 'igdb_3_steam',
        igdbId: 3,
        title: 'Persona 5 Royal',
        genres: ['JRPG'],
        storefront: Storefront.steam,
        status: GameStatus.backlog,
        addedAt: DateTime(2026, 1, 3),
        updatedAt: DateTime(2026, 1, 3),
      );

      // --- Stage 1: First backup with 1 game ---
      await gamesBox.put(game1.id, game1);
      final success1 = await backupService.createBackup(
        directoryPath: tempBackupDir.path,
        box: gamesBox,
      );
      expect(success1, isTrue);

      final currentFile = File('${tempBackupDir.path}/${OfflineBackupService.currentBackupFileName}');
      final previousFile = File('${tempBackupDir.path}/${OfflineBackupService.previousBackupFileName}');
      final tempFile = File('${tempBackupDir.path}/${OfflineBackupService.tempBackupFileName}');

      expect(await currentFile.exists(), isTrue);
      expect(await previousFile.exists(), isFalse);
      expect(await tempFile.exists(), isFalse);

      final current1Json = jsonDecode(await currentFile.readAsString()) as Map<String, dynamic>;
      final games1List = current1Json['games'] as List;
      expect(games1List.length, equals(1));
      expect(games1List.first['title'], equals('Chrono Trigger'));

      var info = await backupService.getBackupInfo(tempBackupDir.path);
      expect(info.hasCurrent, isTrue);
      expect(info.hasPrevious, isFalse);
      expect(info.currentSizeBytes, greaterThan(0));

      // --- Stage 2: Second backup with 2 games ---
      await gamesBox.put(game2.id, game2);
      final success2 = await backupService.createBackup(
        directoryPath: tempBackupDir.path,
        box: gamesBox,
      );
      expect(success2, isTrue);

      expect(await currentFile.exists(), isTrue);
      expect(await previousFile.exists(), isTrue);
      expect(await tempFile.exists(), isFalse);

      // Previous must hold game1 (the previous state)
      final prevJson = jsonDecode(await previousFile.readAsString()) as Map<String, dynamic>;
      final prevGames = prevJson['games'] as List;
      expect(prevGames.length, equals(1));
      expect(prevGames.first['title'], equals('Chrono Trigger'));

      // Current must hold both game1 and game2
      final current2Json = jsonDecode(await currentFile.readAsString()) as Map<String, dynamic>;
      final current2Games = current2Json['games'] as List;
      expect(current2Games.length, equals(2));

      info = await backupService.getBackupInfo(tempBackupDir.path);
      expect(info.hasCurrent, isTrue);
      expect(info.hasPrevious, isTrue);
      expect(info.previousSizeBytes, greaterThan(0));

      // --- Stage 3: Third backup with 3 games ---
      await gamesBox.put(game3.id, game3);
      final success3 = await backupService.createBackup(
        directoryPath: tempBackupDir.path,
        box: gamesBox,
      );
      expect(success3, isTrue);

      // Previous must now hold the 2 games from stage 2 (game1 + game2)
      final prev3Json = jsonDecode(await previousFile.readAsString()) as Map<String, dynamic>;
      final prev3Games = prev3Json['games'] as List;
      expect(prev3Games.length, equals(2));

      // Current must now hold all 3 games
      final current3Json = jsonDecode(await currentFile.readAsString()) as Map<String, dynamic>;
      final current3Games = current3Json['games'] as List;
      expect(current3Games.length, equals(3));

      // Ensure no dangling .tmp or other files exist
      final allFiles = tempBackupDir.listSync().whereType<File>().toList();
      expect(allFiles.length, equals(2));
    });

    test('restoreFromFile restores games via LWW merge from selected backup file', () async {
      final game = GameEntry(
        id: 'igdb_100_steam',
        igdbId: 100,
        title: 'Elden Ring',
        genres: ['Action', 'RPG'],
        storefront: Storefront.steam,
        status: GameStatus.playing,
        addedAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      await gamesBox.put(game.id, game);
      await backupService.createBackup(
        directoryPath: tempBackupDir.path,
        box: gamesBox,
      );

      // Clear the box completely
      await gamesBox.clear();
      expect(gamesBox.isEmpty, isTrue);

      // Restore from current backup file
      final filePath = '${tempBackupDir.path}/${OfflineBackupService.currentBackupFileName}';
      final restoredCount = await backupService.restoreFromFile(
        filePath: filePath,
        box: gamesBox,
        driveSyncService: driveService,
      );

      expect(restoredCount, equals(1));
      expect(gamesBox.length, equals(1));
      expect(gamesBox.get('igdb_100_steam')?.title, equals('Elden Ring'));
    });
  });
}
