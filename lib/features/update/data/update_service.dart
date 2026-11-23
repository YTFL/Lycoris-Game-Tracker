import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

import '../../sync/data/settings_repository.dart';
import '../domain/models/app_update_model.dart';

enum InstallResult {
  installerStarted,
  permissionRequired,
  installerUnavailable,
  failed,
}

class UpdateService {
  final SettingsRepository? _settingsRepository;
  final Dio _dio;

  static const String repoOwner = 'YTFL';
  static const String repoName = 'Lycoris-Game-Tracker';

  static const String updateJsonUrl =
      'https://raw.githubusercontent.com/$repoOwner/$repoName/main/update.json';
  static const String latestReleaseUrl =
      'https://api.github.com/repos/$repoOwner/$repoName/releases/latest';

  static const platform = MethodChannel('com.ytfl.lycoris/update');
  static const Duration reminderPeriod = Duration(hours: 24);

  UpdateService([this._settingsRepository, Dio? dio]) : _dio = dio ?? Dio();

  /// Check if a newer version exists on GitHub
  Future<AppUpdate?> checkForUpdate({bool respectDeferral = true}) async {
    try {
      // 1. Check if user deferred update notifications
      if (respectDeferral && _settingsRepository != null) {
        final deferredUntil = _settingsRepository.updateDeferredUntil;
        if (deferredUntil != null && DateTime.now().isBefore(deferredUntil)) {
          debugPrint('UpdateService: Update check deferred until $deferredUntil');
          return null;
        }
      }

      // 2. Fetch remote update metadata (try update.json first, fallback to releases API)
      final remoteUpdate = await fetchRemoteUpdate();
      if (remoteUpdate == null) return null;

      // 3. Compare with current running package version
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      final currentBuildNumber = int.tryParse(packageInfo.buildNumber) ?? 0;

      final versionComparison = AppUpdate.compareVersions(
        remoteUpdate.version,
        currentVersion,
      );

      final hasUpdateAvailable = versionComparison > 0 ||
          (versionComparison == 0 && remoteUpdate.buildNumber > currentBuildNumber);

      await _settingsRepository?.setLastUpdateCheckAt(DateTime.now());

      if (hasUpdateAvailable) {
        return remoteUpdate;
      }

      // Latest version already installed; prune any residual APKs
      await deleteDownloadedAPK();
      return null;
    } catch (e) {
      debugPrint('UpdateService: Error during checkForUpdate: $e');
      return null;
    }
  }

  /// Primary fetch: checks update.json, then enriches with release notes and assets
  Future<AppUpdate?> fetchRemoteUpdate() async {
    try {
      // 1. Try raw update.json
      try {
        final response = await _dio.get<String>(
          updateJsonUrl,
          options: Options(
            responseType: ResponseType.plain,
            sendTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
          ),
        );

        if (response.statusCode == 200 && response.data != null) {
          final decoded = jsonDecode(response.data!) as Map<String, dynamic>;
          final updateFromJson = AppUpdate.fromJson(decoded);

          // Enrich with release notes & download URL from GitHub release API
          final enriched = await _enrichWithGitHubRelease(updateFromJson);
          return enriched;
        }
      } catch (e) {
        debugPrint('UpdateService: update.json not reachable, attempting releases/latest API fallback: $e');
      }

      // 2. Fallback: query GitHub Releases API directly
      return await _fetchFromGitHubLatestRelease();
    } catch (e) {
      debugPrint('UpdateService: Failed to fetch remote update info: $e');
      return null;
    }
  }

  /// Query GitHub Releases API for the latest published release
  Future<AppUpdate?> _fetchFromGitHubLatestRelease() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        latestReleaseUrl,
        options: Options(
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data!;
        final tagName = (data['tag_name'] as String? ?? '1.0.0').replaceFirst(RegExp(r'^v'), '');
        final body = data['body'] as String? ?? '';
        final publishedAtStr = data['published_at'] as String?;
        final publishedAt = publishedAtStr != null ? DateTime.tryParse(publishedAtStr) : null;

        // Extract APK download URL from release assets
        final downloadUrl = _findApkUrlFromAssets(data['assets'] as List<dynamic>?);

        return AppUpdate(
          version: tagName,
          buildNumber: 1, // Default fallback if build number not parsed from tag
          changelog: sanitizeReleaseNotes(body),
          downloadUrl: downloadUrl ??
              'https://github.com/$repoOwner/$repoName/releases/download/v$tagName/Lycoris-v$tagName.apk',
          publishedAt: publishedAt,
        );
      }
    } catch (e) {
      debugPrint('UpdateService: Error fetching from GitHub latest release API: $e');
    }
    return null;
  }

  /// Enrich metadata from update.json by pulling release notes from the tag release API
  Future<AppUpdate> _enrichWithGitHubRelease(AppUpdate baseUpdate) async {
    try {
      final tagUrl =
          'https://api.github.com/repos/$repoOwner/$repoName/releases/tags/v${baseUpdate.version}';

      final response = await _dio.get<Map<String, dynamic>>(
        tagUrl,
        options: Options(
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data!;
        final body = data['body'] as String? ?? '';
        final apkUrl = _findApkUrlFromAssets(data['assets'] as List<dynamic>?);
        final publishedAtStr = data['published_at'] as String?;

        return baseUpdate.copyWith(
          changelog: body.isNotEmpty ? sanitizeReleaseNotes(body) : baseUpdate.changelog,
          downloadUrl: baseUpdate.downloadUrl ?? apkUrl,
          publishedAt: publishedAtStr != null ? DateTime.tryParse(publishedAtStr) : baseUpdate.publishedAt,
        );
      }
    } catch (e) {
      debugPrint('UpdateService: Could not enrich release details from GitHub API: $e');
    }

    // Default fallback download URL if none exists
    final finalUrl = baseUpdate.downloadUrl ??
        'https://github.com/$repoOwner/$repoName/releases/download/v${baseUpdate.version}/Lycoris-v${baseUpdate.version}.apk';
    return baseUpdate.copyWith(downloadUrl: finalUrl);
  }

  /// Locate .apk asset download URL from GitHub release assets
  static String? _findApkUrlFromAssets(List<dynamic>? assets) {
    if (assets == null || assets.isEmpty) return null;
    for (final asset in assets) {
      if (asset is Map<String, dynamic>) {
        final name = (asset['name'] as String? ?? '').toLowerCase();
        if (name.endsWith('.apk')) {
          return asset['browser_download_url'] as String?;
        }
      }
    }
    return null;
  }

  /// Download APK file with progress streaming to application documents directory
  Future<File?> downloadAPK(
    String remoteVersion, {
    String? downloadUrl,
    void Function(double progress)? onProgress,
    CancelToken? cancelToken,
  }) async {
    try {
      final apkUrl = downloadUrl ??
          'https://github.com/$repoOwner/$repoName/releases/download/v$remoteVersion/Lycoris-v$remoteVersion.apk';

      final dir = await getApplicationDocumentsDirectory();
      final targetPath = '${dir.path}/lycoris-update.apk';
      final targetFile = File(targetPath);

      if (await targetFile.exists()) {
        await targetFile.delete();
      }

      await _dio.download(
        apkUrl,
        targetPath,
        cancelToken: cancelToken,
        onReceiveProgress: (received, total) {
          if (total > 0 && onProgress != null) {
            onProgress((received / total).clamp(0.0, 1.0));
          }
        },
      );

      if (await targetFile.exists()) {
        onProgress?.call(1.0);
        return targetFile;
      }
      return null;
    } catch (e) {
      debugPrint('UpdateService: Error downloading APK: $e');
      return null;
    }
  }

  /// Install downloaded APK file via Android intent or OpenFilex
  Future<InstallResult> installAPK(File apkFile) async {
    try {
      if (!Platform.isAndroid) {
        return InstallResult.failed;
      }

      // Check if file exists
      if (!await apkFile.exists()) {
        return InstallResult.failed;
      }

      // 1. Try native MethodChannel for full Android 8+ unknown sources handling
      try {
        final result = await platform.invokeMethod<String>(
          'installAPK',
          {'apkPath': apkFile.path},
        );

        if (result == 'installer_started') {
          return InstallResult.installerStarted;
        } else if (result == 'permission_required') {
          return InstallResult.permissionRequired;
        } else if (result == 'installer_not_found') {
          return InstallResult.installerUnavailable;
        }
      } catch (nativeErr) {
        debugPrint('UpdateService: Native install channel error: $nativeErr');
      }

      // 2. Fallback to OpenFilex
      final openResult = await OpenFilex.open(
        apkFile.path,
        type: 'application/vnd.android.package-archive',
      );

      switch (openResult.type) {
        case ResultType.done:
          return InstallResult.installerStarted;
        case ResultType.noAppToOpen:
          return InstallResult.installerUnavailable;
        case ResultType.permissionDenied:
          return InstallResult.permissionRequired;
        case ResultType.fileNotFound:
        case ResultType.error:
          return InstallResult.failed;
      }
    } catch (e) {
      debugPrint('UpdateService: Error executing installAPK: $e');
      return InstallResult.failed;
    }
  }

  /// Open Android install unknown apps permission settings page for this app
  Future<void> openInstallPermissionSettings() async {
    try {
      if (Platform.isAndroid) {
        await platform.invokeMethod('openInstallPermissionSettings');
      }
    } catch (e) {
      debugPrint('UpdateService: Could not open install permission settings: $e');
    }
  }

  /// Delete local downloaded APK to free disk space
  Future<void> deleteDownloadedAPK() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final apkPath = '${dir.path}/lycoris-update.apk';
      final file = File(apkPath);
      if (await file.exists()) {
        await file.delete();
        debugPrint('UpdateService: Purged existing APK: $apkPath');
      }
    } catch (e) {
      debugPrint('UpdateService: Error purging downloaded APK: $e');
    }
  }

  /// Suppress update notifications for reminder period (24 hours)
  Future<void> deferUpdate() async {
    final deferUntil = DateTime.now().add(reminderPeriod);
    await _settingsRepository?.setUpdateDeferredUntil(deferUntil);
  }

  /// Clear any active deferral
  Future<void> clearDeferral() async {
    await _settingsRepository?.clearUpdateDeferral();
  }

  /// Sanitize markdown release notes for clean in-app display
  static String sanitizeReleaseNotes(String markdown) {
    final normalized = markdown.replaceAll('\r\n', '\n').trim();
    if (normalized.isEmpty) return normalized;

    var lines = normalized.split('\n');
    lines = _removeTopHeaderBlock(lines);
    lines = _removeInstallationSection(lines);
    lines = _removeTrailingDividersAndFooters(lines);

    return lines.join('\n').trim();
  }

  static List<String> _removeTopHeaderBlock(List<String> lines) {
    if (lines.isEmpty) return lines;
    final firstNonEmptyIndex = lines.indexWhere((l) => l.trim().isNotEmpty);
    if (firstNonEmptyIndex == -1) return lines;

    final firstNonEmpty = lines[firstNonEmptyIndex].trim();
    if (!firstNonEmpty.startsWith('# ')) {
      return lines;
    }

    final separatorIndex = lines.indexWhere(
      (l) => l.trim() == '---',
      firstNonEmptyIndex,
    );
    if (separatorIndex == -1) return lines;

    return lines.sublist(separatorIndex + 1);
  }

  static List<String> _removeInstallationSection(List<String> lines) {
    if (lines.isEmpty) return lines;
    final installationHeaderRegex = RegExp(r'^##\s+.*installation', caseSensitive: false);
    final sectionHeaderRegex = RegExp(r'^##\s+');

    final startIndex = lines.indexWhere((l) => installationHeaderRegex.hasMatch(l.trim()));
    if (startIndex == -1) return lines;

    var endIndex = lines.length;
    for (var i = startIndex + 1; i < lines.length; i++) {
      if (sectionHeaderRegex.hasMatch(lines[i].trim())) {
        endIndex = i;
        break;
      }
    }

    return [...lines.sublist(0, startIndex), ...lines.sublist(endIndex)];
  }

  static List<String> _removeTrailingDividersAndFooters(List<String> lines) {
    final copy = List<String>.from(lines);
    while (copy.isNotEmpty) {
      final trimmed = copy.last.trim();
      final lower = trimmed.toLowerCase();
      if (trimmed.isEmpty ||
          trimmed == '---' ||
          trimmed == '***' ||
          trimmed == '___' ||
          lower.startsWith('for full history') ||
          lower.startsWith('see [changelog.md]') ||
          lower.startsWith('for full details')) {
        copy.removeLast();
      } else {
        break;
      }
    }
    return copy;
  }
}
