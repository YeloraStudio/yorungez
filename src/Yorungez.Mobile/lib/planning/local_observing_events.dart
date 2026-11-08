import 'dart:typed_data';

import 'observing_intervals.dart';

enum LocalEventKind {
  penumbralLunar,
  partialLunar,
  totalLunar,
  partialSolar,
  annularSolar,
  totalSolar,
  geminids,
  quadrantids,
  perseids,
}

typedef EclipseContacts = ({
  LocalEventKind kind,
  DateTime start,
  DateTime peak,
  DateTime end,
  DateTime? centralStart,
  DateTime? centralEnd,
});

final class LocalObservingEvent {
  const LocalObservingEvent({
    required this.kind,
    required this.start,
    required this.end,
    required this.suggested,
    this.moonlight = false,
  });

  final LocalEventKind kind;
  final DateTime start, end, suggested;
  final bool moonlight;
  bool get solar => kind.index >= 3 && kind.index <= 5;
  bool get meteor => kind.index >= 6;
}

const _geminids = (LocalEventKind.geminids, 112.0, 33.0);
const _quadrantids = (LocalEventKind.quadrantids, 230.0, 49.0);
const _perseids = (LocalEventKind.perseids, 48.0, 58.0);

// IMO annual calendars, table 5 and the individual shower notes. These are
// reported maxima near which we look for local observing time, not detections.
final _meteorPeaks = [
  (DateTime.utc(2026, 12, 14, 14), _geminids),
  (DateTime.utc(2027, 1, 4, 3, 25), _quadrantids),
  (DateTime.utc(2027, 8, 13, 9), _perseids),
  (DateTime.utc(2027, 12, 14, 20), _geminids),
];

List<LocalObservingEvent> localObservingEvents(
  DateTime start,
  DateTime end,
  List<EclipseContacts> eclipses,
  List<double> Function(DateTime, List<double>) sky,
) {
  final result = <LocalObservingEvent>[];
  for (final eclipse in eclipses) {
    final solar = eclipse.kind.index >= 3;
    final windows = observingIntervals(
      later(start, eclipse.start),
      earlier(end, eclipse.end),
      const Duration(minutes: 1),
      (time) => sky(time, const [])[solar ? 1 : 9] > 0,
    );
    for (final window in windows) {
      var kind = eclipse.kind;
      var from = window.start, to = window.end;
      if (eclipse.centralStart case final centralStart?) {
        final localStart = later(from, centralStart);
        final localEnd = earlier(to, eclipse.centralEnd!);
        if (localStart.isBefore(localEnd)) {
          from = localStart;
          to = localEnd;
        } else {
          kind = solar
              ? LocalEventKind.partialSolar
              : LocalEventKind.partialLunar;
        }
      }
      result.add(
        LocalObservingEvent(
          kind: kind,
          start: window.start,
          end: window.end,
          suggested: later(from, earlier(eclipse.peak, to)),
        ),
      );
    }
  }
  for (final (peak, (kind, raDegrees, dec)) in _meteorPeaks) {
    const nearPeak = Duration(hours: 18);
    final from = later(start, peak.subtract(nearPeak));
    final to = earlier(end, peak.add(nearPeak));
    if (!from.isBefore(to)) continue;
    final positions = [raDegrees / 15, dec];
    final cache = <DateTime, List<double>>{};
    List<double> sample(DateTime t) =>
        cache.putIfAbsent(t, () => sky(t, positions));
    final windows = observingIntervals(
      from,
      to,
      const Duration(minutes: 10),
      (time) => sample(time)[1] <= -18 && sample(time)[73] >= 15,
    );
    LocalObservingEvent? best;
    double score = double.negativeInfinity;
    for (final window in windows) {
      for (
        var t = window.start;
        !t.isAfter(window.end);
        t = t.add(const Duration(minutes: 10))
      ) {
        final raw = sample(t);
        final moon = raw[9] > 0 ? raw[15] : 0.0;
        final merit =
            raw[73] - 70 * moon - t.difference(peak).abs().inMinutes / 60;
        if (merit <= score) continue;
        score = merit;
        best = LocalObservingEvent(
          kind: kind,
          start: window.start,
          end: window.end,
          suggested: t,
          moonlight: raw[9] > 0 && raw[15] >= .5,
        );
      }
    }
    if (best != null) result.add(best);
  }
  return result..sort((a, b) => a.start.compareTo(b.start));
}

Float64List encodeLocalEvents(List<LocalObservingEvent> events) =>
    Float64List.fromList([
      for (final event in events) ...[
        event.kind.index.toDouble(),
        event.start.millisecondsSinceEpoch.toDouble(),
        event.end.millisecondsSinceEpoch.toDouble(),
        event.suggested.millisecondsSinceEpoch.toDouble(),
        event.moonlight ? 1 : 0,
      ],
    ]);

List<LocalObservingEvent> decodeLocalEvents(Float64List raw) {
  if (raw.length % 5 != 0 || raw.any((value) => !value.isFinite)) {
    throw const FormatException('Invalid local events');
  }
  DateTime at(int i) =>
      DateTime.fromMillisecondsSinceEpoch(raw[i].round(), isUtc: true);
  return [
    for (var i = 0; i < raw.length; i += 5)
      LocalObservingEvent(
        kind: LocalEventKind.values[raw[i].toInt()],
        start: at(i + 1),
        end: at(i + 2),
        suggested: at(i + 3),
        moonlight: raw[i + 4] == 1,
      ),
  ];
}
