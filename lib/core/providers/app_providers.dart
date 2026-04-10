import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/local_datasource.dart';
import '../../data/datasources/remote_datasource.dart';
import '../models/meal.dart';
import '../../data/repositories/meal_repository.dart';
import '../../services/location_service.dart';

// Core
final remoteDataSourceProvider = Provider((ref) => RemoteDataSource());
final localDataSourceProvider = Provider((ref) => LocalDataSource());
final mealRepositoryProvider = Provider((ref) =>
    MealRepository(ref.watch(remoteDataSourceProvider), ref.watch(localDataSourceProvider)));

final locationServiceProvider = Provider((ref) => LocationService());

// Dynamic Data from API
final categoriesProvider = FutureProvider<List<String>>((ref) async {
  final repo = ref.watch(mealRepositoryProvider);
  return await repo.getAllCategories();
});

final areasProvider = FutureProvider<List<String>>((ref) async {
  final repo = ref.watch(mealRepositoryProvider);
  return await repo.getAllAreas();
});

final ingredientsListProvider = FutureProvider<List<String>>((ref) async {
  final repo = ref.watch(mealRepositoryProvider);
  return await repo.getAllIngredients();
});

// Smart Time-based Recommended Category (Dynamic)
final recommendedCategoryProvider = FutureProvider<String>((ref) async {
  final categories = await ref.watch(categoriesProvider.future);
  final hour = DateTime.now().hour;

  // Time-based priority mapping (dynamic fallback)
  if (hour >= 5 && hour < 11) {
    // Breakfast time
    if (categories.contains('Breakfast')) return 'Breakfast';
    if (categories.contains('Pork')) return 'Pork';
  }
  else if (hour >= 11 && hour < 16) {
    // Lunch time
    if (categories.contains('Chicken')) return 'Chicken';
    if (categories.contains('Beef')) return 'Beef';
    if (categories.contains('Pasta')) return 'Pasta';
  }
  else if (hour >= 16 && hour < 22) {
    // Dinner time
    if (categories.contains('Seafood')) return 'Seafood';
    if (categories.contains('Vegetarian')) return 'Vegetarian';
    if (categories.contains('Lamb')) return 'Lamb';
  }
  else {
    // Late night / Dessert
    if (categories.contains('Dessert')) return 'Dessert';
  }

  // Ultimate fallback - return first available category
  return categories.isNotEmpty ? categories.first : 'Chicken';
});

// Home Meals - Fully Dynamic (Location → Time-based → Random)
final homeMealsProvider = FutureProvider<List<Meal>>((ref) async {
  final repo = ref.watch(mealRepositoryProvider);
  final locationService = ref.watch(locationServiceProvider);
  final recommendedCat = await ref.watch(recommendedCategoryProvider.future);

  try {
    // Priority 1: Location-based
    final country = await locationService.getUserCountry();
    if (country != null && country.isNotEmpty) {
      final locationMeals = await repo.getMealsByArea(country);
      if (locationMeals.isNotEmpty) return locationMeals;
    }

    // Priority 2: Time-based recommended category
    final timeMeals = await repo.getMealsByCategory(recommendedCat);
    if (timeMeals.isNotEmpty) return timeMeals;

    // Priority 3: Random meals as final fallback
    return await repo.getRandomMeals(count: 10);
  } catch (e) {
    // Full offline fallback
    return await ref.watch(localDataSourceProvider).getCachedMeals();
  }
});

// Search Provider
final searchMealsProvider = FutureProvider.family<List<Meal>, String>((ref, query) async {
  if (query.trim().isEmpty) return [];
  final repo = ref.watch(mealRepositoryProvider);
  return await repo.searchMeals(query.trim());
});

// Filter Providers
final categoryMealsProvider = FutureProvider.family<List<Meal>, String>((ref, category) async {
  final repo = ref.watch(mealRepositoryProvider);
  try {
    final meals = await repo.getMealsByCategory(category);
    await ref.watch(localDataSourceProvider).cacheMeals(meals);
    return meals;
  } catch (e) {
    return await ref.watch(localDataSourceProvider).getCachedMeals();
  }
});

final areaMealsProvider = FutureProvider.family<List<Meal>, String>((ref, area) async {
  final repo = ref.watch(mealRepositoryProvider);
  try {
    final meals = await repo.getMealsByArea(area);
    await ref.watch(localDataSourceProvider).cacheMeals(meals);
    return meals;
  } catch (e) {
    return await ref.watch(localDataSourceProvider).getCachedMeals();
  }
});

final ingredientMealsProvider = FutureProvider.family<List<Meal>, String>((ref, ingredient) async {
  final repo = ref.watch(mealRepositoryProvider);
  try {
    return await repo.getMealsByIngredient(ingredient);
  } catch (e) {
    return await ref.watch(localDataSourceProvider).getCachedMeals();
  }
});

// Favorites
final favoritesProvider = StateNotifierProvider<FavoritesNotifier, List<Meal>>((ref) {
  return FavoritesNotifier(ref.watch(localDataSourceProvider));
});

class FavoritesNotifier extends StateNotifier<List<Meal>> {
  final LocalDataSource _local;
  FavoritesNotifier(this._local) : super([]) {
    _load();
  }
  Future<void> _load() async => state = await _local.getFavorites();

  Future<void> toggleFavorite(Meal meal) async {
    await _local.toggleFavorite(meal);
    await _load();
  }
}