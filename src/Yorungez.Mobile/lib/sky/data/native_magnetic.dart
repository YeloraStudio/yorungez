import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import '../domain/sky_geometry.dart';

typedef _Native =
    Int32 Function(Double, Double, Double, Double, Pointer<Double>);
typedef _Call = int Function(double, double, double, double, Pointer<Double>);

final class NativeMagnetic {
  NativeMagnetic() {
    final lib = Platform.isIOS
        ? DynamicLibrary.process()
        : DynamicLibrary.open(
            Platform.isAndroid
                ? 'libyorungez_magnetic.so'
                : Platform.environment['YORUNGEZ_MAGNETIC_LIBRARY'] ??
                      '${Directory.current.path}/../../.local/mobile-science/${Platform.isWindows ? 'yorungez_magnetic.dll' : 'libyorungez_magnetic.so'}',
          );
    if (lib.lookupFunction<Int32 Function(), int Function()>(
          'yg_magnetic_abi',
        )() !=
        1) {
      throw const FormatException('Unsupported magnetic ABI');
    }
    _call = lib.lookupFunction<_Native, _Call>('yg_magnetic');
  }
  late final _Call _call;
  List<double> calculate(SkyObserver observer, DateTime instant) {
    final utc = instant.toUtc(), out = calloc<Double>(3);
    final start = DateTime.utc(utc.year), end = DateTime.utc(utc.year + 1);
    final year =
        utc.year +
        utc.difference(start).inMicroseconds /
            end.difference(start).inMicroseconds;
    try {
      if (_call(
            year,
            observer.latitude,
            observer.longitude,
            observer.elevation / 1000,
            out,
          ) !=
          0) {
        return const [0, 180, 0];
      }
      return List<double>.from(out.asTypedList(3));
    } finally {
      calloc.free(out);
    }
  }
}
