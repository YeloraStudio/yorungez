enum ObjectKind { star, deepSky, constellation, solarSystem, satellite }

const issObject = SkyObject(
  id: 'sat-25544',
  names: {
    'en': 'International Space Station',
    'tr': 'Uluslararası Uzay İstasyonu',
  },
  kind: ObjectKind.satellite,
  designation: 'NORAD 25544',
  aliases: ['ISS', 'Uzay İstasyonu'],
  summaries: {
    'en': 'Crewed space station in low Earth orbit',
    'tr': 'Alçak Dünya yörüngesinde insanlı uzay istasyonu',
  },
);

const solarObjects = [
  SkyObject(
    id: 'sun',
    names: {'en': 'Sun', 'tr': 'Güneş'},
    kind: ObjectKind.solarSystem,
  ),
  SkyObject(
    id: 'moon',
    names: {'en': 'Moon', 'tr': 'Ay'},
    kind: ObjectKind.solarSystem,
  ),
  SkyObject(
    id: 'mercury',
    names: {'en': 'Mercury', 'tr': 'Merkür'},
    kind: ObjectKind.solarSystem,
  ),
  SkyObject(
    id: 'venus',
    names: {'en': 'Venus', 'tr': 'Venüs'},
    kind: ObjectKind.solarSystem,
  ),
  SkyObject(
    id: 'mars',
    names: {'en': 'Mars', 'tr': 'Mars'},
    kind: ObjectKind.solarSystem,
  ),
  SkyObject(
    id: 'jupiter',
    names: {'en': 'Jupiter', 'tr': 'Jüpiter'},
    kind: ObjectKind.solarSystem,
  ),
  SkyObject(
    id: 'saturn',
    names: {'en': 'Saturn', 'tr': 'Satürn'},
    kind: ObjectKind.solarSystem,
  ),
  SkyObject(
    id: 'uranus',
    names: {'en': 'Uranus', 'tr': 'Uranüs'},
    kind: ObjectKind.solarSystem,
  ),
  SkyObject(
    id: 'neptune',
    names: {'en': 'Neptune', 'tr': 'Neptün'},
    kind: ObjectKind.solarSystem,
  ),
];

final class SkyObject {
  const SkyObject({
    required this.id,
    required this.names,
    required this.kind,
    this.designation = '',
    this.aliases = const [],
    this.raHours,
    this.decDegrees,
    this.magnitude,
    this.distanceParsecs,
    this.constellation = '',
    this.subtype = '',
    this.summaries = const {},
  });

  final String id;
  final Map<String, String> names;
  final ObjectKind kind;
  final String designation;
  final List<String> aliases;
  final double? raHours;
  final double? decDegrees;
  final double? magnitude;
  final double? distanceParsecs;
  final String constellation, subtype;
  final Map<String, String> summaries;

  String name(String language) => names[language] ?? names['en'] ?? id;

  Iterable<String> get searchTerms => [
    id,
    designation,
    ...names.values,
    ...aliases,
  ];
}

String normalizeSearch(String value) {
  var result = value.replaceAll('İ', 'i').replaceAll('I', 'i').toLowerCase();
  const replacements = {
    'ı': 'i',
    'ö': 'o',
    'ü': 'u',
    'ş': 's',
    'ğ': 'g',
    'ç': 'c',
  };
  for (final entry in replacements.entries) {
    result = result.replaceAll(entry.key, entry.value);
  }
  return result.replaceAll(RegExp(r'[^a-z0-9]'), '');
}

List<SkyObject> searchObjects(List<SkyObject> objects, String query) {
  final term = normalizeSearch(query);
  if (term.isEmpty) return objects;
  final matches = <(SkyObject, int)>[];
  for (final object in objects) {
    var best = 3;
    for (final alias in object.searchTerms) {
      final normalized = normalizeSearch(alias);
      final score = normalized == term
          ? 0
          : normalized.startsWith(term)
          ? 1
          : normalized.contains(term)
          ? 2
          : 3;
      if (score < best) best = score;
    }
    if (best < 3) matches.add((object, best));
  }
  matches.sort((a, b) {
    final rank = a.$2.compareTo(b.$2);
    return rank != 0 ? rank : a.$1.id.compareTo(b.$1.id);
  });
  return matches.map((entry) => entry.$1).toList(growable: false);
}
