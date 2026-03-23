enum DiscountType {
  percentage,
  fixed,
  freeDelivery;

  static DiscountType fromString(String value) {
    return DiscountType.values.firstWhere(
      (e) =>
          e.name == value || e.name == value.toLowerCase().replaceAll('_', ''),
      orElse: () => DiscountType.fixed,
    );
  }
}

class PromoCode {
  final String id;
  final String code;
  final String description;
  final DiscountType discountType;
  final double discountValue;
  final double minOrderAmount;
  final double? maxDiscountAmount;
  final bool isFirstOrderOnly;
  final List<String>? applicableStoreIds;
  final List<String>? applicableOrderTypes;
  final int? usageLimitTotal;
  final int usageLimitPerUser;
  final int currentUsageTotal;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isActive;

  PromoCode({
    required this.id,
    required this.code,
    required this.description,
    required this.discountType,
    required this.discountValue,
    required this.minOrderAmount,
    this.maxDiscountAmount,
    this.isFirstOrderOnly = false,
    this.applicableStoreIds,
    this.applicableOrderTypes,
    this.usageLimitTotal,
    this.usageLimitPerUser = 1,
    this.currentUsageTotal = 0,
    required this.startDate,
    this.endDate,
    this.isActive = true,
  });

  factory PromoCode.fromJson(Map<String, dynamic> json) {
    final discountTypeStr = json['discount_type'] as String;
    return PromoCode(
      id: json['id'] as String,
      code: json['code'] as String,
      description: json['description'] ?? '',
      discountType: DiscountType.values.firstWhere(
        (e) =>
            e.name == _toCamelCase(discountTypeStr) ||
            e.name.toLowerCase() ==
                discountTypeStr.toLowerCase().replaceAll('_', ''),
        orElse: () => DiscountType.fixed,
      ),
      discountValue: (json['discount_value'] as num?)?.toDouble() ?? 0.0,
      minOrderAmount: (json['min_order_amount'] as num?)?.toDouble() ?? 0.0,
      maxDiscountAmount: (json['max_discount_amount'] as num?)?.toDouble(),
      isFirstOrderOnly: json['is_first_order_only'] ?? false,
      applicableStoreIds: (json['applicable_store_ids'] as List?)
          ?.map((e) => e as String)
          .toList(),
      applicableOrderTypes: (json['applicable_order_types'] as List?)
          ?.map((e) => e as String)
          .toList(),
      usageLimitTotal: json['usage_limit_total'] as int?,
      usageLimitPerUser: json['usage_limit_per_user'] ?? 1,
      currentUsageTotal: json['current_usage_total'] ?? 0,
      startDate: DateTime.parse(json['start_date']),
      endDate:
          json['end_date'] != null ? DateTime.parse(json['end_date']) : null,
      isActive: json['is_active'] ?? true,
    );
  }

  static String _toCamelCase(String snake) {
    final parts = snake.split('_');
    if (parts.length == 1) return parts[0];
    return parts[0] +
        parts.skip(1).map((e) => e[0].toUpperCase() + e.substring(1)).join();
  }
}
