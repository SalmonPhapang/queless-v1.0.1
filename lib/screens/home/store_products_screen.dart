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
import 'package:queless/utils/snack_bar_helper.dart';
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStoreHeader(theme),
                _buildCategoryChips(),
                Expanded(
                  child: _buildProductList(theme),
                ),
                _buildBottomActions(theme),
              ],
            ),
    );
  }

  Widget _buildBottomActions(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Back to Stores'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStoreHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.store.name,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.store.cuisineTypes.join(', '),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.star_rounded,
                  color: theme.colorScheme.tertiary, size: 18),
              const SizedBox(width: 4),
              Text(
                '${widget.store.rating} (${widget.store.totalReviews} reviews)',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(width: 16),
              Icon(Icons.delivery_dining_rounded,
                  color: theme.colorScheme.primary, size: 18),
              const SizedBox(width: 4),
              Text(
                '${widget.store.deliveryTimeMin}-${widget.store.deliveryTimeMax} min',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(width: 16),
              Icon(Icons.location_on_rounded,
                  color: theme.colorScheme.secondary, size: 18),
              const SizedBox(width: 4),
              Text(
                _distance != null ? '${_distance!.toStringAsFixed(1)} km' : '',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChips() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = category['category'] == _selectedCategory;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(category['name']),
              selected: isSelected,
              onSelected: (_) => _filterByCategory(category['category']),
              avatar: Icon(category['icon'], size: 18),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductList(ThemeData theme) {
    if (_filteredProducts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off,
                size: 64, color: theme.colorScheme.onSurface.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text(
              'No products found in this category',
              style: theme.textTheme.titleMedium,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredProducts.length,
      itemBuilder: (context, index) {
        final product = _filteredProducts[index];
        final promoService = PromotionService();

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProductDetailScreen(product: product),
              ),
            ),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Stack(
                      children: [
                        CachedNetworkImage(
                          imageUrl: product.imageUrl,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            width: 80,
                            height: 80,
                            color: theme.colorScheme.surfaceContainerHighest,
                          ),
                          errorWidget: (context, url, error) => Container(
                            width: 80,
                            height: 80,
                            color: theme.colorScheme.surfaceContainerHighest,
                            child: Icon(Icons.broken_image,
                                color: theme.colorScheme.onSurface),
                          ),
                        ),
                        AnimatedBuilder(
                          animation: promoService,
                          builder: (context, _) {
                            final promo =
                                promoService.promotionForProduct(product.id);
                            if (promo != null && promo.badgeText != null) {
                              return Positioned(
                                top: 4,
                                left: 4,
                                child: PromoBadge(text: promo.badgeText!),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: product.isInStock
                                ? theme.colorScheme.onSurface
                                : theme.colorScheme.onSurface.withOpacity(0.5),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (product.brand != null && product.brand!.isNotEmpty)
                          Text(
                            product.brand!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withOpacity(product.isInStock ? 0.7 : 0.4),
                            ),
                          ),
                        const SizedBox(height: 4),
                        Text(
                          product.description,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withOpacity(product.isInStock ? 1.0 : 0.4),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 12,
                          runSpacing: 4,
                          children: [
                            Text(
                              Formatters.formatCurrency(product.price),
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: product.isInStock
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.primary
                                        .withOpacity(0.5),
                              ),
                            ),
                            if (!product.isInStock)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.errorContainer,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'OUT OF STOCK',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.error,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.add_shopping_cart,
                      color: product.isInStock
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface.withOpacity(0.2),
                    ),
                    onPressed: product.isInStock
                        ? () {
                            if (widget.store.category == 'food') {
                              FoodCartService().addItem(product);
                            } else {
                              CartService().addItem(product);
                            }
                            SnackBarHelper.showSuccess(
                                context, '${product.name} added to cart!');
                          }
                        : null,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
