import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../catalogue/data/catalogue_repository.dart';
import '../../l10n/generated/app_localizations.dart';

class CatalogueState extends ConsumerWidget {
  const CatalogueState({super.key, required this.builder});
  final Widget Function(Catalogue catalogue) builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = AppLocalizations.of(context);
    return ref
        .watch(catalogueProvider)
        .when(
          data: builder,
          loading: () => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 20),
                Text(text.loading),
              ],
            ),
          ),
          error: (_, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_off_outlined, size: 36),
                  const SizedBox(height: 16),
                  Text(text.loadError, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => ref.invalidate(catalogueProvider),
                    child: Text(text.retry),
                  ),
                ],
              ),
            ),
          ),
        );
  }
}
