import 'package:flutter/foundation.dart';
import 'package:queless/models/product.dart';
import 'package:queless/supabase/supabase_config.dart';

class ProductService {
  static final ProductService _instance = ProductService._internal();
  factory ProductService() => _instance;
  ProductService._internal();

  List<Product> _cachedProducts = [];

  Future<void> init() async {
    await _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      final data = await SupabaseService.select(
        'products',
        orderBy: 'created_at',
        ascending: false,
      );

      _cachedProducts = data.map((json) => Product.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error loading products: $e');
      _cachedProducts = [];
    }
  }

  Future<List<Product>> getAllProducts() async {
    if (_cachedProducts.isEmpty) {
      await _loadProducts();
    }
    return List.from(_cachedProducts);
  }

  Future<List<Product>> getProductsByCategory(ProductCategory category) async {
    try {
      final data = await SupabaseService.select(
        'products',
        filters: {'category': category.name},
        orderBy: 'name',
        ascending: true,
      );

      return data.map((json) => Product.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error getting products by category: $e');
      return [];
    }
  }

  Future<List<Product>> searchProducts(String query) async {
    final products = await getAllProducts();
    final lowerQuery = query.toLowerCase();
    return products.where((p) =>
      p.name.toLowerCase().contains(lowerQuery) ||
      (p.brand?.toLowerCase().contains(lowerQuery) ?? false) ||
      p.description.toLowerCase().contains(lowerQuery) ||
      p.tags.any((tag) => tag.toLowerCase().contains(lowerQuery))
    ).toList();
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
      debugPrint('Error getting local brand products: $e');
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
      debugPrint('Error getting featured products: $e');
      return [];
    }
  }

  Future<Product?> getProductById(String id) async {
    try {
      final data = await SupabaseService.selectSingle(
        'products',
        filters: {'id': id},
      );

      return data != null ? Product.fromJson(data) : null;
    } catch (e) {
      debugPrint('Error getting product by id: $e');
      return null;
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
      debugPrint('Error getting products by type: $e');
      return [];
    }
  }

  Future<List<Product>> getProductsByStore(String storeId) async {
    try {
      final data = await SupabaseService.select(
        'products',
        filters: {'store_id': storeId},
        orderBy: 'name',
        ascending: true,
      );

      debugPrint('📦 Loading ${data.length} products for store $storeId');
      return data.map((json) {
        try {
          return Product.fromJson(json);
        } catch (e) {
          debugPrint('Error parsing product: ${json['name']} - $e');
          debugPrint('Product data: $json');
          rethrow;
        }
      }).toList();
    } catch (e, stackTrace) {
      debugPrint('Error getting products by store: $e');
      debugPrint('Stack trace: $stackTrace');
      return [];
    }
  }
}
