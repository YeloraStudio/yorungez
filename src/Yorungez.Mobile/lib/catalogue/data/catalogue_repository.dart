import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../domain/sky_object.dart';

final class Catalogue {
  const Catalogue(
    this.objects,
    this.images,
    this.notices,
    this.version, {
    this.starInput = const [],
    this.dsoInput = const [],
    this.lines = const {},
    this.colours = const {},
    this.art = const {},
    this.infoSources = const {},
  });
  final List<SkyObject> objects;
  final Map<String, Map<String, dynamic>> images;
  final String notices;
  final String version;
  final List<double> starInput, dsoInput;
  final Map<String, List<List<String>>> lines;
  final Map<String, double> colours;
  final Map<String, dynamic> art;
  final Map<String, List<Map<String, dynamic>>> infoSources;
  SkyObject? find(String id) {
    for (final object in objects) {
      if (object.id == id) return object;
    }
    return null;
  }
}

class CatalogueRepository {
  CatalogueRepository({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;
  final AssetBundle _bundle;

  Future<Catalogue> load() async {
    const prefix = 'assets/generated/';
    final manifest =
        jsonDecode(await _bundle.loadString('${prefix}manifest.json'))
            as Map<String, dynamic>;
    if (manifest['schemaVersion'] != 1 || manifest['epoch'] != 'J2000.0') {
      throw const FormatException('Unsupported public catalogue manifest');
    }
    final payloads = <String, Uint8List>{};
    for (final entry in (manifest['files'] as Map<String, dynamic>).entries) {
      if (!RegExp(r'^[a-zA-Z0-9_./-]+$').hasMatch(entry.key) ||
          entry.key.contains('..') ||
          entry.key.startsWith('/')) {
        throw const FormatException('Invalid public asset path');
      }
      final data = await _bundle.load('$prefix${entry.key}');
      payloads[entry.key] = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );
    }
    return compute(decodeCatalogue, <String, Object>{
      'manifest': manifest,
      'payloads': payloads,
    });
  }
}

Catalogue decodeCatalogue(Map<String, Object> input) {
  final manifest = input['manifest']! as Map<String, dynamic>;
  final payloads = input['payloads']! as Map<String, Uint8List>;
  for (final entry in (manifest['files'] as Map<String, dynamic>).entries) {
    if (sha256.convert(payloads[entry.key]!).toString() != entry.value) {
      throw const FormatException('Public catalogue integrity check failed');
    }
  }
  Map<String, dynamic> decode(String name) =>
      jsonDecode(utf8.decode(payloads[name]!)) as Map<String, dynamic>;
  final bright = decode('bright-sky.json');
  final overlays = decode('overlays.json');
  final info = decode('mobile-object-info.json');
  if (bright['schemaVersion'] != 1 ||
      overlays['schemaVersion'] != 1 ||
      bright['epoch'] != 'J2000.0' ||
      bright['version'] != manifest['catalogueVersion']) {
    throw const FormatException('Unsupported public catalogue');
  }
  double? number(dynamic value) =>
      value is num && value.isFinite ? value.toDouble() : null;
  const dsoNames = {
    'dso-ngc0224': {'en': 'Andromeda Galaxy', 'tr': 'Andromeda Gökadası'},
    'dso-ngc1976': {'en': 'Orion Nebula', 'tr': 'Orion Bulutsusu'},
  };
  final objects = <SkyObject>[
    issObject,
    for (final object in solarObjects)
      SkyObject(
        id: object.id,
        names: object.names,
        kind: object.kind,
        summaries: ((info['descriptions'] as Map)[object.id]['text'] as Map)
            .cast<String, String>(),
      ),
    for (final star in bright['stars'] as List)
      SkyObject(
        id: star['id'] as String,
        names: {
          'en': (star['name'] as String?)?.isNotEmpty == true
              ? star['name'] as String
              : star['designation'] as String,
        },
        kind: ObjectKind.star,
        designation: star['designation'] as String,
        aliases: [if (star['hip'] != null) 'HIP ${star['hip']}'],
        raHours: number(star['raHoursJ2000']),
        decDegrees: number(star['decDegreesJ2000']),
        magnitude: number(star['magnitude']),
        distanceParsecs: number(star['distanceParsecs']),
        constellation: star['constellation'] as String,
      ),
    for (final dso in overlays['deepSky'] as List)
      SkyObject(
        id: dso['id'] as String,
        names: dsoNames[dso['id']] ?? {'en': dso['name'] as String},
        kind: ObjectKind.deepSky,
        designation: dso['name'] as String,
        aliases: [
          dso['designation'] as String,
          ...(dso['aliases'] as List).cast<String>(),
        ],
        raHours: number(dso['raHoursJ2000']),
        decDegrees: number(dso['decDegreesJ2000']),
        magnitude: number(dso['magnitude']),
        subtype: dso['type'] as String,
      ),
    for (final constellation in bright['constellations'] as List)
      SkyObject(
        id: constellation['id'] as String,
        names: {
          ...(constellation['names'] as Map).cast<String, String>(),
          'en':
              (info['constellationLatinNames'] as Map)[constellation['id']]
                  as String,
        },
        aliases: [(constellation['names'] as Map)['en'] as String],
        kind: ObjectKind.constellation,
        designation: constellation['iau'] as String,
      ),
  ];
  if (objects.map((object) => object.id).toSet().length != objects.length ||
      (bright['stars'] as List).length != manifest['stars'] ||
      (bright['constellations'] as List).length != manifest['constellations'] ||
      (overlays['deepSky'] as List).length != manifest['deepSky']) {
    throw const FormatException('Public catalogue count or identity mismatch');
  }
  for (final object in objects) {
    if (object.kind == ObjectKind.constellation ||
        object.kind == ObjectKind.solarSystem ||
        object.kind == ObjectKind.satellite) {
      continue;
    }
    if (object.raHours == null ||
        object.decDegrees == null ||
        object.raHours! < 0 ||
        object.raHours! >= 24 ||
        object.decDegrees!.abs() > 90) {
      throw const FormatException('Invalid catalogue coordinates');
    }
  }
  final media = decode('object-media.json');
  final images = <String, Map<String, dynamic>>{};
  for (final entry in (media['images'] as Map<String, dynamic>).entries) {
    if (payloads.containsKey('images/${entry.key}.jpg')) {
      images[entry.key] = entry.value as Map<String, dynamic>;
    }
  }
  return Catalogue(
    List.unmodifiable(objects),
    Map.unmodifiable(images),
    utf8.decode(payloads['notices.txt']!),
    manifest['catalogueVersion'] as String,
    starInput: List<double>.unmodifiable([
      for (final s in [
        ...bright['stars'] as List,
        for (final anchor in overlays['art']['anchors'] as List) anchor['star'],
      ]) ...[
        ...(s['positionPc'] as List).map((v) => (v as num).toDouble()),
        ...(s['velocityPcPerYear'] as List).map((v) => (v as num).toDouble()),
      ],
    ]),
    art: (overlays['art'] as Map).cast<String, dynamic>(),
    infoSources: {
      for (final entry
          in (info['descriptions'] as Map<String, dynamic>).entries)
        entry.key: [
          for (final source in entry.value['sources'] as List)
            Map<String, dynamic>.from(source as Map),
        ],
    },
    dsoInput: List<double>.unmodifiable([
      for (final d in overlays['deepSky'] as List) ...[
        (d['raHoursJ2000'] as num).toDouble(),
        (d['decDegreesJ2000'] as num).toDouble(),
      ],
    ]),
    lines: {
      for (final c in bright['constellations'] as List)
        c['id'] as String: [
          for (final line in c['lines'] as List) (line as List).cast<String>(),
        ],
    },
    colours: {
      for (final s in bright['stars'] as List)
        if (s['colorIndex'] is num)
          s['id'] as String: (s['colorIndex'] as num).toDouble(),
    },
  );
}
