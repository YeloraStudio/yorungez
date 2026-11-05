import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'account_api.dart';
import 'account_models.dart';
import 'credential_vault.dart';

// No personal cache, write queue, request logging or token in UI preferences.
final class AccountSession extends ChangeNotifier {
  AccountSession(
    this.api,
    this.vault, {
    required this.applyLanguage,
    required this.currentLanguage,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;
  final AccountApi api;
  final CredentialVault vault;
  final void Function(String) applyLanguage;
  final String Function() currentLanguage;
  final DateTime Function() _now;
  AccountState _state = const AccountState();
  AccountState get state => _state;
  AccountTokens? _tokens;
  String? _refreshToken;
  DateTime? _refreshExpires;
  int _epoch = 0, _profileRevision = 0;
  int _notebookRevision = 0;
  bool _disposed = false, _initialised = false;
  bool _mustClearCredentials = false;
  Future<void>? _initialiseFlight, _refreshFlight, _profileFlight;
  Future<void> _vaultTail = Future.value();

  void _check(int epoch) {
    if (_disposed || epoch != _epoch) {
      throw const AccountFailure(AccountFailureKind.changed);
    }
  }

  void _publish({
    AccountUser? user,
    ExplorationPreferences? preferences,
    bool restoring = false,
    AccountFailure? failure,
  }) {
    if (_disposed) return;
    _state = AccountState(
      user: user,
      preferences: preferences,
      restoring: restoring,
      failure: failure,
      epoch: _epoch,
      notebookRevision: _notebookRevision,
    );
    notifyListeners();
  }

  void _problem(AccountFailure failure) => _publish(
    user: state.user,
    preferences: state.preferences,
    failure: failure,
  );
  Future<void> _store(String? value, int epoch) {
    final operation = _vaultTail.then((_) async {
      _check(epoch);
      try {
        if (value == null) {
          await vault.clear();
        } else {
          await vault.write(value);
        }
      } catch (_) {
        throw const AccountFailure(AccountFailureKind.storage);
      }
      _check(epoch);
    });
    _vaultTail = operation.catchError((Object _) {});
    return operation;
  }

  Future<void> _accept(AccountTokens tokens, int epoch) async {
    _check(epoch);
    try {
      await _store(
        jsonEncode({
          'refresh': tokens.refresh,
          'expires': tokens.refreshExpires.toIso8601String(),
        }),
        epoch,
      );
    } on AccountFailure catch (error) {
      if (error.kind == AccountFailureKind.storage) {
        _check(epoch);
        _tokens = null;
        _refreshToken = null;
        _refreshExpires = null;
        try {
          await _clearCredentials(epoch);
        } catch (_) {
          /* No insecure fallback. */
        }
        try {
          await api.request(
            'auth/logout',
            method: 'POST',
            access: tokens.access,
          );
        } catch (_) {
          /* Best-effort revoke newly issued family. */
        }
        _publish(failure: error);
      }
      rethrow;
    }
    _check(epoch);
    _tokens = tokens;
    _refreshToken = tokens.refresh;
    _refreshExpires = tokens.refreshExpires;
  }

  Future<void> initialise() {
    if (_initialised) return Future.value();
    return _initialiseFlight ??= _initialise().whenComplete(
      () => _initialiseFlight = null,
    );
  }

  Future<void> _initialise() async {
    final epoch = _epoch;
    _publish(restoring: true);
    try {
      String? saved;
      try {
        saved = await vault.read();
      } catch (_) {
        throw const AccountFailure(AccountFailureKind.storage);
      }
      _check(epoch);
      _initialised = true;
      if (saved == null) {
        _publish();
        return;
      }
      try {
        final data = objectMap(jsonDecode(saved));
        _refreshToken = requiredString(data, 'refresh', 4096);
        _refreshExpires = DateTime.parse(requiredString(data, 'expires', 64));
      } catch (_) {
        await _expire(epoch);
        return;
      }
      await _refresh();
      await refreshProfile();
    } on AccountFailure catch (error) {
      if (epoch == _epoch &&
          !_disposed &&
          error.kind != AccountFailureKind.changed) {
        _problem(error);
      }
    }
  }

  Future<void> retry() async {
    if (_mustClearCredentials) {
      try {
        await _clearCredentials(_epoch);
        _publish();
      } on AccountFailure catch (error) {
        if (!_disposed && error.kind != AccountFailureKind.changed) {
          _problem(error);
        }
      }
      return;
    }
    if (!_initialised) {
      await initialise();
      return;
    }
    if (_refreshToken != null || _tokens != null) await refreshProfile();
  }

  Future<void> _expire(int epoch) async {
    _check(epoch);
    _tokens = null;
    _refreshToken = null;
    _refreshExpires = null;
    _publish();
    await _clearCredentials(epoch);
  }

  Future<void> _clearCredentials(int epoch) async {
    _mustClearCredentials = true;
    await _store(null, epoch);
    _check(epoch);
    _mustClearCredentials = false;
  }

  Future<void> _refresh() {
    if (_refreshFlight != null) return _refreshFlight!;
    final operation = _rotate(_epoch);
    _refreshFlight = operation;
    return operation.whenComplete(() {
      if (identical(_refreshFlight, operation)) _refreshFlight = null;
    });
  }

  Future<void> _rotate(int epoch) async {
    _check(epoch);
    final refresh = _refreshToken;
    if (refresh == null ||
        _refreshExpires == null ||
        !_refreshExpires!.isAfter(_now())) {
      await _expire(epoch);
      throw const AccountFailure(AccountFailureKind.unauthorized);
    }
    try {
      final data = await api.request(
        'auth/refresh',
        method: 'POST',
        body: {'refreshToken': refresh},
        language: currentLanguage(),
      );
      _check(epoch);
      await _accept(AccountTokens.decode(data), epoch);
    } on AccountFailure catch (error) {
      if (error.kind == AccountFailureKind.unauthorized) await _expire(epoch);
      rethrow;
    }
  }

  Future<dynamic> authorized(
    String path, {
    String method = 'GET',
    Map<String, dynamic>? body,
  }) async {
    final epoch = _epoch, owner = state.user?.id;
    if (_tokens == null ||
        !_tokens!.accessExpires.isAfter(
          _now().add(const Duration(seconds: 20)),
        )) {
      await _refresh();
    }
    _check(epoch);
    var access = _tokens!.access;
    Future<dynamic> send() => api.request(
      path,
      method: method,
      body: body,
      access: access,
      owner: owner,
      language: currentLanguage(),
    );
    dynamic data;
    try {
      data = await send();
    } on AccountFailure catch (error) {
      _check(epoch);
      if (error.kind != AccountFailureKind.unauthorized) rethrow;
      // Only a rejected 401 is retried, once. Network/timeouts and writes with
      // an uncertain result are never replayed. Concurrent 401s share rotation.
      if (access == _tokens?.access) await _refresh();
      _check(epoch);
      access = _tokens!.access;
      try {
        data = await send();
      } on AccountFailure catch (again) {
        if (again.kind == AccountFailureKind.unauthorized) await _expire(epoch);
        rethrow;
      }
    }
    _check(epoch);
    return data;
  }

  Future<void> signIn(String email, String password) async {
    final epoch = ++_epoch;
    _profileRevision++;
    _tokens = null;
    _refreshToken = null;
    _refreshExpires = null;
    _refreshFlight = null;
    _profileFlight = null;
    _initialised = true;
    _publish(restoring: true);
    try {
      await _clearCredentials(epoch);
      final data = await api.request(
        'auth/login',
        method: 'POST',
        body: {'email': email.trim(), 'password': password},
        language: currentLanguage(),
      );
      _check(epoch);
      await _accept(AccountTokens.decode(data), epoch);
      await refreshProfile();
      _check(epoch);
      if (state.user == null) {
        throw state.failure ?? const AccountFailure(AccountFailureKind.network);
      }
    } on AccountFailure catch (error) {
      if (epoch == _epoch &&
          !_disposed &&
          error.kind != AccountFailureKind.changed) {
        _problem(error);
      }
      rethrow;
    }
  }

  Future<void> register(
    String firstName,
    String lastName,
    String email,
    String password,
  ) async {
    await api.request(
      'auth/register',
      method: 'POST',
      language: currentLanguage(),
      body: {
        'firstName': firstName.trim(),
        'lastName': lastName.trim(),
        'email': email.trim(),
        'password': password,
      },
    );
  }

  Future<void> requestEmail(String email, {required bool reset}) async {
    await api.request(
      reset ? 'auth/forgot-password' : 'auth/resend-confirmation',
      method: 'POST',
      language: currentLanguage(),
      body: {'email': email.trim()},
    );
  }

  Future<void> refreshProfile() {
    if (_profileFlight != null) return _profileFlight!;
    final operation = _loadProfile(_epoch, _profileRevision);
    _profileFlight = operation;
    return operation.whenComplete(() {
      if (identical(_profileFlight, operation)) _profileFlight = null;
    });
  }

  Future<void> _loadProfile(int epoch, int revision) async {
    try {
      final user = AccountUser.decode(await authorized('auth/me'));
      _check(epoch);
      if (revision != _profileRevision) return;
      if (state.user != null && state.user!.id != user.id) {
        throw const AccountFailure(AccountFailureKind.changed);
      }
      applyLanguage(user.language);
      _publish(user: user, preferences: state.preferences);
      try {
        final preferences = ExplorationPreferences.decode(
          await authorized('auth/exploration-preferences'),
        );
        _check(epoch);
        if (revision == _profileRevision) {
          _publish(user: state.user, preferences: preferences);
        }
      } on AccountFailure catch (error) {
        if (epoch == _epoch &&
            !_disposed &&
            error.kind != AccountFailureKind.changed) {
          _problem(error);
        }
      }
    } on AccountFailure catch (error) {
      if (epoch == _epoch &&
          !_disposed &&
          error.kind != AccountFailureKind.changed) {
        _problem(error);
      }
    }
  }

  Future<void> setLanguage(String language) async {
    if (!['en', 'tr'].contains(language) || state.user == null) {
      throw const AccountFailure(AccountFailureKind.unauthorized);
    }
    final epoch = _epoch, owner = state.user!.id;
    _profileRevision++;
    final user = AccountUser.decode(
      await authorized(
        'auth/language',
        method: 'POST',
        body: {'preferredLanguage': language},
      ),
    );
    _check(epoch);
    if (owner != user.id) {
      throw const AccountFailure(AccountFailureKind.changed);
    }
    applyLanguage(user.language);
    _publish(user: user, preferences: state.preferences);
  }

  Future<void> updateName(String first, String last) async {
    final epoch = _epoch, owner = state.user?.id;
    _profileRevision++;
    final user = AccountUser.decode(
      await authorized(
        'auth/profile',
        method: 'POST',
        body: {'firstName': first.trim(), 'lastName': last.trim()},
      ),
    );
    _check(epoch);
    if (owner != user.id) {
      throw const AccountFailure(AccountFailureKind.changed);
    }
    applyLanguage(user.language);
    _publish(user: user, preferences: state.preferences);
  }

  Future<void> savePreferences(bool music, Set<String> layers) async {
    final epoch = _epoch, current = state.preferences;
    if (state.user == null || current == null) {
      throw const AccountFailure(AccountFailureKind.network);
    }
    _profileRevision++;
    final preferences = ExplorationPreferences.decode(
      await authorized(
        'auth/exploration-preferences',
        method: 'POST',
        body: {
          'musicEnabled': music,
          'skyLayers': layers.toList()..sort(),
          'expectedRevision': current.revision,
        },
      ),
    );
    _check(epoch);
    _publish(user: state.user, preferences: preferences);
  }

  Future<List<NotebookEntry>> notebook() async {
    final owner = state.user?.id;
    if (owner == null) {
      throw const AccountFailure(AccountFailureKind.unauthorized);
    }
    final data = objectMap(await authorized('notebook/'));
    if (data['userId'] != owner) {
      throw const AccountFailure(AccountFailureKind.changed);
    }
    final entries = data['entries'];
    if (entries is! List) {
      throw const AccountFailure(AccountFailureKind.protocol);
    }
    return entries.map(NotebookEntry.decode).where((e) => !e.deleted).toList();
  }

  Future<NotebookEntry> saveEntry(Map<String, dynamic> entry) async {
    if (state.user == null) {
      throw const AccountFailure(AccountFailureKind.unauthorized);
    }
    final saved = NotebookEntry.decode(
      await authorized('notebook/', method: 'POST', body: entry),
    );
    _notebookRevision++;
    _publish(user: state.user, preferences: state.preferences);
    return saved;
  }

  Future<bool> signOut() async {
    final access = _tokens?.access;
    final epoch = ++_epoch;
    _profileRevision++;
    _tokens = null;
    _refreshToken = null;
    _refreshExpires = null;
    _profileFlight = null;
    _refreshFlight = null;
    _publish(); // Immediately hide every personal view before any network wait.
    AccountFailure? storageFailure;
    try {
      await _clearCredentials(epoch);
    } on AccountFailure catch (error) {
      storageFailure = error;
    }
    var revoked = access == null;
    try {
      if (access != null) {
        await api.request(
          'auth/logout',
          method: 'POST',
          access: access,
          language: currentLanguage(),
        );
      }
      revoked = true;
    } on AccountFailure {
      revoked = false;
    }
    _check(epoch);
    if (storageFailure != null) {
      _problem(storageFailure);
      throw storageFailure;
    }
    return revoked;
  }

  @override
  void dispose() {
    _disposed = true;
    _epoch++;
    super.dispose();
  }
}
