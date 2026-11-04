import 'dart:typed_data';
import '../../catalogue/data/catalogue_repository.dart';
import '../../catalogue/domain/sky_object.dart';
import 'sky_geometry.dart';

final class SkyPoint {
  SkyPoint(
    this.object,
    this.azimuth,
    this.altitude, {
    this.magnitude,
    this.distanceAu,
    this.radius = 0,
    this.raOfDate,
    this.decOfDate,
    this.phase = 1,
  }) : vector = Vec3.horizon(azimuth, altitude);
  final SkyObject object;
  final double azimuth, altitude;
  final Vec3 vector;
  final double? magnitude, distanceAu;
  final double radius, phase;
  final double? raOfDate, decOfDate;
}

final class SkyFrame {
  SkyFrame(
    this.instant,
    this.observer,
    this.points,
    this.equatorialToEnu, [
    this.artAnchors = const [],
    this.magneticCorrection,
  ]);
  final DateTime instant;
  final SkyObserver observer;
  final Map<String, SkyPoint> points;
  final List<double> equatorialToEnu;
  final List<Vec3> artAnchors;
  final (double, double, double)? magneticCorrection;
  factory SkyFrame.decode(
    Catalogue catalogue,
    SkyObserver observer,
    DateTime instant,
    Float64List raw,
  ) {
    final stars = catalogue.objects
        .where((o) => o.kind == ObjectKind.star)
        .toList();
    final dsos = catalogue.objects
        .where((o) => o.kind == ObjectKind.deepSky)
        .toList();
    final expected = 81 + catalogue.starInput.length ~/ 3 + dsos.length * 2;
    if (![
          expected,
          expected + 3,
          expected + 9,
          expected + 12,
        ].contains(raw.length) ||
        raw.any((v) => !v.isFinite)) {
      throw const FormatException('Invalid sky frame');
    }
    final points = <String, SkyPoint>{};
    for (var i = 0; i < solarObjects.length; i++) {
      final o = catalogue.find(solarObjects[i].id)!;
      points[o.id] = SkyPoint(
        o,
        raw[i * 8],
        raw[i * 8 + 1],
        magnitude: raw[i * 8 + 5],
        distanceAu: raw[i * 8 + 4],
        radius: raw[i * 8 + 6],
        phase: raw[i * 8 + 7],
        raOfDate: raw[i * 8 + 2],
        decOfDate: raw[i * 8 + 3],
      );
    }
    var offset = 72;
    for (final o in stars) {
      points[o.id] = SkyPoint(
        o,
        raw[offset],
        raw[offset + 1],
        magnitude: o.magnitude,
      );
      offset += 2;
    }
    final anchors = <Vec3>[];
    for (var i = 0; i < catalogue.starInput.length ~/ 6 - stars.length; i++) {
      anchors.add(Vec3.horizon(raw[offset], raw[offset + 1]));
      offset += 2;
    }
    for (final o in dsos) {
      points[o.id] = SkyPoint(
        o,
        raw[offset],
        raw[offset + 1],
        magnitude: o.magnitude,
      );
      offset += 2;
    }
    for (final entry in catalogue.lines.entries) {
      var sum = const Vec3(0, 0, 0);
      for (final id in entry.value.expand((line) => line).toSet()) {
        final v = points[id]?.vector;
        if (v != null) sum = sum + v;
      }
      if (sum.dot(sum) > 0) {
        final v = sum.unit;
        final o = catalogue.find(entry.key);
        if (o != null) points[o.id] = SkyPoint(o, v.azimuth, v.altitude);
      }
    }
    if (raw.length == expected + 9 || raw.length == expected + 12) {
      points[issObject.id] = SkyPoint(
        issObject,
        raw[offset + 15],
        raw[offset + 16],
        distanceAu: raw[offset + 17] / 149597870.7,
      );
    }
    return SkyFrame(
      instant,
      observer,
      Map.unmodifiable(points),
      raw.sublist(offset, offset + 9),
      List.unmodifiable(anchors),
      raw.length == expected + 3 || raw.length == expected + 12
          ? (raw[raw.length - 3], raw[raw.length - 2], raw.last)
          : null,
    );
  }
}
