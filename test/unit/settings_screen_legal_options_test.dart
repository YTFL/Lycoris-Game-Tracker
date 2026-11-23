import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lycoris/features/search/data/igdb_cache_service.dart';
import 'package:lycoris/features/sync/presentation/controllers/settings_notifier.dart';
import 'package:lycoris/features/sync/presentation/screens/markdown_viewer_screen.dart';
import 'package:lycoris/features/sync/presentation/screens/settings_screen.dart';
import 'package:lycoris/features/tracker/presentation/controllers/library_notifier.dart';
import 'package:lycoris/features/tracker/presentation/controllers/library_state.dart';

class FakeSettingsNotifier extends StateNotifier<SettingsState> implements SettingsNotifier {
  FakeSettingsNotifier()
      : super(const SettingsState(
          workerProxyUrl: 'https://lycoris-proxy.workers.dev',
          twitchClientId: '',
          twitchBearerToken: '',
          primaryCurrency: 'USD',
        ));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeIGDBCacheService extends Fake implements IGDBCacheService {
  @override
  Future<int> getSizeBytes() async => 0;
}

class FakeLibraryNotifier extends StateNotifier<LibraryState> implements LibraryNotifier {
  FakeLibraryNotifier() : super(const LibraryState());

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('SettingsScreen renders About & Legal section with all 4 options', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final fakeSettingsNotifier = FakeSettingsNotifier();
    final fakeCacheService = FakeIGDBCacheService();
    final fakeLibraryNotifier = FakeLibraryNotifier();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsNotifierProvider.overrideWith((ref) => fakeSettingsNotifier),
          igdbCacheServiceProvider.overrideWithValue(fakeCacheService),
          libraryNotifierProvider.overrideWith((ref) => fakeLibraryNotifier),
        ],
        child: const MaterialApp(
          home: SettingsScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify section title
    expect(find.text('About & Legal'), findsOneWidget);
    expect(find.text('Release notes, developer showcase, and terms.'), findsOneWidget);

    // Verify Option 1: What's New
    expect(find.text("What's New"), findsOneWidget);
    expect(find.text('Release notes and latest changes'), findsOneWidget);

    // Verify Option 2: View More Apps by Me
    expect(find.text('View More Apps by Me'), findsOneWidget);
    expect(find.text('https://ytfl.github.io/'), findsOneWidget);

    // Verify Option 3: Terms and Conditions
    expect(find.text('Terms and Conditions'), findsOneWidget);
    expect(find.text('AGPL-3.0 License & terms of service'), findsOneWidget);

    // Verify Option 4: Privacy Policy
    expect(find.text('Privacy Policy'), findsOneWidget);
    expect(find.text('Zero telemetry & local data sovereignty'), findsOneWidget);
  });

  testWidgets('Tapping Terms and Conditions navigates to MarkdownViewerScreen', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final fakeSettingsNotifier = FakeSettingsNotifier();
    final fakeCacheService = FakeIGDBCacheService();
    final fakeLibraryNotifier = FakeLibraryNotifier();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsNotifierProvider.overrideWith((ref) => fakeSettingsNotifier),
          igdbCacheServiceProvider.overrideWithValue(fakeCacheService),
          libraryNotifierProvider.overrideWith((ref) => fakeLibraryNotifier),
        ],
        child: const MaterialApp(
          home: SettingsScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Tap Terms and Conditions
    await tester.ensureVisible(find.text('Terms and Conditions'));
    await tester.tap(find.text('Terms and Conditions'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Check that MarkdownViewerScreen is pushed
    expect(find.byType(MarkdownViewerScreen), findsOneWidget);
  });

  testWidgets('SettingsScreen has removed subtitle and conversion benchmark clutter', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final fakeSettingsNotifier = FakeSettingsNotifier();
    final fakeCacheService = FakeIGDBCacheService();
    final fakeLibraryNotifier = FakeLibraryNotifier();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsNotifierProvider.overrideWith((ref) => fakeSettingsNotifier),
          igdbCacheServiceProvider.overrideWithValue(fakeCacheService),
          libraryNotifierProvider.overrideWith((ref) => fakeLibraryNotifier),
        ],
        child: const MaterialApp(
          home: SettingsScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify footer subtitle is removed
    expect(find.text('Offline-first gaming library & investment ROI tracker'), findsNothing);

    // Verify conversion benchmark clutter is removed
    expect(find.text('CONVERSION BENCHMARK (BASE: 1 USD)'), findsNothing);

    // Verify clean header and update button exist
    expect(find.text('Lycoris'), findsOneWidget);
    expect(find.text('Check for Updates'), findsOneWidget);
  });
}
