import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../logic/stats.dart';

/// Per-user record of reservations made through the app (feeds the stats).
abstract class LedgerStore {
  Future<List<LedgerEntry>> load(String username);
  Future<void> save(String username, List<LedgerEntry> entries);
}

class PrefsLedgerStore implements LedgerStore {
  String _key(String username) => 'ledger:$username';

  @override
  Future<List<LedgerEntry>> load(String username) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(username));
    if (raw == null || raw.isEmpty) return [];
    try {
      return (jsonDecode(raw) as List)
          .map((e) => LedgerEntry.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } on Object {
      return [];
    }
  }

  @override
  Future<void> save(String username, List<LedgerEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _key(username), jsonEncode(entries.map((e) => e.toJson()).toList()));
  }
}
