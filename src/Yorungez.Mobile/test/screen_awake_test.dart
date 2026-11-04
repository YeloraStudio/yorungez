import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yorungez/sky/data/screen_awake.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('yorungez/screen-test');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test(
    'a delayed activation is followed by release on disposal without late reactivation',
    () async {
      final loading = Completer<void>(), enabled = Completer<void>();
      final calls = <bool>[];
      messenger.setMockMethodCallHandler(channel, (call) async {
        expect(call.method, 'setEnabled');
        calls.add(call.arguments as bool);
        if (call.arguments == true) {
          enabled.complete();
          await loading.future;
        }
        return null;
      });
      final screen = ScreenAwake(channel: channel);
      final activation = screen.setActive(true);
      await enabled.future;
      final closing = screen.close();
      final ignored = screen.setActive(true);
      loading.complete();
      await Future.wait([activation, closing, ignored]);
      expect(calls, [true, false]);
      await screen.close();
      expect(calls, [true, false]);
    },
  );

  test(
    'foreground changes serialize correctly and a platform failure does not block release',
    () async {
      final calls = <bool>[];
      messenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call.arguments as bool);
        if (calls.length == 1) throw PlatformException(code: 'synthetic');
        return null;
      });
      final screen = ScreenAwake(channel: channel);
      await screen.setActive(true);
      await screen.setActive(false);
      await screen.setActive(false);
      await screen.setActive(true);
      await screen.close();
      expect(calls, [true, false, true, false]);
    },
  );
}
