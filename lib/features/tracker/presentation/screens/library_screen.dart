import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../home/domain/models/home_tab_config.dart';
import '../../../home/presentation/controllers/home_tabs_notifier.dart';
import '../../domain/models/game_entry.dart';
import '../../domain/models/storefront.dart';
import '../controllers/library_notifier.dart';
import '../controllers/library_state.dart';
import '../widgets/game_cover_card.dart';
import '../widgets/game_list_row.dart';
import 'dossier_screen.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

// Backward compatibility alias during transition
typedef VaultScreen = LibraryScreen;

class _LibraryScreenState extends ConsumerState<LibraryScreen> with TickerProviderStateMixin {
  final _searchController = SearchController();
  TabController? _tabController;
  int _activeTabsCount = 0;

  @override
  void initState() {
    super.initState();
  }

  void _updateTabController(int newCount) {
    if (_tabController != null && _activeTabsCount == newCount) {
      return;
    }
    final previousIndex = _tabController?.index ?? 0;
    _tabController?.dispose();
    _activeTabsCount = newCount;
    final initialIndex = (previousIndex < newCount) ? previousIndex : (newCount - 1).clamp(0, newCount);
    _tabController = TabController(length: newCount, vsync: this, initialIndex: initialIndex);
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _showPlatformFilterSheet(BuildContext context, LibraryState libraryState, LibraryNotifier notifier) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colorScheme.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.75,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Filter by Platform',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (libraryState.storefrontFilter != null)
                          TextButton(
                            onPressed: () {
                              notifier.setStorefrontFilter(null);
                              Navigator.pop(ctx);
                            },
                            child: const Text('Reset'),
                          ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        ListTile(
                          leading: Icon(
                            Icons.devices_other_rounded,
                            color: libraryState.storefrontFilter == null ? colorScheme.primary : colorScheme.onSurfaceVariant,
                          ),
                          title: Text(
                            'All Platforms',
                            style: TextStyle(
                              fontWeight: libraryState.storefrontFilter == null ? FontWeight.w800 : FontWeight.w500,
                              color: libraryState.storefrontFilter == null ? colorScheme.primary : colorScheme.onSurface,
                            ),
                          ),
                          trailing: Text('(${libraryState.allGames.length})'),
                          onTap: () {
                            notifier.setStorefrontFilter(null);
                            Navigator.pop(ctx);
                          },
                        ),
                        ...Storefront.values.map((s) {
                          final isSelected = libraryState.storefrontFilter == s;
                          final count = libraryState.allGames.where((g) => g.storefront == s).length;
                          return ListTile(
                            leading: Icon(
                              s.fallbackIcon,
                              color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
                            ),
                            title: Text(
                              s.label,
                              style: TextStyle(
                                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                                color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                              ),
                            ),
                            trailing: Text('($count)'),
                            onTap: () {
                              notifier.setStorefrontFilter(isSelected ? null : s);
                              Navigator.pop(ctx);
                            },
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final libraryState = ref.watch(libraryNotifierProvider);
    final notifier = ref.read(libraryNotifierProvider.notifier);
    final tabsState = ref.watch(homeTabsNotifierProvider);
    final visibleTabs = tabsState.visibleTabs;

    // Keep TabController in sync with visible tabs count
    final activeCount = visibleTabs.isNotEmpty ? visibleTabs.length : 1;
    _updateTabController(activeCount);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.sports_esports, color: colorScheme.primary),
            const SizedBox(width: 10),
            Text(
              'Library',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        actions: [
          // 1. View Mode Switcher (Cycles: 2 cols -> 3 cols -> 4 cols -> list -> 2 cols)
          IconButton(
            tooltip: libraryState.viewMode.label,
            icon: Icon(libraryState.viewMode.icon),
            onPressed: () => notifier.cycleViewMode(),
          ),

          // 2. Sort Menu
          PopupMenuButton<LibrarySortOption>(
            tooltip: 'Sort games',
            icon: const Icon(Icons.sort_rounded),
            onSelected: (option) => notifier.setSortOption(option),
            itemBuilder: (ctx) => LibrarySortOption.values.map((opt) {
              final isSelected = libraryState.sortOption == opt;
              return PopupMenuItem(
                value: opt,
                child: Row(
                  children: [
                    Icon(
                      isSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
                      size: 16,
                      color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        opt.label,
                        style: TextStyle(
                          color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      isSelected
                          ? (libraryState.sortAscending
                              ? Icons.arrow_upward_rounded
                              : Icons.arrow_downward_rounded)
                          : Icons.swap_vert_rounded,
                      size: 16,
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(106),
          child: Column(
            children: [
              // SearchBar with trailing platform filter button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: SearchBar(
                  controller: _searchController,
                  hintText: 'Search title, genres, notes...',
                  leading: const Padding(
                    padding: EdgeInsets.only(left: 12),
                    child: Icon(Icons.search, size: 20),
                  ),
                  trailing: [
                    if (_searchController.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          notifier.setSearchQuery('');
                          setState(() {});
                        },
                      ),
                    IconButton(
                      icon: Badge(
                        isLabelVisible: libraryState.storefrontFilter != null,
                        backgroundColor: colorScheme.primary,
                        smallSize: 8,
                        child: Icon(
                          libraryState.storefrontFilter != null
                              ? libraryState.storefrontFilter!.fallbackIcon
                              : Icons.filter_list_rounded,
                          color: libraryState.storefrontFilter != null
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant,
                        ),
                      ),
                      tooltip: 'Filter by Platform',
                      onPressed: () => _showPlatformFilterSheet(context, libraryState, notifier),
                    ),
                  ],
                  elevation: const WidgetStatePropertyAll(0),
                  backgroundColor: WidgetStatePropertyAll(colorScheme.surfaceContainerHigh),
                  onChanged: (val) {
                    notifier.setSearchQuery(val);
                    setState(() {});
                  },
                ),
              ),

              // TabBar for Statuses & Custom Categories (Synced with TabBarView for swiping)
              TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                indicatorSize: TabBarIndicatorSize.label,
                indicatorWeight: 3,
                indicatorColor: colorScheme.primary,
                labelColor: colorScheme.primary,
                unselectedLabelColor: colorScheme.onSurfaceVariant,
                labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 13),
                tabs: visibleTabs.map((tab) {
                  int count = 0;
                  if (tab.type == HomeTabType.status) {
                    if (tab.status == null) {
                      count = libraryState.allGames.length;
                    } else {
                      count = libraryState.allGames.where((g) => g.status == tab.status).length;
                    }
                  } else if (tab.customCategoryId != null) {
                    count = libraryState.allGames
                        .where((g) => g.customCategories.contains(tab.customCategoryId))
                        .length;
                  }
                  return Tab(text: '${tab.label} ($count)');
                }).toList(),
              ),
            ],
          ),
        ),
      ),
      // Swipeable TabBarView across all visible tabs
      body: TabBarView(
        controller: _tabController,
        children: visibleTabs.map((tab) {
          return _buildGameListForTab(context, tab, libraryState);
        }).toList(),
      ),
    );
  }

  Widget _buildGameListForTab(BuildContext context, HomeTabConfig tab, LibraryState libraryState) {
    // Filter games by tab type, search query, and storefront filter
    var games = List<GameEntry>.from(libraryState.allGames);

    if (tab.type == HomeTabType.status) {
      if (tab.status != null) {
        games = games.where((g) => g.status == tab.status).toList();
      }
    } else if (tab.type == HomeTabType.custom && tab.customCategoryId != null) {
      games = games.where((g) => g.customCategories.contains(tab.customCategoryId)).toList();
    }

    if (libraryState.storefrontFilter != null) {
      games = games.where((g) => g.storefront == libraryState.storefrontFilter).toList();
    }

    if (libraryState.searchQuery.trim().isNotEmpty) {
      final query = libraryState.searchQuery.trim().toLowerCase();
      games = games.where((g) {
        return g.title.toLowerCase().contains(query) ||
            g.genres.any((genre) => genre.toLowerCase().contains(query)) ||
            g.notes.toLowerCase().contains(query);
      }).toList();
    }

    // Apply sorting
    final dir = libraryState.sortAscending ? 1 : -1;
    switch (libraryState.sortOption) {
      case LibrarySortOption.lastUpdated:
        games.sort((a, b) => dir * a.updatedAt.compareTo(b.updatedAt));
        break;
      case LibrarySortOption.playtimeDesc:
        games.sort((a, b) => dir * a.totalMinutesPlayed.compareTo(b.totalMinutesPlayed));
        break;
      case LibrarySortOption.costPerHourAsc:
        games.sort((a, b) {
          final costA = a.costPerHour;
          final costB = b.costPerHour;
          if (costA == null && costB == null) return 0;
          if (costA == null) return 1;
          if (costB == null) return -1;
          return dir * costA.compareTo(costB);
        });
        break;
      case LibrarySortOption.ratingDesc:
        games.sort((a, b) => dir * a.personalRating.compareTo(b.personalRating));
        break;
      case LibrarySortOption.priceDesc:
        games.sort((a, b) => dir * a.totalSpent.compareTo(b.totalSpent));
        break;
      case LibrarySortOption.titleAsc:
        games.sort((a, b) => dir * a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
    }

    if (games.isEmpty) {
      return _buildEmptyState(context, libraryState.allGames.isEmpty);
    }

    // List view
    if (libraryState.viewMode == LibraryViewMode.list) {
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        itemCount: games.length,
        itemBuilder: (context, index) {
          final game = games[index];
          return GameListRow(
            game: game,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DossierScreen(gameId: game.id),
                ),
              );
            },
          );
        },
      );
    }

    // Grid view (2, 3, or 4 columns)
    final cols = libraryState.viewMode.columns;
    final double childAspect = cols == 4 ? (3 / 4.8) : (cols == 3 ? (3 / 4.6) : (3 / 4.4));
    final double spacing = cols == 4 ? 8.0 : (cols == 3 ? 10.0 : 14.0);

    return GridView.builder(
      padding: EdgeInsets.all(spacing),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        childAspectRatio: childAspect,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
      ),
      itemCount: games.length,
      itemBuilder: (context, index) {
        final game = games[index];
        return GameCoverCard(
          game: game,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DossierScreen(gameId: game.id),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isLibraryEmpty) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isLibraryEmpty ? Icons.sports_esports_outlined : Icons.search_off_rounded,
                size: 48,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isLibraryEmpty ? 'Your Library is Empty' : 'No Matching Titles',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isLibraryEmpty
                  ? 'Track games across multiple storefronts with real-time ROI.\nTap the "+ Add Game" button below to add your first title.'
                  : 'Try clearing your search query or choosing another platform tab.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
