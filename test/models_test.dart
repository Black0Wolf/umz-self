import 'package:flutter_test/flutter_test.dart';
import 'package:umz_self/src/api/models.dart';
import 'package:umz_self/src/ui/strings.dart';

Map<String, dynamic> _meal({int state = 0}) => {
      'Id': 21,
      'MealId': 1,
      'MealName': 'صبحانه',
      'Date': '1405/08/13',
      'MealState': state,
      'MealStateTitle': 'فعال',
      'FoodCountLimit': [
        {'FoodType': 1, 'PriceType': 1, 'MaxCount': 0, 'TotalCount': 0},
        {'FoodType': 1, 'PriceType': 2, 'MaxCount': 1, 'TotalCount': 1},
      ],
      'FoodMenu': [
        {
          'FoodId': 1298,
          'FoodName': 'ص کره با پنیر و عسل',
          'FoodType': 1,
          'SelfMenu': [
            {
              'SelfId': 10,
              'SelfName': 'سلف جهانگردی چالوس',
              'Price': 1000000,
              'Yarane': 900000,
              'MaxReserveCount': 0,
              'HasDailySale': false,
            }
          ],
        }
      ],
      'LastReserved': [],
    };

void main() {
  test('Day.fromJson parses a week-view day', () {
    final d = Day.fromJson({
      'DayDate': '1405/08/13',
      'MiladiDayDate': '2026-11-04T00:00:00',
      'DayTitle': 'چهارشنبه',
      'DayState': 0,
      'ActiveDay': false,
      'Meals': [_meal()],
    });
    expect(d.date, '1405/08/13');
    expect(d.miladi, DateTime(2026, 11, 4));
    expect(d.meals.single.isOpen, isTrue);
    expect(d.mealsWithMenu, hasLength(1));
    final offer = d.meals.single.foods.single.offers.single;
    expect(offer.studentPays, 100000);
  });

  test('closed meal is not open', () {
    expect(Meal.fromJson(_meal(state: 4)).isOpen, isFalse);
  });

  test('ReserveRow matches the payload the site accepted', () {
    final day = Day.fromJson({'DayDate': '1405/08/13', 'DayTitle': 'چهارشنبه'});
    final meal = Meal.fromJson(_meal());
    final food = meal.foods.single;
    final offer = food.offers.single;
    final j = ReserveRow.forOffer(day: day, meal: meal, food: food, offer: offer)
        .toJson();
    expect(j['Id'], 21);
    expect(j['MealId'], 1);
    expect(j['FoodId'], 1298);
    expect(j['SelfId'], 10);
    expect(j['Counts'], 1);
    expect(j['PriceType'], 2);
    expect(j['Price'], 100000);
    expect(j['SobsidPrice'], 900000);
    expect(j['OP'], 1);
    expect(j['Type'], 1);
  });

  test('full price when no subsidised limit exists', () {
    final m = _meal();
    (m['FoodCountLimit'] as List).removeLast();
    final meal = Meal.fromJson(m);
    expect(meal.priceTypeFor(1), priceTypeFull);
  });

  test('formatToman converts rial and groups digits', () {
    expect(formatToman(-850000), '-85,000');
    expect(formatToman(100000), '10,000');
    expect(formatToman(0), '0');
    expect(formatToman(12345670), '1,234,567');
  });
}
