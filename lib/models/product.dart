enum ProductCategory {
  beer,
  wine,
  spirits,
  mixers,
  snacks,
  food,
  burgers,
  pizza,
  chicken,
  asian,
  desserts,
  drinks,
  groceries;

  String get displayName {
    switch (this) {
      case ProductCategory.beer:
        return 'Beer';
      case ProductCategory.wine:
        return 'Wine';
      case ProductCategory.spirits:
        return 'Spirits';
      case ProductCategory.mixers:
        return 'Mixers';
      case ProductCategory.snacks:
        return 'Snacks';
      case ProductCategory.food:
        return 'Food';
      case ProductCategory.burgers:
        return 'Burgers';
      case ProductCategory.pizza:
        return 'Pizza';
      case ProductCategory.chicken:
        return 'Chicken';
      case ProductCategory.asian:
        return 'Asian';
      case ProductCategory.desserts:
        return 'Desserts';
      case ProductCategory.drinks:
        return 'Drinks';
      case ProductCategory.groceries:
        return 'Groceries';
    }
  }
}

enum ProductType {
  alcohol,
  food;

  String get displayName {
    switch (this) {
      case ProductType.alcohol:
        return 'Alcohol';
      case ProductType.food:
        return 'Food';
    }
  }
}

class Product {
  static const double feeRate = 0.20;

  final String id;
  final String name;
  final String category;
  final String? brand;
  final String description;
  final double price;
  final String imageUrl;
  final double? alcoholContent;
  final String? volume;
  final bool isLocalBrand;
  final List<String> tags;
  final ProductType productType;
  final String? storeId;
  final int stock;
  final DateTime createdAt;
  final DateTime updatedAt;

  Product({
    required this.id,
    required this.name,
    required this.category,
    this.brand,
    required this.description,
    required this.price,
    required this.imageUrl,
    this.alcoholContent,
    this.volume,
    this.isLocalBrand = false,
    required this.tags,
    this.productType = ProductType.alcohol,
    this.storeId,
    this.stock = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isInStock => stock > 0;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category,
        'brand': brand,
        'description': description,
        'price': price,
        'image_url': imageUrl,
        'alcohol_content': alcoholContent,
        'volume': volume,
        'is_local_brand': isLocalBrand,
        'tags': tags,
        'product_type': productType.name,
        'store_id': storeId,
        'stock': stock,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: json['id'] as String,
        name: json['name'] as String,
        category: json['category']?.toString() ?? 'Food',
        brand: json['brand'] as String?,
        description: json['description'] as String? ?? '',
        price: (json['price'] as num).toDouble() * (1 + feeRate),
        imageUrl: json['image_url'] as String? ?? '',
        alcoholContent: json['alcohol_content'] != null
            ? (json['alcohol_content'] as num).toDouble()
            : null,
        volume: json['volume'] as String?,
        isLocalBrand: json['is_local_brand'] as bool? ?? false,
        tags: (json['tags'] as List?)?.map((e) => e as String).toList() ?? [],
        productType: json['product_type'] != null
            ? ProductType.values.firstWhere(
                (e) => e.name == json['product_type'],
                orElse: () => ProductType.alcohol)
            : ProductType.alcohol,
        storeId: json['store_id'] as String?,
        stock: json['stock'] as int? ?? 0,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );

  Product copyWith({
    String? id,
    String? name,
    String? category,
    String? brand,
    String? description,
    double? price,
    String? imageUrl,
    double? alcoholContent,
    String? volume,
    bool? isLocalBrand,
    List<String>? tags,
    ProductType? productType,
    String? storeId,
    int? stock,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      Product(
        id: id ?? this.id,
        name: name ?? this.name,
        category: category ?? this.category,
        brand: brand ?? this.brand,
        description: description ?? this.description,
        price: price ?? this.price,
        imageUrl: imageUrl ?? this.imageUrl,
        alcoholContent: alcoholContent ?? this.alcoholContent,
        volume: volume ?? this.volume,
        isLocalBrand: isLocalBrand ?? this.isLocalBrand,
        tags: tags ?? this.tags,
        productType: productType ?? this.productType,
        storeId: storeId ?? this.storeId,
        stock: stock ?? this.stock,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}
