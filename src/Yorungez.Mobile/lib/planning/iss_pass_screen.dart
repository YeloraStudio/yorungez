import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../app/providers.dart';
import '../catalogue/domain/sky_object.dart';
import '../core/presentation/external_link.dart';
import '../l10n/generated/app_localizations.dart';
import '../sky/data/iss_elements.dart';
import '../sky/domain/sky_geometry.dart';
import 'iss_passes.dart';
import 'observing_guide.dart';
import 'observing_guide_screen.dart';
import 'planning_controls.dart';
import 'planning_time.dart';
import 'reminder_screen.dart';

class IssPassScreen extends ConsumerStatefulWidget {
  const IssPassScreen({super.key});

  @override
  ConsumerState<IssPassScreen> createState() => _IssPassScreenState();
}

class _IssPassScreenState extends ConsumerState<IssPassScreen> {
  SkyObserver? _observer;
  Future<(IssElements, List<IssPass>)?>? _prediction;

  Future<(IssElements, List<IssPass>)?> _load(SkyObserver observer) async {
    final now = DateTime.now().toUtc();
    final packet = await ref.read(issRepositoryProvider).load(now);
    final start = DateTime.now().toUtc();
    if (!mounted || packet == null || !packet.usable(start)) return null;
    final worker = await ref.read(skyWorkerProvider.future);
    return (packet, await worker.issPasses(observer, start, packet.values));
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final language = Localizations.localeOf(context).languageCode;
    final zone = ref.watch(planningZoneProvider);
    final observer = ref.watch(
      skyFrameProvider.select((frame) => frame?.observer),
    );
    if (observer != null && observer != _observer) {
      _observer = observer;
      _prediction = _load(observer);
    }
    return Scaffold(
      appBar: AppBar(title: Text(t.issPassesTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(t.issPassesIntro),
            const SizedBox(height: 12),
            if (observer == null)
              Text(t.planningLocationNeeded)
            else ...[
              if (observer.example) Text(t.guideExampleSite),
              FutureBuilder<(IssElements, List<IssPass>)?>(
                key: ValueKey(_prediction),
                future: _prediction,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const LinearProgressIndicator();
                  }
                  final prediction = snapshot.data;
                  if (snapshot.hasError || prediction == null) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (prediction == null && !snapshot.hasError)
                          Text(t.issFreshnessNeeded),
                        PlanningError(
                          onRetry: () => setState(() => _observer = null),
                        ),
                      ],
                    );
                  }
                  final (packet, passes) = prediction;
                  final upcoming = passes.where(
                    (p) => p.end.isAfter(DateTime.now().toUtc()),
                  );
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        '${t.issElementsEpoch} · ${PlanningTime.utc(packet.epoch, language)}',
                      ),
                      Text(
                        '${t.issPredictionUntil} · ${PlanningTime.label(packet.expires, zone, language)}',
                      ),
                      const SizedBox(height: 12),
                      if (upcoming.isEmpty) Text(t.issNoPasses),
                      for (final pass in upcoming.take(8))
                        _PassCard(pass: pass, zone: zone),
                    ],
                  );
                },
              ),
            ],
            const SizedBox(height: 12),
            const ExternalLink(
              url: 'https://spotthestation.nasa.gov/',
              label: 'NASA Spot the Station',
            ),
          ],
        ),
      ),
    );
  }
}

class _PassCard extends ConsumerWidget {
  const _PassCard({required this.pass, required this.zone});
  final IssPass pass;
  final String zone;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final language = Localizations.localeOf(context).languageCode;
    final number = NumberFormat.decimalPatternDigits(
      locale: language,
      decimalDigits: 0,
    );
    final now = DateTime.now().toUtc();
    String local(DateTime instant) =>
        PlanningTime.label(instant, zone, language, seconds: true);
    String direction(GuideDirection value) =>
        '${directionName(t, value.azimuth)} · ${number.format(value.altitude)}°';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              local(pass.start),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(PlanningTime.utc(pass.start, language)),
            const SizedBox(height: 8),
            Text('${t.issAppears} · ${direction(pass.appears)}'),
            Text(
              '${t.issHighest} · ${local(pass.peak)} · ${direction(pass.highest)}',
            ),
            Text(
              '${t.issDisappears} · ${local(pass.end)} · ${direction(pass.disappears)}',
            ),
            Text(
              t.issDuration(
                number.format(pass.end.difference(pass.start).inSeconds),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: () =>
                      openPlannedSky(context, ref, issObject.id, pass.peak),
                  icon: const Icon(Icons.north_east),
                  label: Text(t.focusTarget),
                ),
                if (pass.start.isAfter(now.add(const Duration(minutes: 2))))
                  OutlinedButton.icon(
                    onPressed: () => showReminderEditor(
                      context,
                      ref,
                      title: issObject.name(language),
                      targetId: issObject.id,
                      instant: pass.start,
                    ),
                    icon: const Icon(Icons.notifications_active_outlined),
                    label: Text(t.remindMe),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
