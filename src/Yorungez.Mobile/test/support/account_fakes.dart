import 'dart:async';
import 'package:yorungez/account/account_api.dart';
import 'package:yorungez/account/account_models.dart';
import 'package:yorungez/account/credential_vault.dart';

class MemoryVault implements CredentialVault {
  String? value;
  bool failWrite = false;
  bool failClear = false;
  @override
  Future<String?> read() async => value;
  @override
  Future<void> write(String value) async {
    if (failWrite) throw StateError('Synthetic storage failure');
    this.value = value;
  }

  @override
  Future<void> clear() async {
    if (failClear) throw StateError('Synthetic clear failure');
    value = null;
  }
}

class FakeAccountApi implements AccountApi {
  DateTime now = DateTime.utc(2026, 11, 5);
  int refreshes = 0, logouts = 0, saves = 0;
  String owner = 'account-a', language = 'tr';
  bool failLanguage = false, offlineLogout = false;
  AccountFailure? refreshFailure;
  Completer<void>? refreshing;
  Completer<dynamic>? heldProfile;
  Future<dynamic> Function(String, String, Map<String, dynamic>?, String?)?
  intercept;
  Map<String, dynamic> profile() => {
    'id': owner,
    'email': '$owner@example.invalid',
    'emailConfirmed': true,
    'firstName': 'Public',
    'lastName': 'Tester',
    'preferredLanguage': language,
  };
  Map<String, dynamic> pair() => {
    'accessToken': 'synthetic-access-$owner-$refreshes',
    'refreshToken': 'synthetic-refresh-$owner-$refreshes',
    'accessExpiresAt': now.add(const Duration(minutes: 10)).toIso8601String(),
    'refreshExpiresAt': now.add(const Duration(days: 7)).toIso8601String(),
  };
  @override
  Future<dynamic> request(
    String path, {
    String method = 'GET',
    Map<String, dynamic>? body,
    String? access,
    String? owner,
    String language = 'en',
  }) async {
    if (intercept != null && path == 'notebook/') {
      return intercept!(path, method, body, access);
    }
    switch (path) {
      case 'auth/login':
        this.owner = body!['email'] == 'b@example.invalid'
            ? 'account-b'
            : 'account-a';
        return pair();
      case 'auth/refresh':
        refreshes++;
        if (refreshFailure != null) throw refreshFailure!;
        await refreshing?.future;
        return pair();
      case 'auth/me':
        return heldProfile?.future ?? profile();
      case 'auth/language':
        if (failLanguage) {
          throw const AccountFailure(AccountFailureKind.network);
        }
        this.language = body!['preferredLanguage'] as String;
        return profile();
      case 'auth/exploration-preferences':
        return {
          'musicEnabled': false,
          'skyLayers': ['stars', 'cosmic'],
          'revision': 1,
        };
      case 'auth/logout':
        logouts++;
        if (offlineLogout) {
          throw const AccountFailure(AccountFailureKind.network);
        }
        return {};
      case 'notebook/':
        if (method == 'POST') {
          saves++;
          return {
            'id': body!['id'],
            'kind': body['kind'],
            'body': body['body'],
            'revision': 1,
          };
        }
        return {'userId': this.owner, 'entries': []};
      default:
        return {};
    }
  }
}
