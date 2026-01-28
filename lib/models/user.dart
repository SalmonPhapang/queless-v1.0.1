class User {
  final String id;
  final String email;
  final String phone;
  final String fullName;
  final bool ageVerified;
  final String? idDocumentUrl;
  final List<Address> addresses;
  final List<String> favoriteProducts;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.id,
    required this.email,
    required this.phone,
    required this.fullName,
    required this.ageVerified,
    this.idDocumentUrl,
    required this.addresses,
    required this.favoriteProducts,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'phone': phone,
    'full_name': fullName,
    'age_verified': ageVerified,
    'id_document_url': idDocumentUrl,
    'addresses': addresses.map((a) => a.toJson()).toList(),
    'favorite_products': favoriteProducts,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'] as String,
    email: json['email'] as String,
    phone: json['phone'] as String,
    fullName: json['full_name'] as String,
    ageVerified: json['age_verified'] as bool,
    idDocumentUrl: json['id_document_url'] as String?,
    addresses: (json['addresses'] as List?)?.map((a) => Address.fromJson(a as Map<String, dynamic>)).toList() ?? [],
    favoriteProducts: (json['favorite_products'] as List?)?.map((e) => e as String).toList() ?? [],
    createdAt: DateTime.parse(json['created_at'] as String),
    updatedAt: DateTime.parse(json['updated_at'] as String),
  );

  User copyWith({
    String? id,
    String? email,
    String? phone,
    String? fullName,
    bool? ageVerified,
    String? idDocumentUrl,
    List<Address>? addresses,
    List<String>? favoriteProducts,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => User(
    id: id ?? this.id,
    email: email ?? this.email,
    phone: phone ?? this.phone,
    fullName: fullName ?? this.fullName,
    ageVerified: ageVerified ?? this.ageVerified,
    idDocumentUrl: idDocumentUrl ?? this.idDocumentUrl,
    addresses: addresses ?? this.addresses,
    favoriteProducts: favoriteProducts ?? this.favoriteProducts,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}

class Address {
  final String id;
  final String userId;
  final String label;
  final String streetAddress;
  final String city;
  final String province;
  final String postalCode;
  final double latitude;
  final double longitude;
  final bool isDefault;

  Address({
    required this.id,
    required this.userId,
    required this.label,
    required this.streetAddress,
    required this.city,
    required this.province,
    required this.postalCode,
    required this.latitude,
    required this.longitude,
    required this.isDefault,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'label': label,
    'street_address': streetAddress,
    'city': city,
    'province': province,
    'postal_code': postalCode,
    'latitude': latitude,
    'longitude': longitude,
    'is_default': isDefault,
  };

  factory Address.fromJson(Map<String, dynamic> json) => Address(
    id: json['id'] as String,
    userId: json['user_id'] as String,
    label: json['label'] as String,
    streetAddress: json['street_address'] as String,
    city: json['city'] as String,
    province: json['province'] as String,
    postalCode: json['postal_code'] as String,
    latitude: (json['latitude'] as num).toDouble(),
    longitude: (json['longitude'] as num).toDouble(),
    isDefault: json['is_default'] as bool,
  );

  Address copyWith({
    String? id,
    String? userId,
    String? label,
    String? streetAddress,
    String? city,
    String? province,
    String? postalCode,
    double? latitude,
    double? longitude,
    bool? isDefault,
  }) => Address(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    label: label ?? this.label,
    streetAddress: streetAddress ?? this.streetAddress,
    city: city ?? this.city,
    province: province ?? this.province,
    postalCode: postalCode ?? this.postalCode,
    latitude: latitude ?? this.latitude,
    longitude: longitude ?? this.longitude,
    isDefault: isDefault ?? this.isDefault,
  );

  String get fullAddress => '$streetAddress, $city, $province $postalCode';
}
