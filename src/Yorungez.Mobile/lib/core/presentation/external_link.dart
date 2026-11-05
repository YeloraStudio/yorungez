import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../l10n/generated/app_localizations.dart';

bool safeExternalUri(Uri uri) =>
    uri.scheme == 'https' && uri.host.isNotEmpty && uri.userInfo.isEmpty;
final externalOpenerProvider = Provider<Future<bool> Function(Uri)>(
  (ref) =>
      (uri) => launchUrl(uri, mode: LaunchMode.externalApplication),
);

class ExternalLink extends ConsumerWidget {
  const ExternalLink({
    super.key,
    required this.url,
    this.label,
    this.small = false,
  });
  final String url;
  final String? label;
  final bool small;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uri = Uri.tryParse(url), t = AppLocalizations.of(context);
    return TextButton.icon(
      style: TextButton.styleFrom(
        alignment: Alignment.centerLeft,
        textStyle: small ? const TextStyle(fontSize: 12) : null,
      ),
      onPressed: () async {
        var opened = false;
        try {
          if (uri != null && safeExternalUri(uri)) {
            opened = await ref.read(externalOpenerProvider)(uri);
          }
        } catch (_) {
          /* Safe UI error, no URL/token logging. */
        }
        if (!opened && context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(t.linkUnavailable)));
        }
      },
      icon: const Icon(Icons.open_in_new, size: 16),
      label: Text(label ?? url, softWrap: true),
    );
  }
}
