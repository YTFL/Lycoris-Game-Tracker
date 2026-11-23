import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lycoris/features/sync/presentation/screens/markdown_viewer_screen.dart';

class TestAssetBundle extends CachingAssetBundle {
  final Map<String, String> assets;

  TestAssetBundle(this.assets);

  @override
  Future<ByteData> load(String key) async {
    if (assets.containsKey(key)) {
      final bytes = utf8.encode(assets[key]!);
      return ByteData.view(Uint8List.fromList(bytes).buffer);
    }
    throw FlutterError('Asset not found: $key');
  }
}

void main() {
  testWidgets('MarkdownViewerScreen displays title and renders markdown content', (tester) async {
    const assetPath = 'test_doc.md';
    const markdownContent = '''
# Welcome to Lycoris
This is a test paragraph describing the **awesome** features.

- Feature 1
- Feature 2

> Note: Offline first.
''';

    final bundle = TestAssetBundle({assetPath: markdownContent});

    await tester.pumpWidget(
      DefaultAssetBundle(
        bundle: bundle,
        child: const MaterialApp(
          home: MarkdownViewerScreen(
            title: "What's New",
            assetPath: assetPath,
          ),
        ),
      ),
    );

    // Initial pump
    await tester.pump();
    // Complete FutureBuilder
    await tester.pumpAndSettle();

    // Verify AppBar title
    expect(find.text("What's New"), findsOneWidget);

    // Verify Markdown widget is present
    expect(find.byType(Markdown), findsOneWidget);

    // Verify rendered content
    expect(find.textContaining('Welcome to Lycoris'), findsOneWidget);
    expect(find.textContaining('Feature 1'), findsOneWidget);
  });

  testWidgets('MarkdownViewerScreen displays error view when asset fails to load', (tester) async {
    final bundle = TestAssetBundle({});

    await tester.pumpWidget(
      DefaultAssetBundle(
        bundle: bundle,
        child: const MaterialApp(
          home: MarkdownViewerScreen(
            title: 'Terms of Service',
            assetPath: 'non_existent_file.md',
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Terms of Service'), findsOneWidget);
    expect(find.text('Failed to load Terms of Service'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
  });
}
