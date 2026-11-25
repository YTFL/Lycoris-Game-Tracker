import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models/custom_category.dart';
import '../../domain/models/home_tab_config.dart';
import '../../../sync/data/settings_repository.dart';
import '../../../tracker/presentation/controllers/library_notifier.dart';

class HomeTabsState {
  final List<HomeTabConfig> tabs;
  final List<CustomCategory> customCategories;

  const HomeTabsState({
    required this.tabs,
    required this.customCategories,
  });

  HomeTabsState copyWith({
    List<HomeTabConfig>? tabs,
    List<CustomCategory>? customCategories,
  }) {
    return HomeTabsState(
      tabs: tabs ?? this.tabs,
      customCategories: customCategories ?? this.customCategories,
    );
  }

  List<HomeTabConfig> get visibleTabs => tabs.where((t) => t.isVisible).toList();
}

final homeTabsNotifierProvider =
    StateNotifierProvider<HomeTabsNotifier, HomeTabsState>((ref) {
  final settingsRepo = ref.watch(settingsRepositoryProvider);
  return HomeTabsNotifier(settingsRepo, ref);
});

class HomeTabsNotifier extends StateNotifier<HomeTabsState> {
  final SettingsRepository _settingsRepo;
  final Ref _ref;

  HomeTabsNotifier(this._settingsRepo, this._ref)
      : super(_loadInitialState(_settingsRepo));

  static HomeTabsState _loadInitialState(SettingsRepository repo) {
    // 1. Load custom categories
    List<CustomCategory> categories = [];
    final catJson = repo.customCategoriesJson;
    if (catJson != null && catJson.isNotEmpty) {
      try {
        final decoded = jsonDecode(catJson) as List<dynamic>;
        categories = decoded
            .map((item) => CustomCategory.fromJson(item as Map<String, dynamic>))
            .toList();
      } catch (_) {
        categories = [];
      }
    }

    // 2. Load tabs config
    List<HomeTabConfig> tabs = [];
    final tabsJson = repo.homeTabsJson;
    if (tabsJson != null && tabsJson.isNotEmpty) {
      try {
        final decoded = jsonDecode(tabsJson) as List<dynamic>;
        tabs = decoded
            .map((item) => HomeTabConfig.fromJson(item as Map<String, dynamic>))
            .toList();
      } catch (_) {
        tabs = [];
      }
    }

    if (tabs.isEmpty) {
      tabs = HomeTabConfig.defaultTabs();
    } else {
      // Ensure all custom categories exist in tabs or are appended if missing
      for (final cat in categories) {
        final tabExists = tabs.any((t) => t.customCategoryId == cat.id);
        if (!tabExists) {
          tabs.add(HomeTabConfig(
            id: 'cat_${cat.id}',
            label: cat.name,
            type: HomeTabType.custom,
            isVisible: true,
            customCategoryId: cat.id,
          ));
        }
      }
      // Also update labels of custom tabs in case category name changed
      tabs = tabs.map((t) {
        if (t.type == HomeTabType.custom && t.customCategoryId != null) {
          final cat = categories.where((c) => c.id == t.customCategoryId).firstOrNull;
          if (cat != null && cat.name != t.label) {
            return t.copyWith(label: cat.name);
          }
        }
        return t;
      }).toList();
    }

    // Ensure at least one tab is visible
    if (!tabs.any((t) => t.isVisible)) {
      tabs[0] = tabs[0].copyWith(isVisible: true);
    }

    return HomeTabsState(
      tabs: tabs,
      customCategories: categories,
    );
  }

  Future<void> _saveState() async {
    final tabsJson = jsonEncode(state.tabs.map((t) => t.toJson()).toList());
    final catJson = jsonEncode(state.customCategories.map((c) => c.toJson()).toList());
    await _settingsRepo.setHomeTabsJson(tabsJson);
    await _settingsRepo.setCustomCategoriesJson(catJson);
  }

  Future<void> reorderTabs(int oldIndex, int newIndex) async {
    final list = List<HomeTabConfig>.from(state.tabs);
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);

    state = state.copyWith(tabs: list);
    await _saveState();
  }

  Future<bool> toggleTabVisibility(String id) async {
    final targetIndex = state.tabs.indexWhere((t) => t.id == id);
    if (targetIndex == -1) return false;

    final targetTab = state.tabs[targetIndex];
    // If currently visible and trying to hide, ensure at least one OTHER tab remains visible
    if (targetTab.isVisible) {
      final visibleCount = state.tabs.where((t) => t.isVisible).length;
      if (visibleCount <= 1) {
        return false; // Cannot hide the last remaining visible tab
      }
    }

    final updatedTabs = List<HomeTabConfig>.from(state.tabs);
    updatedTabs[targetIndex] = targetTab.copyWith(isVisible: !targetTab.isVisible);

    state = state.copyWith(tabs: updatedTabs);
    await _saveState();
    return true;
  }

  Future<CustomCategory> addCustomCategory(String name) async {
    final trimmedName = name.trim();
    final newId = const Uuid().v4();
    final newCategory = CustomCategory(
      id: newId,
      name: trimmedName,
      createdAt: DateTime.now(),
    );

    final updatedCategories = [...state.customCategories, newCategory];
    final newTab = HomeTabConfig(
      id: 'cat_$newId',
      label: trimmedName,
      type: HomeTabType.custom,
      isVisible: true,
      customCategoryId: newId,
    );
    final updatedTabs = [...state.tabs, newTab];

    state = state.copyWith(
      customCategories: updatedCategories,
      tabs: updatedTabs,
    );
    await _saveState();
    return newCategory;
  }

  Future<void> renameCustomCategory(String categoryId, String newName) async {
    final trimmedName = newName.trim();
    final updatedCategories = state.customCategories.map((cat) {
      if (cat.id == categoryId) {
        return cat.copyWith(name: trimmedName);
      }
      return cat;
    }).toList();

    final updatedTabs = state.tabs.map((tab) {
      if (tab.customCategoryId == categoryId) {
        return tab.copyWith(label: trimmedName);
      }
      return tab;
    }).toList();

    state = state.copyWith(
      customCategories: updatedCategories,
      tabs: updatedTabs,
    );
    await _saveState();
  }

  Future<void> deleteCustomCategory(String categoryId) async {
    // 1. Remove from custom categories list
    final updatedCategories =
        state.customCategories.where((c) => c.id != categoryId).toList();

    // 2. Remove tab from home tabs
    var updatedTabs =
        state.tabs.where((t) => t.customCategoryId != categoryId).toList();

    // Ensure at least one tab is visible
    if (!updatedTabs.any((t) => t.isVisible) && updatedTabs.isNotEmpty) {
      updatedTabs[0] = updatedTabs[0].copyWith(isVisible: true);
    } else if (updatedTabs.isEmpty) {
      updatedTabs = HomeTabConfig.defaultTabs();
    }

    state = state.copyWith(
      customCategories: updatedCategories,
      tabs: updatedTabs,
    );
    await _saveState();

    // 3. Remove this category reference from all games in LibraryNotifier
    await _ref.read(libraryNotifierProvider.notifier).removeCategoryFromAllGames(categoryId);
  }

  Future<void> resetToDefaults() async {
    // Keep custom categories in state so games don't lose them,
    // but reset tabs list to default status tabs + append custom categories at the end
    final defaultTabs = HomeTabConfig.defaultTabs();
    final customTabs = state.customCategories.map((cat) {
      return HomeTabConfig(
        id: 'cat_${cat.id}',
        label: cat.name,
        type: HomeTabType.custom,
        isVisible: true,
        customCategoryId: cat.id,
      );
    }).toList();

    final resetTabs = [...defaultTabs, ...customTabs];
    state = state.copyWith(tabs: resetTabs);
    await _saveState();
  }
}
