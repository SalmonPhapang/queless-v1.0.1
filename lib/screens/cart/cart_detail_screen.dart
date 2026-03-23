import 'package:flutter/material.dart';
import 'package:queless/models/store.dart';
import 'package:queless/services/cart_service.dart';
import 'package:queless/services/food_cart_service.dart';
import 'package:queless/screens/cart/checkout_screen.dart';
import 'package:queless/utils/formatters.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CartDetailScreen extends StatefulWidget {
  final String storeId;
  final bool isFood;
  final Store? store;

  const CartDetailScreen({
    super.key,
    required this.storeId,
    required this.isFood,
    this.store,
  });

  @override
  State<CartDetailScreen> createState() => _CartDetailScreenState();
}

class _CartDetailScreenState extends State<CartDetailScreen> {
  final _cartService = CartService();
  final _foodCartService = FoodCartService();

  @override
  void initState() {
    super.initState();
    _cartService.addListener(_refresh);
    _foodCartService.addListener(_refresh);
  }

  @override
  void dispose() {
    _cartService.removeListener(_refresh);
    _foodCartService.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cart = widget.isFood
        ? _foodCartService.carts[widget.storeId]
        : _cartService.carts[widget.storeId];

    if (cart == null || cart.items.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.store?.name ?? 'Cart')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.shopping_cart_outlined,
                size: 80,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 16),
              const Text('This cart is empty'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    final subtotal = cart.subtotal;
    final deliveryFee = widget.isFood
        ? _foodCartService.getDeliveryFee(cart.storeId)
        : _cartService.getDeliveryFee(cart.storeId);
    final discount = widget.isFood
        ? _foodCartService.calculateDiscount(cart.storeId)
        : _cartService.calculateDiscount(cart.storeId);
    final total = subtotal + deliveryFee - discount;
    final minOrder = widget.isFood
        ? _foodCartService.minimumOrderLimit
        : _cartService.minimumOrderLimit;
    final isMinMet = subtotal >= minOrder;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.store?.name ?? 'Cart Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              _showClearDialog(context);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: cart.items.length,
              separatorBuilder: (_, __) => const Divider(height: 32),
              itemBuilder: (context, index) {
                final item = cart.items[index];
                return Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: item.productImageUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: item.productImageUrl,
                              width: 70,
                              height: 70,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              width: 70,
                              height: 70,
                              color: theme.colorScheme.surfaceContainerHighest,
                              child: Icon(
                                widget.isFood
                                    ? Icons.fastfood
                                    : Icons.local_bar,
                                size: 32,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.productName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            Formatters.formatCurrency(item.price),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: () {
                            if (widget.isFood) {
                              _foodCartService.updateQuantity(widget.storeId,
                                  item.productId, item.quantity - 1);
                            } else {
                              _cartService.updateQuantity(widget.storeId,
                                  item.productId, item.quantity - 1);
                            }
                          },
                        ),
                        Text(
                          '${item.quantity}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: () {
                            if (widget.isFood) {
                              _foodCartService.updateQuantity(widget.storeId,
                                  item.productId, item.quantity + 1);
                            } else {
                              _cartService.updateQuantity(widget.storeId,
                                  item.productId, item.quantity + 1);
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildPriceRow(
                      'Subtotal', Formatters.formatCurrency(subtotal), theme),
                  const SizedBox(height: 8),
                  _buildPriceRow('Delivery Fee',
                      Formatters.formatCurrency(deliveryFee), theme),
                  if (discount > 0) ...[
                    const SizedBox(height: 8),
                    _buildPriceRow('Discount',
                        '-${Formatters.formatCurrency(discount)}', theme,
                        isDiscount: true),
                  ],
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Divider(),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        Formatters.formatCurrency(total),
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (!isMinMet)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.errorContainer
                              .withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: theme.colorScheme.error
                                  .withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline,
                                color: theme.colorScheme.error, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Minimum order R${minOrder.toStringAsFixed(0)} required to checkout.',
                                style: theme.textTheme.bodySmall
                                    ?.copyWith(color: theme.colorScheme.error),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: isMinMet
                          ? () {
                              if (widget.isFood) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => FoodCheckoutScreen(
                                        storeId: widget.storeId),
                                  ),
                                );
                              } else {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        CheckoutScreen(storeId: widget.storeId),
                                  ),
                                );
                              }
                            }
                          : null,
                      child: const Text('PROCEED TO CHECKOUT'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String value, ThemeData theme,
      {bool isDiscount = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: theme.textTheme.bodyMedium),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isDiscount ? theme.colorScheme.secondary : null,
            fontWeight: isDiscount ? FontWeight.bold : null,
          ),
        ),
      ],
    );
  }

  void _showClearDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cart?'),
        content: const Text(
            'Are you sure you want to remove all items from this cart?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              if (widget.isFood) {
                _foodCartService.clear(widget.storeId);
              } else {
                _cartService.clear(widget.storeId);
              }
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to CartScreen
            },
            child: const Text('CLEAR', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
