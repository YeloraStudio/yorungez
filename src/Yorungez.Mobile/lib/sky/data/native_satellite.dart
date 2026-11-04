import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';
import '../domain/sky_geometry.dart';

typedef _Native =
    Int32 Function(
      Pointer<Double>,
      Double,
      Double,
      Double,
      Double,
      Pointer<Double>,
      Int32,
    );
typedef _Call =
    int Function(
      Pointer<Double>,
      double,
      double,
      double,
      double,
      Pointer<Double>,
      int,
    );

final class NativeSatellite {
  NativeSatellite() {
    final lib = Platform.isIOS
        ? DynamicLibrary.process()
        : DynamicLibrary.open(
            Platform.isAndroid
                ? 'libyorungez_satellite.so'
                : Platform.environment['YORUNGEZ_SATELLITE_LIBRARY'] ??
                      '${Directory.current.path}/../../.local/mobile-science/${Platform.isWindows ? 'yorungez_satellite.dll' : 'libyorungez_satellite.so'}',
          );
    if (lib.lookupFunction<Int32 Function(), int Function()>(
          'yg_satellite_abi',
        )() !=
        1) {
      throw const FormatException('Unsupported satellite ABI');
    }
    _call = lib.lookupFunction<_Native, _Call>('yg_satellite');
  }
  late final _Call _call;
  Float64List calculate(
    List<double> elements,
    SkyObserver observer,
    DateTime instant,
  ) {
    if (elements.length != 10 || elements.any((v) => !v.isFinite)) {
      throw const FormatException('Invalid elements');
    }
    final e = calloc<Double>(10), out = calloc<Double>(9);
    try {
      e.asTypedList(10).setAll(0, elements);
      final status = _call(
        e,
        instant.microsecondsSinceEpoch / 1e6,
        observer.latitude,
        observer.longitude,
        observer.elevation,
        out,
        9,
      );
      if (status != 0) throw const FormatException('Propagation unavailable');
      return Float64List.fromList(out.asTypedList(9));
    } finally {
      calloc.free(e);
      calloc.free(out);
    }
  }
}
