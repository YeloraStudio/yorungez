import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:yorungez/catalogue/data/catalogue_repository.dart';
import 'package:yorungez/sky/data/native_sky.dart';
import 'package:yorungez/sky/data/sky_visuals.dart';
import 'package:yorungez/sky/domain/sky_frame.dart';
import 'package:yorungez/sky/domain/sky_geometry.dart';
import 'package:yorungez/sky/domain/sky_track.dart';
import 'package:yorungez/sky/presentation/sky_painter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'registered galactic frame puts centre and north pole at expected panorama landmarks',
    () {
      Vec3 equatorial(double ra, double dec) => Vec3(
        math.cos(dec * radians) * math.cos(ra * radians),
        math.cos(dec * radians) * math.sin(ra * radians),
        math.sin(dec * radians),
      );
      Vec3 transform(Vec3 e) => Vec3(
        equatorialToGalactic[0] * e.x +
            equatorialToGalactic[1] * e.y +
            equatorialToGalactic[2] * e.z,
        equatorialToGalactic[3] * e.x +
            equatorialToGalactic[4] * e.y +
            equatorialToGalactic[5] * e.z,
        equatorialToGalactic[6] * e.x +
            equatorialToGalactic[7] * e.y +
            equatorialToGalactic[8] * e.z,
      );
      final centre = transform(equatorial(266.4051, -28.936175));
      expect(centre.x, closeTo(1, 1e-8));
      expect(centre.y.abs(), lessThan(2e-6));
      expect(centre.z.abs(), lessThan(2e-6));
      final pole = transform(equatorial(192.85948, 27.12825));
      expect(pole.z, closeTo(1, 1e-12));
      expect(
        galacticFromEnu([1, 0, 0, 0, 1, 0, 0, 0, 1]),
        equatorialToGalactic,
      );
    },
  );
  test(
    'new, full and quarter phase masks keep the illuminated limb on the Sun side',
    () {
      expect(illuminatedDisc(10, 0).contains(const Offset(4, 0)), isTrue);
      expect(illuminatedDisc(10, 1).contains(const Offset(-4, 0)), isFalse);
      expect(illuminatedDisc(10, .5).contains(const Offset(4, 0)), isFalse);
      expect(illuminatedDisc(10, .5).contains(const Offset(-4, 0)), isTrue);
    },
  );
  test(
    'Orion and Leo source anchors land exactly on their calculated stellar rays',
    () async {
      final catalogue = await CatalogueRepository().load(),
          observer = SkyObserver(41, 29);
      final instant = DateTime.utc(2026, 11, 4);
      final frame = SkyFrame.decode(
        catalogue,
        observer,
        instant,
        NativeSky().calculate(
          observer,
          instant,
          catalogue.starInput,
          catalogue.dsoInput,
        ),
      );
      expect(frame.artAnchors.length, 255);
      for (final id in ['con-ori', 'con-leo']) {
        final figure = (catalogue.art['figures'] as List).singleWhere(
          (f) => f['id'] == id,
        );
        final ids = (figure['anchors'] as List).cast<int>();
        final anchors = [
          for (final i in ids) (catalogue.art['anchors'] as List)[i],
        ];
        final rays = [for (final i in ids) frame.artAnchors[i]];
        for (var i = 0; i < 3; i++) {
          final actual = figureRay(
            (anchors[i]['x'] as num).toDouble(),
            (anchors[i]['y'] as num).toDouble(),
            anchors,
            rays,
          );
          expect(actual.dot(rays[i]), closeTo(1, 1e-12));
        }
      }
    },
  );
  test(
    'a queued apparent track matches independent full-frame calculations at sampled UTC instants',
    () async {
      final catalogue = await CatalogueRepository().load(),
          observer = SkyObserver(41, 29);
      final instant = DateTime.utc(2026, 11, 4),
          worker = await SkyWorker.start(catalogue);
      try {
        final path = worker.trajectory(observer, instant, 'moon');
        final frame = worker.calculate(observer, instant);
        final track = SkyTrack('moon', instant, observer, await path);
        expect(track.points.length, 73);
        expect(
          (await frame).length,
          84 + catalogue.starInput.length ~/ 3 + catalogue.dsoInput.length,
        );
        final native = NativeSky();
        for (final sample in [
          track.points.first,
          track.points[36],
          track.points.last,
        ]) {
          final raw = native.calculate(observer, sample.instant, [], []);
          expect(
            sample.direction.dot(Vec3.horizon(raw[8], raw[9])),
            closeTo(1, 1e-12),
          );
        }
      } finally {
        worker.close();
      }
    },
  );
}
