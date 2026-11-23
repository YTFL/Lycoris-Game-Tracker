import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../core/constants/api_constants.dart';
import 'igdb_cache_service.dart';

class IGDBSearchResult {
  final int id;
  final String title;
  final String? summary;
  final String? coverBigUrl;
  final String? cover720pUrl;
  final List<String> genres;
  final DateTime? releaseDate;

  const IGDBSearchResult({
    required this.id,
    required this.title,
    this.summary,
    this.coverBigUrl,
    this.cover720pUrl,
    required this.genres,
    this.releaseDate,
  });

  factory IGDBSearchResult.fromJson(Map<String, dynamic> json) {
    // If deserializing from local cache
    if (json.containsKey('title') && !json.containsKey('name')) {
      return IGDBSearchResult.fromCacheJson(json);
    }

    final coverData = json['cover'] as Map<String, dynamic>?;
    final imageId = coverData?['image_id'] as String?;

    final genresList = (json['genres'] as List<dynamic>?)
            ?.map((g) => (g as Map<String, dynamic>)['name'] as String)
            .toList() ??
        <String>[];

    DateTime? releaseDate;
    if (json['first_release_date'] != null) {
      final timestamp = json['first_release_date'] as int;
      releaseDate = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    }

    return IGDBSearchResult(
      id: json['id'] as int,
      title: json['name'] as String,
      summary: json['summary'] as String?,
      coverBigUrl: imageId != null ? ApiConstants.coverBigUrl(imageId) : null,
      cover720pUrl: imageId != null ? ApiConstants.cover720pUrl(imageId) : null,
      genres: genresList,
      releaseDate: releaseDate,
    );
  }

  factory IGDBSearchResult.fromCacheJson(Map<dynamic, dynamic> map) {
    return IGDBSearchResult(
      id: map['id'] as int,
      title: map['title'] as String,
      summary: map['summary'] as String?,
      coverBigUrl: map['coverBigUrl'] as String?,
      cover720pUrl: map['cover720pUrl'] as String?,
      genres: (map['genres'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      releaseDate: map['releaseDate'] != null
          ? DateTime.tryParse(map['releaseDate'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'summary': summary,
        'coverBigUrl': coverBigUrl,
        'cover720pUrl': cover720pUrl,
        'genres': genres,
        'releaseDate': releaseDate?.toIso8601String(),
      };
}

class IGDBDlcResult {
  final int id;
  final String title;
  final String? summary;
  final String? coverBigUrl;
  final String? cover720pUrl;
  final DateTime? releaseDate;
  final int category;

  const IGDBDlcResult({
    required this.id,
    required this.title,
    this.summary,
    this.coverBigUrl,
    this.cover720pUrl,
    this.releaseDate,
    this.category = 1,
  });

  String get categoryLabel {
    switch (category) {
      case 1:
        return 'DLC / Addon';
      case 2:
        return 'Expansion';
      case 3:
        return 'Bundle';
      case 4:
        return 'Standalone Expansion';
      case 8:
        return 'Remap / Pack';
      case 9:
        return 'Season Pass';
      case 10:
        return 'Game Edition';
      default:
        return 'DLC / Extra';
    }
  }

  factory IGDBDlcResult.fromJson(Map<String, dynamic> json) {
    final coverData = json['cover'] as Map<String, dynamic>?;
    final imageId = coverData?['image_id'] as String?;

    DateTime? releaseDate;
    if (json['first_release_date'] != null) {
      final timestamp = json['first_release_date'] as int;
      releaseDate = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    }

    return IGDBDlcResult(
      id: json['id'] as int,
      title: json['name'] as String? ?? 'Untitled DLC',
      summary: json['summary'] as String?,
      coverBigUrl: imageId != null ? ApiConstants.coverBigUrl(imageId) : null,
      cover720pUrl: imageId != null ? ApiConstants.cover720pUrl(imageId) : null,
      releaseDate: releaseDate,
      category: json['category'] as int? ?? 1,
    );
  }
}

class IGDBService {
  final Dio _dio;
  String _workerProxyUrl;
  String? _twitchClientId;
  String? _twitchClientSecret;
  IGDBCacheService? _cacheService;

  String? _cachedAppToken;
  DateTime? _tokenExpiresAt;

  IGDBService({
    Dio? dio,
    String? workerProxyUrl,
    String? twitchClientId,
    String? twitchClientSecret,
    IGDBCacheService? cacheService,
  })  : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
            )),
        _workerProxyUrl = workerProxyUrl ?? ApiConstants.igdbProxyUrl,
        // ignore: prefer_initializing_formals
        _twitchClientId = twitchClientId,
        // ignore: prefer_initializing_formals
        _twitchClientSecret = twitchClientSecret,
        // ignore: prefer_initializing_formals
        _cacheService = cacheService;

  void configure({
    String? workerProxyUrl,
    String? clientId,
    String? clientSecret,
    IGDBCacheService? cacheService,
  }) {
    if (workerProxyUrl != null && workerProxyUrl.trim().isNotEmpty) {
      _workerProxyUrl = workerProxyUrl.trim();
    }
    if (clientId != null) {
      _twitchClientId = clientId.trim().isEmpty ? null : clientId.trim();
    }
    if (clientSecret != null) {
      _twitchClientSecret = clientSecret.trim().isEmpty ? null : clientSecret.trim();
    }
    if (cacheService != null) {
      _cacheService = cacheService;
    }
  }

  bool get hasDirectTwitchCredentials =>
      _twitchClientId != null &&
      _twitchClientId!.isNotEmpty &&
      _twitchClientSecret != null &&
      _twitchClientSecret!.isNotEmpty;

  bool get isConfigured => true;

  Future<String?> _getTwitchAppToken() async {
    if (!hasDirectTwitchCredentials) return null;

    final now = DateTime.now();
    if (_cachedAppToken != null && _tokenExpiresAt != null && _tokenExpiresAt!.isAfter(now)) {
      return _cachedAppToken;
    }

    try {
      final tokenUrl =
          'https://id.twitch.tv/oauth2/token?client_id=${_twitchClientId!}&client_secret=${_twitchClientSecret!}&grant_type=client_credentials';
      final response = await _dio.post<dynamic>(tokenUrl);
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final token = data['access_token'] as String;
        final expiresIn = data['expires_in'] as int? ?? 3600;
        _cachedAppToken = token;
        _tokenExpiresAt = now.add(Duration(seconds: max(60, expiresIn - 300)));
        return token;
      }
    } catch (e) {
      debugPrint('[IGDBService] Direct Twitch OAuth token fetch failed: $e');
    }
    return null;
  }

  /// Tests connectivity with the configured proxy or direct IGDB endpoint
  Future<bool> testConnection() async {
    try {
      final results = await searchGames('Zelda', limit: 1, bypassCache: true);
      return results.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Searches IGDB for games matching query using APICalypse syntax.
  /// Checks client-side cache first unless [bypassCache] is true.
  /// Falls back to local cached entities on network error or HTTP 429 rate limit.
  Future<List<IGDBSearchResult>> searchGames(
    String query, {
    int limit = 15,
    bool bypassCache = false,
  }) async {
    final sanitizedQuery = query.replaceAll('"', '').trim();
    if (sanitizedQuery.isEmpty) return [];

    // 1. Client-Side Cache Lookup
    if (!bypassCache && _cacheService != null) {
      final cached = _cacheService!.getCachedQuery(sanitizedQuery);
      if (cached != null && cached.isNotEmpty) {
        return cached.take(limit).toList();
      }
    }

    final apicalypseQuery = '''
fields name, summary, cover.image_id, genres.name, first_release_date;
search "$sanitizedQuery";
limit $limit;
''';

    try {
      final rawList = await _postApicalypse(apicalypseQuery);
      final results = rawList
          .map((item) => IGDBSearchResult.fromJson(item as Map<String, dynamic>))
          .toList();

      // 3. Persist fresh results to local cache permanently
      if (_cacheService != null && results.isNotEmpty) {
        await _cacheService!.cacheQueryResults(sanitizedQuery, results);
      }

      return results;
    } catch (e) {
      debugPrint('[IGDBService] Network search failed ($e), checking offline entity cache...');
      // 4. Fallback to local cached entities on network error or HTTP 429 rate limit
      if (_cacheService != null) {
        final localMatches = _cacheService!.searchLocalEntities(sanitizedQuery, limit: limit);
        if (localMatches.isNotEmpty) {
          return localMatches;
        }
      }
      return [];
    }
  }

  /// Sends an APICalypse query payload to IGDB games endpoint
  Future<List<dynamic>> _postApicalypse(String apicalypseQuery) async {
    final Response<dynamic> response;

    if (hasDirectTwitchCredentials) {
      final token = await _getTwitchAppToken();
      if (token == null) {
        throw Exception('Unable to obtain Twitch App Access Token with provided credentials.');
      }

      response = await _dio.post<dynamic>(
        ApiConstants.igdbGamesEndpoint,
        data: apicalypseQuery,
        options: Options(
          headers: {
            'Client-ID': _twitchClientId!,
            'Authorization': 'Bearer $token',
            'Content-Type': 'text/plain',
          },
        ),
      );
    } else {
      var targetUrl = _workerProxyUrl;
      if (!targetUrl.endsWith('/games') && !targetUrl.endsWith('/v4/games')) {
        targetUrl = targetUrl.endsWith('/') ? '${targetUrl}games' : '$targetUrl/games';
      }

      response = await _dio.post<dynamic>(
        targetUrl,
        data: apicalypseQuery,
        options: Options(
          headers: {'Content-Type': 'text/plain'},
        ),
      );
    }

    return (response.data as List<dynamic>?) ?? [];
  }

  /// Fetches official DLCs, expansions, and add-ons associated with a parent game from IGDB.
  Future<List<IGDBDlcResult>> fetchGameDlcs(int parentIgdbId) async {
    if (parentIgdbId <= 0) return [];

    // 1. Primary Query: Query games where parent_game = parentIgdbId
    final primaryQuery = '''
fields name, summary, cover.image_id, first_release_date, category;
where parent_game = $parentIgdbId;
sort first_release_date asc;
limit 50;
''';

    try {
      final rawList = await _postApicalypse(primaryQuery);
      if (rawList.isNotEmpty) {
        return rawList
            .map((item) => IGDBDlcResult.fromJson(item as Map<String, dynamic>))
            .toList();
      }

      // 2. Fallback: Query parent game and expand dlcs & expansions
      final fallbackQuery = '''
fields dlcs.name, dlcs.summary, dlcs.cover.image_id, dlcs.first_release_date, dlcs.category,
       expansions.name, expansions.summary, expansions.cover.image_id, expansions.first_release_date, expansions.category;
where id = $parentIgdbId;
limit 1;
''';
      final fallbackList = await _postApicalypse(fallbackQuery);
      if (fallbackList.isNotEmpty) {
        final gameData = fallbackList.first as Map<String, dynamic>;
        final List<IGDBDlcResult> combined = [];

        if (gameData['dlcs'] is List) {
          for (final dlc in gameData['dlcs'] as List) {
            if (dlc is Map<String, dynamic>) {
              combined.add(IGDBDlcResult.fromJson(dlc));
            }
          }
        }
        if (gameData['expansions'] is List) {
          for (final exp in gameData['expansions'] as List) {
            if (exp is Map<String, dynamic>) {
              combined.add(IGDBDlcResult.fromJson(exp));
            }
          }
        }
        if (combined.isNotEmpty) {
          combined.sort((a, b) {
            if (a.releaseDate == null && b.releaseDate == null) return 0;
            if (a.releaseDate == null) return 1;
            if (b.releaseDate == null) return -1;
            return a.releaseDate!.compareTo(b.releaseDate!);
          });
          return combined;
        }
      }
    } catch (e) {
      debugPrint('[IGDBService] fetchGameDlcs failed for id $parentIgdbId: $e');
    }
    return [];
  }
}
