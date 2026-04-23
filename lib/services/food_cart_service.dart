import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:queless/models/cart.dart';
import 'package:queless/models/product.dart';

import 'package:queless/models/promo_code.dart';
import 'package:queless/services/promo_code_service.dart';

class FoodCartService extends ChangeNotifier {
  static const String _cartKey = 'food_cart_data_multi';
  static const double _baseDeliveryFee = 25.0;
  static const double _extendedDeliveryFee = 45.0;
  static const double _foodMinimumOrder = 65.0;

  static final FoodCartService _instance = FoodCartService._internal();
  factory FoodCartService() => _instance;
  FoodCartService._internal();

  final _promoCodeService = PromoCodeService();
  Map<String, Cart> _carts = {};
  bool _isInitialized = false;
  Map<String, PromoCode?> _appliedPromos = {};
  Map<String, double> _storeDistances = {};

  Map<String, Cart> get carts => _carts;
  int get totalItemCount =>
      _carts.values.fold(0, (sum, cart) => sum + cart.totalItems);

  int get itemCount => totalItemCount;

  double getSubtotal(String storeId) => _carts[storeId]?.subtotal ?? 0.0;
  double get baseSubtotal {
    double total = 0.0;
    for (var cart in _carts.values) {
      total += cart.baseSubtotal;
    }
    return total;
  }

  double getBaseSubtotal(String storeId) => _carts[storeId]?.baseSubtotal ?? 0.0;

  double getDeliveryFee(String storeId) {
    final promo = _appliedPromos[storeId];
    final hasFreeDelivery = promo?.discountType == DiscountType.freeDelivery;
    if (hasFreeDelivery) return 0.0;

    final distance = _storeDistances[storeId] ?? 0.0;
    return distance > 5000 ? _extendedDeliveryFee : _baseDeliveryFee;
  }

  void updateStoreDistance(String storeId, double distanceMeters) {
    _storeDistances[storeId] = distanceMeters;
    notifyListeners();
  }

  double get minimumOrderLimit => _foodMinimumOrder;

  bool isMinimumOrderMet(String storeId) =>
      getSubtotal(storeId) >= _foodMinimumOrder;

  bool get isInitialized => _isInitialized;

  PromoCode? getAppliedPromo(String storeId) => _appliedPromos[storeId];

  Future<void> init() async {
    await _loadCarts();
    _isInitialized = true;
    debugPrint('🛒 FoodCartService initialized with ${_carts.length} carts');
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
              '✅ Food carts loaded from local storage: ${_carts.length} carts');
        } catch (e) {
          debugPrint('⚠️ Error parsing multi-food-cart JSON: $e');
          _carts = {};
        }
      } else {
        _carts = {};
      }
    } catch (e) {
      debugPrint('❌ Error loading multi-food-carts: $e');
      _carts = {};
    }
  }

  Future<void> addItem(Product product, {int quantity = 1}) async {
    final storeId = product.storeId ?? '';
    debugPrint(
        '🛒 Adding ${product.name} x$quantity to food cart for store $storeId');

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
    _carts.remove(storeId);
    _appliedPromos.remove(storeId);
    await _saveCarts();
    notifyListeners();
  }

  Future<void> clearCart() async {
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
      orderType: 'Food',
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
      debugPrint('❌ Error saving multi-food-carts: $e');
    }
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

  Future<String?> applyPromoCode(String storeId, String code) async {
    debugPrint(
        '🎟️ Attempting to apply promo: $code to food cart for store $storeId');
    final promo = await _promoCodeService.getPromoCode(code);
    if (promo == null) {
      debugPrint('❌ Promo $code not found');
      return 'Invalid promo code';
    }

    final error = await _promoCodeService.validatePromoCode(
      promo: promo,
      subtotal: getSubtotal(storeId),
      orderType: 'Food',
      storeId: storeId,
    );

    if (error != null) {
      debugPrint('❌ Promo $code validation failed: $error');
      return error;
    }

    debugPrint('✅ Promo $code applied successfully for store $storeId');
    _appliedPromos[storeId] = promo;
    notifyListeners();
    return null;
  }

  void removePromoCode(String storeId) {
    _appliedPromos.remove(storeId);
    notifyListeners();
  }
}
