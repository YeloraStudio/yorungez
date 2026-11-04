import 'package:flutter/services.dart';

/// A foreground screen lease, not a background CPU wake lock.
/// Serial calls ensure a delayed enable cannot overtake pause/disposal.
final class ScreenAwake {
  ScreenAwake({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('yorungez/screen');
  final MethodChannel _channel;
  Future<void> _pending = Future<void>.value();
  bool? _requested;
  bool _closed = false;

  Future<void> setActive(bool enabled) {
    if (_closed || _requested == enabled) return _pending;
    _requested = enabled;
    _pending = _pending.then((_) async {
      try {
        await _channel.invokeMethod<void>('setEnabled', enabled);
      } on PlatformException {
        // An unavailable platform adapter must not prevent sky exploration.
      } on MissingPluginException {
        // Host widget tests do not run Android/iOS platform adapters.
      }
    });
    return _pending;
  }

  Future<void> close() {
    if (!_closed) {
      setActive(false);
      _closed = true;
    }
    return _pending;
  }
}
