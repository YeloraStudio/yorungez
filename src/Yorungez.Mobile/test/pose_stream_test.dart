import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yorungez/sky/data/mobile_services.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('unavailable motion reaches the stream error handler', () async {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    const channel = MethodChannel('yorungez/pose');
    final error = Completer<PlatformException>();
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'listen') {
        // iOS must emit this on the event sink and acknowledge listen normally.
        await messenger.handlePlatformMessage(
          channel.name,
          const StandardMethodCodec().encodeErrorEnvelope(
            code: 'pose_unavailable',
            message: 'Device motion unavailable',
          ),
          (_) {},
        );
      }
      return null;
    });
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
    final subscription = nativePoseChannel.receiveBroadcastStream().listen(
      (_) => fail('Unavailable hardware must not emit a pose'),
      onError: (Object value) => error.complete(value as PlatformException),
    );
    addTearDown(subscription.cancel);
    expect((await error.future).code, 'pose_unavailable');
  });
}
