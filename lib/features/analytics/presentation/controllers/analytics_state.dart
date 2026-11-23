import '../../../tracker/domain/models/game_entry.dart';
import '../../../tracker/domain/models/game_status.dart';

enum AnalyticsTab {
  playtimeHabits('Playtime & Habits'),
  ratingJoy('Rating & Joy'),
  backlogPipeline('Backlog & Pipeline'),
  superlatives('Superlatives');

  final String label;
  const AnalyticsTab(this.label);
}

enum QuadrantCategory {
  timelessMasterpiece('Timeless Masterpieces', 'High Time • High Rating'),
  sweetShortGem('Sweet & Short Gems', 'Low Time • High Rating'),
  timeTrap('Time Traps / Grinds', 'High Time • Modest Rating'),
  earlyDrop('Early Drops / Misses', 'Low Time • Modest Rating');

  final String title;
  final String subtitle;
  const QuadrantCategory(this.title, this.subtitle);
}

class QuadrantGameEntry {
  final GameEntry game;
  final QuadrantCategory category;
  final double hours;
  final double rating;

  const QuadrantGameEntry({
    required this.game,
    required this.category,
    required this.hours,
    required this.rating,
  });
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

class AnalyticsState {
  final AnalyticsTab currentTab;
  final String primaryCurrency;

  // General KPIs
  final int totalGamesCount;
  final int totalMinutesPlayed;
  final double totalInvested;
  final double averageCostPerHour;
  final double averagePlaytimeHours;
  final double medianPlaytimeHours;
  final double top3GamesSharePercent;

  // 1. Playtime & Habits
  final List<PlaytimeBucketData> playtimeBuckets;
  final List<GenreAnalyticsData> topGenres;

  // 2. Rating & Joy
  final double medianRating;
  final double ratingThreshold;
  final double hoursThreshold;
  final Map<QuadrantCategory, List<QuadrantGameEntry>> quadrantGames;
  final List<JoyPerDollarEntry> topJoyPerDollar;
  final double averagePersonalRating;
  final int totalRatedGames;

  // 3. Backlog & Pipeline
  final Map<GameStatus, int> statusCounts;
  final double completionRate;
  final int abandonedCount;
  final int abandonedMinutes;
  final double abandonedSpend;
  final double abandonedHoursTaxPercent;
  final double backlogCapital;
  final GameEntry? nextQuickWin;

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
    this.currentTab = AnalyticsTab.playtimeHabits,
    this.primaryCurrency = 'USD',
    this.totalGamesCount = 0,
    this.totalMinutesPlayed = 0,
    this.totalInvested = 0.0,
    this.averageCostPerHour = 0.0,
    this.averagePlaytimeHours = 0.0,
    this.medianPlaytimeHours = 0.0,
    this.top3GamesSharePercent = 0.0,
    this.playtimeBuckets = const [],
    this.topGenres = const [],
    this.medianRating = 0.0,
    this.ratingThreshold = 7.5,
    this.hoursThreshold = 15.0,
    this.quadrantGames = const {},
    this.topJoyPerDollar = const [],
    this.averagePersonalRating = 0.0,
    this.totalRatedGames = 0,
    this.statusCounts = const {},
    this.completionRate = 0.0,
    this.abandonedCount = 0,
    this.abandonedMinutes = 0,
    this.abandonedSpend = 0.0,
    this.abandonedHoursTaxPercent = 0.0,
    this.backlogCapital = 0.0,
    this.nextQuickWin,
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
    List<PlaytimeBucketData>? playtimeBuckets,
    List<GenreAnalyticsData>? topGenres,
    double? medianRating,
    double? ratingThreshold,
    double? hoursThreshold,
    Map<QuadrantCategory, List<QuadrantGameEntry>>? quadrantGames,
    List<JoyPerDollarEntry>? topJoyPerDollar,
    double? averagePersonalRating,
    int? totalRatedGames,
    Map<GameStatus, int>? statusCounts,
    double? completionRate,
    int? abandonedCount,
    int? abandonedMinutes,
    double? abandonedSpend,
    double? abandonedHoursTaxPercent,
    double? backlogCapital,
    GameEntry? nextQuickWin,
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
      playtimeBuckets: playtimeBuckets ?? this.playtimeBuckets,
      topGenres: topGenres ?? this.topGenres,
      medianRating: medianRating ?? this.medianRating,
      ratingThreshold: ratingThreshold ?? this.ratingThreshold,
      hoursThreshold: hoursThreshold ?? this.hoursThreshold,
      quadrantGames: quadrantGames ?? this.quadrantGames,
      topJoyPerDollar: topJoyPerDollar ?? this.topJoyPerDollar,
      averagePersonalRating: averagePersonalRating ?? this.averagePersonalRating,
      totalRatedGames: totalRatedGames ?? this.totalRatedGames,
      statusCounts: statusCounts ?? this.statusCounts,
      completionRate: completionRate ?? this.completionRate,
      abandonedCount: abandonedCount ?? this.abandonedCount,
      abandonedMinutes: abandonedMinutes ?? this.abandonedMinutes,
      abandonedSpend: abandonedSpend ?? this.abandonedSpend,
      abandonedHoursTaxPercent: abandonedHoursTaxPercent ?? this.abandonedHoursTaxPercent,
      backlogCapital: backlogCapital ?? this.backlogCapital,
      nextQuickWin: nextQuickWin ?? this.nextQuickWin,
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
