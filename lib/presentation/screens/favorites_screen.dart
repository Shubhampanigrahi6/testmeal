import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/recipe_card.dart';
import '../../core/providers/app_providers.dart';
import 'meal_detail_screen.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Favorites')),
      body: favorites.isEmpty
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_border, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text('No favorite recipes yet', style: TextStyle(fontSize: 18)),
          ],
        ),
      )
          : GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: favorites.length,
        itemBuilder: (context, index) {
          final meal = favorites[index];
          return RecipeCard(
            meal: meal,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MealDetailScreen(meal: meal),
              ),
            ),
            onFavoriteToggle: () {
              ref.read(favoritesProvider.notifier).toggleFavorite(meal);
            },
          );
        },
      ),
    );
  }
}