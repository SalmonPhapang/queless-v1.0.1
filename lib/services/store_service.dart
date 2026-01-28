import 'package:flutter/foundation.dart';
import 'package:queless/models/store.dart';
import 'package:queless/services/location_service.dart';
import 'package:queless/supabase/supabase_config.dart';

class StoreService {
  static final StoreService _instance = StoreService._internal();
  factory StoreService() => _instance;
  StoreService._internal();

  List<Store> _cachedStores = [];

  Future<void> init() async {
    await _loadStores();
  }

  Future<void> _loadStores() async {
    try {
      final data = await SupabaseService.select(
        'stores',
        orderBy: 'rating',
        ascending: false,
      );

      _cachedStores = data.map((json) => Store.fromJson(json)).toList();
      debugPrint('✅ Loaded ${_cachedStores.length} stores');
    } catch (e) {
      debugPrint('❌ Error loading stores: $e');
      _cachedStores = [];
    }
  }

  Future<List<Store>> getAllStores() async {
    if (_cachedStores.isEmpty) {
      await _loadStores();
    }
    return List.from(_cachedStores);
  }

  Future<List<Store>> getOpenStores() async {
    try {
      final data = await SupabaseService.select(
        'stores',
        filters: {'is_open': true},
        orderBy: 'rating',
        ascending: false,
      );

      return data.map((json) => Store.fromJson(json)).toList();
    } catch (e) {
      debugPrint('❌ Error getting open stores: $e');
      return [];
    }
  }

  Future<List<Store>> searchStores(String query) async {
    final stores = await getAllStores();
    final lowerQuery = query.toLowerCase();
    return stores
        .where((s) =>
            s.name.toLowerCase().contains(lowerQuery) ||
            s.description.toLowerCase().contains(lowerQuery) ||
            s.cuisineTypes
                .any((type) => type.toLowerCase().contains(lowerQuery)) ||
            s.tags.any((tag) => tag.toLowerCase().contains(lowerQuery)))
        .toList();
  }

  Future<Store?> getStoreById(String id) async {
    try {
      final data = await SupabaseService.selectSingle(
        'stores',
        filters: {'id': id},
      );

      return data != null ? Store.fromJson(data) : null;
    } catch (e) {
      debugPrint('❌ Error getting store by id: $e');
      return null;
    }
  }

  Future<List<Store>> getNearbyStores({
    required double latitude,
    required double longitude,
    double radiusMeters = 5000,
  }) async {
    try {
      final allStores = await getAllStores();
      final nearbyStores = <Store>[];

      for (final store in allStores) {
        if (store.location.isEmpty) continue;

        try {
          final parts = store.location.split(',');
          if (parts.length != 2) continue;

          final storeLat = double.parse(parts[0].trim());
          final storeLng = double.parse(parts[1].trim());

          final distance = LocationService().calculateDistance(
            latitude,
            longitude,
            storeLat,
            storeLng,
          );

          if (distance <= radiusMeters) {
            nearbyStores.add(store);
          }
        } catch (e) {
          debugPrint(
              '❌ Error parsing location for store ${store.name} (${store.id}): $e');
        }
      }

      debugPrint(
          '✅ Found ${nearbyStores.length} stores within ${radiusMeters}m');
      return nearbyStores;
    } catch (e) {
      debugPrint('❌ Error getting nearby stores: $e');
      return [];
    }
  }

  Future<List<Store>> getStoresByCategory(String category) async {
    try {
      final data = await SupabaseService.select(
        'stores',
        filters: {'category': category},
        orderBy: 'rating',
        ascending: false,
      );

      return data.map((json) => Store.fromJson(json)).toList();
    } catch (e) {
      debugPrint('❌ Error getting stores by category: $e');
      return [];
    }
  }
}
