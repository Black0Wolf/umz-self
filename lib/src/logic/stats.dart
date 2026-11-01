/// Spending statistics from the reservations this app made. Pure Dart.
library;

/// One successful reservation made through the app.
class LedgerEntry {
  const LedgerEntry({
    required this.date,
    required this.mealId,
    required this.mealName,
    required this.foodName,
    required this.selfName,
    required this.priceRial,
    required this.reserveNumber,
    required this.at,
    required this.auto,
  });

  factory LedgerEntry.fromJson(Map<String, dynamic> j) => LedgerEntry(
        date: '${j['date']}',
        mealId: (j['mealId'] as num?)?.toInt() ?? 0,
        mealName: '${j['mealName']}',
        foodName: '${j['foodName']}',
        selfName: '${j['selfName']}',
        priceRial: (j['priceRial'] as num?)?.toInt() ?? 0,
        reserveNumber: '${j['reserveNumber']}',
        at: DateTime.tryParse('${j['at']}') ?? DateTime.fromMillisecondsSinceEpoch(0),
        auto: j['auto'] == true,
      );

  /// Jalali date of the meal, e.g. `1405/08/13`.
  final String date;
  final int mealId;
  final String mealName;
  final String foodName;
  final String selfName;
  final int priceRial;
  final String reserveNumber;

  /// When the app made the reservation.
  final DateTime at;

  /// True if the auto-reserve timer made it.
  final bool auto;

  /// `1405/08`.
  String get month => date.length >= 7 ? date.substring(0, 7) : date;

  Map<String, dynamic> toJson() => {
        'date': date,
        'mealId': mealId,
        'mealName': mealName,
        'foodName': foodName,
        'selfName': selfName,
        'priceRial': priceRial,
        'reserveNumber': reserveNumber,
        'at': at.toIso8601String(),
        'auto': auto,
      };
}

class Stats {
  Stats._({
    required this.count,
    required this.totalRial,
    required this.autoCount,
    required this.mealCount,
    required this.mealSpent,
    required this.monthSpent,
    required this.topFoods,
    required this.selfCount,
    required this.mostExpensive,
  });

  factory Stats.from(List<LedgerEntry> entries) {
    var total = 0;
    var auto = 0;
    final mealCount = <String, int>{};
    final mealSpent = <String, int>{};
    final monthSpent = <String, int>{};
    final foods = <String, int>{};
    final selfs = <String, int>{};
    LedgerEntry? priciest;
    for (final e in entries) {
      total += e.priceRial;
      if (e.auto) auto++;
      mealCount[e.mealName] = (mealCount[e.mealName] ?? 0) + 1;
      mealSpent[e.mealName] = (mealSpent[e.mealName] ?? 0) + e.priceRial;
      monthSpent[e.month] = (monthSpent[e.month] ?? 0) + e.priceRial;
      foods[e.foodName] = (foods[e.foodName] ?? 0) + 1;
      selfs[e.selfName] = (selfs[e.selfName] ?? 0) + 1;
      if (priciest == null || e.priceRial > priciest.priceRial) priciest = e;
    }
    return Stats._(
      count: entries.length,
      totalRial: total,
      autoCount: auto,
      mealCount: _byValueDesc(mealCount),
      mealSpent: mealSpent,
      monthSpent: Map.fromEntries(
          monthSpent.entries.toList()..sort((a, b) => a.key.compareTo(b.key))),
      topFoods: _byValueDesc(foods, limit: 5),
      selfCount: _byValueDesc(selfs),
      mostExpensive: priciest,
    );
  }

  final int count;

  /// Total paid by the student, in rial.
  final int totalRial;
  final int autoCount;

  /// Meals reserved per meal name (breakfast / lunch / dinner ...).
  final Map<String, int> mealCount;
  final Map<String, int> mealSpent;

  /// Rial spent per Jalali month, oldest first.
  final Map<String, int> monthSpent;
  final Map<String, int> topFoods;
  final Map<String, int> selfCount;
  final LedgerEntry? mostExpensive;

  int get averageRial => count == 0 ? 0 : totalRial ~/ count;
  int get manualCount => count - autoCount;
}

Map<String, int> _byValueDesc(Map<String, int> m, {int? limit}) {
  final sorted = m.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  final taken = limit == null ? sorted : sorted.take(limit);
  return {for (final e in taken) e.key: e.value};
}
