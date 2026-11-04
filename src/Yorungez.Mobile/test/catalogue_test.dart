import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yorungez/catalogue/data/catalogue_repository.dart';
import 'package:yorungez/catalogue/domain/sky_object.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Catalogue catalogue;
  setUpAll(() async => catalogue = await CatalogueRepository().load());

  test(
    'mobile brief names retain scientific Latin constellation names and EN/TR solar descriptions',
    () {
      expect(catalogue.find('con-cen')!.name('en'), 'Centaurus');
      expect(catalogue.find('con-leo')!.name('en'), 'Leo');
      expect(catalogue.find('hyg-68483')!.constellation, 'Cen');
      expect(
        catalogue.find('jupiter')!.summaries['en'],
        'Largest planet in the Solar System',
      );
      expect(catalogue.find('moon')!.summaries['tr'], isNotEmpty);
    },
  );
  test('bundled canonical catalogue opens offline with stable identities', () {
    expect(catalogue.objects.length, 5278);
    expect(
      catalogue.objects.where((o) => o.kind == ObjectKind.star).length,
      5073,
    );
    expect(
      catalogue.objects.where((o) => o.kind == ObjectKind.constellation).length,
      88,
    );
    expect(
      catalogue.objects.where((o) => o.kind == ObjectKind.deepSky).length,
      107,
    );
    expect(catalogue.images.length, 12);
    expect(catalogue.notices, contains('Mattia Verga'));
    expect(catalogue.find('hyg-32263')!.raHours, 6.752481);
    expect(catalogue.find('missing'), isNull);
  });

  test('M31 and Andromeda retain different object identities and types', () {
    expect(searchObjects(catalogue.objects, 'M31').first.id, 'dso-ngc0224');
    final results = searchObjects(catalogue.objects, 'andromeda');
    expect(results.map((o) => o.id), containsAll(['con-and', 'dso-ngc0224']));
    expect(catalogue.find('con-and')!.kind, ObjectKind.constellation);
  });

  test(
    'Turkish names, ASCII aliases and spaced identifiers are searchable',
    () {
      expect(
        searchObjects(catalogue.objects, 'GÖKADASI').first.id,
        'dso-ngc0224',
      );
      expect(
        searchObjects(catalogue.objects, 'gokadasi').first.id,
        'dso-ngc0224',
      );
      expect(searchObjects(catalogue.objects, 'M 31').first.id, 'dso-ngc0224');
      expect(
        searchObjects(catalogue.objects, 'HIP 32349').first.id,
        'hyg-32263',
      );
      expect(searchObjects(catalogue.objects, 'not-a-real-object'), isEmpty);
    },
  );

  Map<String, Object> input() {
    final manifest =
        jsonDecode(File('assets/generated/manifest.json').readAsStringSync())
            as Map<String, dynamic>;
    return {
      'manifest': manifest,
      'payloads': <String, Uint8List>{
        for (final name in (manifest['files'] as Map).keys)
          name as String: File('assets/generated/$name').readAsBytesSync(),
      },
    };
  }

  test('corrupted bundled bytes are rejected before catalogue use', () {
    final value = input();
    final bytes =
        (value['payloads'] as Map<String, Uint8List>)['bright-sky.json']!;
    bytes[100] ^= 1;
    expect(() => decodeCatalogue(value), throwsFormatException);
  });

  test(
    'an unsupported epoch is rejected even with internally valid hashes',
    () {
      final value = input();
      final payloads = value['payloads'] as Map<String, Uint8List>;
      final bright =
          jsonDecode(utf8.decode(payloads['bright-sky.json']!))
              as Map<String, dynamic>;
      bright['epoch'] = 'J2050.0';
      payloads['bright-sky.json'] = Uint8List.fromList(
        utf8.encode(jsonEncode(bright)),
      );
      ((value['manifest'] as Map)['files'] as Map)['bright-sky.json'] = sha256
          .convert(payloads['bright-sky.json']!)
          .toString();
      expect(() => decodeCatalogue(value), throwsFormatException);
    },
  );
}
