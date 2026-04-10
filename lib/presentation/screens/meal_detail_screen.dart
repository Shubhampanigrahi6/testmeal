import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';   // ← This line was missing
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/meal.dart';
import '../../core/providers/app_providers.dart';

class MealDetailScreen extends ConsumerWidget {
  final Meal meal;

  const MealDetailScreen({super.key, required this.meal});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFavorite = ref.watch(favoritesProvider).any((m) => m.id == meal.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(meal.name),
        actions: [
          IconButton(
            icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border),
            color: isFavorite ? Colors.red : null,
            onPressed: () {
              ref.read(favoritesProvider.notifier).toggleFavorite(meal);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(
              tag: 'meal_${meal.id}',
              child: CachedNetworkImage(
                imageUrl: meal.thumbnail ?? '',
                width: double.infinity,
                height: 250,
                fit: BoxFit.cover,
                placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                errorWidget: (context, url, error) => const Icon(Icons.image_not_supported, size: 100),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meal.name,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Chip(label: Text(meal.category ?? 'Unknown')),
                      const SizedBox(width: 8),
                      Chip(label: Text(meal.area ?? 'Unknown')),
                    ],
                  ),
                  const SizedBox(height: 20),

                  const Text('Instructions', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text(meal.instructions ?? 'No instructions available.'),
                  const SizedBox(height: 30),

                  if (meal.youtube != null && meal.youtube!.isNotEmpty)
                    ElevatedButton.icon(
                      onPressed: () async {
                        final url = Uri.parse(meal.youtube!);
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url, mode: LaunchMode.externalApplication);
                        }
                      },
                      icon: const Icon(Icons.play_circle),
                      label: const Text('Watch on YouTube'),
                    ),

                  const SizedBox(height: 30),
                  const Text('Ingredients', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  ...meal.ingredients.map((ing) => ListTile(
                    leading: const Icon(Icons.check_circle, color: Colors.green),
                    title: Text('${ing['measure']} ${ing['ingredient']}'),
                    dense: true,
                  )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}