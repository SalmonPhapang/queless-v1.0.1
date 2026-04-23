import 'package:queless/logger.dart';
import 'package:queless/models/product.dart';
import 'package:queless/services/cache_service.dart';
import 'package:queless/supabase/supabase_config.dart';

class ProductService {
  static final ProductService _instance = ProductService._internal();
  factory ProductService() => _instance;
  ProductService._internal();

  final _cache = CacheService();

  Future<List<Product>> getAllProducts() async {
    const cacheKey = 'all_products';
    final cachedDynamic = _cache.get<dynamic>(cacheKey);
    if (cachedDynamic != null && cachedDynamic is List) {
      return cachedDynamic
          .map((json) => json is Product
              ? json
              : Product.fromJson(json as Map<String, dynamic>))
          .toList();
    }

    try {
      final data = await SupabaseService.select(
        'products',
        orderBy: 'created_at',
        ascending: false,
      );
      final products = data.map((json) => Product.fromJson(json)).toList();
      final productsJson = products.map((p) => p.toJson()).toList();
      await _cache.set(cacheKey, productsJson);
      return products;
    } catch (e) {
      Logger.debug('Error loading products: $e');
      final cached = _cache.get<dynamic>(cacheKey);
      if (cached != null && cached is List) {
        return cached
            .map((json) => json is Product
                ? json
                : Product.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    }
  }

  Future<List<Product>> getProductsByCategory(String category) async {
    final cacheKey = 'products_cat_$category';
    final cachedDynamic = _cache.get<dynamic>(cacheKey);
    if (cachedDynamic != null && cachedDynamic is List) {
      return cachedDynamic
          .map((json) => json is Product
              ? json
              : Product.fromJson(json as Map<String, dynamic>))
          .toList();
    }

    try {
      final data = await SupabaseService.select(
        'products',
        filters: {'category': category},
        orderBy: 'name',
        ascending: true,
      );

      final products = data.map((json) => Product.fromJson(json)).toList();
      final productsJson = products.map((p) => p.toJson()).toList();
      await _cache.set(cacheKey, productsJson);
      return products;
    } catch (e) {
      Logger.debug('Error getting products by category: $e');
      final cached = _cache.get<dynamic>(cacheKey);
      if (cached != null && cached is List) {
        return cached
            .map((json) => json is Product
                ? json
                : Product.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    }
  }

  Future<List<Product>> searchProducts(String query) async {
    final products = await getAllProducts();
    final lowerQuery = query.toLowerCase();
    return products
        .where((p) =>
            p.name.toLowerCase().contains(lowerQuery) ||
            (p.brand?.toLowerCase().contains(lowerQuery) ?? false) ||
            p.description.toLowerCase().contains(lowerQuery) ||
            p.tags.any((tag) => tag.toLowerCase().contains(lowerQuery)))
        .toList();
  }

  Future<List<Product>> getLocalBrandProducts() async {
    const cacheKey = 'products_local_brands';
    final cachedDynamic = _cache.get<dynamic>(cacheKey);
    if (cachedDynamic != null && cachedDynamic is List) {
      return cachedDynamic
          .map((json) => json is Product
              ? json
              : Product.fromJson(json as Map<String, dynamic>))
          .toList();
    }

    try {
      final data = await SupabaseService.select(
        'products',
        filters: {'is_local_brand': true},
        orderBy: 'name',
        ascending: true,
      );

      final products = data.map((json) => Product.fromJson(json)).toList();
      final productsJson = products.map((p) => p.toJson()).toList();
      await _cache.set(cacheKey, productsJson);
      return products;
    } catch (e) {
      Logger.debug('Error getting local brand products: $e');
      final cached = _cache.get<dynamic>(cacheKey);
      if (cached != null && cached is List) {
        return cached
            .map((json) => json is Product
                ? json
                : Product.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    }
  }

  Future<List<Product>> getFeaturedProducts() async {
    const cacheKey = 'products_featured';
    final cachedDynamic = _cache.get<dynamic>(cacheKey);
    if (cachedDynamic != null && cachedDynamic is List) {
      return cachedDynamic
          .map((json) => json is Product
              ? json
              : Product.fromJson(json as Map<String, dynamic>))
          .toList();
    }

    try {
      final data = await SupabaseService.select(
        'products',
        limit: 6,
      );

      final products = data.map((json) => Product.fromJson(json)).toList();
      final productsJson = products.map((p) => p.toJson()).toList();
      await _cache.set(cacheKey, productsJson);
      return products;
    } catch (e) {
      Logger.debug('Error getting featured products: $e');
      final cached = _cache.get<dynamic>(cacheKey);
      if (cached != null && cached is List) {
        return cached
            .map((json) => json is Product
                ? json
                : Product.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    }
  }

  Future<List<Product>> getProductsByStoreId(String storeId) async {
    return getProductsByStore(storeId);
  }

  Future<Product?> getProductById(String id) async {
    final cacheKey = 'product_$id';
    final cachedDynamic = _cache.get<dynamic>(cacheKey);
    if (cachedDynamic != null) {
      if (cachedDynamic is Product) return cachedDynamic;
      if (cachedDynamic is Map<String, dynamic>) {
        return Product.fromJson(cachedDynamic);
      }
    }

    try {
      final data = await SupabaseService.selectSingle(
        'products',
        filters: {'id': id},
      );

      final product = data != null ? Product.fromJson(data) : null;
      if (product != null) {
        await _cache.set(cacheKey, product.toJson());
      }
      return product;
    } catch (e) {
      Logger.debug('Error getting product by id: $e');
      final cached = _cache.get<dynamic>(cacheKey);
      if (cached != null) {
        if (cached is Product) return cached;
        if (cached is Map<String, dynamic>) return Product.fromJson(cached);
      }
      return null;
    }
  }

  Future<List<Product>> getProductsByIds(List<String> ids) async {
    if (ids.isEmpty) return [];

    final products = await getAllProducts();
    return products.where((p) => ids.contains(p.id)).toList();
  }

  Future<List<Product>> getProductsByType(ProductType type) async {
    final cacheKey = 'products_type_${type.name}';
    final cachedDynamic = _cache.get<dynamic>(cacheKey);
    if (cachedDynamic != null && cachedDynamic is List) {
      return cachedDynamic
          .map((json) => json is Product
              ? json
              : Product.fromJson(json as Map<String, dynamic>))
          .toList();
    }

    try {
      final data = await SupabaseService.select(
        'products',
        filters: {'product_type': type.name},
        orderBy: 'created_at',
        ascending: false,
      );

      final products = data.map((json) => Product.fromJson(json)).toList();
      final productsJson = products.map((p) => p.toJson()).toList();
      await _cache.set(cacheKey, productsJson);
      return products;
    } catch (e) {
      Logger.debug('Error getting products by type: $e');
      final cached = _cache.get<dynamic>(cacheKey);
      if (cached != null && cached is List) {
        return cached
            .map((json) => json is Product
                ? json
                : Product.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    }
  }

  Future<List<Product>> getProductsByStore(String storeId) async {
    final cacheKey = 'products_store_$storeId';
    final cachedDynamic = _cache.get<dynamic>(cacheKey);
    if (cachedDynamic != null && cachedDynamic is List) {
      return cachedDynamic
          .map((json) => json is Product
              ? json
              : Product.fromJson(json as Map<String, dynamic>))
          .toList();
    }

    try {
      final data = await SupabaseService.select(
        'products',
        filters: {'store_id': storeId},
        orderBy: 'name',
        ascending: true,
      );

      Logger.debug('📦 Loading ${data.length} products for store $storeId');
      final products = data.map((json) {
        try {
          return Product.fromJson(json);
        } catch (e) {
          Logger.debug('Error parsing product: ${json['name']} - $e');
          Logger.debug('Product data: $json');
          rethrow;
        }
      }).toList();

      final productsJson = products.map((p) => p.toJson()).toList();
      await _cache.set(cacheKey, productsJson);
      return products;
    } catch (e, stackTrace) {
      Logger.debug('Error getting products by store: $e');
      Logger.debug('Stack trace: $stackTrace');
      final cached = _cache.get<dynamic>(cacheKey);
      if (cached != null && cached is List) {
        return cached
            .map((json) => json is Product
                ? json
                : Product.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    }
  }
}
