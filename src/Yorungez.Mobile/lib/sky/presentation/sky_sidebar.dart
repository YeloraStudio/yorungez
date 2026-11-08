import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/generated/app_localizations.dart';
import 'sky_painter.dart';
import '../../account/account_widgets.dart';
import '../../core/presentation/external_link.dart';

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
    required this.changeLayer,
    required this.showPrivacy,
    required this.dwellEnabled,
    required this.zoomEnabled,
    required this.changeDwell,
    required this.changeZoom,
    this.savingPreferences = false,
    this.simulated = false,
    required this.showTonight,
    required this.showCalendar,
    required this.showReminders,
    required this.showTimeZone,
    required this.returnToLive,
  });
  final Set<SkyLayer> layers;
  final bool savingPreferences, simulated;
  final VoidCallback showTonight,
      showCalendar,
      showReminders,
      showTimeZone,
      returnToLive;
  final bool muted;
  final bool dwellEnabled, zoomEnabled;
  final ValueChanged<bool> changeDwell, changeZoom;
  final String language, location, clock;
  final VoidCallback changeLocation,
      calibrate,
      showSources,
      showConnection,
      showPrivacy;
  final Future<void> Function() toggleMusic;
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
                      semanticLabel: 'Yorungez',
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Yorungez.',
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
                  AccountMenu(closeDrawer: () => Navigator.pop(context)),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.nights_stay_outlined),
                    title: Text(t.tonight),
                    onTap: () => closeThen(showTonight),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.calendar_month_outlined),
                    title: Text(t.eventCalendar),
                    onTap: () => closeThen(showCalendar),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.explore_outlined),
                    title: Text(t.guideTitle),
                    onTap: () => closeThen(() => context.push('/observe')),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.satellite_alt_outlined),
                    title: Text(t.issPassesTitle),
                    onTap: () => closeThen(() => context.push('/iss-passes')),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.notifications_active_outlined),
                    title: Text(t.reminders),
                    onTap: () => closeThen(showReminders),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.menu_book_outlined),
                    title: Text(t.glossaryTitle),
                    onTap: () => closeThen(() => context.push('/glossary')),
                  ),
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
                    title: Text(simulated ? t.simulation : t.localAndUtc),
                    subtitle: Text(clock),
                    onTap: () => closeThen(showTimeZone),
                  ),
                  if (simulated)
                    TextButton(
                      onPressed: () => closeThen(returnToLive),
                      child: Text(t.returnLive),
                    ),
                  const Divider(height: 24),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(t.dwellSetting),
                    value: dwellEnabled,
                    onChanged: changeDwell,
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(t.zoomSetting),
                    subtitle: Text(t.zoomSettingHelp),
                    value: zoomEnabled,
                    onChanged: changeZoom,
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
                      onChanged: savingPreferences
                          ? null
                          : (value) => changeLayer(entry.$1, value),
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
                  ExternalLink(
                    url: 'https://yorungez.com/$language',
                    label: 'yorungez.com',
                    small: true,
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
                      onChanged: savingPreferences
                          ? null
                          : (_) => unawaited(toggleMusic()),
                    ),
                    const SizedBox(height: 8),
                    const LanguagePicker(),
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
