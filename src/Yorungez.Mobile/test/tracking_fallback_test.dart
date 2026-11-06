import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yorungez/app/providers.dart';
import 'package:yorungez/catalogue/data/catalogue_repository.dart';
import 'package:yorungez/l10n/generated/app_localizations.dart';
import 'package:yorungez/sky/data/native_pose_source.dart';
import 'package:yorungez/sky/domain/sky_geometry.dart';
import 'package:yorungez/sky/presentation/sky_painter.dart';
import 'package:yorungez/sky/presentation/sky_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Catalogue catalogue;
  setUpAll(() async => catalogue = await CatalogueRepository().load());
  final scene = find.byWidgetPredicate(
    (w) => w is CustomPaint && w.painter is SkyPainter,
  );

  Future<ProviderContainer> mount(
    WidgetTester tester,
    String language,
    NativePoseSource source,
  ) async {
    final container = ProviderContainer(
      overrides: [
        catalogueProvider.overrideWith((ref) async => catalogue),
        nativePoseSourceProvider.overrideWithValue(source),
      ],
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          locale: Locale(language),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          theme: ThemeData.dark(),
          home: Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(1.5)),
              child: SkyScreen(
                initialObserver: SkyObserver(41, 29, example: true),
              ),
            ),
          ),
        ),
      ),
    );
    for (var i = 0; i < 30 && scene.evaluate().isEmpty; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump();
    }
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
    return container;
  }

  Future<void> unmount(WidgetTester tester, ProviderContainer container) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    container.dispose();
  }

  for (final language in ['en', 'tr']) {
    testWidgets(
      '$language unsupported notice is once; manual sky remains usable',
      (tester) async {
        SharedPreferences.setMockInitialValues({
          'sky.privacyNoticeVersion': 1,
          'sky.musicEnabled': false,
        });
        WidgetController.hitTestWarningShouldBeFatal = true;
        addTearDown(() => WidgetController.hitTestWarningShouldBeFatal = false);
        tester.view.physicalSize = language == 'en'
            ? const Size(844, 390)
            : const Size(320, 640);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final source = NativePoseSource(
          probe: () async => false,
          events: () => throw StateError('Unsupported sensor was registered'),
        );
        var container = await mount(tester, language, source);
        expect(scene, findsOneWidget);
        expect(find.byType(AlertDialog), findsOneWidget);
        final t = AppLocalizations.of(tester.element(find.byType(SkyScreen)));
        expect(find.text(t.trackingUnsupportedNotice), findsOneWidget);
        expect(
          tester
              .widget<IconButton>(
                find.widgetWithIcon(IconButton, Icons.explore_outlined),
              )
              .onPressed,
          isNull,
        );
        expect(
          tester
              .widget<IconButton>(
                find.widgetWithIcon(IconButton, Icons.camera_alt_outlined),
              )
              .onPressed,
          isNull,
        );
        await tester.tap(find.text(t.understood));
        await tester.pump(const Duration(seconds: 1));
        final before =
            (tester.widget<CustomPaint>(scene).painter! as SkyPainter)
                .pose
                .forward
                .azimuth;
        await tester.dragFrom(const Offset(140, 280), const Offset(70, 0));
        await tester.pump();
        expect(
          (tester.widget<CustomPaint>(scene).painter! as SkyPainter)
              .pose
              .forward
              .azimuth,
          isNot(before),
        );
        expect(
          tester
              .widget<IconButton>(
                find.widgetWithIcon(IconButton, Icons.search_rounded),
              )
              .onPressed,
          isNotNull,
        );
        expect(tester.takeException(), isNull);
        await unmount(tester, container);
        // A new app scope still respects the persisted, non-personal acknowledgement.
        container = await mount(tester, language, source);
        expect(find.byType(AlertDialog), findsNothing);
        expect(scene, findsOneWidget);
        expect(tester.takeException(), isNull);
        await unmount(tester, container);
      },
    );
  }

  testWidgets('backgrounded capability result cannot consume the notice', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'sky.privacyNoticeVersion': 1,
      'sky.musicEnabled': false,
    });
    final probe = Completer<bool>();
    final container = await mount(
      tester,
      'en',
      NativePoseSource(
        probe: () => probe.future,
        events: () => const Stream.empty(),
      ),
    );
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    probe.complete(false);
    await tester.pump();
    expect(find.byType(AlertDialog), findsNothing);
    expect(
      (await SharedPreferences.getInstance()).containsKey(
        'sky.trackingNoticeVersion',
      ),
      isFalse,
    );
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(tester.takeException(), isNull);
    await unmount(tester, container);
  });

  testWidgets(
    'silent sensor stops following and allows a manual pan and retry',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        'sky.privacyNoticeVersion': 1,
        'sky.musicEnabled': false,
      });
      final events = StreamController<dynamic>.broadcast();
      final container = await mount(
        tester,
        'en',
        NativePoseSource(probe: () async => true, events: () => events.stream),
      );
      for (var i = 0; i < 9; i++) {
        await tester.pump(const Duration(seconds: 1));
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 80)),
        );
        await tester.pump();
      }
      final t = AppLocalizations.of(tester.element(find.byType(SkyScreen)));
      expect(find.text(t.sensorNoData), findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);
      expect(
        (await SharedPreferences.getInstance()).containsKey(
          'sky.trackingNoticeVersion',
        ),
        isFalse,
      );
      final before = (tester.widget<CustomPaint>(scene).painter! as SkyPainter)
          .pose
          .forward
          .azimuth;
      await tester.dragFrom(const Offset(140, 280), const Offset(70, 0));
      await tester.pump();
      expect(
        (tester.widget<CustomPaint>(scene).painter! as SkyPainter)
            .pose
            .forward
            .azimuth,
        isNot(before),
      );
      expect(find.byTooltip(t.startTracking), findsOneWidget);
      await tester.tap(find.byTooltip(t.startTracking));
      await tester.pump();
      expect(find.byTooltip(t.stopTracking), findsOneWidget);
      expect(tester.takeException(), isNull);
      await unmount(tester, container);
      await events.close();
    },
  );
}
