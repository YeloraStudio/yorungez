import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

// Deterministic local staging. No network, credentials or user data.
Future<void> main() async {
  final app = File.fromUri(Platform.script).parent.parent;
  final repo = app.parent.parent;
  final nativeManifest =
      jsonDecode(
            await File(
              '${repo.path}/third-party/astronomy-engine/source/c/manifest.json',
            ).readAsString(),
          )
          as Map<String, dynamic>;
  for (final entry
      in (nativeManifest['files'] as Map<String, dynamic>).entries) {
    final bytes = await File(
      '${repo.path}/third-party/astronomy-engine/source/c/${entry.key}',
    ).readAsBytes();
    if (sha256.convert(bytes).toString() != (entry.value as Map)['sha256']) {
      throw StateError('Pinned astronomy source checksum mismatch');
    }
  }

  for (final name in ['sgp4', 'wmm2025']) {
    final root = '${repo.path}/third-party/$name';
    final manifest =
        jsonDecode(await File('$root/manifest.json').readAsString())
            as Map<String, dynamic>;
    for (final entry in (manifest['files'] as Map<String, dynamic>).entries) {
      final bytes = await File('$root/${entry.key}').readAsBytes();
      if (sha256.convert(bytes).toString() != (entry.value as Map)['sha256']) {
        throw StateError('Pinned native source mismatch');
      }
    }
  }
  final cof = await File(
    '${repo.path}/third-party/wmm2025/WMM.COF',
  ).readAsLines();
  final coefficients = cof
      .skip(1)
      .map((line) => line.trim().split(RegExp(r'\s+')))
      .where((row) => row.length == 6)
      .toList();
  final expectedHeader =
      '/* Generated from pinned WMM2025 WMM.COF; NOAA/NCEI and BGS. Public domain source data. */\nstatic const double yg_wmm_coefficients[90][6] = {\n${coefficients.map((row) => '    {${row.join(',')}},\n').join()}};\n';
  if (coefficients.length != 90 ||
      (await File(
            '${app.path}/native/wmm_coefficients.h',
          ).readAsString()).replaceAll('\r\n', '\n') !=
          expectedHeader) {
    throw StateError('WMM coefficient transcription mismatch');
  }
  final output = Directory('${app.path}/assets/generated');
  await Directory('${output.path}/images').create(recursive: true);
  final files = <String, String>{};
  Future<void> copy(String relative, String target, {String? expected}) async {
    final bytes = await File('${repo.path}/$relative').readAsBytes();
    final digest = sha256.convert(bytes).toString();
    if (expected != null && digest != expected) {
      throw StateError('Canonical public asset checksum mismatch: $relative');
    }
    await File('${output.path}/$target').writeAsBytes(bytes);
    files[target] = digest;
  }

  final eventManifest =
      jsonDecode(
            await File('${repo.path}/data/events/manifest.json').readAsString(),
          )
          as Map<String, dynamic>;
  await copy(
    'data/events/calendar.json',
    'calendar.json',
    expected: eventManifest['sha256'] as String,
  );
  await copy('data/events/manifest.json', 'calendar-manifest.json');
  final brightManifest =
      jsonDecode(
            await File(
              '${repo.path}/data/catalog/manifest.json',
            ).readAsString(),
          )
          as Map<String, dynamic>;
  final overlayManifest =
      jsonDecode(
            await File(
              '${repo.path}/data/catalog/overlays-manifest.json',
            ).readAsString(),
          )
          as Map<String, dynamic>;
  await copy(
    'data/catalog/bright-sky.json',
    'bright-sky.json',
    expected: brightManifest['derivedSha256'] as String,
  );
  final overlayBytes = await File(
    '${repo.path}/data/catalog/overlays.json',
  ).readAsBytes();
  if (sha256.convert(overlayBytes).toString() != overlayManifest['sha256']) {
    throw StateError('Canonical overlay checksum mismatch');
  }
  // Independently licensed figures retain canonical celestial anchors and hashes.
  final overlays =
      jsonDecode(utf8.decode(overlayBytes)) as Map<String, dynamic>;
  final dsoBytes = utf8.encode(
    jsonEncode({
      'schemaVersion': overlays['schemaVersion'],
      'deepSky': overlays['deepSky'],
      'art': overlays['art'],
    }),
  );
  await File('${output.path}/overlays.json').writeAsBytes(dsoBytes);
  files['overlays.json'] = sha256.convert(dsoBytes).toString();
  await Directory('${output.path}/sky-art').create(recursive: true);
  for (final entry in overlayManifest['artFiles'] as List) {
    final file = entry['file'] as String;
    await copy(
      file,
      'sky-art/${file.split('/').last}',
      expected: entry['sha256'] as String,
    );
  }
  await copy('data/branding/source/app-icon-fullbleed.png', 'app-icon.png');
  await copy('data/catalog/mobile-object-info.json', 'mobile-object-info.json');
  final sky =
      jsonDecode(
            await File('${repo.path}/data/sky/manifest.json').readAsString(),
          )
          as Map<String, dynamic>;
  await copy(
    'data/sky/eso0932a.jpg',
    'cosmic-sky.jpg',
    expected: sky['sha256'] as String,
  );
  await copy('data/sky/manifest.json', 'cosmic-sky.json');

  final media =
      jsonDecode(
            await File(
              '${repo.path}/data/catalog/object-media.json',
            ).readAsString(),
          )
          as Map<String, dynamic>;
  final sun =
      jsonDecode(
            await File(
              '${repo.path}/data/catalog/sun-content.json',
            ).readAsString(),
          )
          as Map<String, dynamic>;
  (media['images'] as Map<String, dynamic>)['sun'] =
      (sun['en'] as Map<String, dynamic>)['image'];
  final mediaBytes = utf8.encode(jsonEncode(media));
  await File('${output.path}/object-media.json').writeAsBytes(mediaBytes);
  files['object-media.json'] = sha256.convert(mediaBytes).toString();
  for (final id in (media['images'] as Map<String, dynamic>).keys) {
    final entry =
        (media['images'] as Map<String, dynamic>)[id] as Map<String, dynamic>;
    await copy(
      'src/Yorungez.Web/public${entry['url']}',
      'images/$id.jpg',
      expected: entry['sha256'] as String,
    );
  }
  final audioManifest =
      jsonDecode(
            await File('${repo.path}/data/audio/manifest.json').readAsString(),
          )
          as Map<String, dynamic>;
  await copy(
    'data/audio/cylinder-four.m4a',
    'cylinder-four.m4a',
    expected: audioManifest['sha256'] as String,
  );
  final notices = <String, String>{
    'flutter_secure_storage 11.2.0 — German Saprykin and contributors, BSD-3-Clause; https://pub.dev/packages/flutter_secure_storage':
        'third-party/flutter-account-plugins/flutter_secure_storage.LICENSE',
    'url_launcher 6.3.3 — The Flutter Authors, BSD-3-Clause; https://pub.dev/packages/url_launcher':
        'third-party/flutter-account-plugins/url_launcher.LICENSE',
    'Yorungez original code — Apache-2.0; https://github.com/YeloraStudio/yorungez':
        'LICENSE',
    'Astronomy Engine 2.1.19 — Don Cross; https://github.com/cosinekitty/astronomy':
        'third-party/astronomy-engine/LICENSE',
    'HYG 4.1 — David Nash / Astronomy Nexus; https://github.com/astronexus/HYG-Database':
        'third-party/hyg/LICENSE.md',
    'OpenNGC — Mattia Verga; https://github.com/mattiaverga/OpenNGC':
        'third-party/openngc/LICENSE.txt',
    'd3-celestial — Olaf Frohn; https://github.com/ofrohn/d3-celestial':
        'third-party/d3-celestial/LICENSE',
  };
  // Keep exact upstream notices accessible offline, independent of UI summaries.
  final noticeText = StringBuffer();
  noticeText.writeln(
    'timezone 0.11.2 — Dart authors. BSD-3-Clause; bundled IANA tzdb 2025c. https://pub.dev/packages/timezone',
  );
  noticeText.writeln(
    await File(
      '${repo.path}/third-party/flutter-account-plugins/timezone-LICENSE',
    ).readAsString(),
  );
  noticeText.writeln(
    await File('${repo.path}/third-party/sgp4/NOTICE.md').readAsString(),
  );
  noticeText.writeln(
    await File('${repo.path}/third-party/wmm2025/NOTICE.md').readAsString(),
  );
  noticeText.writeln(
    'path_provider — Flutter authors, BSD-3-Clause. https://pub.dev/packages/path_provider/license',
  );
  noticeText.writeln(
    '360-degree sky: ESO/S. Brunier, CC BY 4.0. https://www.eso.org/public/images/eso0932a/ Photographic composite, runtime filtered/projected, not astrometric point data. https://creativecommons.org/licenses/by/4.0/',
  );
  noticeText.writeln(
    await File(
      '${repo.path}/third-party/stellarium-art/NOTICE.md',
    ).readAsString(),
  );
  noticeText.writeln(
    await File(
      '${repo.path}/third-party/stellarium-art/UPSTREAM-description.md',
    ).readAsString(),
  );
  noticeText.writeln(
    'Cylinder Four by Chris Zabriskie. From the album Cylinders (2014). Licensed under CC BY 4.0. https://creativecommons.org/licenses/by/4.0/ https://chriszabriskie.com/cylinders/ Unmodified author audio; repeated playback and local volume control.',
  );
  for (final entry in notices.entries) {
    noticeText.writeln('# ${entry.key}');
    noticeText.writeln(
      await File('${repo.path}/${entry.value}').readAsString(),
    );
  }
  final noticeBytes = utf8.encode(noticeText.toString());
  await File('${output.path}/notices.txt').writeAsBytes(noticeBytes);
  files['notices.txt'] = sha256.convert(noticeBytes).toString();
  await File('${output.path}/manifest.json').writeAsString(
    '${const JsonEncoder.withIndent('  ').convert({
      'schemaVersion': 1,
      'catalogueVersion': brightManifest['version'],
      'epoch': 'J2000.0',
      'stars': brightManifest['starCount'],
      'constellations': brightManifest['constellationCount'],
      'deepSky': overlayManifest['deepSkyCount'],
      'sourceDigests': {'bright-sky.json': brightManifest['derivedSha256'], 'overlays.json': overlayManifest['sha256']},
      'files': files,
    })}\n',
  );
  stdout.writeln(
    'Staged ${files.length} verified public assets. No data downloaded.',
  );
}
