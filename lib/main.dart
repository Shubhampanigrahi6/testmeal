import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Services
import 'services/notification_service.dart';
import 'services/location_service.dart';

// Data
import 'data/datasources/local_datasource.dart';


// Screens
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/search_screen.dart';
import 'presentation/screens/favorites_screen.dart';
import 'presentation/screens/category_screen.dart';
import 'presentation/screens/area_screen.dart';
import 'presentation/screens/ingredient_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  final localDS = LocalDataSource();
  await localDS.init();

  // Initialize Notifications
  await NotificationService.initialize();

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  void initState() {
    super.initState();
    _setupPermissionsAndNotifications();
  }

  Future<void> _setupPermissionsAndNotifications() async {
    // 1. Request Notification Permission gracefully
    final notificationGranted = await NotificationService.requestNotificationPermission();

    if (notificationGranted) {
      // 2. Schedule notifications with real recipe suggestions
      await NotificationService.scheduleMealNotifications(ref);
    } else {
      // Optional: Show a snackbar or dialog explaining benefits
      print('Notification permission denied by user.');
    }

    // 3. Request Location Permission (non-blocking)
    final locationService = LocationService();
    await locationService.requestPermissions();
  }

  @override
  Widget build(BuildContext context) {
    final GoRouter router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
        GoRoute(path: '/search', builder: (_, __) => const SearchScreen()),
        GoRoute(path: '/favorites', builder: (_, __) => const FavoritesScreen()),
        GoRoute(path: '/ingredients', builder: (_, __) => const IngredientScreen()),
        GoRoute(
          path: '/category/:category',
          builder: (context, state) => CategoryScreen(
            category: state.pathParameters['category'] ?? 'Chicken',
          ),
        ),
        GoRoute(
          path: '/area/:area',
          builder: (context, state) => AreaScreen(
            area: state.pathParameters['area'] ?? 'Canadian',
          ),
        ),
      ],
    );

    return MaterialApp.router(
      title: 'LocalPlate',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.deepOrange,
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}