import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../app/providers.dart';
import '../core/presentation/external_link.dart';
import '../l10n/generated/app_localizations.dart';
import '../sky/domain/sky_geometry.dart';
import 'observing_guide.dart';
import 'planning_controls.dart';
import 'planning_time.dart';

String directionName(AppLocalizations t, double azimuth) => [
  t.guideNorth,
  t.guideNorthEast,
  t.guideEast,
  t.guideSouthEast,
  t.guideSouth,
  t.guideSouthWest,
  t.guideWest,
  t.guideNorthWest,
][compassSector(azimuth)];

class ObservationGuideScreen extends ConsumerWidget {
  const ObservationGuideScreen({super.key, this.target});

  final String? target;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final observer = ref.watch(
      skyFrameProvider.select((frame) => frame?.observer),
    );
    final zone = ref.watch(planningZoneProvider);
    final instant = ref.watch(skyInstantProvider) ?? DateTime.now().toUtc();
    final date = PlanningTime.nightDate(instant, zone);
    return Scaffold(
      appBar: AppBar(title: Text(t.guideTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(t.guideIntro),
            const SizedBox(height: 12),
            if (observer == null)
              Text(t.planningLocationNeeded)
            else
              ObservationGuidePanel(
                observer: observer,
                date: date,
                target: guideTargets.contains(target) ? target : null,
              ),
          ],
        ),
      ),
    );
  }
}

class ObservationGuidePanel extends ConsumerStatefulWidget {
  const ObservationGuidePanel({
    super.key,
    required this.observer,
    required this.date,
    this.equipment,
    this.target,
  });

  final SkyObserver observer;
  final DateTime date;
  final ObservingEquipment? equipment;
  final String? target;

  @override
  ConsumerState<ObservationGuidePanel> createState() =>
      _ObservationGuidePanelState();
}

class _ObservationGuidePanelState extends ConsumerState<ObservationGuidePanel> {
  (SkyObserver, DateTime, String)? _input;
  Future<Map<String, ObservationSlot>>? _future;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final language = Localizations.localeOf(context).languageCode;
    final zone = ref.watch(planningZoneProvider);
    final catalogue = ref.watch(catalogueProvider).asData?.value;
    final input = (widget.observer, widget.date, zone);
    if (input != _input) {
      _input = input;
      _future = Future.sync(() {
        final window = PlanningTime.window(input.$2, zone);
        return ref
            .read(skyWorkerProvider.future)
            .then(
              (worker) =>
                  worker.observingGuide(input.$1, window.start, window.end),
            );
      });
    }
    return FutureBuilder<Map<String, ObservationSlot>>(
      key: ValueKey(input),
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return PlanningError(onRetry: () => setState(() => _input = null));
        }
        final slots = snapshot.data;
        if (slots == null || catalogue == null) {
          return const Center(child: CircularProgressIndicator());
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.observer.example) Text(t.guideExampleSite),
            for (final id in guideTargets)
              if ((widget.target == null || widget.target == id) &&
                  (widget.equipment == null || suitedTo(id, widget.equipment!)))
                _GuideCard(
                  id: id,
                  name: catalogue.find(id)!.name(language),
                  slot: slots[id],
                  binoculars: widget.equipment != ObservingEquipment.nakedEye,
                ),
            const SizedBox(height: 12),
            Text(t.guideConditions),
            const ExternalLink(
              url:
                  'https://science.nasa.gov/solar-system/skywatching/night-sky-network/binoculars-a-great-first-telescope/',
              label: 'NASA Night Sky Network',
              small: true,
            ),
          ],
        );
      },
    );
  }
}

class _GuideCard extends ConsumerWidget {
  const _GuideCard({
    required this.id,
    required this.name,
    required this.slot,
    required this.binoculars,
  });

  final String id, name;
  final ObservationSlot? slot;
  final bool binoculars;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final language = Localizations.localeOf(context).languageCode;
    final zone = ref.watch(planningZoneProvider);
    final tip = switch (id) {
      'moon' => binoculars ? t.guideMoon : t.guideMoonUnaided,
      'jupiter' => binoculars ? t.guideJupiter : t.guidePlanetUnaided,
      'saturn' => binoculars ? t.guideSaturn : t.guidePlanetUnaided,
      'dso-mel022' => t.guidePleiades,
      _ => t.guideOrion,
    };
    String local(DateTime value) => PlanningTime.label(value, zone, language);
    final observation = slot;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            if (observation == null) Text(t.guideNoWindow),
            if (observation != null) ...[
              Text(
                '${t.guideWindow}\n${local(observation.start)} – ${local(observation.end)}',
              ),
              const SizedBox(height: 8),
              Text('${t.suggestedTime} · ${local(observation.best)}'),
              Text(PlanningTime.utc(observation.best, language)),
              const SizedBox(height: 12),
              ObservationDirection(direction: observation.direction),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: () =>
                    openPlannedSky(context, ref, id, observation.best),
                icon: const Icon(Icons.north_east),
                label: Text(t.focusTarget),
              ),
            ],
            const SizedBox(height: 8),
            Text(tip),
          ],
        ),
      ),
    );
  }
}

class ObservationDirection extends StatelessWidget {
  const ObservationDirection({super.key, required this.direction});
  final GuideDirection direction;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final language = Localizations.localeOf(context).languageCode;
    final angle = NumberFormat.decimalPatternDigits(
      locale: language,
      decimalDigits: 0,
    );
    final altitude = direction.altitude;
    if (altitude < 0) return Text(t.belowHorizon);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          altitude >= 89
              ? t.guideOverhead
              : t.guidePointing(
                  directionName(t, direction.azimuth),
                  angle.format(altitude),
                ),
        ),
        ExcludeSemantics(
          child: SizedBox(
            width: 112,
            height: 58,
            child: CustomPaint(painter: _HorizonDiagram(altitude)),
          ),
        ),
      ],
    );
  }
}

class _HorizonDiagram extends CustomPainter {
  const _HorizonDiagram(this.altitude);
  final double altitude;

  @override
  void paint(Canvas canvas, Size size) {
    final origin = Offset(8, size.height - 8);
    final angle = altitude * radians;
    final end = origin + Offset(44 * math.cos(angle), -44 * math.sin(angle));
    final baseline = Paint()
      ..color = const Color(0xFF9EA1A6)
      ..strokeWidth = 1.5;
    final direction = Paint()
      ..color = const Color(0xFFDA8190)
      ..strokeWidth = 2;
    canvas.drawLine(origin, Offset(size.width - 8, origin.dy), baseline);
    canvas.drawLine(origin, end, direction);
    canvas.drawCircle(end, 3, direction);
  }

  @override
  bool shouldRepaint(_HorizonDiagram oldDelegate) =>
      altitude != oldDelegate.altitude;
}
