import 'dart:io';
import 'package:flutter/material.dart';
import '../services/local_cover_storage.dart';

/// Renders a game cover from permanent local storage if available,
/// or downloads it once and caches it permanently.
class GameCoverImage extends StatelessWidget {
  final String? imageUrl;
  final int? memCacheWidth;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  const GameCoverImage({
    super.key,
    required this.imageUrl,
    this.memCacheWidth,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;
    if (url == null || url.isEmpty) {
      return errorWidget ?? placeholder ?? const SizedBox.shrink();
    }

    final localFile = LocalCoverStorage.getLocalFileSync(url);
    if (localFile != null) {
      return Image.file(
        localFile,
        fit: fit,
        cacheWidth: memCacheWidth,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) => errorWidget ?? placeholder ?? const SizedBox.shrink(),
      );
    }

    return FutureBuilder<File?>(
      future: LocalCoverStorage.getOrDownload(url),
      builder: (context, snapshot) {
        final file = snapshot.data;
        if (file != null) {
          return Image.file(
            file,
            fit: fit,
            cacheWidth: memCacheWidth,
            gaplessPlayback: true,
            errorBuilder: (_, _, _) => errorWidget ?? placeholder ?? const SizedBox.shrink(),
          );
        }
        if (snapshot.connectionState == ConnectionState.done) {
          return errorWidget ?? placeholder ?? const SizedBox.shrink();
        }
        return placeholder ?? const SizedBox.shrink();
      },
    );
  }
}
