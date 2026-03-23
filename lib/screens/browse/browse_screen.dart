import 'package:flutter/material.dart';
import 'package:queless/models/product.dart';
import 'package:queless/services/product_service.dart';
import 'package:queless/services/location_service.dart';
import 'package:queless/services/store_service.dart';
import 'package:queless/services/cart_service.dart';
import 'package:queless/models/store.dart';
import 'package:queless/screens/product/product_detail_screen.dart';
import 'package:queless/utils/formatters.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:queless/services/promotion_service.dart';
import 'package:queless/widgets/promo_badge.dart';

class BrowseScreen extends StatefulWidget {
  final ProductType productType;

  const BrowseScreen({
    super.key,
    this.productType = ProductType.alcohol,
  });

  @override
  State<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends State<BrowseScreen> {
  final _productService = ProductService();
  final _promotionService = PromotionService();
  final _locationService = LocationService();
  final _storeService = StoreService();
  final _cartService = CartService();

  final _searchController = TextEditingController();
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  bool _isLoading = true;
  ProductCategory? _selectedCategory;
  Store? _nearestStore;
  double? _distanceToStore;

  // Dynamically derived categories from the loaded products
  List<ProductCategory> _availableCategories = [];

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    setState(() => _isLoading = true);
    await _promotionService.refreshActivePromotions();
    await _findNearestStore();
    await _loadProducts();
  }

  Future<void> _findNearestStore() async {
    if (widget.productType != ProductType.alcohol) return;

    final position = await _locationService.getCurrentLocation();
    if (position == null) return;

    final store = await _storeService.findNearestStore(
      latitude: position.latitude,
      longitude: position.longitude,
      category: 'liquor',
    );

    if (store != null && store.location.isNotEmpty) {
      final parts = store.location.split(',');
      if (parts.length == 2) {
        final storeLat = double.parse(parts[0].trim());
        final storeLng = double.parse(parts[1].trim());
        final distance = _locationService.calculateDistance(
          position.latitude,
          position.longitude,
          storeLat,
          storeLng,
        );

        final distanceKm = distance / 1000;

        setState(() {
          _nearestStore = store;
          _distanceToStore = distanceKm;
        });
      }
    } else {
      // No store found within 5km
      setState(() {
        _nearestStore = null;
        _distanceToStore = null;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      List<Product> productsToLoad;

      if (widget.productType == ProductType.alcohol && _nearestStore != null) {
        debugPrint(
            '🔍 BrowseScreen: Fetching products for store ${_nearestStore!.id}');
        // Load products specifically for this store
        productsToLoad =
            await _productService.getProductsByStoreId(_nearestStore!.id);
        debugPrint('🔍 BrowseScreen: Found ${productsToLoad.length} products');
      } else {
        debugPrint(
            '🔍 BrowseScreen: Loading all products for type ${widget.productType}');
        // Generic alcohol products or other types
        final allProducts = await _productService.getAllProducts();
        productsToLoad = allProducts
            .where((p) => p.productType == widget.productType)
            .toList();
      }

      // Extract available categories from the products
      final categories = productsToLoad.map((p) => p.category).toSet().toList();
      categories.sort((a, b) => a.index.compareTo(b.index));

      if (mounted) {
        setState(() {
          _products = productsToLoad;
          _filteredProducts = productsToLoad;
          _availableCategories = categories;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ BrowseScreen: Error loading products: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _filterProducts() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredProducts = _products.where((product) {
        final matchesSearch = query.isEmpty ||
            product.name.toLowerCase().contains(query) ||
            (product.brand?.toLowerCase().contains(query) ?? false);
        final matchesCategory =
            _selectedCategory == null || product.category == _selectedCategory;
        return matchesSearch && matchesCategory;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Browse Products')),
      body: Column(
        children: [
          if (widget.productType == ProductType.alcohol &&
              _nearestStore != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              child: Row(
                children: [
                  Icon(Icons.store, color: theme.colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ordering from: ${_nearestStore!.name}',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${_distanceToStore!.toStringAsFixed(1)}km away • Delivery: ${Formatters.formatCurrency(_cartService.getDeliveryFee(_nearestStore!.id))}',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          if (widget.productType == ProductType.alcohol &&
              _nearestStore == null &&
              !_isLoading)
            Expanded(
              child: Center(
                child: Container(
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color:
                        theme.colorScheme.errorContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: theme.colorScheme.error.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.error.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.location_off_rounded,
                          size: 48,
                          color: theme.colorScheme.error,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'No liquor stores available nearby',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: theme.colorScheme.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'We are currently expanding our delivery zones. If no store is shown, please check back soon!',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.7),
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else ...[
            if (_products.isNotEmpty || _isLoading)
              Padding(
                padding: const EdgeInsets.all(20),
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Search products, brands...',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (_) => _filterProducts(),
                ),
              ),
            SizedBox(
              height: 50,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  FilterChip(
                    label: const Text('All'),
                    selected: _selectedCategory == null,
                    onSelected: (_) => setState(() {
                      _selectedCategory = null;
                      _filterProducts();
                    }),
                  ),
                  const SizedBox(width: 8),
                  ..._availableCategories.map((category) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(category.displayName),
                          selected: _selectedCategory == category,
                          onSelected: (_) => setState(() {
                            _selectedCategory = category;
                            _filterProducts();
                          }),
                        ),
                      )),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredProducts.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search_off,
                                  size: 80,
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.3)),
                              const SizedBox(height: 16),
                              Text('No products found',
                                  style: theme.textTheme.titleMedium),
                            ],
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.all(20),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.7,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          itemCount: _filteredProducts.length,
                          itemBuilder: (context, index) => ProductGridItem(
                              product: _filteredProducts[index]),
                        ),
            ),
          ],
        ],
      ),
    );
  }
}

class ProductGridItem extends StatefulWidget {
  final Product product;

  const ProductGridItem({super.key, required this.product});

  @override
  State<ProductGridItem> createState() => _ProductGridItemState();
}

class _ProductGridItemState extends State<ProductGridItem> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor =
        _isHovering ? theme.colorScheme.secondary : theme.colorScheme.onSurface;
    final promoService = PromotionService();

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => ProductDetailScreen(product: widget.product))),
        child: Card(
          clipBehavior: Clip.antiAlias,
          color: theme.colorScheme.surface,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: theme.colorScheme.outline.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: AnimatedBuilder(
                  animation: promoService,
                  builder: (context, _) {
                    final promo =
                        promoService.promotionForProduct(widget.product.id);

                    final image = widget.product.imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: widget.product.imageUrl,
                            imageBuilder: (context, imageProvider) => Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surface,
                              ),
                              child: SizedBox.expand(
                                child: Image(
                                  image: imageProvider,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                            placeholder: (context, url) => Container(
                              decoration: BoxDecoration(
                                color:
                                    theme.colorScheme.surfaceContainerHighest,
                              ),
                              child: Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.3),
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              decoration: BoxDecoration(
                                color:
                                    theme.colorScheme.surfaceContainerHighest,
                              ),
                              child: Center(
                                child: Icon(Icons.local_bar,
                                    size: 56,
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.3)),
                              ),
                            ),
                          )
                        : Container(
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest,
                            ),
                            child: Center(
                              child: Icon(Icons.local_bar,
                                  size: 56,
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.3)),
                            ),
                          );

                    return Stack(
                      children: [
                        Positioned.fill(child: image),
                        if (promo != null)
                          Positioned(
                            top: 12,
                            left: 12,
                            child: PromoBadge(text: promo.badgeText),
                          ),
                      ],
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.product.isLocalBrand) ...[
                      Row(
                        children: [
                          Icon(Icons.flag,
                              size: 12,
                              color: _isHovering
                                  ? theme.colorScheme.secondary
                                  : Colors.green),
                          const SizedBox(width: 4),
                          Text('Local',
                              style: theme.textTheme.bodySmall?.copyWith(
                                  color: _isHovering
                                      ? theme.colorScheme.secondary
                                      : Colors.green,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 4),
                    ],
                    Text(
                      widget.product.name,
                      style: theme.textTheme.titleSmall
                          ?.copyWith(color: textColor),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (widget.product.volume != null)
                      Text(
                        widget.product.volume!,
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: _isHovering
                                ? theme.colorScheme.secondary
                                : theme.colorScheme.onSurface
                                    .withValues(alpha: 0.6)),
                      ),
                    const SizedBox(height: 8),
                    Text(
                      Formatters.formatCurrency(widget.product.price),
                      style: theme.textTheme.titleMedium?.copyWith(
                          color: textColor, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
