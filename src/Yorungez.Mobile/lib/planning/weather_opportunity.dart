import '../catalogue/domain/sky_object.dart';
import '../l10n/generated/app_localizations.dart';

const weatherBodies = ['moon', 'mercury', 'venus', 'mars', 'jupiter', 'saturn'];

String localizedMoonPhase(AppLocalizations t, String phase) => switch (phase) {
  'new-moon' => t.eventNewMoon,
  'waxing-crescent' => t.moonWaxingCrescent,
  'first-quarter' => t.eventFirstQuarter,
  'waxing-gibbous' => t.moonWaxingGibbous,
  'full-moon' => t.eventFullMoon,
  'waning-gibbous' => t.moonWaningGibbous,
  'last-quarter' => t.eventLastQuarter,
  'waning-crescent' => t.moonWaningCrescent,
  _ => t.observingMoonPhase,
};

String observingGuidePath({
  String? target,
  DateTime? from,
  DateTime? to,
  bool nightOnly = false,
}) => Uri(
  path: '/observe',
  queryParameters: {
    'target': ?target,
    if (from != null) 'from': from.toUtc().toIso8601String(),
    if (to != null) 'to': to.toUtc().toIso8601String(),
    if (nightOnly) 'night': '1',
  },
).toString();

String weatherTargetName(AppLocalizations t, String id, String language) =>
    switch (id) {
      'penumbral-lunar' => t.eclipsePenumbral,
      'partial-lunar' => t.eclipsePartialLunar,
      'total-lunar' => t.eclipseTotalLunar,
      'geminids' => t.meteorGeminids,
      'quadrantids' => t.meteorQuadrantids,
      'perseids' => t.meteorPerseids,
      _ =>
        solarObjects.where((o) => o.id == id).firstOrNull?.name(language) ?? id,
    };

final class ObservingOpportunity {
  ObservingOpportunity(Map<String, dynamic> value)
    : id = value['id'] as String,
      target = value['target'] as String,
      start = DateTime.parse(value['startUtc'] as String).toUtc(),
      end = DateTime.parse(value['endUtc'] as String).toUtc(),
      best = DateTime.parse(value['bestUtc'] as String).toUtc(),
      azimuth = (value['azimuthDegrees'] as num?)?.toDouble(),
      altitude = (value['altitudeDegrees'] as num).toDouble(),
      cloud = (value['cloudPercent'] as num?)?.toDouble(),
      light = value['light'] as String,
      conditions = value['conditions'] as String;

  final String id, target, light, conditions;
  final DateTime start, end, best;
  final double? azimuth, cloud;
  final double altitude;
}
