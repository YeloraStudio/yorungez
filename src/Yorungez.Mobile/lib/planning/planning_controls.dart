import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
import '../app/providers.dart';
import '../l10n/generated/app_localizations.dart';
import 'planning_time.dart';

class ChoiceField<T> extends StatelessWidget {
  const ChoiceField({
    super.key,
    required this.label,
    required this.valueLabel,
    required this.choices,
    required this.onSelected,
    this.enabled = true,
  });
  final String label, valueLabel;
  final List<(T, String)> choices;
  final ValueChanged<T> onSelected;
  final bool enabled;
  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(18),
    onTap: !enabled
        ? null
        : () async {
            final value = await showModalBottomSheet<T>(
              context: context,
              useSafeArea: true,
              isScrollControlled: true,
              builder: (context) => SizedBox(
                height: MediaQuery.sizeOf(context).height * .65,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        label,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        children: [
                          for (final choice in choices)
                            ListTile(
                              title: Text(choice.$2),
                              onTap: () => Navigator.pop(context, choice.$1),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
            if (context.mounted && value != null) onSelected(value);
          },
    child: InputDecorator(
      decoration: InputDecoration(labelText: label, enabled: enabled),
      child: Row(
        children: [
          Expanded(child: Text(valueLabel)),
          const Icon(Icons.expand_more),
        ],
      ),
    ),
  );
}

class PlanningDateButton extends StatelessWidget {
  const PlanningDateButton({
    super.key,
    required this.value,
    required this.onSelected,
  });
  final DateTime value;
  final ValueChanged<DateTime> onSelected;
  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    icon: const Icon(Icons.calendar_today_outlined),
    label: Text(
      DateFormat.yMMMd(
        Localizations.localeOf(context).languageCode,
      ).format(value),
    ),
    onPressed: () async {
      final result = await showDialog<DateTime>(
        context: context,
        builder: (context) {
          var selected = value;
          return StatefulBuilder(
            builder: (context, setState) => AlertDialog(
              scrollable: true,
              contentPadding: const EdgeInsets.fromLTRB(8, 12, 8, 0),
              content: SizedBox(
                width: 340,
                height: 330,
                child: CalendarDatePicker(
                  initialDate: selected,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2035, 12, 30),
                  onDateChanged: (d) => setState(() => selected = d),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(AppLocalizations.of(context).close),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, selected),
                  child: Text(AppLocalizations.of(context).applyDate),
                ),
              ],
            ),
          );
        },
      );
      if (context.mounted && result != null) {
        onSelected(DateTime.utc(result.year, result.month, result.day));
      }
    },
  );
}

class TimeZoneScreen extends ConsumerStatefulWidget {
  const TimeZoneScreen({super.key});
  @override
  ConsumerState<TimeZoneScreen> createState() => _TimeZoneScreenState();
}

class _TimeZoneScreenState extends ConsumerState<TimeZoneScreen> {
  String _query = '';
  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context),
        selected = ref.watch(planningZoneProvider);
    PlanningTime.initialise();
    final zones = [
      'UTC',
      ...tz.timeZoneDatabase.locations.keys
          .where((s) => s.contains('/'))
          .toList()
        ..sort(),
    ];
    return Scaffold(
      appBar: AppBar(title: Text(t.timeZone)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text(t.zoneHelp),
                const SizedBox(height: 16),
                TextField(
                  decoration: InputDecoration(
                    labelText: t.searchTimeZone,
                    prefixIcon: const Icon(Icons.search),
                  ),
                  onChanged: (q) => setState(() => _query = q),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                for (final name in zones.where(
                  (s) => s.toLowerCase().contains(_query.toLowerCase()),
                ))
                  ListTile(
                    title: Text(name),
                    subtitle: Text(PlanningTime.offset(DateTime.now(), name)),
                    trailing: name == selected ? const Icon(Icons.check) : null,
                    onTap: () {
                      ref.read(planningZoneProvider.notifier).select(name);
                      Navigator.pop(context);
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
