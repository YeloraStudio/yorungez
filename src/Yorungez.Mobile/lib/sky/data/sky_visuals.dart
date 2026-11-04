import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import '../domain/sky_geometry.dart';

/// Bounded decoded textures. Canonical source bytes and credits stay unchanged.
final class SkyVisuals {
  final Map<String, ui.Image> images = {};
  final Set<String> _pending = {};
  ui.FragmentShader? cosmic;
  bool _closed = false;
  Set<String> _wanted = {};
  Future<ui.Image> _decode(String path, int width) async {
    final bytes = await rootBundle.load(path);
    final codec = await ui.instantiateImageCodec(
      bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
      targetWidth: width,
    );
    try {
      return (await codec.getNextFrame()).image;
    } finally {
      codec.dispose();
    }
  }

  Future<void> initialise() async {
    final image = await _decode('assets/generated/cosmic-sky.jpg', 1024);
    if (_closed) {
      image.dispose();
      return;
    }
    images['cosmic'] = image;
    final program = await ui.FragmentProgram.fromAsset(
      'shaders/cosmic_sky.frag',
    );
    if (_closed) return;
    cosmic = program.fragmentShader()..setImageSampler(0, image);
    for (final id in [
      'sun',
      'moon',
      'mercury',
      'venus',
      'mars',
      'jupiter',
      'saturn',
      'uranus',
      'neptune',
    ]) {
      final texture = await _decode('assets/generated/images/$id.jpg', 256);
      if (_closed) {
        texture.dispose();
        return;
      }
      images[id] = texture;
    }
  }

  Future<void> updateArt(Set<String> wanted, void Function() repaint) async {
    _wanted = wanted.take(12).toSet();
    for (final key
        in images.keys
            .where((k) => k.startsWith('/sky-art/') && !_wanted.contains(k))
            .toList()) {
      images.remove(key)!.dispose();
    }
    for (final path in _wanted.toList()) {
      if (_closed || images.containsKey(path) || !_pending.add(path)) continue;
      try {
        final image = await _decode('assets/generated$path', 512);
        if (_closed || !_wanted.contains(path)) {
          image.dispose();
        } else {
          images[path] = image;
          repaint();
        }
      } finally {
        _pending.remove(path);
      }
    }
  }

  void close() {
    _closed = true;
    cosmic?.dispose();
    for (final image in images.values) {
      image.dispose();
    }
    images.clear();
  }
}

/// IAU/J2000 equatorial-to-galactic rotation, consistent with the catalogue epoch.
const equatorialToGalactic = [
  -.0548755604162154,
  -.8734370902348850,
  -.4838350155487132,
  .4941094278755837,
  -.4448296299600112,
  .7469822444972189,
  -.8676661490190047,
  -.1980763734312015,
  .4559837761750669,
];
List<double> galacticFromEnu(List<double> eqjToEnu) => [
  for (var row = 0; row < 3; row++)
    for (var col = 0; col < 3; col++)
      equatorialToGalactic[row * 3] * eqjToEnu[col * 3] +
          equatorialToGalactic[row * 3 + 1] * eqjToEnu[col * 3 + 1] +
          equatorialToGalactic[row * 3 + 2] * eqjToEnu[col * 3 + 2],
];

/// Affine source anchors lifted onto the sphere, before view projection.
Vec3 figureRay(double x, double y, List<dynamic> anchors, List<Vec3> rays) {
  final a = anchors[0] as Map, b = anchors[1] as Map, c = anchors[2] as Map;
  final ax = (a['x'] as num).toDouble(), ay = (a['y'] as num).toDouble();
  final bx = (b['x'] as num).toDouble(), by = (b['y'] as num).toDouble();
  final cx = (c['x'] as num).toDouble(), cy = (c['y'] as num).toDouble();
  final determinant = (bx - ax) * (cy - ay) - (cx - ax) * (by - ay);
  if (determinant.abs() < 1) {
    throw const FormatException('Degenerate figure anchors');
  }
  final u = ((x - ax) * (cy - ay) - (y - ay) * (cx - ax)) / determinant;
  final v = ((bx - ax) * (y - ay) - (by - ay) * (x - ax)) / determinant;
  return (rays[0] * (1 - u - v) + rays[1] * u + rays[2] * v).unit;
}
