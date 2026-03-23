import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:queless/models/cart.dart';
import 'package:queless/models/product.dart';
import 'package:queless/models/store.dart';

import 'package:queless/models/promo_code.dart';
import 'package:queless/services/promo_code_service.dart';

class CartService extends ChangeNotifier {
  static const String _cartKey = 'cart_data_multi';
  static const double _fixedDeliveryFee = 25.0;
  static const double _alcoholMinimumOrder = 100.0;

  static final CartService _instance = CartService._internal();
  factory CartService() => _instance;
  CartService._internal();

  final _promoCodeService = PromoCodeService();
  Map<String, Cart> _carts = {};
  bool _isInitialized = false;
  Map<String, PromoCode?> _appliedPromos = {};

  Map<String, Cart> get carts => _carts;
  int get totalItemCount =>
      _carts.values.fold(0, (sum, cart) => sum + cart.totalItems);

  int get itemCount => totalItemCount;

  double getSubtotal(String storeId) => _carts[storeId]?.subtotal ?? 0.0;

  double getDeliveryFee(String storeId) {
    final promo = _appliedPromos[storeId];
    final hasFreeDelivery = promo?.discountType == DiscountType.freeDelivery;
    return hasFreeDelivery ? 0.0 : _fixedDeliveryFee;
  }

  double get minimumOrderLimit => _alcoholMinimumOrder;

  bool isMinimumOrderMet(String storeId) =>
      getSubtotal(storeId) >= _alcoholMinimumOrder;

  bool get isInitialized => _isInitialized;

  PromoCode? getAppliedPromo(String storeId) => _appliedPromos[storeId];

  Future<String?> applyPromoCode(String storeId, String code) async {
    debugPrint(
        '🎟️  Attempting to apply promo: $code to liquor cart for store $storeId');
    final promo = await _promoCodeService.getPromoCode(code);
    if (promo == null) {
      debugPrint('❌ Promo $code not found');
      return 'Invalid promo code';
    }

    final error = await _promoCodeService.validatePromoCode(
      promo: promo,
      subtotal: getSubtotal(storeId),
      orderType: 'Liquor',
      storeId: storeId,
    );

    if (error != null) {
      debugPrint('❌ Promo $code validation failed: $error');
      return error;
    }

    debugPrint('✅ Promo $code applied successfully for store $storeId');
    _appliedPromos[storeId] = promo;
    notifyListeners();
    return null; // Success
  }

  void removePromoCode(String storeId) {
    _appliedPromos.remove(storeId);
    notifyListeners();
  }

  double calculateDiscount(String storeId) {
    final promo = _appliedPromos[storeId];
    if (promo == null) return 0.0;

    final subtotal = getSubtotal(storeId);
    if (promo.discountType == DiscountType.percentage) {
      return subtotal * (promo.discountValue / 100);
    } else if (promo.discountType == DiscountType.fixed) {
      return promo.discountValue;
    }
    return 0.0;
  }

  double calculateTotal(String storeId) {
    return getSubtotal(storeId) +
        getDeliveryFee(storeId) -
        calculateDiscount(storeId);
  }

  Future<void> init() async {
    await _loadCarts();
    _isInitialized = true;
    debugPrint('🛒 CartService initialized with ${_carts.length} carts');
  }

  Future<void> _loadCarts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartsJson = prefs.getString(_cartKey);

      if (cartsJson != null && cartsJson.isNotEmpty) {
        try {
          final Map<String, dynamic> decoded = jsonDecode(cartsJson);
          _carts =
              decoded.map((key, value) => MapEntry(key, Cart.fromJson(value)));
          debugPrint(
              '✅ Carts loaded from local storage: ${_carts.length} carts');
        } catch (e) {
          debugPrint('⚠️ Error parsing multi-cart JSON: $e');
          _carts = {};
        }
      } else {
        _carts = {};
      }
    } catch (e) {
      debugPrint('❌ Error loading multi-carts: $e');
      _carts = {};
    }
  }

  Future<void> addItem(Product product, {int quantity = 1}) async {
    final storeId = product.storeId ?? '';
    debugPrint(
        '🛒 Adding ${product.name} x$quantity to cart for store $storeId');

    Cart? cart = _carts[storeId];
    if (cart == null) {
      cart = Cart(
        userId: 'local',
        storeId: storeId,
        items: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }

    final items = List<CartItem>.from(cart.items);
    final existingIndex =
        items.indexWhere((item) => item.productId == product.id);

    if (existingIndex != -1) {
      items[existingIndex].quantity += quantity;
    } else {
      items.add(CartItem.fromProduct(product, quantity: quantity));
    }

    _carts[storeId] = cart.copyWith(
      items: items,
      updatedAt: DateTime.now(),
    );

    await _revalidatePromo(storeId);
    await _saveCarts();
    notifyListeners();
  }

  Future<void> removeItem(String storeId, String productId) async {
    debugPrint('🛒 Removing item $productId from cart for store $storeId');
    final cart = _carts[storeId];
    if (cart == null) return;

    final items =
        cart.items.where((item) => item.productId != productId).toList();

    if (items.isEmpty) {
      _carts.remove(storeId);
      _appliedPromos.remove(storeId);
    } else {
      _carts[storeId] = cart.copyWith(items: items, updatedAt: DateTime.now());
      await _revalidatePromo(storeId);
    }

    await _saveCarts();
    notifyListeners();
  }

  Future<void> updateQuantity(
      String storeId, String productId, int quantity) async {
    debugPrint(
        '🛒 Updating quantity for item $productId to $quantity for store $storeId');
    final cart = _carts[storeId];
    if (cart == null) return;

    final items = List<CartItem>.from(cart.items);
    final index = items.indexWhere((item) => item.productId == productId);

    if (index != -1) {
      if (quantity <= 0) {
        items.removeAt(index);
      } else {
        items[index].quantity = quantity;
      }
    }

    if (items.isEmpty) {
      _carts.remove(storeId);
      _appliedPromos.remove(storeId);
    } else {
      _carts[storeId] = cart.copyWith(items: items, updatedAt: DateTime.now());
      await _revalidatePromo(storeId);
    }

    await _saveCarts();
    notifyListeners();
  }

  Future<void> clear(String storeId) async {
    debugPrint('🛒 Clearing cart for store $storeId');
    _carts.remove(storeId);
    _appliedPromos.remove(storeId);
    await _saveCarts();
    notifyListeners();
  }

  Future<void> clearCart() async {
    debugPrint('🛒 Clearing all carts');
    _carts.clear();
    _appliedPromos.clear();
    await _saveCarts();
    notifyListeners();
  }

  Future<void> _revalidatePromo(String storeId) async {
    final promo = _appliedPromos[storeId];
    if (promo == null) return;

    final error = await _promoCodeService.validatePromoCode(
      promo: promo,
      subtotal: getSubtotal(storeId),
      orderType: 'Liquor',
      storeId: storeId,
    );

    if (error != null) {
      debugPrint('⚠️ Promo code $promo removed from store $storeId: $error');
      _appliedPromos.remove(storeId);
    }
  }

  Future<void> _saveCarts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartsJson =
          jsonEncode(_carts.map((key, value) => MapEntry(key, value.toJson())));
      await prefs.setString(_cartKey, cartsJson);
    } catch (e) {
      debugPrint('❌ Error saving multi-carts: $e');
    }
  }
}
