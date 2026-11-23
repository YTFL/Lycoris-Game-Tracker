import 'package:flutter/material.dart';
import '../../../../core/utils/currency_helper.dart';
import '../../../../core/utils/time_normalizer.dart';
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

        const SizedBox(height: 12),

        // 2. Dynamic Threshold Bento Cards (replacing split text banner)
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context: context,
                title: 'Playtime Divider',
                value: '${state.hoursThreshold.toStringAsFixed(1)} hrs',
                subtitle: 'Median library playtime threshold',
                icon: Icons.schedule_rounded,
                accentColor: colorScheme.tertiary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                context: context,
                title: 'Rating Divider',
                value: '${state.ratingThreshold.toStringAsFixed(1)} ★',
                subtitle: 'Median library rating threshold',
                icon: Icons.tune_rounded,
                accentColor: colorScheme.primary,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // 3. The Satisfaction Quadrant Matrix Card (Redesigned)
        _buildGoldenQuadrantCard(context),

        const SizedBox(height: 16),

        // 4. Joy-Per-Dollar (Happiness ROI) Leaderboard (Normalized Colors)
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

  Widget _buildGoldenQuadrantCard(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final categories = [
      QuadrantCategory.timelessMasterpiece,
      QuadrantCategory.sweetShortGem,
      QuadrantCategory.timeTrap,
      QuadrantCategory.earlyDrop,
    ];

    final categoryColors = {
      QuadrantCategory.timelessMasterpiece: colorScheme.primary,
      QuadrantCategory.sweetShortGem: colorScheme.secondary,
      QuadrantCategory.timeTrap: colorScheme.tertiary,
      QuadrantCategory.earlyDrop: colorScheme.onSurfaceVariant,
    };

    final categoryIcons = {
      QuadrantCategory.timelessMasterpiece: Icons.stars_rounded,
      QuadrantCategory.sweetShortGem: Icons.diamond_outlined,
      QuadrantCategory.timeTrap: Icons.hourglass_bottom_rounded,
      QuadrantCategory.earlyDrop: Icons.exit_to_app_rounded,
    };

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
                  child: Icon(Icons.grid_view_rounded, size: 18, color: colorScheme.primary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Satisfaction Matrix',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        'Playtime depth vs. satisfaction matrix',
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

            // Quadrant Sections
            ...categories.map((cat) {
              final gamesInCat = state.quadrantGames[cat] ?? [];
              final color = categoryColors[cat]!;
              final icon = categoryIcons[cat]!;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withAlpha(40),
                    width: 0.8,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: color.withAlpha(25),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(icon, size: 14, color: color),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          cat.title,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: colorScheme.outlineVariant.withAlpha(60)),
                          ),
                          child: Text(
                            '${gamesInCat.length}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      cat.subtitle,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 10),

                    if (gamesInCat.isEmpty)
                      Text(
                        'No games in this quadrant yet.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant.withAlpha(120),
                          fontStyle: FontStyle.italic,
                          fontSize: 11,
                        ),
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: gamesInCat.map((entry) {
                          return InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () => _openDossier(context, entry.game.id),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerLowest,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: colorScheme.outlineVariant.withAlpha(50),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ConstrainedBox(
                                    constraints: const BoxConstraints(maxWidth: 140),
                                    child: Text(
                                      entry.game.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: colorScheme.onSurface,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: color.withAlpha(20),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '${entry.rating.toStringAsFixed(1)}★ • ${entry.hours.toStringAsFixed(0)}h',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: color,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
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
                  child: Icon(Icons.sentiment_very_satisfied_rounded, size: 18, color: colorScheme.primary),
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
                separatorBuilder: (_, _) => Divider(color: colorScheme.outlineVariant.withAlpha(50), height: 16),
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
                                  style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: colorScheme.outlineVariant.withAlpha(60)),
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
