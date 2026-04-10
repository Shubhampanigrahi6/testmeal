import 'package:hive_flutter/hive_flutter.dart';

part 'meal.g.dart';

@HiveType(typeId: 0)
class Meal extends HiveObject {
  @HiveField(0) final String id;
  @HiveField(1) final String name;
  @HiveField(2) final String? category;
  @HiveField(3) final String? area;
  @HiveField(4) final String? instructions;
  @HiveField(5) final String? thumbnail;
  @HiveField(6) final String? youtube;
  @HiveField(7) final List<Map<String, String>> ingredients;

  Meal({
    required this.id,
    required this.name,
    this.category,
    this.area,
    this.instructions,
    this.thumbnail,
    this.youtube,
    this.ingredients = const [],
  });

  factory Meal.fromJson(Map<String, dynamic> json) {
    List<Map<String, String>> ing = [];
    for (int i = 1; i <= 20; i++) {
      final ingredient = json['strIngredient$i']?.toString().trim();
      final measure = json['strMeasure$i']?.toString().trim();
      if (ingredient != null && ingredient.isNotEmpty && ingredient != 'null') {
        ing.add({'ingredient': ingredient, 'measure': measure ?? ''});
      }
    }
    return Meal(
      id: json['idMeal'] ?? '',
      name: json['strMeal'] ?? '',
      category: json['strCategory'],
      area: json['strArea'],
      instructions: json['strInstructions'],
      thumbnail: json['strMealThumb'],
      youtube: json['strYoutube'],
      ingredients: ing,
    );
  }
}