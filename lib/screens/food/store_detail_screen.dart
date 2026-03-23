import 'package:flutter/material.dart';
import 'package:queless/models/store.dart';
import 'package:queless/models/product.dart';
import 'package:queless/services/product_service.dart';
import 'package:queless/services/food_cart_service.dart';
import 'package:queless/utils/snack_bar_helper.dart';
import 'package:queless/services/promotion_service.dart';
import 'package:queless/screens/cart/cart_screen.dart';
import 'package:queless/utils/formatters.dart';
import 'package:queless/widgets/promo_badge.dart';
import 'package:cached_network_image/cached_network_image.dart';

class StoreDetailScreen extends StatefulWidget {
  final Store store;
  const StoreDetailScreen({super.key, required this.store});

  @override
  State<StoreDetailScreen> createState() => _StoreDetailScreenState();
}

class _StoreDetailScreenState extends State<StoreDetailScreen> {
  final _productService = ProductService();
  final _cartService = FoodCartService();
  List<Product> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      final products =
          await _productService.getProductsByStore(widget.store.id);
      setState(() {
        _products = products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addToCart(Product product) async {
    await _cartService.addItem(product);
    if (mounted) {
      final theme = Theme.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Added to Food Cart'),
          backgroundColor: theme.colorScheme.secondary,
          behavior: SnackBarBehavior.floating,
          width: 280,
          duration: const Duration(seconds: 4),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final promoService = PromotionService();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.store.name,
                      style: const TextStyle(
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            offset: Offset(0, 1),
                            blurRadius: 4.0,
                            color: Colors.black54,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (!widget.store.isOpen)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'OFFLINE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              background: AnimatedBuilder(
                animation: promoService,
                builder: (context, _) {
                  final promo = promoService.promotionForStore(widget.store.id);

                  final image = widget.store.imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: widget.store.imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: theme.colorScheme.surfaceContainerHighest,
                            child: Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: theme.colorScheme.primary
                                    .withValues(alpha: 0.3),
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: theme.colorScheme.surfaceContainerHighest,
                            child: Center(
                              child: Icon(Icons.restaurant_menu,
                                  size: 80,
                                  color: theme.colorScheme.primary
                                      .withValues(alpha: 0.3)),
                            ),
                          ),
                        )
                      : Container(
                          color: theme.colorScheme.surfaceContainerHighest,
                          child: Center(
                            child: Icon(Icons.restaurant_menu,
                                size: 80,
                                color: theme.colorScheme.primary
                                    .withValues(alpha: 0.3)),
                          ),
                        );

                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      image,
                      // Overlay to ensure title readability
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black54,
                            ],
                          ),
                        ),
                      ),
                      if (promo != null)
                        Positioned(
                          top: MediaQuery.of(context).padding.top + 50,
                          left: 16,
                          child: PromoBadge(text: promo.badgeText),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.store.description,
                      style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 20, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        '${widget.store.rating.toStringAsFixed(1)} (${widget.store.totalReviews} reviews)',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.delivery_dining,
                          size: 20, color: theme.colorScheme.primary),
                      const SizedBox(width: 4),
                      Text(
                        '${widget.store.deliveryTimeMin}-${widget.store.deliveryTimeMax} min',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.store.cuisineTypes.join(' • '),
                    style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                  ),
                  const Divider(height: 32),
                  if (!widget.store.isOpen)
                    Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.errorContainer
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: theme.colorScheme.error.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline,
                              color: theme.colorScheme.error),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Store is currently offline',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    color: theme.colorScheme.error,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  widget.store.nextOpeningTime ??
                                      'Will open tomorrow at 9am',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  Text('Menu',
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          _isLoading
              ? const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                )
              : _products.isEmpty
                  ? SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(40),
                          child: Text('No menu items available',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.5))),
                        ),
                      ),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => FoodProductCard(
                            product: _products[index],
                            onAddToCart: _addToCart,
                            store: widget.store,
                          ),
                          childCount: _products.length,
                        ),
                      ),
                    ),
        ],
      ),
    );
  }
}

class FoodProductCard extends StatelessWidget {
  final Product product;
  final Store store;
  final Function(Product) onAddToCart;

  const FoodProductCard(
      {super.key,
      required this.product,
      required this.onAddToCart,
      required this.store});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final promoService = PromotionService();

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                FoodProductDetailScreen(product: product, store: store),
          ),
        );
      },
      child: Opacity(
        opacity: store.isOpen ? 1.0 : 0.6,
        child: Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedBuilder(
                  animation: promoService,
                  builder: (context, _) {
                    final promo = promoService.promotionForProduct(product.id);

                    final image = product.imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: product.imageUrl,
                            imageBuilder: (context, imageProvider) => Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color:
                                    theme.colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(12),
                                image: DecorationImage(
                                  image: imageProvider,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                            placeholder: (context, url) => Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color:
                                    theme.colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(12),
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
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color:
                                    theme.colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(Icons.fastfood,
                                  size: 32,
                                  color: theme.colorScheme.primary
                                      .withValues(alpha: 0.5)),
                            ),
                          )
                        : Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.fastfood,
                                size: 32,
                                color: theme.colorScheme.primary
                                    .withValues(alpha: 0.5)),
                          );

                    return Stack(
                      children: [
                        image,
                        if (promo != null)
                          Positioned(
                            top: 4,
                            left: 4,
                            child: Transform.scale(
                              scale: 0.8,
                              child: PromoBadge(text: promo.badgeText),
                            ),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(product.name,
                          style: theme.textTheme.titleSmall, maxLines: 2),
                      const SizedBox(height: 4),
                      Text(
                        product.description,
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.6)),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            Formatters.formatCurrency(product.price),
                            style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold),
                          ),
                          if (store.isOpen)
                            FilledButton.icon(
                              onPressed: () => onAddToCart(product),
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text('Add'),
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                minimumSize: const Size(0, 36),
                              ),
                            )
                          else
                            Text(
                              'Offline',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.error,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class FoodProductDetailScreen extends StatefulWidget {
  final Product product;
  final Store store;

  const FoodProductDetailScreen(
      {super.key, required this.product, required this.store});

  @override
  State<FoodProductDetailScreen> createState() =>
      _FoodProductDetailScreenState();
}

class _FoodProductDetailScreenState extends State<FoodProductDetailScreen> {
  final _cartService = FoodCartService();
  int _quantity = 1;
  bool _isAdding = false;

  Future<void> _addToCart() async {
    setState(() => _isAdding = true);

    try {
      await _cartService.addItem(widget.product, quantity: _quantity);

      if (mounted) {
        final theme = Theme.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Added to Food Cart'),
            backgroundColor: theme.colorScheme.secondary,
            behavior: SnackBarBehavior.floating,
            width: 280,
            duration: const Duration(seconds: 4),
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
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(context, e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isAdding = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final promoService = PromotionService();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product.name,
            maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedBuilder(
                    animation: promoService,
                    builder: (context, _) {
                      final promo =
                          promoService.promotionForProduct(widget.product.id);

                      final image = widget.product.imageUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: widget.product.imageUrl,
                              imageBuilder: (context, imageProvider) =>
                                  Container(
                                height: 300,
                                decoration: BoxDecoration(
                                  color:
                                      theme.colorScheme.surfaceContainerHighest,
                                  image: DecorationImage(
                                    image: imageProvider,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                              placeholder: (context, url) => Container(
                                height: 300,
                                color:
                                    theme.colorScheme.surfaceContainerHighest,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: theme.colorScheme.primary
                                        .withValues(alpha: 0.3),
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                height: 300,
                                color:
                                    theme.colorScheme.surfaceContainerHighest,
                                child: Center(
                                  child: Icon(Icons.fastfood,
                                      size: 100,
                                      color: theme.colorScheme.primary
                                          .withValues(alpha: 0.3)),
                                ),
                              ),
                            )
                          : Container(
                              height: 300,
                              color: theme.colorScheme.surfaceContainerHighest,
                              child: Center(
                                child: Icon(Icons.fastfood,
                                    size: 100,
                                    color: theme.colorScheme.primary
                                        .withValues(alpha: 0.3)),
                              ),
                            );

                      return Stack(
                        children: [
                          image,
                          if (promo != null)
                            Positioned(
                              top: 20,
                              left: 20,
                              child: PromoBadge(text: promo.badgeText),
                            ),
                        ],
                      );
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.product.isLocalBrand) ...[
                          Row(
                            children: [
                              const Icon(Icons.flag,
                                  size: 16, color: Colors.green),
                              const SizedBox(width: 8),
                              Text(
                                'Local Brand',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                        ],
                        Text(
                          widget.product.name,
                          style: theme.textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        if (widget.product.brand != null) ...[
                          Text(
                            widget.product.brand!,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.7),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        Text(
                          Formatters.formatCurrency(widget.product.price),
                          style: theme.textTheme.headlineMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 24),
                        if (widget.product.volume != null)
                          Row(
                            children: [
                              InfoChip(
                                icon: Icons.straighten,
                                label: widget.product.volume!,
                              ),
                            ],
                          ),
                        if (widget.product.volume != null)
                          const SizedBox(height: 24),
                        Text('Description',
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(widget.product.description,
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(height: 1.5)),
                        if (widget.product.tags.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: widget.product.tags
                                .map((tag) => Chip(
                                    label: Text(tag),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8)))
                                .toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -2))
              ],
            ),
            child: widget.store.isOpen
                ? Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: _quantity > 1
                                  ? () => setState(() => _quantity--)
                                  : null,
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              child: Text('$_quantity',
                                  style: theme.textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold)),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () => setState(() => _quantity++),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isAdding ? null : _addToCart,
                          icon: _isAdding
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.add_shopping_cart),
                          label: Text(_isAdding ? 'Adding...' : 'Add to Cart'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: theme.colorScheme.onPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.error.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Store is currently offline',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.error,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.store.nextOpeningTime ??
                              'Will open tomorrow at 9am',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const InfoChip({super.key, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.onPrimaryContainer),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
