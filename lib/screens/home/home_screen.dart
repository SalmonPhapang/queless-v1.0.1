import 'package:flutter/material.dart';
import 'package:queless/models/product.dart';
import 'package:queless/models/order.dart';
import 'package:queless/services/product_service.dart';
import 'package:queless/services/auth_service.dart';
import 'package:queless/services/order_service.dart';
import 'package:queless/screens/product/product_detail_screen.dart';
import 'package:queless/screens/browse/browse_screen.dart';
import 'package:queless/screens/food/store_detail_screen.dart';
import 'package:queless/screens/orders/orders_screen.dart';
import 'package:queless/screens/orders/order_tracking_screen.dart';
import 'package:queless/utils/formatters.dart';
import 'package:queless/utils/compliance_helper.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:queless/models/promotion.dart';
import 'package:queless/services/promotion_service.dart';
import 'package:queless/services/store_service.dart';
import 'package:queless/services/location_service.dart';
import 'package:queless/services/cart_service.dart';
import 'package:queless/models/store.dart';
import 'package:queless/widgets/promotion_modal.dart';
import 'package:queless/widgets/promo_badge.dart';
import 'package:queless/screens/home/store_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _productService = ProductService();
  final _authService = AuthService();
  final _orderService = OrderService();
  final _promotionService = PromotionService();
  final _storeService = StoreService();
  final _locationService = LocationService();
  final _cartService = CartService();
  List<Order> _activeOrders = [];
  bool _isLoading = true;
  List<Store> _nearbyStores = [];
  String? _userAddress;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    setState(() => _isLoading = true);
    await _fetchNearbyStoresAndAddress();
    await _loadOrdersAndPromotions();
  }

  Future<void> _fetchNearbyStoresAndAddress() async {
    final position = await _locationService.getCurrentLocation();
    if (position == null) return;

    // 1. Try 5km radius
    var stores = await _storeService.getNearbyStores(
      latitude: position.latitude,
      longitude: position.longitude,
      radiusMeters: 5000,
      category: 'liquor',
    );

    bool isExtendedRange = false;
    if (stores.isEmpty) {
      // 2. Try 10km radius
      stores = await _storeService.getNearbyStores(
        latitude: position.latitude,
        longitude: position.longitude,
        radiusMeters: 10000,
        category: 'liquor',
      );
      if (stores.isNotEmpty) {
        isExtendedRange = true;
      }
    }

    final address = await _locationService.getAddressFromCoordinates(
        position.latitude, position.longitude);

    if (mounted) {
      setState(() {
        _nearbyStores = stores;
        _userAddress = address;
        _isExtendedRange = isExtendedRange;
      });

      // Update distances in cart service for fee calculation
      for (final store in stores) {
        if (store.distance != null) {
          _cartService.updateStoreDistance(store.id, store.distance!);
        }
      }
    }
  }

  bool _isExtendedRange = false;

  Future<void> _loadOrdersAndPromotions() async {
    setState(() => _isLoading = true);
    try {
      final active = await _orderService.getActiveOrders();
      await _promotionService.refreshActivePromotions();

      if (mounted) {
        setState(() {
          _activeOrders = active;
          _isLoading = false;
        });
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _maybeShowPromotion();
      });
    } catch (e) {
      debugPrint('❌ Error loading orders/promotions in HomeScreen: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _maybeShowPromotion() async {
    final promo = _promotionService.featuredPromotion;
    if (promo == null) return;
    if (!await _promotionService.shouldShowPromotionModal()) return;
    if (!context.mounted) return;

    final rootContext = context;
    await showDialog<void>(
      context: rootContext,
      builder: (dialogContext) => PromotionModal(
        promotion: promo,
        onDismiss: () => Navigator.pop(dialogContext),
        onView: () async {
          Navigator.pop(dialogContext);
          if (!rootContext.mounted) return;

          if (promo.targetType == PromotionTargetType.product) {
            await Navigator.push(
              rootContext,
              MaterialPageRoute(
                builder: (_) => BrowseScreen(
                  productIds: promo.targetIds,
                  title: promo.title,
                ),
              ),
            );
            if (!rootContext.mounted) return;
            await _loadOrdersAndPromotions();
            return;
          }

          final store = await _storeService.getStoreById(promo.targetId);
          if (!rootContext.mounted || store == null) return;
          await Navigator.push(
            rootContext,
            MaterialPageRoute(builder: (_) => StoreDetailScreen(store: store)),
          );
        },
      ),
    );

    await _promotionService.markPromotionModalShown();
  }

  Widget _buildBadge(ThemeData theme, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: theme.textTheme.labelSmall?.copyWith(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildActiveOrderCard(ThemeData theme, Order order) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.local_shipping,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Active Order',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _buildBadge(theme, order.status.displayName, Colors.black),
                    _buildBadge(theme, order.orderType,
                        Colors.white.withValues(alpha: 0.2)),
                    Text(
                      Formatters.formatCurrency(order.total),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => OrderTrackingScreen(
                    orderId: order.id,
                    source: OrderTrackingSource.home,
                  ),
                ),
              );
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: BorderSide(
                color: Colors.white.withValues(alpha: 0.9),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              minimumSize: const Size(0, 32),
              textStyle: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            child: const Text('Track'),
          ),
        ],
      ),
    );
  }

  Widget _buildMultipleActiveOrders(ThemeData theme, List<Order> orders) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Active Orders (${orders.length})',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const OrdersScreen()),
              ),
              child: const Text('View All'),
            ),
          ],
        ),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return Container(
                width: MediaQuery.of(context).size.width * 0.8,
                margin: const EdgeInsets.only(right: 12),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.local_shipping,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            order.orderNumber.isNotEmpty
                                ? order.orderNumber
                                : 'Order #${order.id.substring(0, 6)}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              _buildBadge(theme, order.status.displayName,
                                  Colors.black),
                              _buildBadge(theme, order.orderType,
                                  Colors.white.withValues(alpha: 0.2)),
                              Text(
                                Formatters.formatCurrency(order.total),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => OrderTrackingScreen(
                              orderId: order.id,
                              source: OrderTrackingSource.home,
                            ),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        minimumSize: const Size(0, 30),
                        textStyle: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      child: const Text('Track'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = _authService.currentUser;
    final hasActiveOrder = _activeOrders.isNotEmpty;
    final latestOrder = hasActiveOrder ? _activeOrders.first : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Queless'),
        actions: const [],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _initData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        'Hello, ${user?.fullName.split(' ').first ?? 'Guest'}!',
                        style: theme.textTheme.headlineSmall),
                    const SizedBox(height: 8),
                    Text(
                      'What would you like to order today?',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    if (hasActiveOrder) ...[
                      const SizedBox(height: 24),
                      if (_activeOrders.length == 1)
                        _buildActiveOrderCard(theme, _activeOrders.first)
                      else
                        _buildMultipleActiveOrders(theme, _activeOrders),
                    ],
                    if (_userAddress != null) ...[
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color:
                              theme.colorScheme.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: theme.colorScheme.primary
                                .withValues(alpha: 0.1),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary
                                    .withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.location_on_rounded,
                                color: theme.colorScheme.primary,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Your Location',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _userAddress!,
                                    style:
                                        theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    const ResponsibleDrinkingBanner(),
                    if (_isExtendedRange) ...[
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondaryContainer
                              .withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: theme.colorScheme.secondary
                                .withValues(alpha: 0.1),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline_rounded,
                                color: theme.colorScheme.secondary),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'No stores within 5km. Showing nearby options within 10km. Delivery fee: R45.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.secondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (_nearbyStores.isNotEmpty) ...[
                      const SizedBox(height: 32),
                      Text('Liquor Stores',
                          style: theme.textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _nearbyStores.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final store = _nearbyStores[index];
                          return StoreCard(store: store);
                        },
                      ),
                    ] else if (!_isLoading) ...[
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.errorContainer
                              .withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color:
                                theme.colorScheme.error.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.location_off_rounded,
                                color: theme.colorScheme.error),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'No liquor stores available',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.error,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (_nearbyStores.isEmpty && !_isLoading) ...[
                      const SizedBox(height: 48),
                      Center(
                        child: Column(
                          children: [
                            Icon(Icons.search_off_rounded,
                                size: 64,
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.2)),
                            const SizedBox(height: 16),
                            Text(
                              'Explore categories to see what we offer\nin other regions!',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}

class ResponsibleDrinkingBanner extends StatelessWidget {
  const ResponsibleDrinkingBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Color(0xFFFFFFFF), size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              ComplianceHelper.getRandomResponsibleDrinkingMessage(),
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: const Color(0xFFFFFFFF)),
            ),
          ),
        ],
      ),
    );
  }
}
