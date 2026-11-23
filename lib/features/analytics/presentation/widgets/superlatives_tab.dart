import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../core/utils/currency_helper.dart';
import '../../../../core/utils/time_normalizer.dart';
import '../../../tracker/domain/models/game_entry.dart';
import '../../../tracker/presentation/screens/dossier_screen.dart';
import '../controllers/analytics_state.dart';

class SuperlativesTab extends StatelessWidget {
  final AnalyticsState state;

  const SuperlativesTab({
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

    final awards = <_AwardData>[
      if (state.infiniteValueGame != null)
        _AwardData(
          title: 'The Infinite Value',
          subtitle: 'Lowest cost per hour of entertainment',
          badgeText: state.infiniteValueCostPerHour != null
              ? '${CurrencyHelper.format(state.infiniteValueCostPerHour!, currencyCode: state.primaryCurrency)}/hr'
              : 'N/A',
          icon: Icons.stars_rounded,
          color: const Color(0xFF10B981), // Emerald
          game: state.infiniteValueGame!,
          extraDetail: '${TimeNormalizer.format(state.infiniteValueGame!.totalMinutesPlayed)} played',
        ),
      if (state.blackHoleGame != null)
        _AwardData(
          title: 'The Black Hole',
          subtitle: 'Highest absolute logged playtime',
          badgeText: TimeNormalizer.format(state.blackHoleGame!.totalMinutesPlayed),
          icon: Icons.all_inclusive_rounded,
          color: const Color(0xFF8B5CF6), // Purple
          game: state.blackHoleGame!,
          extraDetail: '${(state.blackHoleGame!.hoursPlayed / 24).toStringAsFixed(1)} full days',
        ),
      if (state.moneyPitGame != null)
        _AwardData(
          title: 'The Money Pit',
          subtitle: 'Highest cost per hour invested',
          badgeText: state.moneyPitCostPerHour != null
              ? '${CurrencyHelper.format(state.moneyPitCostPerHour!, currencyCode: state.primaryCurrency)}/hr'
              : 'N/A',
          icon: Icons.money_off_csred_rounded,
          color: const Color(0xFFEF4444), // Crimson
          game: state.moneyPitGame!,
          extraDetail: 'Paid ${CurrencyHelper.format(state.moneyPitGame!.totalSpent, currencyCode: state.moneyPitGame!.currency)}',
        ),
      if (state.goldenFreebieGame != null)
        _AwardData(
          title: 'The Golden Freebie',
          subtitle: 'Most played free or claimed game',
          badgeText: TimeNormalizer.format(state.goldenFreebieGame!.totalMinutesPlayed),
          icon: Icons.card_giftcard_rounded,
          color: const Color(0xFFF59E0B), // Amber
          game: state.goldenFreebieGame!,
          extraDetail: 'Claimed for \$0.00',
        ),
      if (state.masterpieceGame != null)
        _AwardData(
          title: 'The Masterpiece',
          subtitle: 'Highest personal rating among completed titles',
          badgeText: '${state.masterpieceGame!.personalRating.toStringAsFixed(1)} ★',
          icon: Icons.military_tech_rounded,
          color: const Color(0xFFFBBF24), // Gold
          game: state.masterpieceGame!,
          extraDetail: state.masterpieceGame!.status.displayName,
        ),
      if (state.dlcCollectorGame != null && state.dlcCollectorSpend != null && state.dlcCollectorSpend! > 0)
        _AwardData(
          title: 'The DLC Collector',
          subtitle: 'Most capital invested in expansions & DLCs',
          badgeText: CurrencyHelper.format(state.dlcCollectorSpend!, currencyCode: state.primaryCurrency),
          icon: Icons.shopping_bag_outlined,
          color: colorScheme.primary,
          game: state.dlcCollectorGame!,
          extraDetail: '${state.dlcCollectorGame!.additionalExpenses.length} DLCs/expansions recorded',
        ),
    ];

    if (awards.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.emoji_events_outlined, size: 48, color: colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                'No Accolades Yet',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Log playtime and financial costs on your games to unlock your personal gaming Hall of Fame.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Icon(Icons.military_tech_rounded, size: 20, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Personal Gaming Hall of Fame',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),

        ...awards.map((award) => _buildAwardCard(context, award)),

        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildAwardCard(BuildContext context, _AwardData award) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final game = award.game;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      color: colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: award.color.withAlpha(50)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openDossier(context, game.id),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Award title & icon header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: award.color.withAlpha(25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(award.icon, size: 16, color: award.color),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          award.title,
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: award.color,
                            letterSpacing: 0.3,
                          ),
                        ),
                        Text(
                          award.subtitle,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: award.color.withAlpha(20),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: award.color.withAlpha(70)),
                    ),
                    child: Text(
                      award.badgeText,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: award.color,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Game row
              Row(
                children: [
                  if (game.coverUrl != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: game.coverUrl!,
                        width: 44,
                        height: 58,
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) => Container(
                          width: 44,
                          height: 58,
                          color: colorScheme.surfaceContainerHighest,
                          child: const Icon(Icons.sports_esports),
                        ),
                      ),
                    )
                  else
                    Container(
                      width: 44,
                      height: 58,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.sports_esports, color: colorScheme.primary),
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
                            fontWeight: FontWeight.w800,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${game.storefront.label} • ${award.extraDetail}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, size: 20, color: colorScheme.onSurfaceVariant),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AwardData {
  final String title;
  final String subtitle;
  final String badgeText;
  final IconData icon;
  final Color color;
  final GameEntry game;
  final String extraDetail;

  const _AwardData({
    required this.title,
    required this.subtitle,
    required this.badgeText,
    required this.icon,
    required this.color,
    required this.game,
    required this.extraDetail,
  });
}
