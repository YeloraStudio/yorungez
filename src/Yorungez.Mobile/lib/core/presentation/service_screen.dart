import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../l10n/generated/app_localizations.dart';
import '../api/yorungez_api.dart';

class ServiceScreen extends ConsumerStatefulWidget {
  const ServiceScreen({super.key});
  @override
  ConsumerState<ServiceScreen> createState() => _ServiceScreenState();
}

class _ServiceScreenState extends ConsumerState<ServiceScreen> {
  bool _busy = false;
  bool _success = false;
  ServiceFailureKind? _failure;

  Future<void> _check() async {
    setState(() {
      _busy = true;
      _success = false;
      _failure = null;
    });
    try {
      await ref
          .read(apiProvider)
          .checkStatus(ref.read(localeProvider).languageCode);
      if (mounted) setState(() => _success = true);
    } on ServiceFailure catch (error) {
      if (mounted) setState(() => _failure = error.kind);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    final message = switch (_failure) {
      ServiceFailureKind.network => text.networkError,
      ServiceFailureKind.timeout => text.timeoutError,
      ServiceFailureKind.server => text.serverError,
      ServiceFailureKind.protocol => text.protocolError,
      null => _success ? text.connected : '',
    };
    return Scaffold(
      appBar: AppBar(title: Text(text.connection)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Icon(Icons.dns_outlined, size: 44),
            const SizedBox(height: 24),
            Text(
              text.connectionDescription,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _busy ? null : _check,
              child: Text(text.checkConnection),
            ),
            if (_busy)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
            if (message.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 24),
                child: Semantics(liveRegion: true, child: Text(message)),
              ),
          ],
        ),
      ),
    );
  }
}
