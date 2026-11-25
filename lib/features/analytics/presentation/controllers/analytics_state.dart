import '../../../tracker/domain/models/game_entry.dart';
import '../../../tracker/domain/models/game_status.dart';
import '../../../tracker/domain/models/storefront.dart';

enum AnalyticsTab {
  overview('Overview'),
  playtimeHabits('Playtime & Habits'),
  ratingJoy('Rating & Joy'),
  backlogPipeline('Backlog & Pipeline'),
  superlatives('Superlatives');

  final String label;
  const AnalyticsTab(this.label);
}

enum PlaytimeBucket {
  biteSized('Bite-Sized', '< 5 hrs', 0, 5),
  shortCampaign('Short Campaign', '5–20 hrs', 5, 20),
  deepDive('Deep Dive', '20–50 hrs', 20, 50),
  epicOdyssey('Epic Odyssey', '50–100 hrs', 50, 100),
  endlessVoid('Endless Void', '100+ hrs', 100, 999999);

  final String label;
  final String rangeLabel;
  final int minHours;
  final int maxHours;
  const PlaytimeBucket(this.label, this.rangeLabel, this.minHours, this.maxHours);
}

class PlaytimeBucketData {
  final PlaytimeBucket bucket;
  final int count;
  final int totalMinutes;
  final double percentage;
  final List<GameEntry> games;

  const PlaytimeBucketData({
    required this.bucket,
    required this.count,
    required this.totalMinutes,
    required this.percentage,
    required this.games,
  });

  double get totalHours => totalMinutes / 60.0;
}

class GenreAnalyticsData {
  final String genre;
  final int totalMinutes;
  final int gamesCount;
  final double? averageRating;
  final int ratedGamesCount;

  const GenreAnalyticsData({
    required this.genre,
    required this.totalMinutes,
    required this.gamesCount,
    this.averageRating,
    required this.ratedGamesCount,
  });

  double get totalHours => totalMinutes / 60.0;
}

class StorefrontAnalyticsData {
  final Storefront storefront;
  final int count;
  final double totalSpend;
  final int totalMinutes;

  const StorefrontAnalyticsData({
    required this.storefront,
    required this.count,
    required this.totalSpend,
    required this.totalMinutes,
  });

  double get totalHours => totalMinutes / 60.0;
}

class JoyPerDollarEntry {
  final GameEntry game;
  final double joyScore; // rating / cost
  final double rating;
  final double convertedCost;

  const JoyPerDollarEntry({
    required this.game,
    required this.joyScore,
    required this.rating,
    required this.convertedCost,
  });
}

class RatingBucketData {
  final String label;
  final String rangeLabel;
  final int count;
  final double percentage;

  const RatingBucketData({
    required this.label,
    required this.rangeLabel,
    required this.count,
    required this.percentage,
  });
}

class AnalyticsState {
  final AnalyticsTab currentTab;
  final String primaryCurrency;

  // General KPIs (The Core Big 4 & Overview)
  final int totalGamesCount;
  final int totalMinutesPlayed;
  final double totalInvested;
  final double averageCostPerHour;
  final double averagePlaytimeHours;
  final double medianPlaytimeHours;
  final double top3GamesSharePercent;
  final int playedGamesCount;
  final int unplayedGamesCount;
  final double backlogCapitalPercent;
  final StorefrontAnalyticsData? topStorefront;

  // 1. Playtime & Habits
  final List<PlaytimeBucketData> playtimeBuckets;
  final List<GenreAnalyticsData> topGenres;

  // 2. Rating & Joy
  final double medianRating;
  final List<JoyPerDollarEntry> topJoyPerDollar;
  final double averagePersonalRating;
  final int totalRatedGames;
  final List<RatingBucketData> ratingDistribution;
  final List<GameEntry> topRatedGames;

  // 3. Backlog & Pipeline
  final Map<GameStatus, int> statusCounts;
  final double completionRate;
  final int abandonedCount;
  final int abandonedMinutes;
  final double abandonedSpend;
  final double abandonedHoursTaxPercent;
  final double backlogCapital;

  // 4. Superlatives
  final GameEntry? infiniteValueGame;
  final double? infiniteValueCostPerHour;
  final GameEntry? blackHoleGame;
  final GameEntry? moneyPitGame;
  final double? moneyPitCostPerHour;
  final GameEntry? goldenFreebieGame;
  final GameEntry? masterpieceGame;
  final GameEntry? dlcCollectorGame;
  final double? dlcCollectorSpend;

  const AnalyticsState({
    this.currentTab = AnalyticsTab.overview,
    this.primaryCurrency = 'USD',
    this.totalGamesCount = 0,
    this.totalMinutesPlayed = 0,
    this.totalInvested = 0.0,
    this.averageCostPerHour = 0.0,
    this.averagePlaytimeHours = 0.0,
    this.medianPlaytimeHours = 0.0,
    this.top3GamesSharePercent = 0.0,
    this.playedGamesCount = 0,
    this.unplayedGamesCount = 0,
    this.backlogCapitalPercent = 0.0,
    this.topStorefront,
    this.playtimeBuckets = const [],
    this.topGenres = const [],
    this.medianRating = 0.0,
    this.topJoyPerDollar = const [],
    this.averagePersonalRating = 0.0,
    this.totalRatedGames = 0,
    this.ratingDistribution = const [],
    this.topRatedGames = const [],
    this.statusCounts = const {},
    this.completionRate = 0.0,
    this.abandonedCount = 0,
    this.abandonedMinutes = 0,
    this.abandonedSpend = 0.0,
    this.abandonedHoursTaxPercent = 0.0,
    this.backlogCapital = 0.0,
    this.infiniteValueGame,
    this.infiniteValueCostPerHour,
    this.blackHoleGame,
    this.moneyPitGame,
    this.moneyPitCostPerHour,
    this.goldenFreebieGame,
    this.masterpieceGame,
    this.dlcCollectorGame,
    this.dlcCollectorSpend,
  });

  double get totalHoursPlayed => totalMinutesPlayed / 60.0;
  double get totalDaysPlayed => totalHoursPlayed / 24.0;
  double get abandonedHours => abandonedMinutes / 60.0;

  AnalyticsState copyWith({
    AnalyticsTab? currentTab,
    String? primaryCurrency,
    int? totalGamesCount,
    int? totalMinutesPlayed,
    double? totalInvested,
    double? averageCostPerHour,
    double? averagePlaytimeHours,
    double? medianPlaytimeHours,
    double? top3GamesSharePercent,
    int? playedGamesCount,
    int? unplayedGamesCount,
    double? backlogCapitalPercent,
    StorefrontAnalyticsData? topStorefront,
    List<PlaytimeBucketData>? playtimeBuckets,
    List<GenreAnalyticsData>? topGenres,
    double? medianRating,
    List<JoyPerDollarEntry>? topJoyPerDollar,
    double? averagePersonalRating,
    int? totalRatedGames,
    List<RatingBucketData>? ratingDistribution,
    List<GameEntry>? topRatedGames,
    Map<GameStatus, int>? statusCounts,
    double? completionRate,
    int? abandonedCount,
    int? abandonedMinutes,
    double? abandonedSpend,
    double? abandonedHoursTaxPercent,
    double? backlogCapital,
    GameEntry? infiniteValueGame,
    double? infiniteValueCostPerHour,
    GameEntry? blackHoleGame,
    GameEntry? moneyPitGame,
    double? moneyPitCostPerHour,
    GameEntry? goldenFreebieGame,
    GameEntry? masterpieceGame,
    GameEntry? dlcCollectorGame,
    double? dlcCollectorSpend,
  }) {
    return AnalyticsState(
      currentTab: currentTab ?? this.currentTab,
      primaryCurrency: primaryCurrency ?? this.primaryCurrency,
      totalGamesCount: totalGamesCount ?? this.totalGamesCount,
      totalMinutesPlayed: totalMinutesPlayed ?? this.totalMinutesPlayed,
      totalInvested: totalInvested ?? this.totalInvested,
      averageCostPerHour: averageCostPerHour ?? this.averageCostPerHour,
      averagePlaytimeHours: averagePlaytimeHours ?? this.averagePlaytimeHours,
      medianPlaytimeHours: medianPlaytimeHours ?? this.medianPlaytimeHours,
      top3GamesSharePercent: top3GamesSharePercent ?? this.top3GamesSharePercent,
      playedGamesCount: playedGamesCount ?? this.playedGamesCount,
      unplayedGamesCount: unplayedGamesCount ?? this.unplayedGamesCount,
      backlogCapitalPercent: backlogCapitalPercent ?? this.backlogCapitalPercent,
      topStorefront: topStorefront ?? this.topStorefront,
      playtimeBuckets: playtimeBuckets ?? this.playtimeBuckets,
      topGenres: topGenres ?? this.topGenres,
      medianRating: medianRating ?? this.medianRating,
      topJoyPerDollar: topJoyPerDollar ?? this.topJoyPerDollar,
      averagePersonalRating: averagePersonalRating ?? this.averagePersonalRating,
      totalRatedGames: totalRatedGames ?? this.totalRatedGames,
      ratingDistribution: ratingDistribution ?? this.ratingDistribution,
      topRatedGames: topRatedGames ?? this.topRatedGames,
      statusCounts: statusCounts ?? this.statusCounts,
      completionRate: completionRate ?? this.completionRate,
      abandonedCount: abandonedCount ?? this.abandonedCount,
      abandonedMinutes: abandonedMinutes ?? this.abandonedMinutes,
      abandonedSpend: abandonedSpend ?? this.abandonedSpend,
      abandonedHoursTaxPercent: abandonedHoursTaxPercent ?? this.abandonedHoursTaxPercent,
      backlogCapital: backlogCapital ?? this.backlogCapital,
      infiniteValueGame: infiniteValueGame ?? this.infiniteValueGame,
      infiniteValueCostPerHour: infiniteValueCostPerHour ?? this.infiniteValueCostPerHour,
      blackHoleGame: blackHoleGame ?? this.blackHoleGame,
      moneyPitGame: moneyPitGame ?? this.moneyPitGame,
      moneyPitCostPerHour: moneyPitCostPerHour ?? this.moneyPitCostPerHour,
      goldenFreebieGame: goldenFreebieGame ?? this.goldenFreebieGame,
      masterpieceGame: masterpieceGame ?? this.masterpieceGame,
      dlcCollectorGame: dlcCollectorGame ?? this.dlcCollectorGame,
      dlcCollectorSpend: dlcCollectorSpend ?? this.dlcCollectorSpend,
    );
  }
}
