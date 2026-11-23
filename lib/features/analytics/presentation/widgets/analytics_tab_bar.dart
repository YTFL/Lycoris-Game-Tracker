import 'package:flutter/material.dart';
import '../controllers/analytics_state.dart';

class AnalyticsTabBar extends StatelessWidget implements PreferredSizeWidget {
  final TabController controller;

  const AnalyticsTabBar({
    super.key,
    required this.controller,
  });

  IconData _iconForTab(AnalyticsTab tab) {
    switch (tab) {
      case AnalyticsTab.overview:
        return Icons.dashboard_rounded;
      case AnalyticsTab.playtimeHabits:
        return Icons.timer_outlined;
      case AnalyticsTab.ratingJoy:
        return Icons.stars_rounded;
      case AnalyticsTab.backlogPipeline:
        return Icons.filter_alt_outlined;
      case AnalyticsTab.superlatives:
        return Icons.emoji_events_outlined;
    }
  }

  @override
  Size get preferredSize => const Size.fromHeight(48);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return TabBar(
      controller: controller,
      isScrollable: true,
      tabAlignment: TabAlignment.start,
      indicatorSize: TabBarIndicatorSize.label,
      indicatorWeight: 3,
      indicatorColor: colorScheme.primary,
      labelColor: colorScheme.primary,
      unselectedLabelColor: colorScheme.onSurfaceVariant,
      labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
      unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 13),
      tabs: AnalyticsTab.values.map((tab) {
        return Tab(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_iconForTab(tab), size: 16),
              const SizedBox(width: 8),
              Text(tab.label),
            ],
          ),
        );
      }).toList(),
    );
  }
}
