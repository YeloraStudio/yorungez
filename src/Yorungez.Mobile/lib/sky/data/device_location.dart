import 'package:geolocator/geolocator.dart';
import '../domain/sky_geometry.dart';

abstract interface class DeviceLocationSource {
  Future<bool> permitted({required bool request});
  Future<Position?> recent();
  Future<Position> current();
}

class ForegroundDeviceLocation implements DeviceLocationSource {
  @override
  Future<bool> permitted({required bool request}) async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied && request) {
      permission = await Geolocator.requestPermission();
    }
    return (permission == LocationPermission.whileInUse ||
            permission == LocationPermission.always) &&
        await Geolocator.isLocationServiceEnabled();
  }

  @override
  Future<Position?> recent() => Geolocator.getLastKnownPosition().timeout(
    const Duration(seconds: 1),
    onTimeout: () => null,
  );
  @override
  Future<Position> current() => Geolocator.getCurrentPosition(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.best,
      timeLimit: Duration(seconds: 15),
    ),
  );
}

SkyObserver? deviceObserver(
  Position fix,
  DateTime now, {
  bool provisional = false,
}) {
  if (![fix.latitude, fix.longitude, fix.accuracy].every((v) => v.isFinite) ||
      fix.latitude.abs() >= 89 ||
      fix.longitude.abs() > 180 ||
      fix.accuracy <= 0 ||
      fix.accuracy > (provisional ? 200 : 10000) ||
      now.difference(fix.timestamp).abs() >
          Duration(seconds: provisional ? 60 : 30)) {
    return null;
  }
  // OS altitude datums differ. Do not label an unverified GPS height ellipsoidal.
  return SkyObserver(
    fix.latitude,
    fix.longitude,
    device: true,
    accuracy: fix.accuracy,
    measuredAt: fix.timestamp,
  );
}
