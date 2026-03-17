import 'package:flutter/foundation.dart';
import 'package:queless/models/order.dart';
import 'package:queless/models/user.dart';
import 'package:queless/services/auth_service.dart';
import 'package:queless/services/cart_service.dart';
import 'package:queless/services/food_cart_service.dart';
import 'package:queless/supabase/supabase_config.dart';
import 'package:queless/utils/id_generator.dart';

class OrderService {
  static final OrderService _instance = OrderService._internal();
  factory OrderService() => _instance;
  OrderService._internal();

  final _authService = AuthService();
  final _cartService = CartService();
  final _foodCartService = FoodCartService();

  Future<void> init() async {}

  Future<Order> createOrder({
    required Address deliveryAddress,
    required String paymentMethod,
    DateTime? scheduledDelivery,
  }) async {
    final user = _authService.currentUser;
    final cart = _cartService.currentCart;

    if (user == null || cart == null || cart.items.isEmpty) {
      throw Exception(
          'Cannot create order: user not logged in or cart is empty');
    }

    final now = DateTime.now();
    final orderItems = cart.items
        .map((cartItem) => OrderItem(
              productId: cartItem.productId,
              productName: cartItem.productName,
              productImageUrl: cartItem.productImageUrl,
              quantity: cartItem.quantity,
              pricePerUnit: cartItem.price,
              totalPrice: cartItem.totalPrice,
            ))
        .toList();

    final subtotal = _cartService.subtotal;
    final deliveryFee = _cartService.deliveryFee;
    final discount = _cartService.calculateDiscount();
    final total = _cartService.calculateTotal();
    final orderNumber = IdGenerator.generateOrderNumber();

    final orderData = {
      'user_id': user.id,
      'order_number': orderNumber,
      'items': orderItems.map((i) => i.toJson()).toList(),
      'subtotal': subtotal,
      'delivery_fee': deliveryFee,
      'discount': discount,
      'total': total,
      'status': OrderStatus.pending.name,
      'delivery_address': deliveryAddress.toJson(),
      'payment_method': paymentMethod,
      'payment_status': PaymentStatus.pending.name,
      'scheduled_delivery': scheduledDelivery?.toIso8601String(),
      'tracking_updates': [
        {
          'status': 'pending',
          'message': 'Order placed successfully',
          'timestamp': now.toIso8601String(),
        }
      ],
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
    };

    try {
      final result = await SupabaseService.insert('orders', orderData);
      await _cartService.clear();

      return Order.fromJson(result.first);
    } catch (e) {
      debugPrint('Error creating order: $e');
      rethrow;
    }
  }

  Future<Order> createFoodOrder({
    required Address deliveryAddress,
    required String paymentMethod,
    DateTime? scheduledDelivery,
  }) async {
    final user = _authService.currentUser;
    final cart = _foodCartService.currentCart;

    if (user == null || cart == null || cart.items.isEmpty) {
      throw Exception(
          'Cannot create order: user not logged in or cart is empty');
    }

    final now = DateTime.now();
    final orderItems = cart.items
        .map(
          (cartItem) => OrderItem(
            productId: cartItem.productId,
            productName: cartItem.productName,
            productImageUrl: cartItem.productImageUrl,
            quantity: cartItem.quantity,
            pricePerUnit: cartItem.price,
            totalPrice: cartItem.totalPrice,
          ),
        )
        .toList();

    final subtotal = _foodCartService.subtotal;
    final deliveryFee = _foodCartService.deliveryFee;
    final discount = _foodCartService.calculateDiscount();
    final total = _foodCartService.calculateTotal();
    final storeId = _foodCartService.currentStoreId;
    final orderNumber = IdGenerator.generateOrderNumber();

    final orderData = {
      'user_id': user.id,
      'order_number': orderNumber,
      'items': orderItems.map((i) => i.toJson()).toList(),
      'subtotal': subtotal,
      'delivery_fee': deliveryFee,
      'discount': discount,
      'total': total,
      'status': OrderStatus.pending.name,
      'delivery_address': deliveryAddress.toJson(),
      'payment_method': paymentMethod,
      'payment_status': PaymentStatus.pending.name,
      'scheduled_delivery': scheduledDelivery?.toIso8601String(),
      'tracking_updates': [
        {
          'status': 'pending',
          'message': 'Order placed successfully',
          'timestamp': now.toIso8601String(),
        }
      ],
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
      'store_id': storeId,
    };

    try {
      final result = await SupabaseService.insert('orders', orderData);
      await _foodCartService.clear();

      return Order.fromJson(result.first);
    } catch (e) {
      debugPrint('Error creating food order: $e');
      rethrow;
    }
  }

  Future<List<Order>> getUserOrders() async {
    final user = _authService.currentUser;
    if (user == null) return [];

    try {
      final data = await SupabaseService.select(
        'orders',
        filters: {'user_id': user.id},
        orderBy: 'created_at',
        ascending: false,
      );

      final orders = data
          .map((json) {
            try {
              return Order.fromJson(json);
            } catch (e) {
              debugPrint('Skipping malformed order: $e');
              return null;
            }
          })
          .whereType<Order>()
          .toList();

      // Run stale order cancellation in background
      _autoCancelStalePendingOrders(orders).catchError((e) {
        debugPrint('Error in auto-cancel background task: $e');
      });

      return orders;
    } catch (e) {
      debugPrint('Error getting user orders: $e');
      rethrow;
    }
  }

  Future<List<Order>> getActiveOrders() async {
    final userOrders = await getUserOrders();
    return userOrders
        .where((order) =>
            order.status != OrderStatus.delivered &&
            order.status != OrderStatus.cancelled)
        .toList();
  }

  Future<List<Order>> getOrderHistory() async {
    final userOrders = await getUserOrders();
    return userOrders
        .where((order) =>
            order.status == OrderStatus.delivered ||
            order.status == OrderStatus.cancelled)
        .toList();
  }

  Future<Order?> getOrderById(String orderId) async {
    try {
      final data = await SupabaseService.selectSingle(
        'orders',
        filters: {'id': orderId},
      );

      return data != null ? Order.fromJson(data) : null;
    } catch (e) {
      debugPrint('Error getting order by id: $e');
      return null;
    }
  }

  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    try {
      final order = await getOrderById(orderId);
      if (order == null) return;

      final trackingUpdates = List<TrackingUpdate>.from(order.trackingUpdates);
      final now = DateTime.now();

      trackingUpdates.add(TrackingUpdate(
        status: status.name,
        message: _getStatusMessage(status),
        timestamp: now,
      ));

      final updateData = <String, dynamic>{
        'status': status.name,
        'tracking_updates': trackingUpdates.map((t) => t.toJson()).toList(),
        'updated_at': now.toIso8601String(),
      };

      // Assign driver when order is out for delivery
      if (status == OrderStatus.outForDelivery && order.driverName == null) {
        final driverNames = [
          'Thabo Mbeki',
          'Sipho Ndlovu',
          'Zanele Khumalo',
          'Lerato Mokoena',
          'Kgotso Molefe'
        ];
        final randomDriver =
            driverNames[DateTime.now().millisecond % driverNames.length];
        updateData['driver_name'] = randomDriver;
        updateData['driver_phone'] =
            '+27 ${(DateTime.now().millisecond % 90 + 10)} ${(DateTime.now().microsecond % 900 + 100)} ${(DateTime.now().second % 9000 + 1000)}';
        updateData['estimated_delivery_time'] =
            now.add(const Duration(minutes: 30)).toIso8601String();
      }

      await SupabaseService.update(
        'orders',
        updateData,
        filters: {'id': orderId},
      );
    } catch (e) {
      debugPrint('Error updating order status: $e');
    }
  }

  Future<void> cancelOrder(String orderId) async {
    await updateOrderStatus(orderId, OrderStatus.cancelled);
  }

  Future<void> updateOrderPaymentStatus(
    String orderId,
    PaymentStatus paymentStatus,
  ) async {
    try {
      final now = DateTime.now();
      final updateData = <String, dynamic>{
        'payment_status': paymentStatus.name,
        'updated_at': now.toIso8601String(),
      };

      await SupabaseService.update(
        'orders',
        updateData,
        filters: {'id': orderId},
      );
    } catch (e) {
      debugPrint('Error updating order payment status: $e');
    }
  }

  Future<void> _autoCancelStalePendingOrders(List<Order> orders) async {
    final cutoff = DateTime.now().subtract(const Duration(hours: 24));

    for (final order in orders) {
      if (order.status == OrderStatus.pending &&
          order.createdAt.isBefore(cutoff)) {
        await updateOrderStatus(order.id, OrderStatus.cancelled);
      }
    }
  }

  bool _isPendingOlderThan24Hours(Order order) {
    if (order.status != OrderStatus.pending) return false;
    final cutoff = DateTime.now().subtract(const Duration(hours: 24));
    return order.createdAt.isBefore(cutoff);
  }

  String _getStatusMessage(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'Order placed successfully';
      case OrderStatus.confirmed:
        return 'Order confirmed and being prepared';
      case OrderStatus.preparing:
        return 'Your order is being prepared';
      case OrderStatus.outForDelivery:
        return 'Your order is on the way';
      case OrderStatus.delivered:
        return 'Order delivered successfully';
      case OrderStatus.cancelled:
        return 'Order cancelled';
    }
  }
}
