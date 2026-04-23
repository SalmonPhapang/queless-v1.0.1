import 'package:queless/logger.dart';
import 'package:queless/utils/logger.dart';
import 'package:queless/models/store.dart';
import 'package:queless/services/cache_service.dart';
import 'package:queless/services/connectivity_service.dart';
import 'package:queless/supabase/supabase_config.dart';

class StoreService {
  static final StoreService _instance = StoreService._internal();
  factory StoreService() => _instance;
  StoreService._internal();

  final _cache = CacheService();

  Future<List<Store>> getAllStores() async {
    const cacheKey = 'all_stores';
    final cachedDynamic = _cache.get<dynamic>(cacheKey);
    if (cachedDynamic != null && cachedDynamic is List) {
      return cachedDynamic
          .map((json) => json is Store
              ? json
              : Store.fromJson(json as Map<String, dynamic>))
          .toList();
    }

    try {
      final data = await SupabaseService.select(
        'stores',
        orderBy: 'rating',
        ascending: false,
      );
      final stores = data.map((json) => Store.fromJson(json)).toList();
      final storesJson = stores.map((s) => s.toJson()).toList();
      await _cache.set(cacheKey, storesJson);
      log('✅ Loaded and cached ${stores.length} stores');
      return stores;
    } catch (e) {
      log('❌ Error loading stores: $e');
      final cached = _cache.get<dynamic>(cacheKey);
      if (cached != null && cached is List) {
        return cached
            .map((json) => json is Store
                ? json
                : Store.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    }
  }

  Future<List<Store>> getStores({String? category}) async {
    final cacheKey = 'stores_${category ?? 'all'}';
    final cachedDynamic = _cache.get<dynamic>(cacheKey);
    if (cachedDynamic != null && cachedDynamic is List) {
      return cachedDynamic
          .map((json) => json is Store
              ? json
              : Store.fromJson(json as Map<String, dynamic>))
          .toList();
    }

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

      final stores = data.map((json) => Store.fromJson(json)).toList();
      final storesJson = stores.map((s) => s.toJson()).toList();
      await _cache.set(cacheKey, storesJson);
      return stores;
    } catch (e) {
      log('❌ Error getting stores: $e');
      final cached = _cache.get<dynamic>(cacheKey);
      if (cached != null && cached is List) {
        return cached
            .map((json) => json is Store
                ? json
                : Store.fromJson(json as Map<String, dynamic>))
            .toList();
      }
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
    final cachedDynamic = _cache.get<dynamic>(cacheKey);
    if (cachedDynamic != null) {
      if (cachedDynamic is Store) return cachedDynamic;
      if (cachedDynamic is Map<String, dynamic>) {
        return Store.fromJson(cachedDynamic);
      }
    }

    try {
      final data = await SupabaseService.selectSingle(
        'stores',
        filters: {'id': id},
      );

      final store = data != null ? Store.fromJson(data) : null;
      if (store != null) {
        await _cache.set(cacheKey, store.toJson());
      }
      return store;
    } catch (e) {
      log('❌ Error getting store by id: $e');
      final cached = _cache.get<dynamic>(cacheKey);
      if (cached != null) {
        if (cached is Store) return cached;
        if (cached is Map<String, dynamic>) return Store.fromJson(cached);
      }
      return null;
    }
  }

  Future<List<Store>> getNearbyStores({
    required double latitude,
    required double longitude,
    double radiusMeters = 5000,
    String? category,
  }) async {
    final cacheKey =
        'nearby_stores_${latitude}_${longitude}_${radiusMeters}_${category ?? 'all'}';
    final cachedDynamic = _cache.get<dynamic>(cacheKey);
    if (cachedDynamic != null && cachedDynamic is List) {
      try {
        final cachedStores = cachedDynamic.map((json) {
          if (json is Store) return json;
          return Store.fromJson(json as Map<String, dynamic>);
        }).toList();
        return cachedStores;
      } catch (e) {
        Logger.debug('⚠️ Error parsing cached nearby stores: $e');
        // If parsing fails, fall through to fetch fresh data
      }
    }

    try {
      if (!ConnectivityService().isConnected) {
        throw Exception('No internet connection');
      }

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

      // Important: Map to JSON before caching for persistent storage consistency
      final storesJson = stores.map((s) => s.toJson()).toList();
      await _cache.set(cacheKey, storesJson);
      return stores;
    } catch (e) {
      Logger.debug('❌ Error getting nearby stores via RPC: $e');
      final cached = _cache.get<dynamic>(cacheKey);
      if (cached != null && cached is List) {
        return cached
            .map((json) => json is Store
                ? json
                : Store.fromJson(json as Map<String, dynamic>))
            .toList();
      }
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
