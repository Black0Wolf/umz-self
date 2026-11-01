/// Plain-Dart models for the Jahangostar reservation API. No Flutter imports.
library;

int _i(Object? v) => v is int
    ? v
    : v is num
        ? v.toInt()
        : int.tryParse('$v') ?? 0;

String _s(Object? v) => v == null ? '' : '$v';

bool _b(Object? v) => v == true;

List<Map<String, dynamic>> _maps(Object? v) => v is List
    ? v.whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList()
    : <Map<String, dynamic>>[];

/// Server price types: 1 = full ("free") price, 2 = subsidised ("yarane").
const int priceTypeFull = 1;
const int priceTypeSubsidised = 2;

/// Meal states seen in the wild. Only [mealStateOpen] means "can reserve".
const int mealStateOpen = 0;

/// One dining hall offering a food, with its prices in rial.
class SelfOffer {
  SelfOffer({
    required this.selfId,
    required this.selfName,
    required this.price,
    required this.yarane,
    required this.maxReserveCount,
    required this.hasDailySale,
  });

  factory SelfOffer.fromJson(Map<String, dynamic> j) => SelfOffer(
        selfId: _i(j['SelfId']),
        selfName: _s(j['SelfName']),
        price: _i(j['Price']),
        yarane: _i(j['Yarane']),
        maxReserveCount: _i(j['MaxReserveCount']),
        hasDailySale: _b(j['HasDailySale']),
      );

  final int selfId;
  final String selfName;

  /// Full price in rial.
  final int price;

  /// Subsidy in rial.
  final int yarane;
  final int maxReserveCount;
  final bool hasDailySale;

  /// What the student pays with the subsidy applied, in rial.
  int get studentPays => price - yarane;
}

class Food {
  Food({
    required this.foodId,
    required this.name,
    required this.foodType,
    required this.compounds,
    required this.foodState,
    required this.offers,
  });

  factory Food.fromJson(Map<String, dynamic> j) => Food(
        foodId: _i(j['FoodId']),
        name: _s(j['FoodName']),
        foodType: _i(j['FoodType']),
        compounds: _s(j['Compounds']),
        foodState: _i(j['FoodState']),
        offers: _maps(j['SelfMenu']).map(SelfOffer.fromJson).toList(),
      );

  final int foodId;
  final String name;
  final int foodType;
  final String compounds;
  final int foodState;
  final List<SelfOffer> offers;
}

class FoodLimit {
  FoodLimit({
    required this.foodType,
    required this.priceType,
    required this.maxCount,
    required this.totalCount,
  });

  factory FoodLimit.fromJson(Map<String, dynamic> j) => FoodLimit(
        foodType: _i(j['FoodType']),
        priceType: _i(j['PriceType']),
        maxCount: _i(j['MaxCount']),
        totalCount: _i(j['TotalCount']),
      );

  final int foodType;
  final int priceType;
  final int maxCount;
  final int totalCount;
}

class Meal {
  Meal({
    required this.id,
    required this.mealId,
    required this.name,
    required this.date,
    required this.dayName,
    required this.state,
    required this.stateTitle,
    required this.canChangeSelf,
    required this.limits,
    required this.foods,
    required this.lastReserved,
  });

  factory Meal.fromJson(Map<String, dynamic> j) => Meal(
        id: _i(j['Id']),
        mealId: _i(j['MealId']),
        name: _s(j['MealName']),
        date: _s(j['Date']),
        dayName: _s(j['DayName']),
        state: _i(j['MealState']),
        stateTitle: _s(j['MealStateTitle']),
        canChangeSelf: _b(j['CanChangeSelf']),
        limits: _maps(j['FoodCountLimit']).map(FoodLimit.fromJson).toList(),
        foods: _maps(j['FoodMenu']).map(Food.fromJson).toList(),
        lastReserved: _maps(j['LastReserved']),
      );

  /// Row id used by the reserve POST (`Id`), distinct from [mealId].
  final int id;
  final int mealId;
  final String name;

  /// Jalali date, e.g. `1405/08/13`.
  final String date;
  final String dayName;
  final int state;
  final String stateTitle;
  final bool canChangeSelf;
  final List<FoodLimit> limits;
  final List<Food> foods;

  /// Raw already-reserved entries; shape not fully mapped yet.
  final List<Map<String, dynamic>> lastReserved;

  bool get isOpen => state == mealStateOpen;

  /// Subsidised price applies when a type-2 limit exists for [foodType].
  /// (Mirrors the web app; exact limit semantics are not fully verified.)
  int priceTypeFor(int foodType) {
    final sub = limits.any((l) =>
        l.foodType == foodType &&
        l.priceType == priceTypeSubsidised &&
        l.maxCount > 0);
    return sub ? priceTypeSubsidised : priceTypeFull;
  }
}

class Day {
  Day({
    required this.date,
    required this.miladi,
    required this.title,
    required this.state,
    required this.stateTitle,
    required this.active,
    required this.meals,
  });

  factory Day.fromJson(Map<String, dynamic> j) => Day(
        date: _s(j['DayDate']),
        miladi: DateTime.tryParse(_s(j['MiladiDayDate'])),
        title: _s(j['DayTitle']),
        state: _i(j['DayState']),
        stateTitle: _s(j['DayStateTitle']),
        active: _b(j['ActiveDay']),
        meals: _maps(j['Meals']).map(Meal.fromJson).toList(),
      );

  final String date;
  final DateTime? miladi;
  final String title;
  final int state;
  final String stateTitle;
  final bool active;
  final List<Meal> meals;

  /// Meals that actually have a menu.
  Iterable<Meal> get mealsWithMenu => meals.where((m) => m.foods.isNotEmpty);
}

/// One row of the reserve POST body (always sent as a one-meal list).
class ReserveRow {
  ReserveRow({
    required this.date,
    required this.meal,
    required this.food,
    required this.offer,
    required this.priceType,
    this.count = 1,
    this.row = 1,
    this.dayName = '',
    this.dayIndex = 0,
    this.mealIndex = 0,
  });

  /// Builds a row the same way the web app does.
  factory ReserveRow.forOffer({
    required Day day,
    required Meal meal,
    required Food food,
    required SelfOffer offer,
    int? priceType,
  }) =>
      ReserveRow(
        date: day.date,
        meal: meal,
        food: food,
        offer: offer,
        priceType: priceType ?? meal.priceTypeFor(food.foodType),
        dayName: day.title,
      );

  final String date;
  final Meal meal;
  final Food food;
  final SelfOffer offer;
  final int priceType;
  final int count;
  final int row;
  final String dayName;
  final int dayIndex;
  final int mealIndex;

  /// Price per unit the student pays, in rial.
  int get unitPrice =>
      priceType == priceTypeSubsidised ? offer.price - offer.yarane : offer.price;

  Map<String, dynamic> toJson() => {
        'Row': row,
        'Id': meal.id,
        'Date': date,
        'MealId': meal.mealId,
        'FoodId': food.foodId,
        'FoodName': food.name,
        'SelfId': offer.selfId,
        'LastCounts': 0,
        'Counts': count,
        'Price': unitPrice,
        'SobsidPrice': offer.yarane,
        'PriceType': priceType,
        'State': 0,
        'Type': food.foodType,
        'OP': 1,
        'OpCategory': 1,
        'Provider': 1,
        'Saved': 0,
        'MealName': meal.name,
        'DayName': dayName,
        'SelfName': offer.selfName,
        'DayIndex': dayIndex,
        'MealIndex': mealIndex,
      };
}

/// One element of the reserve POST response. HTTP status is 200 even on
/// failure, so callers must look at [ok] / [stateMessage].
class ReserveResult {
  ReserveResult({
    required this.row,
    required this.date,
    required this.mealId,
    required this.foodId,
    required this.selfId,
    required this.count,
    required this.price,
    required this.priceType,
    required this.state,
    required this.stateCode,
    required this.stateMessage,
    required this.reserveNumber,
  });

  factory ReserveResult.fromJson(Map<String, dynamic> j) => ReserveResult(
        row: _i(j['Row']),
        date: _s(j['Date']),
        mealId: _i(j['MealID']),
        foodId: _i(j['FoodID']),
        selfId: _i(j['SelfID']),
        count: _i(j['Count']),
        price: _i(j['Price']),
        priceType: _i(j['PriceType']),
        state: _i(j['State']),
        stateCode: _i(j['StateCode']),
        stateMessage: j['StateMessage'] == null ? null : _s(j['StateMessage']),
        reserveNumber:
            j['ReserveNumber'] == null ? null : _s(j['ReserveNumber']),
      );

  final int row;
  final String date;
  final int mealId;
  final int foodId;
  final int selfId;
  final int count;
  final int price;
  final int priceType;
  final int state;
  final int stateCode;
  final String? stateMessage;
  final String? reserveNumber;

  /// A successful reservation carries a reserve number. Known failure:
  /// stateCode 3 = insufficient balance (no reserve number).
  bool get ok => reserveNumber != null && reserveNumber!.isNotEmpty;
}
