import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yorungez/catalogue/data/catalogue_repository.dart';
import 'package:yorungez/catalogue/data/survey_image.dart';
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
    expect(catalogue.objects.length, 5341);
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
      169,
    );
    expect(catalogue.images.length, 30);
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
        searchObjects(catalogue.objects, 'GÖKADASI').map((o) => o.id),
        contains('dso-ngc0224'),
      );
      expect(
        searchObjects(catalogue.objects, 'gokadasi').map((o) => o.id),
        contains('dso-ngc0224'),
      );
      expect(searchObjects(catalogue.objects, 'M 31').first.id, 'dso-ngc0224');
      expect(
        searchObjects(catalogue.objects, 'HIP 32349').first.id,
        'hyg-32263',
      );
      expect(searchObjects(catalogue.objects, 'not-a-real-object'), isEmpty);
    },
  );

  test(
    'regional and galaxy searches work offline without fake point targets',
    () {
      for (final query in ['milkyway', 'Saman yolu', 'Samanyolu Galaksisi']) {
        final galaxy = searchObjects(catalogue.objects, query).single;
        expect(galaxy.id, 'milky-way');
        expect(galaxy.raHours, isNull);
        expect(galaxy.regionId, 'con-sgr');
        expect(surveyImageUri(galaxy), isNull);
      }
      expect(
        searchObjects(catalogue.objects, 'galaksiler').length,
        greaterThan(75),
      );
      expect(
        searchObjects(catalogue.objects, 'İğne Galaksisi').first.id,
        'dso-ngc4565',
      );
      expect(
        searchObjects(catalogue.objects, 'NGC 5128').first.id,
        'dso-ngc5128',
      );
      expect(
        searchObjects(catalogue.objects, 'Sunak Takımyıldızı').first.id,
        'con-ara',
      );
      expect(
        searchObjects(catalogue.objects, 'Altar').map((o) => o.id),
        containsAll(['con-ara', 'hyg-97338']),
      );
    },
  );

  test(
    'image coverage includes the requested references and valid chart data',
    () {
      expect(
        catalogue.images.keys,
        containsAll([
          'sat-25544',
          'hyg-90979',
          'hyg-97338',
          'hyg-32263',
          'con-ara',
          'dso-ngc0224',
          'milky-way',
        ]),
      );
      final chartIds = catalogue.lines.entries
          .where((entry) => entry.value.any((line) => line.length >= 2))
          .map((entry) => entry.key)
          .toSet();
      expect(
        catalogue.objects.every(
          (object) =>
              catalogue.images.containsKey(object.id) ||
              surveyImageUri(object) != null ||
              chartIds.contains(object.id),
        ),
        isTrue,
      );
      expect(
        catalogue.objects
                .where(
                  (object) =>
                      catalogue.images.containsKey(object.id) ||
                      surveyImageUri(object) != null,
                )
                .length /
            catalogue.objects.length,
        greaterThan(.98),
      );
      final uri = surveyImageUri(catalogue.find('dso-ngc0253')!)!;
      expect(uri.scheme, 'https');
      expect(uri.host, 'skyview.gsfc.nasa.gov');
      expect(
        uri.queryParameters['Position'],
        matches(RegExp(r'^\d+\.\d+,-\d+\.\d+$')),
      );
      expect(uri.queryParameters['Survey'], '2MASS-K');
      expect(surveyImageUri(issObject), isNull);
    },
  );

  test('glossary includes the shared 60 sourced terms in both languages', () {
    expect(catalogue.glossary, hasLength(60));
    final azimuth = catalogue.glossary.singleWhere(
      (term) => term.id == 'azimuth',
    );
    expect(azimuth.matches(normalizeSearch('AZ')), isTrue);
    expect(azimuth.definition('tr'), contains('90° azimut doğuya'));
    expect(azimuth.definition('en'), contains('90° means look east'));
    expect(azimuth.sources.single, startsWith('https://'));
  });

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
