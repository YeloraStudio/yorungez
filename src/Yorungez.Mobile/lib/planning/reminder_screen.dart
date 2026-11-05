import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../account/account_models.dart';
import '../account/notebook_screen.dart' show newNoteId;
import '../account/account_widgets.dart';
import '../app/providers.dart';
import '../l10n/generated/app_localizations.dart';
import 'planning_controls.dart';
import 'planning_time.dart';
import 'reminder_model.dart';
import 'event_catalogue.dart';
import '../catalogue/domain/sky_object.dart';

final remindersProvider = FutureProvider.autoDispose<List<EventReminder>>((
  ref,
) async {
  final state = ref.watch(
    accountStateProvider.select((s) => (s.user?.id, s.epoch)),
  );
  if (state.$1 == null) {
    throw const AccountFailure(AccountFailureKind.unauthorized);
  }
  final data = objectMap(
    await ref.read(accountSessionProvider).authorized('notebook/reminders'),
  );
  if (data['userId'] != state.$1 || data['reminders'] is! List) {
    throw const AccountFailure(AccountFailureKind.changed);
  }
  return (data['reminders'] as List).map(EventReminder.decode).toList();
});

String reminderError(AppLocalizations t, Object error) {
  if (error is AccountFailure) {
    return switch (error.code) {
      'Reminders.InvalidTime' => t.reminderInvalidTime,
      'Reminders.InvalidEvent' => t.reminderInvalidEvent,
      'Reminders.Conflict' => t.reminderConflict,
      'Reminders.Limit' => t.reminderLimit,
      _ => accountError(t, error),
    };
  }
  return accountError(t, error);
}

String reminderTitle(AppLocalizations t, EventReminder r, String language) {
  final target =
      solarObjects
          .where((o) => o.id == r.targetId)
          .firstOrNull
          ?.name(language) ??
      r.targetId;
  if (r.eventId == null) return '$target · ${t.observingTime}';
  const kinds = [
    'new-moon',
    'first-quarter',
    'full-moon',
    'last-quarter',
    'march-equinox',
    'june-solstice',
    'september-equinox',
    'december-solstice',
    'opposition',
    'greatest-elongation',
    'inferior-conjunction',
    'superior-conjunction',
  ];
  final kind = kinds.where((k) => r.eventId!.startsWith('$k-')).firstOrNull;
  if (kind == null) return r.title;
  return '$target · ${SkyEvent(r.eventId!, kind, r.targetId, r.instant, '', '').title(t)}';
}

String reminderStatus(AppLocalizations t, String status) => switch (status) {
  'scheduled' => t.reminderScheduled,
  'sending' => t.reminderSending,
  'sent' => t.reminderSent,
  'failed' => t.reminderFailed,
  'expired' => t.reminderExpired,
  'cancelled' => t.reminderCancelled,
  'suppressed' => t.reminderSuppressed,
  _ => t.serverError,
};

Future<void> showReminderEditor(
  BuildContext context,
  WidgetRef ref, {
  required String title,
  required String targetId,
  required DateTime instant,
  String? eventId,
}) async {
  final owner = ref.read(accountStateProvider).user?.id;
  if (owner == null) {
    context.push('/account');
    return;
  }
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _ReminderEditor(
      owner: owner,
      title: title,
      targetId: targetId,
      instant: instant,
      eventId: eventId,
      zone: ref.read(planningZoneProvider),
    ),
  );
}

class _ReminderEditor extends ConsumerStatefulWidget {
  const _ReminderEditor({
    required this.owner,
    required this.title,
    required this.targetId,
    required this.instant,
    required this.zone,
    this.eventId,
  });
  final String owner, title, targetId, zone;
  final String? eventId;
  final DateTime instant;
  @override
  ConsumerState<_ReminderEditor> createState() => _ReminderEditorState();
}

class _ReminderEditorState extends ConsumerState<_ReminderEditor> {
  final _id = newNoteId();
  int _lead = 30;
  bool _busy = false;
  Object? _failure;
  Future<void> _save() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _failure = null;
    });
    final session = ref.read(accountSessionProvider);
    try {
      if (session.state.user?.id != widget.owner) {
        throw const AccountFailure(AccountFailureKind.changed);
      }
      EventReminder.decode(
        await session.authorized(
          'notebook/reminders',
          method: 'POST',
          body: {
            'id': _id,
            'expectedRevision': 0,
            'eventId': widget.eventId,
            'targetId': widget.targetId,
            'instantUtc': widget.instant.toUtc().toIso8601String(),
            'timeZoneId': widget.zone,
            'leadMinutes': _lead,
          },
        ),
      );
      if (!mounted) return;
      ref.invalidate(remindersProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).reminderSaved)),
      );
      if (ModalRoute.of(context)?.isCurrent == true) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => _failure = e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context),
        language = ref.watch(localeProvider).languageCode;
    final choices = <(int, String)>[
      (0, t.atEventTime),
      (10, t.tenMinutesBefore),
      (30, t.thirtyMinutesBefore),
      (60, t.oneHourBefore),
      (180, t.threeHoursBefore),
      (1440, t.oneDayBefore),
    ];
    final valid = widget.instant
        .subtract(Duration(minutes: _lead))
        .isAfter(DateTime.now().toUtc().add(const Duration(minutes: 2)));
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        24 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              t.emailReminder,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Text(PlanningTime.label(widget.instant, widget.zone, language)),
            Text(widget.zone),
            Text(PlanningTime.utc(widget.instant, language)),
            const SizedBox(height: 20),
            ChoiceField<int>(
              label: t.remindMe,
              valueLabel: choices.firstWhere((c) => c.$1 == _lead).$2,
              choices: choices,
              enabled: !_busy,
              onSelected: (value) => setState(() => _lead = value),
            ),
            const SizedBox(height: 16),
            Text(t.reminderDeliveryHelp),
            const SizedBox(height: 16),
            if (!valid)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(t.reminderInvalidTime),
              ),
            if (_failure != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(reminderError(t, _failure!)),
              ),
            FilledButton.icon(
              onPressed: _busy || !valid ? null : _save,
              icon: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.notifications_active_outlined),
              label: Text(t.scheduleReminder),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(t.close),
            ),
          ],
        ),
      ),
    );
  }
}

class ReminderScreen extends ConsumerStatefulWidget {
  const ReminderScreen({super.key});
  @override
  ConsumerState<ReminderScreen> createState() => _ReminderScreenState();
}

class _ReminderScreenState extends ConsumerState<ReminderScreen> {
  String? _busy;
  Future<void> _cancel(EventReminder reminder) async {
    if (_busy != null) return;
    setState(() => _busy = reminder.id);
    try {
      await ref
          .read(accountSessionProvider)
          .authorized(
            'notebook/reminders',
            method: 'POST',
            body: reminder.cancelInput(),
          );
      if (mounted) ref.invalidate(remindersProvider);
    } catch (e) {
      if (mounted) {
        ref.invalidate(remindersProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(reminderError(AppLocalizations.of(context), e)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context),
        owner = ref.watch(accountStateProvider).user,
        language = ref.watch(localeProvider).languageCode;
    return Scaffold(
      appBar: AppBar(
        title: Text(t.reminders),
        actions: [
          IconButton(
            tooltip: t.retry,
            onPressed: () => ref.invalidate(remindersProvider),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: owner == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(t.reminderAccountRequired),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => context.push('/account'),
                      child: Text(t.signIn),
                    ),
                  ],
                ),
              ),
            )
          : ref
                .watch(remindersProvider)
                .when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(reminderError(t, e)),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: () => ref.invalidate(remindersProvider),
                            child: Text(t.retry),
                          ),
                        ],
                      ),
                    ),
                  ),
                  data: (rows) => ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      Text(t.reminderDeliveryHelp),
                      const SizedBox(height: 12),
                      Text(t.pushLater),
                      const SizedBox(height: 20),
                      if (rows.isEmpty) Text(t.remindersEmpty),
                      for (final r in rows)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  reminderTitle(t, r, language),
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  PlanningTime.label(
                                    r.instant,
                                    r.zone,
                                    language,
                                  ),
                                ),
                                Text(r.zone),
                                Text(PlanningTime.utc(r.instant, language)),
                                const SizedBox(height: 10),
                                Text(
                                  '${t.emailReminder} · ${reminderStatus(t, r.status)}',
                                ),
                                Text(
                                  '${t.reminderSendTime}: ${PlanningTime.label(r.due, r.zone, language)}',
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 12,
                                  children: [
                                    OutlinedButton(
                                      onPressed: () {
                                        ref
                                            .read(skyInstantProvider.notifier)
                                            .select(r.instant);
                                        ref
                                            .read(skyFocusProvider.notifier)
                                            .request(r.targetId);
                                        context.go('/');
                                      },
                                      child: Text(t.focusTarget),
                                    ),
                                    if (r.status == 'scheduled')
                                      TextButton(
                                        onPressed: _busy != null
                                            ? null
                                            : () => _cancel(r),
                                        child: Text(
                                          _busy == r.id
                                              ? t.loading
                                              : t.cancelReminder,
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }
}
