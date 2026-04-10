import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/models/meal.dart';

const String baseUrl = 'https://www.themealdb.com/api/json/v1/1/';

class RemoteDataSource {
  // Smart Search: by name or first letter
  Future<List<Meal>> searchMeals(String query) async {
    if (query.trim().isEmpty) return [];

    final trimmed = query.trim();
    Uri url;

    if (trimmed.length == 1) {
      url = Uri.parse('${baseUrl}search.php?f=${trimmed.toLowerCase()}');
    } else {
      url = Uri.parse('${baseUrl}search.php?s=$trimmed');
    }

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body)['meals'];
        if (data == null) return [];
        return (data as List).map((m) => Meal.fromJson(m)).toList();
      }
      return [];
    } catch (e) {
      print("Search error: $e");
      return [];
    }
  }

  Future<List<Meal>> getMealsByCategory(String category) async {
    final res = await http.get(Uri.parse('${baseUrl}filter.php?c=$category'));
    return _parseFilter(res);
  }

  Future<List<Meal>> getMealsByIngredient(String ingredient) async {
    final res = await http.get(Uri.parse('${baseUrl}filter.php?i=$ingredient'));
    return _parseFilter(res);
  }

  Future<List<String>> getAllIngredients() async {
    try {
      final response = await http.get(Uri.parse('${baseUrl}list.php?i=list'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body)['meals'] as List?;
        return data?.map((e) => e['strIngredient'].toString()).toList() ?? [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Meal?> getRandomMeal() async {
    try {
      final response = await http.get(Uri.parse('${baseUrl}random.php'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body)['meals'] as List?;
        if (data != null && data.isNotEmpty) {
          return Meal.fromJson(data[0]);
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<List<String>> getAllCategories() async {
    try {
      final response = await http.get(Uri.parse('${baseUrl}categories.php'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body)['categories'] as List?;
        return data?.map((e) => e['strCategory'].toString()).toList() ?? [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<String>> getAllAreas() async {
    try {
      final response = await http.get(Uri.parse('${baseUrl}list.php?a=list'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body)['meals'] as List?;
        return data?.map((e) => e['strArea'].toString())
            .where((area) => area.isNotEmpty && area != 'Unknown')
            .toList() ?? [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<Meal>> getMealsByArea(String area) async {
    final res = await http.get(Uri.parse('${baseUrl}filter.php?a=$area'));
    return _parseFilter(res);
  }

  List<Meal> _parseFilter(http.Response res) {
    if (res.statusCode == 200) {
      final data = json.decode(res.body)['meals'];
      if (data == null) return [];
      return (data as List).map((m) => Meal.fromJson(m)).toList();
    }
    return [];
  }
}