import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/exchange_rate_service.dart';
import '../../../../core/utils/currency_helper.dart';
import '../../../sync/data/settings_repository.dart';
import '../../../sync/presentation/controllers/settings_notifier.dart';
import '../../../tracker/domain/models/game_entry.dart';
import '../../../tracker/domain/models/game_status.dart';
import '../../../tracker/domain/models/storefront.dart';
import '../../../tracker/presentation/controllers/library_notifier.dart';
import '../../../tracker/presentation/controllers/library_state.dart';
import '../../domain/models/backlog_recommendation.dart';
import '../../domain/services/backlog_ml_recommender.dart';
import 'analytics_state.dart';

final analyticsTabProvider = StateProvider<AnalyticsTab>((ref) => AnalyticsTab.overview);

final analyticsStateProvider = Provider<AnalyticsState>((ref) {
  final libraryState = ref.watch(libraryNotifierProvider);
  final settingsState = ref.watch(settingsNotifierProvider);
  final exchangeRates = ref.watch(exchangeRatesNotifierProvider);
  final currentTab = ref.watch(analyticsTabProvider);

  return AnalyticsEngine.compute(
    games: libraryState.allGames,
    primaryCurrency: settingsState.primaryCurrency,
    exchangeRates: exchangeRates,
    currentTab: currentTab,
  );
});

final backlogRecommendationProvider =
    StateNotifierProvider<BacklogRecommendationNotifier, BacklogRecommendation?>(
  (ref) {
    final settingsRepo = ref.watch(settingsRepositoryProvider);
    final initialGames = ref.read(libraryNotifierProvider).allGames;
    final primaryCurrency = ref.watch(
      settingsNotifierProvider.select((s) => s.primaryCurrency),
    );
    final exchangeRates = ref.watch(exchangeRatesNotifierProvider);

    final notifier = BacklogRecommendationNotifier(
      settingsRepo: settingsRepo,
      initialGames: initialGames,
      primaryCurrency: primaryCurrency,
      exchangeRates: exchangeRates,
    );

    ref.listen<LibraryState>(libraryNotifierProvider, (prev, next) {
      notifier.onLibraryChanged(next.allGames);
    });

    return notifier;
  },
);

class BacklogRecommendationNotifier extends StateNotifier<BacklogRecommendation?> {
  final SettingsRepository _settingsRepo;
  final String _primaryCurrency;
  final ExchangeRates? _exchangeRates;

  BacklogRecommendationNotifier({
    required SettingsRepository settingsRepo,
    required List<GameEntry> initialGames,
    required String primaryCurrency,
    required ExchangeRates? exchangeRates,
  })  : _settingsRepo = settingsRepo,
        _primaryCurrency = primaryCurrency,
        _exchangeRates = exchangeRates,
        super(
          _resolveOrCompute(
            settingsRepo: settingsRepo,
            games: initialGames,
            primaryCurrency: primaryCurrency,
            exchangeRates: exchangeRates,
          ),
        );

  static BacklogRecommendation? _tryHydrateFromStorage(
    SettingsRepository settingsRepo,
    List<GameEntry> games,
  ) {
    final rawJson = settingsRepo.backlogRecommendationJson;
    if (rawJson == null || rawJson.isEmpty) return null;

    try {
      final map = jsonDecode(rawJson) as Map<String, dynamic>;
      final gameId = map['gameId'] as String?;
      if (gameId == null) return null;

      GameEntry? matchedGame;
      for (final g in games) {
        if (g.id == gameId) {
          matchedGame = g;
          break;
        }
      }

      // Keep the pinned recommendation only while its status remains backlog.
      // Any transition to playing/completed/mastered/abandoned (or wishlist/deleted) triggers a fresh ML run.
      if (matchedGame == null || matchedGame.status != GameStatus.backlog) {
        return null;
      }

      final matchScore = (map['matchScore'] as num?)?.toDouble() ?? 0.75;
      final predictedRating = (map['predictedRating'] as num?)?.toDouble() ?? 7.5;
      final primaryReason =
          map['primaryReason'] as String? ?? 'Recommended from your backlog';
      final factors = (map['matchingFactors'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const <String>[];

      return BacklogRecommendation(
        game: matchedGame,
        matchScore: matchScore,
        predictedRating: predictedRating,
        primaryReason: primaryReason,
        matchingFactors: factors,
      );
    } catch (_) {
      return null;
    }
  }

  static BacklogRecommendation? _resolveOrCompute({
    required SettingsRepository settingsRepo,
    required List<GameEntry> games,
    required String primaryCurrency,
    required ExchangeRates? exchangeRates,
  }) {
    final cached = _tryHydrateFromStorage(settingsRepo, games);
    if (cached != null) return cached;

    final fresh = BacklogMlRecommender.recommend(
      games: games,
      primaryCurrency: primaryCurrency,
      exchangeRates: exchangeRates,
    );

    if (fresh != null) {
      settingsRepo.setBacklogRecommendationJson(jsonEncode(fresh.toJson()));
    } else if (settingsRepo.backlogRecommendationJson != null) {
      settingsRepo.clearBacklogRecommendation();
    }

    return fresh;
  }

  void onLibraryChanged(List<GameEntry> games) {
    final current = state;
    if (current != null) {
      GameEntry? updatedCurrent;
      for (final g in games) {
        if (g.id == current.game.id) {
          updatedCurrent = g;
          break;
        }
      }

      // Only re-run the recommender when the recommended game's status leaves Backlog
      // (playing / completed / mastered / abandoned) or it is removed.
      if (updatedCurrent != null && updatedCurrent.status == GameStatus.backlog) {
        if (updatedCurrent != current.game) {
          state = current.copyWith(game: updatedCurrent);
        }
        return;
      }
    } else {
      final hasBacklog = games.any((g) => g.status == GameStatus.backlog);
      if (!hasBacklog) return;
    }

    final next = BacklogMlRecommender.recommend(
      games: games,
      primaryCurrency: _primaryCurrency,
      exchangeRates: _exchangeRates,
    );

    state = next;
    if (next != null) {
      _settingsRepo.setBacklogRecommendationJson(jsonEncode(next.toJson()));
    } else {
      _settingsRepo.clearBacklogRecommendation();
    }
  }
}

class AnalyticsEngine {
  static double computeMedian(List<double> values) {
    if (values.isEmpty) return 0.0;
    final sorted = List<double>.from(values)..sort();
    final middle = sorted.length ~/ 2;
    if (sorted.length % 2 == 1) {
      return sorted[middle];
    } else {
      return (sorted[middle - 1] + sorted[middle]) / 2.0;
    }
  }

  static AnalyticsState compute({
    required List<GameEntry> games,
    required String primaryCurrency,
    ExchangeRates? exchangeRates,
    required AnalyticsTab currentTab,
  }) {
    if (games.isEmpty) {
      return AnalyticsState(
        currentTab: currentTab,
        primaryCurrency: primaryCurrency,
      );
    }

    double convertSpend(GameEntry g, double amount) {
      return CurrencyHelper.convert(
        amount: amount,
        fromCurrency: g.currency,
        toCurrency: primaryCurrency,
        rates: exchangeRates,
      );
    }

    double convertGameSpend(GameEntry g) {
      return convertSpend(g, g.totalSpent);
    }

    double normalizedCostPerHour(GameEntry g) {
      if (g.costPerHour == null) return 999999.0;
      return convertSpend(g, g.costPerHour!);
    }

    // 1. General Totals & KPIs
    int totalMinutesPlayed = 0;
    double totalInvested = 0.0;
    int playedMinutes = 0;
    double playedSpend = 0.0;

    for (final game in games) {
      final spend = convertGameSpend(game);
      totalInvested += spend;
      totalMinutesPlayed += game.totalMinutesPlayed;

      if (game.totalMinutesPlayed > 0) {
        playedMinutes += game.totalMinutesPlayed;
        playedSpend += spend;
      }
    }

    final playedGames = games.where((g) => g.totalMinutesPlayed > 0).toList();
    final averageCostPerHour =
        playedMinutes > 0 ? (playedSpend / (playedMinutes / 60.0)) : 0.0;

    final playedHoursList =
        playedGames.map((g) => g.totalMinutesPlayed / 60.0).toList();
    final averagePlaytimeHours =
        playedGames.isNotEmpty ? (totalMinutesPlayed / 60.0) / playedGames.length : 0.0;
    final medianPlaytimeHours = computeMedian(playedHoursList);

    // Top 3 games playtime share
    final sortedByPlaytime = List<GameEntry>.from(playedGames)
      ..sort((a, b) => b.totalMinutesPlayed.compareTo(a.totalMinutesPlayed));
    final top3Minutes =
        sortedByPlaytime.take(3).fold<int>(0, (sum, g) => sum + g.totalMinutesPlayed);
    final top3GamesSharePercent =
        totalMinutesPlayed > 0 ? (top3Minutes / totalMinutesPlayed) * 100.0 : 0.0;

    // 2. Playtime Commitment Buckets (5 tiers)
    final bucketMap = <PlaytimeBucket, List<GameEntry>>{
      for (final b in PlaytimeBucket.values) b: [],
    };

    for (final game in playedGames) {
      final h = game.totalMinutesPlayed / 60.0;
      if (h < 5.0) {
        bucketMap[PlaytimeBucket.biteSized]!.add(game);
      } else if (h < 20.0) {
        bucketMap[PlaytimeBucket.shortCampaign]!.add(game);
      } else if (h < 50.0) {
        bucketMap[PlaytimeBucket.deepDive]!.add(game);
      } else if (h < 100.0) {
        bucketMap[PlaytimeBucket.epicOdyssey]!.add(game);
      } else {
        bucketMap[PlaytimeBucket.endlessVoid]!.add(game);
      }
    }

    final playtimeBuckets = PlaytimeBucket.values.map((bucket) {
      final bucketGames = bucketMap[bucket]!;
      final count = bucketGames.length;
      final minutes = bucketGames.fold<int>(0, (sum, g) => sum + g.totalMinutesPlayed);
      final percentage =
          playedGames.isNotEmpty ? (count / playedGames.length) * 100.0 : 0.0;

      return PlaytimeBucketData(
        bucket: bucket,
        count: count,
        totalMinutes: minutes,
        percentage: percentage,
        games: bucketGames,
      );
    }).toList();

    // 3. Genre Analytics
    final genreMinutesMap = <String, int>{};
    final genreGamesCountMap = <String, int>{};
    final genreRatingsMap = <String, List<double>>{};

    for (final game in games) {
      if (game.genres.isEmpty) continue;
      for (final rawGenre in game.genres) {
        final genre = rawGenre.trim();
        if (genre.isEmpty) continue;

        genreMinutesMap[genre] = (genreMinutesMap[genre] ?? 0) + game.totalMinutesPlayed;
        genreGamesCountMap[genre] = (genreGamesCountMap[genre] ?? 0) + 1;

        if (game.personalRating > 0) {
          genreRatingsMap.putIfAbsent(genre, () => []).add(game.personalRating);
        }
      }
    }

    final topGenres = genreMinutesMap.entries.map((entry) {
      final genre = entry.key;
      final minutes = entry.value;
      final count = genreGamesCountMap[genre] ?? 0;
      final ratings = genreRatingsMap[genre] ?? [];
      final avgRating =
          ratings.isNotEmpty ? (ratings.reduce((a, b) => a + b) / ratings.length) : null;

      return GenreAnalyticsData(
        genre: genre,
        totalMinutes: minutes,
        gamesCount: count,
        averageRating: avgRating,
        ratedGamesCount: ratings.length,
      );
    }).toList()
      ..sort((a, b) {
        final cmp = b.totalMinutes.compareTo(a.totalMinutes);
        if (cmp != 0) return cmp;
        return b.gamesCount.compareTo(a.gamesCount);
      });

    // 4. Rating & Joy (Summary, Distribution, Top Rated & Joy-Per-Dollar)
    final ratedGames = games.where((g) => g.personalRating > 0).toList()
      ..sort((a, b) {
        final cmp = b.personalRating.compareTo(a.personalRating);
        if (cmp != 0) return cmp;
        return b.totalMinutesPlayed.compareTo(a.totalMinutesPlayed);
      });
    final allRatings = ratedGames.map((g) => g.personalRating).toList();
    final averagePersonalRating = allRatings.isNotEmpty
        ? (allRatings.reduce((a, b) => a + b) / allRatings.length)
        : 0.0;
    final medianRating = computeMedian(allRatings);

    int masterpiecesCount = 0;
    int greatCount = 0;
    int decentCount = 0;
    int modestCount = 0;
    for (final r in allRatings) {
      if (r >= 9.0) {
        masterpiecesCount++;
      } else if (r >= 7.5) {
        greatCount++;
      } else if (r >= 6.0) {
        decentCount++;
      } else {
        modestCount++;
      }
    }
    final totalRated = allRatings.length;
    final ratingDistribution = <RatingBucketData>[
      RatingBucketData(
        label: 'Masterpieces',
        rangeLabel: '9.0 – 10.0 ★',
        count: masterpiecesCount,
        percentage: totalRated > 0 ? (masterpiecesCount / totalRated) * 100.0 : 0.0,
      ),
      RatingBucketData(
        label: 'Great',
        rangeLabel: '7.5 – 8.9 ★',
        count: greatCount,
        percentage: totalRated > 0 ? (greatCount / totalRated) * 100.0 : 0.0,
      ),
      RatingBucketData(
        label: 'Decent',
        rangeLabel: '6.0 – 7.4 ★',
        count: decentCount,
        percentage: totalRated > 0 ? (decentCount / totalRated) * 100.0 : 0.0,
      ),
      RatingBucketData(
        label: 'Modest',
        rangeLabel: '< 6.0 ★',
        count: modestCount,
        percentage: totalRated > 0 ? (modestCount / totalRated) * 100.0 : 0.0,
      ),
    ];

    // Joy-Per-Dollar (for paid games with active playtime and rating)
    final paidRatedGames = games
        .where((g) => g.totalSpent > 0 && g.personalRating > 0 && g.totalMinutesPlayed > 0)
        .toList();
    final topJoyPerDollar = paidRatedGames.map((g) {
      final cost = convertGameSpend(g);
      final joyScore = cost > 0 ? (g.personalRating / cost) : 0.0;
      return JoyPerDollarEntry(
        game: g,
        joyScore: joyScore,
        rating: g.personalRating,
        convertedCost: cost,
      );
    }).toList()
      ..sort((a, b) => b.joyScore.compareTo(a.joyScore));

    // 5. Backlog & Pipeline
    final statusCounts = <GameStatus, int>{
      for (final s in GameStatus.values) s: 0,
    };
    for (final game in games) {
      statusCounts[game.status] = (statusCounts[game.status] ?? 0) + 1;
    }

    final completedCount =
        (statusCounts[GameStatus.completed] ?? 0) + (statusCounts[GameStatus.mastered] ?? 0);
    final completionRate = games.isNotEmpty ? (completedCount / games.length) * 100.0 : 0.0;

    final abandonedGames = games.where((g) => g.status == GameStatus.abandoned).toList();
    final abandonedMinutes =
        abandonedGames.fold<int>(0, (sum, g) => sum + g.totalMinutesPlayed);
    final abandonedSpend =
        abandonedGames.fold<double>(0.0, (sum, g) => sum + convertGameSpend(g));
    final abandonedHoursTaxPercent =
        totalMinutesPlayed > 0 ? (abandonedMinutes / totalMinutesPlayed) * 100.0 : 0.0;

    double backlogCapital = 0.0;
    for (final game in games) {
      final spend = convertGameSpend(game);
      if (game.status == GameStatus.backlog ||
          (game.totalMinutesPlayed == 0 &&
              game.totalSpent > 0 &&
              game.status != GameStatus.wishlist)) {
        backlogCapital += spend;
      }
    }

    // 6. Storefront Breakdown & Top Storefront
    final storefrontCounts = <Storefront, int>{};
    final storefrontSpend = <Storefront, double>{};
    final storefrontMinutes = <Storefront, int>{};

    for (final game in games) {
      final sf = game.storefront;
      storefrontCounts[sf] = (storefrontCounts[sf] ?? 0) + 1;
      storefrontSpend[sf] = (storefrontSpend[sf] ?? 0.0) + convertGameSpend(game);
      storefrontMinutes[sf] = (storefrontMinutes[sf] ?? 0) + game.totalMinutesPlayed;
    }

    StorefrontAnalyticsData? topStorefront;
    if (storefrontCounts.isNotEmpty) {
      final sortedStorefronts = storefrontCounts.keys.toList()
        ..sort((a, b) {
          final cmp = (storefrontCounts[b] ?? 0).compareTo(storefrontCounts[a] ?? 0);
          if (cmp != 0) return cmp;
          return (storefrontSpend[b] ?? 0.0).compareTo(storefrontSpend[a] ?? 0.0);
        });
      final bestSf = sortedStorefronts.first;
      topStorefront = StorefrontAnalyticsData(
        storefront: bestSf,
        count: storefrontCounts[bestSf] ?? 0,
        totalSpend: storefrontSpend[bestSf] ?? 0.0,
        totalMinutes: storefrontMinutes[bestSf] ?? 0,
      );
    }

    final backlogCapitalPercent =
        totalInvested > 0 ? (backlogCapital / totalInvested) * 100.0 : 0.0;
    final playedGamesCount = playedGames.length;
    final unplayedGamesCount = games.length - playedGamesCount;

    // 7. Superlatives & Accolades
    // The Infinite Value: lowest cost/hr with totalSpent > 0 and playtime > 0
    final validRoiGames = games
        .where((g) => g.totalMinutesPlayed > 0 && g.totalSpent > 0 && g.costPerHour != null)
        .toList()
      ..sort((a, b) => normalizedCostPerHour(a).compareTo(normalizedCostPerHour(b)));
    final infiniteValueGame = validRoiGames.isNotEmpty ? validRoiGames.first : null;
    final infiniteValueCostPerHour =
        infiniteValueGame != null ? normalizedCostPerHour(infiniteValueGame) : null;

    // The Black Hole: most played
    final blackHoleGame = sortedByPlaytime.isNotEmpty ? sortedByPlaytime.first : null;

    // The Money Pit: highest cost/hr with playtime > 0
    final moneyPitGame = validRoiGames.isNotEmpty ? validRoiGames.last : null;
    final moneyPitCostPerHour =
        moneyPitGame != null ? normalizedCostPerHour(moneyPitGame) : null;

    // The Golden Freebie: totalSpent == 0 with most playtime
    final freeGamesWithPlaytime = games
        .where((g) => g.totalSpent <= 0 && g.totalMinutesPlayed > 0)
        .toList()
      ..sort((a, b) => b.totalMinutesPlayed.compareTo(a.totalMinutesPlayed));
    final goldenFreebieGame =
        freeGamesWithPlaytime.isNotEmpty ? freeGamesWithPlaytime.first : null;

    // The Masterpiece: highest rating among completed or mastered
    final completedGames = games
        .where((g) =>
            (g.status == GameStatus.completed || g.status == GameStatus.mastered) &&
            g.personalRating > 0)
        .toList()
      ..sort((a, b) {
        final cmp = b.personalRating.compareTo(a.personalRating);
        if (cmp != 0) return cmp;
        return b.totalMinutesPlayed.compareTo(a.totalMinutesPlayed);
      });
    final masterpieceGame = completedGames.isNotEmpty ? completedGames.first : null;

    // The DLC Collector: game with most DLC / extra spend
    final dlcGames = games.where((g) => g.additionalExpenses.isNotEmpty).toList()
      ..sort((a, b) {
        final aExtra = a.additionalExpenses.fold<double>(0.0, (sum, e) => sum + e.amount);
        final bExtra = b.additionalExpenses.fold<double>(0.0, (sum, e) => sum + e.amount);
        return convertSpend(b, bExtra).compareTo(convertSpend(a, aExtra));
      });
    final dlcCollectorGame = dlcGames.isNotEmpty ? dlcGames.first : null;
    final dlcCollectorSpend = dlcCollectorGame != null
        ? convertSpend(
            dlcCollectorGame,
            dlcCollectorGame.additionalExpenses
                .fold<double>(0.0, (sum, e) => sum + e.amount),
          )
        : null;

    return AnalyticsState(
      currentTab: currentTab,
      primaryCurrency: primaryCurrency,
      totalGamesCount: games.length,
      totalMinutesPlayed: totalMinutesPlayed,
      totalInvested: totalInvested,
      averageCostPerHour: averageCostPerHour,
      averagePlaytimeHours: averagePlaytimeHours,
      medianPlaytimeHours: medianPlaytimeHours,
      top3GamesSharePercent: top3GamesSharePercent,
      playedGamesCount: playedGamesCount,
      unplayedGamesCount: unplayedGamesCount,
      backlogCapitalPercent: backlogCapitalPercent,
      topStorefront: topStorefront,
      playtimeBuckets: playtimeBuckets,
      topGenres: topGenres,
      medianRating: medianRating,
      topJoyPerDollar: topJoyPerDollar.take(5).toList(),
      averagePersonalRating: averagePersonalRating,
      totalRatedGames: allRatings.length,
      ratingDistribution: ratingDistribution,
      topRatedGames: ratedGames.take(5).toList(),
      statusCounts: statusCounts,
      completionRate: completionRate,
      abandonedCount: abandonedGames.length,
      abandonedMinutes: abandonedMinutes,
      abandonedSpend: abandonedSpend,
      abandonedHoursTaxPercent: abandonedHoursTaxPercent,
      backlogCapital: backlogCapital,
      infiniteValueGame: infiniteValueGame,
      infiniteValueCostPerHour: infiniteValueCostPerHour,
      blackHoleGame: blackHoleGame,
      moneyPitGame: moneyPitGame,
      moneyPitCostPerHour: moneyPitCostPerHour,
      goldenFreebieGame: goldenFreebieGame,
      masterpieceGame: masterpieceGame,
      dlcCollectorGame: dlcCollectorGame,
      dlcCollectorSpend: dlcCollectorSpend,
    );
  }
}
