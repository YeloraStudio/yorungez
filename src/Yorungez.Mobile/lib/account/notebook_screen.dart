import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../app/providers.dart';
import '../l10n/generated/app_localizations.dart';
import 'account_models.dart';
import 'account_widgets.dart';

String newNoteId() {
  final bytes = List.generate(16, (_) => Random.secure().nextInt(256));
  bytes[6] = (bytes[6] & 15) | 64;
  bytes[8] = (bytes[8] & 63) | 128;
  final hex = bytes.map((v) => v.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}

String entryKind(AppLocalizations t, String kind) => switch (kind) {
  'favorite' => t.favoriteRecord,
  'observation' => t.observationRecord,
  'place' => t.placeRecord,
  _ => t.noteRecord,
};

class NotebookScreen extends ConsumerWidget {
  const NotebookScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context),
        user = ref.watch(accountStateProvider).user;
    return Scaffold(
      appBar: AppBar(
        title: Text(t.myNotebook),
        actions: [
          if (user != null)
            IconButton(
              tooltip: t.retry,
              onPressed: () => ref.invalidate(notebookProvider),
              icon: const Icon(Icons.refresh),
            ),
        ],
      ),
      body: SafeArea(
        child: user == null
            ? SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(t.notebookRequiresAccount),
                    const SizedBox(height: 24),
                    const AccountMenu(),
                  ],
                ),
              )
            : ref
                  .watch(notebookProvider)
                  .when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (error, _) => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(accountError(t, error)),
                            const SizedBox(height: 16),
                            TextButton(
                              onPressed: () => ref.invalidate(notebookProvider),
                              child: Text(t.retry),
                            ),
                          ],
                        ),
                      ),
                    ),
                    data: (entries) => ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        Text(t.serverNotebookHelp),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: () => showNoteEditor(context, ref),
                          icon: const Icon(Icons.add),
                          label: Text(t.newNote),
                        ),
                        const SizedBox(height: 20),
                        if (entries.isEmpty) Text(t.emptyNotebook),
                        for (final entry in entries)
                          Card(
                            child: ListTile(
                              leading: Icon(switch (entry.kind) {
                                'favorite' => Icons.star_outline,
                                'observation' => Icons.visibility_outlined,
                                'place' => Icons.location_on_outlined,
                                _ => Icons.notes_outlined,
                              }),
                              title: Text(
                                entry.target?['name'] as String? ??
                                    (entry.body.isEmpty
                                        ? entryKind(t, entry.kind)
                                        : entry.body),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(entryKind(t, entry.kind)),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () =>
                                  _detail(context, ref, entry, user.id),
                            ),
                          ),
                      ],
                    ),
                  ),
      ),
    );
  }

  Future<void> _detail(
    BuildContext parentContext,
    WidgetRef parentRef,
    NotebookEntry entry,
    String owner,
  ) => showModalBottomSheet<void>(
    context: parentContext,
    useSafeArea: true,
    isScrollControlled: true,
    builder: (context) => Consumer(
      builder: (context, ref, _) {
        final t = AppLocalizations.of(context);
        if (ref.watch(accountStateProvider).user?.id != owner) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Text(t.accountChanged),
          );
        }
        final location = entry.location;
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                entryKind(t, entry.kind),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              if (entry.target != null) Text(entry.target!['name'] as String),
              if (entry.body.isNotEmpty) SelectableText(entry.body),
              for (final key in [
                'createdAtUtc',
                'updatedAtUtc',
                'observedAtUtc',
                'instantUtc',
              ])
                if (entry.data[key] != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      '${switch (key) {
                        'createdAtUtc' => t.createdAt,
                        'updatedAtUtc' => t.updatedAt,
                        'instantUtc' => t.eventTime,
                        _ => t.observedAt,
                      }}: ${DateFormat("yyyy-MM-dd HH:mm 'UTC'").format(DateTime.parse(entry.data[key] as String).toUtc())}',
                    ),
                  ),
              if (location != null) ...[
                const SizedBox(height: 12),
                Text(location['placeName'] as String? ?? t.placeRecord),
                SelectableText(
                  '${location['latitude']}, ${location['longitude']}',
                ),
              ],
              if (entry.target != null) ...[
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () {
                    if (entry.data['instantUtc'] is String) {
                      ref
                          .read(skyInstantProvider.notifier)
                          .select(
                            DateTime.parse(entry.data['instantUtc'] as String),
                          );
                    }
                    ref
                        .read(skyFocusProvider.notifier)
                        .request(entry.target!['id'] as String);
                    Navigator.pop(context);
                    context.go('/');
                  },
                  child: Text(t.focusTarget),
                ),
              ],
              if (entry.kind == 'note') ...[
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    showNoteEditor(parentContext, parentRef, entry: entry);
                  },
                  child: Text(t.editNote),
                ),
              ],
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(t.close),
              ),
            ],
          ),
        );
      },
    ),
  );
}

Future<void> showNoteEditor(
  BuildContext context,
  WidgetRef ref, {
  NotebookEntry? entry,
  Map<String, dynamic>? target,
  DateTime? instantUtc,
}) async {
  final owner = ref.read(accountStateProvider).user?.id;
  if (owner == null) {
    context.push('/account');
    return;
  }
  await showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    builder: (_) => _NoteEditor(
      owner: owner,
      entry: entry,
      target: target,
      instantUtc: instantUtc,
    ),
  );
}

class _NoteEditor extends ConsumerStatefulWidget {
  const _NoteEditor({
    required this.owner,
    this.entry,
    this.target,
    this.instantUtc,
  });
  final DateTime? instantUtc;
  final String owner;
  final NotebookEntry? entry;
  final Map<String, dynamic>? target;
  @override
  ConsumerState<_NoteEditor> createState() => _NoteEditorState();
}

class _NoteEditorState extends ConsumerState<_NoteEditor> {
  late final TextEditingController _body;
  late final String _id;
  bool _busy = false;
  Object? _failure;
  @override
  void initState() {
    super.initState();
    _body = TextEditingController(text: widget.entry?.body ?? '');
    _id = widget.entry?.id ?? newNoteId();
  }

  @override
  void dispose() {
    _body.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy) return;
    if (_body.text.trim().isEmpty) {
      setState(
        () => _failure = const AccountFailure(AccountFailureKind.validation),
      );
      return;
    }
    setState(() {
      _busy = true;
      _failure = null;
    });
    try {
      if (ref.read(accountStateProvider).user?.id != widget.owner) {
        throw const AccountFailure(AccountFailureKind.changed);
      }
      final entry = widget.entry;
      final payload = entry == null
          ? <String, dynamic>{
              'id': _id,
              'kind': 'note',
              'expectedRevision': 0,
              'target': widget.target,
              'instantUtc': widget.instantUtc?.toUtc().toIso8601String(),
            }
          : <String, dynamic>{
              ...entry.data,
              'expectedRevision': entry.revision,
            };
      payload['body'] = _body.text;
      await ref.read(accountSessionProvider).saveEntry(payload);
      if (mounted && ModalRoute.of(context)?.isCurrent == true) {
        Navigator.pop(context);
      }
    } on AccountFailure catch (error) {
      if (mounted) setState(() => _failure = error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    if (ref.watch(accountStateProvider).user?.id != widget.owner) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Text(t.accountChanged),
      );
    }
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        MediaQuery.viewInsetsOf(context).bottom + 32,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.entry == null ? t.newNote : t.editNote,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          Text(t.serverNotebookHelp),
          const SizedBox(height: 16),
          TextField(
            controller: _body,
            enabled: !_busy,
            maxLength: 8000,
            minLines: 4,
            maxLines: 10,
            decoration: InputDecoration(labelText: t.noteBody),
          ),
          if (_failure != null) Text(accountError(t, _failure!)),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _busy ? null : _save,
            child: Text(t.saveNote),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _busy ? null : () => Navigator.pop(context),
            child: Text(t.close),
          ),
        ],
      ),
    );
  }
}
