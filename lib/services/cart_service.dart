import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:queless/models/cart.dart';
import 'package:queless/models/product.dart';

class CartService extends ChangeNotifier {
  static const String _cartKey = 'cart_data';
  static const double _deliveryFee = 35.0;
  static final CartService _instance = CartService._internal();
  factory CartService() => _instance;
  CartService._internal();

  Cart? _currentCart;
  bool _isInitialized = false;

  Cart? get currentCart => _currentCart;
  int get itemCount => _currentCart?.totalItems ?? 0;
  double get subtotal => _currentCart?.subtotal ?? 0.0;
  double get deliveryFee => _deliveryFee;
  bool get isInitialized => _isInitialized;

  Future<void> init() async {
    await _loadCart();
    _isInitialized = true;
    debugPrint('🛒 CartService initialized with $itemCount items');
  }

  Future<void> _loadCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartJson = prefs.getString(_cartKey);

      if (cartJson != null && cartJson.isNotEmpty) {
        try {
          final cartData = jsonDecode(cartJson) as Map<String, dynamic>;
          _currentCart = Cart.fromJson(cartData);
          debugPrint('✅ Cart loaded from local storage: ${_currentCart!.items.length} items');
        } catch (e) {
          debugPrint('⚠️  Error parsing cart JSON: $e');
          debugPrint('Corrupted cart data, creating new cart');
          _createNewCart();
          await _saveCart();
        }
      } else {
        _createNewCart();
        debugPrint('📦 New empty cart created');
      }
    } catch (e) {
      debugPrint('❌ Error loading cart from SharedPreferences: $e');
      _createNewCart();
    } finally {
      _isInitialized = true;
    }
  }

  void _createNewCart() {
    final now = DateTime.now();
    _currentCart = Cart(
      userId: 'local',
      items: [],
      createdAt: now,
      updatedAt: now,
    );
  }

  Future<void> addItem(Product product, {int quantity = 1}) async {
    debugPrint('🛒 Adding ${product.name} x$quantity to cart');

    if (_currentCart == null) {
      _createNewCart();
    }

    final items = List<CartItem>.from(_currentCart!.items);
    final existingIndex = items.indexWhere((item) => item.productId == product.id);

    if (existingIndex != -1) {
      items[existingIndex].quantity += quantity;
      debugPrint('📈 Updated quantity: ${items[existingIndex].quantity}');
    } else {
      items.add(CartItem.fromProduct(product, quantity: quantity));
      debugPrint('➕ Added new item to cart');
    }

    _currentCart = _currentCart!.copyWith(
      items: items,
      updatedAt: DateTime.now(),
    );

    await _saveCart();
    notifyListeners();
  }

  Future<void> removeItem(String productId) async {
    if (_currentCart == null) return;

    final items = _currentCart!.items.where((item) => item.productId != productId).toList();

    _currentCart = _currentCart!.copyWith(
      items: items,
      updatedAt: DateTime.now(),
    );

    await _saveCart();
    notifyListeners();
    debugPrint('🗑️  Item removed from cart');
  }

  Future<void> updateQuantity(String productId, int quantity) async {
    if (_currentCart == null) return;

    final items = List<CartItem>.from(_currentCart!.items);
    final index = items.indexWhere((item) => item.productId == productId);

    if (index != -1) {
      if (quantity <= 0) {
        items.removeAt(index);
      } else {
        items[index].quantity = quantity;
      }
    }

    _currentCart = _currentCart!.copyWith(
      items: items,
      updatedAt: DateTime.now(),
    );

    await _saveCart();
    notifyListeners();
    debugPrint('🔄 Quantity updated');
  }

  Future<void> applyPromoCode(String code) async {
    if (_currentCart == null) return;

    _currentCart = _currentCart!.copyWith(
      promoCode: code,
      updatedAt: DateTime.now(),
    );

    await _saveCart();
    notifyListeners();
    debugPrint('🎟️  Promo code applied: $code');
  }

  Future<void> removePromoCode() async {
    if (_currentCart == null) return;

    _currentCart = _currentCart!.copyWith(
      promoCode: null,
      updatedAt: DateTime.now(),
    );

    await _saveCart();
    notifyListeners();
    debugPrint('🎟️  Promo code removed');
  }

  double calculateDiscount() {
    if (_currentCart?.promoCode == null) return 0.0;

    switch (_currentCart!.promoCode!.toUpperCase()) {
      case 'BRAAI10':
        return subtotal * 0.10;
      case 'RUGBY15':
        return subtotal * 0.15;
      case 'FIRST20':
        return subtotal * 0.20;
      default:
        return 0.0;
    }
  }

  double calculateTotal() {
    final discount = calculateDiscount();
    return subtotal + deliveryFee - discount;
  }

  Future<void> clear() async {
    debugPrint('🧹 Clearing cart');
    
    final now = DateTime.now();
    _currentCart = _currentCart!.copyWith(
      items: [],
      promoCode: null,
      updatedAt: now,
    );

    await _saveCart();
    notifyListeners();
    debugPrint('✅ Cart cleared successfully');
  }

  Future<void> clearCart() => clear();

  Future<void> _saveCart() async {
    if (_currentCart == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final cartJson = jsonEncode(_currentCart!.toJson());
      await prefs.setString(_cartKey, cartJson);
      debugPrint('💾 Cart saved to local storage: ${_currentCart!.items.length} items');
    } catch (e) {
      debugPrint('❌ Error saving cart: $e');
    }
  }
}
