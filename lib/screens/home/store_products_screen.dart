import 'package:flutter/material.dart';
import 'package:queless/models/product.dart';
import 'package:queless/models/store.dart';
import 'package:queless/services/food_cart_service.dart';
import 'package:queless/services/product_service.dart';
import 'package:queless/services/cart_service.dart';
import 'package:queless/services/location_service.dart';
import 'package:queless/services/promotion_service.dart';
import 'package:queless/widgets/promo_badge.dart';
import 'package:queless/utils/formatters.dart';
import 'package:queless/screens/cart/cart_screen.dart';
import 'package:queless/screens/product/product_detail_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';

class StoreProductsScreen extends StatefulWidget {
  final Store store;

  const StoreProductsScreen({super.key, required this.store});

  @override
  State<StoreProductsScreen> createState() => _StoreProductsScreenState();
}

class _StoreProductsScreenState extends State<StoreProductsScreen> {
  final _productService = ProductService();
  final _cartService = CartService();
  final _locationService = LocationService();
  List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];
  bool _isLoading = true;
  double? _distance;
  String? _selectedCategory;

  List<Map<String, dynamic>> _categories = [];

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    await _updateCartStoreInfo();
    await _loadProducts();
    await PromotionService().refreshActivePromotions();
  }

  Future<void> _updateCartStoreInfo() async {
    final position = await _locationService.getCurrentLocation();
    if (position != null && widget.store.location.isNotEmpty) {
      final parts = widget.store.location.split(',');
      if (parts.length == 2) {
        final storeLat = double.parse(parts[0].trim());
        final storeLng = double.parse(parts[1].trim());
        final distance = _locationService.calculateDistance(
          position.latitude,
          position.longitude,
          storeLat,
          storeLng,
        );
        setState(() => _distance = distance / 1000);

        // Update distance in cart services for fee calculation
        if (widget.store.category == 'food') {
          FoodCartService().updateStoreDistance(widget.store.id, distance);
        } else {
          CartService().updateStoreDistance(widget.store.id, distance);
        }
      }
    }
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      final products =
          await _productService.getProductsByStoreId(widget.store.id);
      if (mounted) {
        setState(() {
          _allProducts = products;
          _filteredProducts = products;
          _isLoading = false;
        });
        _generateCategoriesFromProducts();
      }
    } catch (e) {
      debugPrint('Error loading products for store: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _filterByCategory(String? category) {
    setState(() {
      _selectedCategory = category;
      if (category == null) {
        _filteredProducts = _allProducts;
      } else {
        _filteredProducts =
            _allProducts.where((p) => p.category == category).toList();
      }
    });
  }

  void _generateCategoriesFromProducts() {
    if (_allProducts.isEmpty) return;

    final categoryNames = <String>{};
    for (var product in _allProducts) {
      categoryNames.add(product.category);
    }

    final categoryList =
        categoryNames.map<Map<String, dynamic>>((categoryName) {
      String name = categoryName;
      IconData icon;

      // Try to find a matching enum for the icon, or fallback to default
      ProductCategory? enumCategory;
      try {
        enumCategory = ProductCategory.values.firstWhere(
          (e) => e.name.toLowerCase() == categoryName.toLowerCase(),
        );
      } catch (_) {
        enumCategory = null;
      }

      if (enumCategory != null) {
        switch (enumCategory) {
          case ProductCategory.beer:
            icon = Icons.sports_bar;
            break;
          case ProductCategory.wine:
            icon = Icons.wine_bar;
            break;
          case ProductCategory.spirits:
            icon = Icons.local_bar;
            break;
          case ProductCategory.mixers:
            icon = Icons.local_drink;
            break;
          case ProductCategory.snacks:
            icon = Icons.fastfood;
            break;
          case ProductCategory.food:
            icon = Icons.restaurant;
            break;
          case ProductCategory.burgers:
            icon = Icons.lunch_dining;
            break;
          case ProductCategory.pizza:
            icon = Icons.local_pizza;
            break;
          case ProductCategory.chicken:
            icon = Icons.restaurant;
            break;
          case ProductCategory.asian:
            icon = Icons.ramen_dining;
            break;
          case ProductCategory.desserts:
            icon = Icons.cake;
            break;
          case ProductCategory.drinks:
            icon = Icons.local_drink;
            break;
          case ProductCategory.groceries:
            icon = Icons.shopping_basket;
            break;
        }
      } else {
        // Handle common strings that might not be in the enum but we want icons for
        final lowerName = name.toLowerCase();
        if (lowerName.contains('burger')) {
          icon = Icons.lunch_dining;
        } else if (lowerName.contains('pizza')) {
          icon = Icons.local_pizza;
        } else if (lowerName.contains('drink') ||
            lowerName.contains('beverage')) {
          icon = Icons.local_drink;
        } else if (lowerName.contains('dessert') ||
            lowerName.contains('sweet')) {
          icon = Icons.cake;
        } else if (lowerName.contains('meat') ||
            lowerName.contains('chicken')) {
          icon = Icons.restaurant;
        } else {
          icon = Icons.category;
        }
      }

      // Capitalize first letter for display if it's all lowercase
      if (name.isNotEmpty && name == name.toLowerCase()) {
        name = name[0].toUpperCase() + name.substring(1);
      }

      return {'name': name, 'category': categoryName, 'icon': icon};
    }).toList();

    categoryList
        .sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));

    categoryList.insert(
        0, {'name': 'All', 'category': null, 'icon': Icons.all_inclusive});

    setState(() {
      _categories = categoryList;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.store.name),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildCategoryFilter(theme),
                Expanded(
                  child: _filteredProducts.isEmpty
                      ? _buildEmptyState(theme)
                      : GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.65, // Adjusted for more content
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          itemCount: _filteredProducts.length,
                          itemBuilder: (context, index) => _ProductCard(
                            product: _filteredProducts[index],
                            store: widget.store,
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildCategoryFilter(ThemeData theme) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = _selectedCategory == cat['category'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: isSelected,
              label: Text(cat['name']),
              onSelected: (_) => _filterByCategory(cat['category']),
              avatar: Icon(cat['icon'],
                  size: 18,
                  color: isSelected ? Colors.white : theme.colorScheme.primary),
              backgroundColor: theme.colorScheme.surface,
              selectedColor: theme.colorScheme.primary,
              labelStyle: TextStyle(
                  color:
                      isSelected ? Colors.white : theme.colorScheme.onSurface),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded,
              size: 64,
              color: theme.colorScheme.outline.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(
            'No products found in this category',
            style: theme.textTheme.bodyLarge
                ?.copyWith(color: theme.colorScheme.outline),
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  final Store store;

  const _ProductCard({required this.product, required this.store});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cartService = CartService();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => ProductDetailScreen(product: product)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section
            Expanded(
              flex: 5,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    color:
                        theme.colorScheme.surfaceVariant.withValues(alpha: 0.3),
                    child: product.imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: product.imageUrl,
                            fit: BoxFit.contain,
                            placeholder: (context, url) => const Center(
                                child:
                                    CircularProgressIndicator(strokeWidth: 2)),
                            errorWidget: (context, url, error) => const Center(
                                child: Icon(Icons.local_bar, size: 48)),
                          )
                        : const Center(child: Icon(Icons.local_bar, size: 48)),
                  ),
                  AnimatedBuilder(
                    animation: PromotionService(),
                    builder: (context, _) {
                      final promo =
                          PromotionService().promotionForProduct(product.id);
                      if (promo == null) return const SizedBox.shrink();
                      return Positioned(
                        top: 8,
                        left: 8,
                        child: Transform.scale(
                          scale: 0.8,
                          alignment: Alignment.topLeft,
                          child: PromoBadge(text: promo.badgeText),
                        ),
                      );
                    },
                  ),
                  if (product.isLocalBrand)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'LOCAL',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Info Section
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    product.volume ?? '',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.outline),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        Formatters.formatCurrency(product.price),
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Action Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: store.isOpen && product.isInStock
                      ? () async {
                          await cartService.addItem(product);
                          if (context.mounted) {
                            _showAddedSnackBar(context, theme, product);
                          }
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 32),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    backgroundColor: store.isOpen && product.isInStock
                        ? null
                        : theme.colorScheme.surfaceVariant,
                  ),
                  child: Text(
                    !product.isInStock
                        ? 'Out of Stock'
                        : store.isOpen
                            ? 'Add to Cart'
                            : 'Offline',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddedSnackBar(
      BuildContext context, ThemeData theme, Product product) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Added to Alcohol Cart'),
        backgroundColor: theme.colorScheme.secondary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        action: SnackBarAction(
          label: 'View Cart',
          textColor: Colors.white,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const CartScreen(),
              ),
            );
          },
        ),
      ),
    );
  }
}
