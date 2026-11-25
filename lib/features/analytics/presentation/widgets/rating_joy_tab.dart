import 'package:flutter/material.dart';
import '../../../../core/utils/currency_helper.dart';
import '../../../../core/utils/time_normalizer.dart';
import '../../../../core/widgets/game_cover_image.dart';
import '../../../tracker/presentation/screens/dossier_screen.dart';
import '../controllers/analytics_state.dart';

class RatingJoyTab extends StatelessWidget {
  final AnalyticsState state;

  const RatingJoyTab({
    super.key,
    required this.state,
  });

  void _openDossier(BuildContext context, String gameId) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DossierScreen(gameId: gameId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        // 1. Rating Summary KPI Row
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context: context,
                title: 'Average Rating',
                value: state.totalRatedGames > 0
                    ? '${state.averagePersonalRating.toStringAsFixed(1)} ★'
                    : 'N/A',
                subtitle: 'Across ${state.totalRatedGames} rated titles',
                icon: Icons.star_half_rounded,
                accentColor: colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                context: context,
                title: 'Median Rating',
                value: state.totalRatedGames > 0
                    ? '${state.medianRating.toStringAsFixed(1)} ★'
                    : 'N/A',
                subtitle: 'Library rating midpoint',
                icon: Icons.grade_rounded,
                accentColor: colorScheme.secondary,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // 2. Rating Distribution Card
        _buildRatingDistributionCard(context),

        const SizedBox(height: 16),

        // 3. Highest Rated Games Showcase
        _buildTopRatedGamesCard(context),

        const SizedBox(height: 16),

        // 4. Joy-Per-Dollar (Happiness ROI) Leaderboard
        _buildJoyPerDollarCard(context),

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

  Widget _buildRatingDistributionCard(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final buckets = state.ratingDistribution;
    final tierColors = [
      colorScheme.primary,
      colorScheme.secondary,
      colorScheme.tertiary,
      colorScheme.onSurfaceVariant,
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
                  child: Icon(Icons.bar_chart_rounded, size: 18, color: colorScheme.primary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rating Distribution',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        'Spread across ${state.totalRatedGames} rated titles',
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
            if (state.totalRatedGames == 0)
              Text(
                'Rate games in your library to see your score distribution.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              )
            else ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  height: 12,
                  child: Row(
                    children: buckets.asMap().entries.map((entry) {
                      final i = entry.key;
                      final b = entry.value;
                      if (b.count == 0) return const SizedBox.shrink();
                      return Expanded(
                        flex: b.count,
                        child: Container(color: tierColors[i % tierColors.length]),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              ...buckets.asMap().entries.map((entry) {
                final i = entry.key;
                final b = entry.value;
                final color = tierColors[i % tierColors.length];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${b.label} (${b.rangeLabel})',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                      Text(
                        '${b.count} (${b.percentage.toStringAsFixed(0)}%)',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTopRatedGamesCard(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final games = state.topRatedGames;

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
                    color: colorScheme.secondary.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.workspace_premium_rounded, size: 18, color: colorScheme.secondary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Highest Rated Games',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        'Your personal all-time favorites',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (games.isEmpty)
              Text(
                'No rated games yet.',
                style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: games.length,
                separatorBuilder: (_, _) => Divider(
                  color: colorScheme.outlineVariant.withAlpha(50),
                  height: 14,
                ),
                itemBuilder: (context, index) {
                  final game = games[index];
                  return InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => _openDossier(context, game.id),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: SizedBox(
                              width: 36,
                              height: 48,
                              child: game.coverUrl != null && game.coverUrl!.isNotEmpty
                                  ? GameCoverImage(
                                      imageUrl: game.coverUrl!,
                                      memCacheWidth: 120,
                                      fit: BoxFit.cover,
                                      placeholder: Container(
                                        color: colorScheme.surfaceContainerHigh,
                                      ),
                                      errorWidget: Container(
                                        color: colorScheme.surfaceContainerHigh,
                                        child: Icon(Icons.sports_esports, size: 16, color: colorScheme.onSurfaceVariant),
                                      ),
                                    )
                                  : Container(
                                      color: colorScheme.surfaceContainerHigh,
                                      child: Icon(Icons.sports_esports, size: 16, color: colorScheme.onSurfaceVariant),
                                    ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  game.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                Text(
                                  '${game.storefront.label} • ${TimeNormalizer.format(game.totalMinutesPlayed)}',
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
                              color: colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: colorScheme.outlineVariant.withAlpha(60),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.star_rounded, size: 12, color: colorScheme.primary),
                                const SizedBox(width: 3),
                                Text(
                                  game.personalRating.toStringAsFixed(1),
                                  style: TextStyle(
                                    color: colorScheme.onSurface,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildJoyPerDollarCard(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final items = state.topJoyPerDollar;

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
                    Icons.sentiment_very_satisfied_rounded,
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
                        'Joy-Per-Dollar Champions',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        'Highest satisfaction delivered per currency spent',
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

            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'No paid games with ratings and playtime recorded yet.',
                  style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                separatorBuilder: (_, _) => Divider(
                  color: colorScheme.outlineVariant.withAlpha(50),
                  height: 16,
                ),
                itemBuilder: (context, index) {
                  final entry = items[index];
                  final game = entry.game;

                  return InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => _openDossier(context, game.id),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Text(
                            '#${index + 1}',
                            style: TextStyle(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  game.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurface,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  '${game.storefront.label} • Paid ${CurrencyHelper.format(entry.convertedCost, currencyCode: state.primaryCurrency)} • ${TimeNormalizer.format(game.totalMinutesPlayed)}',
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
                              color: colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: colorScheme.outlineVariant.withAlpha(60),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.star_rounded, size: 12, color: colorScheme.primary),
                                const SizedBox(width: 3),
                                Text(
                                  entry.rating.toStringAsFixed(1),
                                  style: TextStyle(
                                    color: colorScheme.onSurface,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
