import 'package:flutter_test/flutter_test.dart';
import 'package:lycoris/features/update/data/update_service.dart';
import 'package:lycoris/features/update/domain/models/app_update_model.dart';

void main() {
  group('AppUpdate Model & Version Comparison', () {
    test('compareVersions correctly identifies higher, lower, and equal versions', () {
      // Greater versions
      expect(AppUpdate.compareVersions('1.0.1', '1.0.0'), equals(1));
      expect(AppUpdate.compareVersions('1.1.0', '1.0.9'), equals(1));
      expect(AppUpdate.compareVersions('2.0.0', '1.99.99'), equals(1));
      expect(AppUpdate.compareVersions('1.10.0', '1.9.0'), equals(1));
      expect(AppUpdate.compareVersions('v1.0.1', '1.0.0'), equals(1));

      // Lesser versions
      expect(AppUpdate.compareVersions('1.0.0', '1.0.1'), equals(-1));
      expect(AppUpdate.compareVersions('0.9.9', '1.0.0'), equals(-1));

      // Equal versions
      expect(AppUpdate.compareVersions('1.0.0', '1.0.0'), equals(0));
      expect(AppUpdate.compareVersions('v1.0.0', '1.0.0'), equals(0));
      expect(AppUpdate.compareVersions('1.0', '1.0.0'), equals(0));
      expect(AppUpdate.compareVersions('1.0.0+2', '1.0.0+1'), equals(0));
    });

    test('isVersionGreater returns boolean properly', () {
      expect(AppUpdate.isVersionGreater('1.0.1', '1.0.0'), isTrue);
      expect(AppUpdate.isVersionGreater('1.0.0', '1.0.1'), isFalse);
      expect(AppUpdate.isVersionGreater('1.0.0', '1.0.0'), isFalse);
    });

    test('fromJson correctly parses complete JSON', () {
      final json = {
        'version': 'v1.2.3',
        'buildNumber': 42,
        'changelog': '## Enhancements\n- Added auto update',
        'downloadUrl': 'https://example.com/lycoris.apk',
        'published_at': '2026-10-24T12:00:00.000Z',
      };

      final update = AppUpdate.fromJson(json);
      expect(update.version, equals('1.2.3'));
      expect(update.buildNumber, equals(42));
      expect(update.changelog, contains('Added auto update'));
      expect(update.downloadUrl, equals('https://example.com/lycoris.apk'));
      expect(update.publishedAt, equals(DateTime.parse('2026-10-24T12:00:00.000Z')));
      expect(update.versionInfo, equals('v1.2.3'));
    });

    test('fromJson handles string build numbers and fallbacks', () {
      final json = {
        'version': '2.0.0',
        'buildNumber': '15',
        'body': 'Release notes from GitHub API',
      };

      final update = AppUpdate.fromJson(json);
      expect(update.version, equals('2.0.0'));
      expect(update.buildNumber, equals(15));
      expect(update.changelog, equals('Release notes from GitHub API'));
      expect(update.downloadUrl, isNull);
    });

    test('toJson produces expected structure', () {
      const update = AppUpdate(
        version: '1.0.1',
        buildNumber: 2,
        changelog: 'Changelog text',
        downloadUrl: 'https://example.com/app.apk',
      );

      final json = update.toJson();
      expect(json['version'], equals('1.0.1'));
      expect(json['buildNumber'], equals(2));
      expect(json['changelog'], equals('Changelog text'));
      expect(json['downloadUrl'], equals('https://example.com/app.apk'));
    });
  });

  group('UpdateService.sanitizeReleaseNotes', () {
    test('removes top level # header and metadata block before ---', () {
      const rawMarkdown = '''
# Lycoris Version 1.0.0 Release Notes

**Release Date:** October 24, 2026  
**License:** AGPL-3.0  

---

## Features
- Added game cover carousel
- Added financial ROI analysis
''';

      final sanitized = UpdateService.sanitizeReleaseNotes(rawMarkdown);
      expect(sanitized.startsWith('# Lycoris'), isFalse);
      expect(sanitized.contains('**Release Date:**'), isFalse);
      expect(sanitized.contains('## Features'), isTrue);
      expect(sanitized.contains('Added game cover carousel'), isTrue);
    });

    test('removes installation instructions section', () {
      const rawMarkdown = '''
## Features
- Improved cloud sync

## Installation
1. Download the APK below
2. Tap install

## Bug Fixes
- Fixed currency conversion rounding
''';

      final sanitized = UpdateService.sanitizeReleaseNotes(rawMarkdown);
      expect(sanitized.contains('## Installation'), isFalse);
      expect(sanitized.contains('Download the APK below'), isFalse);
      expect(sanitized.contains('## Features'), isTrue);
      expect(sanitized.contains('## Bug Fixes'), isTrue);
    });

    test('removes trailing dividers and footers', () {
      const rawMarkdown = '''
## What's New
- New feature A
- New feature B

---
For full details, see CHANGELOG.md
---
''';

      final sanitized = UpdateService.sanitizeReleaseNotes(rawMarkdown);
      expect(sanitized.endsWith('---'), isFalse);
      expect(sanitized.contains('For full details'), isFalse);
      expect(sanitized.contains('New feature B'), isTrue);
    });
  });
}
