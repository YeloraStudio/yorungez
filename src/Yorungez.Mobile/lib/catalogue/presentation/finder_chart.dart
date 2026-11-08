import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../data/catalogue_repository.dart';
import '../domain/sky_object.dart';

class FinderChart extends StatefulWidget {
  const FinderChart({super.key, required this.catalogue, required this.object});

  final Catalogue catalogue;
  final SkyObject object;

  @override
  State<FinderChart> createState() => _FinderChartState();
}

class _FinderChartState extends State<FinderChart> {
  late _Chart _chart = _Chart.build(widget.catalogue, widget.object);

  @override
  void didUpdateWidget(FinderChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.catalogue != widget.catalogue ||
        oldWidget.object != widget.object) {
      _chart = _Chart.build(widget.catalogue, widget.object);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final language = Localizations.localeOf(context).languageCode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          image: true,
          label: '${t.finderChart} · ${widget.object.name(language)}',
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: SizedBox(
              width: double.infinity,
              height: 220,
              child: CustomPaint(painter: _ChartPainter(_chart)),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(t.finderChart, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 4),
        Text(t.finderChartNote, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

typedef _Direction = ({double ra, double dec});

class _Chart {
  const _Chart(this.stars, this.lines, this.field, this.markCentre);

  final List<(Offset, double)> stars;
  final List<List<Offset>> lines;
  final double field;
  final bool markCentre;

  static _Chart build(Catalogue catalogue, SkyObject object) {
    const toRadians = math.pi / 180;
    final lines = catalogue.lines[object.id] ?? const <List<String>>[];
    final stars = catalogue.objects.where((o) => o.kind == ObjectKind.star);
    final anchors = lines.expand((line) => line).toSet();
    final directions = <String, _Direction>{};
    for (final star in stars) {
      if (anchors.contains(star.id)) {
        directions[star.id] = (
          ra: star.raHours! * 15 * toRadians,
          dec: star.decDegrees! * toRadians,
        );
      }
    }
    late final _Direction centre;
    if (object.raHours case final double ra) {
      centre = (ra: ra * 15 * toRadians, dec: object.decDegrees! * toRadians);
    } else {
      var x = 0.0, y = 0.0, z = 0.0;
      for (final point in directions.values) {
        x += math.cos(point.dec) * math.cos(point.ra);
        y += math.cos(point.dec) * math.sin(point.ra);
        z += math.sin(point.dec);
      }
      centre = (
        ra: math.atan2(y, x),
        dec: math.atan2(z, math.sqrt(x * x + y * y)),
      );
    }
    final sinDec = math.sin(centre.dec), cosDec = math.cos(centre.dec);
    Offset? project(_Direction point) {
      final delta = point.ra - centre.ra;
      final sin = math.sin(point.dec), cos = math.cos(point.dec);
      final depth = sinDec * sin + cosDec * cos * math.cos(delta);
      if (depth <= 0) return null;
      return Offset(
        -cos * math.sin(delta) / depth,
        -(cosDec * sin - sinDec * cos * math.cos(delta)) / depth,
      );
    }

    final paths = [
      for (final line in lines)
        [
          for (final id in line)
            if (directions[id] case final point?) ?project(point),
        ],
    ];
    final field = paths
        .expand((path) => path)
        .fold<double>(
          math.tan(5 * toRadians),
          (radius, point) => math.max(radius, point.distance * 1.15),
        );
    return _Chart(
      [
        for (final star in stars)
          if (project((
                ra: star.raHours! * 15 * toRadians,
                dec: star.decDegrees! * toRadians,
              ))
              case final point?)
            if (point.distanceSquared <= field * field)
              (point, star.magnitude ?? 6.0),
      ],
      paths,
      field,
      lines.isEmpty,
    );
  }
}

class _ChartPainter extends CustomPainter {
  const _ChartPainter(this.chart);

  final _Chart chart;

  @override
  void paint(Canvas canvas, Size size) {
    final centre = size.center(Offset.zero);
    final scale = (size.shortestSide / 2 - 16) / chart.field;
    Offset screen(Offset point) => centre + point * scale;
    canvas.drawColor(const Color(0xFF101118), BlendMode.src);
    final ink = Paint()..color = const Color(0xFFC9B6A6);
    canvas.drawCircle(
      centre,
      size.shortestSide / 2 - 16,
      Paint()
        ..color = const Color(0xFF3C3F43)
        ..style = PaintingStyle.stroke,
    );
    for (final points in chart.lines) {
      for (var i = 1; i < points.length; i++) {
        canvas.drawLine(screen(points[i - 1]), screen(points[i]), ink);
      }
    }
    for (final (point, magnitude) in chart.stars) {
      canvas.drawCircle(
        screen(point),
        (2.9 - .34 * magnitude).clamp(.6, 3.8),
        ink..color = const Color(0xFFF7F1E6),
      );
    }
    if (chart.markCentre) {
      canvas.drawCircle(
        centre,
        9,
        ink
          ..color = const Color(0xFFDA8190)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4,
      );
    }
  }

  @override
  bool shouldRepaint(_ChartPainter oldDelegate) => oldDelegate.chart != chart;
}
