import 'package:flutter_test/flutter_test.dart';
import 'package:lycoris/features/analytics/presentation/controllers/analytics_notifier.dart';
import 'package:lycoris/features/analytics/presentation/controllers/analytics_state.dart';
import 'package:lycoris/features/search/data/igdb_service.dart';
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

    test('The Golden Quadrant classifies correctly with dynamic median thresholds', () {
      final now = DateTime.now();
      final games = [
        // 1. Masterpiece: High time, High rating
        GameEntry(
          id: '1',
          igdbId: 101,
          title: 'Masterpiece RPG',
          genres: ['RPG'],
          storefront: Storefront.steam,
          status: GameStatus.completed,
          totalMinutesPlayed: 3600, // 60h
          basePrice: 60.0,
          personalRating: 9.5,
          addedAt: now,
          updatedAt: now,
        ),
        // 2. Sweet & Short Gem: Low time, High rating
        GameEntry(
          id: '2',
          igdbId: 102,
          title: 'Indie Gem',
          genres: ['Indie', 'Platformer'],
          storefront: Storefront.steam,
          status: GameStatus.completed,
          totalMinutesPlayed: 300, // 5h
          basePrice: 15.0,
          personalRating: 9.0,
          addedAt: now,
          updatedAt: now,
        ),
        // 3. Time Trap: High time, Lower rating
        GameEntry(
          id: '3',
          igdbId: 103,
          title: 'Endless Grind',
          genres: ['Shooter'],
          storefront: Storefront.steam,
          status: GameStatus.playing,
          totalMinutesPlayed: 4800, // 80h
          basePrice: 0.0,
          personalRating: 5.5,
          addedAt: now,
          updatedAt: now,
        ),
        // 4. Early Drop: Low time, Lower rating
        GameEntry(
          id: '4',
          igdbId: 104,
          title: 'Boring Game',
          genres: ['Adventure'],
          storefront: Storefront.steam,
          status: GameStatus.abandoned,
          totalMinutesPlayed: 120, // 2h
          basePrice: 30.0,
          personalRating: 4.0,
          addedAt: now,
          updatedAt: now,
        ),
      ];

      final state = AnalyticsEngine.compute(
        games: games,
        primaryCurrency: 'USD',
        exchangeRates: null,
        currentTab: AnalyticsTab.ratingJoy,
      );

      final masterpieces = state.quadrantGames[QuadrantCategory.timelessMasterpiece]!;
      final gems = state.quadrantGames[QuadrantCategory.sweetShortGem]!;
      final traps = state.quadrantGames[QuadrantCategory.timeTrap]!;
      final drops = state.quadrantGames[QuadrantCategory.earlyDrop]!;

      expect(masterpieces.any((e) => e.game.title == 'Masterpiece RPG'), isTrue);
      expect(gems.any((e) => e.game.title == 'Indie Gem'), isTrue);
      expect(traps.any((e) => e.game.title == 'Endless Grind'), isTrue);
      expect(drops.any((e) => e.game.title == 'Boring Game'), isTrue);
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
