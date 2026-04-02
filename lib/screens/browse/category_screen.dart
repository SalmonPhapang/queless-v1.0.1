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

class CategoryScreen extends StatefulWidget {
  final String category;

  const CategoryScreen({super.key, required this.category});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final _productService = ProductService();
  final _promotionService = PromotionService();
  final _locationService = LocationService();
  final _storeService = StoreService();
  final _cartService = CartService();

  List<Product> _products = [];
  bool _isLoading = true;
  Store? _nearestStore;
  double? _distanceToStore;

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
    final position = await _locationService.getCurrentLocation();
    if (position == null) return;

    final store = await _storeService.findNearestStore(
      latitude: position.latitude,
      longitude: position.longitude,
      category: 'liquor',
    );

    if (store != null) {
      final distanceKm = (store.distance ?? 0) / 1000;

      setState(() {
        _nearestStore = store;
        _distanceToStore = distanceKm;
      });

      // Update distance in cart service for fee calculation
      _cartService.updateStoreDistance(store.id, store.distance ?? 0);
    }
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      List<Product> productsToLoad;

      if (_nearestStore != null) {
        debugPrint(
            '🔍 CategoryScreen: Fetching products for category ${widget.category} and store ${_nearestStore!.id}');
        // Load products specifically from the nearest store and category
        final storeProducts =
            await _productService.getProductsByStoreId(_nearestStore!.id);

        productsToLoad =
            storeProducts.where((p) => p.category == widget.category).toList();
        debugPrint(
            '🔍 CategoryScreen: Found ${productsToLoad.length} products');
      } else {
        debugPrint(
            '🔍 CategoryScreen: Loading all products for category ${widget.category}');
        productsToLoad =
            await _productService.getProductsByCategory(widget.category);
      }

      if (mounted) {
        setState(() {
          _products = productsToLoad;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ CategoryScreen: Error loading products: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(widget.category)),
      body: Column(
        children: [
          if (_nearestStore != null)
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
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _products.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 64,
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.3),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _nearestStore == null
                                  ? 'No liquor stores available nearby'
                                  : 'No products in this category from ${_nearestStore!.name}',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.titleMedium,
                            ),
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
                        itemCount: _products.length,
                        itemBuilder: (context, index) {
                          final product = _products[index];
                          return _HoverProductCard(product: product);
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _HoverProductCard extends StatefulWidget {
  final Product product;

  const _HoverProductCard({required this.product});

  @override
  State<_HoverProductCard> createState() => _HoverProductCardState();
}

class _HoverProductCardState extends State<_HoverProductCard> {
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
            borderRadius: BorderRadius.circular(16),
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
                                  color: theme.colorScheme.primary
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
                    Text(widget.product.name,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(color: textColor),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    if (widget.product.volume != null)
                      Text(widget.product.volume!,
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: _isHovering
                                  ? theme.colorScheme.secondary
                                  : theme.colorScheme.onSurface
                                      .withValues(alpha: 0.6))),
                    const SizedBox(height: 8),
                    Text(Formatters.formatCurrency(widget.product.price),
                        style: theme.textTheme.titleMedium?.copyWith(
                            color: textColor, fontWeight: FontWeight.bold)),
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
