import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import 'catalogue_state.dart';
import 'external_link.dart';

class SourcesScreen extends StatelessWidget {
  const SourcesScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(text.sources)),
      body: SafeArea(
        child: CatalogueState(
          builder: (catalogue) => ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(text.sourcesDescription),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => showLicensePage(
                  context: context,
                  applicationName: 'Yorungez',
                ),
                child: Text(text.softwareLicences),
              ),
              const SizedBox(height: 24),
              Text(text.sourceHyg),
              const SizedBox(height: 12),
              Text(text.sourceDso),
              const SizedBox(height: 12),
              Text(text.sourceConstellations),
              const SizedBox(height: 24),
              SelectableText(catalogue.version),
              for (final image in catalogue.images.values) ...[
                const Divider(height: 36),
                SelectableText('${image['credit']}\n${image['license']}'),
                ExternalLink(
                  url: image['sourceUrl'] as String,
                  label: text.imageSource,
                ),
                ExternalLink(
                  url: image['licenseUrl'] as String,
                  label: text.imageLicence,
                ),
              ],
              const Divider(height: 36),
              SelectableText(
                catalogue.notices,
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
