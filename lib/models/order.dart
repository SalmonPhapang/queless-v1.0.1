import 'package:flutter/foundation.dart';
import 'package:queless/models/product.dart';
import 'package:queless/models/user.dart';

enum OrderStatus {
  pending,
  confirmed,
  preparing,
  outForDelivery,
  delivered,
  cancelled;

  String get displayName {
    switch (this) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.preparing:
        return 'Preparing';
      case OrderStatus.outForDelivery:
        return 'Out for Delivery';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }
}

enum PaymentStatus {
  pending,
  completed,
  failed,
  refunded;

  String get displayName {
    switch (this) {
      case PaymentStatus.pending:
        return 'Pending';
      case PaymentStatus.completed:
        return 'Completed';
      case PaymentStatus.failed:
        return 'Failed';
      case PaymentStatus.refunded:
        return 'Refunded';
    }
  }
}

class OrderItem {
  final String productId;
  final String productName;
  final String productImageUrl;
  final int quantity;
  final double pricePerUnit;
  final double totalPrice;

  OrderItem({
    required this.productId,
    required this.productName,
    required this.productImageUrl,
    required this.quantity,
    required this.pricePerUnit,
    required this.totalPrice,
  });

  Map<String, dynamic> toJson() => {
        'product_id': productId,
        'product_name': productName,
        'product_image_url': productImageUrl,
        'quantity': quantity,
        'price_per_unit': pricePerUnit,
        'total_price': totalPrice,
      };

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
        productId: json['product_id']?.toString() ?? '',
        productName: json['product_name']?.toString() ?? 'Unknown Product',
        productImageUrl: json['product_image_url']?.toString() ?? '',
        quantity: (json['quantity'] as num?)?.toInt() ?? 0,
        pricePerUnit: (json['price_per_unit'] as num?)?.toDouble() ?? 0.0,
        totalPrice: (json['total_price'] as num?)?.toDouble() ?? 0.0,
      );

  factory OrderItem.fromProduct(Product product, int quantity) => OrderItem(
        productId: product.id,
        productName: product.name,
        productImageUrl: product.imageUrl,
        quantity: quantity,
        pricePerUnit: product.price,
        totalPrice: product.price * quantity,
      );
}

class TrackingUpdate {
  final String status;
  final String message;
  final DateTime timestamp;

  TrackingUpdate({
    required this.status,
    required this.message,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'status': status,
        'message': message,
        'timestamp': timestamp.toIso8601String(),
      };

  factory TrackingUpdate.fromJson(Map<String, dynamic> json) => TrackingUpdate(
        status: json['status'] as String,
        message: json['message'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
      );
}

class DriverInfo {
  final String name;
  final String phone;
  final Map<String, dynamic>? location;

  DriverInfo({
    required this.name,
    required this.phone,
    this.location,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'phone': phone,
        'location': location,
      };

  factory DriverInfo.fromJson(Map<String, dynamic> json) => DriverInfo(
        name: json['name'] as String,
        phone: json['phone'] as String,
        location: json['location'] as Map<String, dynamic>?,
      );
}

class Order {
  final String id;
  final String orderNumber;
  final String userId;
  final List<OrderItem> items;
  final double subtotal;
  final double deliveryFee;
  final double discount;
  final double total;
  final OrderStatus status;
  final Address deliveryAddress;
  final String paymentMethod;
  final PaymentStatus paymentStatus;
  final DateTime? scheduledDelivery;
  final List<TrackingUpdate> trackingUpdates;
  final String? driverName;
  final String? driverPhone;
  final Map<String, dynamic>? driverLocation;
  final DateTime? estimatedDeliveryTime;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? storeId;
  final String? promoCodeId;
  final String type; // 'Liquor' or 'Food'

  String get orderType => type;

  Order({
    required this.id,
    required this.orderNumber,
    required this.userId,
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    required this.discount,
    required this.total,
    required this.status,
    required this.deliveryAddress,
    required this.paymentMethod,
    required this.paymentStatus,
    this.scheduledDelivery,
    required this.trackingUpdates,
    this.driverName,
    this.driverPhone,
    this.driverLocation,
    this.estimatedDeliveryTime,
    required this.createdAt,
    required this.updatedAt,
    this.storeId,
    this.promoCodeId,
    required this.type,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'order_number': orderNumber,
        'user_id': userId,
        'items': items.map((i) => i.toJson()).toList(),
        'subtotal': subtotal,
        'delivery_fee': deliveryFee,
        'discount': discount,
        'total': total,
        'status': status.name,
        'delivery_address': deliveryAddress.toJson(),
        'payment_method': paymentMethod,
        'payment_status': paymentStatus.name,
        'scheduled_delivery': scheduledDelivery?.toIso8601String(),
        'tracking_updates': trackingUpdates.map((t) => t.toJson()).toList(),
        'driver_name': driverName,
        'driver_phone': driverPhone,
        'driver_location': driverLocation,
        'estimated_delivery_time': estimatedDeliveryTime?.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'store_id': storeId,
        'promo_code_id': promoCodeId,
        'type': type,
      };

  factory Order.fromJson(Map<String, dynamic> json) {
    try {
      return Order(
        id: json['id']?.toString() ?? '',
        orderNumber: json['order_number']?.toString() ?? '',
        userId: json['user_id']?.toString() ?? '',
        items: (json['items'] as List?)
                ?.map((i) => OrderItem.fromJson(i as Map<String, dynamic>))
                .toList() ??
            [],
        subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
        deliveryFee: (json['delivery_fee'] as num?)?.toDouble() ?? 0.0,
        discount: (json['discount'] as num?)?.toDouble() ?? 0.0,
        total: (json['total'] as num?)?.toDouble() ?? 0.0,
        status: OrderStatus.values.firstWhere(
          (e) =>
              e.name.toLowerCase() == json['status']?.toString().toLowerCase(),
          orElse: () => OrderStatus.pending,
        ),
        deliveryAddress: Address.fromJson(
            (json['delivery_address'] as Map<String, dynamic>?) ?? {}),
        paymentMethod: json['payment_method']?.toString() ?? 'Unknown',
        paymentStatus: PaymentStatus.values.firstWhere(
          (e) =>
              e.name.toLowerCase() ==
              json['payment_status']?.toString().toLowerCase(),
          orElse: () => PaymentStatus.pending,
        ),
        scheduledDelivery: json['scheduled_delivery'] != null
            ? DateTime.tryParse(json['scheduled_delivery'].toString())
            : null,
        trackingUpdates: (json['tracking_updates'] as List?)
                ?.map((t) => TrackingUpdate.fromJson(t as Map<String, dynamic>))
                .toList() ??
            [],
        driverName: json['driver_name']?.toString(),
        driverPhone: json['driver_phone']?.toString(),
        driverLocation: json['driver_location'] as Map<String, dynamic>?,
        estimatedDeliveryTime: json['estimated_delivery_time'] != null
            ? DateTime.tryParse(json['estimated_delivery_time'].toString())
            : null,
        createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
            DateTime.now(),
        updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? '') ??
            DateTime.now(),
        storeId: json['store_id']?.toString(),
        promoCodeId: json['promo_code_id']?.toString(),
        type: json['type']?.toString() ??
            (json['store_id'] != null ? 'Liquor' : 'Food'),
      );
    } catch (e) {
      debugPrint('Error parsing Order from JSON: $e');
      rethrow;
    }
  }

  Order copyWith({
    String? id,
    String? orderNumber,
    String? userId,
    List<OrderItem>? items,
    double? subtotal,
    double? deliveryFee,
    double? discount,
    double? total,
    OrderStatus? status,
    Address? deliveryAddress,
    String? paymentMethod,
    PaymentStatus? paymentStatus,
    DateTime? scheduledDelivery,
    List<TrackingUpdate>? trackingUpdates,
    String? driverName,
    String? driverPhone,
    Map<String, dynamic>? driverLocation,
    DateTime? estimatedDeliveryTime,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? storeId,
    String? promoCodeId,
    String? type,
  }) =>
      Order(
        id: id ?? this.id,
        orderNumber: orderNumber ?? this.orderNumber,
        userId: userId ?? this.userId,
        items: items ?? this.items,
        subtotal: subtotal ?? this.subtotal,
        deliveryFee: deliveryFee ?? this.deliveryFee,
        discount: discount ?? this.discount,
        total: total ?? this.total,
        status: status ?? this.status,
        deliveryAddress: deliveryAddress ?? this.deliveryAddress,
        paymentMethod: paymentMethod ?? this.paymentMethod,
        paymentStatus: paymentStatus ?? this.paymentStatus,
        scheduledDelivery: scheduledDelivery ?? this.scheduledDelivery,
        trackingUpdates: trackingUpdates ?? this.trackingUpdates,
        driverName: driverName ?? this.driverName,
        driverPhone: driverPhone ?? this.driverPhone,
        driverLocation: driverLocation ?? this.driverLocation,
        estimatedDeliveryTime:
            estimatedDeliveryTime ?? this.estimatedDeliveryTime,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        storeId: storeId ?? this.storeId,
        promoCodeId: promoCodeId ?? this.promoCodeId,
        type: type ?? this.type,
      );

  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);
}
