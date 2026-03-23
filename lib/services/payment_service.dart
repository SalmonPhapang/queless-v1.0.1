import 'package:flutter/foundation.dart';
import 'package:queless/models/payment.dart';
import 'package:queless/services/auth_service.dart';
import 'package:queless/services/order_service.dart';
import 'package:queless/models/order.dart';
import 'package:queless/supabase/supabase_config.dart';

class PaymentService {
  static final PaymentService _instance = PaymentService._internal();
  factory PaymentService() => _instance;
  PaymentService._internal();

  final _authService = AuthService();

  Future<Payment> createPayment({
    required String orderId,
    required double amount,
    required PaymentMethod paymentMethod,
  }) async {
    final authUser = SupabaseConfig.auth.currentUser;
    if (authUser == null) {
      throw Exception('User not authenticated with Supabase');
    }

    final now = DateTime.now();
    final provider = _getProviderForMethod(paymentMethod);
    final paymentReference = 'QUE${now.millisecondsSinceEpoch}';

    final paymentData = {
      'order_id': orderId,
      'user_id': authUser.id,
      'amount': amount,
      'payment_method': paymentMethod.name,
      'provider': provider.name,
      'status': 'pending',
      'payment_reference': paymentReference,
      'metadata': {},
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
    };

    try {
      final result = await SupabaseService.insert('payments', paymentData);
      return Payment.fromJson(result.first);
    } catch (e) {
      debugPrint('Error creating payment: $e');
      rethrow;
    }
  }

  Future<Payment?> processPayment({
    required String paymentId,
    required PaymentMethod paymentMethod,
  }) async {
    if (paymentMethod == PaymentMethod.instantEft) {
      return await getPaymentById(paymentId);
    }
    try {
      // Simulate payment processing
      await Future.delayed(const Duration(seconds: 2));

      final status = paymentMethod == PaymentMethod.cashOnDelivery
          ? 'pending'
          : 'completed';

      final transactionId = paymentMethod != PaymentMethod.cashOnDelivery
          ? 'TXN${DateTime.now().millisecondsSinceEpoch}'
          : null;

      await updatePaymentStatus(
        paymentId: paymentId,
        status: status,
        transactionId: transactionId,
      );

      await _syncOrderAfterPayment(paymentId, status);

      return await getPaymentById(paymentId);
    } catch (e) {
      debugPrint('Error processing payment: $e');
      await updatePaymentStatus(paymentId: paymentId, status: 'failed');
      rethrow;
    }
  }

  Future<void> updatePaymentStatus({
    required String paymentId,
    required String status,
    String? transactionId,
  }) async {
    try {
      final updateData = {
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (transactionId != null) {
        updateData['transaction_id'] = transactionId;
      }

      await SupabaseService.update(
        'payments',
        updateData,
        filters: {'id': paymentId},
      );
    } catch (e) {
      debugPrint('Error updating payment status: $e');
    }
  }

  Future<void> updatePaymentStatusFromOzow({
    required String paymentId,
    required Object status,
  }) async {
    final mappedStatus = _mapOzowStatusToPaymentStatus(status);
    await updatePaymentStatus(paymentId: paymentId, status: mappedStatus);
    await _syncOrderAfterPayment(paymentId, mappedStatus);
  }

  String _mapOzowStatusToPaymentStatus(Object status) {
    final value = status.toString().toLowerCase();

    if (value.contains('success') || value.contains('complete')) {
      return 'completed';
    }

    if (value.contains('processing') || value.contains('pending')) {
      return 'pending';
    }

    if (value.contains('cancel') ||
        value.contains('fail') ||
        value.contains('error')) {
      return 'failed';
    }

    return 'failed';
  }

  Future<void> updatePaymentStatusFromPaystack({
    required String paymentId,
    required String status,
    String? reference,
  }) async {
    final mappedStatus = _mapPaystackStatusToPaymentStatus(status);
    await updatePaymentStatus(
      paymentId: paymentId,
      status: mappedStatus,
      transactionId: reference,
    );

    await _syncOrderAfterPayment(paymentId, mappedStatus);
  }

  Future<void> _syncOrderAfterPayment(
      String paymentId, String mappedStatus) async {
    try {
      final payment = await getPaymentById(paymentId);
      if (payment == null) {
        debugPrint('Sync failed: Payment $paymentId not found');
        return;
      }

      final orderService = OrderService();
      final paymentStatusEnum = PaymentStatus.values.firstWhere(
          (e) => e.name.toLowerCase() == mappedStatus.toLowerCase(),
          orElse: () => PaymentStatus.failed);

      await orderService.updateOrderPaymentStatus(
          payment.orderId, paymentStatusEnum);

      if (mappedStatus == 'completed') {
        await orderService.updateOrderStatus(
          payment.orderId,
          OrderStatus.preparing,
        );
        try {
          final order = await orderService.getOrderById(payment.orderId);

          await SupabaseConfig.client.functions.invoke(
            'new-order-notify',
            headers: {
              'Authorization': 'Bearer ${SupabaseConfig.anonKey}',
              'apikey': SupabaseConfig.anonKey,
            },
            body: {
              'order_id': payment.orderId,
              'store_id': order?.storeId,
              'order_type': order?.orderType,
            },
          );
        } catch (e) {
          debugPrint('Error invoking new-order-notify: $e');
        }
      }
    } catch (e) {
      debugPrint('Error syncing order after payment: $e');
    }
  }

  String _mapPaystackStatusToPaymentStatus(String status) {
    final value = status.toLowerCase();

    if (value.contains('success')) {
      return 'completed';
    }

    if (value.contains('pending')) {
      return 'pending';
    }

    if (value.contains('cancel') || value.contains('fail')) {
      return 'failed';
    }

    return 'failed';
  }

  Future<Payment?> getPaymentById(String paymentId) async {
    try {
      final data = await SupabaseService.selectSingle(
        'payments',
        filters: {'id': paymentId},
      );

      return data != null ? Payment.fromJson(data) : null;
    } catch (e) {
      debugPrint('Error getting payment by id: $e');
      return null;
    }
  }

  Future<Payment?> getPaymentByOrderId(String orderId) async {
    try {
      final data = await SupabaseService.selectSingle(
        'payments',
        filters: {'order_id': orderId},
      );

      return data != null ? Payment.fromJson(data) : null;
    } catch (e) {
      debugPrint('Error getting payment by order id: $e');
      return null;
    }
  }

  Future<List<Payment>> getUserPayments() async {
    final user = _authService.currentUser;
    if (user == null) return [];

    try {
      final data = await SupabaseService.select(
        'payments',
        filters: {'user_id': user.id},
        orderBy: 'created_at',
        ascending: false,
      );

      return data.map((json) => Payment.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error getting user payments: $e');
      return [];
    }
  }

  PaymentProvider _getProviderForMethod(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.card:
        return PaymentProvider.paystack;
      case PaymentMethod.instantEft:
        return PaymentProvider.paystack;
      case PaymentMethod.eft:
      case PaymentMethod.cashOnDelivery:
        return PaymentProvider.manual;
    }
  }
}
