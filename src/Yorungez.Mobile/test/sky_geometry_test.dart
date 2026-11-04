import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:yorungez/sky/domain/sky_geometry.dart';
import 'package:yorungez/sky/data/mobile_services.dart';

void main() {
  test(
    'true azimuth wraps and a selected direction projects to the optical centre',
    () {
      for (final az in [0.0, 1.0, 90.0, 180.0, 359.0]) {
        for (final alt in [-89.0, 0.0, 45.0, 89.0]) {
          final pose = ViewPose.horizon(az, alt);
          final xy = SkyProjection(
            pose,
            390,
            844,
            80,
          ).project(Vec3.horizon(az, alt))!;
          expect(xy.$1, closeTo(195, 1e-8));
          expect(xy.$2, closeTo(422, 1e-8));
          expect(pose.right.dot(pose.up), closeTo(0, 1e-12));
        }
      }
    },
  );
  test(
    'rear optical axis and display rotation preserve handedness and roll',
    () {
      const r = [1.0, 0.0, 0.0, 0.0, 0.0, -1.0, 0.0, 1.0, 0.0];
      for (final rotation in [0, 90, 180, 270]) {
        final pose = ViewPose.device(r, rotation);
        expect(pose.forward.azimuth, closeTo(0, 1e-8));
        expect(pose.forward.altitude, closeTo(0, 1e-8));
        expect(pose.right.cross(pose.forward).dot(pose.up), closeTo(1, 1e-8));
      }
      final landscape = ViewPose.device(r, 90);
      expect(landscape.up.x, closeTo(-1, 1e-8));
      final aligned = ViewPose.device(r, 0, math.pi / 2);
      expect(aligned.forward.azimuth, closeTo(90, 1e-8));
    },
  );
  test(
    'optical projection rejects behind-camera vectors; wide virtual sky stays finite',
    () {
      final pose = ViewPose.horizon(0, 0);
      expect(
        SkyProjection(
          pose,
          844,
          390,
          60,
          optical: true,
        ).project(Vec3.horizon(180, 0)),
        isNull,
      );
      final xy = SkyProjection(
        pose,
        844,
        390,
        240,
      ).project(Vec3.horizon(110, 0));
      expect(xy, isNotNull);
      expect(xy!.$1.isFinite, isTrue);
      expect(
        () => ViewPose.device(List.filled(9, 0.0), 0),
        throwsFormatException,
      );
    },
  );
  test(
    'pose source, freshness and invalid matrices cannot silently become true north',
    () {
      final now = DateTime.now();
      final sample = PoseSample.decode({
        'matrix': [1, 0, 0, 0, 0, -1, 0, 1, 0],
        'rotation': 0,
        'reference': 'magnetic',
        'quality': 2,
        'timestampMs': now.millisecondsSinceEpoch,
      });
      expect(sample.reference, 'magnetic');
      expect(sample.fresh(now), isTrue);
      expect(sample.fresh(now.add(const Duration(seconds: 3))), isFalse);
      expect(
        () => PoseSample.decode({
          'matrix': [1, 0, 0, 0, 0, -1, 0, 1, 0],
          'rotation': 0,
          'reference': 'relative',
          'quality': 3,
          'timestampMs': 0,
        }),
        throwsFormatException,
      );
    },
  );
  test('unsupported polar and non-finite observer contexts are rejected', () {
    expect(() => SkyObserver(89, 0), throwsFormatException);
    expect(() => SkyObserver(double.nan, 0), throwsFormatException);
    expect(() => SkyObserver(41, 181), throwsFormatException);
    expect(
      () => SkyObserver(41, 29, elevation: double.infinity),
      throwsFormatException,
    );
  });
}
