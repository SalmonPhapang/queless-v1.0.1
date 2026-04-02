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
    final cached = _cache.get<List<Product>>(cacheKey);
    if (cached != null) return cached;

    try {
      final data = await SupabaseService.select(
        'products',
        orderBy: 'created_at',
        ascending: false,
      );
      final products = data.map((json) => Product.fromJson(json)).toList();
      await _cache.set(cacheKey, products);
      return products;
    } catch (e) {
      Logger.debug('Error loading products: $e');
      return _cache.get<List<Product>>(cacheKey) ?? [];
    }
  }

  Future<List<Product>> getProductsByCategory(ProductCategory category) async {
    final cacheKey = 'products_cat_${category.name}';
    final cached = _cache.get<List<Product>>(cacheKey);
    if (cached != null) return cached;

    try {
      final data = await SupabaseService.select(
        'products',
        filters: {'category': category.name},
        orderBy: 'name',
        ascending: true,
      );

      final products = data.map((json) => Product.fromJson(json)).toList();
      await _cache.set(cacheKey, products);
      return products;
    } catch (e) {
      Logger.debug('Error getting products by category: $e');
      return _cache.get<List<Product>>(cacheKey) ?? [];
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
    try {
      final data = await SupabaseService.select(
        'products',
        filters: {'is_local_brand': true},
        orderBy: 'name',
        ascending: true,
      );

      return data.map((json) => Product.fromJson(json)).toList();
    } catch (e) {
      Logger.debug('Error getting local brand products: $e');
      return [];
    }
  }

  Future<List<Product>> getFeaturedProducts() async {
    try {
      final data = await SupabaseService.select(
        'products',
        limit: 6,
      );

      return data.map((json) => Product.fromJson(json)).toList();
    } catch (e) {
      Logger.debug('Error getting featured products: $e');
      return [];
    }
  }

  Future<List<Product>> getProductsByStoreId(String storeId) async {
    try {
      final data = await SupabaseService.select(
        'products',
        filters: {'store_id': storeId},
        orderBy: 'name',
        ascending: true,
      );

      return data.map((json) => Product.fromJson(json)).toList();
    } catch (e) {
      Logger.debug('Error getting products by store id: $e');
      return [];
    }
  }

  Future<Product?> getProductById(String id) async {
    final cacheKey = 'product_$id';
    final cachedProduct = _cache.get<Product>(cacheKey);
    if (cachedProduct != null) return cachedProduct;

    try {
      final data = await SupabaseService.selectSingle(
        'products',
        filters: {'id': id},
      );

      final product = data != null ? Product.fromJson(data) : null;
      if (product != null) {
        await _cache.set(cacheKey, product);
      }
      return product;
    } catch (e) {
      Logger.debug('Error getting product by id: $e');
      return _cache.get<Product>(cacheKey);
    }
  }

  Future<List<Product>> getProductsByIds(List<String> ids) async {
    if (ids.isEmpty) return [];

    final products = await getAllProducts();
    return products.where((p) => ids.contains(p.id)).toList();
  }

  Future<List<Product>> getProductsByType(ProductType type) async {
    try {
      final data = await SupabaseService.select(
        'products',
        filters: {'product_type': type.name},
        orderBy: 'created_at',
        ascending: false,
      );

      return data.map((json) => Product.fromJson(json)).toList();
    } catch (e) {
      Logger.debug('Error getting products by type: $e');
      return [];
    }
  }

  Future<List<Product>> getProductsByStore(String storeId) async {
    final cacheKey = 'products_store_$storeId';
    final cached = _cache.get<List<Product>>(cacheKey);
    if (cached != null) return cached;

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

      await _cache.set(cacheKey, products);
      return products;
    } catch (e, stackTrace) {
      Logger.debug('Error getting products by store: $e');
      Logger.debug('Stack trace: $stackTrace');
      return _cache.get<List<Product>>(cacheKey) ?? [];
    }
  }
}
