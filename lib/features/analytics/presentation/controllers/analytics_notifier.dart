import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/exchange_rate_service.dart';
import '../../../../core/utils/currency_helper.dart';
import '../../../sync/presentation/controllers/settings_notifier.dart';
import '../../../tracker/domain/models/game_entry.dart';
import '../../../tracker/domain/models/game_status.dart';
import '../../../tracker/presentation/controllers/library_notifier.dart';
import 'analytics_state.dart';

final analyticsTabProvider = StateProvider<AnalyticsTab>((ref) => AnalyticsTab.playtimeHabits);

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
    final averageCostPerHour = playedMinutes > 0 ? (playedSpend / (playedMinutes / 60.0)) : 0.0;

    final playedHoursList = playedGames.map((g) => g.totalMinutesPlayed / 60.0).toList();
    final averagePlaytimeHours = playedGames.isNotEmpty ? (totalMinutesPlayed / 60.0) / playedGames.length : 0.0;
    final medianPlaytimeHours = computeMedian(playedHoursList);

    // Top 3 games playtime share
    final sortedByPlaytime = List<GameEntry>.from(playedGames)
      ..sort((a, b) => b.totalMinutesPlayed.compareTo(a.totalMinutesPlayed));
    final top3Minutes = sortedByPlaytime.take(3).fold<int>(0, (sum, g) => sum + g.totalMinutesPlayed);
    final top3GamesSharePercent = totalMinutesPlayed > 0 ? (top3Minutes / totalMinutesPlayed) * 100.0 : 0.0;

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
      final percentage = playedGames.isNotEmpty ? (count / playedGames.length) * 100.0 : 0.0;

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
      final avgRating = ratings.isNotEmpty ? (ratings.reduce((a, b) => a + b) / ratings.length) : null;

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

    // 4. Rating & Joy (The Golden Quadrant & Joy-Per-Dollar)
    final ratedPlayedGames = games.where((g) => g.totalMinutesPlayed > 0 && g.personalRating > 0).toList();
    final allRatings = games.where((g) => g.personalRating > 0).map((g) => g.personalRating).toList();
    final averagePersonalRating = allRatings.isNotEmpty ? (allRatings.reduce((a, b) => a + b) / allRatings.length) : 0.0;
    final medianRating = computeMedian(allRatings);

    // Median-Adaptive Thresholds
    final hoursThreshold = (medianPlaytimeHours > 0 ? medianPlaytimeHours : 15.0).clamp(8.0, 50.0);
    final ratingThreshold = (medianRating > 0 ? medianRating : 7.5).clamp(7.0, 8.5);

    final quadrantMap = <QuadrantCategory, List<QuadrantGameEntry>>{
      for (final cat in QuadrantCategory.values) cat: [],
    };

    for (final game in ratedPlayedGames) {
      final hours = game.totalMinutesPlayed / 60.0;
      final rating = game.personalRating;

      final QuadrantCategory category;
      if (hours >= hoursThreshold && rating >= ratingThreshold) {
        category = QuadrantCategory.timelessMasterpiece;
      } else if (hours < hoursThreshold && rating >= ratingThreshold) {
        category = QuadrantCategory.sweetShortGem;
      } else if (hours >= hoursThreshold && rating < ratingThreshold) {
        category = QuadrantCategory.timeTrap;
      } else {
        category = QuadrantCategory.earlyDrop;
      }

      quadrantMap[category]!.add(
        QuadrantGameEntry(
          game: game,
          category: category,
          hours: hours,
          rating: rating,
        ),
      );
    }

    // Joy-Per-Dollar (for paid games with active playtime and rating)
    final paidRatedGames = games.where((g) => g.totalSpent > 0 && g.personalRating > 0 && g.totalMinutesPlayed > 0).toList();
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

    final completedCount = (statusCounts[GameStatus.completed] ?? 0) + (statusCounts[GameStatus.mastered] ?? 0);
    final completionRate = games.isNotEmpty ? (completedCount / games.length) * 100.0 : 0.0;

    final abandonedGames = games.where((g) => g.status == GameStatus.abandoned).toList();
    final abandonedMinutes = abandonedGames.fold<int>(0, (sum, g) => sum + g.totalMinutesPlayed);
    final abandonedSpend = abandonedGames.fold<double>(0.0, (sum, g) => sum + convertGameSpend(g));
    final abandonedHoursTaxPercent = totalMinutesPlayed > 0 ? (abandonedMinutes / totalMinutesPlayed) * 100.0 : 0.0;

    double backlogCapital = 0.0;
    final backlogGames = <GameEntry>[];
    for (final game in games) {
      final spend = convertGameSpend(game);
      if (game.status == GameStatus.backlog || (game.totalMinutesPlayed == 0 && game.totalSpent > 0)) {
        backlogCapital += spend;
        if (game.totalMinutesPlayed == 0) {
          backlogGames.add(game);
        }
      }
    }

    // Next quick win: unplayed game, prioritizing highest personal interest or added date
    GameEntry? nextQuickWin;
    if (backlogGames.isNotEmpty) {
      backlogGames.sort((a, b) {
        if (a.personalRating != b.personalRating) {
          return b.personalRating.compareTo(a.personalRating);
        }
        return b.addedAt.compareTo(a.addedAt);
      });
      nextQuickWin = backlogGames.first;
    }

    // 6. Superlatives & Accolades
    // The Infinite Value: lowest cost/hr with totalSpent > 0 and playtime > 0
    final validRoiGames = games.where((g) => g.totalMinutesPlayed > 0 && g.totalSpent > 0 && g.costPerHour != null).toList()
      ..sort((a, b) => normalizedCostPerHour(a).compareTo(normalizedCostPerHour(b)));
    final infiniteValueGame = validRoiGames.isNotEmpty ? validRoiGames.first : null;
    final infiniteValueCostPerHour = infiniteValueGame != null ? normalizedCostPerHour(infiniteValueGame) : null;

    // The Black Hole: most played
    final blackHoleGame = sortedByPlaytime.isNotEmpty ? sortedByPlaytime.first : null;

    // The Money Pit: highest cost/hr with playtime > 0
    final moneyPitGame = validRoiGames.isNotEmpty ? validRoiGames.last : null;
    final moneyPitCostPerHour = moneyPitGame != null ? normalizedCostPerHour(moneyPitGame) : null;

    // The Golden Freebie: totalSpent == 0 with most playtime
    final freeGamesWithPlaytime = games.where((g) => g.totalSpent <= 0 && g.totalMinutesPlayed > 0).toList()
      ..sort((a, b) => b.totalMinutesPlayed.compareTo(a.totalMinutesPlayed));
    final goldenFreebieGame = freeGamesWithPlaytime.isNotEmpty ? freeGamesWithPlaytime.first : null;

    // The Masterpiece: highest rating among completed or mastered
    final completedGames = games.where((g) => (g.status == GameStatus.completed || g.status == GameStatus.mastered) && g.personalRating > 0).toList()
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
            dlcCollectorGame.additionalExpenses.fold<double>(0.0, (sum, e) => sum + e.amount),
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
      playtimeBuckets: playtimeBuckets,
      topGenres: topGenres,
      medianRating: medianRating,
      ratingThreshold: ratingThreshold,
      hoursThreshold: hoursThreshold,
      quadrantGames: quadrantMap,
      topJoyPerDollar: topJoyPerDollar.take(5).toList(),
      averagePersonalRating: averagePersonalRating,
      totalRatedGames: allRatings.length,
      statusCounts: statusCounts,
      completionRate: completionRate,
      abandonedCount: abandonedGames.length,
      abandonedMinutes: abandonedMinutes,
      abandonedSpend: abandonedSpend,
      abandonedHoursTaxPercent: abandonedHoursTaxPercent,
      backlogCapital: backlogCapital,
      nextQuickWin: nextQuickWin,
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
