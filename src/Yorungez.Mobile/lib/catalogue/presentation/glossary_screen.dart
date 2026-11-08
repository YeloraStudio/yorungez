import 'package:flutter/material.dart';

import '../../core/presentation/catalogue_state.dart';
import '../../core/presentation/external_link.dart';
import '../../l10n/generated/app_localizations.dart';
import '../domain/glossary_term.dart';
import '../domain/sky_object.dart';

class GlossaryScreen extends StatefulWidget {
  const GlossaryScreen({super.key, this.termId});

  final String? termId;

  @override
  State<GlossaryScreen> createState() => _GlossaryScreenState();
}

class _GlossaryScreenState extends State<GlossaryScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final language = Localizations.localeOf(context).languageCode;
    return Scaffold(
      appBar: AppBar(title: Text(t.glossaryTitle)),
      body: SafeArea(
        child: CatalogueState(
          builder: (catalogue) {
            final selected = widget.termId;
            final terms =
                [
                  for (final term in catalogue.glossary)
                    if (_query.isEmpty || term.matches(_query)) term,
                ]..sort((a, b) {
                  if (a.id == selected) return b.id == selected ? 0 : -1;
                  if (b.id == selected) return 1;
                  return normalizeSearch(
                    a.name(language),
                  ).compareTo(normalizeSearch(b.name(language)));
                });
            return CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  sliver: SliverToBoxAdapter(
                    child: TextField(
                      onChanged: (value) =>
                          setState(() => _query = normalizeSearch(value)),
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search),
                        hintText: t.glossarySearch,
                      ),
                    ),
                  ),
                ),
                if (terms.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(t.emptySearch),
                    ),
                  ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                  sliver: SliverList.builder(
                    itemCount: terms.length,
                    itemBuilder: (context, index) => _TermTile(
                      key: ValueKey(terms[index].id),
                      term: terms[index],
                      language: language,
                      expanded: selected == terms[index].id,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TermTile extends StatelessWidget {
  const _TermTile({
    super.key,
    required this.term,
    required this.language,
    required this.expanded,
  });

  final GlossaryTerm term;
  final String language;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final name = term.name(language);
    final abbreviation = term.abbreviationFor(language);
    return Card(
      child: ExpansionTile(
        key: PageStorageKey(term.id),
        initiallyExpanded: expanded,
        title: Text(abbreviation == null ? name : '$name ($abbreviation)'),
        subtitle: Text(term.definition(language)),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (index, url) in term.sources.indexed)
            ExternalLink(
              url: url,
              label:
                  '${t.sources} ${index + 1} · ${Uri.tryParse(url)?.host ?? ''}',
              small: true,
            ),
        ],
      ),
    );
  }
}
