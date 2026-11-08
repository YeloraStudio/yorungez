import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'every staged public asset is bundled with its verified bytes',
    () async {
      const prefix = 'assets/generated/';
      final manifest =
          jsonDecode(await rootBundle.loadString('${prefix}manifest.json'))
              as Map<String, dynamic>;
      final files = manifest['files'] as Map<String, dynamic>;
      expect(files.keys, containsAll(['app-icon.png', 'cosmic-sky.jpg']));
      for (final entry in files.entries) {
        final data = await rootBundle.load('$prefix${entry.key}');
        expect(
          sha256
              .convert(
                data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
              )
              .toString(),
          entry.value,
          reason: entry.key,
        );
      }
    },
  );
}
