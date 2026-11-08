import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yorungez/app/app.dart';
import 'package:yorungez/l10n/generated/app_localizations.dart';
import 'package:yorungez/app/providers.dart';
import 'package:yorungez/catalogue/data/catalogue_repository.dart';
import 'package:yorungez/planning/event_catalogue.dart';
import 'package:yorungez/planning/night_plan.dart';
import 'package:yorungez/planning/planning_time.dart';
import 'package:yorungez/planning/reminder_screen.dart';
import 'package:yorungez/sky/data/native_sky.dart';
import 'package:yorungez/sky/domain/sky_geometry.dart';
import 'package:yorungez/sky/domain/sky_frame.dart';
import 'support/account_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late EventCatalogue events;
  late Catalogue catalogue;
  setUpAll(() async {
    events = await EventCatalogue.load();
    catalogue = await CatalogueRepository().load();
  });
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'Explicit zone selection wins over device bootstrap and GMT is normalized',
    () async {
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(
        const MethodChannel('yorungez/time'),
        (_) async => 'GMT',
      );
      addTearDown(
        () => messenger.setMockMethodCallHandler(
          const MethodChannel('yorungez/time'),
          null,
        ),
      );
      final c = ProviderContainer();
      addTearDown(c.dispose);
      c.read(planningZoneProvider.notifier).select('Europe/Istanbul');
      await Future<void>.delayed(Duration.zero);
      expect(c.read(planningZoneProvider), 'Europe/Istanbul');
      expect(await PlanningTime.deviceZone(), 'UTC');
    },
  );

  test(
    'IANA local time retains UTC instant, fractional offset and month rollover',
    () {
      final utc = DateTime.utc(2026, 10, 31, 22);
      final istanbul = PlanningTime.local(utc, 'Europe/Istanbul');
      expect(istanbul.month, 11);
      expect(istanbul.day, 1);
      expect(istanbul.hour, 1);
      expect(istanbul.toUtc(), utc);
      expect(PlanningTime.offset(utc, 'Asia/Kathmandu'), 'GMT+05:45');
      expect(PlanningTime.offset(utc, 'America/St_Johns'), 'GMT-02:30');
    },
  );
  test(
    'Night windows follow local noon, DST 23/25 hours and midnight uses previous night',
    () {
      final short = PlanningTime.window(
        DateTime.utc(2026, 3, 7),
        'America/New_York',
      );
      final long = PlanningTime.window(
        DateTime.utc(2026, 10, 31),
        'America/New_York',
      );
      expect(short.end.difference(short.start), const Duration(hours: 23));
      expect(long.end.difference(long.start), const Duration(hours: 25));
      expect(
        PlanningTime.nightDate(
          DateTime.utc(2026, 11, 5, 22),
          'Europe/Istanbul',
        ),
        DateTime.utc(2026, 11, 5),
      );
      expect(
        () => PlanningTime.window(DateTime.utc(2035, 12, 31), 'UTC'),
        throwsFormatException,
      );
    },
  );
  test(
    'Canonical offline calendar is fingerprint-verified and filtered by local month',
    () {
      expect(events.events.length, 2623);
      final instant = DateTime.utc(2026, 10, 31, 22);
      final sample = EventCatalogue([
        SkyEvent(
          'test',
          'new-moon',
          'moon',
          instant,
          'usno',
          'https://aa.usno.navy.mil/data/MoonPhases',
        ),
      ], {});
      expect(sample.month(2026, 10, 'UTC').single.instant, instant);
      expect(sample.month(2026, 11, 'Europe/Istanbul').single.instant, instant);
      expect(sample.month(2026, 10, 'Europe/Istanbul'), isEmpty);
    },
  );
  test(
    'Serial native worker plans ordinary and polar nights and still calculates frames',
    () async {
      final worker = await SkyWorker.start(catalogue);
      addTearDown(worker.close);
      final site = SkyObserver(41.0082, 28.9784),
          window = PlanningTime.window(
            DateTime.utc(2026, 11, 5),
            'Europe/Istanbul',
          );
      final plan = await worker.plan(site, window.start, window.end);
      expect(plan.state, 0);
      expect(plan.rows.length, 8);
      expect(plan.sunset, isNotNull);
      expect(plan.sunrise, isNotNull);
      expect(plan.sunset!.isBefore(plan.sunrise!), isTrue);
      for (final row in plan.rows) {
        for (final i in row.intervals) {
          expect(i.end.isAfter(i.start), isTrue);
          expect(i.start.isBefore(plan.start), isFalse);
          expect(i.end.isAfter(plan.end), isFalse);
        }
      }
      expect(
        NightPlan.decode(plan.encode()).rows.map((r) => r.id),
        NightPlan.ids,
      );
      final pole = SkyObserver(78.2232, 15.6469);
      final day = PlanningTime.window(DateTime.utc(2026, 6, 21), 'Europe/Oslo');
      expect((await worker.plan(pole, day.start, day.end)).state, 1);
      final night = PlanningTime.window(
        DateTime.utc(2026, 12, 21),
        'Europe/Oslo',
      );
      expect((await worker.plan(pole, night.start, night.end)).state, 2);
      expect(
        (await worker.calculate(site, DateTime.utc(2026, 11, 5))).isNotEmpty,
        isTrue,
      );
    },
  );
  test(
    'Rapid date changes coalesce queued planning jobs and keep the worker usable',
    () async {
      final worker = await SkyWorker.start(catalogue);
      addTearDown(worker.close);
      final site = SkyObserver(41.0082, 28.9784);
      final jobs = <Future<int>>[];
      for (var day = 1; day <= 12; day++) {
        final w = PlanningTime.window(
          DateTime.utc(2026, 11, day),
          'Europe/Istanbul',
        );
        jobs.add(
          worker
              .plan(site, w.start, w.end)
              .then((p) => p.state, onError: (Object _) => -1),
        );
      }
      final results = await Future.wait(jobs);
      expect(results.last, 0);
      expect(results.where((r) => r == -1), isNotEmpty);
      expect(
        (await worker.calculate(site, DateTime.utc(2026, 11, 5))).isNotEmpty,
        isTrue,
      );
    },
  );
  testWidgets(
    'The Turkish guide opens the selected target without a sensor and shows local time',
    (tester) async {
      final site = SkyObserver(41.0082, 28.9784);
      final instant = DateTime.utc(2026, 11, 8, 18);
      final container = ProviderContainer(
        overrides: [
          catalogueProvider.overrideWith((ref) async => catalogue),
          accountApiProvider.overrideWithValue(FakeAccountApi()),
          credentialVaultProvider.overrideWithValue(MemoryVault()),
        ],
      );
      container.read(localeProvider.notifier).select('tr');
      container.read(planningZoneProvider.notifier).select('Europe/Istanbul');
      container.read(skyInstantProvider.notifier).select(instant);
      container
          .read(skyFrameProvider.notifier)
          .publish(SkyFrame(instant, site, {}, []));
      container.read(routerProvider).go('/observe?target=dso-mel022');
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const YorungezApp(),
        ),
      );
      for (var i = 0; i < 30 && find.text('Ülker').evaluate().isEmpty; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)),
        );
        await tester.pump();
      }
      expect(find.text('Nereye bakmalıyım?'), findsOneWidget);
      expect(find.text('Ülker'), findsOneWidget);
      expect(find.textContaining('GMT+03:00'), findsWidgets);
      expect(find.textContaining('ufuktan yaklaşık'), findsOneWidget);
      expect(find.textContaining('UTC'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      container.dispose();
    },
  );
  testWidgets(
    'Object details label simulated coordinates and show local time plus UTC',
    (tester) async {
      final instant = DateTime.utc(2026, 11, 5, 23),
          site = SkyObserver(41.0082, 28.9784, example: true);
      final c = ProviderContainer(
        overrides: [
          catalogueProvider.overrideWith((ref) async => catalogue),
          accountApiProvider.overrideWithValue(FakeAccountApi()),
          credentialVaultProvider.overrideWithValue(MemoryVault()),
        ],
      );
      c.read(planningZoneProvider.notifier).select('Europe/Istanbul');
      c.read(skyInstantProvider.notifier).select(instant);
      c
          .read(skyFrameProvider.notifier)
          .publish(
            SkyFrame.decode(
              catalogue,
              site,
              instant,
              NativeSky().calculate(
                site,
                instant,
                catalogue.starInput,
                catalogue.dsoInput,
              ),
            ),
          );
      c.read(routerProvider).go('/objects/moon');
      await tester.pumpWidget(
        UncontrolledProviderScope(container: c, child: const YorungezApp()),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Simulation'));
      expect(find.text('Live sky'), findsNothing);
      expect(find.textContaining('GMT+03:00'), findsOneWidget);
      expect(find.textContaining('UTC'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      c.dispose();
    },
  );
  for (final language in ['en', 'tr']) {
    for (final size in [const Size(320, 640), const Size(844, 390)]) {
      testWidgets('Calendar and month choices work in $language at $size', (
        tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final container = ProviderContainer(
          overrides: [
            eventCatalogueProvider.overrideWith((ref) async => events),
            accountApiProvider.overrideWithValue(FakeAccountApi()),
            credentialVaultProvider.overrideWithValue(MemoryVault()),
          ],
        );
        container.read(localeProvider.notifier).select(language);
        container.read(planningZoneProvider.notifier).select('Europe/Istanbul');
        container.read(routerProvider).go('/calendar');
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const YorungezApp(),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.text(language == 'en' ? 'Event calendar' : 'Etkinlik takvimi'),
          findsOneWidget,
        );
        expect(find.textContaining('GMT+03:00'), findsWidgets);
        expect(find.textContaining('UTC'), findsWidgets);
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('2026').first);
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.text('2035'),
          500,
          scrollable: find.byType(Scrollable).last,
        );
        expect(find.text('2035'), findsOneWidget);
        await tester.tap(find.text('2035'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        container.dispose();
      });
    }
  }
  testWidgets(
    'Private reminders hide on sign-out and a dismissed pending save never touches disposed UI',
    (tester) async {
      final api = ReminderApi();
      final live = ProviderContainer(
        overrides: [
          accountApiProvider.overrideWithValue(api),
          credentialVaultProvider.overrideWithValue(MemoryVault()),
        ],
      );
      await live
          .read(accountSessionProvider)
          .signIn('a@example.invalid', 'synthetic passphrase');
      live.read(localeProvider.notifier).select('en');
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: live,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Consumer(
              builder: (context, ref, _) => Scaffold(
                body: TextButton(
                  onPressed: () => showReminderEditor(
                    context,
                    ref,
                    title: 'Public event',
                    targetId: 'jupiter',
                    instant: DateTime.now().toUtc().add(
                      const Duration(days: 1),
                    ),
                  ),
                  child: const Text('Open reminder'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open reminder'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Schedule reminder'));
      await tester.pump();
      await tester.tap(find.widgetWithText(TextButton, 'Close'));
      await tester.pumpAndSettle();
      api.pending.complete(api.row);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: live,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const ReminderScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Jupiter'), findsOneWidget);
      await live.read(accountSessionProvider).signOut();
      await tester.pumpAndSettle();
      expect(find.textContaining('Jupiter'), findsNothing);
      expect(find.textContaining('Sign in to schedule'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      live.dispose();
    },
  );
}

class ReminderApi extends FakeAccountApi {
  final pending = Completer<dynamic>();
  Map<String, dynamic> get row => {
    'id': 'synthetic-id',
    'revision': 1,
    'targetId': 'jupiter',
    'title': 'Jupiter · Observing time',
    'eventId': null,
    'timeZoneId': 'Europe/Istanbul',
    'leadMinutes': 30,
    'channel': 'email',
    'status': 'scheduled',
    'instantUtc': DateTime.now()
        .toUtc()
        .add(const Duration(days: 1))
        .toIso8601String(),
    'dueAtUtc': DateTime.now()
        .toUtc()
        .add(const Duration(hours: 23))
        .toIso8601String(),
  };
  @override
  Future<dynamic> request(
    String path, {
    String method = 'GET',
    Map<String, dynamic>? body,
    String? access,
    String? owner,
    String language = 'en',
  }) {
    if (path == 'notebook/reminders') {
      return method == 'POST'
          ? pending.future
          : Future.value({
              'userId': this.owner,
              'reminders': [row],
            });
    }
    return super.request(
      path,
      method: method,
      body: body,
      access: access,
      owner: owner,
      language: language,
    );
  }
}
