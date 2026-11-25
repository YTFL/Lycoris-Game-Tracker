import 'dart:math' as math;
import '../../../../core/services/exchange_rate_service.dart';
import '../../../../core/utils/currency_helper.dart';
import '../../../tracker/domain/models/game_entry.dart';
import '../../../tracker/domain/models/game_status.dart';
import '../models/backlog_recommendation.dart';

/// Lightweight, fast on-demand Ridge Regression (L2-regularized linear model)
/// trained on the user's past rated games to predict enjoyment for backlog titles.
class BacklogMlRecommender {
  static const double _regularizationLambda = 0.8;
  static const double _learningRate = 0.2;
  static const int _epochs = 60;

  /// Generates the single best backlog recommendation from [games].
  /// Strictly considers ONLY games with [GameStatus.backlog] and NEVER [GameStatus.wishlist].
  static BacklogRecommendation? recommend({
    required List<GameEntry> games,
    String primaryCurrency = 'USD',
    ExchangeRates? exchangeRates,
  }) {
    final candidates = games
        .where((g) => g.status == GameStatus.backlog)
        .toList();

    if (candidates.isEmpty) return null;

    // Train on past rated games (exclude wishlist and backlog unless no other rated games exist)
    var trainingGames = games
        .where(
          (g) =>
              g.personalRating > 0 &&
              g.status != GameStatus.wishlist &&
              g.status != GameStatus.backlog,
        )
        .toList();

    if (trainingGames.isEmpty) {
      trainingGames = games
          .where((g) => g.personalRating > 0 && g.status != GameStatus.wishlist)
          .toList();
    }

    // Cold-start fallback when user has not rated any games yet
    if (trainingGames.isEmpty) {
      final sorted = List<GameEntry>.from(candidates)
        ..sort((a, b) {
          final paidCmp = (b.totalSpent > 0 ? 1 : 0).compareTo(a.totalSpent > 0 ? 1 : 0);
          if (paidCmp != 0) return paidCmp;
          return b.addedAt.compareTo(a.addedAt);
        });
      final best = sorted.first;
      return BacklogRecommendation(
        game: best,
        matchScore: 0.72,
        predictedRating: 7.5,
        primaryReason: 'Ready to jump into from your backlog',
        matchingFactors: [
          best.storefront.label,
          if (best.genres.isNotEmpty) best.genres.first,
        ],
      );
    }

    // Build USD-normalized price helper for consistent price tiering
    double priceInUsd(GameEntry g) {
      return CurrencyHelper.convert(
        amount: g.totalSpent,
        fromCurrency: g.currency,
        toCurrency: 'USD',
        rates: exchangeRates,
      );
    }

    // Extract sparse feature vectors
    Map<String, double> extractFeatures(GameEntry g) {
      final features = <String, double>{};

      final cleanGenres = g.genres
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      if (cleanGenres.isNotEmpty) {
        final norm = 1.0 / math.sqrt(cleanGenres.length);
        for (final genre in cleanGenres) {
          features['genre:${genre.toLowerCase()}'] = norm;
        }
      }

      final cleanCats = g.customCategories
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      if (cleanCats.isNotEmpty) {
        final norm = 0.8 / math.sqrt(cleanCats.length);
        for (final cat in cleanCats) {
          features['cat:${cat.toLowerCase()}'] = norm;
        }
      }

      features['sf:${g.storefront.name}'] = 0.45;

      final usd = priceInUsd(g);
      if (usd <= 0.01) {
        features['price:free'] = 0.35;
      } else if (usd <= 15.0) {
        features['price:budget'] = 0.35;
      } else if (usd <= 40.0) {
        features['price:mid'] = 0.35;
      } else {
        features['price:aaa'] = 0.35;
      }

      return features;
    }

    // Precompute training vectors and sample weights (higher playtime = stronger signal)
    final trainVectors = <Map<String, double>>[];
    final trainRatings = <double>[];
    final trainWeights = <double>[];
    double totalWeight = 0.0;
    double weightedRatingSum = 0.0;

    // Also track empirical genre stats for explainability
    final genreRatings = <String, List<double>>{};
    final genreOriginalNames = <String, String>{};

    for (final g in trainingGames) {
      final vec = extractFeatures(g);
      final w = 1.0 + (g.hoursPlayed.clamp(0.0, 60.0) / 60.0) * 0.5;
      trainVectors.add(vec);
      trainRatings.add(g.personalRating);
      trainWeights.add(w);
      totalWeight += w;
      weightedRatingSum += w * g.personalRating;

      for (final raw in g.genres) {
        final trimmed = raw.trim();
        if (trimmed.isEmpty) continue;
        final key = trimmed.toLowerCase();
        genreOriginalNames.putIfAbsent(key, () => trimmed);
        genreRatings.putIfAbsent(key, () => []).add(g.personalRating);
      }
    }

    final globalMean = weightedRatingSum / totalWeight;
    final residuals = [
      for (int i = 0; i < trainRatings.length; i++) trainRatings[i] - globalMean,
    ];

    // Collect all feature keys across training data
    final weights = <String, double>{};
    for (final vec in trainVectors) {
      for (final k in vec.keys) {
        weights.putIfAbsent(k, () => 0.0);
      }
    }

    // Batch gradient descent for L2-regularized Ridge Regression
    for (int epoch = 0; epoch < _epochs; epoch++) {
      final grads = <String, double>{
        for (final k in weights.keys) k: _regularizationLambda * weights[k]!,
      };

      for (int i = 0; i < trainVectors.length; i++) {
        final vec = trainVectors[i];
        final sampleW = trainWeights[i];
        double predResidual = 0.0;
        vec.forEach((k, v) {
          predResidual += (weights[k] ?? 0.0) * v;
        });

        final error = (predResidual - residuals[i]) * (sampleW / totalWeight);
        vec.forEach((k, v) {
          grads[k] = (grads[k] ?? 0.0) + error * v;
        });
      }

      weights.forEach((k, w) {
        weights[k] = w - _learningRate * (grads[k] ?? 0.0);
      });
    }

    // Score each candidate backlog game
    BacklogRecommendation? bestRec;
    double bestSortScore = -double.infinity;

    for (final candidate in candidates) {
      final vec = extractFeatures(candidate);
      double delta = 0.0;
      vec.forEach((k, v) {
        delta += (weights[k] ?? 0.0) * v;
      });

      final predictedRating = (globalMean + delta).clamp(1.0, 10.0);

      // Identify top contributing genre and empirical stats for explanation
      String? topGenreName;
      double? topGenreAvg;
      double bestGenreContribution = -double.infinity;

      for (final raw in candidate.genres) {
        final trimmed = raw.trim();
        if (trimmed.isEmpty) continue;
        final key = trimmed.toLowerCase();
        final featKey = 'genre:$key';
        final learnedW = weights[featKey] ?? 0.0;
        final hist = genreRatings[key];
        final avg = hist != null && hist.isNotEmpty
            ? hist.reduce((a, b) => a + b) / hist.length
            : null;

        final contribution = learnedW * (vec[featKey] ?? 0.0);
        if (avg != null && contribution > bestGenreContribution) {
          bestGenreContribution = contribution;
          topGenreName = genreOriginalNames[key] ?? trimmed;
          topGenreAvg = avg;
        }
      }

      // Compute normalized match score (0.50 - 0.99)
      final ratingNorm = ((predictedRating - 4.0) / 6.0).clamp(0.0, 1.0);
      final overlapBoost = topGenreAvg != null && topGenreAvg >= globalMean ? 0.04 : 0.0;
      final matchScore = (0.54 + ratingNorm * 0.41 + overlapBoost).clamp(0.50, 0.99);

      // Build human-readable primary reason and factors
      final String primaryReason;
      final factors = <String>[];

      if (topGenreName != null && topGenreAvg != null) {
        primaryReason =
            'Matches your love for $topGenreName (avg ${topGenreAvg.toStringAsFixed(1)}★)';
        factors.add('$topGenreName • ${topGenreAvg.toStringAsFixed(1)}★ avg');
      } else {
        primaryReason =
            'Predicted ${predictedRating.toStringAsFixed(1)}★ based on your rated library';
      }

      factors.add(candidate.storefront.label);
      if (candidate.totalSpent <= 0.01) {
        factors.add('Free');
      }

      // Tie-break slightly on matchScore & recency
      final compositeScore = predictedRating + matchScore * 0.1;

      if (compositeScore > bestSortScore ||
          (compositeScore == bestSortScore &&
              bestRec != null &&
              candidate.addedAt.isAfter(bestRec.game.addedAt))) {
        bestSortScore = compositeScore;
        bestRec = BacklogRecommendation(
          game: candidate,
          matchScore: matchScore,
          predictedRating: predictedRating,
          primaryReason: primaryReason,
          matchingFactors: factors.take(3).toList(),
        );
      }
    }

    return bestRec;
  }
}
