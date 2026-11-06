import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yorungez/sky/data/mobile_services.dart';
import 'package:yorungez/sky/data/native_pose_source.dart';

void main() {
  final now = DateTime.utc(2026, 11, 6);
  Map<String, Object> packet({int age = 0, int quality = 2}) => {
    'matrix': [1, 0, 0, 0, 0, -1, 0, 1, 0],
    'rotation': 0,
    'reference': 'magnetic',
    'quality': quality,
    'timestampMs': now.millisecondsSinceEpoch - age,
  };

  testWidgets('unsupported capability never registers a sensor listener', (
    tester,
  ) async {
    var subscribed = false, done = false;
    final errors = <Object>[];
    NativePoseSource(
      probe: () async => false,
      events: () {
        subscribed = true;
        return const Stream.empty();
      },
    ).samples().listen(
      (_) => fail('Unexpected pose'),
      onError: errors.add,
      onDone: () => done = true,
    );
    await tester.pump();
    expect(errors, [PoseFailure.unsupported]);
    expect(subscribed, isFalse);
    expect(done, isTrue);
  });

  testWidgets('capability probe timeout is transient and cancellable', (
    tester,
  ) async {
    final probe = Completer<bool>();
    var subscribed = false;
    final errors = <Object>[];
    final source = NativePoseSource(
      probe: () => probe.future,
      events: () {
        subscribed = true;
        return const Stream.empty();
      },
    );
    source.samples().listen((_) {}, onError: errors.add);
    await tester.pump(const Duration(seconds: 3));
    expect(errors, [PoseFailure.unavailable]);
    probe.complete(true);
    await tester.pump();
    expect(subscribed, isFalse);

    final cancelledProbe = Completer<bool>();
    final sub = NativePoseSource(
      probe: () => cancelledProbe.future,
      events: () => throw StateError('Must not register after cancellation'),
    ).samples().listen((_) {}, onError: errors.add);
    await sub.cancel();
    cancelledProbe.complete(true);
    await tester.pump(const Duration(seconds: 9));
    expect(errors, [PoseFailure.unavailable]);
  });

  testWidgets(
    'silent provider stops after eight seconds, cancelling native work',
    (tester) async {
      var cancelled = false;
      final events = StreamController<dynamic>(
        onCancel: () => cancelled = true,
      );
      final errors = <Object>[];
      NativePoseSource(
        probe: () async => true,
        events: () => events.stream,
      ).samples().listen((_) {}, onError: errors.add);
      await tester.pump();
      await tester.pump(const Duration(seconds: 7));
      expect(errors, isEmpty);
      await tester.pump(const Duration(seconds: 1));
      expect(errors, [PoseFailure.noData]);
      expect(cancelled, isTrue);
      unawaited(events.close());
      await tester.pump();
    },
  );

  for (final kind in ['malformed', 'stale', 'duplicate', 'unreliable']) {
    testWidgets('$kind packets cannot prolong a stalled orientation stream', (
      tester,
    ) async {
      final events = StreamController<dynamic>();
      final samples = <PoseSample>[];
      final errors = <Object>[];
      NativePoseSource(
        probe: () async => true,
        events: () => events.stream,
        now: () => now,
      ).samples().listen(samples.add, onError: errors.add);
      await tester.pump();
      events.add(packet());
      await tester.pump();
      expect(samples.single.reference, 'magnetic');
      await tester.pump(const Duration(seconds: 5));
      events.add(switch (kind) {
        'malformed' => {
          'matrix': [double.nan],
        },
        'stale' => packet(age: 3000),
        'duplicate' => packet(),
        _ => packet(age: -1, quality: 0),
      });
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));
      expect(errors, [PoseFailure.noData]);
      expect(samples.length, kind == 'unreliable' ? 2 : 1);
      unawaited(events.close());
      await tester.pump();
    });
  }

  testWidgets('native cleanup failure cannot crash the manual fallback', (
    tester,
  ) async {
    final events = StreamController<dynamic>(
      onCancel: () async {
        throw PlatformException(code: 'pose_unavailable');
      },
    );
    final errors = <Object>[];
    NativePoseSource(
      probe: () async => true,
      events: () => events.stream,
    ).samples().listen((_) {}, onError: errors.add);
    await tester.pump();
    await tester.pump(const Duration(seconds: 8));
    expect(errors, [PoseFailure.noData]);
    expect(tester.takeException(), isNull);
    unawaited(events.close());
    await tester.pump();
  });

  testWidgets('fresh ordered samples keep tracking alive, stop releases it', (
    tester,
  ) async {
    final events = StreamController<dynamic>();
    final samples = <PoseSample>[], errors = <Object>[];
    final sub = NativePoseSource(
      probe: () async => true,
      events: () => events.stream,
      now: () => now,
    ).samples().listen(samples.add, onError: errors.add);
    await tester.pump();
    events.add(packet());
    await tester.pump();
    await tester.pump(const Duration(seconds: 6));
    events.add(packet(age: -1));
    await tester.pump();
    await tester.pump(const Duration(seconds: 6));
    expect(errors, isEmpty);
    expect(samples.length, 2);
    unawaited(sub.cancel());
    await tester.pump();
    await tester.pump(const Duration(seconds: 9));
    expect(errors, isEmpty);
    unawaited(events.close());
    await tester.pump();
  });

  for (final kind in ['unsupported', 'permission', 'closed']) {
    testWidgets(
      'stream $kind maps to the correct failure without retry loops',
      (tester) async {
        final events = StreamController<dynamic>();
        final errors = <Object>[];
        NativePoseSource(
          probe: () async => true,
          events: () => events.stream,
        ).samples().listen((_) {}, onError: errors.add);
        await tester.pump();
        if (kind == 'closed') {
          unawaited(events.close());
        } else {
          events.addError(
            PlatformException(
              code: kind == 'unsupported'
                  ? 'pose_unsupported'
                  : 'pose_unavailable',
            ),
          );
        }
        await tester.pump(const Duration(seconds: 9));
        expect(errors, [
          kind == 'unsupported'
              ? PoseFailure.unsupported
              : PoseFailure.unavailable,
        ]);
        unawaited(events.close());
        await tester.pump();
      },
    );
  }

  test(
    'notice persists only a UI acknowledgement and survives app restart',
    () async {
      SharedPreferences.setMockInitialValues({});
      var presentations = 0;
      final notice = TrackingNotice();
      Future<bool> present(TrackingNotice target) =>
          target.present(canShow: () => true, show: () => presentations++);
      await Future.wait([present(notice), present(notice)]);
      await present(notice);
      await present(TrackingNotice());
      expect(presentations, 1);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getKeys(), {'sky.trackingNoticeVersion'});
      expect(prefs.getInt('sky.trackingNoticeVersion'), 1);
    },
  );

  test('hidden sky does not consume its one-time notice', () async {
    SharedPreferences.setMockInitialValues({});
    final notice = TrackingNotice();
    var presentations = 0;
    expect(
      await notice.present(canShow: () => false, show: () => presentations++),
      isFalse,
    );
    expect((await SharedPreferences.getInstance()).getKeys(), isEmpty);
    expect(
      await notice.present(canShow: () => true, show: () => presentations++),
      isTrue,
    );
    expect(presentations, 1);
  });
}
