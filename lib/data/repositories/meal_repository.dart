import '../../core/models/meal.dart';
import '../datasources/local_datasource.dart';
import '../datasources/remote_datasource.dart';

class MealRepository {
  final RemoteDataSource _remote;
  final LocalDataSource _local;

  MealRepository(this._remote, this._local);

  Future<List<Meal>> getMealsByCategory(String category) async =>
      _remote.getMealsByCategory(category);

  Future<List<Meal>> getMealsByArea(String area) async =>
      _remote.getMealsByArea(area);

  Future<List<Meal>> getMealsByIngredient(String ingredient) async =>
      _remote.getMealsByIngredient(ingredient);

  Future<List<String>> getAllCategories() async => _remote.getAllCategories();

  Future<List<String>> getAllAreas() async => _remote.getAllAreas(); // New

  Future<List<String>> getAllIngredients() async => _remote.getAllIngredients();

  Future<List<Meal>> searchMeals(String query) async {
    try {
      final meals = await _remote.searchMeals(query);
      if (meals.isNotEmpty) await _local.cacheMeals(meals);
      return meals;
    } catch (e) {
      return await _local.getCachedMeals();
    }
  }

  // New: Random meals fallback
  Future<List<Meal>> getRandomMeals({int count = 8}) async {
    List<Meal> meals = [];
    for (int i = 0; i < count; i++) {
      final random = await _remote.getRandomMeal();
      if (random != null) meals.add(random);
    }
    await _local.cacheMeals(meals);
    return meals;
  }
}