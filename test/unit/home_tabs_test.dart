import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:lycoris/features/home/presentation/controllers/home_tabs_notifier.dart';
import 'package:lycoris/features/sync/data/settings_repository.dart';
import 'package:lycoris/features/tracker/data/game_repository.dart';
import 'package:lycoris/features/tracker/domain/models/game_entry.dart';
import 'package:lycoris/features/tracker/domain/models/game_status.dart';
import 'package:lycoris/features/tracker/domain/models/storefront.dart';
import 'package:lycoris/features/tracker/presentation/controllers/library_notifier.dart';

void main() {
  group('Home Tabs & Custom Categories Tests', () {
    late Directory tempDir;
    late Box<dynamic> settingsBox;
    late Box<GameEntry> gamesBox;
    late SettingsRepository settingsRepo;
    late GameRepository gameRepo;
    late ProviderContainer container;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('hive_tabs_test_');
      Hive.init(tempDir.path);
      settingsBox = await Hive.openBox<dynamic>('test_settings_box');
      gamesBox = await Hive.openBox<GameEntry>('test_games_box');
      settingsRepo = SettingsRepository(settingsBox);
      gameRepo = GameRepository(gamesBox);

      container = ProviderContainer(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(settingsRepo),
          gameRepositoryProvider.overrideWithValue(gameRepo),
        ],
      );
    });

    tearDown(() async {
      container.dispose();
      await settingsBox.close();
      await gamesBox.close();
      await Hive.deleteBoxFromDisk('test_settings_box');
      await Hive.deleteBoxFromDisk('test_games_box');
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('default tabs are loaded when no stored tabs exist', () {
      final state = container.read(homeTabsNotifierProvider);
      expect(state.tabs.length, equals(7));
      expect(state.tabs.first.id, equals('status_all'));
      expect(state.visibleTabs.length, equals(7));
      expect(state.customCategories, isEmpty);
    });

    test('can add custom category and it creates a custom tab', () async {
      final notifier = container.read(homeTabsNotifierProvider.notifier);
      final cat = await notifier.addCustomCategory('Favorites');

      final state = container.read(homeTabsNotifierProvider);
      expect(state.customCategories.length, equals(1));
      expect(state.customCategories.first.name, equals('Favorites'));
      expect(state.tabs.any((t) => t.customCategoryId == cat.id), isTrue);
      expect(state.visibleTabs.length, equals(8));
    });

    test('can reorder tabs', () async {
      final notifier = container.read(homeTabsNotifierProvider.notifier);
      // Default order: All (0), Playing (1), Backlog (2)...
      await notifier.reorderTabs(1, 0); // Move Playing to the top

      var state = container.read(homeTabsNotifierProvider);
      expect(state.tabs.first.id, equals('status_playing'));

      // Move Playing (0) down to index 2 (after Backlog)
      await notifier.reorderTabs(0, 2);
      state = container.read(homeTabsNotifierProvider);
      expect(state.tabs[2].id, equals('status_playing'));
    });

    test('can hide status tabs but at least one must remain visible', () async {
      final notifier = container.read(homeTabsNotifierProvider.notifier);

      // Hide Playing tab
      final success = await notifier.toggleTabVisibility('status_playing');
      expect(success, isTrue);

      final state = container.read(homeTabsNotifierProvider);
      final playingTab = state.tabs.firstWhere((t) => t.id == 'status_playing');
      expect(playingTab.isVisible, isFalse);
      expect(state.visibleTabs.length, equals(6));

      // Try hiding all tabs until only 1 remains
      for (final tab in state.tabs) {
        if (tab.isVisible && tab.id != 'status_all') {
          await notifier.toggleTabVisibility(tab.id);
        }
      }
      expect(container.read(homeTabsNotifierProvider).visibleTabs.length, equals(1));

      // Attempting to hide the last visible tab should fail
      final hideLast = await notifier.toggleTabVisibility('status_all');
      expect(hideLast, isFalse);
      expect(container.read(homeTabsNotifierProvider).visibleTabs.length, equals(1));
    });

    test('deleting a custom category removes its tab and cleans up games', () async {
      final homeNotifier = container.read(homeTabsNotifierProvider.notifier);
      final cat = await homeNotifier.addCustomCategory('Speedrun');

      // Create a game with this category
      final game = GameEntry(
        id: 'test_game_1',
        igdbId: 101,
        title: 'Celeste',
        genres: ['Platformer'],
        storefront: Storefront.steam,
        status: GameStatus.playing,
        customCategories: [cat.id],
        addedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await container.read(libraryNotifierProvider.notifier).saveGame(game);

      expect(gameRepo.getById('test_game_1')?.customCategories.contains(cat.id), isTrue);

      // Delete custom category
      await homeNotifier.deleteCustomCategory(cat.id);

      final state = container.read(homeTabsNotifierProvider);
      expect(state.customCategories, isEmpty);
      expect(state.tabs.any((t) => t.customCategoryId == cat.id), isFalse);

      // Verify the game no longer has that category
      expect(gameRepo.getById('test_game_1')?.customCategories.contains(cat.id), isFalse);
    });

    test('resetToDefaults restores default status tab order while preserving custom categories', () async {
      final notifier = container.read(homeTabsNotifierProvider.notifier);
      await notifier.addCustomCategory('Favorites');
      await notifier.reorderTabs(2, 0); // Alter order
      await notifier.toggleTabVisibility('status_playing'); // Hide Playing

      await notifier.resetToDefaults();

      final state = container.read(homeTabsNotifierProvider);
      expect(state.tabs.first.id, equals('status_all'));
      expect(state.tabs[1].id, equals('status_playing'));
      expect(state.tabs[1].isVisible, isTrue);
      expect(state.customCategories.length, equals(1));
      expect(state.tabs.any((t) => t.label == 'Favorites'), isTrue);
    });
  });
}
