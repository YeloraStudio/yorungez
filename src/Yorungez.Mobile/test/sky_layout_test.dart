import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yorungez/app/providers.dart';
import 'package:yorungez/catalogue/data/catalogue_repository.dart';
import 'package:yorungez/l10n/generated/app_localizations.dart';
import 'package:yorungez/sky/domain/sky_geometry.dart';
import 'package:yorungez/sky/presentation/sky_painter.dart';
import 'package:yorungez/sky/presentation/sky_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Catalogue catalogue;
  setUpAll(() async => catalogue = await CatalogueRepository().load());
  testWidgets(
    'real native sky and controls survive portrait/landscape with large text',
    (tester) async {
      WidgetController.hitTestWarningShouldBeFatal = true;
      addTearDown(() => WidgetController.hitTestWarningShouldBeFatal = false);
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('yorungez/pose'),
        (_) async => null,
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          const MethodChannel('yorungez/pose'),
          null,
        ),
      );
      SharedPreferences.setMockInitialValues({
        'sky.privacyNoticeVersion': 1,
        'sky.musicEnabled': false,
      });
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final container = ProviderContainer(
        overrides: [catalogueProvider.overrideWith((ref) async => catalogue)],
      );
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            locale: const Locale('en'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            theme: ThemeData.dark(),
            home: MediaQuery(
              data: const MediaQueryData(
                size: Size(390, 844),
                textScaler: TextScaler.linear(2),
              ),
              child: SkyScreen(
                initialObserver: SkyObserver(41.0082, 28.9784, example: true),
              ),
            ),
          ),
        ),
      );
      final scene = find.byWidgetPredicate(
        (w) => w is CustomPaint && w.painter is SkyPainter,
      );
      for (var i = 0; i < 30 && scene.evaluate().isEmpty; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
        await tester.pump();
      }
      expect(scene, findsOneWidget);
      final frame =
          (tester.widget<CustomPaint>(scene).painter! as SkyPainter).frame;
      expect(frame.points.length, catalogue.objects.length - 2);
      expect(frame.points['moon'], isNotNull);
      SkyPainter currentPainter() =>
          tester.widget<CustomPaint>(scene).painter! as SkyPainter;
      expect(currentPainter().fov, 60);
      expect(find.byTooltip('Zoom in'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byIcon(Icons.menu_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Language'), findsOneWidget);
      expect(find.text('Cosmic ambience'), findsOneWidget);
      final dwellTitle = find.text('Reticle auto-select (1 s)');
      final zoomTitle = find.text('Sky map zoom');
      final dwell = find.ancestor(
        of: dwellTitle,
        matching: find.byType(SwitchListTile),
      );
      final zoom = find.ancestor(
        of: zoomTitle,
        matching: find.byType(SwitchListTile),
      );
      final drawerList = find
          .descendant(
            of: find.byType(Drawer),
            matching: find.byType(Scrollable),
          )
          .first;
      await tester.scrollUntilVisible(dwellTitle, 100, scrollable: drawerList);
      await tester.pump();
      expect(tester.widget<SwitchListTile>(dwell).value, isTrue);
      await tester.tap(dwellTitle);
      await tester.pump();
      await tester.scrollUntilVisible(zoomTitle, 100, scrollable: drawerList);
      await tester.pump();
      expect(tester.widget<SwitchListTile>(zoom).value, isFalse);
      await tester.tap(zoomTitle);
      await tester.pump();
      expect(tester.takeException(), isNull);
      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(
        find.text('Hold a target in the reticle for 1 second'),
        findsNothing,
      );
      expect(
        (await SharedPreferences.getInstance()).getBool('sky.dwellEnabled'),
        isFalse,
      );
      expect(
        (await SharedPreferences.getInstance()).getBool('sky.zoomEnabled'),
        isTrue,
      );
      await tester.tap(find.byTooltip('Zoom in'));
      await tester.pump();
      expect(currentPainter().fov, 48);
      await tester.tap(find.byTooltip('Zoom out'));
      await tester.pump();
      expect(currentPainter().fov, 60);
      final first = await tester.startGesture(const Offset(125, 360));
      final second = await tester.startGesture(const Offset(245, 360));
      await first.moveBy(const Offset(-40, 0));
      await second.moveBy(const Offset(40, 0));
      await first.up();
      await second.up();
      await tester.pump();
      expect(currentPainter().fov, lessThan(60));
      await tester.tap(find.byIcon(Icons.menu_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.scrollUntilVisible(zoomTitle, 100, scrollable: drawerList);
      await tester.pump();
      await tester.tap(zoomTitle);
      await tester.pump();
      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(currentPainter().fov, 60);
      expect(find.byTooltip('Zoom in'), findsNothing);
      container.read(localeProvider.notifier).select('tr');
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            locale: const Locale('tr'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            theme: ThemeData.dark(),
            home: MediaQuery(
              data: const MediaQueryData(
                size: Size(844, 390),
                textScaler: TextScaler.linear(2),
              ),
              child: SkyScreen(
                initialObserver: SkyObserver(41.0082, 28.9784, example: true),
              ),
            ),
          ),
        ),
      );
      tester.view.physicalSize = const Size(844, 390);
      await tester.pump();
      expect(scene, findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byIcon(Icons.menu_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Dil'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      container.dispose();
    },
  );
}
