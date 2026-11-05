enum AccountFailureKind {
  network,
  timeout,
  server,
  protocol,
  unauthorized,
  unconfirmed,
  conflict,
  validation,
  throttled,
  storage,
  changed,
}

final class AccountFailure implements Exception {
  const AccountFailure(this.kind, [this.code = '']);
  final AccountFailureKind kind;
  // Only a bounded machine code, never the HTTP request, token or personal body.
  final String code;
}

Map<String, dynamic> objectMap(dynamic value) {
  if (value is! Map<String, dynamic>) {
    throw const AccountFailure(AccountFailureKind.protocol);
  }
  return value;
}

String requiredString(
  Map<String, dynamic> value,
  String key, [
  int max = 1000,
]) {
  final field = value[key];
  if (field is! String || field.isEmpty || field.length > max) {
    throw const AccountFailure(AccountFailureKind.protocol);
  }
  return field;
}

final class AccountUser {
  const AccountUser(
    this.id,
    this.email,
    this.firstName,
    this.lastName,
    this.language,
  );
  final String id, email, language;
  final String? firstName, lastName;
  String get displayName => [
    firstName,
    lastName,
  ].whereType<String>().where((s) => s.isNotEmpty).join(' ');
  factory AccountUser.decode(dynamic value) {
    final data = objectMap(value);
    final language = data['preferredLanguage'];
    if (data['emailConfirmed'] != true ||
        !['en', 'tr'].contains(language) ||
        [
          data['firstName'],
          data['lastName'],
        ].any((v) => v != null && (v is! String || v.length > 100))) {
      throw const AccountFailure(AccountFailureKind.protocol);
    }
    return AccountUser(
      requiredString(data, 'id', 64),
      requiredString(data, 'email', 254),
      data['firstName'] as String?,
      data['lastName'] as String?,
      language as String,
    );
  }
}

final class AccountTokens {
  const AccountTokens(
    this.access,
    this.accessExpires,
    this.refresh,
    this.refreshExpires,
  );
  final String access, refresh;
  final DateTime accessExpires, refreshExpires;
  factory AccountTokens.decode(dynamic value) {
    final data = objectMap(value);
    final access = DateTime.tryParse(data['accessExpiresAt']?.toString() ?? '');
    final refresh = DateTime.tryParse(
      data['refreshExpiresAt']?.toString() ?? '',
    );
    if (access == null || refresh == null || !refresh.isAfter(access)) {
      throw const AccountFailure(AccountFailureKind.protocol);
    }
    return AccountTokens(
      requiredString(data, 'accessToken', 16384),
      access.toUtc(),
      requiredString(data, 'refreshToken', 4096),
      refresh.toUtc(),
    );
  }
}

const allowedSkyLayers = {
  'stars',
  'solar',
  'deepSky',
  'constellations',
  'figures',
  'cosmic',
  'grid',
  'horizon',
  'atmosphere',
};

final class ExplorationPreferences {
  const ExplorationPreferences(this.musicEnabled, this.layers, this.revision);
  final bool musicEnabled;
  final Set<String> layers;
  final int revision;
  factory ExplorationPreferences.decode(dynamic value) {
    final data = objectMap(value), layers = data['skyLayers'];
    if (data['musicEnabled'] is! bool ||
        data['revision'] is! int ||
        (data['revision'] as int) < 0 ||
        layers is! List ||
        layers.length > allowedSkyLayers.length ||
        layers.any((v) => !allowedSkyLayers.contains(v)) ||
        layers.toSet().length != layers.length) {
      throw const AccountFailure(AccountFailureKind.protocol);
    }
    return ExplorationPreferences(
      data['musicEnabled'] as bool,
      Set<String>.from(layers),
      data['revision'] as int,
    );
  }
}

final class NotebookEntry {
  NotebookEntry(this.data);
  final Map<String, dynamic> data;
  String get id => data['id'] as String;
  String get kind => data['kind'] as String;
  int get revision => data['revision'] as int;
  String get body => data['body'] as String? ?? '';
  Map<String, dynamic>? get target => data['target'] as Map<String, dynamic>?;
  Map<String, dynamic>? get location =>
      data['location'] as Map<String, dynamic>?;
  bool get deleted => data['deletedAtUtc'] != null;
  factory NotebookEntry.decode(dynamic value) {
    final data = objectMap(value);
    requiredString(data, 'id', 160);
    if (!['note', 'favorite', 'observation', 'place'].contains(data['kind']) ||
        data['revision'] is! int ||
        (data['revision'] as int) < 1 ||
        (data['body'] != null &&
            (data['body'] is! String ||
                (data['body'] as String).length > 8000))) {
      throw const AccountFailure(AccountFailureKind.protocol);
    }
    for (final key in ['target', 'location']) {
      if (data[key] != null) objectMap(data[key]);
    }
    return NotebookEntry(Map<String, dynamic>.unmodifiable(data));
  }
}

final class AccountState {
  const AccountState({
    this.user,
    this.preferences,
    this.restoring = false,
    this.failure,
    this.epoch = 0,
    this.notebookRevision = 0,
  });
  final AccountUser? user;
  final ExplorationPreferences? preferences;
  final bool restoring;
  final AccountFailure? failure;
  final int epoch;
  final int notebookRevision;
}
