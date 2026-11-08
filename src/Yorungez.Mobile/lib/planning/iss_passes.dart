import 'dart:math' as math;
import 'dart:typed_data';

import '../sky/domain/sky_geometry.dart';
import 'observing_guide.dart';
import 'observing_intervals.dart';

final class IssPass {
  const IssPass(
    this.start,
    this.peak,
    this.end,
    this.appears,
    this.highest,
    this.disappears,
  );
  final DateTime start, peak, end;
  final GuideDirection appears, highest, disappears;
}

// Compare the apparent solar and terrestrial discs as seen from the ISS.
// The Earth uses its equatorial radius, a conservative spherical shadow.
bool stationInFullSunlight(
  SkyObserver site,
  GuideDirection station,
  double rangeKm,
  GuideDirection sun,
  double sunDistanceAu,
) {
  const earthRadius = 6378.137, eccentricitySquared = .0066943799901413165;
  final phi = site.latitude * radians;
  final sin = math.sin(phi), cos = math.cos(phi);
  final n = earthRadius / math.sqrt(1 - eccentricitySquared * sin * sin);
  final siteEnu = Vec3(
    0,
    -n * eccentricitySquared * sin * cos,
    n * (1 - eccentricitySquared * sin * sin) + site.elevation / 1000,
  );
  final toStation = Vec3.horizon(station.azimuth, station.altitude) * rangeKm;
  final toEarth = (siteEnu + toStation) * -1;
  final toSun =
      Vec3.horizon(sun.azimuth, sun.altitude) * (sunDistanceAu * 149597870.7) +
      toStation * -1;
  final earthDistance = math.sqrt(toEarth.dot(toEarth));
  final sunDistance = math.sqrt(toSun.dot(toSun));
  if (earthDistance <= earthRadius || sunDistance <= 695700) return false;
  final separation = math.acos(toEarth.unit.dot(toSun.unit).clamp(-1, 1));
  return separation >
      math.asin(earthRadius / earthDistance) + math.asin(695700 / sunDistance);
}

List<IssPass> estimateIssPasses(
  SkyObserver site,
  DateTime start,
  DateTime end,
  List<double> Function(DateTime) stationAt,
  List<double> Function(DateTime) skyAt,
) {
  final cache = <DateTime, (GuideDirection, bool)>{};
  (GuideDirection, bool) sample(DateTime instant) =>
      cache.putIfAbsent(instant, () {
        final raw = stationAt(instant);
        final direction = (azimuth: raw[6], altitude: raw[7]);
        if (direction.altitude < 10) return (direction, false);
        final sun = skyAt(instant);
        if (sun[1] > -6) return (direction, false);
        return (
          direction,
          stationInFullSunlight(site, direction, raw[8], (
            azimuth: sun[0],
            altitude: sun[1],
          ), sun[4]),
        );
      });
  final windows = observingIntervals(
    start,
    end,
    const Duration(seconds: 15),
    (t) => sample(t).$2,
  );
  final passes = <IssPass>[];
  for (final window in windows) {
    // A range edge is not a physical appearance or disappearance.
    if (window.start == start ||
        window.end == end ||
        window.end.difference(window.start) < const Duration(seconds: 30)) {
      continue;
    }
    var peak = window.start;
    for (
      var t = window.start;
      !t.isAfter(window.end);
      t = t.add(const Duration(seconds: 5))
    ) {
      if (sample(t).$1.altitude > sample(peak).$1.altitude) peak = t;
    }
    if (sample(window.end).$1.altitude > sample(peak).$1.altitude) {
      peak = window.end;
    }
    passes.add(
      IssPass(
        window.start,
        peak,
        window.end,
        sample(window.start).$1,
        sample(peak).$1,
        sample(window.end).$1,
      ),
    );
  }
  return passes;
}

Float64List encodePasses(List<IssPass> passes) => Float64List.fromList([
  for (final pass in passes) ...[
    pass.start.millisecondsSinceEpoch.toDouble(),
    pass.peak.millisecondsSinceEpoch.toDouble(),
    pass.end.millisecondsSinceEpoch.toDouble(),
    for (final direction in [pass.appears, pass.highest, pass.disappears]) ...[
      direction.azimuth,
      direction.altitude,
    ],
  ],
]);

List<IssPass> decodePasses(Float64List raw) {
  if (raw.length % 9 != 0 || raw.any((value) => !value.isFinite)) {
    throw const FormatException('Invalid ISS passes');
  }
  DateTime at(int i) =>
      DateTime.fromMillisecondsSinceEpoch(raw[i].round(), isUtc: true);
  GuideDirection direction(int i) => (azimuth: raw[i], altitude: raw[i + 1]);
  return [
    for (var i = 0; i < raw.length; i += 9)
      IssPass(
        at(i),
        at(i + 1),
        at(i + 2),
        direction(i + 3),
        direction(i + 5),
        direction(i + 7),
      ),
  ];
}
