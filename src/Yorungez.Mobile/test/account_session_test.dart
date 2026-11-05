import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:yorungez/account/account_models.dart';
import 'package:yorungez/account/account_session.dart';
import 'support/account_fakes.dart';

void main() {
  late FakeAccountApi api;
  late MemoryVault vault;
  late AccountSession session;
  late String language;
  setUp(() {
    api = FakeAccountApi();
    vault = MemoryVault();
    language = 'en';
    session = AccountSession(
      api,
      vault,
      applyLanguage: (code) => language = code,
      currentLanguage: () => language,
      now: () => api.now,
    );
  });
  tearDown(() => session.dispose());

  test(
    'login applies shared profile language, stores only refresh and reads server preferences',
    () async {
      await session.signIn('a@example.invalid', 'a synthetic test passphrase');
      expect(language, 'tr');
      expect(session.state.user?.displayName, 'Public Tester');
      expect(session.state.preferences?.musicEnabled, false);
      final saved = jsonDecode(vault.value!) as Map;
      expect(saved.keys.toSet(), {'refresh', 'expires'});
      expect(vault.value, isNot(contains('synthetic-access')));
      expect(vault.value, isNot(contains('@example.invalid')));
      expect(await session.notebook(), isEmpty);
    },
  );
  test('a rotating refresh is shared by concurrent expired requests', () async {
    await session.signIn('a@example.invalid', 'synthetic');
    api.now = api.now.add(const Duration(minutes: 11));
    api.refreshing = Completer<void>();
    final one = session.notebook(), two = session.notebook();
    await Future<void>.delayed(Duration.zero);
    expect(api.refreshes, 1);
    api.refreshing!.complete();
    await Future.wait([one, two]);
    expect(
      jsonDecode(vault.value!)['refresh'],
      'synthetic-refresh-account-a-1',
    );
  });
  test(
    'two 401 responses rotate once and replay only rejected requests',
    () async {
      await session.signIn('a@example.invalid', 'synthetic');
      api.refreshing = Completer<void>();
      api.intercept = (path, method, body, access) async {
        if (access!.endsWith('-0')) {
          throw const AccountFailure(AccountFailureKind.unauthorized);
        }
        return {'userId': 'account-a', 'entries': []};
      };
      final one = session.notebook(), two = session.notebook();
      await Future<void>.delayed(Duration.zero);
      expect(api.refreshes, 1);
      api.refreshing!.complete();
      await Future.wait([one, two]);
      expect(api.refreshes, 1);
    },
  );
  test(
    'uncertain personal writes are not replayed and are not stored locally',
    () async {
      await session.signIn('a@example.invalid', 'synthetic');
      var writes = 0;
      api.intercept = (path, method, body, access) async {
        writes++;
        throw const AccountFailure(AccountFailureKind.timeout);
      };
      final saved = vault.value;
      await expectLater(
        session.saveEntry({
          'id': 'synthetic-note',
          'kind': 'note',
          'body': 'private in-memory draft',
        }),
        throwsA(
          isA<AccountFailure>().having(
            (e) => e.kind,
            'kind',
            AccountFailureKind.timeout,
          ),
        ),
      );
      expect(writes, 1);
      expect(vault.value, saved);
      expect(vault.value, isNot(contains('private in-memory draft')));
    },
  );
  test(
    'server-first language failure leaves the current language intact',
    () async {
      await session.signIn('a@example.invalid', 'synthetic');
      api.failLanguage = true;
      await expectLater(
        session.setLanguage('en'),
        throwsA(isA<AccountFailure>()),
      );
      expect(language, 'tr');
      api.failLanguage = false;
      await session.setLanguage('en');
      expect(language, 'en');
    },
  );
  test('a stale profile from account A cannot replace account B', () async {
    await session.signIn('a@example.invalid', 'synthetic');
    final old = api.profile(), delayed = Completer<dynamic>();
    api.heldProfile = delayed;
    final pending = session.refreshProfile();
    await Future<void>.delayed(Duration.zero);
    api.heldProfile = null;
    await session.signIn('b@example.invalid', 'synthetic');
    delayed.complete(old);
    await pending;
    expect(session.state.user?.id, 'account-b');
  });
  test(
    'late personal data is rejected after sign-out and credentials stay cleared',
    () async {
      await session.signIn('a@example.invalid', 'synthetic');
      final delayed = Completer<dynamic>();
      api.intercept = (_, _, _, _) => delayed.future;
      final pending = session.notebook();
      final rejected = expectLater(
        pending,
        throwsA(
          isA<AccountFailure>().having(
            (e) => e.kind,
            'kind',
            AccountFailureKind.changed,
          ),
        ),
      );
      await Future<void>.delayed(Duration.zero);
      await session.signOut();
      delayed.complete({'userId': 'account-a', 'entries': []});
      await rejected;
      expect(session.state.user, isNull);
      expect(vault.value, isNull);
      expect(api.logouts, 1);
    },
  );
  test('wrong-owner notebook payload never reaches the view', () async {
    await session.signIn('a@example.invalid', 'synthetic');
    api.intercept = (_, _, _, _) async => {
      'userId': 'account-b',
      'entries': [],
    };
    await expectLater(
      session.notebook(),
      throwsA(
        isA<AccountFailure>().having(
          (e) => e.kind,
          'kind',
          AccountFailureKind.changed,
        ),
      ),
    );
  });
  test(
    'secure-storage failure does not fall back to plaintext or accept a session',
    () async {
      vault.failWrite = true;
      await expectLater(
        session.signIn('a@example.invalid', 'synthetic'),
        throwsA(
          isA<AccountFailure>().having(
            (e) => e.kind,
            'kind',
            AccountFailureKind.storage,
          ),
        ),
      );
      expect(session.state.user, isNull);
      expect(vault.value, isNull);
      expect(api.logouts, 1);
    },
  );
  test(
    'offline logout removes the device credential and reports uncertain revocation',
    () async {
      await session.signIn('a@example.invalid', 'synthetic');
      api.offlineLogout = true;
      expect(await session.signOut(), false);
      expect(session.state.user, isNull);
      expect(vault.value, isNull);
    },
  );
  test(
    'cold restore rotates the secure refresh credential before exposing an account',
    () async {
      vault.value = jsonEncode({
        'refresh': 'synthetic-old-refresh',
        'expires': api.now.add(const Duration(days: 1)).toIso8601String(),
      });
      await session.initialise();
      expect(api.refreshes, 1);
      expect(session.state.user?.id, 'account-a');
      expect(language, 'tr');
      expect(
        jsonDecode(vault.value!)['refresh'],
        'synthetic-refresh-account-a-1',
      );
    },
  );
  test('revoked refresh clears the account and secure credential', () async {
    await session.signIn('a@example.invalid', 'synthetic');
    api.now = api.now.add(const Duration(minutes: 11));
    api.refreshFailure = const AccountFailure(AccountFailureKind.unauthorized);
    await expectLater(session.notebook(), throwsA(isA<AccountFailure>()));
    expect(session.state.user, isNull);
    expect(vault.value, isNull);
  });
  test(
    'rotation storage failure hides the account and revokes the issued family',
    () async {
      await session.signIn('a@example.invalid', 'synthetic');
      api.now = api.now.add(const Duration(minutes: 11));
      vault.failWrite = true;
      await expectLater(session.notebook(), throwsA(isA<AccountFailure>()));
      expect(session.state.user, isNull);
      expect(vault.value, isNull);
      expect(api.logouts, 1);
    },
  );
  test(
    'logout still revokes if secure deletion fails and retry never restores the old account',
    () async {
      await session.signIn('a@example.invalid', 'synthetic');
      vault.failClear = true;
      await expectLater(session.signOut(), throwsA(isA<AccountFailure>()));
      expect(api.logouts, 1);
      expect(session.state.user, isNull);
      vault.failClear = false;
      await session.retry();
      expect(vault.value, isNull);
      expect(session.state.user, isNull);
      expect(api.refreshes, 0);
    },
  );
}
