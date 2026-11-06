import 'dart:async';
import 'package:flutter/services.dart';
import 'mobile_services.dart';

enum PoseFailure { unsupported, unavailable, noData }

/// A missing physical capability is distinct from a denied/interrupted stream.
/// Only finite, fresh, ordered samples keep the watchdog alive. No pose is stored.
final class NativePoseSource {
  NativePoseSource({
    Future<bool> Function()? probe,
    Stream<dynamic> Function()? events,
    this.probeTimeout = const Duration(seconds: 3),
    this.sampleTimeout = const Duration(seconds: 8),
    DateTime Function()? now,
  }) : _probe = probe ?? _nativeSupport,
       _events = events ?? nativePoseChannel.receiveBroadcastStream,
       _now = now ?? DateTime.now;

  final Future<bool> Function() _probe;
  final Stream<dynamic> Function() _events;
  final DateTime Function() _now;
  final Duration probeTimeout, sampleTimeout;

  static Future<bool> _nativeSupport() async {
    const channel = MethodChannel('yorungez/pose-capabilities');
    final value = await channel.invokeMapMethod<String, dynamic>('get');
    if (value?['supported'] is! bool) {
      throw const FormatException('Invalid pose capability response');
    }
    return value!['supported'] as bool;
  }

  Stream<PoseSample> samples() {
    late final StreamController<PoseSample> output;
    StreamSubscription<dynamic>? subscription;
    Timer? watchdog;
    var stopped = false;
    double? lastTimestamp;

    Future<void> cancelNative() async {
      try {
        await subscription?.cancel();
      } on Object {
        // An unavailable platform may also reject cleanup. Never retain pose
        // or crash the fallback UI because a cancellation acknowledgement fails.
      }
    }

    void fail(PoseFailure reason) {
      if (stopped) return;
      stopped = true;
      watchdog?.cancel();
      output.addError(reason);
      unawaited(cancelNative());
      unawaited(output.close());
    }

    void armWatchdog() {
      watchdog?.cancel();
      watchdog = Timer(sampleTimeout, () => fail(PoseFailure.noData));
    }

    Future<void> start() async {
      try {
        bool supported;
        try {
          supported = await _probe().timeout(probeTimeout);
        } on MissingPluginException {
          // Older platform hosts may only have the event channel. Their stream
          // remains bounded by the same watchdog; absence never means support.
          supported = true;
        }
        if (stopped) return;
        if (!supported) {
          fail(PoseFailure.unsupported);
          return;
        }
        armWatchdog();
        subscription = _events().listen(
          (event) {
            if (stopped) return;
            try {
              final sample = PoseSample.decode(event);
              if (!sample.fresh(_now()) ||
                  (lastTimestamp != null &&
                      sample.timestampMs <= lastTimestamp!)) {
                return;
              }
              lastTimestamp = sample.timestampMs;
              if (sample.quality > 0) armWatchdog();
              output.add(sample);
            } on Object {
              // Bad/old/unreliable packets cannot postpone failure indefinitely.
            }
          },
          onError: (Object error) => fail(
            error is PlatformException && error.code == 'pose_unsupported'
                ? PoseFailure.unsupported
                : PoseFailure.unavailable,
          ),
          onDone: () => fail(PoseFailure.unavailable),
        );
        if (stopped) await cancelNative();
      } on Object {
        fail(PoseFailure.unavailable);
      }
    }

    output = StreamController<PoseSample>(
      onListen: () => unawaited(start()),
      onCancel: () async {
        stopped = true;
        watchdog?.cancel();
        await cancelNative();
      },
    );
    return output.stream;
  }
}

/// One non-personal notice acknowledgement per installation. Failed optional
/// storage still suppresses repeats within this application session.
final class TrackingNotice {
  TrackingNotice({MobilePreferences? preferences})
    : _preferences = preferences ?? MobilePreferences();
  final MobilePreferences _preferences;
  bool _shown = false, _busy = false;

  /// True means handled (already seen or just displayed); false defers until
  /// the sky is visible. Persist only after actual presentation.
  Future<bool> present({
    required bool Function() canShow,
    required void Function() show,
  }) async {
    if (_shown) return true;
    if (_busy) return false;
    _busy = true;
    try {
      var seen = false;
      try {
        seen = await _preferences.trackingNoticeSeen();
      } on Object {
        // Optional storage must not block capability handling.
      }
      if (seen) {
        _shown = true;
        return true;
      }
      if (!canShow()) return false;
      show();
      _shown = true;
      try {
        await _preferences.markTrackingNoticeSeen();
      } on Object {
        // Still suppress repeats in this session if storage is unavailable.
      }
      return true;
    } finally {
      _busy = false;
    }
  }
}
