import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/currency_helper.dart';
import '../../../tracker/domain/models/game_status.dart';
import '../../../tracker/presentation/screens/dossier_screen.dart';
import '../../domain/models/backlog_recommendation.dart';
import '../controllers/analytics_notifier.dart';
import '../controllers/analytics_state.dart';

class BacklogPipelineTab extends ConsumerWidget {
  final AnalyticsState state;

  const BacklogPipelineTab({
    super.key,
    required this.state,
  });

  void _openDossier(BuildContext context, String gameId) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DossierScreen(gameId: gameId)),
    );
  }

  Color _statusColor(GameStatus status, ColorScheme colorScheme) {
    switch (status) {
      case GameStatus.backlog:
        return colorScheme.onSurfaceVariant;
      case GameStatus.playing:
        return colorScheme.primary;
      case GameStatus.completed:
        return colorScheme.secondary;
      case GameStatus.mastered:
        return colorScheme.tertiary;
      case GameStatus.abandoned:
        return colorScheme.error;
      case GameStatus.wishlist:
        return colorScheme.primary.withAlpha(150);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final recommendation = ref.watch(backlogRecommendationProvider);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        // 1. Completion Health & Backlog Sunk Cost
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context: context,
                title: 'Completion Rate',
                value: '${state.completionRate.toStringAsFixed(1)}%',
                subtitle: 'Completed & Mastered titles',
                icon: Icons.task_alt_rounded,
                accentColor: colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                context: context,
                title: 'Backlog Sunk Capital',
                value: CurrencyHelper.format(
                  state.backlogCapital,
                  currencyCode: state.primaryCurrency,
                ),
                subtitle: '${state.backlogCapitalPercent.toStringAsFixed(0)}% of total budget',
                icon: Icons.inventory_2_outlined,
                accentColor: colorScheme.secondary,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Direct Game Split: Played vs. Unplayed Ratio Banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colorScheme.outlineVariant.withAlpha(50)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: colorScheme.tertiary.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.pie_chart_rounded, size: 16, color: colorScheme.tertiary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Played vs. Unplayed Ratio',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      '${state.playedGamesCount} played titles • ${state.unplayedGamesCount} unplayed titles',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colorScheme.outlineVariant.withAlpha(60)),
                ),
                child: Text(
                  '${state.playedGamesCount} / ${state.unplayedGamesCount}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // 2. Smart Backlog Recommender (On-demand ML pick, locked until status changes)
        if (recommendation != null) ...[
          _buildRecommendationCard(context, recommendation),
          const SizedBox(height: 16),
        ],

        // 3. Status Funnel Card
        _buildStatusPipelineCard(context),

        const SizedBox(height: 16),

        // 4. The Abandoned Tax Card
        _buildAbandonedTaxCard(context),

        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildStatCard({
    required BuildContext context,
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant.withAlpha(50)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(icon, size: 18, color: accentColor),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                color: accentColor,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant.withAlpha(180),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationCard(
    BuildContext context,
    BacklogRecommendation rec,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final game = rec.game;
    final matchPercent = (rec.matchScore * 100).round();

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: colorScheme.primary.withAlpha(75)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _openDossier(context, game.id),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row: label + match confidence pill
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withAlpha(25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.auto_awesome_rounded,
                      size: 15,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'SMART BACKLOG PICK',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: colorScheme.primary,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withAlpha(25),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: colorScheme.primary.withAlpha(70)),
                    ),
                    child: Text(
                      '$matchPercent% Match',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Main content row: Cover artwork + Title/Reason/Chips
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      width: 62,
                      height: 84,
                      child: game.coverUrl != null && game.coverUrl!.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: game.coverUrl!,
                              fit: BoxFit.cover,
                              placeholder: (_, _) => Container(
                                color: colorScheme.surfaceContainerHigh,
                              ),
                              errorWidget: (_, _, _) => Container(
                                color: colorScheme.surfaceContainerHigh,
                                child: Icon(
                                  Icons.sports_esports_rounded,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            )
                          : Container(
                              color: colorScheme.surfaceContainerHigh,
                              child: Icon(
                                Icons.sports_esports_rounded,
                                color: colorScheme.primary,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          game.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: colorScheme.onSurface,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          rec.primaryReason,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            // Predicted Enjoyment Badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: colorScheme.outlineVariant.withAlpha(60),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.star_rounded,
                                    size: 12,
                                    color: colorScheme.primary,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    'Est. ${rec.predictedRating.toStringAsFixed(1)}',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w800,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ...rec.matchingFactors.map(
                              (factor) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: colorScheme.surfaceContainerHigh,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: colorScheme.outlineVariant.withAlpha(45),
                                  ),
                                ),
                                child: Text(
                                  factor,
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Action CTA
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonalIcon(
                  onPressed: () => _openDossier(context, game.id),
                  style: FilledButton.styleFrom(
                    backgroundColor: colorScheme.primary.withAlpha(30),
                    foregroundColor: colorScheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.play_arrow_rounded, size: 18),
                  label: const Text(
                    'Start Playing Next',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusPipelineCard(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final totalGames = state.totalGamesCount;

    final statuses = [
      GameStatus.backlog,
      GameStatus.playing,
      GameStatus.completed,
      GameStatus.mastered,
      GameStatus.abandoned,
      GameStatus.wishlist,
    ];

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant.withAlpha(50)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.filter_list_rounded,
                    size: 18,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Library Status Funnel',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        'Distribution across your gaming lifecycle',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            ...statuses.map((status) {
              final count = state.statusCounts[status] ?? 0;
              final percent = totalGames > 0 ? (count / totalGames) * 100 : 0.0;
              final ratio = totalGames > 0 ? (count / totalGames) : 0.0;
              final normalizedColor = _statusColor(status, colorScheme);

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(status.icon, size: 16, color: normalizedColor),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            status.displayName,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                        Text(
                          '$count (${percent.toStringAsFixed(0)}%)',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: ratio,
                        minHeight: 6,
                        backgroundColor: colorScheme.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation(normalizedColor),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildAbandonedTaxCard(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.error.withAlpha(60)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: colorScheme.error.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.cancel_outlined, size: 18, color: colorScheme.error),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'The Abandoned Tax',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        'Time and capital poured into dropped titles',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${state.abandonedHours.toStringAsFixed(1)} hrs',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: colorScheme.error,
                        ),
                      ),
                      Text(
                        'Abandoned Playtime',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        CurrencyHelper.format(
                          state.abandonedSpend,
                          currencyCode: state.primaryCurrency,
                        ),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: colorScheme.error,
                        ),
                      ),
                      Text(
                        'Sunk Spend',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${state.abandonedHoursTaxPercent.toStringAsFixed(1)}%',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: colorScheme.error,
                        ),
                      ),
                      Text(
                        'of Total Hours Lost',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
