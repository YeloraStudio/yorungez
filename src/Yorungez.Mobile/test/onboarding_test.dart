import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yorungez/app/app.dart';
import 'package:yorungez/app/providers.dart';
import 'package:yorungez/catalogue/data/catalogue_repository.dart';
import 'package:yorungez/sky/data/mobile_services.dart';
import 'package:yorungez/sky/presentation/sky_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Catalogue catalogue;
  setUpAll(() async => catalogue = await CatalogueRepository().load());
  test('only notice version and audio preference are persisted', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = MobilePreferences();
    expect(await prefs.onboardingComplete(), isFalse);
    await prefs.completeOnboarding();
    await prefs.setMusic(false);
    expect(await prefs.musicEnabled(), isFalse);
    expect((await SharedPreferences.getInstance()).getKeys(), {
      'sky.privacyNoticeVersion',
      'sky.musicEnabled',
    });
  });
  testWidgets(
    'sky keeps the screen awake only while active and releases it on exit',
    (tester) async {
      SharedPreferences.setMockInitialValues({'sky.musicEnabled': false});
      const channel = MethodChannel('yorungez/screen');
      final calls = <bool>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
        call,
      ) async {
        calls.add(call.arguments as bool);
        return null;
      });
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          null,
        ),
      );
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      final container = ProviderContainer(
        overrides: [catalogueProvider.overrideWith((ref) async => catalogue)],
      );
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const YorungezApp(),
        ),
      );
      await tester.pumpAndSettle();
      expect(calls.last, isTrue);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pumpAndSettle();
      expect(calls.last, isFalse);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(calls.last, isTrue);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      expect(calls, [true, false, true, false]);
      container.dispose();
    },
  );
  for (final entry in [
    ('en', const Size(844, 390)),
    ('tr', const Size(320, 640)),
  ]) {
    testWidgets(
      'first launch is sky/privacy, optional permission flow at ${entry.$1} large text',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        tester.view.physicalSize = entry.$2;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final container = ProviderContainer(
          overrides: [catalogueProvider.overrideWith((ref) async => catalogue)],
        );
        container.read(localeProvider.notifier).select(entry.$1);
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(2)),
              child: const YorungezApp(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(SkyScreen), findsOneWidget);
        expect(
          find.text(
            entry.$1 == 'en' ? 'Before we explore' : 'Keşfe başlamadan',
          ),
          findsOneWidget,
        );
        final next = find.text(entry.$1 == 'en' ? 'Continue' : 'Devam et');
        await tester.ensureVisible(next);
        await tester.tap(next);
        await tester.pumpAndSettle();
        expect(
          find.text(
            entry.$1 == 'en'
                ? 'Choose how to explore'
                : 'Nasıl keşfedeceğini seç',
          ),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        container.dispose();
      },
    );
  }
}
