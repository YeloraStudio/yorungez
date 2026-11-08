import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../core/presentation/external_link.dart';
import '../../l10n/generated/app_localizations.dart';
import '../data/survey_image.dart';
import '../domain/sky_object.dart';

class SurveyVisual extends StatefulWidget {
  const SurveyVisual({super.key, required this.object});

  final SkyObject object;

  @override
  State<SurveyVisual> createState() => _SurveyVisualState();
}

class _SurveyVisualState extends State<SurveyVisual> {
  Future<Uint8List>? _preview;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Text(t.surveyImageNote, style: Theme.of(context).textTheme.bodySmall),
        FutureBuilder<Uint8List>(
          future: _preview,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: LinearProgressIndicator(),
              );
            }
            if (snapshot.data case final Uint8List bytes) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.memory(
                      bytes,
                      width: double.infinity,
                      height: 220,
                      fit: BoxFit.contain,
                      semanticLabel: t.surveyImage,
                      errorBuilder: (_, _, _) => Text(t.imageUnavailable),
                    ),
                  ),
                  Text(
                    t.surveyCredit,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  ExternalLink(
                    url:
                        'https://irsa.ipac.caltech.edu/data/2MASS/docs/releases/allsky/',
                    label: t.imageSource,
                    small: true,
                  ),
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (snapshot.hasError) Text(t.surveyUnavailable),
                TextButton.icon(
                  icon: const Icon(Icons.photo_outlined),
                  onPressed: () =>
                      setState(() => _preview = loadSurveyImage(widget.object)),
                  label: Text(t.surveyImage),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
