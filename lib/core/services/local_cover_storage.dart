import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Permanent local disk storage for game cover artworks under
/// `<ApplicationDocumentsDirectory>/covers/`.
/// Never cleared by the OS and never expires.
class LocalCoverStorage {
  static Directory? _coversDir;
  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
    ),
  );
  static final Map<String, Future<File?>> _inFlight = {};

  static Future<void> init() async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(appDir.path, 'covers'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    _coversDir = dir;
  }

  static String _fileNameForUrl(String url) {
    final digest = sha256.convert(utf8.encode(url)).toString();
    return '$digest.jpg';
  }

  /// Synchronously returns the local [File] if already downloaded, or null.
  /// Enables frame-1 rendering on app boot with zero async delay.
  static File? getLocalFileSync(String url) {
    final dir = _coversDir;
    if (dir == null || url.isEmpty) return null;
    final file = File(p.join(dir.path, _fileNameForUrl(url)));
    if (file.existsSync()) return file;
    return null;
  }

  /// Returns the local [File] if present, otherwise downloads it once
  /// and saves it permanently to local app storage.
  static Future<File?> getOrDownload(String url) {
    final existing = getLocalFileSync(url);
    if (existing != null) return Future.value(existing);

    return _inFlight.putIfAbsent(url, () async {
      try {
        if (_coversDir == null) {
          await init();
        }
        final dir = _coversDir!;
        final targetPath = p.join(dir.path, _fileNameForUrl(url));
        final tempPath = '$targetPath.tmp';

        await _dio.download(url, tempPath);
        final tempFile = File(tempPath);
        if (await tempFile.exists()) {
          return await tempFile.rename(targetPath);
        }
        return null;
      } catch (_) {
        return null;
      } finally {
        _inFlight.remove(url);
      }
    });
  }
}
