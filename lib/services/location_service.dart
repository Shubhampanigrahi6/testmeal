import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  // Cache the areas list to avoid multiple API calls
  List<String> _cachedAreas = [];

  /// Request location permission gracefully
  Future<bool> requestPermissions() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return false;

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        await openAppSettings();
        return false;
      }

      return permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always;
    } catch (e) {
      print('Location permission error: $e');
      return false;
    }
  }

  /// Get all available areas from TheMealDB dynamically
  Future<List<String>> _getAllAreas() async {
    if (_cachedAreas.isNotEmpty) return _cachedAreas;

    try {
      final response = await http.get(
        Uri.parse('https://www.themealdb.com/api/json/v1/1/list.php?a=list'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body)['meals'] as List?;
        _cachedAreas = data
            ?.map((e) => e['strArea'].toString())
            .where((area) => area.isNotEmpty && area != 'Unknown')
            .toList() ??
            [];
      }
    } catch (e) {
      print('Failed to fetch areas: $e');
    }
    return _cachedAreas;
  }

  /// Dynamically map detected country to TheMealDB area
  String _mapToArea(String country, List<String> availableAreas) {
    final lowerCountry = country.toLowerCase().trim();

    for (final area in availableAreas) {
      final lowerArea = area.toLowerCase().trim();

      // Exact match
      if (lowerArea == lowerCountry) return area;

      // Common mappings
      if (lowerCountry.contains('india') && lowerArea == 'indian') return area;
      if (lowerCountry.contains('us') || lowerCountry.contains('america') && lowerArea == 'american') return area;
      if (lowerCountry.contains('uk') || lowerCountry.contains('britain') && lowerArea == 'british') return area;
      if (lowerCountry.contains('canada') && lowerArea == 'canadian') return area;

      // Fuzzy match - if country name contains area name or vice versa
      if (lowerCountry.contains(lowerArea) || lowerArea.contains(lowerCountry)) {
        return area;
      }
    }

    // If no match found, return original (some countries work directly)
    return country;
  }

  /// Main method: Get user's country and return best matching TheMealDB area
  Future<String?> getUserCountry() async {
    try {
      final hasPermission = await requestPermissions();
      if (!hasPermission) return null;

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );

      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?'
            'lat=${position.latitude}&lon=${position.longitude}&format=json',
      );

      final response = await http.get(
        url,
        headers: {'User-Agent': 'LocalPlateRecipeApp/1.0'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        String? country = data['address']?['country'];

        if (country == null || country.isEmpty) return null;

        // Get dynamic area list
        final availableAreas = await _getAllAreas();

        // Dynamically map
        final mappedArea = _mapToArea(country, availableAreas);

        print('Detected country: $country → Mapped to area: $mappedArea');
        return mappedArea;
      }
    } catch (e) {
      print('LocationService error: $e');
    }

    return null;
  }
}