import 'package:flutter/material.dart';
import 'package:queless/models/product.dart';
import 'package:queless/services/store_service.dart';
import 'package:queless/models/store.dart';
import 'package:queless/services/food_cart_service.dart';
import 'package:queless/services/cart_service.dart';
import 'package:queless/services/auth_service.dart';
import 'package:queless/services/promotion_service.dart';
import 'package:queless/utils/formatters.dart';
import 'package:queless/screens/cart/cart_screen.dart';
import 'package:queless/widgets/promo_badge.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final _cartService = CartService();
  final _foodCartService = FoodCartService();
  final _authService = AuthService();
  final _storeService = StoreService();
  int _quantity = 1;
  bool _isAdding = false;
  Store? _store;
  bool _isLoadingStore = false;

  @override
  void initState() {
    super.initState();
    if (widget.product.storeId != null) {
      _loadStore();
    }
  }

  Future<void> _loadStore() async {
    setState(() => _isLoadingStore = true);
    try {
      final store = await _storeService.getStoreById(widget.product.storeId!);
      if (mounted) {
        setState(() {
          _store = store;
          _isLoadingStore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingStore = false);
      }
    }
  }

  Future<void> _addToCart() async {
    setState(() => _isAdding = true);

    try {
      final isFood = _store?.category == 'food';
      if (isFood) {
        await _foodCartService.addItem(widget.product, quantity: _quantity);
      } else {
        await _cartService.addItem(widget.product, quantity: _quantity);
      }

      if (mounted) {
        final theme = Theme.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(isFood ? 'Added to Food Cart' : 'Added to Alcohol Cart'),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.toString()),
              backgroundColor: Theme.of(context).colorScheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isAdding = false);
    }
  }

  void _toggleFavorite() async {
    await _authService.toggleFavorite(widget.product.id);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isFavorite = _authService.currentUser?.favoriteProducts
            .contains(widget.product.id) ??
        false;

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border),
            onPressed: _toggleFavorite,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedBuilder(
                    animation: PromotionService(),
                    builder: (context, _) {
                      final promo = PromotionService()
                          .promotionForProduct(widget.product.id);

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
                                  child: Icon(Icons.local_bar,
                                      size: 100,
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.3)),
                                ),
                              ),
                            )
                          : Container(
                              height: 300,
                              color: theme.colorScheme.surfaceContainerHighest,
                              child: Center(
                                child: Icon(Icons.local_bar,
                                    size: 100,
                                    color: theme.colorScheme.onSurface
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
                              Text('Local Brand',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 12),
                        ],
                        Text(widget.product.name,
                            style: theme.textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        if (widget.product.brand != null) ...[
                          Text(widget.product.brand!,
                              style: theme.textTheme.titleMedium?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.7))),
                          const SizedBox(height: 16),
                        ],
                        Text(Formatters.formatCurrency(widget.product.price),
                            style: theme.textTheme.headlineMedium?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 24),
                        if (widget.product.volume != null ||
                            widget.product.alcoholContent != null)
                          Row(
                            children: [
                              if (widget.product.volume != null)
                                InfoChip(
                                    icon: Icons.straighten,
                                    label: widget.product.volume!),
                              if (widget.product.volume != null &&
                                  widget.product.alcoholContent != null)
                                const SizedBox(width: 12),
                              if (widget.product.alcoholContent != null)
                                InfoChip(
                                    icon: Icons.percent,
                                    label:
                                        '${widget.product.alcoholContent}% ABV'),
                            ],
                          ),
                        if (widget.product.volume != null ||
                            widget.product.alcoholContent != null)
                          const SizedBox(height: 24),
                        Text('Description',
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(widget.product.description,
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(height: 1.5)),
                        const SizedBox(height: 24),
                        if (widget.product.tags.isNotEmpty) ...[
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
                          const SizedBox(height: 24),
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
            child: _isLoadingStore
                ? const Center(child: CircularProgressIndicator())
                : (_store?.isOpen ?? true)
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
                                        : null),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12),
                                  child: Text('$_quantity',
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                              fontWeight: FontWeight.bold)),
                                ),
                                IconButton(
                                    icon: const Icon(Icons.add),
                                    onPressed: () =>
                                        setState(() => _quantity++)),
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
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2))
                                  : const Icon(Icons.shopping_cart_outlined),
                              label: _isAdding
                                  ? const SizedBox.shrink()
                                  : FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        'Add • ${Formatters.formatCurrency(widget.product.price * _quantity)}',
                                        maxLines: 1,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
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
                            color:
                                theme.colorScheme.error.withValues(alpha: 0.2),
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
                              _store?.nextOpeningTime ??
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
          Text(label,
              style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
