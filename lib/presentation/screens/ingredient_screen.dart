import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import '../widgets/recipe_card.dart';
import '../../core/providers/app_providers.dart';
import 'meal_detail_screen.dart';

class IngredientScreen extends ConsumerStatefulWidget {
  const IngredientScreen({super.key});

  @override
  ConsumerState<IngredientScreen> createState() => _IngredientScreenState();
}

class _IngredientScreenState extends ConsumerState<IngredientScreen> {
  String selectedIngredient = '';

  @override
  Widget build(BuildContext context) {
    final ingredientsAsync = ref.watch(ingredientsListProvider);
    final mealsAsync = selectedIngredient.isEmpty
        ? null
        : ref.watch(ingredientMealsProvider(selectedIngredient));

    return Scaffold(
      appBar: AppBar(title: const Text('Filter by Ingredient')),
      body: Column(
        children: [
          // Ingredient Dropdown / Chips
          Padding(
            padding: const EdgeInsets.all(16),
            child: ingredientsAsync.when(
              data: (ingredients) => Autocomplete<String>(
                optionsBuilder: (textEditingValue) {
                  if (textEditingValue.text.isEmpty) return const Iterable<String>.empty();
                  return ingredients.where((ingredient) =>
                      ingredient.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                },
                onSelected: (ingredient) {
                  setState(() => selectedIngredient = ingredient);
                },
                fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                  return TextField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: InputDecoration(
                      hintText: 'Search ingredient (e.g. chicken, rice, egg)...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                },
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Text('Failed to load ingredients'),
            ),
          ),

          const Divider(),

          // Results
          Expanded(
            child: selectedIngredient.isEmpty
                ? const Center(
              child: Text(
                'Select an ingredient to see recipes',
                style: TextStyle(fontSize: 16),
              ),
            )
                : mealsAsync!.when(
              data: (meals) => meals.isEmpty
                  ? Center(child: Text('No recipes found with "$selectedIngredient"'))
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
                    onFavoriteToggle: () =>
                        ref.read(favoritesProvider.notifier).toggleFavorite(meal),
                  );
                },
              ),
              loading: () => Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, childAspectRatio: 0.75),
                  itemCount: 6,
                  itemBuilder: (_, __) => const Card(),
                ),
              ),
              error: (_, __) => const Center(child: Text('Failed to load recipes')),
            ),
          ),
        ],
      ),
    );
  }
}