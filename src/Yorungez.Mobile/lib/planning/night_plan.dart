import 'dart:typed_data';
import '../sky/domain/sky_geometry.dart';

final class NightInterval {
  const NightInterval(this.start, this.end);
  final DateTime start, end;
}

final class NightRow {
  const NightRow(
    this.id,
    this.intervals,
    this.best,
    this.altitude,
    this.rise,
    this.set,
  );
  final String id;
  final List<NightInterval> intervals;
  final DateTime? best, rise, set;
  final double? altitude;
}

final class NightPlan {
  const NightPlan(
    this.state,
    this.start,
    this.end,
    this.sunset,
    this.sunrise,
    this.rows,
  );
  // ordinary, no-night, polar-night, partial; same semantics as the Web planner.
  final int state;
  final DateTime start, end;
  final DateTime? sunset, sunrise;
  final List<NightRow> rows;
  static const ids = [
    'moon',
    'mercury',
    'venus',
    'mars',
    'jupiter',
    'saturn',
    'uranus',
    'neptune',
  ];
  Float64List encode() {
    double at(DateTime? d) =>
        d?.millisecondsSinceEpoch.toDouble() ?? double.nan;
    return Float64List.fromList([
      state.toDouble(),
      at(start),
      at(end),
      at(sunset),
      at(sunrise),
      for (final r in rows) ...[
        at(r.best),
        r.altitude ?? double.nan,
        at(r.rise),
        at(r.set),
        r.intervals.length.toDouble(),
        for (final i in r.intervals) ...[at(i.start), at(i.end)],
      ],
    ]);
  }

  factory NightPlan.decode(Float64List data) {
    var index = 0;
    double take() => data[index++];
    DateTime? date() {
      final n = take();
      return n.isNaN
          ? null
          : DateTime.fromMillisecondsSinceEpoch(n.round(), isUtc: true);
    }

    final state = take().toInt(),
        start = date()!,
        end = date()!,
        sunset = date(),
        sunrise = date();
    final rows = <NightRow>[];
    for (final id in ids) {
      final best = date(),
          alt = take(),
          rise = date(),
          set = date(),
          count = take().toInt();
      if (count < 0 || count > 8) {
        throw const FormatException('Invalid intervals');
      }
      rows.add(
        NightRow(
          id,
          [for (var i = 0; i < count; i++) NightInterval(date()!, date()!)],
          best,
          alt.isNaN ? null : alt,
          rise,
          set,
        ),
      );
    }
    if (index != data.length || state < 0 || state > 3 || !end.isAfter(start)) {
      throw const FormatException('Invalid plan');
    }
    return NightPlan(state, start, end, sunset, sunrise, rows);
  }
}

typedef Crossings = ({bool above, List<({DateTime time, bool up})> edges});

// Pure interval logic; all ephemeris/rise-set values come from the pinned native solver.
NightPlan calculateNightPlan(
  SkyObserver site,
  DateTime start,
  DateTime end,
  Crossings Function(int) crossings,
  double Function(int, DateTime, bool) altitude,
) {
  List<NightInterval> intervals(Crossings c, bool above) {
    var active = c.above == above, begun = start;
    final out = <NightInterval>[];
    for (final edge in c.edges) {
      final next = edge.up == above;
      if (next && !active) begun = edge.time;
      if (!next && active) out.add(NightInterval(begun, edge.time));
      active = next;
    }
    if (active) out.add(NightInterval(begun, end));
    return out;
  }

  DateTime? edge(Crossings c, bool up) {
    for (final e in c.edges) {
      if (e.up == up) return e.time;
    }
    return null;
  }

  final sun = crossings(0), nights = intervals(sun, false);
  final state = nights.isEmpty
      ? 1
      : sun.edges.isEmpty
      ? 2
      : sun.edges.length < 2
      ? 3
      : 0;
  final rows = <NightRow>[];
  for (var b = 1; b <= 8; b++) {
    final c = crossings(b), visible = <NightInterval>[];
    for (final a in intervals(c, true)) {
      for (final n in nights) {
        final s = a.start.isAfter(n.start) ? a.start : n.start;
        final e = a.end.isBefore(n.end) ? a.end : n.end;
        if (e.isAfter(s)) visible.add(NightInterval(s, e));
      }
    }
    DateTime? best;
    var bestAlt = -double.infinity, bestDark = false;
    for (final v in visible) {
      for (var n = 0; n < 25; n++) {
        final t = v.start.add(
          Duration(
            microseconds:
                (v.end.difference(v.start).inMicroseconds * (n + .5) / 25)
                    .round(),
          ),
        );
        final alt = altitude(b, t, false), dark = altitude(0, t, true) < -6;
        if ((dark && !bestDark) || (dark == bestDark && alt > bestAlt)) {
          best = t;
          bestAlt = alt;
          bestDark = dark;
        }
      }
    }
    rows.add(
      NightRow(
        NightPlan.ids[b - 1],
        visible,
        best,
        best == null ? null : bestAlt,
        edge(c, true),
        edge(c, false),
      ),
    );
  }
  return NightPlan(
    state,
    nights.isEmpty ? start : nights.first.start,
    nights.isEmpty ? end : nights.last.end,
    edge(sun, false),
    edge(sun, true),
    rows,
  );
}
