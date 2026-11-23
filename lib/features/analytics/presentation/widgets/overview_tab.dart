import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../core/utils/currency_helper.dart';
import '../../../../core/utils/time_normalizer.dart';
import '../../../tracker/presentation/screens/dossier_screen.dart';
import '../controllers/analytics_state.dart';

class OverviewTab extends StatelessWidget {
  final AnalyticsState state;

  const OverviewTab({
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
        // Section 1: The Core Big 4 (Hero Cards)
        _buildSectionHeader(
          context,
          icon: Icons.dashboard_rounded,
          title: 'The Core Big 4',
          subtitle: 'High-level lifetime gaming investment & scale',
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildHeroStatCard(
                context: context,
                title: 'Total Playtime',
                value: '${state.totalHoursPlayed.toStringAsFixed(1)} hrs',
                subtitle: '${state.totalDaysPlayed.toStringAsFixed(1)} days equivalent',
                icon: Icons.timer_rounded,
                accentColor: colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildHeroStatCard(
                context: context,
                title: 'Total Invested',
                value: CurrencyHelper.format(state.totalInvested, currencyCode: state.primaryCurrency),
                subtitle: 'Base games + DLC spend',
                icon: Icons.account_balance_wallet_rounded,
                accentColor: colorScheme.secondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildHeroStatCard(
                context: context,
                title: 'Total Games Owned',
                value: '${state.totalGamesCount}',
                subtitle: 'Vault title count',
                icon: Icons.sports_esports_rounded,
                accentColor: colorScheme.tertiary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildHeroStatCard(
                context: context,
                title: 'Average Cost / Hour',
                value: state.totalMinutesPlayed > 0
                    ? '${CurrencyHelper.format(state.averageCostPerHour, currencyCode: state.primaryCurrency)}/hr'
                    : 'N/A',
                subtitle: 'Overall entertainment rate',
                icon: Icons.speed_rounded,
                accentColor: colorScheme.primary,
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Section 2: Quick Health & Balance
        _buildSectionHeader(
          context,
          icon: Icons.monitor_heart_rounded,
          title: 'Quick Health & Balance',
          subtitle: 'Completion pace, backlog capital, and rating sentiment',
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                context: context,
                title: 'Completion Rate',
                value: '${state.completionRate.toStringAsFixed(1)}%',
                subtitle: 'Beaten or mastered titles',
                icon: Icons.task_alt_rounded,
                accentColor: colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricTile(
                context: context,
                title: 'Backlog Sunk Capital',
                value: CurrencyHelper.format(state.backlogCapital, currencyCode: state.primaryCurrency),
                subtitle: '${state.backlogCapitalPercent.toStringAsFixed(0)}% of total budget',
                icon: Icons.inventory_2_outlined,
                accentColor: colorScheme.secondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                context: context,
                title: 'Played vs. Unplayed',
                value: '${state.playedGamesCount} / ${state.unplayedGamesCount}',
                subtitle: '${state.playedGamesCount} played • ${state.unplayedGamesCount} untouched',
                icon: Icons.pie_chart_outline_rounded,
                accentColor: colorScheme.tertiary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricTile(
                context: context,
                title: 'Average Personal Rating',
                value: state.totalRatedGames > 0
                    ? '${state.averagePersonalRating.toStringAsFixed(1)} ★'
                    : 'N/A',
                subtitle: 'Across ${state.totalRatedGames} rated titles',
                icon: Icons.star_half_rounded,
                accentColor: colorScheme.primary,
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Section 3: Highlights & Extremes (Quick Showcase)
        _buildSectionHeader(
          context,
          icon: Icons.auto_awesome_rounded,
          title: 'Highlights & Extremes',
          subtitle: 'Peak achievements and key library pillars',
        ),
        const SizedBox(height: 10),
        _buildHighlightsCard(context),

        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: colorScheme.primary.withAlpha(20),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: colorScheme.primary),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                  color: colorScheme.onSurface,
                ),
              ),
              Text(
                subtitle,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeroStatCard({
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
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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

  Widget _buildMetricTile({
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
      color: colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: colorScheme.outlineVariant.withAlpha(40)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 15, color: accentColor),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHighlightsCard(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final mostPlayed = state.blackHoleGame;
    final bestValue = state.infiniteValueGame;
    final topGenre = state.topGenres.isNotEmpty ? state.topGenres.first : null;
    final topStorefront = state.topStorefront;

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
          children: [
            // 1. Most Played Game
            if (mostPlayed != null)
              _buildHighlightRow(
                context,
                badgeLabel: 'MOST PLAYED',
                badgeColor: colorScheme.secondary,
                icon: Icons.all_inclusive_rounded,
                title: mostPlayed.title,
                detail: '${TimeNormalizer.format(mostPlayed.totalMinutesPlayed)} (${(mostPlayed.hoursPlayed / 24).toStringAsFixed(1)} days)',
                coverUrl: mostPlayed.coverUrl,
                onTap: () => _openDossier(context, mostPlayed.id),
              )
            else
              _buildPlaceholderHighlightRow(
                context,
                badgeLabel: 'MOST PLAYED',
                badgeColor: colorScheme.secondary,
                message: 'No played games yet',
              ),

            Divider(color: colorScheme.outlineVariant.withAlpha(40), height: 20),

            // 2. Best Value Title
            if (bestValue != null && state.infiniteValueCostPerHour != null)
              _buildHighlightRow(
                context,
                badgeLabel: 'BEST VALUE',
                badgeColor: colorScheme.primary,
                icon: Icons.stars_rounded,
                title: bestValue.title,
                detail: '${CurrencyHelper.format(state.infiniteValueCostPerHour!, currencyCode: state.primaryCurrency)}/hr • ${TimeNormalizer.format(bestValue.totalMinutesPlayed)}',
                coverUrl: bestValue.coverUrl,
                onTap: () => _openDossier(context, bestValue.id),
              )
            else
              _buildPlaceholderHighlightRow(
                context,
                badgeLabel: 'BEST VALUE',
                badgeColor: colorScheme.primary,
                message: 'Log costs & playtime to unlock',
              ),

            Divider(color: colorScheme.outlineVariant.withAlpha(40), height: 20),

            // 3. Top Genre
            if (topGenre != null)
              _buildGenericHighlightRow(
                context,
                badgeLabel: 'TOP GENRE',
                badgeColor: colorScheme.tertiary,
                icon: Icons.category_rounded,
                title: topGenre.genre,
                detail: '${TimeNormalizer.format(topGenre.totalMinutes)} logged across ${topGenre.gamesCount} games',
              )
            else
              _buildPlaceholderHighlightRow(
                context,
                badgeLabel: 'TOP GENRE',
                badgeColor: colorScheme.tertiary,
                message: 'Categorize games to see genre insights',
              ),

            Divider(color: colorScheme.outlineVariant.withAlpha(40), height: 20),

            // 4. Top Storefront
            if (topStorefront != null)
              _buildGenericHighlightRow(
                context,
                badgeLabel: 'TOP PLATFORM',
                badgeColor: colorScheme.primary,
                icon: topStorefront.storefront.fallbackIcon,
                title: topStorefront.storefront.label,
                detail: '${topStorefront.count} games • Spent ${CurrencyHelper.format(topStorefront.totalSpend, currencyCode: state.primaryCurrency)}',
              )
            else
              _buildPlaceholderHighlightRow(
                context,
                badgeLabel: 'TOP PLATFORM',
                badgeColor: colorScheme.primary,
                message: 'No storefront data available',
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHighlightRow(
    BuildContext context, {
    required String badgeLabel,
    required Color badgeColor,
    required IconData icon,
    required String title,
    required String detail,
    String? coverUrl,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            if (coverUrl != null && coverUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: CachedNetworkImage(
                  imageUrl: coverUrl,
                  width: 38,
                  height: 50,
                  fit: BoxFit.cover,
                  errorWidget: (_, _, _) => Container(
                    width: 38,
                    height: 50,
                    color: colorScheme.surfaceContainerHighest,
                    child: Icon(icon, size: 18, color: badgeColor),
                  ),
                ),
              )
            else
              Container(
                width: 38,
                height: 50,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, size: 18, color: badgeColor),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: badgeColor.withAlpha(25),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      badgeLabel,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: badgeColor,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    detail,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 18, color: colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  Widget _buildGenericHighlightRow(
    BuildContext context, {
    required String badgeLabel,
    required Color badgeColor,
    required IconData icon,
    required String title,
    required String detail,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: badgeColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: badgeColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    badgeLabel,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: badgeColor,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  detail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderHighlightRow(
    BuildContext context, {
    required String badgeLabel,
    required Color badgeColor,
    required String message,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
            decoration: BoxDecoration(
              color: badgeColor.withAlpha(25),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              badgeLabel,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: badgeColor,
                letterSpacing: 0.4,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant.withAlpha(140),
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
