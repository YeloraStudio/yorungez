import 'dart:math' as math;
import 'dart:ui' as ui;
import '../data/sky_visuals.dart';
import 'package:flutter/material.dart';
import '../../catalogue/data/catalogue_repository.dart';
import '../../catalogue/domain/sky_object.dart';
import '../domain/sky_frame.dart';
import '../domain/sky_track.dart';
import '../domain/sky_geometry.dart';

enum SkyLayer {
  stars,
  solar,
  deepSky,
  constellations,
  figures,
  cosmic,
  grid,
  horizon,
  atmosphere,
}

class SkyPainter extends CustomPainter {
  SkyPainter({
    required this.frame,
    required this.catalogue,
    required this.pose,
    required this.fov,
    required this.layers,
    required this.language,
    required this.cardinals,
    this.selected,
    this.optical = false,
    this.camera = false,
    this.visuals,
    this.track,
    this.dwellProgress = 0,
    this.selectionProgress = 0,
  });
  final SkyVisuals? visuals;
  final SkyTrack? track;
  final SkyFrame frame;
  final Catalogue catalogue;
  final ViewPose pose;
  final double fov;
  final Set<SkyLayer> layers;
  final String language;
  final List<String> cardinals;
  final String? selected;
  final bool optical, camera;
  final double dwellProgress, selectionProgress;
  bool visible(SkyPoint p) => switch (p.object.kind) {
    ObjectKind.star =>
      layers.contains(SkyLayer.stars) && (p.magnitude ?? 8) < 6.6,
    ObjectKind.deepSky => layers.contains(SkyLayer.deepSky),
    ObjectKind.solarSystem => layers.contains(SkyLayer.solar),
    ObjectKind.satellite => layers.contains(SkyLayer.solar),
    ObjectKind.constellation => layers.contains(SkyLayer.constellations),
    ObjectKind.extended => false,
  };
  SkyPoint? pick(Offset point, Size size) {
    final projection = SkyProjection(
      pose,
      size.width,
      size.height,
      fov,
      optical: optical,
    );
    SkyPoint? best;
    var distance = 30.0;
    for (final p in frame.points.values) {
      if (!visible(p)) continue;
      final xy = projection.project(p.vector);
      if (xy == null) continue;
      final d = (Offset(xy.$1, xy.$2) - point).distance;
      if (d < distance) {
        distance = d;
        best = p;
      }
    }
    return best;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final projection = SkyProjection(
      pose,
      size.width,
      size.height,
      fov,
      optical: optical,
    );
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    if (!camera) {
      canvas.drawColor(const Color(0xFF020308), BlendMode.srcOver);
      _cosmic(canvas, size);
    }
    if (!camera && layers.contains(SkyLayer.atmosphere)) {
      final sun = frame.points['sun']!.altitude;
      final daylight = ((sun + 15) / 30).clamp(0.0, 1.0);
      canvas.drawRect(
        Offset.zero & size,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.lerp(
                const Color(0xFF020308),
                const Color(0xFF24475E),
                daylight,
              )!,
              Color.lerp(
                const Color(0xFF0B101A),
                const Color(0xFF95A6AD),
                daylight,
              )!,
            ],
          ).createShader(Offset.zero & size),
      );
    }
    void line(Iterable<Vec3> vectors, Color colour, [double width = .65]) {
      final path = Path();
      Offset? previous;
      for (final v in vectors) {
        final xy = projection.project(v);
        final p = xy == null ? null : Offset(xy.$1, xy.$2);
        if (p == null ||
            (p.dx.abs() > size.width * 8 || p.dy.abs() > size.height * 8)) {
          previous = null;
          continue;
        }
        if (previous == null ||
            (p - previous).distance > size.longestSide * .6) {
          path.moveTo(p.dx, p.dy);
        } else {
          path.lineTo(p.dx, p.dy);
        }
        previous = p;
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = colour
          ..style = PaintingStyle.stroke
          ..strokeWidth = width,
      );
    }

    _track(canvas, size, projection);
    if (layers.contains(SkyLayer.figures)) _figures(canvas, size, projection);
    if (layers.contains(SkyLayer.grid)) {
      for (var alt = -60; alt <= 60; alt += 30) {
        line([
          for (var az = 0; az <= 360; az += 2)
            Vec3.horizon(az.toDouble(), alt.toDouble()),
        ], const Color(0x448A7471));
      }
      for (var az = 0; az < 360; az += 30) {
        line([
          for (var alt = -90; alt <= 90; alt += 2)
            Vec3.horizon(az.toDouble(), alt.toDouble()),
        ], const Color(0x448A7471));
      }
    }
    if (layers.contains(SkyLayer.constellations)) {
      for (final lines in catalogue.lines.values) {
        for (final ids in lines) {
          line(
            ids.map((id) => frame.points[id]!.vector),
            const Color(0x997B96AD),
            1,
          );
        }
      }
    }
    var labels = 0;
    void label(
      String value,
      Offset p, {
      Color colour = const Color(0xFFC9B6A6),
    }) {
      if (p.dx < 0 ||
          p.dy < 0 ||
          p.dx > size.width - 30 ||
          p.dy > size.height - 28) {
        return;
      }
      final painter = TextPainter(
        text: TextSpan(
          text: value,
          style: TextStyle(
            color: colour,
            fontSize: 11,
            shadows: const [Shadow(blurRadius: 3, color: Colors.black)],
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout(maxWidth: 170);
      painter.paint(canvas, p);
    }

    for (final p in frame.points.values) {
      if (!visible(p)) continue;
      if (layers.contains(SkyLayer.atmosphere) &&
          !camera &&
          frame.points['sun']!.altitude > 0 &&
          p.object.kind == ObjectKind.star &&
          (p.magnitude ?? 8) > -2) {
        continue;
      }
      final xy = projection.project(p.vector);
      if (xy == null) continue;
      final pos = Offset(xy.$1, xy.$2);
      if (pos.dx < -40 ||
          pos.dy < -40 ||
          pos.dx > size.width + 40 ||
          pos.dy > size.height + 40) {
        continue;
      }
      if (p.object.kind == ObjectKind.satellite) {
        _station(
          canvas,
          pos,
          p.object.id == selected ? 1 + .2 * selectionProgress : 1,
        );
      } else if (p.object.kind == ObjectKind.star ||
          p.object.kind == ObjectKind.solarSystem) {
        final mag = p.magnitude ?? 5;
        final radius =
            (2.3 - mag * .3).clamp(.5, 4.5) *
            (p.object.id == selected ? 1 + .25 * selectionProgress : 1);
        final bv = catalogue.colours[p.object.id] ?? .3;
        final colour = p.object.id == 'mars'
            ? const Color(0xFFE8A185)
            : p.object.id == 'sun'
            ? const Color(0xFFFFEDBD)
            : bv < .15
            ? const Color(0xFFDCE8FF)
            : bv > .9
            ? const Color(0xFFFFD1A0)
            : const Color(0xFFF7F1E6);
        if (mag < 1.2) {
          final rect = Rect.fromCircle(center: pos, radius: radius * 5);
          canvas.drawCircle(
            pos,
            radius * 5,
            Paint()
              ..shader = RadialGradient(
                colors: [
                  colour.withValues(alpha: .28),
                  colour.withValues(alpha: 0),
                ],
              ).createShader(rect),
          );
        }
        if (p.object.kind == ObjectKind.solarSystem &&
            visuals?.images[p.object.id] != null) {
          _solar(canvas, size, projection, p, pos);
        } else {
          canvas.drawCircle(pos, radius, Paint()..color = colour);
        }
      } else if (p.object.kind == ObjectKind.deepSky) {
        canvas.drawOval(
          Rect.fromCenter(center: pos, width: 9, height: 5),
          Paint()
            ..color = const Color(0xAA9EA1A6)
            ..style = PaintingStyle.stroke,
        );
      }
      final important =
          p.object.kind == ObjectKind.solarSystem || p.object.id == selected;
      if (important ||
          (labels < 16 &&
              ((p.magnitude ?? 9) < 1 ||
                  p.object.kind == ObjectKind.constellation))) {
        label(
          p.object.name(language),
          pos + const Offset(7, 7),
          colour: important ? const Color(0xFFF7F1E6) : const Color(0xFFC9B6A6),
        );
        labels++;
      }
      if (p.object.id == selected) {
        canvas.drawCircle(
          pos,
          16,
          Paint()
            ..color = const Color(0xFFBF5265)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
      }
    }
    if (layers.contains(SkyLayer.horizon)) {
      line(
        [for (var az = 0; az <= 360; az++) Vec3.horizon(az.toDouble(), 0)],
        const Color(0xFF8B2333),
        1.2,
      );
      for (var i = 0; i < 4; i++) {
        final p = projection.project(Vec3.horizon(i * 90.0, 0));
        if (p != null) {
          label(
            cardinals[i],
            Offset(p.$1, p.$2 - 23),
            colour: const Color(0xFFF7F1E6),
          );
        }
      }
    }
    final centre = Offset(size.width / 2, size.height / 2);
    final reticle = Paint()
      ..color = const Color(0x669EA1A6)
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(centre, 28, reticle);
    if (dwellProgress > 0 && dwellProgress < 1) {
      canvas.drawArc(
        Rect.fromCircle(center: centre, radius: 30),
        -math.pi / 2,
        math.pi * 2 * dwellProgress,
        false,
        Paint()
          ..color = const Color(0xFFC9B6A6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
    canvas.drawLine(
      centre + const Offset(-36, 0),
      centre + const Offset(-23, 0),
      reticle,
    );
    canvas.drawLine(
      centre + const Offset(23, 0),
      centre + const Offset(36, 0),
      reticle,
    );
    canvas.restore();
  }

  void _track(Canvas canvas, Size size, SkyProjection projection) {
    final path = track;
    if (path == null || !identical(path.observer, frame.observer)) return;
    final limit =
        (path.points.length * Curves.easeOut.transform(selectionProgress))
            .ceil();
    Offset? previous;
    for (final sample in path.points.take(limit)) {
      final xy = projection.project(sample.direction);
      if (xy == null) {
        previous = null;
        continue;
      }
      final p = Offset(xy.$1, xy.$2);
      if (previous != null && (p - previous).distance < size.longestSide * .4) {
        final paint = Paint()
          ..color = const Color(0x667B96AD)
          ..strokeWidth = 2;
        if (sample.instant.isBefore(path.centre)) {
          canvas.drawLine(previous, p, paint);
        } else {
          final length = (p - previous).distance;
          for (var d = 0.0; d < length; d += 8) {
            canvas.drawCircle(
              Offset.lerp(previous, p, d / math.max(length, 1))!,
              1.6,
              paint,
            );
          }
        }
      }
      previous = p;
    }
  }

  void _cosmic(Canvas canvas, Size size) {
    final shader = visuals?.cosmic;
    if (shader == null || !layers.contains(SkyLayer.cosmic)) return;
    final rotation = galacticFromEnu(frame.equatorialToEnu);
    final uniforms = [
      size.width,
      size.height,
      size.shortestSide / (2 * math.tan(fov * radians / 2)),
      pose.forward.x,
      pose.forward.y,
      pose.forward.z,
      pose.right.x,
      pose.right.y,
      pose.right.z,
      pose.up.x,
      pose.up.y,
      pose.up.z,
      ...rotation,
      1.65,
    ];
    for (var i = 0; i < uniforms.length; i++) {
      shader.setFloat(i, uniforms[i]);
    }
    canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
  }

  Set<String> wantedArt() {
    if (!layers.contains(SkyLayer.figures)) return {};
    final ranked = <(String, double)>[];
    for (final figure in catalogue.art['figures'] as List? ?? []) {
      final ids = (figure['anchors'] as List).cast<int>();
      if (ids.any((i) => i >= frame.artAnchors.length)) continue;
      final centre =
          (frame.artAnchors[ids[0]] +
                  frame.artAnchors[ids[1]] +
                  frame.artAnchors[ids[2]])
              .unit;
      final front = centre.dot(pose.forward);
      if (front > .45) ranked.add((figure['src'] as String, front));
    }
    ranked.sort((a, b) => b.$2.compareTo(a.$2));
    return ranked.take(8).map((e) => e.$1).toSet();
  }

  void _figures(Canvas canvas, Size size, SkyProjection projection) {
    for (final figure in catalogue.art['figures'] as List? ?? []) {
      final image = visuals?.images[figure['src']];
      if (image == null) continue;
      final ids = (figure['anchors'] as List).cast<int>();
      if (ids.any((i) => i >= frame.artAnchors.length)) continue;
      final anchors = [
        for (final i in ids) (catalogue.art['anchors'] as List)[i],
      ];
      final rays = [for (final i in ids) frame.artAnchors[i]];
      final original = (figure['size'] as List).cast<num>();
      final width = original[0].toDouble(), height = original[1].toDouble();
      final positions = <Offset>[], uv = <Offset>[];
      void triangle(List<Offset> source, List<Offset?> target) {
        if (target.any((p) => p == null)) return;
        final a = target[0]!, b = target[1]!, c = target[2]!;
        if ((a - b).distance > size.longestSide * .6 ||
            (a - c).distance > size.longestSide * .6) {
          return;
        }
        if ([a, b, c].every((p) => p.dx < 0) ||
            [a, b, c].every((p) => p.dy < 0) ||
            [a, b, c].every((p) => p.dx > size.width) ||
            [a, b, c].every((p) => p.dy > size.height)) {
          return;
        }
        positions.addAll([a, b, c]);
        uv.addAll(
          source.map(
            (p) => Offset(
              p.dx * image.width / width,
              p.dy * image.height / height,
            ),
          ),
        );
      }

      for (var y = 0; y < 8; y++) {
        for (var x = 0; x < 8; x++) {
          final p = [
            Offset(x * width / 8, y * height / 8),
            Offset((x + 1) * width / 8, y * height / 8),
            Offset((x + 1) * width / 8, (y + 1) * height / 8),
            Offset(x * width / 8, (y + 1) * height / 8),
          ];
          final q = p.map((p) {
            final xy = projection.project(figureRay(p.dx, p.dy, anchors, rays));
            return xy == null ? null : Offset(xy.$1, xy.$2);
          }).toList();
          triangle([p[0], p[1], p[2]], [q[0], q[1], q[2]]);
          triangle([p[0], p[2], p[3]], [q[0], q[2], q[3]]);
        }
      }
      if (positions.isEmpty) continue;
      final vertices = ui.Vertices(
        ui.VertexMode.triangles,
        positions,
        textureCoordinates: uv,
      );
      canvas.drawVertices(
        vertices,
        BlendMode.modulate,
        Paint()
          ..color = const Color(0x44FFFFFF)
          ..shader = ui.ImageShader(
            image,
            TileMode.clamp,
            TileMode.clamp,
            Matrix4.identity().storage,
          ),
      );
      vertices.dispose();
    }
  }

  // Original schematic ISS glyph, not a copied competitor symbol.
  void _station(Canvas canvas, Offset centre, double scale) {
    canvas.save();
    canvas.translate(centre.dx, centre.dy);
    canvas.scale(scale);
    canvas.rotate(-.45);
    final panel = Paint()..color = const Color(0xFF7B96AD),
        body = Paint()..color = const Color(0xFFF7F1E6);
    canvas.drawRect(const Rect.fromLTWH(-2, -13, 4, 26), body);
    for (final x in [-15.0, 6.0]) {
      for (final y in [-11.0, 3.0]) {
        canvas.drawRect(Rect.fromLTWH(x, y, 9, 9), panel);
        canvas.drawLine(
          Offset(x, y + 4.5),
          Offset(x + 9, y + 4.5),
          Paint()
            ..color = const Color(0xFF3C3F43)
            ..strokeWidth = 1,
        );
      }
    }
    canvas.drawRect(const Rect.fromLTWH(-6, -2, 12, 4), body);
    canvas.restore();
  }

  void _solar(
    Canvas canvas,
    Size size,
    SkyProjection projection,
    SkyPoint point,
    Offset centre,
  ) {
    final image = visuals!.images[point.object.id]!;
    final minimum = switch (point.object.id) {
      'moon' => 26.0,
      'sun' => 29.0,
      'jupiter' => 18.0,
      'saturn' => 12.0,
      'mars' => 12.0,
      _ => 9.0,
    };
    final physical =
        size.shortestSide /
        (2 * math.tan(fov * radians / 2)) *
        math.tan(point.radius * radians);
    final radius =
        math.max(minimum, physical).clamp(1.0, 32.0) *
        (point.object.id == selected
            ? 1 + .23 * Curves.easeOut.transform(selectionProgress)
            : 1);
    // Source photographs are illustrative surfaces, not current resolved views.
    const crops = <String, List<double>>{
      'moon': [82 / 960, 66 / 912, 798 / 960, 798 / 912],
      'sun': [79 / 960, 80 / 960, 808 / 960, 808 / 960],
      'jupiter': [35 / 940, 31 / 940, 875 / 940, 875 / 940],
      'mars': [80 / 960, 70 / 960, 810 / 960, 810 / 960],
      'venus': [0, 9 / 480, 444 / 480, 454 / 480],
    };
    final crop = crops[point.object.id] ?? [0.0, 0.0, 1.0, 1.0];
    final source = Rect.fromLTWH(
      crop[0] * image.width,
      crop[1] * image.height,
      crop[2] * image.width,
      crop[3] * image.height,
    );
    final ring = point.object.id == 'saturn';
    final destination = Rect.fromCenter(
      center: centre,
      width: radius * (ring ? 4.6 : 2),
      height: radius * 2,
    );
    canvas.save();
    if (!ring) {
      canvas.clipPath(
        Path()..addOval(Rect.fromCircle(center: centre, radius: radius)),
      );
    }
    canvas.drawImageRect(
      image,
      source,
      destination,
      Paint()
        ..filterQuality = FilterQuality.medium
        ..blendMode = ring ? BlendMode.screen : BlendMode.srcOver,
    );
    if (point.object.id != 'sun' && !ring) {
      // Geocentric illuminated fraction; bright limb points toward the Sun in
      // this same observer/view basis. Archive texture orientation is illustrative.
      final sun = frame.points['sun']!.vector;
      final tangent = sun + point.vector * (-sun.dot(point.vector));
      final angle = math.atan2(-tangent.dot(pose.up), tangent.dot(pose.right));
      canvas.translate(centre.dx, centre.dy);
      canvas.rotate(angle);
      canvas.clipPath(illuminatedDisc(radius, point.phase), doAntiAlias: true);
      canvas.drawColor(const Color(0xEE000000), BlendMode.srcOver);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant SkyPainter old) => true;
}

class CompassRose extends StatelessWidget {
  const CompassRose({
    super.key,
    required this.azimuth,
    required this.cardinals,
    required this.label,
  });
  final double azimuth;
  final List<String> cardinals;
  final String label;
  @override
  Widget build(BuildContext context) => Semantics(
    label: label,
    child: SizedBox(
      width: 94,
      height: 94,
      child: CustomPaint(painter: _RosePainter(azimuth, cardinals)),
    ),
  );
}

class _RosePainter extends CustomPainter {
  _RosePainter(this.az, this.labels);
  final double az;
  final List<String> labels;
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    canvas.drawCircle(c, 31, Paint()..color = const Color(0x55000000));
    canvas.drawCircle(
      c,
      31,
      Paint()
        ..color = const Color(0x779EA1A6)
        ..style = PaintingStyle.stroke,
    );
    for (var i = 0; i < 4; i++) {
      final a = (i * 90 - az) * radians;
      final tip = c + Offset(math.sin(a) * 28, -math.cos(a) * 28);
      final side = Offset(math.cos(a) * 5, math.sin(a) * 5);
      canvas.drawPath(
        Path()
          ..moveTo(tip.dx, tip.dy)
          ..lineTo(c.dx + side.dx, c.dy + side.dy)
          ..lineTo(c.dx - side.dx, c.dy - side.dy)
          ..close(),
        Paint()
          ..color = i == 0 ? const Color(0xFFBF5265) : const Color(0xFF9EA1A6),
      );
      final p = c + Offset(math.sin(a) * 39, -math.cos(a) * 39);
      final t = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: const TextStyle(fontSize: 10, color: Color(0xFFF7F1E6)),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      t.paint(canvas, p - Offset(t.width / 2, t.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant _RosePainter old) =>
      az != old.az || labels != old.labels;
}

/// Shadow mask = disc minus illuminated side. Fractions 0/0.5/1 are new/quarter/full.
Path illuminatedDisc(double radius, double fraction) {
  final k = 2 * fraction.clamp(0.0, 1.0) - 1;
  final lit = Path();
  for (var i = 0; i <= 64; i++) {
    final y = -radius + 2 * radius * i / 64;
    final edge = math.sqrt(math.max(0, radius * radius - y * y));
    final x = -k * edge;
    if (i == 0) {
      lit.moveTo(x, y);
    } else {
      lit.lineTo(x, y);
    }
  }
  for (var i = 64; i >= 0; i--) {
    final y = -radius + 2 * radius * i / 64;
    lit.lineTo(math.sqrt(math.max(0, radius * radius - y * y)), y);
  }
  lit.close();
  return Path.combine(
    PathOperation.difference,
    Path()..addOval(Rect.fromCircle(center: Offset.zero, radius: radius)),
    lit,
  );
}
