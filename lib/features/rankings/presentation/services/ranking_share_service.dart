import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../controllers/rankings_state.dart';
import '../widgets/ranking_list_tile.dart';
import '../widgets/ranking_top5_showcase.dart';

/// Captures the entire rankings page (Top 5 showcase + all remaining ranked
/// games) as a high-resolution PNG image and opens the native share sheet.
class RankingShareService {
  static Future<void> shareRankings({
    required BuildContext context,
    required List<RankedGameItem> rankedList,
  }) async {
    if (rankedList.isEmpty) return;

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenWidth = MediaQuery.sizeOf(context).width.clamp(360.0, 480.0);

    final top5 = rankedList.take(5).toList();
    final remaining = rankedList.skip(5).toList();

    final boundaryKey = GlobalKey();
    final overlay = Overlay.of(context);

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => Positioned(
        left: -10000,
        top: 0,
        width: screenWidth,
        height: MediaQuery.sizeOf(context).height,
        child: Material(
          color: theme.scaffoldBackgroundColor,
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: RepaintBoundary(
              key: boundaryKey,
              child: Container(
                width: screenWidth,
                color: theme.scaffoldBackgroundColor,
                padding: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                        child: Row(
                          children: [
                            Icon(
                              Icons.leaderboard_outlined,
                              color: colorScheme.primary,
                              size: 24,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'My Lycoris Rankings',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            Text(
                              '${rankedList.length} games',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Top 5 Showcase
                      RankingTop5Showcase(
                        topItems: top5,
                        onItemTap: (_) {},
                      ),
                      // Remaining ranks
                      if (remaining.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        for (final item in remaining)
                          RankingListTile(
                            item: item,
                            onTap: () {},
                          ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );

    overlay.insert(entry);
    try {
      // Wait for layout & paint to complete.
      await WidgetsBinding.instance.endOfFrame;
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final boundary = boundaryKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) {
        throw StateError('Failed to locate rankings render boundary.');
      }

      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (byteData == null) {
        throw StateError('Failed to encode rankings image.');
      }

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/lycoris_rankings.png');
      await file.writeAsBytes(byteData.buffer.asUint8List());

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: 'My Lycoris Game Rankings (${rankedList.length} games)',
        ),
      );
    } finally {
      entry.remove();
    }
  }
}
