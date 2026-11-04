import 'dart:typed_data';
import 'sky_geometry.dart';

final class TrackSample {
  const TrackSample(this.instant, this.direction);
  final DateTime instant;
  final Vec3 direction;
}

final class SkyTrack {
  SkyTrack(this.id, this.centre, this.observer, Float64List raw) {
    if (raw.length < 6 || raw.length % 3 != 0 || raw.any((v) => !v.isFinite)) {
      throw const FormatException('Invalid apparent track');
    }
    final samples = <TrackSample>[];
    for (var i = 0; i < raw.length; i += 3) {
      if (raw[i + 1] < 0 ||
          raw[i + 1] >= 360 ||
          raw[i + 2].abs() > 90 ||
          (i > 0 && raw[i] <= raw[i - 3])) {
        throw const FormatException('Invalid track sample');
      }
      samples.add(
        TrackSample(
          DateTime.fromMillisecondsSinceEpoch(raw[i].round(), isUtc: true),
          Vec3.horizon(raw[i + 1], raw[i + 2]),
        ),
      );
    }
    points = List.unmodifiable(samples);
  }
  final String id;
  final DateTime centre;
  final SkyObserver observer;
  late final List<TrackSample> points;
}
