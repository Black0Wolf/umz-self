import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class Account {
  const Account(this.username, this.password);

  factory Account.fromJson(Map<String, dynamic> j) =>
      Account('${j['u']}', '${j['p']}');

  final String username;
  final String password;

  Map<String, dynamic> toJson() => {'u': username, 'p': password};
}

/// Saved logins in the OS secure store (Windows DPAPI / Android Keystore).
abstract class CredentialStore {
  Future<List<Account>> accounts();
  Future<void> save(Account account);
  Future<void> remove(String username);
  Future<String?> lastUsername();
  Future<void> setLastUsername(String? username);
  Future<String?> language();
  Future<void> setLanguage(String lang);
}

class SecureCredentialStore implements CredentialStore {
  SecureCredentialStore([FlutterSecureStorage? storage])
      : _s = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _s;

  static const _kAccounts = 'accounts';
  static const _kLast = 'last_username';
  static const _kLang = 'language';

  @override
  Future<List<Account>> accounts() async {
    final raw = await _s.read(key: _kAccounts);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => Account.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } on Object {
      return [];
    }
  }

  Future<void> _write(List<Account> list) => _s.write(
      key: _kAccounts, value: jsonEncode(list.map((a) => a.toJson()).toList()));

  @override
  Future<void> save(Account account) async {
    final list = await accounts()
      ..removeWhere((a) => a.username == account.username)
      ..add(account);
    await _write(list);
    await setLastUsername(account.username);
  }

  @override
  Future<void> remove(String username) async {
    final list = await accounts()
      ..removeWhere((a) => a.username == username);
    await _write(list);
    if (await lastUsername() == username) await setLastUsername(null);
  }

  @override
  Future<String?> lastUsername() => _s.read(key: _kLast);

  @override
  Future<void> setLastUsername(String? username) => username == null
      ? _s.delete(key: _kLast)
      : _s.write(key: _kLast, value: username);

  @override
  Future<String?> language() => _s.read(key: _kLang);

  @override
  Future<void> setLanguage(String lang) => _s.write(key: _kLang, value: lang);
}
