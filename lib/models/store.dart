class Store {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final String category;
  final List<String> cuisineTypes;
  final double rating;
  final int totalReviews;
  final int deliveryTimeMin;
  final int deliveryTimeMax;
  final double deliveryFee;
  final double minimumOrder;
  final bool isOpen;
  final Map<String, dynamic> operatingHours;
  final String address;
  final String location;
  final String phone;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;

  final String? nextOpeningTime; // e.g. "Tomorrow at 9am"
  final double? distance; // distance in meters, only set when searching nearby

  final bool isApproved;

  Store({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.category,
    required this.cuisineTypes,
    required this.rating,
    required this.totalReviews,
    required this.deliveryTimeMin,
    required this.deliveryTimeMax,
    required this.deliveryFee,
    required this.minimumOrder,
    required this.isOpen,
    required this.operatingHours,
    required this.address,
    required this.location,
    required this.phone,
    required this.tags,
    required this.createdAt,
    required this.updatedAt,
    this.nextOpeningTime,
    this.distance,
    this.isApproved = true,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'image_url': imageUrl,
        'category': category,
        'cuisine_types': cuisineTypes,
        'rating': rating,
        'total_reviews': totalReviews,
        'delivery_time_min': deliveryTimeMin,
        'delivery_time_max': deliveryTimeMax,
        'delivery_fee': deliveryFee,
        'minimum_order': minimumOrder,
        'is_open': isOpen,
        'operating_hours': operatingHours,
        'address': address,
        'location': location,
        'phone': phone,
        'tags': tags,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'next_opening_time': nextOpeningTime,
        'distance': distance,
        'is_approved': isApproved,
      };

  factory Store.fromJson(Map<String, dynamic> json) => Store(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String,
        imageUrl: json['image_url'] as String,
        category: json['category'] as String,
        cuisineTypes: (json['cuisine_types'] as List?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        rating: (json['rating'] as num).toDouble(),
        totalReviews: json['total_reviews'] as int,
        deliveryTimeMin: json['delivery_time_min'] as int,
        deliveryTimeMax: json['delivery_time_max'] as int,
        deliveryFee: (json['delivery_fee'] as num).toDouble(),
        minimumOrder: (json['minimum_order'] as num).toDouble(),
        isOpen: json['is_open'] as bool,
        operatingHours: json['operating_hours'] as Map<String, dynamic>? ?? {},
        address: json['address'] as String,
        location: json['location'] as String? ?? '',
        phone: json['phone'] as String,
        tags: (json['tags'] as List?)?.map((e) => e as String).toList() ?? [],
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
        nextOpeningTime: json['next_opening_time'] as String?,
        distance: (json['distance'] as num?)?.toDouble(),
        isApproved: json['is_approved'] as bool? ?? true,
      );

  Store copyWith({
    String? id,
    String? name,
    String? description,
    String? imageUrl,
    String? category,
    List<String>? cuisineTypes,
    double? rating,
    int? totalReviews,
    int? deliveryTimeMin,
    int? deliveryTimeMax,
    double? deliveryFee,
    double? minimumOrder,
    bool? isOpen,
    Map<String, dynamic>? operatingHours,
    String? address,
    String? location,
    String? phone,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? nextOpeningTime,
    double? distance,
    bool? isApproved,
  }) {
    return Store(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      cuisineTypes: cuisineTypes ?? this.cuisineTypes,
      rating: rating ?? this.rating,
      totalReviews: totalReviews ?? this.totalReviews,
      deliveryTimeMin: deliveryTimeMin ?? this.deliveryTimeMin,
      deliveryTimeMax: deliveryTimeMax ?? this.deliveryTimeMax,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      minimumOrder: minimumOrder ?? this.minimumOrder,
      isOpen: isOpen ?? this.isOpen,
      operatingHours: operatingHours ?? this.operatingHours,
      address: address ?? this.address,
      location: location ?? this.location,
      phone: phone ?? this.phone,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      nextOpeningTime: nextOpeningTime ?? this.nextOpeningTime,
      distance: distance ?? this.distance,
      isApproved: isApproved ?? this.isApproved,
    );
  }
}
