// Genuine production widgets/native calculations with a public Istanbul example.
// Run only on the isolated capture emulator; no login, personal data, or OS permissions.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yorungez/app/app.dart';
import 'package:yorungez/app/providers.dart';
import 'package:yorungez/planning/planning_controls.dart';
import 'package:yorungez/planning/event_catalogue.dart';
import 'package:yorungez/sky/domain/sky_geometry.dart';
import 'package:yorungez/sky/presentation/sky_painter.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('English store capture of public example only', (tester) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString('ui.language', 'en');
    await preferences.setInt('sky.privacyNoticeVersion', 1);
    await preferences.setBool('sky.musicEnabled', false);
    final container = ProviderContainer(
      overrides: [
        initialSkyObserverProvider.overrideWithValue(
          SkyObserver(41.0082, 28.9784, example: true),
        ),
      ],
    );
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      container.dispose();
    });
    container.read(localeProvider.notifier).select('en');
    container.read(planningZoneProvider.notifier).select('Europe/Istanbul');
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const YorungezApp(),
      ),
    );
    Future<void> frames([int seconds = 2]) async {
      for (var i = 0; i < seconds * 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
    }

    for (var i = 0; i < 100 && container.read(skyFrameProvider) == null; i++) {
      await frames(1);
    }
    expect(container.read(skyFrameProvider), isNotNull);
    expect(container.read(accountStateProvider).user, isNull);
    await binding.convertFlutterSurfaceToImage();
    Future<void> capture(String name) async {
      await frames();
      await binding.takeScreenshot(name);
    }

    Future<void> sky(String id) async {
      container.read(routerProvider).go('/');
      container
          .read(skyInstantProvider.notifier)
          .select(DateTime.utc(2026, 11, 5, 23));
      container.read(skyFocusProvider.notifier).request(id);
      await frames(4);
      final painting = tester.widget<CustomPaint>(
        find.byWidgetPredicate(
          (w) => w is CustomPaint && w.painter is SkyPainter,
        ),
      );
      expect((painting.painter! as SkyPainter).selected, id);
    }

    Future<void> layer(String label, bool enabled) async {
      await tester.tap(find.byIcon(Icons.menu_rounded));
      await frames(1);
      final control = find.widgetWithText(SwitchListTile, label);
      await tester.scrollUntilVisible(
        control,
        250,
        scrollable: find
            .descendant(
              of: find.byType(Drawer),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await Scrollable.ensureVisible(tester.element(control), alignment: .2);
      await frames(1);
      if (tester.widget<SwitchListTile>(control).value != enabled) {
        await tester.tap(control);
        await frames(1);
      }
      expect(tester.widget<SwitchListTile>(control).value, enabled);
      await tester.tap(find.byTooltip('Close'));
      await frames(1);
    }

    await layer('Constellation figures', false);
    await sky('jupiter');
    await capture('01-jupiter');
    await sky('moon');
    await capture('02-moon');
    await layer('Constellation figures', true);
    await layer('Cosmic sky', false);
    await sky('con-ori');
    final figurePaint =
        tester
                .widget<CustomPaint>(
                  find.byWidgetPredicate(
                    (w) => w is CustomPaint && w.painter is SkyPainter,
                  ),
                )
                .painter!
            as SkyPainter;
    expect(figurePaint.layers.contains(SkyLayer.figures), isTrue);
    await capture('03-orion');
    container.read(routerProvider).push('/objects/dso-ngc0224');
    await capture('04-andromeda');
    container.read(routerProvider).go('/');
    await frames();
    container.read(routerProvider).push('/tonight');
    await frames(8);
    expect(find.text('Europe/Istanbul'), findsOneWidget);
    await capture('05-tonight');
    container.read(routerProvider).go('/');
    await frames();
    container.read(routerProvider).push('/calendar');
    await frames();
    expect(find.text('Europe/Istanbul'), findsOneWidget);
    await tester.tap(
      find.byWidgetPredicate(
        (w) => w is ChoiceField<int> && w.label == 'Month',
      ),
    );
    await frames(1);
    await tester.scrollUntilVisible(
      find.text('December'),
      250,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('December'));
    await frames(1);
    await capture('06-calendar');
    final event = (await container.read(
      eventCatalogueProvider.future,
    )).month(2026, 12, 'Europe/Istanbul').first;
    await tester.tap(find.widgetWithText(FilledButton, 'Focus on sky').first);
    await frames(4);
    expect(container.read(skyInstantProvider), event.instant);
    expect(container.read(skyFrameProvider)!.instant, event.instant);
    await tester.tap(find.widgetWithText(FilledButton, 'Back to live'));
    await frames(2);
    expect(container.read(skyInstantProvider), isNull);
    container.read(routerProvider).go('/');
    await frames();
    container.read(routerProvider).push('/catalogue');
    await capture('07-catalogue');
    container.read(routerProvider).go('/');
    await frames();
    container.read(routerProvider).push('/account?mode=register');
    await capture('08-account');
    expect(tester.takeException(), isNull);
  });
}
