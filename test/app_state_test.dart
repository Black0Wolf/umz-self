import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:umz_self/src/api/umz_client.dart';
import 'package:umz_self/src/logic/stats.dart';
import 'package:umz_self/src/state/app_state.dart';
import 'package:umz_self/src/storage/credential_store.dart';
import 'package:umz_self/src/storage/ledger_store.dart';

import 'fake_server.dart';
import 'happy_server.dart';

class MemCredentialStore implements CredentialStore {
  final accountsList = <Account>[];
  String? last;
  String? lang;
  bool auto = false;

  @override
  Future<List<Account>> accounts() async => accountsList;
  @override
  Future<void> save(Account a) async {
    accountsList
      ..removeWhere((x) => x.username == a.username)
      ..add(a);
    last = a.username;
  }

  @override
  Future<void> remove(String u) async =>
      accountsList.removeWhere((x) => x.username == u);
  @override
  Future<String?> lastUsername() async => last;
  @override
  Future<void> setLastUsername(String? u) async => last = u;
  @override
  Future<String?> language() async => lang;
  @override
  Future<void> setLanguage(String l) async => lang = l;
  @override
  Future<bool> autoReserve() async => auto;
  @override
  Future<void> setAutoReserve(bool on) async => auto = on;
}

class MemLedgerStore implements LedgerStore {
  final data = <String, List<LedgerEntry>>{};
  @override
  Future<List<LedgerEntry>> load(String u) async => data[u] ?? [];
  @override
  Future<void> save(String u, List<LedgerEntry> e) async => data[u] = e;
}

Map<String, dynamic> _meal(int mealId, String name) => {
      'Id': 20 + mealId,
      'MealId': mealId,
      'MealName': name,
      'Date': '1405/08/13',
      'MealState': 0,
      'MealStateTitle': 'open',
      'FoodCountLimit': [
        {'FoodType': 1, 'PriceType': 2, 'MaxCount': 1, 'TotalCount': 0},
      ],
      'FoodMenu': [
        {
          'FoodId': mealId * 10,
          'FoodName': 'food$mealId',
          'FoodType': 1,
          'SelfMenu': [
            {
              'SelfId': 10,
              'SelfName': 'hall',
              'Price': 1000000,
              'Yarane': 900000,
            }
          ],
        }
      ],
      'LastReserved': [],
    };

Map<String, dynamic> _result(Map row, {required bool ok}) => {
      'Row': row['Row'],
      'Date': row['Date'],
      'MealID': row['MealId'],
      'FoodID': row['FoodId'],
      'SelfID': row['SelfId'],
      'Count': 1,
      'Price': row['Price'],
      'PriceType': 2,
      'State': ok ? 1 : 2,
      'StateCode': ok ? 0 : 3,
      'StateMessage': ok ? null : 'موجودی کافی نمی باشد',
      'ReserveNumber': ok ? 'R${row['MealId']}' : null,
    };

/// Server with one day of three open meals. [okMeals] lists the MealIds the
/// reserve call accepts; any other meal is refused for low balance.
(FakeAdapter, List<int>) _server(Set<int> okMeals) {
  final server = happyServer();
  final accepted = <int>[];
  server.routes['GET /api/v0/Reservation'] = (o) => jsonBody([
        {
          'DayDate': '1405/08/13',
          'DayTitle': 'wed',
          'DayState': 0,
          'Meals': [_meal(1, 'breakfast'), _meal(2, 'lunch'), _meal(3, 'dinner')],
        }
      ]);
  server.routes['POST /api/v0/Reservation'] = (o) {
    final rows = (o.data as List).cast<Map>();
    final results = <Map<String, dynamic>>[];
    for (final r in rows) {
      final ok = okMeals.contains(r['MealId']);
      if (ok) accepted.add(r['MealId'] as int);
      results.add(_result(r, ok: ok));
    }
    return jsonBody(results);
  };
  return (server, accepted);
}

AppState _app(FakeAdapter server, MemLedgerStore ledger) => AppState(
      client: UmzClient(dio: Dio()..httpClientAdapter = server),
      store: MemCredentialStore(),
      ledgerStore: ledger,
      pauseBetweenReserves: Duration.zero,
    );

void main() {
  test('reserveAll books every open meal and records them in the ledger',
      () async {
    final (server, booked) = _server({1, 2, 3});
    final ledger = MemLedgerStore();
    final app = _app(server, ledger);
    await app.login('user', 'good');

    final plans = app.planVisibleWeek();
    expect(plans, hasLength(3));

    final summary = await app.reserveAll(plans);
    expect(summary.reserved, 3);
    expect(summary.spentRial, 300000); // 3 x (1,000,000 - 900,000)
    expect(summary.failures, isEmpty);
    expect(booked, [1, 2, 3]);
    expect(app.ledger, hasLength(3));
    expect(ledger.data['user'], hasLength(3));
    expect(app.stats.totalRial, 300000);
  });

  test('reserveAll stops at the first insufficient-balance refusal', () async {
    final (server, booked) = _server({1}); // meal 2 refused -> stop
    final app = _app(server, MemLedgerStore());
    await app.login('user', 'good');

    final summary = await app.reserveAll(app.planVisibleWeek());
    expect(summary.reserved, 1);
    expect(summary.stoppedForBalance, isTrue);
    expect(summary.failures.single, contains('موجودی'));
    expect(booked, [1]); // meal 3 was never attempted
    expect(app.ledger, hasLength(1));
  });

  test('auto tick reserves once, then waits while the balance is unchanged',
      () async {
    final (server, booked) = _server({}); // everything refused
    final app = _app(server, MemLedgerStore());
    await app.login('user', 'good');

    await app.autoTick();
    expect(app.activity.any((l) => l.contains('Balance too low') ||
        l.contains('اعتبار کافی نیست')), isTrue);
    final attempts = server.log.where((l) => l == 'POST /api/v0/Reservation');
    expect(attempts.length, 1); // stopped after the first refusal

    await app.autoTick(); // credit unchanged -> no new attempts
    expect(
        server.log.where((l) => l == 'POST /api/v0/Reservation').length, 1);
    expect(booked, isEmpty);
  });
}
