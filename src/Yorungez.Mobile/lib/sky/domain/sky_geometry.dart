import 'dart:math' as math;

const radians = math.pi / 180;

final class Vec3 {
  const Vec3(this.x, this.y, this.z);
  final double x, y, z;
  double dot(Vec3 b) => x * b.x + y * b.y + z * b.z;
  Vec3 cross(Vec3 b) =>
      Vec3(y * b.z - z * b.y, z * b.x - x * b.z, x * b.y - y * b.x);
  Vec3 operator +(Vec3 b) => Vec3(x + b.x, y + b.y, z + b.z);
  Vec3 operator *(double value) => Vec3(x * value, y * value, z * value);
  Vec3 get unit {
    final length = math.sqrt(dot(this));
    if (!length.isFinite || length < 1e-10) {
      throw const FormatException('Invalid direction');
    }
    return this * (1 / length);
  }

  static Vec3 horizon(double az, double alt) => Vec3(
    math.cos(alt * radians) * math.sin(az * radians),
    math.cos(alt * radians) * math.cos(az * radians),
    math.sin(alt * radians),
  );
  double get azimuth => (math.atan2(x, y) / radians + 360) % 360;
  double get altitude => math.atan2(z, math.sqrt(x * x + y * y)) / radians;
}

final class ViewPose {
  const ViewPose(this.forward, this.right, this.up);
  factory ViewPose.horizon(double az, double alt, [double roll = 0]) {
    final forward = Vec3.horizon(az, alt);
    final right = Vec3(math.cos(az * radians), -math.sin(az * radians), 0);
    final up = right.cross(forward);
    return ViewPose(
      forward,
      right * math.cos(roll * radians) + up * (-math.sin(roll * radians)),
      up * math.cos(roll * radians) + right * math.sin(roll * radians),
    );
  }
  // Row-major device-to-ENU matrix. Device +Z points out of the screen;
  // the rear optical axis is -Z. Display axes are rotated in the screen plane.
  factory ViewPose.device(
    List<double> matrix,
    int displayRotation, [
    double yawOffset = 0,
  ]) {
    if (matrix.length != 9 ||
        matrix.any((v) => !v.isFinite) ||
        ![0, 90, 180, 270].contains(displayRotation)) {
      throw const FormatException('Invalid native pose');
    }
    Vec3 column(int n) => Vec3(matrix[n], matrix[n + 3], matrix[n + 6]);
    Vec3 yaw(Vec3 v) => Vec3(
      v.x * math.cos(yawOffset) + v.y * math.sin(yawOffset),
      v.y * math.cos(yawOffset) - v.x * math.sin(yawOffset),
      v.z,
    );
    final x = column(0), y = column(1), z = column(2);
    if ((x.dot(x) - 1).abs() > .03 ||
        (y.dot(y) - 1).abs() > .03 ||
        (z.dot(z) - 1).abs() > .03 ||
        x.dot(y).abs() > .03 ||
        x.cross(y).dot(z) < .97) {
      throw const FormatException('Native pose is not a rotation');
    }
    final angle = displayRotation * radians;
    return ViewPose(
      yaw(z * (-1)),
      yaw(x * math.cos(angle) + y * math.sin(angle)),
      yaw(y * math.cos(angle) + x * (-math.sin(angle))),
    );
  }
  final Vec3 forward, right, up;
}

final class SkyProjection {
  const SkyProjection(
    this.pose,
    this.width,
    this.height,
    this.fieldOfView, {
    this.optical = false,
  });
  final ViewPose pose;
  final double width, height, fieldOfView;
  final bool optical;
  (double, double)? project(Vec3 vector) {
    final front = vector.dot(pose.forward);
    final short = math.min(width, height);
    if (optical && front <= .001) return null;
    if (!optical && front <= -.999) return null;
    final factor = optical
        ? short / (2 * math.tan(fieldOfView * radians / 2) * front)
        : short / (2 * math.tan(fieldOfView * radians / 4) * (1 + front));
    final x = width / 2 + factor * vector.dot(pose.right);
    final y = height / 2 - factor * vector.dot(pose.up);
    return x.isFinite && y.isFinite ? (x, y) : null;
  }
}

final class SkyObserver {
  SkyObserver(
    this.latitude,
    this.longitude, {
    this.elevation = 0,
    this.device = false,
    this.example = false,
    this.accuracy,
    this.measuredAt,
  }) {
    if (!latitude.isFinite ||
        latitude.abs() >= 89 ||
        !longitude.isFinite ||
        longitude.abs() > 180 ||
        !elevation.isFinite ||
        elevation < -500 ||
        elevation > 100000) {
      throw const FormatException('Unsupported observer context');
    }
  }
  final double latitude, longitude, elevation;
  final bool device, example;
  final double? accuracy;
  final DateTime? measuredAt;
}
