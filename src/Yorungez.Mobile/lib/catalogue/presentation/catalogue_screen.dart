import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/presentation/catalogue_state.dart';
import '../../l10n/generated/app_localizations.dart';
import '../data/catalogue_repository.dart';
import '../domain/sky_object.dart';

String kindLabel(AppLocalizations text, ObjectKind kind) => switch (kind) {
  ObjectKind.star => text.star,
  ObjectKind.deepSky => text.deepSky,
  ObjectKind.constellation => text.constellation,
  ObjectKind.solarSystem => text.solarSystemObject,
  ObjectKind.satellite => text.stationObject,
};

class CatalogueScreen extends ConsumerStatefulWidget {
  const CatalogueScreen({super.key, this.pickTarget = false});
  final bool pickTarget;
  @override
  ConsumerState<CatalogueScreen> createState() => _CatalogueScreenState();
}

class _CatalogueScreenState extends ConsumerState<CatalogueScreen> {
  final _search = TextEditingController();
  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    return Scaffold(
      drawer: const _Menu(),
      body: SafeArea(
        child: CatalogueState(
          builder: (catalogue) => _body(context, catalogue, text),
        ),
      ),
    );
  }

  Widget _body(
    BuildContext context,
    Catalogue catalogue,
    AppLocalizations text,
  ) {
    final language = ref.watch(localeProvider).languageCode;
    final query = _search.text;
    final matches = searchObjects(catalogue.objects, query);
    final featured = ['dso-ngc0224', 'hyg-32263', 'dso-ngc1976', 'con-ori'];
    final visible = query.isEmpty
        ? [
            ...featured.map(catalogue.find).whereType<SkyObject>(),
            ...catalogue.objects
                .where((item) => !featured.contains(item.id))
                .take(16),
          ]
        : matches.take(60).toList();
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Builder(
                      builder: (context) => IconButton(
                        tooltip: text.menu,
                        onPressed: () => Scaffold.of(context).openDrawer(),
                        icon: const Icon(Icons.menu_rounded),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text.rich(
                          TextSpan(
                            text: 'yorungez',
                            children: [
                              TextSpan(
                                text: '.',
                                style: TextStyle(color: Color(0xFFBF5265)),
                              ),
                            ],
                          ),
                          style: TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 26),
                Text(
                  text.catalogueTitle,
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  text.tagline,
                  style: const TextStyle(
                    color: Color(0xFFC9B6A6),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: text.searchHint,
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: query.isEmpty
                        ? null
                        : IconButton(
                            tooltip: text.clearSearch,
                            onPressed: () => setState(_search.clear),
                            icon: const Icon(Icons.close),
                          ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  query.isEmpty
                      ? text.objectsOffline(catalogue.objects.length)
                      : text.searchCount(matches.length),
                  style: const TextStyle(color: Color(0xFFC9B6A6)),
                ),
                const SizedBox(height: 18),
                if (query.isEmpty) _ArchiveBanner(text: text),
                if (visible.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Text(text.emptySearch),
                  ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 32),
          sliver: SliverList.builder(
            itemCount: visible.length,
            itemBuilder: (context, index) {
              final object = visible[index];
              return ListTile(
                key: ValueKey(object.id),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFF302A2D),
                  child: Icon(
                    object.kind == ObjectKind.star
                        ? Icons.auto_awesome_outlined
                        : object.kind == ObjectKind.constellation
                        ? Icons.polyline_outlined
                        : Icons.blur_circular,
                    color: const Color(0xFFC9B6A6),
                  ),
                ),
                title: Text(
                  object.name(language),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  '${kindLabel(text, object.kind)} · ${object.designation.isEmpty ? object.id : object.designation}',
                ),
                trailing: const Icon(Icons.arrow_forward_rounded, size: 20),
                onTap: () => widget.pickTarget
                    ? context.pop(object.id)
                    : context.push('/objects/${object.id}'),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ArchiveBanner extends StatelessWidget {
  const _ArchiveBanner({required this.text});
  final AppLocalizations text;
  @override
  Widget build(BuildContext context) => Semantics(
    label: '${text.archiveImage}: ${text.viewAll}',
    child: ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Stack(
        children: [
          ExcludeSemantics(
            child: Image.asset(
              'assets/generated/images/dso-ngc0224.jpg',
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const SizedBox(height: 180),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: .9),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 18,
            right: 18,
            bottom: 14,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text.viewAll,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${text.archiveImage} · Lviatour · CC BY-SA 2.5',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFFC9B6A6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _Menu extends ConsumerWidget {
  const _Menu();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = AppLocalizations.of(context);
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.asset(
                  'assets/generated/app-icon.png',
                  width: 70,
                  height: 70,
                  semanticLabel: 'yorungez',
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              text.appDescription,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 28),
            ListTile(
              leading: const Icon(Icons.auto_awesome_outlined),
              title: Text(text.catalogueTitle),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.dns_outlined),
              title: Text(text.connection),
              onTap: () {
                Navigator.pop(context);
                context.push('/connection');
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text(text.sources),
              onTap: () {
                Navigator.pop(context);
                context.push('/sources');
              },
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Divider(),
            ),
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: ref.watch(localeProvider).languageCode,
              decoration: InputDecoration(labelText: text.language),
              items: const [
                DropdownMenuItem(value: 'en', child: Text('English')),
                DropdownMenuItem(value: 'tr', child: Text('Türkçe')),
              ],
              onChanged: (value) {
                if (value != null) {
                  ref.read(localeProvider.notifier).select(value);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
