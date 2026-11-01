import 'package:flutter_test/flutter_test.dart';
import 'package:umz_self/src/api/models.dart';
import 'package:umz_self/src/logic/planner.dart';
import 'package:umz_self/src/logic/stats.dart';

Map<String, dynamic> offer(int selfId, int price, {int yarane = 900000}) => {
      'SelfId': selfId,
      'SelfName': 'self$selfId',
      'Price': price,
      'Yarane': yarane,
    };

Map<String, dynamic> meal(
  int mealId,
  String name, {
  int state = 0,
  List<Map<String, dynamic>>? foods,
  List<Object> reserved = const [],
}) =>
    {
      'Id': 20 + mealId,
      'MealId': mealId,
      'MealName': name,
      'Date': '1405/08/13',
      'MealState': state,
      'FoodCountLimit': [
        {'FoodType': 1, 'PriceType': 2, 'MaxCount': 1, 'TotalCount': 0},
      ],
      'FoodMenu': foods ??
          [
            {
              'FoodId': mealId * 10,
              'FoodName': 'food$mealId',
              'FoodType': 1,
              'SelfMenu': [offer(10, 1000000)],
            },
          ],
      'LastReserved': reserved,
    };

Day day(String date, List<Map<String, dynamic>> meals) => Day.fromJson({
      'DayDate': date,
      'DayTitle': 'd',
      'Meals': meals,
    });

void main() {
  group('planReservations', () {
    test('plans only open, unreserved meals that have a menu', () {
      final days = [
        day('1405/08/13', [
          meal(1, 'breakfast'),
          meal(2, 'lunch', state: 4), // closed
          meal(3, 'dinner', reserved: [<String, dynamic>{}]), // already booked
          meal(4, 'sahari', foods: []), // no menu
        ]),
      ];
      final plans = planReservations(days);
      expect(plans.map((p) => p.meal.name), ['breakfast']);
    });

    test('picks the first food and its cheapest dining hall', () {
      final days = [
        day('1405/08/13', [
          meal(1, 'lunch', foods: [
            {
              'FoodId': 1,
              'FoodName': 'first',
              'FoodType': 1,
              'SelfMenu': [offer(10, 3500000), offer(11, 3000000)],
            },
            {
              'FoodId': 2,
              'FoodName': 'second',
              'FoodType': 1,
              'SelfMenu': [offer(10, 100000)],
            },
          ]),
        ]),
      ];
      final p = planReservations(days).single;
      expect(p.food.name, 'first');
      expect(p.offer.selfId, 11);
      expect(p.price, 2100000); // 3,000,000 - 900,000 subsidy
    });

    test('preferred dining hall wins when offered', () {
      final days = [
        day('1405/08/13', [
          meal(1, 'lunch', foods: [
            {
              'FoodId': 1,
              'FoodName': 'f',
              'FoodType': 1,
              'SelfMenu': [offer(10, 3500000), offer(11, 3000000)],
            },
          ]),
        ]),
      ];
      expect(planReservations(days, preferredSelfId: 10).single.offer.selfId,
          10);
    });

    test('skips keys that failed before', () {
      final d = day('1405/08/13', [meal(1, 'breakfast')]);
      final key = mealKey(d, d.meals.single);
      expect(planReservations([d], skip: {key}), isEmpty);
    });
  });

  group('Stats', () {
    LedgerEntry e(String date, String meal, String food, int price,
            {bool auto = false, String self = 's1'}) =>
        LedgerEntry(
          date: date,
          mealId: 1,
          mealName: meal,
          foodName: food,
          selfName: self,
          priceRial: price,
          reserveNumber: 'r',
          at: DateTime(2026, 11, 2),
          auto: auto,
        );

    test('empty ledger gives zeros', () {
      final s = Stats.from([]);
      expect(s.count, 0);
      expect(s.totalRial, 0);
      expect(s.averageRial, 0);
      expect(s.mostExpensive, isNull);
    });

    test('totals, averages and groupings', () {
      final s = Stats.from([
        e('1405/08/13', 'lunch', 'a', 350000, auto: true),
        e('1405/08/13', 'lunch', 'a', 350000),
        e('1405/08/14', 'dinner', 'b', 200000, self: 's2'),
        e('1405/09/01', 'breakfast', 'c', 100000),
      ]);
      expect(s.count, 4);
      expect(s.totalRial, 1000000);
      expect(s.averageRial, 250000);
      expect(s.autoCount, 1);
      expect(s.manualCount, 3);
      expect(s.mealCount['lunch'], 2);
      expect(s.mealSpent['lunch'], 700000);
      expect(s.monthSpent.keys.toList(), ['1405/08', '1405/09']);
      expect(s.monthSpent['1405/08'], 900000);
      expect(s.topFoods.keys.first, 'a');
      expect(s.selfCount['s1'], 3);
      expect(s.mostExpensive!.priceRial, 350000);
    });

    test('ledger entry survives a JSON round trip', () {
      final original = e('1405/08/13', 'lunch', 'a', 350000, auto: true);
      final copy = LedgerEntry.fromJson(original.toJson());
      expect(copy.date, original.date);
      expect(copy.priceRial, 350000);
      expect(copy.auto, isTrue);
      expect(copy.at, original.at);
    });
  });
}
