import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/timezone.dart' as tz;

import '../app/providers.dart';
import '../core/presentation/external_link.dart';
import '../l10n/generated/app_localizations.dart';
import '../sky/domain/sky_geometry.dart';
import 'local_observing_events.dart';
import 'planning_controls.dart';
import 'planning_time.dart';

class LocalEventsPanel extends ConsumerStatefulWidget {
  const LocalEventsPanel({super.key, required this.month});
  final DateTime month;

  @override
  ConsumerState<LocalEventsPanel> createState() => _LocalEventsPanelState();
}

class _LocalEventsPanelState extends ConsumerState<LocalEventsPanel> {
  (SkyObserver, DateTime, String)? _request;
  Future<List<LocalObservingEvent>>? _future;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final observer = ref.watch(
      skyFrameProvider.select((frame) => frame?.observer),
    );
    final zone = ref.watch(planningZoneProvider);
    final month = widget.month;
    if (observer != null) {
      final request = (observer, month, zone);
      if (request != _request) {
        _request = request;
        final location = PlanningTime.zone(zone);
        final start = tz.TZDateTime(location, month.year, month.month).toUtc();
        final end = tz.TZDateTime(
          location,
          month.year,
          month.month + 1,
        ).toUtc();
        _future = ref
            .read(skyWorkerProvider.future)
            .then((worker) => worker.localEvents(observer, start, end));
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(t.localEventsIntro),
        if (observer == null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(t.planningLocationNeeded),
          )
        else ...[
          if (observer.example) Text(t.guideExampleSite),
          FutureBuilder<List<LocalObservingEvent>>(
            key: ValueKey(_request),
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return PlanningError(
                  onRetry: () => setState(() => _request = null),
                );
              }
              final events = snapshot.data;
              if (events == null) return const LinearProgressIndicator();
              if (events.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(t.localEventsEmpty),
                );
              }
              return Column(
                children: [
                  for (final event in events)
                    _LocalEventCard(event: event, zone: zone),
                ],
              );
            },
          ),
        ],
        const SizedBox(height: 12),
      ],
    );
  }
}

class _LocalEventCard extends ConsumerWidget {
  const _LocalEventCard({required this.event, required this.zone});
  final LocalObservingEvent event;
  final String zone;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final language = Localizations.localeOf(context).languageCode;
    final title = switch (event.kind) {
      LocalEventKind.penumbralLunar => t.eclipsePenumbral,
      LocalEventKind.partialLunar => t.eclipsePartialLunar,
      LocalEventKind.totalLunar => t.eclipseTotalLunar,
      LocalEventKind.partialSolar => t.eclipsePartialSolar,
      LocalEventKind.annularSolar => t.eclipseAnnularSolar,
      LocalEventKind.totalSolar => t.eclipseTotalSolar,
      LocalEventKind.geminids => t.meteorGeminids,
      LocalEventKind.quadrantids => t.meteorQuadrantids,
      LocalEventKind.perseids => t.meteorPerseids,
    };
    String local(DateTime instant) =>
        PlanningTime.label(instant, zone, language);
    final source = event.meteor
        ? 'https://www.imo.net/calendar/'
        : 'https://eclipse.gsfc.nasa.gov/';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('${local(event.start)} – ${local(event.end)}'),
            const SizedBox(height: 8),
            Text('${t.suggestedTime} · ${local(event.suggested)}'),
            Text(PlanningTime.utc(event.suggested, language)),
            if (event.solar) ...[
              const SizedBox(height: 10),
              Text(t.eclipseSafety),
              ExternalLink(
                url: 'https://science.nasa.gov/eclipses/safety/',
                label: t.eclipseSafetyLink,
                small: true,
              ),
            ],
            if (event.kind == LocalEventKind.penumbralLunar)
              Text(t.eclipseSubtle),
            if (event.meteor)
              Text(event.moonlight ? t.meteorMoonlight : t.meteorWindow),
            if (!event.meteor)
              TextButton.icon(
                onPressed: () => openPlannedSky(
                  context,
                  ref,
                  event.solar ? 'sun' : 'moon',
                  event.suggested,
                ),
                icon: const Icon(Icons.north_east),
                label: Text(t.focusTarget),
              ),
            ExternalLink(
              url: source,
              label: event.meteor
                  ? 'International Meteor Organization'
                  : 'NASA Eclipse Catalog',
              small: true,
            ),
          ],
        ),
      ),
    );
  }
}
