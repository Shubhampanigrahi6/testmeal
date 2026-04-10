import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import 'package:go_router/go_router.dart';
import '../widgets/recipe_card.dart';
import '../../core/providers/app_providers.dart';
import 'meal_detail_screen.dart';
import 'category_screen.dart';
import 'area_screen.dart';           // ← New

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hour = DateTime.now().hour;
    final greeting = hour < 11 ? 'Good Morning' : (hour < 16 ? 'Good Afternoon' : 'Good Evening');

    final recommendedCategoryAsync = ref.watch(recommendedCategoryProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final areasAsync = ref.watch(areasProvider);
    final mealsAsync = ref.watch(homeMealsProvider);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$greeting 👋', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const Text('Find your next delicious meal', style: TextStyle(fontSize: 14, color: Colors.grey)),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.notifications_outlined), onPressed: () {}),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => context.push('/ingredients'),
          ),
          IconButton(
            icon: const Icon(Icons.favorite_border),
            onPressed: () => context.push('/favorites'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(homeMealsProvider.future),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search Bar
              GestureDetector(
                onTap: () => context.push('/search'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.search, color: Colors.deepOrange),
                      SizedBox(width: 12),
                      Text('Search recipes...', style: TextStyle(fontSize: 16, color: Colors.grey)),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Recommended Banner (Dynamic)
              recommendedCategoryAsync.when(
                data: (recommended) => Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF6B00), Color(0xFFFFA726)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star_rounded, color: Colors.white, size: 32),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'Recommended for $recommended',
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                loading: () => const SizedBox(height: 80, child: Center(child: CircularProgressIndicator())),
                error: (_, __) => const SizedBox(),
              ),

              const SizedBox(height: 28),

              // Browse Categories (Dynamic from API)
              const Text('Browse Categories', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              categoriesAsync.when(
                data: (categories) => SizedBox(
                  height: 48,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final cat = categories[index];
                      return Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: FilterChip(
                          label: Text(cat),
                          backgroundColor: Colors.grey[200],
                          selectedColor: Colors.deepOrange,
                          labelStyle: const TextStyle(color: Colors.black87),
                          onSelected: (_) => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => CategoryScreen(category: cat)),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const Text('Failed to load categories'),
              ),

              const SizedBox(height: 32),

              // Browse by Country / Area (Dynamic from API)
              const Text('Browse by Country', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              areasAsync.when(
                data: (areas) => SizedBox(
                  height: 48,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: areas.length,
                    itemBuilder: (context, index) {
                      final area = areas[index];
                      return Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: FilterChip(
                          label: Text(area),
                          backgroundColor: Colors.grey[200],
                          onSelected: (_) => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => AreaScreen(area: area)),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const Text('Failed to load countries'),
              ),

              const SizedBox(height: 32),

              // Suggested Recipes
              const Text('Suggested Recipes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              mealsAsync.when(
                data: (meals) => meals.isEmpty
                    ? const Center(child: Text('No recipes available'))
                    : GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                  ),
                  itemCount: meals.length,
                  itemBuilder: (context, index) {
                    return RecipeCard(
                      meal: meals[index],
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => MealDetailScreen(meal: meals[index])),
                      ),
                      onFavoriteToggle: () =>
                          ref.read(favoritesProvider.notifier).toggleFavorite(meals[index]),
                    );
                  },
                ),
                loading: () => Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: const SizedBox(height: 320, child: Card()),
                ),
                error: (_, __) => const Center(child: Text('Showing cached recipes...')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}