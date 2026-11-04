import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';

import '../../catalogue/data/catalogue_repository.dart';
import '../domain/sky_geometry.dart';
import 'native_satellite.dart';
import 'native_magnetic.dart';
import '../../catalogue/domain/sky_object.dart';

const solarIds = [
  'sun',
  'moon',
  'mercury',
  'venus',
  'mars',
  'jupiter',
  'saturn',
  'uranus',
  'neptune',
];
typedef _CalculateNative =
    Int32 Function(
      Double,
      Double,
      Double,
      Double,
      Pointer<Double>,
      Int32,
      Pointer<Double>,
      Int32,
      Pointer<Double>,
      Int32,
    );
typedef _Calculate =
    int Function(
      double,
      double,
      double,
      double,
      Pointer<Double>,
      int,
      Pointer<Double>,
      int,
      Pointer<Double>,
      int,
    );

final class NativeSky {
  NativeSky() {
    final lib = Platform.isIOS
        ? DynamicLibrary.process()
        : DynamicLibrary.open(
            Platform.isAndroid
                ? 'libyorungez_sky.so'
                : Platform.environment['YORUNGEZ_SKY_LIBRARY'] ??
                      '${Directory.current.path}/../../.local/mobile-science/${Platform.isWindows ? 'yorungez_sky.dll' : 'libyorungez_sky.so'}',
          );
    if (lib.lookupFunction<Int32 Function(), int Function()>(
          'yg_abi_version',
        )() !=
        2) {
      throw const FormatException('Unsupported calculation ABI');
    }
    _calculate = lib.lookupFunction<_CalculateNative, _Calculate>('yg_sky');
  }
  late final _Calculate _calculate;
  Float64List calculate(
    SkyObserver observer,
    DateTime instant,
    List<double> stars,
    List<double> dsos,
  ) {
    if (stars.length % 6 != 0 || dsos.length % 2 != 0) {
      throw const FormatException('Invalid scientific input layout');
    }
    if (instant.toUtc().year < 2000 || instant.toUtc().year >= 2036) {
      throw const FormatException('Unsupported calculation date');
    }
    final s = calloc<Double>(stars.isEmpty ? 1 : stars.length);
    final d = calloc<Double>(dsos.isEmpty ? 1 : dsos.length);
    final length = 81 + stars.length ~/ 3 + dsos.length;
    final out = calloc<Double>(length);
    try {
      s.asTypedList(stars.length).setAll(0, stars);
      d.asTypedList(dsos.length).setAll(0, dsos);
      final status = _calculate(
        instant.millisecondsSinceEpoch / 1000,
        observer.latitude,
        observer.longitude,
        observer.elevation,
        s,
        stars.length ~/ 6,
        d,
        dsos.length ~/ 2,
        out,
        length,
      );
      if (status != 0) throw const FormatException('Native calculation failed');
      return Float64List.fromList(out.asTypedList(length));
    } finally {
      calloc.free(s);
      calloc.free(d);
      calloc.free(out);
    }
  }
}

// One serial native worker, bounded to one frame and one selected trajectory.
// Frames and paths use the same mutable native engine, never concurrent FFI.
final class SkyWorker {
  SkyWorker._(this._isolate, this._messages, this._commands);
  final Isolate _isolate;
  final ReceivePort _messages;
  final SendPort _commands;
  final _queue = <(Object, Completer<Float64List>)>[];
  (Object, Completer<Float64List>)? _pending;
  StreamSubscription<dynamic>? _subscription;
  bool _closed = false, _frameOutstanding = false, _trackOutstanding = false;
  static Future<SkyWorker> start(Catalogue catalogue) async {
    final messages = ReceivePort(), ready = Completer<SendPort>();
    SkyWorker? worker;
    final subscription = messages.listen((message) {
      if (message is SendPort) {
        ready.complete(message);
        return;
      }
      final current = worker?._pending;
      worker?._pending = null;
      if (current == null) return;
      if (message is Float64List) {
        current.$2.complete(message);
      } else {
        current.$2.completeError(
          const FormatException('Calculation unavailable'),
        );
      }
      worker?._pump();
    });
    final ids = [
      ...solarIds,
      ...catalogue.objects
          .where((o) => o.kind == ObjectKind.star)
          .map((o) => o.id),
      ...catalogue.objects
          .where((o) => o.kind == ObjectKind.deepSky)
          .map((o) => o.id),
    ];
    final isolate = await Isolate.spawn(_runWorker, (
      messages.sendPort,
      catalogue.starInput,
      catalogue.dsoInput,
      {for (var i = 0; i < ids.length; i++) ids[i]: i},
      catalogue.objects.where((o) => o.kind == ObjectKind.star).length,
    ));
    try {
      final commands = await ready.future.timeout(const Duration(seconds: 8));
      worker = SkyWorker._(isolate, messages, commands)
        .._subscription = subscription;
      return worker;
    } catch (_) {
      isolate.kill();
      await subscription.cancel();
      messages.close();
      rethrow;
    }
  }

  void _pump() {
    if (_closed || _pending != null || _queue.isEmpty) return;
    _pending = _queue.removeAt(0);
    _commands.send(_pending!.$1);
  }

  Future<Float64List> _enqueue(Object message) {
    if (_closed) throw StateError('Calculation worker closed');
    final result = Completer<Float64List>();
    _queue.add((message, result));
    _pump();
    return result.future.timeout(const Duration(seconds: 8));
  }

  Future<Float64List> calculate(
    SkyObserver observer,
    DateTime instant, {
    List<double> iss = const [],
  }) {
    if (_closed || _frameOutstanding) {
      throw StateError('Frame busy or worker closed');
    }
    _frameOutstanding = true;
    return _enqueue((
      'frame',
      observer,
      instant,
      '',
      iss,
    )).whenComplete(() => _frameOutstanding = false);
  }

  Future<Float64List> trajectory(
    SkyObserver observer,
    DateTime instant,
    String id, {
    List<double> iss = const [],
  }) {
    if (_closed || _trackOutstanding) {
      throw StateError('Trajectory busy or worker closed');
    }
    _trackOutstanding = true;
    return _enqueue((
      'track',
      observer,
      instant,
      id,
      iss,
    )).whenComplete(() => _trackOutstanding = false);
  }

  void close() {
    if (_closed) return;
    _closed = true;
    _isolate.kill();
    unawaited(_subscription?.cancel());
    _messages.close();
    for (final job in [?_pending, ..._queue]) {
      job.$2.completeError(StateError('Calculation worker closed'));
    }
    _pending = null;
    _queue.clear();
  }
}

void _runWorker(
  (SendPort, List<double>, List<double>, Map<String, int>, int) input,
) {
  final port = ReceivePort();
  input.$1.send(port.sendPort);
  NativeSky? engine;
  NativeSatellite? satellite;
  NativeMagnetic? magnetic;
  SkyObserver? magneticObserver;
  DateTime? magneticTime;
  List<double> correction = const [0, 180, 0];
  port.listen((message) {
    try {
      final request =
          message as (String, SkyObserver, DateTime, String, List<double>);
      engine ??= NativeSky();
      if (request.$1 == 'frame') {
        final raw = engine!.calculate(
          request.$2,
          request.$3,
          input.$2,
          input.$3,
        );
        if ((magneticObserver?.latitude != request.$2.latitude ||
                magneticObserver?.longitude != request.$2.longitude ||
                magneticObserver?.elevation != request.$2.elevation) ||
            magneticTime == null ||
            request.$3.difference(magneticTime!).abs() >
                const Duration(hours: 1)) {
          try {
            magnetic ??= NativeMagnetic();
            correction = magnetic!.calculate(request.$2, request.$3);
          } catch (_) {
            correction = const [0, 180, 0];
          }
          magneticObserver = request.$2;
          magneticTime = request.$3;
        }
        var station = <double>[];
        if (request.$5.isNotEmpty) {
          try {
            satellite ??= NativeSatellite();
            station = satellite!.calculate(request.$5, request.$2, request.$3);
          } catch (_) {
            /* Keep general sky available. */
          }
        }
        input.$1.send(
          Float64List.fromList([...raw, ...station, ...correction]),
        );
      } else if (request.$4 == 'sat-25544') {
        if (request.$5.length != 10) {
          throw const FormatException('Missing station elements');
        }
        satellite ??= NativeSatellite();
        final result = <double>[];
        for (var seconds = -600; seconds <= 600; seconds += 10) {
          final instant = request.$3.add(Duration(seconds: seconds));
          if (instant.millisecondsSinceEpoch / 1000 >=
              request.$5[0] + 72 * 3600) {
            continue;
          }
          final raw = satellite!.calculate(request.$5, request.$2, instant);
          result.addAll([
            instant.millisecondsSinceEpoch.toDouble(),
            raw[6],
            raw[7],
          ]);
        }
        input.$1.send(Float64List.fromList(result));
      } else {
        final index = input.$4[request.$4];
        if (index == null) throw const FormatException('Untrackable identity');
        final stars = index >= 9 && index < 9 + input.$5
            ? input.$2.sublist((index - 9) * 6, (index - 9) * 6 + 6)
            : <double>[];
        final dsos = index >= 9 + input.$5
            ? input.$3.sublist(
                (index - 9 - input.$5) * 2,
                (index - 9 - input.$5) * 2 + 2,
              )
            : <double>[];
        final offset = index < 9 ? index * 8 : 72;
        final result = <double>[];
        for (var minutes = -360; minutes <= 360; minutes += 10) {
          final instant = request.$3.add(Duration(minutes: minutes));
          if (instant.year < 2000 || instant.year >= 2036) continue;
          final raw = engine!.calculate(request.$2, instant, stars, dsos);
          result.addAll([
            instant.millisecondsSinceEpoch.toDouble(),
            raw[offset],
            raw[offset + 1],
          ]);
        }
        input.$1.send(Float64List.fromList(result));
      }
    } catch (_) {
      input.$1.send(false);
    }
  });
}
