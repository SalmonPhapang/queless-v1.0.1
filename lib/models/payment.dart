enum PaymentMethod {
  card,
  cashOnDelivery,
  eft,
  instantEft;

  String get displayName {
    switch (this) {
      case PaymentMethod.card:
        return 'Credit/Debit Card';
      case PaymentMethod.cashOnDelivery:
        return 'Cash on Delivery';
      case PaymentMethod.eft:
        return 'EFT';
      case PaymentMethod.instantEft:
        return 'Card or Instant EFT';
    }
  }
}

enum PaymentProvider {
  payfast,
  paystack,
  stripe,
  ozow,
  manual;

  String get displayName {
    switch (this) {
      case PaymentProvider.payfast:
        return 'PayFast';
      case PaymentProvider.paystack:
        return 'Paystack';
      case PaymentProvider.stripe:
        return 'Stripe';
      case PaymentProvider.ozow:
        return 'Ozow';
      case PaymentProvider.manual:
        return 'Manual';
    }
  }
}

class Payment {
  final String id;
  final String orderId;
  final String userId;
  final double amount;
  final PaymentMethod paymentMethod;
  final PaymentProvider provider;
  final String status; // pending, processing, completed, failed, refunded
  final String? transactionId;
  final String? paymentReference;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  Payment({
    required this.id,
    required this.orderId,
    required this.userId,
    required this.amount,
    required this.paymentMethod,
    required this.provider,
    required this.status,
    this.transactionId,
    this.paymentReference,
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'order_id': orderId,
        'user_id': userId,
        'amount': amount,
        'payment_method': paymentMethod.name,
        'provider': provider.name,
        'status': status,
        'transaction_id': transactionId,
        'payment_reference': paymentReference,
        'metadata': metadata,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory Payment.fromJson(Map<String, dynamic> json) => Payment(
        id: json['id'] as String,
        orderId: json['order_id'] as String,
        userId: json['user_id'] as String,
        amount: (json['amount'] as num).toDouble(),
        paymentMethod: PaymentMethod.values
            .firstWhere((e) => e.name == json['payment_method']),
        provider: PaymentProvider.values
            .firstWhere((e) => e.name == json['provider']),
        status: json['status'] as String,
        transactionId: json['transaction_id'] as String?,
        paymentReference: json['payment_reference'] as String?,
        metadata: json['metadata'] as Map<String, dynamic>?,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );

  Payment copyWith({
    String? id,
    String? orderId,
    String? userId,
    double? amount,
    PaymentMethod? paymentMethod,
    PaymentProvider? provider,
    String? status,
    String? transactionId,
    String? paymentReference,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      Payment(
        id: id ?? this.id,
        orderId: orderId ?? this.orderId,
        userId: userId ?? this.userId,
        amount: amount ?? this.amount,
        paymentMethod: paymentMethod ?? this.paymentMethod,
        provider: provider ?? this.provider,
        status: status ?? this.status,
        transactionId: transactionId ?? this.transactionId,
        paymentReference: paymentReference ?? this.paymentReference,
        metadata: metadata ?? this.metadata,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}
