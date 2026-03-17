import 'package:flutter/material.dart';
import 'package:queless/models/order.dart';
import 'package:queless/models/product.dart';
import 'package:queless/services/order_service.dart';
import 'package:queless/services/product_service.dart';
import 'package:queless/utils/snack_bar_helper.dart';
import 'package:queless/screens/orders/order_tracking_screen.dart';
import 'package:queless/utils/formatters.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen>
    with SingleTickerProviderStateMixin {
  final _orderService = OrderService();
  final _productService = ProductService();
  late TabController _tabController;
  List<Order> _activeOrders = [];
  List<Order> _orderHistory = [];
  bool _isLoading = true;
  Map<String, String> _orderTypeLabels = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final active = await _orderService.getActiveOrders();
      final history = await _orderService.getOrderHistory();
      final typeLabels = <String, String>{};

      if (mounted) {
        setState(() {
          _activeOrders = active;
          _orderHistory = history;
        });
      }

      final allOrders = [...active, ...history];
      for (final order in allOrders) {
        if (order.items.isEmpty) continue;
        final firstItem = order.items.first;
        try {
          final product =
              await _productService.getProductById(firstItem.productId);
          if (product != null) {
            final label =
                product.productType == ProductType.food ? 'Food' : 'Alcohol';
            typeLabels[order.id] = label;
          }
        } catch (e) {
          debugPrint('Error fetching product label for order ${order.id}: $e');
        }
      }

      if (mounted) {
        setState(() {
          _orderTypeLabels = typeLabels;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading orders: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        SnackBarHelper.showError(
            context, 'Failed to load orders. Please try again.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOrderList(_activeOrders, 'No active orders'),
                _buildOrderList(_orderHistory, 'No order history'),
              ],
            ),
    );
  }

  Widget _buildOrderList(List<Order> orders, String emptyMessage) {
    final theme = Theme.of(context);

    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined,
                size: 80,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text(emptyMessage, style: theme.textTheme.titleMedium),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadOrders,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          final typeLabel = _orderTypeLabels[order.id] ?? 'Alcohol';
          return OrderCard(order: order, orderTypeLabel: typeLabel);
        },
      ),
    );
  }
}

class OrderCard extends StatelessWidget {
  final Order order;
  final String orderTypeLabel;

  const OrderCard(
      {super.key, required this.order, required this.orderTypeLabel});

  Color _getStatusColor(OrderStatus status, BuildContext context) {
    final theme = Theme.of(context);
    switch (status) {
      case OrderStatus.pending:
      case OrderStatus.confirmed:
        return Colors.orange;
      case OrderStatus.preparing:
      case OrderStatus.outForDelivery:
        return theme.colorScheme.primary;
      case OrderStatus.delivered:
        return Colors.green;
      case OrderStatus.cancelled:
        return theme.colorScheme.error;
    }
  }

  Color _getOrderTypeColor(BuildContext context) {
    final theme = Theme.of(context);
    if (orderTypeLabel.toLowerCase() == 'food') {
      return theme.colorScheme.secondary;
    }
    return theme.colorScheme.primary;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OrderTrackingScreen(
              orderId: order.id,
              source: OrderTrackingSource.orders,
            ),
          ),
        ),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    order.orderNumber.isNotEmpty
                        ? order.orderNumber
                        : 'Order #${order.id.substring(0, 8)}',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(order.status, context)
                          .withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      order.status.displayName,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: _getStatusColor(order.status, context),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color:
                          _getOrderTypeColor(context).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          orderTypeLabel.toLowerCase() == 'food'
                              ? Icons.restaurant
                              : Icons.local_bar,
                          size: 14,
                          color: _getOrderTypeColor(context),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$orderTypeLabel order',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: _getOrderTypeColor(context),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.calendar_today,
                      size: 14,
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                  const SizedBox(width: 6),
                  Text(Formatters.formatDateTime(order.createdAt),
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.6))),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.location_on_outlined,
                      size: 14,
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      order.deliveryAddress.streetAddress,
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.6)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${order.totalItems} items',
                      style: theme.textTheme.bodyMedium),
                  Text(Formatters.formatCurrency(order.total),
                      style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
