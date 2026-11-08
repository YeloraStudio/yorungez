import 'night_plan.dart';

/// Refines a change in a sampled predicate to one second. The caller chooses
/// the cadence and must describe what its visibility predicate represents.
List<NightInterval> observingIntervals(
  DateTime start,
  DateTime end,
  Duration step,
  bool Function(DateTime) visible,
) {
  if (!start.isBefore(end)) return const [];
  final result = <NightInterval>[];
  var previous = start;
  var active = visible(start);
  DateTime? began = active ? start : null;
  while (previous.isBefore(end)) {
    final next = earlier(previous.add(step), end);
    final nextActive = visible(next);
    if (active != nextActive) {
      var lo = previous, hi = next;
      while (hi.difference(lo) > const Duration(seconds: 1)) {
        final mid = lo.add(
          Duration(milliseconds: hi.difference(lo).inMilliseconds ~/ 2),
        );
        if (visible(mid) == active) {
          lo = mid;
        } else {
          hi = mid;
        }
      }
      if (nextActive) {
        began = hi;
      } else if (lo.isAfter(began!)) {
        result.add(NightInterval(began, lo));
      }
      active = nextActive;
    }
    previous = next;
  }
  if (active && end.isAfter(began!)) result.add(NightInterval(began, end));
  return result;
}

DateTime earlier(DateTime a, DateTime b) => a.isBefore(b) ? a : b;
DateTime later(DateTime a, DateTime b) => a.isAfter(b) ? a : b;
