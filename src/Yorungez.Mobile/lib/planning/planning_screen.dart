import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../app/providers.dart';
import '../account/account_widgets.dart';
import '../account/notebook_screen.dart';
import '../catalogue/domain/sky_object.dart';
import '../core/presentation/external_link.dart';
import '../l10n/generated/app_localizations.dart';
import '../sky/domain/sky_geometry.dart';
import 'event_catalogue.dart';
import 'local_events_panel.dart';
import 'night_plan.dart';
import 'observing_guide.dart';
import 'observing_guide_screen.dart';
import 'planning_controls.dart';
import 'planning_time.dart';
import 'reminder_screen.dart';

String targetName(String id, String language) =>
    solarObjects.firstWhere((o) => o.id == id).name(language);

class EventActions extends ConsumerStatefulWidget {
  const EventActions({
    super.key,
    required this.targetId,
    required this.instant,
    required this.title,
    this.eventId,
  });
  final String targetId, title;
  final DateTime instant;
  final String? eventId;
  @override
  ConsumerState<EventActions> createState() => _EventActionsState();
}

class _EventActionsState extends ConsumerState<EventActions> {
  bool _saving = false;
  Future<void> _favorite() async {
    final session = ref.read(accountSessionProvider);
    if (session.state.user == null) {
      context.push('/account');
      return;
    }
    setState(() => _saving = true);
    try {
      final entries = await session.notebook();
      final id = 'favorite:${widget.targetId}';
      final old = entries.where((e) => e.id == id).firstOrNull;
      await session.saveEntry({
        'id': id,
        'kind': 'favorite',
        'expectedRevision': old?.revision ?? 0,
        'target': {'id': widget.targetId, 'name': widget.title},
        'instantUtc': widget.instant.toUtc().toIso8601String(),
      });
      if (mounted) {
        ref.invalidate(notebookProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).recordSaved)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(accountError(AppLocalizations.of(context), e)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        FilledButton.icon(
          onPressed: () =>
              openPlannedSky(context, ref, widget.targetId, widget.instant),
          icon: const Icon(Icons.north_east),
          label: Text(t.focusTarget),
        ),
        OutlinedButton.icon(
          onPressed:
              !widget.instant.isAfter(
                DateTime.now().toUtc().add(const Duration(minutes: 2)),
              )
              ? null
              : () => showReminderEditor(
                  context,
                  ref,
                  title: widget.title,
                  targetId: widget.targetId,
                  instant: widget.instant,
                  eventId: widget.eventId,
                ),
          icon: const Icon(Icons.notifications_active_outlined),
          label: Text(t.remindMe),
        ),
        IconButton(
          tooltip: t.addNote,
          onPressed: () => showNoteEditor(
            context,
            ref,
            target: {'id': widget.targetId, 'name': widget.title},
            instantUtc: widget.instant,
          ),
          icon: const Icon(Icons.edit_note),
        ),
        IconButton(
          tooltip: t.addFavorite,
          onPressed: _saving ? null : _favorite,
          icon: _saving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.star_outline),
        ),
      ],
    );
  }
}

class EventCalendarScreen extends ConsumerStatefulWidget {
  const EventCalendarScreen({super.key});
  @override
  ConsumerState<EventCalendarScreen> createState() =>
      _EventCalendarScreenState();
}

class _EventCalendarScreenState extends ConsumerState<EventCalendarScreen> {
  DateTime? _month;
  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context),
        language = ref.watch(localeProvider).languageCode,
        zone = ref.watch(planningZoneProvider);
    final now = PlanningTime.local(DateTime.now(), zone),
        month = _month ?? DateTime.utc(now.year, now.month);
    return Scaffold(
      appBar: AppBar(
        title: Text(t.eventCalendar),
        actions: [
          IconButton(
            tooltip: t.timeZone,
            onPressed: () => context.push('/time-zone'),
            icon: const Icon(Icons.public),
          ),
        ],
      ),
      body: ref
          .watch(eventCatalogueProvider)
          .when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => PlanningError(
              onRetry: () => ref.invalidate(eventCatalogueProvider),
            ),
            data: (catalogue) {
              final events = catalogue.month(month.year, month.month, zone);
              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(t.calendarIntro),
                  const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (context, box) {
                      final fields = [
                        ChoiceField<int>(
                          label: t.calendarMonth,
                          valueLabel: DateFormat.MMMM(language).format(month),
                          choices: [
                            for (var m = 1; m <= 12; m++)
                              (
                                m,
                                DateFormat.MMMM(
                                  language,
                                ).format(DateTime(2026, m)),
                              ),
                          ],
                          onSelected: (m) => setState(
                            () => _month = DateTime.utc(month.year, m),
                          ),
                        ),
                        ChoiceField<int>(
                          label: t.calendarYear,
                          valueLabel: '${month.year}',
                          choices: [
                            for (var y = 2000; y <= 2035; y++) (y, '$y'),
                          ],
                          onSelected: (y) => setState(
                            () => _month = DateTime.utc(y, month.month),
                          ),
                        ),
                      ];
                      return box.maxWidth < 350
                          ? Column(
                              children: [
                                fields[0],
                                const SizedBox(height: 16),
                                fields[1],
                              ],
                            )
                          : Row(
                              children: [
                                Expanded(child: fields[0]),
                                const SizedBox(width: 16),
                                Expanded(child: fields[1]),
                              ],
                            );
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(zone, style: Theme.of(context).textTheme.titleSmall),
                  Text(t.calendarGlobal),
                  ExpansionTile(
                    title: Text(t.localEventsTitle),
                    tilePadding: EdgeInsets.zero,
                    children: [LocalEventsPanel(month: month)],
                  ),
                  const SizedBox(height: 16),
                  if (events.isEmpty) Text(t.calendarEmpty),
                  for (final event in events)
                    Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.auto_awesome_outlined,
                                  color: Color(0xFFC9B6A6),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        event.title(t),
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleLarge,
                                      ),
                                      Text(
                                        targetName(event.targetId, language),
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodyMedium,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              PlanningTime.label(event.instant, zone, language),
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(PlanningTime.utc(event.instant, language)),
                            const SizedBox(height: 12),
                            EventActions(
                              key: ValueKey(event.id),
                              targetId: event.targetId,
                              instant: event.instant,
                              title: event.title(t),
                              eventId: event.id,
                            ),
                            const SizedBox(height: 8),
                            ExternalLink(
                              url: event.sourceUrl,
                              label: event.sourceId == 'usno'
                                  ? t.usnoCompared
                                  : t.calculatedEvent,
                              small: true,
                            ),
                          ],
                        ),
                      ),
                    ),
                  Text(t.calendarProvenance),
                  Text(
                    catalogue.provenance['source'] as String,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              );
            },
          ),
    );
  }
}

class TonightScreen extends ConsumerStatefulWidget {
  const TonightScreen({super.key});
  @override
  ConsumerState<TonightScreen> createState() => _TonightScreenState();
}

class _TonightScreenState extends ConsumerState<TonightScreen> {
  DateTime? _date;
  ObservingEquipment? _equipment;
  Future<NightPlan>? _future;
  (SkyObserver, String, DateTime)? _context;
  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context),
        language = ref.watch(localeProvider).languageCode,
        zone = ref.watch(planningZoneProvider);
    final observer = ref.watch(skyFrameProvider)?.observer;
    final date = _date ?? PlanningTime.nightDate(DateTime.now().toUtc(), zone);
    if (observer != null &&
        _equipment == null &&
        (_context?.$1 != observer ||
            _context?.$2 != zone ||
            _context?.$3 != date)) {
      _context = (observer, zone, date);
      try {
        final window = PlanningTime.window(date, zone);
        _future = ref
            .read(skyWorkerProvider.future)
            .then((worker) => worker.plan(observer, window.start, window.end));
      } catch (error, stack) {
        _future = Future.error(error, stack);
      }
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(t.tonight),
        actions: [
          IconButton(
            tooltip: t.timeZone,
            onPressed: () => context.push('/time-zone'),
            icon: const Icon(Icons.public),
          ),
        ],
      ),
      body: observer == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(t.planningLocationNeeded),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => context.go('/'),
                      child: Text(t.focusTarget),
                    ),
                  ],
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: PlanningDateButton(
                        value: date,
                        onSelected: (d) => setState(() => _date = d),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(zone),
                Text(
                  '${observer.latitude.toStringAsFixed(3)}, ${observer.longitude.toStringAsFixed(3)}',
                ),
                const SizedBox(height: 16),
                Text(t.tonightIntro),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final (gear, label) in [
                      (ObservingEquipment.nakedEye, t.guideNakedEye),
                      (ObservingEquipment.binoculars, t.guideBinoculars),
                    ])
                      FilterChip(
                        label: Text(label),
                        selected: _equipment == gear,
                        onSelected: (enabled) =>
                            setState(() => _equipment = enabled ? gear : null),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_equipment != null)
                  ObservationGuidePanel(
                    observer: observer,
                    date: date,
                    equipment: _equipment,
                  )
                else
                  FutureBuilder<NightPlan>(
                    future: _future,
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return PlanningError(
                          onRetry: () => setState(() => _context = null),
                        );
                      }
                      if (!snapshot.hasData) {
                        return const Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      final plan = snapshot.data!;
                      String hour(DateTime? d) => d == null
                          ? '—'
                          : DateFormat.Hm(
                              language,
                            ).format(PlanningTime.local(d, zone));
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      children: [
                                        Text(t.sunset),
                                        const SizedBox(height: 8),
                                        Text(
                                          hour(plan.sunset),
                                          style: Theme.of(
                                            context,
                                          ).textTheme.headlineMedium,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      children: [
                                        Text(t.sunrise),
                                        const SizedBox(height: 8),
                                        Text(
                                          hour(plan.sunrise),
                                          style: Theme.of(
                                            context,
                                          ).textTheme.headlineMedium,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (plan.state != 0)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Text(switch (plan.state) {
                                1 => t.noNight,
                                2 => t.polarNight,
                                _ => t.partialNight,
                              }),
                            ),
                          for (final row in plan.rows)
                            _NightRowCard(row: row, plan: plan, zone: zone),
                          const SizedBox(height: 16),
                          Text(t.visibilityCaution),
                          const SizedBox(height: 12),
                          ExpansionTile(
                            title: Text(t.calculationDetails),
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Text(t.nightDefinition),
                              ),
                            ],
                          ),
                          const ExternalLink(
                            url:
                                'https://github.com/cosinekitty/astronomy/tree/v2.1.19',
                            label: 'Astronomy Engine 2.1.19',
                            small: true,
                          ),
                        ],
                      );
                    },
                  ),
              ],
            ),
    );
  }
}

class _NightRowCard extends ConsumerWidget {
  const _NightRowCard({
    required this.row,
    required this.plan,
    required this.zone,
  });
  final NightRow row;
  final NightPlan plan;
  final String zone;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context),
        language = ref.watch(localeProvider).languageCode,
        name = targetName(row.id, language);
    final total = plan.end.difference(plan.start).inMilliseconds;
    String time(DateTime d) => DateFormat(
      'dd MMM HH:mm',
      language,
    ).format(PlanningTime.local(d, zone));
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(name, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (context, box) => Semantics(
                label: '$name · ${t.tonight}',
                button: row.best != null,
                onTap: row.best == null
                    ? null
                    : () => openPlannedSky(context, ref, row.id, row.best!),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapUp: (details) {
                    final instant = plan.start.add(
                      Duration(
                        milliseconds:
                            (details.localPosition.dx / box.maxWidth * total)
                                .round(),
                      ),
                    );
                    if (row.intervals.any(
                      (i) =>
                          !instant.isBefore(i.start) && instant.isBefore(i.end),
                    )) {
                      openPlannedSky(context, ref, row.id, instant);
                    }
                  },
                  child: SizedBox(
                    height: 44,
                    child: Stack(
                      children: [
                        Positioned(
                          left: 0,
                          right: 0,
                          top: 15,
                          bottom: 15,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: const Color(0xFF25272B),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        for (final i in row.intervals)
                          Positioned(
                            left:
                                (i.start.difference(plan.start).inMilliseconds /
                                        total *
                                        box.maxWidth)
                                    .clamp(0, box.maxWidth),
                            width:
                                (i.end.difference(i.start).inMilliseconds /
                                        total *
                                        box.maxWidth)
                                    .clamp(0, box.maxWidth),
                            top: 17,
                            bottom: 17,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: const Color(0xFFC9B6A6),
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            for (final interval in row.intervals)
              Text('${time(interval.start)} – ${time(interval.end)}'),
            if (row.best == null)
              Text(t.notAboveTonight)
            else ...[
              const SizedBox(height: 8),
              Text(
                '${t.suggestedTime}: ${time(row.best!)} · ${row.altitude!.toStringAsFixed(0)}°',
              ),
              Text(
                PlanningTime.utc(row.best!, language),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              EventActions(
                targetId: row.id,
                instant: row.best!,
                title: '$name · ${t.observingTime}',
              ),
            ],
          ],
        ),
      ),
    );
  }
}
