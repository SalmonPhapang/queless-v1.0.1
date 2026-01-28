import 'package:flutter/material.dart';
import 'package:paystack_for_flutter/paystack_for_flutter.dart';
import 'package:queless/config/app_config.dart';
import 'package:queless/models/payment.dart';
import 'package:queless/screens/orders/order_tracking_screen.dart';
import 'package:queless/services/auth_service.dart';
import 'package:queless/services/cart_service.dart';
import 'package:queless/services/food_cart_service.dart';
import 'package:queless/services/payment_service.dart';

class PaystackPaymentScreen extends StatefulWidget {
  const PaystackPaymentScreen({
    super.key,
    required this.payment,
    required this.isFoodCart,
    this.clearCartOnComplete = true,
  });

  final Payment payment;
  final bool isFoodCart;
  final bool clearCartOnComplete;

  @override
  State<PaystackPaymentScreen> createState() => _PaystackPaymentScreenState();
}

class _PaystackPaymentScreenState extends State<PaystackPaymentScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startPayment();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
      ),
      body: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Future<void> _startPayment() async {
    final amountInMinorUnits = (widget.payment.amount * 100).round();
    final authService = AuthService();
    final user = authService.currentUser;
    final email = user?.email ?? '';
    final fullName = user?.fullName ?? '';
    final parts = fullName.trim().split(' ');
    final firstName = parts.isNotEmpty ? parts.first : '';
    final lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';

    final currency = _mapCurrency(PaystackConfig.currency);

    await PaystackFlutter().pay(
      context: context,
      secretKey: PaystackConfig.secretKey,
      amount: amountInMinorUnits.toDouble(),
      email: email,
      firstName: firstName,
      lastName: lastName,
      callbackUrl: PaystackConfig.callbackUrl,
      showProgressBar: true,
      paymentOptions: const [
        PaymentOption.card,
        PaymentOption.eft,
      ],
      currency: currency,
      metaData: <String, dynamic>{
        'payment_id': widget.payment.id,
        'order_id': widget.payment.orderId,
      },
      onSuccess: (callback) async {
        await PaymentService().updatePaymentStatusFromPaystack(
          paymentId: widget.payment.id,
          status: 'success',
          reference: callback.reference,
        );

        if (widget.clearCartOnComplete) {
          if (widget.isFoodCart) {
            await FoodCartService().clear();
          } else {
            await CartService().clear();
          }
        }

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => OrderTrackingScreen(
              orderId: widget.payment.orderId,
              source: OrderTrackingSource.payment,
            ),
          ),
        );
      },
      onCancelled: (callback) async {
        await PaymentService().updatePaymentStatusFromPaystack(
          paymentId: widget.payment.id,
          status: 'cancelled',
          reference: callback.reference,
        );

        if (widget.clearCartOnComplete) {
          if (widget.isFoodCart) {
            await FoodCartService().clear();
          } else {
            await CartService().clear();
          }
        }

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => OrderTrackingScreen(
              orderId: widget.payment.orderId,
              source: OrderTrackingSource.payment,
            ),
          ),
        );
      },
    );
  }

  Currency _mapCurrency(String value) {
    switch (value.toUpperCase()) {
      case 'NGN':
        return Currency.NGN;
      case 'USD':
        return Currency.USD;
      case 'EUR':
        return Currency.EUR;
      case 'GHS':
        return Currency.GHS;
      case 'ZAR':
        return Currency.ZAR;
      case 'KES':
        return Currency.KES;
      default:
        return Currency.NGN;
    }
  }
}
