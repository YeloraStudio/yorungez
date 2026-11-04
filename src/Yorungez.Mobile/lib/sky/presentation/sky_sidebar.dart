import 'dart:async';
import 'package:flutter/material.dart';
import '../../l10n/generated/app_localizations.dart';
import 'sky_painter.dart';

class SkySidebar extends StatelessWidget {
  const SkySidebar({
    super.key,
    required this.layers,
    required this.muted,
    required this.language,
    required this.location,
    required this.clock,
    required this.changeLocation,
    required this.calibrate,
    required this.showSources,
    required this.showConnection,
    required this.toggleMusic,
    required this.changeLanguage,
    required this.changeLayer,
    required this.showPrivacy,
  });
  final Set<SkyLayer> layers;
  final bool muted;
  final String language, location, clock;
  final VoidCallback changeLocation,
      calibrate,
      showSources,
      showConnection,
      showPrivacy;
  final Future<void> Function() toggleMusic;
  final ValueChanged<String> changeLanguage;
  final void Function(SkyLayer, bool) changeLayer;
  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    void closeThen(VoidCallback action) {
      Navigator.pop(context);
      action();
    }

    return Drawer(
      width: 340,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'assets/generated/app-icon.png',
                      width: 44,
                      height: 44,
                      semanticLabel: 'yorungez',
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'yorungez.',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    tooltip: t.close,
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.location_on_outlined),
                    title: Text(t.locationUpdate),
                    subtitle: Text(location),
                    onTap: () => closeThen(changeLocation),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.schedule_outlined),
                    title: Text(t.liveUtc),
                    subtitle: Text(clock),
                  ),
                  const Divider(height: 24),
                  Text(
                    t.skyLayers,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  for (final entry in [
                    (SkyLayer.stars, t.layerStars),
                    (SkyLayer.solar, t.layerSolar),
                    (SkyLayer.deepSky, t.layerDeepSky),
                    (SkyLayer.constellations, t.layerConstellations),
                    (SkyLayer.figures, t.layerFigures),
                    (SkyLayer.cosmic, t.layerCosmic),
                    (SkyLayer.grid, t.layerGrid),
                    (SkyLayer.horizon, t.layerHorizon),
                    (SkyLayer.atmosphere, t.layerAtmosphere),
                  ])
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(entry.$2),
                      value: layers.contains(entry.$1),
                      onChanged: (value) => changeLayer(entry.$1, value),
                    ),
                  const Divider(height: 20),
                  Text(
                    t.layerHelp,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  TextButton.icon(
                    onPressed: () => closeThen(calibrate),
                    icon: const Icon(Icons.explore_outlined),
                    label: Text(t.showCalibration),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => closeThen(showSources),
                    child: Text(t.sources),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => closeThen(showConnection),
                    child: Text(t.connection),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => closeThen(showPrivacy),
                    child: Text(t.privacyTitle),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * .46,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      secondary: Icon(
                        muted
                            ? Icons.volume_off_outlined
                            : Icons.volume_up_outlined,
                      ),
                      title: Text(t.backgroundMusic),
                      value: !muted,
                      onChanged: (_) => unawaited(toggleMusic()),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      key: ValueKey(language),
                      isExpanded: true,
                      initialValue: language,
                      decoration: InputDecoration(labelText: t.language),
                      items: const [
                        DropdownMenuItem(value: 'en', child: Text('English')),
                        DropdownMenuItem(value: 'tr', child: Text('Türkçe')),
                      ],
                      onChanged: (code) {
                        if (code != null) changeLanguage(code);
                      },
                    ),
                    const SizedBox(height: 10),
                    Text(
                      t.musicCredit,
                      style: Theme.of(context).textTheme.bodySmall,
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
