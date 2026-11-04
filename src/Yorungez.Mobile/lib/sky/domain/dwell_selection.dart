/// Monotonic, stable-identity dwell. Sensor samples do not create timers.
final class DwellSelection {
  DwellSelection({this.duration = const Duration(seconds: 1)});
  final Duration duration;
  String? _candidate;
  Duration? _since, _last;
  bool _fired = false;
  String? get candidate => _candidate;
  double progress(Duration at) => _since == null
      ? 0
      : ((at - _since!).inMicroseconds / duration.inMicroseconds).clamp(
          0.0,
          1.0,
        );
  String? update(String? candidate, Duration at) {
    if (_last != null && at < _last!) {
      reset();
    }
    _last = at;
    if (candidate != _candidate) {
      _candidate = candidate;
      _since = candidate == null ? null : at;
      _fired = false;
    }
    if (candidate == null ||
        _since == null ||
        _fired ||
        at - _since! < duration) {
      return null;
    }
    _fired = true;
    return candidate;
  }

  void reset() {
    _candidate = null;
    _since = null;
    _last = null;
    _fired = false;
  }
}
