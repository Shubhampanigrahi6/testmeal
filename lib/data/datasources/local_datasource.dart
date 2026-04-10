import 'package:hive_flutter/hive_flutter.dart';
import '../../core/models/meal.dart';

class LocalDataSource {
  static const String _favoritesBox = 'favorites';
  static const String _cacheBox = 'cached_meals';

  Future<void> init() async {
    await Hive.initFlutter();
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(MealAdapter());
    }
    await Hive.openBox<Meal>(_favoritesBox);
    await Hive.openBox<Meal>(_cacheBox);
  }

  Future<List<Meal>> getFavorites() async {
    final box = Hive.box<Meal>(_favoritesBox);
    return box.values.toList();
  }

  Future<void> toggleFavorite(Meal meal) async {
    final box = Hive.box<Meal>(_favoritesBox);
    if (box.containsKey(meal.id)) {
      await box.delete(meal.id);
    } else {
      // Create a fresh copy to avoid "same instance" error
      final copy = Meal(
        id: meal.id,
        name: meal.name,
        category: meal.category,
        area: meal.area,
        instructions: meal.instructions,
        thumbnail: meal.thumbnail,
        youtube: meal.youtube,
        ingredients: List.from(meal.ingredients),
      );
      await box.put(meal.id, copy);
    }
  }

  Future<void> cacheMeals(List<Meal> meals) async {
    final box = Hive.box<Meal>(_cacheBox);
    await box.clear();
    for (var meal in meals) {
      final copy = Meal(
        id: meal.id,
        name: meal.name,
        category: meal.category,
        area: meal.area,
        instructions: meal.instructions,
        thumbnail: meal.thumbnail,
        youtube: meal.youtube,
        ingredients: List.from(meal.ingredients),
      );
      await box.put(meal.id, copy);
    }
  }

  Future<List<Meal>> getCachedMeals() async {
    final box = Hive.box<Meal>(_cacheBox);
    return box.values.toList();
  }
}