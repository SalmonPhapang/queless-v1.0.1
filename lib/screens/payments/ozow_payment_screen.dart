import 'package:flutter/material.dart';
import 'package:flutter_ozow/flutter_ozow.dart';
import 'package:queless/config/app_config.dart';
import 'package:queless/models/payment.dart';
import 'package:queless/screens/orders/order_tracking_screen.dart';
import 'package:queless/services/cart_service.dart';
import 'package:queless/services/food_cart_service.dart';
import 'package:queless/services/payment_service.dart';

class OzowPaymentScreen extends StatelessWidget {
  const OzowPaymentScreen({
    super.key,
    required this.payment,
    required this.isFoodCart,
    this.clearCartOnComplete = true,
  });

  final Payment payment;
  final bool isFoodCart;
  final bool clearCartOnComplete;

  @override
  Widget build(BuildContext context) {
    final amount = payment.amount;
    final reference = payment.paymentReference ?? payment.id;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ozow Payment'),
      ),
      body: FlutterOzow(
        transactionId: reference,
        privateKey: OzowConfig.privateKey,
        siteCode: OzowConfig.siteCode,
        bankRef: reference,
        apiKey: OzowConfig.apiKey,
        amount: amount,
        isTest: OzowConfig.isTest,
        notifyUrl: OzowConfig.notifyUrl,
        successUrl: OzowConfig.successUrl,
        errorUrl: OzowConfig.errorUrl,
        cancelUrl: OzowConfig.cancelUrl,
        onComplete: (transaction, status) async {
          try {
            await PaymentService().updatePaymentStatusFromOzow(
              paymentId: payment.id,
              status: status,
            );
          } catch (_) {}

          if (!context.mounted) return;

          if (clearCartOnComplete) {
            if (isFoodCart) {
              await FoodCartService().clear();
            } else {
              await CartService().clear();
            }
          }

          if (!context.mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => OrderTrackingScreen(
                orderId: payment.orderId,
                source: OrderTrackingSource.payment,
              ),
            ),
          );
        },
      ),
    );
  }
}
