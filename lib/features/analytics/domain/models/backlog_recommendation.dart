import '../../../tracker/domain/models/game_entry.dart';

class BacklogRecommendation {
  final GameEntry game;
  final double matchScore; // 0.0 - 1.0
  final double predictedRating; // 1.0 - 10.0
  final String primaryReason;
  final List<String> matchingFactors;

  const BacklogRecommendation({
    required this.game,
    required this.matchScore,
    required this.predictedRating,
    required this.primaryReason,
    this.matchingFactors = const [],
  });

  BacklogRecommendation copyWith({
    GameEntry? game,
    double? matchScore,
    double? predictedRating,
    String? primaryReason,
    List<String>? matchingFactors,
  }) {
    return BacklogRecommendation(
      game: game ?? this.game,
      matchScore: matchScore ?? this.matchScore,
      predictedRating: predictedRating ?? this.predictedRating,
      primaryReason: primaryReason ?? this.primaryReason,
      matchingFactors: matchingFactors ?? this.matchingFactors,
    );
  }

  Map<String, dynamic> toJson() => {
        'gameId': game.id,
        'matchScore': matchScore,
        'predictedRating': predictedRating,
        'primaryReason': primaryReason,
        'matchingFactors': matchingFactors,
      };
}
