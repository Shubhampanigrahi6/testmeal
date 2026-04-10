import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import '../widgets/recipe_card.dart';
import '../../core/providers/app_providers.dart';
import 'meal_detail_screen.dart';

class CategoryScreen extends ConsumerWidget {
  final String category;

  const CategoryScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mealsAsync = ref.watch(categoryMealsProvider(category));

    return Scaffold(
      appBar: AppBar(title: Text('$category Recipes')),
      body: mealsAsync.when(
        data: (meals) => meals.isEmpty
            ? const Center(child: Text('No recipes available in this category'))
            : GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.75,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: meals.length,
          itemBuilder: (context, index) {
            final meal = meals[index];
            return RecipeCard(
              meal: meal,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => MealDetailScreen(meal: meal)),
              ),
              onFavoriteToggle: () => ref.read(favoritesProvider.notifier).toggleFavorite(meal),
            );
          },
        ),
        loading: () => Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.75),
            itemCount: 6,
            itemBuilder: (_, __) => const Card(),
          ),
        ),
        error: (_, __) => const Center(child: Text('Failed to load recipes')),
      ),
    );
  }
}