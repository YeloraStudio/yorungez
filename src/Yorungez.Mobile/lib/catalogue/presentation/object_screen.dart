import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/providers.dart';
import '../../core/presentation/catalogue_state.dart';
import '../../l10n/generated/app_localizations.dart';
import 'catalogue_screen.dart';

class ObjectScreen extends ConsumerWidget {
  const ObjectScreen({super.key, required this.id});
  final String id;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: CatalogueState(
          builder: (catalogue) {
            final object = catalogue.find(id);
            if (object == null) return Center(child: Text(text.notFound));
            final image = catalogue.images[id];
            final language = ref.watch(localeProvider).languageCode;
            final frame = ref.watch(skyFrameProvider);
            final current = frame?.points[id];
            final decimal = NumberFormat.decimalPatternDigits(
              locale: language,
              decimalDigits: 2,
            );
            final coordinate = NumberFormat.decimalPatternDigits(
              locale: language,
              decimalDigits: 6,
            );
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    kindLabel(text, object.kind),
                    style: const TextStyle(color: Color(0xFFC9B6A6)),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    object.name(language),
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SelectableText(object.designation),
                  const SizedBox(height: 24),
                  if (image != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Image.asset(
                        'assets/generated/images/$id.jpg',
                        width: double.infinity,
                        height: 220,
                        fit: BoxFit.contain,
                        semanticLabel:
                            '${text.archiveImage}: ${object.name(language)}',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${text.archiveImage} · ${image['credit']} · ${image['license']}',
                      style: const TextStyle(
                        color: Color(0xFFC9B6A6),
                        fontSize: 12,
                      ),
                    ),
                    SelectableText(
                      image['sourceUrl'] as String,
                      style: const TextStyle(fontSize: 12),
                    ),
                    SelectableText(
                      image['licenseUrl'] as String,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ] else
                    Text(
                      text.imageUnavailable,
                      style: const TextStyle(color: Color(0xFFC9B6A6)),
                    ),
                  const SizedBox(height: 28),
                  if (current != null) ...[
                    Text(
                      text.skyTitle,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      DateFormat(
                        "yyyy-MM-dd HH:mm:ss 'UTC'",
                        language,
                      ).format(frame!.instant),
                    ),
                    _Field(
                      text.azimuthLabel,
                      '${decimal.format(current.azimuth)}°',
                    ),
                    _Field(
                      text.altitudeLabel,
                      '${decimal.format(current.altitude)}°',
                    ),
                    Text(
                      current.altitude >= 0
                          ? text.aboveHorizon
                          : text.belowHorizon,
                    ),
                    if (current.distanceAu != null)
                      _Field(
                        text.distanceAu,
                        decimal.format(current.distanceAu),
                      ),
                    if (current.raOfDate != null) ...[
                      const SizedBox(height: 16),
                      Text(text.calculatedOfDate),
                      _Field(
                        text.rightAscension,
                        coordinate.format(current.raOfDate),
                      ),
                      _Field(
                        text.declination,
                        coordinate.format(current.decOfDate),
                      ),
                    ],
                    Text(text.observabilityHelp),
                    const Divider(height: 32),
                  ],
                  if (object.magnitude != null)
                    _Field(text.magnitude, decimal.format(object.magnitude!)),
                  if (object.distanceParsecs != null)
                    _Field(
                      text.distance,
                      decimal.format(object.distanceParsecs!),
                    ),
                  if (object.raHours != null) ...[
                    const SizedBox(height: 24),
                    Text(
                      text.catalogueCoordinates,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 10),
                    Text(text.coordinateDescription),
                    const SizedBox(height: 14),
                    _Field(
                      text.rightAscension,
                      coordinate.format(object.raHours!),
                    ),
                    _Field(
                      text.declination,
                      coordinate.format(object.decDegrees!),
                    ),
                  ],
                  const SizedBox(height: 20),
                  _Field(text.catalogueReference, object.id),
                  const SizedBox(height: 12),
                  Text(
                    text.sourcesDescription,
                    style: const TextStyle(color: Color(0xFFC9B6A6)),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field(this.label, this.value);
  final String label, value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Wrap(
      spacing: 16,
      runSpacing: 6,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFFC9B6A6))),
        SelectableText(
          value,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ],
    ),
  );
}
