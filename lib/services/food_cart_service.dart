import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:queless/models/cart.dart';
import 'package:queless/models/product.dart';

class FoodCartService extends ChangeNotifier {
  static const String _cartKey = 'food_cart_data';
  static const double _deliveryFee = 35.0;
  static final FoodCartService _instance = FoodCartService._internal();
  factory FoodCartService() => _instance;
  FoodCartService._internal();

  Cart? _currentCart;
  String? _currentStoreId;
  bool _isInitialized = false;

  Cart? get currentCart => _currentCart;
  String? get currentStoreId => _currentStoreId;
  int get itemCount => _currentCart?.totalItems ?? 0;
  double get subtotal => _currentCart?.subtotal ?? 0.0;
  double get deliveryFee => _deliveryFee;
  bool get isInitialized => _isInitialized;

  Future<void> init() async {
    await _loadCart();
    _isInitialized = true;
    debugPrint('🍔 FoodCartService initialized with $itemCount items');
  }

  Future<void> _loadCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartJson = prefs.getString(_cartKey);

      if (cartJson != null && cartJson.isNotEmpty) {
        try {
          final cartData = jsonDecode(cartJson) as Map<String, dynamic>;
          _currentCart = Cart.fromJson(cartData);
          _currentStoreId = prefs.getString('${_cartKey}_store_id');
          debugPrint('✅ Food cart loaded: ${_currentCart!.items.length} items from store $_currentStoreId');
        } catch (e) {
          debugPrint('⚠️  Error parsing food cart JSON: $e');
          _createNewCart();
          await _saveCart();
        }
      } else {
        _createNewCart();
        debugPrint('📦 New empty food cart created');
      }
    } catch (e) {
      debugPrint('❌ Error loading food cart: $e');
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
    _currentStoreId = null;
  }

  Future<bool> canAddProduct(Product product) async {
    // First item or empty cart - always allow
    if (_currentCart == null || _currentCart!.items.isEmpty) {
      return true;
    }

    // Check if product is from the same store
    if (_currentStoreId == null || _currentStoreId == product.storeId) {
      return true;
    }

    // Different store - need confirmation
    return false;
  }

  Future<void> addItem(Product product, {int quantity = 1, bool clearFirst = false}) async {
    debugPrint('🍔 Adding ${product.name} x$quantity to food cart');

    if (_currentCart == null) {
      _createNewCart();
    }

    // Clear cart if switching stores
    if (clearFirst || (_currentStoreId != null && _currentStoreId != product.storeId)) {
      await clear();
      _createNewCart();
    }

    // Set the current store
    _currentStoreId = product.storeId;

    final items = List<CartItem>.from(_currentCart!.items);
    final existingIndex = items.indexWhere((item) => item.productId == product.id);

    if (existingIndex != -1) {
      items[existingIndex].quantity += quantity;
      debugPrint('📈 Updated quantity: ${items[existingIndex].quantity}');
    } else {
      items.add(CartItem.fromProduct(product, quantity: quantity));
      debugPrint('➕ Added new item to food cart');
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

    // Clear store ID if cart is now empty
    if (items.isEmpty) {
      _currentStoreId = null;
    }

    _currentCart = _currentCart!.copyWith(
      items: items,
      updatedAt: DateTime.now(),
    );

    await _saveCart();
    notifyListeners();
    debugPrint('🗑️  Item removed from food cart');
  }

  Future<void> updateQuantity(String productId, int quantity) async {
    if (_currentCart == null) return;

    final items = List<CartItem>.from(_currentCart!.items);
    final index = items.indexWhere((item) => item.productId == productId);

    if (index != -1) {
      if (quantity <= 0) {
        items.removeAt(index);
        // Clear store ID if cart is now empty
        if (items.isEmpty) {
          _currentStoreId = null;
        }
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
    debugPrint('🔄 Food cart quantity updated');
  }

  Future<void> applyPromoCode(String code) async {
    if (_currentCart == null) return;

    _currentCart = _currentCart!.copyWith(
      promoCode: code,
      updatedAt: DateTime.now(),
    );

    await _saveCart();
    notifyListeners();
    debugPrint('🎟️  Promo code applied to food cart: $code');
  }

  Future<void> removePromoCode() async {
    if (_currentCart == null) return;

    _currentCart = _currentCart!.copyWith(
      promoCode: null,
      updatedAt: DateTime.now(),
    );

    await _saveCart();
    notifyListeners();
    debugPrint('🎟️  Promo code removed from food cart');
  }

  double calculateDiscount() {
    if (_currentCart?.promoCode == null) return 0.0;

    switch (_currentCart!.promoCode!.toUpperCase()) {
      case 'FOOD10':
        return subtotal * 0.10;
      case 'MEAL15':
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
    debugPrint('🧹 Clearing food cart');
    
    final now = DateTime.now();
    _currentCart = _currentCart!.copyWith(
      items: [],
      promoCode: null,
      updatedAt: now,
    );
    _currentStoreId = null;

    await _saveCart();
    notifyListeners();
    debugPrint('✅ Food cart cleared successfully');
  }

  Future<void> clearCart() => clear();

  Future<void> _saveCart() async {
    if (_currentCart == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final cartJson = jsonEncode(_currentCart!.toJson());
      await prefs.setString(_cartKey, cartJson);
      if (_currentStoreId != null) {
        await prefs.setString('${_cartKey}_store_id', _currentStoreId!);
      } else {
        await prefs.remove('${_cartKey}_store_id');
      }
      debugPrint('💾 Food cart saved: ${_currentCart!.items.length} items');
    } catch (e) {
      debugPrint('❌ Error saving food cart: $e');
    }
  }
}
