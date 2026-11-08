import 'dart:typed_data';

enum ObservingEquipment { nakedEye, binoculars }

const guideTargets = ['moon', 'jupiter', 'saturn', 'dso-mel022', 'dso-ngc1976'];

bool needsDarkSky(String targetId) => targetId == 'dso-ngc1976';

bool suitedTo(String targetId, ObservingEquipment equipment) =>
    equipment == ObservingEquipment.binoculars || !needsDarkSky(targetId);

typedef GuideDirection = ({double azimuth, double altitude});
typedef GuideSample = ({double solarAltitude, List<GuideDirection> targets});

final class ObservationSlot {
  const ObservationSlot(this.start, this.end, this.best, this.direction);

  final DateTime start, end, best;
  final GuideDirection direction;
}

Map<String, ObservationSlot> recommendObservations(
  DateTime start,
  DateTime end,
  GuideSample Function(DateTime) sample,
) {
  final results = <String, ObservationSlot>{};
  final starts = List<DateTime?>.filled(guideTargets.length, null);
  final peaks = List<(DateTime, GuideDirection)?>.filled(
    guideTargets.length,
    null,
  );
  void finish(int index, DateTime last) {
    final first = starts[index];
    final peak = peaks[index];
    if (first != null && peak != null && last.isAfter(first)) {
      final id = guideTargets[index];
      final previous = results[id];
      if (previous == null || previous.direction.altitude < peak.$2.altitude) {
        results[id] = ObservationSlot(first, last, peak.$1, peak.$2);
      }
    }
    starts[index] = null;
    peaks[index] = null;
  }

  const step = Duration(minutes: 10);
  var previous = start;
  for (var time = start; !time.isAfter(end); time = time.add(step)) {
    final sky = sample(time);
    for (var i = 0; i < guideTargets.length; i++) {
      final target = sky.targets[i];
      final faint = needsDarkSky(guideTargets[i]);
      final suitable =
          target.altitude >= (faint ? 15 : 5) &&
          sky.solarAltitude <= (faint ? -18 : -6);
      if (suitable) {
        starts[i] ??= time;
        if (peaks[i] == null || target.altitude > peaks[i]!.$2.altitude) {
          peaks[i] = (time, target);
        }
      } else {
        finish(i, previous);
      }
    }
    previous = time;
  }
  for (var i = 0; i < guideTargets.length; i++) {
    finish(i, previous);
  }
  return results;
}

Float64List encodeObservations(Map<String, ObservationSlot> slots) =>
    Float64List.fromList([
      for (var i = 0; i < guideTargets.length; i++)
        if (slots[guideTargets[i]] case final slot?) ...[
          i.toDouble(),
          slot.start.millisecondsSinceEpoch.toDouble(),
          slot.end.millisecondsSinceEpoch.toDouble(),
          slot.best.millisecondsSinceEpoch.toDouble(),
          slot.direction.azimuth,
          slot.direction.altitude,
        ],
    ]);

Map<String, ObservationSlot> decodeObservations(Float64List raw) {
  if (raw.length % 6 != 0 || raw.any((v) => !v.isFinite)) {
    throw const FormatException('Invalid observing guide output');
  }
  DateTime time(int i) =>
      DateTime.fromMillisecondsSinceEpoch(raw[i].round(), isUtc: true);
  return {
    for (var i = 0; i < raw.length; i += 6)
      guideTargets[raw[i].toInt()]: ObservationSlot(
        time(i + 1),
        time(i + 2),
        time(i + 3),
        (azimuth: raw[i + 4], altitude: raw[i + 5]),
      ),
  };
}

int compassSector(double azimuth) =>
    (((azimuth % 360) + 22.5) / 45).floor() % 8;
