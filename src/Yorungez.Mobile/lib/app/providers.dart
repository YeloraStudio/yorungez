import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../catalogue/data/catalogue_repository.dart';
import '../core/api/yorungez_api.dart';
import '../sky/domain/sky_frame.dart';

final class SkyFrameController extends Notifier<SkyFrame?> {
  @override
  SkyFrame? build() => null;
  void publish(SkyFrame? frame) {
    state = frame;
  }
}

final skyFrameProvider = NotifierProvider<SkyFrameController, SkyFrame?>(
  SkyFrameController.new,
);

final class LocaleController extends Notifier<Locale> {
  @override
  Locale build() => const Locale('en');
  void select(String code) {
    if (!['en', 'tr'].contains(code)) throw ArgumentError.value(code);
    state = Locale(code);
  }
}

final localeProvider = NotifierProvider<LocaleController, Locale>(
  LocaleController.new,
);
final catalogueRepositoryProvider = Provider((ref) => CatalogueRepository());
final catalogueProvider = FutureProvider(
  (ref) => ref.watch(catalogueRepositoryProvider).load(),
);
final apiProvider = Provider((ref) {
  final uri = validateApiOrigin(
    const String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'https://api.yorungez.com',
    ),
    release: kReleaseMode,
  );
  final api = YorungezApi(uri);
  ref.onDispose(api.close);
  return api;
});
