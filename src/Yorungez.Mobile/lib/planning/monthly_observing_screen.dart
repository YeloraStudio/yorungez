import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../app/providers.dart';
import '../core/presentation/external_link.dart';
import '../l10n/generated/app_localizations.dart';
import 'planning_controls.dart';
import 'planning_time.dart';
import 'planning_surface.dart';
import 'weather_opportunities.dart';
import 'weather_opportunity.dart';

class MonthlyObservingScreen extends ConsumerStatefulWidget {
  const MonthlyObservingScreen({super.key});

  @override
  ConsumerState<MonthlyObservingScreen> createState() =>
      _MonthlyObservingScreenState();
}

class _MonthlyObservingScreenState
    extends ConsumerState<MonthlyObservingScreen> {
  DateTime? _selected;
  String _target = 'moon';

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final zone = ref.watch(planningZoneProvider);
    final observer = ref.watch(
      skyFrameProvider.select((frame) => frame?.observer),
    );
    final today = PlanningTime.calendarDate(DateTime.now(), zone);
    final modelLast = DateTime.utc(2035, 12, 30);
    final plannedLast = today.add(const Duration(days: 29));
    final last = plannedLast.isAfter(modelLast) ? modelLast : plannedLast;
    final selected = _selected ?? today;
    final date = selected.isBefore(today)
        ? today
        : selected.isAfter(last)
        ? last
        : selected;
    final bounds = PlanningTime.calendarDay(date, zone);
    final targetOptions = [
      ('', text.observingAllTargets),
      for (final id in weatherBodies) (id, weatherTargetName(text, id, locale)),
      ('lunar-eclipse', text.observingLunarEclipses),
      for (final id in ['geminids', 'quadrantids', 'perseids'])
        (id, weatherTargetName(text, id, locale)),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(text.observingMonthTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _ObservingBanner(
              first: today,
              last: last,
              text: text,
              locale: locale,
            ),
            const SizedBox(height: 16),
            if (observer == null)
              Text(text.planningLocationNeeded)
            else if (today.isAfter(last))
              Text(text.forecastNoOpportunity)
            else ...[
              PlanningSurface(
                padding: const EdgeInsets.all(12),
                highlighted: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          tooltip: text.observingPreviousDay,
                          onPressed: date == today
                              ? null
                              : () => setState(
                                  () => _selected = date.subtract(
                                    const Duration(days: 1),
                                  ),
                                ),
                          icon: const Icon(Icons.chevron_left),
                        ),
                        Expanded(
                          child: PlanningDateButton(
                            value: date,
                            firstDate: today,
                            lastDate: last,
                            onSelected: (value) =>
                                setState(() => _selected = value),
                          ),
                        ),
                        IconButton(
                          tooltip: text.observingNextDay,
                          onPressed: date == last
                              ? null
                              : () => setState(
                                  () => _selected = date.add(
                                    const Duration(days: 1),
                                  ),
                                ),
                          icon: const Icon(Icons.chevron_right),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ChoiceField<String>(
                      label: text.observingTarget,
                      valueLabel: targetOptions
                          .firstWhere((option) => option.$1 == _target)
                          .$2,
                      choices: targetOptions,
                      onSelected: (value) => setState(() => _target = value),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              WeatherOpportunities(
                observer: observer,
                zone: zone,
                start: bounds.start,
                end: bounds.end,
                target: _target.isEmpty ? null : _target,
                monthly: true,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ObservingBanner extends StatelessWidget {
  const _ObservingBanner({
    required this.first,
    required this.last,
    required this.text,
    required this.locale,
  });

  final DateTime first, last;
  final AppLocalizations text;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final label = DateFormat.MMMd(locale);
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: DecoratedBox(
        decoration: const BoxDecoration(color: Color(0xFF201C20)),
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/generated/images/dso-ngc0224.jpg',
                fit: BoxFit.cover,
                alignment: const Alignment(0, -.35),
                excludeFromSemantics: true,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x33782838),
                      Color(0xEB251E23),
                      Color(0xFF251E23),
                    ],
                    stops: [0, .70, 1],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 60, 16, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!last.isBefore(first))
                    Text(
                      '${label.format(first)} – ${label.format(last)}',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: const Color(0xFFF7F1E6),
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  const SizedBox(height: 6),
                  Text(
                    text.observingMonthIntro,
                    style: const TextStyle(
                      color: Color(0xFFF7F1E6),
                      height: 1.4,
                    ),
                  ),
                  ExternalLink(
                    url:
                        'https://commons.wikimedia.org/wiki/File:M31-Andromede-16-09-2023-Hamois.jpg',
                    label:
                        '${text.observingArchiveCredit} · Lviatour · CC BY-SA 2.5',
                    small: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
