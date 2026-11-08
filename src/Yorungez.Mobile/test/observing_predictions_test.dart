import 'package:flutter_test/flutter_test.dart';
import 'package:yorungez/catalogue/data/catalogue_repository.dart';
import 'package:yorungez/planning/iss_passes.dart';
import 'package:yorungez/planning/local_observing_events.dart';
import 'package:yorungez/planning/observing_guide.dart';
import 'package:yorungez/planning/planning_time.dart';
import 'package:yorungez/sky/data/native_sky.dart';
import 'package:yorungez/sky/domain/sky_geometry.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Catalogue catalogue;
  setUpAll(() async => catalogue = await CatalogueRepository().load());

  test('direction sectors wrap at north and observing thresholds differ', () {
    expect([359.0, 0.0, 22.49, 22.5, 90.0, 180.0, 270.0].map(compassSector), [
      0,
      0,
      0,
      1,
      2,
      4,
      6,
    ]);
    final start = DateTime.utc(2026, 11, 8, 18);
    final end = start.add(const Duration(hours: 1));
    final result = recommendObservations(
      start,
      end,
      (time) => (
        solarAltitude: -10,
        targets: [for (final _ in guideTargets) (azimuth: 235, altitude: 25)],
      ),
    );
    expect(result.keys, containsAll(['jupiter', 'saturn', 'dso-mel022']));
    expect(result, isNot(contains('dso-ngc1976')));
    expect(suitedTo('dso-ngc1976', ObservingEquipment.nakedEye), isFalse);
    expect(suitedTo('dso-ngc1976', ObservingEquipment.binoculars), isTrue);
  });

  test(
    'native guide returns Ülker at its actual plotted direction in Istanbul',
    () async {
      final worker = await SkyWorker.start(catalogue);
      addTearDown(worker.close);
      final site = SkyObserver(41.0082, 28.9784);
      final night = PlanningTime.window(
        DateTime.utc(2026, 11, 8),
        'Europe/Istanbul',
      );
      final slots = await worker.observingGuide(site, night.start, night.end);
      final pleiades = slots['dso-mel022']!;
      final target = catalogue.find('dso-mel022')!;
      final frame = NativeSky().calculate(site, pleiades.best, const [], [
        target.raHours!,
        target.decDegrees!,
      ]);
      expect(target.name('tr'), 'Ülker');
      expect(pleiades.direction.azimuth, closeTo(frame[72], 1e-8));
      expect(pleiades.direction.altitude, closeTo(frame[73], 1e-8));
      expect(frame[1], lessThanOrEqualTo(-6));
      expect(pleiades.start.isBefore(night.start), isFalse);
      expect(pleiades.end.isAfter(night.end), isFalse);
    },
  );

  test(
    'local solar eclipse agrees with NASA city times and excludes an out-of-path site',
    () async {
      // NASA August 12 2026 city table: Reykjavík partial contacts at 16:47 and
      // 18:47 local (UTC), with totality at approximately 17:48–17:49.
      final worker = await SkyWorker.start(catalogue);
      addTearDown(worker.close);
      final start = DateTime.utc(2026, 8), end = DateTime.utc(2026, 9);
      final iceland = await worker.localEvents(
        SkyObserver(64.1466, -21.9426),
        start,
        end,
      );
      final solar = iceland.singleWhere((event) => event.solar);
      expect(solar.kind, LocalEventKind.totalSolar);
      expect(
        solar.start
            .difference(DateTime.utc(2026, 8, 12, 16, 47))
            .abs()
            .inSeconds,
        lessThan(150),
      );
      expect(
        solar.suggested
            .difference(DateTime.utc(2026, 8, 12, 17, 49))
            .abs()
            .inSeconds,
        lessThan(150),
      );
      expect(
        solar.end.difference(DateTime.utc(2026, 8, 12, 18, 47)).abs().inSeconds,
        lessThan(150),
      );
      final nz = await worker.localEvents(
        SkyObserver(-36.8485, 174.7633),
        start,
        end,
      );
      expect(nz.where((event) => event.solar), isEmpty);
    },
  );

  test(
    'Lunar eclipse visibility differs by site and a hidden total phase is classified as partial',
    () async {
      final worker = await SkyWorker.start(catalogue);
      addTearDown(worker.close);
      final start = DateTime.utc(2026, 3), end = DateTime.utc(2026, 4);
      final auckland = await worker.localEvents(
        SkyObserver(-36.8485, 174.7633),
        start,
        end,
      );
      final moon = auckland.singleWhere(
        (event) => event.kind == LocalEventKind.totalLunar,
      );
      expect(moon.suggested.isAfter(DateTime.utc(2026, 3, 3, 11, 4)), isTrue);
      expect(moon.suggested.isBefore(DateTime.utc(2026, 3, 3, 12, 3)), isTrue);
      final istanbul = await worker.localEvents(
        SkyObserver(41.0082, 28.9784),
        start,
        end,
      );
      expect(istanbul.where((event) => !event.solar && !event.meteor), isEmpty);

      final phaseStart = DateTime.utc(2026, 3, 3, 9, 50);
      final moonset = DateTime.utc(2026, 3, 3, 10, 45);
      final partial = localObservingEvents(
        start,
        end,
        [
          (
            kind: LocalEventKind.totalLunar,
            start: phaseStart,
            peak: DateTime.utc(2026, 3, 3, 11, 34),
            end: DateTime.utc(2026, 3, 3, 13, 17),
            centralStart: DateTime.utc(2026, 3, 3, 11, 4),
            centralEnd: DateTime.utc(2026, 3, 3, 12, 3),
          ),
        ],
        (instant, _) =>
            List<double>.filled(10, 0)
              ..[9] = instant.isBefore(moonset) ? 1 : -1,
      );
      expect(partial.single.kind, LocalEventKind.partialLunar);
      expect(partial.single.end.isAfter(moonset), isFalse);
    },
  );

  test(
    'Geminid suggestions require darkness and a raised radiant at the site',
    () async {
      final worker = await SkyWorker.start(catalogue);
      addTearDown(worker.close);
      final site = SkyObserver(41.0082, 28.9784);
      final result = await worker.localEvents(
        site,
        DateTime.utc(2026, 12),
        DateTime.utc(2027),
      );
      final geminids = result.singleWhere(
        (event) => event.kind == LocalEventKind.geminids,
      );
      final raw = NativeSky().calculate(site, geminids.suggested, const [], [
        112 / 15,
        33,
      ]);
      expect(raw[1], lessThanOrEqualTo(-18));
      expect(raw[73], greaterThanOrEqualTo(15));
      expect(
        geminids.suggested
            .difference(DateTime.utc(2026, 12, 14, 14))
            .abs()
            .inHours,
        lessThan(18),
      );
    },
  );

  test(
    'ISS sunlight distinguishes twilight illumination from Earth shadow',
    () {
      final site = SkyObserver(0, 0);
      const station = (azimuth: 0.0, altitude: 90.0);
      expect(
        stationInFullSunlight(site, station, 420, (
          azimuth: 270,
          altitude: -10,
        ), 1),
        isTrue,
      );
      expect(
        stationInFullSunlight(site, station, 420, (
          azimuth: 270,
          altitude: -90,
        ), 1),
        isFalse,
      );
      final start = DateTime.utc(2026, 11, 8, 18);
      final passes = estimateIssPasses(
        site,
        start,
        start.add(const Duration(minutes: 5)),
        (instant) {
          final seconds = instant.difference(start).inSeconds;
          return [0, 0, 0, 0, 0, 0, 90, seconds >= 60 ? 90 : 0, 420];
        },
        (instant) => [
          270,
          instant.difference(start).inSeconds < 150 ? -10 : -90,
          0,
          0,
          1,
        ],
      );
      expect(passes, hasLength(1));
      expect(passes.single.start.difference(start).inSeconds, closeTo(60, 1));
      expect(passes.single.end.difference(start).inSeconds, closeTo(150, 1));
    },
  );
}
