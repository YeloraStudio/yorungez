import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:yorungez/catalogue/data/catalogue_repository.dart';
import 'package:yorungez/sky/data/native_sky.dart';
import 'package:yorungez/sky/domain/sky_frame.dart';
import 'package:yorungez/sky/domain/sky_geometry.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Catalogue catalogue;
  setUpAll(() async => catalogue = await CatalogueRepository().load());
  test(
    'Dart native ABI marshals the real catalogue and matches a frozen observer reference',
    () {
      final row =
          (jsonDecode(
                        File(
                          '../../tests/ReferenceData/Stars/astropy.json',
                        ).readAsStringSync(),
                      )['rows']
                      as List)
                  .first
              as Map;
      final c = row['context'] as Map;
      final observer = SkyObserver(
        (c['latitude'] as num).toDouble(),
        (c['longitude'] as num).toDouble(),
      );
      final instant = DateTime.parse(c['instantUtc'] as String);
      final raw = NativeSky().calculate(
        observer,
        instant,
        catalogue.starInput,
        catalogue.dsoInput,
      );
      final frame = SkyFrame.decode(catalogue, observer, instant, raw);
      expect(frame.points.length, catalogue.objects.length - 2);
      expect(frame.points['dso-ngc5128']!.altitude.isFinite, isTrue);
      expect(frame.points.containsKey('milky-way'), isFalse);
      final p = frame.points[row['starId']]!;
      expect(
        p.altitude,
        closeTo((row['altitudeDegrees'] as num).toDouble(), 1 / 60),
      );
      expect(
        p.azimuth,
        closeTo((row['azimuthDegrees'] as num).toDouble(), 1 / 60),
      );
      expect(frame.points['moon']!.distanceAu, greaterThan(0));
      expect(frame.points['sun']!.object.id, 'sun');
      expect(
        () => NativeSky().calculate(observer, instant, [1], []),
        throwsFormatException,
      );
    },
  );
  test(
    'serial isolate calculation rejects overlap and shuts down cleanly',
    () async {
      final worker = await SkyWorker.start(catalogue);
      try {
        final observer = SkyObserver(41.0082, 28.9784);
        final pending = worker.calculate(observer, DateTime.utc(2026, 11, 4));
        expect(
          () => worker.calculate(observer, DateTime.utc(2026, 11, 4)),
          throwsStateError,
        );
        final raw = await pending;
        expect(
          raw.length,
          84 + catalogue.starInput.length ~/ 3 + catalogue.dsoInput.length,
        );
        expect(raw.every((n) => n.isFinite), isTrue);
      } finally {
        worker.close();
      }
    },
  );
}
