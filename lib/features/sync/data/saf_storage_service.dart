import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class SafStorageResult {
  final String uri;
  final String displayName;

  const SafStorageResult({required this.uri, required this.displayName});
}

class SafStorageService {
  static const MethodChannel _channel = MethodChannel('com.ytfl.lycoris/saf_storage');

  static bool get isSupported {
    if (kIsWeb) return false;
    return Platform.isAndroid;
  }

  /// Opens Android SAF system folder picker with explicit Read & Write permissions
  static Future<SafStorageResult?> pickFolder() async {
    if (!isSupported) return null;
    try {
      final res = await _channel.invokeMapMethod<String, dynamic>('pickFolder');
      if (res != null && res['uri'] != null) {
        return SafStorageResult(
          uri: res['uri'] as String,
          displayName: res['displayName'] as String? ?? 'Backup Folder',
        );
      }
    } catch (e) {
      debugPrint('SafStorageService.pickFolder error: $e');
    }
    return null;
  }

  /// Verifies write permissions in the SAF folder
  static Future<bool> verifyWritable(String uri) async {
    if (!isSupported) return false;
    try {
      final result = await _channel.invokeMethod<bool>('verifyWritable', {'uri': uri});
      return result ?? false;
    } catch (e) {
      debugPrint('SafStorageService.verifyWritable error: $e');
      return false;
    }
  }

  /// Rotates backups and writes current backup via SAF DocumentFile
  static Future<bool> rotateAndSaveBackup({
    required String uri,
    required String content,
    required String currentFileName,
    required String previousFileName,
  }) async {
    if (!isSupported) return false;
    try {
      final result = await _channel.invokeMethod<bool>('rotateAndSaveBackup', {
        'uri': uri,
        'content': content,
        'currentFileName': currentFileName,
        'previousFileName': previousFileName,
      });
      return result ?? false;
    } catch (e) {
      debugPrint('SafStorageService.rotateAndSaveBackup error: $e');
      return false;
    }
  }

  /// Reads backup file content via SAF ContentResolver
  static Future<String?> readBackupFile({
    required String uri,
    required String fileName,
  }) async {
    if (!isSupported) return null;
    try {
      return await _channel.invokeMethod<String>('readBackupFile', {
        'uri': uri,
        'fileName': fileName,
      });
    } catch (e) {
      debugPrint('SafStorageService.readBackupFile error: $e');
      return null;
    }
  }

  /// Retrieves file presence, size, and modified timestamps from SAF
  static Future<Map<String, dynamic>?> getBackupInfo({
    required String uri,
    required String currentFileName,
    required String previousFileName,
  }) async {
    if (!isSupported) return null;
    try {
      return await _channel.invokeMapMethod<String, dynamic>('getBackupInfo', {
        'uri': uri,
        'currentFileName': currentFileName,
        'previousFileName': previousFileName,
      });
    } catch (e) {
      debugPrint('SafStorageService.getBackupInfo error: $e');
      return null;
    }
  }
}
