import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:queless/models/store.dart';
import 'package:queless/models/cart.dart';
import 'package:queless/services/cart_service.dart';
import 'package:queless/services/food_cart_service.dart';
import 'package:queless/services/store_service.dart';
import 'package:queless/screens/cart/cart_detail_screen.dart';
import 'package:queless/utils/formatters.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _cartService = CartService();
  final _foodCartService = FoodCartService();
  final _storeService = StoreService();
  final Map<String, Store> _stores = {};
  bool _isLoadingStores = true;

  @override
  void initState() {
    super.initState();
    _cartService.addListener(_onCartChanged);
    _foodCartService.addListener(_onCartChanged);
    _loadStores();
  }

  @override
  void dispose() {
    _cartService.removeListener(_onCartChanged);
    _foodCartService.removeListener(_onCartChanged);
    super.dispose();
  }

  void _onCartChanged() {
    _loadStores();
  }

  Future<void> _loadStores() async {
    setState(() => _isLoadingStores = true);
    final allStoreIds = {
      ..._cartService.carts.keys,
      ..._foodCartService.carts.keys,
    };

    for (final id in allStoreIds) {
      final store = await _storeService.getStoreById(id);
      if (store != null) {
        _stores[id] = store;
      }
    }

    if (mounted) {
      setState(() => _isLoadingStores = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (!_cartService.isInitialized ||
        !_foodCartService.isInitialized ||
        _isLoadingStores) {
      return Scaffold(
        appBar: AppBar(title: const Text('Carts')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final alcoholCarts = _cartService.carts;
    final foodCarts = _foodCartService.carts;

    if (alcoholCarts.isEmpty && foodCarts.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Carts')),
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
              Text('Your carts are empty', style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                'Add items from any store to get started',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('My Carts')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          ...alcoholCarts.entries.map((entry) => _buildStoreCartCard(
                theme,
                entry.value,
                _stores[entry.key],
                isFood: false,
              )),
          ...foodCarts.entries.map((entry) => _buildStoreCartCard(
                theme,
                entry.value,
                _stores[entry.key],
                isFood: true,
              )),
        ],
      ),
    );
  }

  Widget _buildStoreCartCard(ThemeData theme, Cart cart, Store? store,
      {required bool isFood}) {
    final subtotal = cart.subtotal;
    final deliveryFee = isFood
        ? _foodCartService.getDeliveryFee(cart.storeId)
        : _cartService.getDeliveryFee(cart.storeId);
    final discount = isFood
        ? _foodCartService.calculateDiscount(cart.storeId)
        : _cartService.calculateDiscount(cart.storeId);
    final total = subtotal + deliveryFee - discount;
    final totalItems = cart.totalItems;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CartDetailScreen(
                storeId: cart.storeId,
                isFood: isFood,
                store: store,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color:
                      theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: store?.imageUrl != null && store!.imageUrl.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl: store.imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: theme.colorScheme.primary
                                  .withValues(alpha: 0.3),
                            ),
                          ),
                          errorWidget: (context, url, error) => Icon(
                            isFood ? Icons.fastfood : Icons.local_bar,
                            color: theme.colorScheme.primary,
                            size: 30,
                          ),
                        ),
                      )
                    : Icon(
                        isFood ? Icons.fastfood : Icons.local_bar,
                        color: theme.colorScheme.primary,
                        size: 30,
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      store?.name ?? 'Store ${cart.storeId}',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$totalItems ${totalItems == 1 ? 'item' : 'items'}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    Formatters.formatCurrency(total),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        'View Details',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
