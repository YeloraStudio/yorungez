import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract interface class CredentialVault {
  Future<String?> read();
  Future<void> write(String value);
  Future<void> clear();
}

final class PlatformCredentialVault implements CredentialVault {
  PlatformCredentialVault(Uri origin)
    : _key =
          'yorungez.refresh.v1.${sha256.convert(utf8.encode(origin.toString()))}';
  final String _key;
  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(migrateWithBackup: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.unlocked_this_device,
      synchronizable: false,
    ),
  );
  @override
  Future<String?> read() => _storage.read(key: _key);
  @override
  Future<void> write(String value) => _storage.write(key: _key, value: value);
  @override
  Future<void> clear() => _storage.delete(key: _key);
}
