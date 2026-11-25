// ignore: depend_on_referenced_packages
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Permanent disk cache manager for saved game cover artworks.
/// Prevents [DefaultCacheManager]'s 30-day / 200-object eviction from
/// re-fetching IGDB cover images over the network.
class CoverImageCacheManager {
  static const String key = 'lycoris_cover_cache';

  static final CacheManager instance = CacheManager(
    Config(
      key,
      stalePeriod: const Duration(days: 3650),
      maxNrOfCacheObjects: 5000,
    ),
  );
}
