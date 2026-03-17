import 'package:flutter/material.dart';
import 'package:queless/services/cart_service.dart';
import 'package:queless/services/food_cart_service.dart';
import 'package:queless/screens/cart/checkout_screen.dart';
import 'package:queless/utils/formatters.dart';
import 'package:queless/utils/snack_bar_helper.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _cartService = CartService();
  final _foodCartService = FoodCartService();

  @override
  void initState() {
    super.initState();
    _cartService.addListener(_updateCart);
    _foodCartService.addListener(_updateCart);
  }

  @override
  void dispose() {
    _cartService.removeListener(_updateCart);
    _foodCartService.removeListener(_updateCart);
    super.dispose();
  }

  void _updateCart() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (!_cartService.isInitialized || !_foodCartService.isInitialized) {
      return Scaffold(
        appBar: AppBar(title: const Text('Cart')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final alcoholCart = _cartService.currentCart;
    final foodCart = _foodCartService.currentCart;

    final hasAlcoholItems = alcoholCart != null && alcoholCart.items.isNotEmpty;
    final hasFoodItems = foodCart != null && foodCart.items.isNotEmpty;

    if (!hasAlcoholItems && !hasFoodItems) {
      return Scaffold(
        appBar: AppBar(title: const Text('Cart')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.shopping_cart_outlined,
                size: 100,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 16),
              Text('Your cart is empty', style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                'Add items to get started',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final alcoholTotal = _cartService.calculateTotal();
    final foodTotal = _foodCartService.calculateTotal();

    return Scaffold(
      appBar: AppBar(title: const Text('Cart')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasAlcoholItems)
              Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        theme.colorScheme.primary.withValues(alpha: 0.1),
                    child: Icon(
                      Icons.local_bar,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  title: const Text('Alcohol Cart'),
                  subtitle: Text(
                    '${alcoholCart.totalItems} items • ${Formatters.formatCurrency(alcoholTotal)}',
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const CartDetailScreen(isFoodCart: false),
                      ),
                    );
                  },
                ),
              ),
            if (hasFoodItems)
              Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        theme.colorScheme.primary.withValues(alpha: 0.1),
                    child: Icon(
                      Icons.fastfood,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  title: const Text('Food Cart'),
                  subtitle: Text(
                    '${foodCart.totalItems} items • ${Formatters.formatCurrency(foodTotal)}',
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const CartDetailScreen(isFoodCart: true),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class CartDetailScreen extends StatefulWidget {
  final bool isFoodCart;

  const CartDetailScreen({super.key, required this.isFoodCart});

  @override
  State<CartDetailScreen> createState() => _CartDetailScreenState();
}

class _CartDetailScreenState extends State<CartDetailScreen> {
  final _cartService = CartService();
  final _foodCartService = FoodCartService();
  final _promoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cartService.addListener(_updateCart);
    _foodCartService.addListener(_updateCart);
  }

  @override
  void dispose() {
    _cartService.removeListener(_updateCart);
    _foodCartService.removeListener(_updateCart);
    _promoController.dispose();
    super.dispose();
  }

  void _updateCart() => setState(() {});

  void _checkAndPopIfEmpty() {
    final cart = widget.isFoodCart
        ? _foodCartService.currentCart
        : _cartService.currentCart;

    if (!mounted) return;
    if (cart == null || cart.items.isEmpty) {
      Navigator.pop(context);
    }
  }

  Future<void> _applyPromo() async {
    if (_promoController.text.isEmpty) return;

    if (widget.isFoodCart) {
      await _foodCartService.applyPromoCode(_promoController.text);
    } else {
      await _cartService.applyPromoCode(_promoController.text);
    }
    setState(() {});

    final discount = widget.isFoodCart
        ? _foodCartService.calculateDiscount()
        : _cartService.calculateDiscount();
    if (mounted) {
      if (discount > 0) {
        SnackBarHelper.showSuccess(
          context,
          'Promo code applied! You saved ${Formatters.formatCurrency(discount)}',
        );
      } else {
        SnackBarHelper.showError(context, 'Invalid promo code');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (!_cartService.isInitialized || !_foodCartService.isInitialized) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.isFoodCart ? 'Food Cart' : 'Alcohol Cart'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final cart = widget.isFoodCart
        ? _foodCartService.currentCart
        : _cartService.currentCart;

    if (cart == null || cart.items.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.isFoodCart ? 'Food Cart' : 'Alcohol Cart'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.shopping_cart_outlined,
                size: 100,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 16),
              Text('Your cart is empty', style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                'Add items to get started',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final subtotal =
        widget.isFoodCart ? _foodCartService.subtotal : _cartService.subtotal;
    final deliveryFee = widget.isFoodCart
        ? _foodCartService.deliveryFee
        : _cartService.deliveryFee;
    final discount = widget.isFoodCart
        ? _foodCartService.calculateDiscount()
        : _cartService.calculateDiscount();
    final total = widget.isFoodCart
        ? _foodCartService.calculateTotal()
        : _cartService.calculateTotal();

    final titlePrefix = widget.isFoodCart ? 'Food Cart' : 'Alcohol Cart';

    return Scaffold(
      appBar: AppBar(
        title: Text('$titlePrefix (${cart.totalItems} items)'),
        actions: [
          TextButton(
            onPressed: () async {
              if (widget.isFoodCart) {
                await _foodCartService.clear();
              } else {
                await _cartService.clear();
              }
              _updateCart();
              _checkAndPopIfEmpty();
            },
            child: const Text('Clear'),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: cart.items.length,
              itemBuilder: (context, index) {
                final item = cart.items[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        item.productImageUrl.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: item.productImageUrl,
                                imageBuilder: (context, imageProvider) =>
                                    Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: theme
                                        .colorScheme.surfaceContainerHighest,
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
                                    color: theme
                                        .colorScheme.surfaceContainerHighest,
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
                                    color: theme
                                        .colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    widget.isFoodCart
                                        ? Icons.fastfood
                                        : Icons.local_bar,
                                    size: 32,
                                    color: theme.colorScheme.primary
                                        .withValues(alpha: 0.5),
                                  ),
                                ),
                              )
                            : Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color:
                                      theme.colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  widget.isFoodCart
                                      ? Icons.fastfood
                                      : Icons.local_bar,
                                  size: 32,
                                  color: theme.colorScheme.primary
                                      .withValues(alpha: 0.5),
                                ),
                              ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.productName,
                                style: theme.textTheme.titleSmall,
                                maxLines: 2,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                Formatters.formatCurrency(item.price),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color:
                                    theme.colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove, size: 16),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(
                                      minWidth: 32,
                                      minHeight: 32,
                                    ),
                                    onPressed: () async {
                                      if (widget.isFoodCart) {
                                        await _foodCartService.updateQuantity(
                                          item.productId,
                                          item.quantity - 1,
                                        );
                                      } else {
                                        await _cartService.updateQuantity(
                                          item.productId,
                                          item.quantity - 1,
                                        );
                                      }
                                      _updateCart();
                                      _checkAndPopIfEmpty();
                                    },
                                  ),
                                  Text(
                                    '${item.quantity}',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add, size: 16),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(
                                      minWidth: 32,
                                      minHeight: 32,
                                    ),
                                    onPressed: () async {
                                      if (widget.isFoodCart) {
                                        await _foodCartService.updateQuantity(
                                          item.productId,
                                          item.quantity + 1,
                                        );
                                      } else {
                                        await _cartService.updateQuantity(
                                          item.productId,
                                          item.quantity + 1,
                                        );
                                      }
                                      _updateCart();
                                    },
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.delete_outline,
                                size: 20,
                                color: theme.colorScheme.error,
                              ),
                              onPressed: () async {
                                if (widget.isFoodCart) {
                                  await _foodCartService
                                      .removeItem(item.productId);
                                } else {
                                  await _cartService.removeItem(item.productId);
                                }
                                _updateCart();
                                _checkAndPopIfEmpty();
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
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
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _promoController,
                        decoration: const InputDecoration(
                          hintText: 'Promo code',
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _applyPromo,
                      child: const Text('Apply'),
                    ),
                  ],
                ),
                if (cart.promoCode != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Promo: ${cart.promoCode}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.secondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          if (widget.isFoodCart) {
                            await _foodCartService.removePromoCode();
                          } else {
                            await _cartService.removePromoCode();
                          }
                          setState(() {});
                        },
                        child: const Text('Remove'),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                OrderSummaryRow(
                  label: 'Subtotal',
                  value: Formatters.formatCurrency(subtotal),
                ),
                const SizedBox(height: 8),
                OrderSummaryRow(
                  label: 'Delivery Fee',
                  value: Formatters.formatCurrency(deliveryFee),
                ),
                if (discount > 0) ...[
                  const SizedBox(height: 8),
                  OrderSummaryRow(
                    label: 'Discount',
                    value: '-${Formatters.formatCurrency(discount)}',
                    valueColor: theme.colorScheme.secondary,
                  ),
                ],
                const Divider(height: 24),
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
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (widget.isFoodCart) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const FoodCheckoutScreen(),
                          ),
                        );
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CheckoutScreen(),
                          ),
                        );
                      }
                    },
                    child: const Text('Proceed to Checkout'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class OrderSummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const OrderSummaryRow(
      {super.key, required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: theme.textTheme.bodyMedium),
        Text(value,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: valueColor, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
