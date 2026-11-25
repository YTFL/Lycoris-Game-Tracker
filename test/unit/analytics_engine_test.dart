import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:lycoris/features/analytics/domain/services/backlog_ml_recommender.dart';
import 'package:lycoris/features/analytics/presentation/controllers/analytics_notifier.dart';
import 'package:lycoris/features/analytics/presentation/controllers/analytics_state.dart';
import 'package:lycoris/features/search/data/igdb_service.dart';
import 'package:lycoris/features/sync/data/settings_repository.dart';
import 'package:lycoris/features/tracker/domain/models/additional_expense.dart';
import 'package:lycoris/features/tracker/domain/models/game_entry.dart';
import 'package:lycoris/features/tracker/domain/models/game_status.dart';
import 'package:lycoris/features/tracker/domain/models/storefront.dart';

void main() {
  group('AnalyticsEngine Unit Tests', () {
    test('computeMedian calculates accurately for odd, even, and empty lists', () {
      expect(AnalyticsEngine.computeMedian([]), 0.0);
      expect(AnalyticsEngine.computeMedian([10.0]), 10.0);
      expect(AnalyticsEngine.computeMedian([5.0, 15.0, 25.0]), 15.0);
      expect(AnalyticsEngine.computeMedian([10.0, 20.0, 30.0, 40.0]), 25.0);
      expect(AnalyticsEngine.computeMedian([100.0, 5.0, 10.0]), 10.0);
    });

    test('BacklogMlRecommender learns from rated games and never picks wishlist items', () {
      final now = DateTime.now();
      final games = [
        // Past rated RPGs (high ratings)
        GameEntry(
          id: 'r1',
          igdbId: 1,
          title: 'RPG Hit 1',
          genres: ['RPG'],
          storefront: Storefront.steam,
          status: GameStatus.completed,
          totalMinutesPlayed: 3000,
          personalRating: 9.5,
          addedAt: now,
          updatedAt: now,
        ),
        GameEntry(
          id: 'r2',
          igdbId: 2,
          title: 'RPG Hit 2',
          genres: ['RPG'],
          storefront: Storefront.steam,
          status: GameStatus.mastered,
          totalMinutesPlayed: 4200,
          personalRating: 9.2,
          addedAt: now,
          updatedAt: now,
        ),
        // Past rated Shooter (low ratings)
        GameEntry(
          id: 'r3',
          igdbId: 3,
          title: 'Shooter Miss',
          genres: ['Shooter'],
          storefront: Storefront.epicGames,
          status: GameStatus.abandoned,
          totalMinutesPlayed: 180,
          personalRating: 4.5,
          addedAt: now,
          updatedAt: now,
        ),
        // Wishlist RPG (must NEVER be recommended)
        GameEntry(
          id: 'w1',
          igdbId: 4,
          title: 'Wishlist RPG',
          genres: ['RPG'],
          storefront: Storefront.steam,
          status: GameStatus.wishlist,
          addedAt: now,
          updatedAt: now,
        ),
        // Backlog Shooter
        GameEntry(
          id: 'b1',
          igdbId: 5,
          title: 'Backlog Shooter',
          genres: ['Shooter'],
          storefront: Storefront.epicGames,
          status: GameStatus.backlog,
          addedAt: now,
          updatedAt: now,
        ),
        // Backlog RPG (expected winner)
        GameEntry(
          id: 'b2',
          igdbId: 6,
          title: 'Backlog RPG',
          genres: ['RPG'],
          storefront: Storefront.steam,
          status: GameStatus.backlog,
          addedAt: now,
          updatedAt: now,
        ),
      ];

      final rec = BacklogMlRecommender.recommend(games: games);
      expect(rec, isNotNull);
      expect(rec!.game.id, 'b2');
      expect(rec.game.status, GameStatus.backlog);
      expect(rec.predictedRating, greaterThan(8.0));

      // Verify wishlist-only returns null
      final wishlistOnly = games.where((g) => g.status != GameStatus.backlog).toList();
      expect(BacklogMlRecommender.recommend(games: wishlistOnly), isNull);
    });

    test('BacklogRecommendationNotifier locks recommendation until status leaves backlog', () async {
      final tempDir = await Directory.systemTemp.createTemp('hive_analytics_rec_test_');
      Hive.init(tempDir.path);
      final settingsBox = await Hive.openBox<dynamic>('test_analytics_settings');
      final settingsRepo = SettingsRepository(settingsBox);

      try {
        final now = DateTime.now();
        final rated = GameEntry(
          id: 'rated_rpg',
          igdbId: 10,
          title: 'Beloved RPG',
          genres: ['RPG'],
          storefront: Storefront.steam,
          status: GameStatus.completed,
          totalMinutesPlayed: 2400,
          personalRating: 9.5,
          addedAt: now,
          updatedAt: now,
        );
        final backlog1 = GameEntry(
          id: 'b_rpg',
          igdbId: 11,
          title: 'First Backlog RPG',
          genres: ['RPG'],
          storefront: Storefront.steam,
          status: GameStatus.backlog,
          addedAt: now,
          updatedAt: now,
        );
        final backlog2 = GameEntry(
          id: 'b_indie',
          igdbId: 12,
          title: 'Second Backlog Game',
          genres: ['Indie'],
          storefront: Storefront.gog,
          status: GameStatus.backlog,
          addedAt: now,
          updatedAt: now,
        );

        final notifier = BacklogRecommendationNotifier(
          settingsRepo: settingsRepo,
          initialGames: [rated, backlog1, backlog2],
          primaryCurrency: 'USD',
          exchangeRates: null,
        );

        expect(notifier.state?.game.id, 'b_rpg');

        // Adding a new higher-affinity backlog game or rating another game should NOT change
        // the locked recommendation while b_rpg is still in backlog!
        final newBetterBacklog = GameEntry(
          id: 'b_rpg_better',
          igdbId: 13,
          title: 'New RPG',
          genres: ['RPG'],
          storefront: Storefront.steam,
          status: GameStatus.backlog,
          addedAt: now,
          updatedAt: now,
        );
        notifier.onLibraryChanged([rated, backlog1, backlog2, newBetterBacklog]);
        expect(notifier.state?.game.id, 'b_rpg');

        // Once b_rpg changes status to playing (or completed/mastered/abandoned),
        // the recommender triggers on demand and selects a new backlog game.
        final backlog1Playing = backlog1.copyWith(status: GameStatus.playing);
        notifier.onLibraryChanged([rated, backlog1Playing, backlog2, newBetterBacklog]);
        expect(notifier.state?.game.id, 'b_rpg_better');
      } finally {
        await settingsBox.close();
        await Hive.deleteBoxFromDisk('test_analytics_settings');
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      }
    });

    test('5-Tier Playtime Commitment Buckets bucket games accurately', () {
      final now = DateTime.now();
      final games = [
        GameEntry(
          id: '1',
          igdbId: 1,
          title: 'Bite',
          genres: ['Arcade'],
          storefront: Storefront.steam,
          status: GameStatus.completed,
          totalMinutesPlayed: 120, // 2h (< 5)
          addedAt: now,
          updatedAt: now,
        ),
        GameEntry(
          id: '2',
          igdbId: 2,
          title: 'Short',
          genres: ['Action'],
          storefront: Storefront.steam,
          status: GameStatus.completed,
          totalMinutesPlayed: 600, // 10h (5-20)
          addedAt: now,
          updatedAt: now,
        ),
        GameEntry(
          id: '3',
          igdbId: 3,
          title: 'Deep',
          genres: ['RPG'],
          storefront: Storefront.steam,
          status: GameStatus.completed,
          totalMinutesPlayed: 1800, // 30h (20-50)
          addedAt: now,
          updatedAt: now,
        ),
        GameEntry(
          id: '4',
          igdbId: 4,
          title: 'Epic',
          genres: ['Open World'],
          storefront: Storefront.steam,
          status: GameStatus.completed,
          totalMinutesPlayed: 4500, // 75h (50-100)
          addedAt: now,
          updatedAt: now,
        ),
        GameEntry(
          id: '5',
          igdbId: 5,
          title: 'Endless',
          genres: ['Roguelike'],
          storefront: Storefront.steam,
          status: GameStatus.playing,
          totalMinutesPlayed: 9000, // 150h (100+)
          addedAt: now,
          updatedAt: now,
        ),
      ];

      final state = AnalyticsEngine.compute(
        games: games,
        primaryCurrency: 'USD',
        exchangeRates: null,
        currentTab: AnalyticsTab.playtimeHabits,
      );

      expect(state.playtimeBuckets.length, 5);
      final map = {for (final b in state.playtimeBuckets) b.bucket: b.count};
      expect(map[PlaytimeBucket.biteSized], 1);
      expect(map[PlaytimeBucket.shortCampaign], 1);
      expect(map[PlaytimeBucket.deepDive], 1);
      expect(map[PlaytimeBucket.epicOdyssey], 1);
      expect(map[PlaytimeBucket.endlessVoid], 1);
    });

    test('Genre aggregations calculate minutes and average ratings correctly', () {
      final now = DateTime.now();
      final games = [
        GameEntry(
          id: '1',
          igdbId: 1,
          title: 'Action RPG 1',
          genres: ['Action', 'RPG'],
          storefront: Storefront.steam,
          status: GameStatus.completed,
          totalMinutesPlayed: 600, // 10h
          personalRating: 8.0,
          addedAt: now,
          updatedAt: now,
        ),
        GameEntry(
          id: '2',
          igdbId: 2,
          title: 'Action RPG 2',
          genres: ['Action', 'RPG'],
          storefront: Storefront.steam,
          status: GameStatus.completed,
          totalMinutesPlayed: 1200, // 20h
          personalRating: 10.0,
          addedAt: now,
          updatedAt: now,
        ),
      ];

      final state = AnalyticsEngine.compute(
        games: games,
        primaryCurrency: 'USD',
        exchangeRates: null,
        currentTab: AnalyticsTab.playtimeHabits,
      );

      final rpgGenre = state.topGenres.firstWhere((g) => g.genre == 'RPG');
      expect(rpgGenre.totalMinutes, 1800);
      expect(rpgGenre.gamesCount, 2);
      expect(rpgGenre.averageRating, 9.0);
    });

    test('Superlatives correctly award infinite value, black hole, freebie, and DLC collector', () {
      final now = DateTime.now();
      final games = [
        GameEntry(
          id: '1',
          igdbId: 1,
          title: 'Cheap Endless Game',
          genres: ['Indie'],
          storefront: Storefront.steam,
          status: GameStatus.playing,
          totalMinutesPlayed: 6000, // 100h
          basePrice: 10.0, // $0.10/hr -> Infinite Value
          addedAt: now,
          updatedAt: now,
        ),
        GameEntry(
          id: '2',
          igdbId: 2,
          title: 'Mega MMO',
          genres: ['MMO'],
          storefront: Storefront.steam,
          status: GameStatus.playing,
          totalMinutesPlayed: 30000, // 500h -> Black Hole
          basePrice: 60.0,
          addedAt: now,
          updatedAt: now,
        ),
        GameEntry(
          id: '3',
          igdbId: 3,
          title: 'Awesome Free Game',
          genres: ['Shooter'],
          storefront: Storefront.epicGames,
          status: GameStatus.completed,
          totalMinutesPlayed: 3600, // 60h free -> Golden Freebie
          basePrice: 0.0,
          addedAt: now,
          updatedAt: now,
        ),
        GameEntry(
          id: '4',
          igdbId: 4,
          title: 'Deluxe Game',
          genres: ['RPG'],
          storefront: Storefront.steam,
          status: GameStatus.playing,
          basePrice: 60.0,
          additionalExpenses: [
            AdditionalExpense(id: 'e1', title: 'Expansion 1', amount: 30.0, date: now),
            AdditionalExpense(id: 'e2', title: 'Expansion 2', amount: 20.0, date: now),
          ],
          addedAt: now,
          updatedAt: now,
        ),
      ];

      final state = AnalyticsEngine.compute(
        games: games,
        primaryCurrency: 'USD',
        exchangeRates: null,
        currentTab: AnalyticsTab.superlatives,
      );

      expect(state.infiniteValueGame?.title, 'Cheap Endless Game');
      expect(state.blackHoleGame?.title, 'Mega MMO');
      expect(state.goldenFreebieGame?.title, 'Awesome Free Game');
      expect(state.dlcCollectorGame?.title, 'Deluxe Game');
      expect(state.dlcCollectorSpend, 50.0);
    });

    test('IGDBDlcResult parses category and properties correctly', () {
      final json = {
        'id': 999,
        'name': 'Phantom Liberty',
        'summary': 'Spy thriller expansion for Cyberpunk 2077',
        'category': 2,
        'first_release_date': 1695686400,
        'cover': {'image_id': 'co6w9z'},
      };

      final dlc = IGDBDlcResult.fromJson(json);
      expect(dlc.id, 999);
      expect(dlc.title, 'Phantom Liberty');
      expect(dlc.categoryLabel, 'Expansion');
      expect(dlc.releaseDate, isNotNull);
      expect(dlc.coverBigUrl, contains('co6w9z'));
    });
  });
}
