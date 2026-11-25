import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../home/domain/models/home_tab_config.dart';
import '../../../home/presentation/controllers/home_tabs_notifier.dart';
import '../../../tracker/presentation/controllers/library_notifier.dart';

class TabManagementScreen extends ConsumerStatefulWidget {
  const TabManagementScreen({super.key});

  @override
  ConsumerState<TabManagementScreen> createState() => _TabManagementScreenState();
}

class _TabManagementScreenState extends ConsumerState<TabManagementScreen> {
  void _showAddCategoryDialog(BuildContext context) {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colorScheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('New Custom Category', style: TextStyle(fontWeight: FontWeight.w700)),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Category Name',
              hintText: 'e.g. Favorites, Speedrun, Co-op',
              border: OutlineInputBorder(),
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return 'Please enter a category name';
              }
              final existing = ref
                  .read(homeTabsNotifierProvider)
                  .customCategories
                  .any((c) => c.name.toLowerCase() == val.trim().toLowerCase());
              if (existing) {
                return 'Category already exists';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (formKey.currentState?.validate() ?? false) {
                final categoryName = controller.text.trim();
                await ref
                    .read(homeTabsNotifierProvider.notifier)
                    .addCustomCategory(categoryName);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                }
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Added "$categoryName" category tab')),
                  );
                }
              }
            },
            child: const Text('Add Tab'),
          ),
        ],
      ),
    );
  }

  void _showRenameCategoryDialog(BuildContext context, String categoryId, String currentName) {
    final controller = TextEditingController(text: currentName);
    final formKey = GlobalKey<FormState>();
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colorScheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Rename Category', style: TextStyle(fontWeight: FontWeight.w700)),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'New Name',
              border: OutlineInputBorder(),
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return 'Please enter a name';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (formKey.currentState?.validate() ?? false) {
                await ref
                    .read(homeTabsNotifierProvider.notifier)
                    .renameCustomCategory(categoryId, controller.text.trim());
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteCategory(BuildContext context, String categoryId, String categoryName) {
    final colorScheme = Theme.of(context).colorScheme;
    final allGames = ref.read(libraryNotifierProvider).allGames;
    final gamesCount = allGames.where((g) => g.customCategories.contains(categoryId)).length;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colorScheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete "$categoryName"?', style: const TextStyle(fontWeight: FontWeight.w700)),
        content: Text(
          gamesCount > 0
              ? 'This category tab will be permanently deleted and removed from $gamesCount games in your library.'
              : 'This category tab will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: colorScheme.error),
            onPressed: () async {
              await ref
                  .read(homeTabsNotifierProvider.notifier)
                  .deleteCustomCategory(categoryId);
              if (ctx.mounted) {
                Navigator.pop(ctx);
              }
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Deleted category "$categoryName"')),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _confirmResetDefaults(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colorScheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Reset Tabs to Default?', style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text(
          'This will reset the tab order and visibility to the default layout. Your custom categories and their game assignments will be preserved.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              await ref.read(homeTabsNotifierProvider.notifier).resetToDefaults();
              if (ctx.mounted) {
                Navigator.pop(ctx);
              }
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Tabs reset to default layout')),
                );
              }
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tabsState = ref.watch(homeTabsNotifierProvider);
    final allGames = ref.watch(libraryNotifierProvider).allGames;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customize Home Tabs'),
        actions: [
          IconButton(
            tooltip: 'Reset to default order',
            icon: const Icon(Icons.restore_rounded),
            onPressed: () => _confirmResetDefaults(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: colorScheme.surfaceContainer,
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, size: 20, color: colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Drag tabs to reorder. Toggle visibility switch to hide status tabs. Add custom category tabs for personalized organization.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ReorderableListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: tabsState.tabs.length,
              onReorderItem: (oldIndex, newIndex) {
                ref.read(homeTabsNotifierProvider.notifier).reorderTabs(oldIndex, newIndex);
              },
              itemBuilder: (context, index) {
                final tab = tabsState.tabs[index];
                final isCustom = tab.type == HomeTabType.custom;

                int count = 0;
                if (!isCustom) {
                  if (tab.status == null) {
                    count = allGames.length;
                  } else {
                    count = allGames.where((g) => g.status == tab.status).length;
                  }
                } else if (tab.customCategoryId != null) {
                  count = allGames
                      .where((g) => g.customCategories.contains(tab.customCategoryId))
                      .length;
                }

                return Card(
                  key: ValueKey(tab.id),
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  elevation: 0,
                  color: tab.isVisible
                      ? colorScheme.surfaceContainerHigh
                      : colorScheme.surfaceContainerHighest.withAlpha(120),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: tab.isVisible
                          ? colorScheme.outlineVariant.withAlpha(60)
                          : colorScheme.outlineVariant.withAlpha(20),
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                    leading: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ReorderableDragStartListener(
                          index: index,
                          child: Icon(
                            Icons.drag_indicator_rounded,
                            color: colorScheme.onSurfaceVariant.withAlpha(160),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isCustom
                                ? colorScheme.tertiaryContainer
                                : colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            isCustom ? Icons.label_rounded : Icons.filter_alt_rounded,
                            size: 18,
                            color: isCustom
                                ? colorScheme.onTertiaryContainer
                                : colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                    title: Row(
                      children: [
                        Flexible(
                          child: Text(
                            tab.label,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: tab.isVisible
                                  ? colorScheme.onSurface
                                  : colorScheme.onSurface.withAlpha(120),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$count',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Text(
                      isCustom ? 'Custom Category' : 'Main Status Tab',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant.withAlpha(160),
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isCustom && tab.customCategoryId != null) ...[
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 20),
                            tooltip: 'Rename category',
                            onPressed: () => _showRenameCategoryDialog(
                              context,
                              tab.customCategoryId!,
                              tab.label,
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete_outline_rounded,
                                size: 20, color: colorScheme.error),
                            tooltip: 'Delete custom category',
                            onPressed: () => _confirmDeleteCategory(
                              context,
                              tab.customCategoryId!,
                              tab.label,
                            ),
                          ),
                        ],
                        Switch(
                          value: tab.isVisible,
                          onChanged: (val) async {
                            final success = await ref
                                .read(homeTabsNotifierProvider.notifier)
                                .toggleTabVisibility(tab.id);
                            if (!success && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('At least one tab must remain visible.'),
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddCategoryDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Custom Category'),
      ),
    );
  }
}
