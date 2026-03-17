import 'package:flutter/material.dart';
import 'package:queless/models/product.dart';
import 'package:queless/models/order.dart';
import 'package:queless/services/product_service.dart';
import 'package:queless/services/auth_service.dart';
import 'package:queless/services/order_service.dart';
import 'package:queless/screens/product/product_detail_screen.dart';
import 'package:queless/screens/browse/category_screen.dart';
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
import 'package:queless/widgets/promotion_modal.dart';
import 'package:queless/widgets/promo_badge.dart';

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
  List<Product> _featuredProducts = [];
  List<Product> _localBrands = [];
  List<Order> _activeOrders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      final featured = await _productService.getFeaturedProducts();
      final local = await _productService.getLocalBrandProducts();
      final active = await _orderService.getActiveOrders();
      await _promotionService.refreshActivePromotions();
      setState(() {
        _featuredProducts = featured;
        _localBrands = local.take(4).toList();
        _activeOrders = active;
        _isLoading = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _maybeShowPromotion();
      });
    } catch (e) {
      setState(() => _isLoading = false);
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
            final product =
                await _productService.getProductById(promo.targetId);
            if (!rootContext.mounted || product == null) return;
            await Navigator.push(
              rootContext,
              MaterialPageRoute(
                builder: (_) => ProductDetailScreen(product: product),
              ),
            );
            if (!rootContext.mounted) return;
            await _loadProducts();
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
              onRefresh: _loadProducts,
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
                      if (_activeOrders.length == 1)
                        _buildActiveOrderCard(theme, _activeOrders.first)
                      else
                        _buildMultipleActiveOrders(theme, _activeOrders),
                      const SizedBox(height: 24),
                    ],
                    ResponsibleDrinkingBanner(),
                    const SizedBox(height: 24),
                    Text('Categories',
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    CategoryGrid(),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Featured Products',
                            style: theme.textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        TextButton(
                          onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const BrowseScreen())),
                          child: const Text('See All'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 240,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _featuredProducts.length,
                        itemBuilder: (context, index) =>
                            ProductCard(product: _featuredProducts[index]),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.flag, color: Colors.green, size: 20),
                            const SizedBox(width: 8),
                            Text('Local Brands',
                                style: theme.textTheme.titleLarge
                                    ?.copyWith(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        TextButton(
                          onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const BrowseScreen())),
                          child: const Text('See All'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.75,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: _localBrands.length,
                      itemBuilder: (context, index) =>
                          ProductCard(product: _localBrands[index]),
                    ),
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

class CategoryGrid extends StatefulWidget {
  const CategoryGrid({super.key});

  @override
  State<CategoryGrid> createState() => _CategoryGridState();
}

class _CategoryGridState extends State<CategoryGrid> {
  final List<Map<String, dynamic>> categories = [
    {
      'name': 'Beer',
      'icon': Icons.sports_bar,
      'category': ProductCategory.beer
    },
    {'name': 'Wine', 'icon': Icons.wine_bar, 'category': ProductCategory.wine},
    {
      'name': 'Spirits',
      'icon': Icons.local_bar,
      'category': ProductCategory.spirits
    },
    {
      'name': 'Mixers',
      'icon': Icons.local_drink,
      'category': ProductCategory.mixers
    },
    {
      'name': 'Snacks',
      'icon': Icons.fastfood,
      'category': ProductCategory.snacks
    },
  ];
  int? _hoveredIndex;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isHover = _hoveredIndex == index;
          final labelColor = isHover
              ? theme.colorScheme.secondary
              : theme.colorScheme.onSurface;
          final iconColor = isHover
              ? theme.colorScheme.secondary
              : theme.colorScheme.onSurface;
          return MouseRegion(
            onEnter: (_) => setState(() => _hoveredIndex = index),
            onExit: (_) => setState(() => _hoveredIndex = null),
            child: GestureDetector(
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          CategoryScreen(category: category['category']))),
              child: Container(
                width: 80,
                margin: const EdgeInsets.only(right: 16),
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(category['icon'], color: iconColor, size: 32),
                    ),
                    const SizedBox(height: 8),
                    Text(category['name'],
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: labelColor),
                        textAlign: TextAlign.center),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class ProductCard extends StatefulWidget {
  final Product product;

  const ProductCard({super.key, required this.product});

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
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
        onTap: () async {
          await Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) =>
                      ProductDetailScreen(product: widget.product)));
          if (context.mounted) {
            (context.findAncestorStateOfType<_HomeScreenState>())
                ?._loadProducts();
          }
        },
        child: Container(
          width: 160,
          margin: const EdgeInsets.only(right: 16),
          child: Card(
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
                // Top visual area scales to available height to avoid overflow
                Expanded(
                  child: AnimatedBuilder(
                    animation: promoService,
                    builder: (context, _) {
                      final promo =
                          promoService.promotionForProduct(widget.product.id);

                      final image = widget.product.imageUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: widget.product.imageUrl,
                              imageBuilder: (context, imageProvider) =>
                                  Container(
                                padding: const EdgeInsets.only(top: 16),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surface,
                                  borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(12)),
                                ),
                                child: Image(
                                  image: imageProvider,
                                  fit: BoxFit.contain,
                                  width: double.infinity,
                                ),
                              ),
                              placeholder: (context, url) => Container(
                                decoration: BoxDecoration(
                                  color:
                                      theme.colorScheme.surfaceContainerHighest,
                                  borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(12)),
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
                                  borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(12)),
                                ),
                                child: Center(
                                  child: Icon(Icons.local_bar,
                                      size: 48,
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.3)),
                                ),
                              ),
                            )
                          : Container(
                              decoration: BoxDecoration(
                                color:
                                    theme.colorScheme.surfaceContainerHighest,
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(12)),
                              ),
                              child: Center(
                                child: Icon(Icons.local_bar,
                                    size: 48,
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
                    mainAxisSize: MainAxisSize.min,
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
      ),
    );
  }
}
