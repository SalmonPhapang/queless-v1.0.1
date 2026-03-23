import 'package:flutter/foundation.dart';
import 'package:queless/models/promo_code.dart';
import 'package:queless/supabase/supabase_config.dart';
import 'package:queless/services/auth_service.dart';

class PromoCodeService {
  static final PromoCodeService _instance = PromoCodeService._internal();
  factory PromoCodeService() => _instance;
  PromoCodeService._internal();

  final _authService = AuthService();

  Future<PromoCode?> getPromoCode(String code) async {
    try {
      debugPrint('🔍 Fetching promo code: ${code.toUpperCase()}');
      final data = await SupabaseService.selectSingle(
        'promo_codes',
        filters: {'code': code.toUpperCase(), 'is_active': true},
      );

      if (data == null) {
        debugPrint('❌ Promo code not found in DB');
        return null;
      }
      debugPrint(
          '✅ Promo code found: ${data['code']} - Type: ${data['discount_type']}');
      return PromoCode.fromJson(data);
    } catch (e) {
      debugPrint('❌ Error fetching promo code: $e');
      return null;
    }
  }

  Future<String?> validatePromoCode({
    required PromoCode promo,
    required double subtotal,
    required String orderType, // 'Liquor' or 'Food'
    required String? storeId,
  }) async {
    debugPrint('🧪 Validating promo: ${promo.code} for $orderType order');
    final user = _authService.currentUser;
    if (user == null) return 'Please log in to use promo codes';

    final now = DateTime.now();

    // 1. Check Dates
    if (promo.startDate.isAfter(now)) {
      debugPrint('❌ Promo not yet active');
      return 'This promo code is not active yet';
    }
    if (promo.endDate != null && promo.endDate!.isBefore(now)) {
      debugPrint('❌ Promo expired');
      return 'This promo code has expired';
    }

    // 2. Check Min Order Amount
    if (subtotal < promo.minOrderAmount) {
      debugPrint('❌ Subtotal R$subtotal < Min R${promo.minOrderAmount}');
      return 'Minimum order amount for this code is R${promo.minOrderAmount.toStringAsFixed(2)}';
    }

    // 3. Check Total Usage Limit
    if (promo.usageLimitTotal != null &&
        promo.currentUsageTotal >= promo.usageLimitTotal!) {
      debugPrint('❌ Total usage limit reached');
      return 'This promo code has reached its usage limit';
    }

    // 4. Check Order Type
    if (promo.applicableOrderTypes != null &&
        !promo.applicableOrderTypes!.contains(orderType)) {
      debugPrint(
          '❌ Invalid order type: $orderType. Expected: ${promo.applicableOrderTypes}');
      return 'This promo is only available for ${promo.applicableOrderTypes!.join(' or ')} orders';
    }

    // 5. Check Store ID
    if (promo.applicableStoreIds != null &&
        (storeId == null || !promo.applicableStoreIds!.contains(storeId))) {
      debugPrint('❌ Invalid store ID: $storeId');
      return 'This promo is not available for the selected store';
    }

    // 6. Check First Order Only
    if (promo.isFirstOrderOnly) {
      final orders = await SupabaseService.select(
        'orders',
        filters: {'user_id': user.id},
        limit: 1,
      );
      if (orders.isNotEmpty) {
        debugPrint('❌ Not first order');
        return 'This promo is only available for your first order';
      }
    }

    // 7. Check Usage Per User
    final userUsage = await SupabaseService.select(
      'orders',
      filters: {'user_id': user.id, 'promo_code_id': promo.id},
    );
    if (userUsage.length >= promo.usageLimitPerUser) {
      debugPrint('❌ User usage limit reached');
      return 'You have already used this promo code the maximum number of times';
    }

    debugPrint('✅ Promo code is valid');
    return null; // Valid
  }

  Future<void> incrementUsage(String promoId) async {
    try {
      final promo = await SupabaseService.selectSingle(
        'promo_codes',
        filters: {'id': promoId},
      );
      if (promo == null) return;

      final currentUsage = (promo['current_usage_total'] as int?) ?? 0;

      await SupabaseConfig.client.from('promo_codes').update({
        'current_usage_total': currentUsage + 1,
      }).eq('id', promoId);
    } catch (e) {
      debugPrint('Error incrementing promo usage: $e');
    }
  }
}
