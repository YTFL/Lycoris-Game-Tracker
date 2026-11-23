class AppUpdate {
  final String version;
  final int buildNumber;
  final String changelog;
  final String? downloadUrl;
  final DateTime? publishedAt;

  const AppUpdate({
    required this.version,
    required this.buildNumber,
    required this.changelog,
    this.downloadUrl,
    this.publishedAt,
  });

  /// Parse JSON response from update.json or GitHub API
  factory AppUpdate.fromJson(Map<String, dynamic> json) {
    final rawVersion = (json['version'] as String? ?? '0.0.0').replaceFirst(RegExp(r'^v'), '').trim();
    final buildNumberValue = json['buildNumber'] ?? json['build_number'];
    final parsedBuildNumber = switch (buildNumberValue) {
      int value => value,
      String value => int.tryParse(value) ?? 0,
      _ => 0,
    };

    DateTime? publishedDate;
    if (json['published_at'] != null) {
      publishedDate = DateTime.tryParse(json['published_at'].toString());
    } else if (json['publishedAt'] != null) {
      publishedDate = DateTime.tryParse(json['publishedAt'].toString());
    }

    return AppUpdate(
      version: rawVersion,
      buildNumber: parsedBuildNumber,
      changelog: json['changelog'] as String? ?? json['body'] as String? ?? '',
      downloadUrl: json['downloadUrl'] as String? ?? json['download_url'] as String?,
      publishedAt: publishedDate,
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'buildNumber': buildNumber,
      'changelog': changelog,
      if (downloadUrl != null) 'downloadUrl': downloadUrl,
      if (publishedAt != null) 'publishedAt': publishedAt!.toIso8601String(),
    };
  }

  /// Create a copy with selected fields overridden
  AppUpdate copyWith({
    String? version,
    int? buildNumber,
    String? changelog,
    String? downloadUrl,
    DateTime? publishedAt,
  }) {
    return AppUpdate(
      version: version ?? this.version,
      buildNumber: buildNumber ?? this.buildNumber,
      changelog: changelog ?? this.changelog,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      publishedAt: publishedAt ?? this.publishedAt,
    );
  }

  /// Compare two semantic version strings: returns 1 if left > right, -1 if left < right, 0 if equal.
  static int compareVersions(String left, String right) {
    List<int> parseVersion(String version) {
      final clean = version.replaceFirst(RegExp(r'^v'), '').trim();
      final base = clean.split('+')[0];
      return base.split('.').map((part) {
        final digits = RegExp(r'\d+').firstMatch(part)?.group(0);
        return int.tryParse(digits ?? '') ?? 0;
      }).toList();
    }

    final leftParts = parseVersion(left);
    final rightParts = parseVersion(right);

    final maxLength = [leftParts.length, rightParts.length].reduce((a, b) => a > b ? a : b);
    while (leftParts.length < maxLength) {
      leftParts.add(0);
    }
    while (rightParts.length < maxLength) {
      rightParts.add(0);
    }

    for (int index = 0; index < maxLength; index++) {
      if (leftParts[index] > rightParts[index]) return 1;
      if (leftParts[index] < rightParts[index]) return -1;
    }

    return 0;
  }

  /// Returns true if newVersion is strictly greater than currentVersion
  static bool isVersionGreater(String newVersion, String currentVersion) {
    return compareVersions(newVersion, currentVersion) > 0;
  }

  String get versionInfo => 'v$version';

  @override
  String toString() =>
      'AppUpdate(version: $version, buildNumber: $buildNumber, downloadUrl: $downloadUrl)';
}
