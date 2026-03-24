import 'package:queless/logger.dart';
import 'package:queless/utils/logger.dart';
import 'package:queless/models/store.dart';
import 'package:queless/services/cache_service.dart';
import 'package:queless/supabase/supabase_config.dart';

class StoreService {
  static final StoreService _instance = StoreService._internal();
  factory StoreService() => _instance;
  StoreService._internal();

  final _cache = CacheService();

  Future<List<Store>> getAllStores() async {
    const cacheKey = 'all_stores';
    final cached = _cache.get<List<Store>>(cacheKey);
    if (cached != null) return cached;

    try {
      final data = await SupabaseService.select(
        'stores',
        orderBy: 'rating',
        ascending: false,
      );
      final stores = data.map((json) => Store.fromJson(json)).toList();
      _cache.set(cacheKey, stores);
      log('✅ Loaded and cached ${stores.length} stores');
      return stores;
    } catch (e) {
      log('❌ Error loading stores: $e');
      return [];
    }
  }

  Future<List<Store>> getStores({String? category}) async {
    try {
      final Map<String, dynamic> filters = {};
      if (category != null) {
        filters['category'] = category;
      }

      final data = await SupabaseService.select(
        'stores',
        filters: filters,
        orderBy: 'rating',
        ascending: false,
      );

      return data.map((json) => Store.fromJson(json)).toList();
    } catch (e) {
      log('❌ Error getting stores: $e');
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
    final cacheKey = 'store_$id';
    final cachedStore = _cache.get<Store>(cacheKey);
    if (cachedStore != null) return cachedStore;

    try {
      final data = await SupabaseService.selectSingle(
        'stores',
        filters: {'id': id},
      );

      final store = data != null ? Store.fromJson(data) : null;
      if (store != null) {
        _cache.set(cacheKey, store);
      }
      return store;
    } catch (e) {
      log('❌ Error getting store by id: $e');
      return null;
    }
  }

  Future<List<Store>> getNearbyStores({
    required double latitude,
    required double longitude,
    double radiusMeters = 5000,
    String? category,
  }) async {
    try {
      final response = await SupabaseConfig.client.rpc(
        'nearby_stores',
        params: {
          'lat': latitude.toDouble(),
          'long': longitude.toDouble(),
          'radius_meters': radiusMeters.toDouble(),
        },
      );

      final List<dynamic> data = response as List<dynamic>;
      var stores = data.map((json) {
        // Ensure distance is captured if returned by RPC
        final store = Store.fromJson(json);
        if (json.containsKey('dist_meters')) {
          return store.copyWith(
              distance: (json['dist_meters'] as num).toDouble());
        }
        return store;
      }).toList();

      if (category != null) {
        stores = stores.where((s) => s.category == category).toList();
      }

      return stores;
    } catch (e) {
      Logger.debug('❌ Error getting nearby stores via RPC: $e');
      return [];
    }
  }

  Future<Store?> findNearestStore({
    required double latitude,
    required double longitude,
    String category = 'liquor',
    double radiusMeters = 5000,
  }) async {
    // 1. Try 5km radius
    var stores = await getNearbyStores(
      latitude: latitude,
      longitude: longitude,
      radiusMeters: radiusMeters,
      category: category,
    );

    if (stores.isNotEmpty) return stores.first;

    // 2. Try 10km radius if no stores within 5km
    stores = await getNearbyStores(
      latitude: latitude,
      longitude: longitude,
      radiusMeters: 10000,
      category: category,
    );

    return stores.isNotEmpty ? stores.first : null;
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
      log('❌ Error getting stores by category: $e');
      return [];
    }
  }
}
