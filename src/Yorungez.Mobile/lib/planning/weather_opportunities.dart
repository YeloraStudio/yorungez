import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/providers.dart';
import '../core/presentation/external_link.dart';
import '../l10n/generated/app_localizations.dart';
import '../sky/domain/sky_geometry.dart';
import 'observing_guide.dart';
import 'planning_controls.dart';
import 'planning_time.dart';
import 'reminder_screen.dart';
import 'weather_opportunity.dart';

class WeatherOpportunities extends ConsumerStatefulWidget {
  const WeatherOpportunities({
    super.key,
    required this.observer,
    required this.zone,
    this.target,
    this.start,
    this.end,
    this.nightOnly = false,
    this.monthly = false,
  });

  final SkyObserver observer;
  final String zone;
  final String? target;
  final DateTime? start, end;
  final bool nightOnly, monthly;

  @override
  ConsumerState<WeatherOpportunities> createState() =>
      _WeatherOpportunitiesState();
}

class _WeatherOpportunitiesState extends ConsumerState<WeatherOpportunities> {
  late Future<
    ({
      DateTime? updated,
      DateTime? through,
      String status,
      List<ObservingOpportunity> windows,
      ({String phase, double fraction, DateTime instant})? moon,
    })
  >
  _future;
  CancelToken? _cancel;
  bool _showAll = false;

  Map<String, Object?> get _site => {
    'latitude': widget.observer.latitude,
    'longitude': widget.observer.longitude,
    'elevationMeters': widget.observer.elevation <= 10000
        ? widget.observer.elevation
        : null,
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant WeatherOpportunities old) {
    super.didUpdateWidget(old);
    if (old.observer != widget.observer ||
        old.target != widget.target ||
        old.start != widget.start ||
        old.end != widget.end) {
      _showAll = false;
      _load();
    }
  }

  void _load() {
    _cancel?.cancel();
    final cancel = _cancel = CancelToken();
    _future = ref
        .read(apiProvider)
        .observingOpportunities({
          ..._site,
          'target': widget.target,
          'startUtc': widget.start?.toUtc().toIso8601String(),
          'endUtc': widget.end?.toUtc().toIso8601String(),
          'futureOnly': widget.monthly,
          'includeMoonPhase':
              widget.monthly &&
              (widget.target == null || widget.target == 'moon'),
        }, cancel)
        .then((data) {
          final windows = (data['windows'] as List)
              .map(
                (item) => ObservingOpportunity(
                  Map<String, dynamic>.from(item as Map),
                ),
              )
              .toList();
          int rank(String condition) => switch (condition) {
            'good' => 0,
            'uncertain' => 1,
            'unknown' => 2,
            _ => 3,
          };
          windows.sort((a, b) {
            final result = rank(a.conditions).compareTo(rank(b.conditions));
            return result == 0 ? a.start.compareTo(b.start) : result;
          });
          final updated = data['weatherUpdatedUtc'] as String?;
          final through = data['weatherThroughUtc'] as String?;
          final moon = data['moonPhase'] as Map<String, dynamic>?;
          return (
            updated: updated == null ? null : DateTime.parse(updated),
            through: through == null ? null : DateTime.parse(through),
            status: data['weatherStatus'] as String,
            windows: windows,
            moon: moon == null
                ? null
                : (
                    phase: moon['phase'] as String,
                    fraction: (moon['illuminatedFraction'] as num).toDouble(),
                    instant: DateTime.parse(moon['instantUtc'] as String),
                  ),
          );
        });
  }

  @override
  void dispose() {
    _cancel?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final language = Localizations.localeOf(context).languageCode;
    String local(DateTime instant) =>
        PlanningTime.label(instant, widget.zone, language);

    return FutureBuilder(
      key: ValueKey(_future),
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return PlanningError(onRetry: () => setState(_load));
        }
        final data = snapshot.data;
        if (data == null) return const LinearProgressIndicator();

        final windows = widget.nightOnly
            ? data.windows.where((w) => w.light != 'daylight').toList()
            : data.windows;
        final visible = _showAll ? windows : windows.take(6);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.observer.example) Text(t.guideExampleSite),
            Text(widget.zone),
            if (data.moon case final moon?)
              _MoonPhaseCard(
                title: localizedMoonPhase(t, moon.phase),
                fraction: moon.fraction,
                illuminated: t.moonIlluminated((moon.fraction * 100).round()),
                time: local(moon.instant),
              ),
            if (data.updated case final updated?) ...[
              Text('${t.forecastUpdated} ${local(updated)}'),
              Text(t.forecastWeatherCredit),
              const ExternalLink(
                url: 'https://creativecommons.org/licenses/by/4.0/',
                label: 'CC BY 4.0',
                small: true,
              ),
              Text(t.forecastLocalLimits),
            ] else
              Text(
                data.status == 'outside_range'
                    ? t.forecastLater
                    : t.forecastUnavailable,
              ),
            const SizedBox(height: 10),
            if (windows.isEmpty) Text(t.forecastNoOpportunity),
            for (final window in visible)
              _card(context, window, local, language, data.through),
            if (windows.length > 6)
              TextButton(
                onPressed: () => setState(() => _showAll = !_showAll),
                child: Text(_showAll ? t.forecastShowLess : t.forecastShowAll),
              ),
          ],
        );
      },
    );
  }

  Widget _card(
    BuildContext context,
    ObservingOpportunity window,
    String Function(DateTime) local,
    String language,
    DateTime? weatherThrough,
  ) {
    final t = AppLocalizations.of(context);
    final name = weatherTargetName(t, window.id, language);
    final radiant = window.target == 'radiant';
    final light = switch (window.light) {
      'daylight' => t.forecastDaylight,
      'twilight' => t.forecastTwilight,
      _ => t.forecastNight,
    };
    final locale = MaterialLocalizations.of(context);
    final azimuth = window.azimuth;
    final sector = azimuth == null
        ? null
        : [
            t.guideNorth,
            t.guideNorthEast,
            t.guideEast,
            t.guideSouthEast,
            t.guideSouth,
            t.guideSouthWest,
            t.guideWest,
            t.guideNorthWest,
          ][compassSector(azimuth)];
    final best = window.best;
    final now = DateTime.now().toUtc();
    final reminderTime = best.isAfter(now.add(const Duration(minutes: 32)))
        ? best
        : window.end.subtract(const Duration(minutes: 5));
    final forecastPending =
        weatherThrough != null && !reminderTime.isBefore(weatherThrough);
    final label = switch (window.conditions) {
      'good' => t.forecastGood,
      'uncertain' => t.forecastUncertain,
      'poor' => t.forecastPoor,
      _ => forecastPending ? t.forecastPending : t.forecastUnknown,
    };
    final today = PlanningTime.calendarDate(now, widget.zone);
    final inPlan =
        PlanningTime.calendarDate(
          reminderTime,
          widget.zone,
        ).difference(today).inDays <
        30;
    final canRemind =
        !widget.observer.example &&
        (window.conditions == 'good' ||
            (forecastPending && window.conditions == 'unknown')) &&
        inPlan &&
        reminderTime.isAfter(now.add(const Duration(minutes: 12))) &&
        !reminderTime.isBefore(window.start) &&
        reminderTime.isBefore(window.end);
    final (accent, surface) = switch (window.conditions) {
      'good' => (const Color(0xFFC1DBC9), const Color(0xFF303B35)),
      'uncertain' => (const Color(0xFFE3C497), const Color(0xFF44382F)),
      'poor' => (const Color(0xFFF5B5BE), const Color(0xFF4A2C36)),
      _ => (const Color(0xFFD4C4B6), const Color(0xFF3C3F43)),
    };
    final lightColor = switch (window.light) {
      'daylight' => const Color(0xFFF0D1A4),
      'twilight' => const Color(0xFFE2BAC8),
      _ => const Color(0xFFD2CCD4),
    };
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: accent.withValues(alpha: .27)),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [surface, const Color(0xFF252529)]),
          border: Border(left: BorderSide(color: accent, width: 3)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _ConditionLabel(label, accent),
                  _ConditionLabel(light, lightColor),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                t.suggestedTime,
                style: const TextStyle(color: Color(0xFFD8C7BA), fontSize: 12),
              ),
              Text(local(best), style: Theme.of(context).textTheme.titleSmall),
              Text(
                PlanningTime.utc(best, language),
                style: const TextStyle(color: Color(0xFFD8C7BA), fontSize: 12),
              ),
              const SizedBox(height: 8),
              Text(
                '${local(window.start)} – ${local(window.end)}',
                style: const TextStyle(color: Color(0xFFE5D8CE), fontSize: 12),
              ),
              const SizedBox(height: 8),
              if (radiant) Text(t.forecastRadiant),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  if (sector != null)
                    _ObservationMetric(
                      t.azimuthLabel,
                      '$sector · ${locale.formatDecimal(azimuth!.round())}°',
                    ),
                  _ObservationMetric(
                    t.altitudeLabel,
                    '${locale.formatDecimal(window.altitude.round())}°',
                  ),
                  if (window.cloud case final cloud?)
                    _ObservationMetric(
                      t.observingCloudCover,
                      '${locale.formatDecimal(cloud.round())}%',
                    ),
                ],
              ),
              if (radiant) Text(t.forecastMeteorSky),
              Wrap(
                spacing: 10,
                runSpacing: 6,
                children: [
                  if (!radiant || azimuth != null)
                    TextButton.icon(
                      icon: const Icon(Icons.north_east),
                      label: Text(t.focusTarget),
                      onPressed: () {
                        if (!radiant) {
                          openPlannedSky(context, ref, window.target, best);
                          return;
                        }
                        ref
                            .read(plannedSkyDirectionProvider.notifier)
                            .request(
                              ViewPose.horizon(azimuth!, window.altitude),
                            );
                        ref.read(skyInstantProvider.notifier).select(best);
                        context.go('/');
                      },
                    ),
                  if (canRemind)
                    TextButton.icon(
                      icon: const Icon(Icons.notifications_outlined),
                      label: Text(t.forecastNotifyClear),
                      onPressed: () => showReminderEditor(
                        context,
                        ref,
                        title: name,
                        targetId: window.id,
                        instant: reminderTime,
                        weatherSite: _site,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoonPhaseCard extends StatelessWidget {
  const _MoonPhaseCard({
    required this.title,
    required this.fraction,
    required this.illuminated,
    required this.time,
  });

  final String title, illuminated, time;
  final double fraction;

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    const muted = Color(0xFFD8C7BA);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF685358)),
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xFF4E3039), Color(0xFF292629)],
        ),
      ),
      child: Row(
        children: [
          ExcludeSemantics(
            child: SizedBox.square(
              dimension: 64,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox.expand(
                    child: CircularProgressIndicator(
                      value: fraction.clamp(0, 1).toDouble(),
                      strokeWidth: 3,
                      color: const Color(0xFFD8B68A),
                      backgroundColor: const Color(0xFF685358),
                    ),
                  ),
                  const SizedBox.square(
                    dimension: 48,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          center: Alignment(-.35, -.45),
                          colors: [Color(0xFFD1C6BE), Color(0xFF766967)],
                        ),
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            top: 12,
                            left: 12,
                            child: Icon(
                              Icons.circle,
                              size: 7,
                              color: Color(0xFF9D8F86),
                            ),
                          ),
                          Positioned(
                            top: 24,
                            right: 9,
                            child: Icon(
                              Icons.circle,
                              size: 11,
                              color: Color(0xFF8E8079),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text.observingMoonPhase,
                  style: const TextStyle(color: muted, fontSize: 12),
                ),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: const Color(0xFFFCF1D8),
                  ),
                ),
                Text(illuminated),
                Text(time, style: const TextStyle(color: muted, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ConditionLabel extends StatelessWidget {
  const _ConditionLabel(this.text, this.color);
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: const Color(0x66201A1C),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Text(text, style: TextStyle(color: color, fontSize: 12)),
    ),
  );
}

class _ObservationMetric extends StatelessWidget {
  const _ObservationMetric(this.label, this.value);
  final String label, value;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: const Color(0x66201A1C),
      borderRadius: BorderRadius.circular(9),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Color(0xFFD8C7BA), fontSize: 12),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    ),
  );
}
