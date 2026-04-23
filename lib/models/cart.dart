import 'package:queless/models/product.dart';

class CartItem {
  final String productId;
  final String productName;
  final String productImageUrl;
  final double price; // Markup price
  final double basePrice; // Original price
  int quantity;

  CartItem({
    required this.productId,
    required this.productName,
    required this.productImageUrl,
    required this.price,
    required this.basePrice,
    required this.quantity,
  });

  double get totalPrice => price * quantity;
  double get totalBasePrice => basePrice * quantity;

  Map<String, dynamic> toJson() => {
        'product_id': productId,
        'product_name': productName,
        'product_image_url': productImageUrl,
        'price': price,
        'base_price': basePrice,
        'quantity': quantity,
      };

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
        productId: json['product_id'] as String,
        productName: json['product_name'] as String,
        productImageUrl: json['product_image_url'] as String,
        price: (json['price'] as num).toDouble(),
        basePrice: (json['base_price'] as num?)?.toDouble() ??
            ((json['price'] as num).toDouble() / 1.2), // Fallback calculation
        quantity: json['quantity'] as int,
      );

  factory CartItem.fromProduct(Product product, {int quantity = 1}) => CartItem(
        productId: product.id,
        productName: product.name,
        productImageUrl: product.imageUrl,
        price: product.price,
        basePrice: product.basePrice,
        quantity: quantity,
      );
}

class Cart {
  final String userId;
  final String storeId;
  final List<CartItem> items;
  String? promoCode;
  final DateTime createdAt;
  final DateTime updatedAt;

  Cart({
    required this.userId,
    required this.storeId,
    required this.items,
    this.promoCode,
    required this.createdAt,
    required this.updatedAt,
  });

  double get subtotal => items.fold(0.0, (sum, item) => sum + item.totalPrice);
  double get baseSubtotal =>
      items.fold(0.0, (sum, item) => sum + item.totalBasePrice);
  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'store_id': storeId,
    'items': items.map((i) => i.toJson()).toList(),
    'promo_code': promoCode,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  factory Cart.fromJson(Map<String, dynamic> json) => Cart(
    userId: json['user_id'] as String,
    storeId: json['store_id'] as String? ?? '',
    items: (json['items'] as List).map((i) => CartItem.fromJson(i as Map<String, dynamic>)).toList(),
    promoCode: json['promo_code'] as String?,
    createdAt: DateTime.parse(json['created_at'] as String),
    updatedAt: DateTime.parse(json['updated_at'] as String),
  );

  Cart copyWith({
    String? userId,
    String? storeId,
    List<CartItem>? items,
    String? promoCode,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Cart(
    userId: userId ?? this.userId,
    storeId: storeId ?? this.storeId,
    items: items ?? this.items,
    promoCode: promoCode ?? this.promoCode,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
