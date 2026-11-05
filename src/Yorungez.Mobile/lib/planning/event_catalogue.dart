import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/generated/app_localizations.dart';
import 'planning_time.dart';

final class SkyEvent {
  const SkyEvent(
    this.id,
    this.kind,
    this.targetId,
    this.instant,
    this.sourceId,
    this.sourceUrl,
  );
  final String id, kind, targetId, sourceId, sourceUrl;
  final DateTime instant;
  String title(AppLocalizations t) => switch (kind) {
    'new-moon' => t.eventNewMoon,
    'first-quarter' => t.eventFirstQuarter,
    'full-moon' => t.eventFullMoon,
    'last-quarter' => t.eventLastQuarter,
    'march-equinox' => t.eventMarchEquinox,
    'june-solstice' => t.eventJuneSolstice,
    'september-equinox' => t.eventSeptemberEquinox,
    'december-solstice' => t.eventDecemberSolstice,
    'opposition' => t.eventOpposition,
    'greatest-elongation' => t.eventElongation,
    'inferior-conjunction' => t.eventInferiorConjunction,
    'superior-conjunction' => t.eventSuperiorConjunction,
    _ => throw const FormatException('Unknown calendar event'),
  };
}

final class EventCatalogue {
  const EventCatalogue(this.events, this.provenance);
  final List<SkyEvent> events;
  final Map<String, dynamic> provenance;
  List<SkyEvent> month(int year, int month, String zone) => events.where((e) {
    final d = PlanningTime.local(e.instant, zone);
    return d.year == year && d.month == month;
  }).toList();
  static Future<EventCatalogue> load({AssetBundle? bundle}) async {
    bundle ??= rootBundle;
    final m =
        jsonDecode(
              await bundle.loadString(
                'assets/generated/calendar-manifest.json',
              ),
            )
            as Map<String, dynamic>;
    final bytes = await bundle.load('assets/generated/calendar.json');
    final raw = bytes.buffer.asUint8List(
      bytes.offsetInBytes,
      bytes.lengthInBytes,
    );
    if (sha256.convert(raw).toString() != m['sha256']) {
      throw const FormatException('Calendar integrity mismatch');
    }
    final data = jsonDecode(utf8.decode(raw)) as Map<String, dynamic>;
    final sources = {
      for (final s in m['sources'] as List)
        s['id'] as String: s['url'] as String,
    };
    final events = (data['events'] as List)
        .map(
          (e) => SkyEvent(
            e['id'],
            e['kind'],
            e['targetId'],
            DateTime.parse(e['instantUtc']).toUtc(),
            e['sourceId'],
            sources[e['sourceId']]!,
          ),
        )
        .toList();
    if (events.length != m['eventCount'] ||
        events.map((e) => e.id).toSet().length != events.length) {
      throw const FormatException('Invalid calendar identities');
    }
    return EventCatalogue(events, m);
  }
}

final eventCatalogueProvider = FutureProvider((ref) => EventCatalogue.load());
