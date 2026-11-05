import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yorungez/app/app.dart';
import 'package:yorungez/app/providers.dart';
import 'package:yorungez/catalogue/data/catalogue_repository.dart';
import 'package:yorungez/core/presentation/external_link.dart';
import 'package:yorungez/sky/data/device_location.dart';
import 'package:yorungez/sky/presentation/sky_painter.dart';
import 'package:yorungez/sky/presentation/sky_screen.dart';
import 'support/account_fakes.dart';

Position position(DateTime at, {double accuracy = 8}) => Position(
  latitude: 41.0082,
  longitude: 28.9784,
  timestamp: at,
  accuracy: accuracy,
  altitude: 100,
  altitudeAccuracy: 5,
  heading: 0,
  headingAccuracy: 1,
  speed: 0,
  speedAccuracy: 1,
);

class GrantedLocation implements DeviceLocationSource {
  final fresh = Completer<Position>();
  final requests = <bool>[];
  @override
  Future<bool> permitted({required bool request}) async {
    requests.add(request);
    return true;
  }

  @override
  Future<Position?> recent() async => position(DateTime.now());
  @override
  Future<Position> current() => fresh.future;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Catalogue catalogue;
  setUpAll(() async => catalogue = await CatalogueRepository().load());
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });
  for (final sample in [
    ('en', const Size(844, 390)),
    ('tr', const Size(320, 640)),
  ]) {
    testWidgets(
      'registration validates names and sends no session at ${sample.$1} narrow/landscape',
      (tester) async {
        tester.view.physicalSize = sample.$2;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final api = FakeAccountApi(), vault = MemoryVault();
        final container = ProviderContainer(
          overrides: [
            accountApiProvider.overrideWithValue(api),
            credentialVaultProvider.overrideWithValue(vault),
          ],
        );
        container.read(localeProvider.notifier).select(sample.$1);
        container.read(routerProvider).go('/account?mode=register');
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
              child: const YorungezApp(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final labels = sample.$1 == 'en'
            ? ['First name', 'Last name', 'Email address', 'Password']
            : ['Ad', 'Soyad', 'E-posta adresi', 'Parola'];
        final values = [
          'Public',
          'Tester',
          'public@example.invalid',
          'a long synthetic test passphrase',
        ];
        for (var i = 0; i < labels.length; i++) {
          final field = find.byWidgetPredicate(
            (w) => w is TextField && w.decoration?.labelText == labels[i],
          );
          await tester.ensureVisible(field);
          await tester.enterText(field, values[i]);
          await tester.pumpAndSettle();
        }
        final button = find.widgetWithText(
          FilledButton,
          sample.$1 == 'en' ? 'Create account' : 'Kayıt ol',
        );
        await tester.ensureVisible(button);
        await tester.pumpAndSettle();
        await tester.tap(button);
        await tester.pumpAndSettle();
        expect(
          find.textContaining(
            sample.$1 == 'en' ? 'If the address is eligible' : 'Adres uygunsa',
          ),
          findsOneWidget,
        );
        expect(container.read(accountStateProvider).user, isNull);
        expect(vault.value, isNull);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        container.dispose();
      },
    );
  }
  testWidgets(
    'login shows full name, uses account language and opens the connected notebook',
    (tester) async {
      final api = FakeAccountApi(), vault = MemoryVault();
      final container = ProviderContainer(
        overrides: [
          accountApiProvider.overrideWithValue(api),
          credentialVaultProvider.overrideWithValue(vault),
          catalogueProvider.overrideWith((ref) async => catalogue),
        ],
      );
      container.read(routerProvider).go('/account');
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const YorungezApp(),
        ),
      );
      await tester.pumpAndSettle();
      final email = find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.labelText == 'Email address',
      );
      final password = find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.labelText == 'Password',
      );
      await tester.enterText(email, 'a@example.invalid');
      await tester.enterText(password, 'synthetic test passphrase');
      final submit = find.widgetWithText(FilledButton, 'Sign in');
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await tester.pumpAndSettle();
      expect(container.read(localeProvider).languageCode, 'tr');
      await tester.ensureVisible(find.text('Defterim'));
      await tester.tap(find.text('Defterim'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Defterin boş'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      container.dispose();
    },
  );
  testWidgets(
    'source link opens externally and detail focus uses granted cached GPS before a slow fresh fix',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        'sky.privacyNoticeVersion': 1,
        'sky.musicEnabled': false,
      });
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
      final source = GrantedLocation(), opened = <Uri>[];
      final container = ProviderContainer(
        overrides: [
          catalogueProvider.overrideWith((ref) async => catalogue),
          accountApiProvider.overrideWithValue(FakeAccountApi()),
          credentialVaultProvider.overrideWithValue(MemoryVault()),
          deviceLocationProvider.overrideWithValue(source),
          externalOpenerProvider.overrideWithValue((uri) async {
            opened.add(uri);
            return true;
          }),
        ],
      );
      container.read(routerProvider).go('/objects/moon');
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const YorungezApp(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Image source'));
      await tester.tap(find.text('Image source'));
      await tester.pumpAndSettle();
      expect(opened.single.host, 'commons.wikimedia.org');
      await tester.ensureVisible(find.text('Focus on sky'));
      await tester.tap(find.text('Focus on sky'));
      await tester.pump();
      final scene = find.byWidgetPredicate(
        (w) => w is CustomPaint && w.painter is SkyPainter,
      );
      for (
        var i = 0;
        i < 50 &&
            (scene.evaluate().isEmpty ||
                (tester.widget<CustomPaint>(scene).painter as SkyPainter)
                        .selected !=
                    'moon');
        i++
      ) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
        await tester.pump();
      }
      expect(scene, findsOneWidget);
      final painter = tester.widget<CustomPaint>(scene).painter as SkyPainter;
      expect(painter.selected, 'moon');
      expect(painter.frame.observer.device, true);
      expect(painter.frame.observer.latitude, 41.0082);
      expect(
        painter.pose.forward.dot(painter.frame.points['moon']!.vector),
        closeTo(1, 1e-12),
      );
      expect(source.fresh.isCompleted, false);
      expect(source.requests, [false]);
      expect(container.read(skyFocusProvider), isNull);
      final retainedSky = tester.state(find.byType(SkyScreen));
      container.read(routerProvider).push<void>('/objects/moon');
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Focus on sky'));
      await tester.tap(find.text('Focus on sky'));
      await tester.pump();
      for (var i = 0; i < 30 && container.read(skyFocusProvider) != null; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
        await tester.pump();
      }
      expect(tester.state(find.byType(SkyScreen)), same(retainedSky));
      expect(
        (tester.widget<CustomPaint>(scene).painter as SkyPainter)
            .frame
            .observer
            .latitude,
        41.0082,
      );
      expect(container.read(skyFocusProvider), isNull);
      source.fresh.complete(position(DateTime.now()));
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      container.dispose();
    },
  );
  test(
    'location cache cannot silently provide old, imprecise or unsupported observer data',
    () {
      final now = DateTime.now();
      expect(
        deviceObserver(position(now), now, provisional: true)?.device,
        true,
      );
      expect(
        deviceObserver(
          position(now.subtract(const Duration(minutes: 2))),
          now,
          provisional: true,
        ),
        isNull,
      );
      expect(
        deviceObserver(position(now, accuracy: 500), now, provisional: true),
        isNull,
      );
      expect(deviceObserver(position(now, accuracy: double.nan), now), isNull);
      expect(
        deviceObserver(
          position(now.subtract(const Duration(seconds: 40))),
          now,
        ),
        isNull,
      );
      expect(safeExternalUri(Uri.parse('javascript:alert(1)')), false);
      expect(
        safeExternalUri(Uri.parse('https://user:password@example.invalid/')),
        false,
      );
    },
  );
  testWidgets(
    'leaving sign-in while its profile is delayed cannot touch disposed form controllers',
    (tester) async {
      final api = FakeAccountApi(),
          vault = MemoryVault(),
          delayed = Completer<dynamic>();
      api.heldProfile = delayed;
      final container = ProviderContainer(
        overrides: [
          accountApiProvider.overrideWithValue(api),
          credentialVaultProvider.overrideWithValue(vault),
          catalogueProvider.overrideWith((ref) async => catalogue),
        ],
      );
      container.read(routerProvider).go('/account');
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const YorungezApp(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byWidgetPredicate(
          (w) => w is TextField && w.decoration?.labelText == 'Email address',
        ),
        'a@example.invalid',
      );
      await tester.enterText(
        find.byWidgetPredicate(
          (w) => w is TextField && w.decoration?.labelText == 'Password',
        ),
        'synthetic test passphrase',
      );
      final submit = find.widgetWithText(FilledButton, 'Sign in');
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await tester.pump();
      container.read(routerProvider).go('/catalogue');
      await tester.pumpAndSettle();
      delayed.complete(api.profile());
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(container.read(accountStateProvider).user?.id, 'account-a');
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      container.dispose();
    },
  );
  testWidgets(
    'a completed note write after its sheet is dismissed cannot use the disposed sheet ref',
    (tester) async {
      final api = FakeAccountApi()..language = 'en',
          delayed = Completer<dynamic>();
      Map<String, dynamic>? submitted;
      api.intercept = (path, method, body, access) async {
        if (method == 'POST') {
          submitted = body;
          return delayed.future;
        }
        return {'userId': 'account-a', 'entries': []};
      };
      final container = ProviderContainer(
        overrides: [
          accountApiProvider.overrideWithValue(api),
          credentialVaultProvider.overrideWithValue(MemoryVault()),
        ],
      );
      await container
          .read(accountSessionProvider)
          .signIn('a@example.invalid', 'synthetic');
      container.read(routerProvider).go('/notebook');
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const YorungezApp(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('New note'));
      await tester.pumpAndSettle();
      final field = find.byType(TextField);
      await tester.enterText(field, 'A synthetic unsaved draft');
      await tester.pumpAndSettle();
      final save = find.text('Save to my account');
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pump();
      Navigator.of(tester.element(field)).pop();
      await tester.pumpAndSettle();
      expect(submitted, isNotNull);
      delayed.complete({...submitted!, 'revision': 1});
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      container.dispose();
    },
  );
}
