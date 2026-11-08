import 'sky_object.dart';

final class GlossaryTerm {
  GlossaryTerm.fromJson(Map<String, dynamic> json)
    : id = json['id'] as String,
      abbreviation = json['abbreviation'] as String?,
      translations = {
        for (final entry in (json['translations'] as Map).entries)
          entry.key as String: (entry.value as Map).cast<String, dynamic>(),
      },
      sources = (json['sources'] as List).cast<String>();

  final String id;
  final String? abbreviation;
  final Map<String, Map<String, dynamic>> translations;
  final List<String> sources;

  String name(String language) => translations[language]!['name'] as String;
  String definition(String language) =>
      translations[language]!['definition'] as String;

  String? abbreviationFor(String language) {
    if (id == 'astronomical-unit') return language == 'tr' ? 'AB' : 'AU';
    return abbreviation;
  }

  bool matches(String normalizedQuery) => [
    id,
    ?abbreviation,
    for (final translation in translations.values) ...[
      translation['name'] as String,
      ...(translation['aliases'] as List).cast<String>(),
    ],
  ].any((term) => normalizeSearch(term).contains(normalizedQuery));
}
