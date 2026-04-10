import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/providers/app_providers.dart'; // For recommended category
import 'dart:math';

class NotificationService {
  static final FlutterLocalNotificationsPlugin notificationsPlugin =
  FlutterLocalNotificationsPlugin();

  // Add a callback for when notification is tapped (optional: open specific meal)
  static Future<void> initialize() async {
    tz_data.initializeTimeZones();

    const AndroidInitializationSettings android =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await notificationsPlugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: (response) {
        // Handle tap on notification (e.g., navigate to meal detail)
        print('Notification tapped: ${response.payload}');
        // You can use a global navigator key or GoRouter to open MealDetailScreen here
      },
    );
  }

  /// Request notification permission gracefully
  static Future<bool> requestNotificationPermission() async {
    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
    notificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    final bool? granted = await androidPlugin?.requestNotificationsPermission();
    return granted ?? false;
  }

  /// Schedule meal notifications with ACTUAL recipe suggestion
  static Future<void> scheduleMealNotifications(WidgetRef ref) async {
    // Breakfast at 8:00 AM
    await _scheduleMeal(
      id: 1,
      hour: 8,
      minute: 0,
      title: '🍳 Good Morning! Breakfast Time',
      ref: ref,
      mealType: 'Breakfast',
    );

    // Lunch at 2:00 PM (13:30 in 24h)
    await _scheduleMeal(
      id: 2,
      hour: 13,
      minute: 30,
      title: '🍲 Lunch Time!',
      ref: ref,
      mealType: 'Lunch',
    );

    // Dinner at 7:00 PM
    await _scheduleMeal(
      id: 3,
      hour: 19,
      minute: 0,
      title: '🍽️ Dinner Time',
      ref: ref,
      mealType: 'Dinner',
    );
  }

  static Future<void> _scheduleMeal({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required WidgetRef ref,
    required String mealType,
  }) async {
    final tz.TZDateTime scheduled = _nextInstanceOf(hour, minute);

    // Get a real recommended recipe dynamically
    String body = 'Discover delicious recipes now!';
    String? payload;

    try {
      final repo = ref.read(mealRepositoryProvider);
      final recommendedCat = await _getRecommendedCategoryForType(mealType, ref);

      final meals = await repo.getMealsByCategory(recommendedCat);

      if (meals.isNotEmpty) {
        final randomMeal = meals[Random().nextInt(meals.length)];
        body = 'Try "${randomMeal.name}" today!';
        payload = randomMeal.id; // Pass meal ID so you can open it when tapped
      }
    } catch (e) {
      // Fallback if API fails
      body = 'What will you cook today? Open app to explore!';
    }

    await notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      scheduled,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'meal_channel',
          'Meal Reminders',
          channelDescription: 'Daily meal suggestions with real recipes',
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: payload,
    );
  }

  static tz.TZDateTime _nextInstanceOf(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  // Helper to map meal type to real category
  static Future<String> _getRecommendedCategoryForType(String mealType, WidgetRef ref) async {
    final categories = await ref.read(categoriesProvider.future);

    switch (mealType) {
      case 'Breakfast':
        if (categories.contains('Breakfast')) return 'Breakfast';
        if (categories.contains('Pancake')) return 'Pancake';
        break;
      case 'Lunch':
        if (categories.contains('Chicken')) return 'Chicken';
        if (categories.contains('Beef')) return 'Beef';
        if (categories.contains('Pasta')) return 'Pasta';
        break;
      case 'Dinner':
        if (categories.contains('Seafood')) return 'Seafood';
        if (categories.contains('Lamb')) return 'Lamb';
        if (categories.contains('Vegetarian')) return 'Vegetarian';
        break;
    }
    return categories.isNotEmpty ? categories.first : 'Chicken';
  }
}