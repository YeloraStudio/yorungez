import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yorungez/catalogue/data/catalogue_repository.dart';
import 'package:yorungez/sky/data/iss_elements.dart';
import 'package:yorungez/sky/data/native_satellite.dart';
import 'package:yorungez/sky/data/native_sky.dart';
import 'package:yorungez/sky/domain/sky_frame.dart';
import 'package:yorungez/sky/domain/sky_geometry.dart';
import 'package:yorungez/sky/domain/sky_track.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final now = DateTime.utc(2026, 11, 4, 9);
  Map<String, dynamic> packet({int identity = 25544, String frame = 'TEME'}) {
    final raw = jsonEncode([
      {
        'NORAD_CAT_ID': identity,
        'EPOCH': '2026-11-04T08:00:00',
        'REF_FRAME': frame,
        'MEAN_MOTION': 15.5,
        'ECCENTRICITY': .0004,
        'INCLINATION': 51.6,
        'RA_OF_ASC_NODE': 75.0,
        'ARG_OF_PERICENTER': 20.0,
        'MEAN_ANOMALY': 15.0,
        'BSTAR': .0001,
        'MEAN_MOTION_DOT': .00001,
        'MEAN_MOTION_DDOT': 0,
      },
    ]);
    return {
      'schemaVersion': 1,
      'noradCatalogId': 25544,
      'referenceFrame': 'TEME',
      'timeSystem': 'UTC',
      'meanElementTheory': 'SGP4',
      'epochUtc': '2026-11-04T08:00:00Z',
      'retrievedAtUtc': '2026-11-04T09:00:00Z',
      'expiresAtUtc': '2026-11-07T08:00:00Z',
      'sourceUrl':
          'https://celestrak.org/NORAD/elements/gp.php?CATNR=25544&FORMAT=JSON',
      'rawOmm': raw,
      'sha256': sha256.convert(utf8.encode(raw)).toString(),
    };
  }

  test(
    'public OMM digest, identity, frame and finite offline lifetime are enforced',
    () {
      final valid = IssElements.decode(packet(), now);
      expect(valid.usable(now), isTrue);
      expect(valid.usable(DateTime.utc(2026, 11, 7, 8)), isFalse);
      expect(
        () => IssElements.decode({...packet(), 'sha256': '0' * 64}, now),
        throwsFormatException,
      );
      expect(
        () => IssElements.decode(packet(identity: 5), now),
        throwsFormatException,
      );
      expect(
        () => IssElements.decode(packet(frame: 'J2000'), now),
        throwsFormatException,
      );
    },
  );
  test(
    'native satellite ABI agrees with frozen official Vanguard position and velocity',
    () {
      // Official 00005 verification input; not a production ISS observation.
      final epoch = DateTime.utc(
        2000,
        1,
        1,
      ).add(Duration(microseconds: ((179.78495062 - 1) * 86400 * 1e6).round()));
      final raw = NativeSatellite().calculate(
        [
          epoch.microsecondsSinceEpoch / 1e6,
          2.8098e-5,
          2.3e-7,
          0,
          .1859667,
          331.7664,
          34.2682,
          19.3264,
          10.82419157,
          348.7242,
        ],
        SkyObserver(41, 29),
        epoch,
      );
      final expected = [
        7022.46529266,
        -1400.08296755,
        .03995155,
        1.893841015,
        6.405893759,
        4.534807250,
      ];
      for (var i = 0; i < 6; i++) {
        expect(raw[i], closeTo(expected[i], i < 3 ? 2e-5 : 2e-8));
      }
      expect(raw[8], greaterThan(0));
    },
  );
  test(
    'station frame and short path share one serialized local calculation context',
    () async {
      final catalogue = await CatalogueRepository().load(),
          observer = SkyObserver(41, 29),
          elements = IssElements.decode(packet(), now);
      final worker = await SkyWorker.start(catalogue);
      try {
        final raw = await worker.calculate(observer, now, iss: elements.values);
        final frame = SkyFrame.decode(catalogue, observer, now, raw);
        expect(frame.points['sat-25544'], isNotNull);
        final track = SkyTrack(
          'sat-25544',
          now,
          observer,
          await worker.trajectory(
            observer,
            now,
            'sat-25544',
            iss: elements.values,
          ),
        );
        expect(track.points.length, 121);
        expect(
          track.points[60].direction.dot(frame.points['sat-25544']!.vector),
          closeTo(1, 1e-12),
        );
      } finally {
        worker.close();
      }
    },
  );
}
