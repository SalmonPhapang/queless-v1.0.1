enum PromotionTargetType {
  product,
  store;
}

class Promotion {
  final String id;
  final String title;
  final String message;
  final PromotionTargetType targetType;
  final String targetId;
  final String badgeText;
  final String imageUrl;
  final bool isActive;
  final int priority;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  Promotion({
    required this.id,
    required this.title,
    required this.message,
    required this.targetType,
    required this.targetId,
    required this.badgeText,
    required this.imageUrl,
    this.isActive = true,
    this.priority = 0,
    this.startsAt,
    this.endsAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory Promotion.fromJson(Map<String, dynamic> json) => Promotion(
        id: json['id']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        message: json['message']?.toString() ?? '',
        targetType: (json['target_type']?.toString() ?? 'product')
                    .toLowerCase() ==
                'store'
            ? PromotionTargetType.store
            : PromotionTargetType.product,
        targetId: json['target_id']?.toString() ?? '',
        badgeText: json['badge_text']?.toString() ?? 'Promo',
        imageUrl: json['image_url']?.toString() ?? '',
        isActive: json['is_active'] == true,
        priority: int.tryParse(json['priority']?.toString() ?? '0') ?? 0,
        startsAt: json['starts_at'] != null
            ? DateTime.tryParse(json['starts_at'].toString())
            : null,
        endsAt: json['ends_at'] != null
            ? DateTime.tryParse(json['ends_at'].toString())
            : null,
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'].toString())
            : null,
        updatedAt: json['updated_at'] != null
            ? DateTime.tryParse(json['updated_at'].toString())
            : null,
      );

  bool get isCurrentlyActive {
    if (!isActive) return false;
    final now = DateTime.now();
    if (startsAt != null && startsAt!.isAfter(now)) return false;
    if (endsAt != null && endsAt!.isBefore(now)) return false;
    return true;
  }
}

