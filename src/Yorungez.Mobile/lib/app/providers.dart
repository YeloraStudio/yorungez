import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../account/account_api.dart';
import '../account/account_models.dart';
import '../account/account_session.dart';
import '../account/credential_vault.dart';

import '../catalogue/data/catalogue_repository.dart';
import '../core/api/yorungez_api.dart';
import '../sky/domain/sky_frame.dart';
import '../sky/data/device_location.dart';

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
  int _revision = 0;
  @override
  Locale build() => const Locale('en');
  void select(String code) {
    if (!['en', 'tr'].contains(code)) throw ArgumentError.value(code);
    state = Locale(code);
    _revision++;
    _persist(code);
  }

  Future<void> _persist(String code) async {
    try {
      await (await SharedPreferences.getInstance()).setString(
        'ui.language',
        code,
      );
    } catch (_) {
      /* Optional non-personal preference. */
    }
  }

  Future<void> restore() async {
    final revision = _revision;
    try {
      final code = (await SharedPreferences.getInstance()).getString(
        'ui.language',
      );
      if (ref.mounted && revision == _revision && ['en', 'tr'].contains(code)) {
        state = Locale(code!);
      }
    } catch (_) {
      /* English remains the default. */
    }
  }
}

final localeProvider = NotifierProvider<LocaleController, Locale>(
  LocaleController.new,
);
final catalogueRepositoryProvider = Provider((ref) => CatalogueRepository());
final catalogueProvider = FutureProvider(
  (ref) => ref.watch(catalogueRepositoryProvider).load(),
);
final apiOriginProvider = Provider(
  (ref) => validateApiOrigin(
    const String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'https://api.yorungez.com',
    ),
    release: kReleaseMode,
  ),
);
final apiProvider = Provider((ref) {
  final api = YorungezApi(ref.watch(apiOriginProvider));
  ref.onDispose(api.close);
  return api;
});

final accountApiProvider = Provider<AccountApi>((ref) {
  final api = HttpAccountApi(ref.watch(apiOriginProvider));
  ref.onDispose(api.close);
  return api;
});
final credentialVaultProvider = Provider<CredentialVault>(
  (ref) => PlatformCredentialVault(ref.watch(apiOriginProvider)),
);
final accountSessionProvider = Provider((ref) {
  final session = AccountSession(
    ref.watch(accountApiProvider),
    ref.watch(credentialVaultProvider),
    applyLanguage: (code) {
      if (ref.mounted) ref.read(localeProvider.notifier).select(code);
    },
    currentLanguage: () => ref.read(localeProvider).languageCode,
  );
  ref.onDispose(session.dispose);
  return session;
});

class AccountStateController extends Notifier<AccountState> {
  @override
  AccountState build() {
    final session = ref.watch(accountSessionProvider);
    void changed() {
      state = session.state;
    }

    session.addListener(changed);
    ref.onDispose(() => session.removeListener(changed));
    return session.state;
  }
}

final accountStateProvider =
    NotifierProvider<AccountStateController, AccountState>(
      AccountStateController.new,
    );
final notebookProvider = FutureProvider.autoDispose((ref) {
  ref.watch(accountStateProvider.select((s) => (s.user?.id, s.epoch)));
  return ref.read(accountSessionProvider).notebook();
});

class SkyFocusController extends Notifier<String?> {
  @override
  String? build() => null;
  void request(String id) => state = id;
  void consumed(String id) {
    if (state == id) state = null;
  }
}

final skyFocusProvider = NotifierProvider<SkyFocusController, String?>(
  SkyFocusController.new,
);
final skyRouteObserver = RouteObserver<PageRoute<dynamic>>();
final deviceLocationProvider = Provider<DeviceLocationSource>(
  (ref) => ForegroundDeviceLocation(),
);
