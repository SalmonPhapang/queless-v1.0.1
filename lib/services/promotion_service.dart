import 'package:flutter/foundation.dart';
import 'package:queless/models/promotion.dart';
import 'package:queless/supabase/supabase_config.dart';
import 'package:queless/services/cache_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PromotionService extends ChangeNotifier {
  static final PromotionService _instance = PromotionService._internal();
  factory PromotionService() => _instance;
  PromotionService._internal();

  final _cache = CacheService();
  List<Promotion> _activePromotions = [];
  bool _isLoading = false;

  List<Promotion> get activePromotions => List.unmodifiable(_activePromotions);
  Promotion? get featuredPromotion {
    if (_activePromotions.isEmpty) return null;

    final storePromos = _activePromotions
        .where((p) => p.targetType == PromotionTargetType.store)
        .toList();

    if (storePromos.isNotEmpty) {
      return storePromos.first;
    }

    return _activePromotions.first;
  }

  bool get isLoading => _isLoading;

  Future<void> refreshActivePromotions() async {
    if (_isLoading) return;
    _isLoading = true;

    // Defer notification to avoid "setState() called during build" errors
    // if this is called from initState or build methods.
    Future.microtask(() => notifyListeners());

    const cacheKey = 'active_promotions';

    try {
      final rows = await SupabaseService.select(
        'promotions',
        filters: {'is_active': true},
        orderBy: 'priority',
        ascending: false,
        limit: 50,
      );

      _activePromotions = rows
          .map((row) => Promotion.fromJson(row))
          .where((p) => p.id.isNotEmpty && p.isCurrentlyActive)
          .toList();

      await _cache.set(cacheKey, _activePromotions);
    } catch (_) {
      final cachedDynamic = _cache.get<dynamic>(cacheKey);
      if (cachedDynamic != null && cachedDynamic is List) {
        _activePromotions =
            cachedDynamic.map((json) => Promotion.fromJson(json)).toList();
      } else {
        _activePromotions = [];
      }
    } finally {
      _isLoading = false;
      // Defer notification to avoid "setState() called during build" errors
      Future.microtask(() => notifyListeners());
    }
  }

  bool isProductPromoted(String productId) {
    return _activePromotions.any(
      (p) =>
          p.targetType == PromotionTargetType.product &&
          p.targetIds.contains(productId),
    );
  }

  bool isStorePromoted(String storeId) {
    return _activePromotions.any(
      (p) => p.targetType == PromotionTargetType.store && p.targetId == storeId,
    );
  }

  Promotion? promotionForProduct(String productId) {
    for (final promo in _activePromotions) {
      if (promo.targetType == PromotionTargetType.product &&
          promo.targetIds.contains(productId)) {
        return promo;
      }
    }
    return null;
  }

  Promotion? promotionForStore(String storeId) {
    for (final promo in _activePromotions) {
      if (promo.targetType == PromotionTargetType.store &&
          promo.targetId == storeId) {
        return promo;
      }
    }
    return null;
  }

  Future<bool> shouldShowPromotionModal() async {
    final promo = featuredPromotion;
    if (promo == null) return false;

    final prefs = await SharedPreferences.getInstance();
    final key = 'promo_shown_${promo.id}';
    return !(prefs.getBool(key) ?? false);
  }

  Future<void> markPromotionModalShown() async {
    final promo = featuredPromotion;
    if (promo == null) return;

    final prefs = await SharedPreferences.getInstance();
    final key = 'promo_shown_${promo.id}';
    await prefs.setBool(key, true);
  }
}
