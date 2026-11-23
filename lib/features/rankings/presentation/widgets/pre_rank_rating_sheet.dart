import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../tracker/presentation/widgets/help_me_rate_sheet.dart';
import '../../domain/models/canonical_game.dart';

/// Modal bottom sheet presented before ranking comparisons begin if any
/// of the games being ranked do not have a personal rating yet.
class PreRankRatingSheet extends StatefulWidget {
  final CanonicalGame game;

  const PreRankRatingSheet({
    super.key,
    required this.game,
  });

  /// Displays the modal sheet and returns the confirmed rating, or null if dismissed.
  static Future<double?> show(
    BuildContext context, {
    required CanonicalGame game,
  }) {
    return showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PreRankRatingSheet(game: game),
    );
  }

  @override
  State<PreRankRatingSheet> createState() => _PreRankRatingSheetState();
}

class _PreRankRatingSheetState extends State<PreRankRatingSheet> {
  double _currentRating = 7.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        20 + MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.outlineVariant.withAlpha(120),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header: Icon + Title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withAlpha(90),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.star_half_rounded,
                  color: colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rate to Establish Baseline',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'A rating is required before ranking comparisons',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Game Card Preview
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: colorScheme.surfaceContainerLowest,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: widget.game.coverUrl != null && widget.game.coverUrl!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: widget.game.coverUrl!,
                          fit: BoxFit.cover,
                          errorWidget: (_, _, _) => const Icon(Icons.sports_esports),
                        )
                      : const Icon(Icons.sports_esports),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.game.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Unrated · Set your personal score',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Rating Score Display & Help Me Rate Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.star_rounded,
                    color: colorScheme.secondary,
                    size: 28,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _currentRating.toStringAsFixed(1),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: colorScheme.secondary,
                    ),
                  ),
                  Text(
                    ' / 10.0',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              FilledButton.tonalIcon(
                onPressed: () async {
                  final score = await HelpMeRateSheet.show(
                    context,
                    gameTitle: widget.game.title,
                    coverUrl: widget.game.coverUrl,
                  );
                  if (score != null && score > 0) {
                    setState(() {
                      _currentRating = score;
                    });
                  }
                },
                icon: const Icon(Icons.auto_awesome_rounded, size: 16),
                label: const Text('Help Me Rate'),
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Slider
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: colorScheme.secondary,
              thumbColor: colorScheme.secondary,
            ),
            child: Slider(
              value: _currentRating,
              min: 1.0,
              max: 10.0,
              divisions: 18, // 0.5 step increments from 1.0 to 10.0
              label: _currentRating.toStringAsFixed(1),
              onChanged: (val) {
                setState(() {
                  _currentRating = val;
                });
              },
            ),
          ),
          const SizedBox(height: 16),

          // Confirm Button
          FilledButton(
            onPressed: () {
              Navigator.pop(context, _currentRating);
            },
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              'Save Rating & Continue',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
