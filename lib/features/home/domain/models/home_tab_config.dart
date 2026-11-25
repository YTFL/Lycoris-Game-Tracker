import '../../../tracker/domain/models/game_status.dart';

enum HomeTabType {
  status,
  custom,
}

class HomeTabConfig {
  final String id;
  final String label;
  final HomeTabType type;
  final GameStatus? status;
  final bool isVisible;
  final String? customCategoryId;

  const HomeTabConfig({
    required this.id,
    required this.label,
    required this.type,
    this.status,
    this.isVisible = true,
    this.customCategoryId,
  });

  HomeTabConfig copyWith({
    String? id,
    String? label,
    HomeTabType? type,
    GameStatus? status,
    bool? isVisible,
    String? customCategoryId,
  }) {
    return HomeTabConfig(
      id: id ?? this.id,
      label: label ?? this.label,
      type: type ?? this.type,
      status: status ?? this.status,
      isVisible: isVisible ?? this.isVisible,
      customCategoryId: customCategoryId ?? this.customCategoryId,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'type': type.name,
    'status': status?.index,
    'isVisible': isVisible,
    'customCategoryId': customCategoryId,
  };

  factory HomeTabConfig.fromJson(Map<String, dynamic> json) {
    final typeName = json['type'] as String? ?? 'status';
    final type = HomeTabType.values.firstWhere(
      (e) => e.name == typeName,
      orElse: () => HomeTabType.status,
    );

    GameStatus? status;
    if (json['status'] != null) {
      final statusIdx = json['status'] as int;
      if (statusIdx >= 0 && statusIdx < GameStatus.values.length) {
        status = GameStatus.values[statusIdx];
      }
    }

    return HomeTabConfig(
      id: json['id'] as String,
      label: json['label'] as String,
      type: type,
      status: status,
      isVisible: json['isVisible'] as bool? ?? true,
      customCategoryId: json['customCategoryId'] as String?,
    );
  }

  static List<HomeTabConfig> defaultTabs() {
    return [
      const HomeTabConfig(
        id: 'status_all',
        label: 'All',
        type: HomeTabType.status,
        status: null,
        isVisible: true,
      ),
      const HomeTabConfig(
        id: 'status_playing',
        label: 'Playing',
        type: HomeTabType.status,
        status: GameStatus.playing,
        isVisible: true,
      ),
      const HomeTabConfig(
        id: 'status_backlog',
        label: 'Backlog',
        type: HomeTabType.status,
        status: GameStatus.backlog,
        isVisible: true,
      ),
      const HomeTabConfig(
        id: 'status_completed',
        label: 'Completed',
        type: HomeTabType.status,
        status: GameStatus.completed,
        isVisible: true,
      ),
      const HomeTabConfig(
        id: 'status_mastered',
        label: 'Mastered',
        type: HomeTabType.status,
        status: GameStatus.mastered,
        isVisible: true,
      ),
      const HomeTabConfig(
        id: 'status_abandoned',
        label: 'Abandoned',
        type: HomeTabType.status,
        status: GameStatus.abandoned,
        isVisible: true,
      ),
      const HomeTabConfig(
        id: 'status_wishlist',
        label: 'Wishlist',
        type: HomeTabType.status,
        status: GameStatus.wishlist,
        isVisible: true,
      ),
    ];
  }
}
