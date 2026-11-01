/// Decides what "reserve everything available" would book. Pure Dart.
library;

import '../api/models.dart';

/// Stable key for one meal on one day, used to remember failures.
String mealKey(Day day, Meal meal) => '${day.date}|${meal.mealId}';

class PlannedReservation {
  PlannedReservation(this.day, this.meal, this.food, this.offer);

  final Day day;
  final Meal meal;
  final Food food;
  final SelfOffer offer;

  ReserveRow get row =>
      ReserveRow.forOffer(day: day, meal: meal, food: food, offer: offer);

  /// What the student pays, in rial.
  int get price => row.unitPrice;

  String get key => mealKey(day, meal);
}

/// One planned reservation per open, not-yet-reserved meal.
///
/// Picks the first food on the menu and its cheapest dining hall. With
/// [preferredSelfId], that hall is used whenever the food is offered there.
/// Meals whose key is in [skip] are left out.
List<PlannedReservation> planReservations(
  Iterable<Day> days, {
  Set<String> skip = const {},
  int? preferredSelfId,
}) {
  final plans = <PlannedReservation>[];
  final seen = <String>{};
  for (final day in days) {
    for (final meal in day.meals) {
      if (!meal.isOpen || meal.hasReservation) continue;
      final key = mealKey(day, meal);
      if (skip.contains(key) || !seen.add(key)) continue;
      for (final food in meal.foods) {
        if (food.offers.isEmpty) continue;
        SelfOffer? chosen;
        if (preferredSelfId != null) {
          for (final o in food.offers) {
            if (o.selfId == preferredSelfId) chosen = o;
          }
        }
        chosen ??= food.offers.reduce(
            (a, b) => b.studentPays < a.studentPays ? b : a);
        plans.add(PlannedReservation(day, meal, food, chosen));
        break;
      }
    }
  }
  return plans;
}
