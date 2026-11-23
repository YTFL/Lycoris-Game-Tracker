import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/currency_helper.dart';
import '../../../sync/presentation/controllers/settings_notifier.dart';
import '../controllers/analytics_notifier.dart';
import '../controllers/analytics_state.dart';
import '../widgets/analytics_tab_bar.dart';
import '../widgets/backlog_pipeline_tab.dart';
import '../widgets/playtime_habits_tab.dart';
import '../widgets/rating_joy_tab.dart';
import '../widgets/superlatives_tab.dart';

class AnalyticsDashboard extends ConsumerStatefulWidget {
  const AnalyticsDashboard({super.key});

  @override
  ConsumerState<AnalyticsDashboard> createState() => _AnalyticsDashboardState();
}

class _AnalyticsDashboardState extends ConsumerState<AnalyticsDashboard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(exchangeRatesNotifierProvider.notifier).checkAndAutoFetch();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final state = ref.watch(analyticsStateProvider);
    final primaryCurrency = state.primaryCurrency;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.insights_rounded, color: colorScheme.primary),
            const SizedBox(width: 10),
            Text(
              'Analytics',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        actions: [
          // Currency Selector Button
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => CurrencyHelper.showCurrencyPicker(
                context,
                currentCurrency: primaryCurrency,
                onSelected: (currency) {
                  ref.read(settingsNotifierProvider.notifier).updatePrimaryCurrency(currency);
                },
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: colorScheme.outlineVariant.withAlpha(80)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CurrencySymbolBox(
                      currencyCode: primaryCurrency,
                      size: 20,
                      baseFontSize: 10,
                      borderRadius: BorderRadius.circular(10),
                      backgroundColor: colorScheme.primary,
                      textColor: colorScheme.onPrimary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      primaryCurrency,
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.keyboard_arrow_down, size: 16, color: colorScheme.onSurfaceVariant),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: state.totalGamesCount == 0
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHigh,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.insights_rounded, size: 48, color: colorScheme.primary),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'No Games in Library Yet',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add games to your library to unlock playtime tracking, genre habits, ratings matrix, and personal gaming accolades.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            )
          : Column(
              children: [
                // 1. Sliding Tab Selector
                AnalyticsTabBar(
                  currentTab: state.currentTab,
                  onTabSelected: (tab) {
                    ref.read(analyticsTabProvider.notifier).state = tab;
                  },
                ),

                // 2. Active Tab Content
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: _buildTabContent(state),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildTabContent(AnalyticsState state) {
    switch (state.currentTab) {
      case AnalyticsTab.playtimeHabits:
        return PlaytimeHabitsTab(
          key: const ValueKey('playtimeHabits'),
          state: state,
        );
      case AnalyticsTab.ratingJoy:
        return RatingJoyTab(
          key: const ValueKey('ratingJoy'),
          state: state,
        );
      case AnalyticsTab.backlogPipeline:
        return BacklogPipelineTab(
          key: const ValueKey('backlogPipeline'),
          state: state,
        );
      case AnalyticsTab.superlatives:
        return SuperlativesTab(
          key: const ValueKey('superlatives'),
          state: state,
        );
    }
  }
}
