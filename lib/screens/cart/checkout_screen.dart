import 'package:flutter/material.dart';
import 'package:queless/services/cart_service.dart';
import 'package:queless/services/food_cart_service.dart';
import 'package:queless/services/order_service.dart';
import 'package:queless/services/payment_service.dart';
import 'package:queless/services/auth_service.dart';
import 'package:queless/models/user.dart';
import 'package:queless/models/payment.dart';
import 'package:queless/screens/orders/order_tracking_screen.dart';
import 'package:queless/screens/payments/paystack_payment_screen.dart';
import 'package:queless/screens/profile/address_management_screen.dart';
import 'package:queless/utils/formatters.dart';
import 'package:queless/utils/snack_bar_helper.dart';
import 'package:queless/utils/compliance_helper.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _cartService = CartService();
  final _orderService = OrderService();
  final _paymentService = PaymentService();
  final _authService = AuthService();

  Address? _selectedAddress;
  PaymentMethod _selectedPaymentMethod = PaymentMethod.instantEft;
  bool _isPlacingOrder = false;

  @override
  void initState() {
    super.initState();
    final user = _authService.currentUser;
    if (user != null && user.addresses.isNotEmpty) {
      _selectedAddress = user.addresses
          .firstWhere((a) => a.isDefault, orElse: () => user.addresses.first);
    }
  }

  Future<void> _placeOrder() async {
    final subtotal = _cartService.subtotal;
    if (subtotal < 100.0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Minimum order amount is R100 excluding delivery fee')),
      );
      return;
    }

    if (_selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a delivery address')),
      );
      return;
    }

    final canOrder =
        ComplianceHelper.canOrderAlcohol(_selectedAddress!.province);
    if (!canOrder) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Cannot Place Order'),
          content: Text(ComplianceHelper.getRestrictionMessage(
              _selectedAddress!.province)),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK')),
          ],
        ),
      );
      return;
    }

    setState(() => _isPlacingOrder = true);

    try {
      final order = await _orderService.createOrder(
        deliveryAddress: _selectedAddress!,
        paymentMethod: _selectedPaymentMethod.displayName,
      );

      Payment payment;
      try {
        payment = await _paymentService.createPayment(
          orderId: order.id,
          amount: order.total,
          paymentMethod: _selectedPaymentMethod,
        );
      } catch (e) {
        if (mounted) {
          await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Payment Error'),
              content: const Text(
                'We could not start your payment right now. '
                'Your order has been created and remains pending.\n\n'
                'You can try to pay again from the Orders section.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => OrderTrackingScreen(orderId: order.id),
                      ),
                    );
                  },
                  child: const Text('View Order'),
                ),
              ],
            ),
          );
        }
        return;
      }

      if (_selectedPaymentMethod == PaymentMethod.instantEft ||
          _selectedPaymentMethod == PaymentMethod.card) {
        if (!mounted) return;
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PaystackPaymentScreen(
              payment: payment,
              isFoodCart: false,
            ),
          ),
        );
        return;
      }

      // Show payment processing dialog for non-COD payments
      if (_selectedPaymentMethod != PaymentMethod.cashOnDelivery &&
          _selectedPaymentMethod != PaymentMethod.instantEft &&
          _selectedPaymentMethod != PaymentMethod.card &&
          mounted) {
        _showPaymentDialog(payment);
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) Navigator.pop(context);
      }

      // Process the payment
      await _paymentService.processPayment(
        paymentId: payment.id,
        paymentMethod: _selectedPaymentMethod,
      );

      // Clear the cart after successful payment
      await _cartService.clear();

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => OrderTrackingScreen(
              orderId: order.id,
              source: OrderTrackingSource.payment,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(
          context,
          'Something went wrong while placing your order. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _isPlacingOrder = false);
    }
  }

  void _showPaymentDialog(Payment payment) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Processing Payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text('Payment Reference: ${payment.paymentReference}'),
            const SizedBox(height: 8),
            Text('Amount: ${Formatters.formatCurrency(payment.amount)}'),
            const SizedBox(height: 16),
            const Text('Please complete your payment...',
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = _cartService.calculateTotal();
    final subtotal = _cartService.subtotal;
    const minOrderAmount = 100.0;
    final hasMinimumSubtotal = subtotal >= minOrderAmount;

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Delivery Address',
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  if (_selectedAddress == null)
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.location_on_outlined),
                        title: const Text('No address selected'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () async {
                          await Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      const AddressManagementScreen()));
                          setState(() {
                            final user = _authService.currentUser;
                            if (user != null && user.addresses.isNotEmpty) {
                              _selectedAddress = user.addresses.firstWhere(
                                  (a) => a.isDefault,
                                  orElse: () => user.addresses.first);
                            }
                          });
                        },
                      ),
                    )
                  else
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.location_on),
                        title: Text(_selectedAddress!.label),
                        subtitle: Text(_selectedAddress!.fullAddress),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () async {
                          await Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      const AddressManagementScreen()));
                          setState(() {
                            final user = _authService.currentUser;
                            if (user != null && user.addresses.isNotEmpty) {
                              _selectedAddress = user.addresses.firstWhere(
                                  (a) => a.isDefault,
                                  orElse: () => user.addresses.first);
                            }
                          });
                        },
                      ),
                    ),
                  const SizedBox(height: 32),
                  Text('Payment Method',
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Card(
                    child: RadioListTile<PaymentMethod>(
                      value: PaymentMethod.instantEft,
                      groupValue: _selectedPaymentMethod,
                      onChanged: (value) =>
                          setState(() => _selectedPaymentMethod = value!),
                      title: Text(PaymentMethod.instantEft.displayName),
                      secondary: const Icon(Icons.account_balance),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer
                          .withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color:
                              theme.colorScheme.error.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.info_outline,
                            color: theme.colorScheme.error),
                        const SizedBox(height: 8),
                        Text(
                          ComplianceHelper
                              .getRandomResponsibleDrinkingMessage(),
                          style: theme.textTheme.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -2))
              ],
            ),
            child: Column(
              children: [
                if (!hasMinimumSubtotal)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer
                          .withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.error.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: theme.colorScheme.error,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Minimum order amount is R100 excluding delivery fee',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total Amount',
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    Text(Formatters.formatCurrency(total),
                        style: theme.textTheme.titleLarge?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isPlacingOrder || !hasMinimumSubtotal
                        ? null
                        : _placeOrder,
                    child: _isPlacingOrder
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Place Order'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class FoodCheckoutScreen extends StatefulWidget {
  const FoodCheckoutScreen({super.key});

  @override
  State<FoodCheckoutScreen> createState() => _FoodCheckoutScreenState();
}

class _FoodCheckoutScreenState extends State<FoodCheckoutScreen> {
  final _cartService = FoodCartService();
  final _orderService = OrderService();
  final _paymentService = PaymentService();
  final _authService = AuthService();

  Address? _selectedAddress;
  PaymentMethod _selectedPaymentMethod = PaymentMethod.instantEft;
  bool _isPlacingOrder = false;

  @override
  void initState() {
    super.initState();
    final user = _authService.currentUser;
    if (user != null && user.addresses.isNotEmpty) {
      _selectedAddress = user.addresses.firstWhere(
        (a) => a.isDefault,
        orElse: () => user.addresses.first,
      );
    }
  }

  Future<void> _placeOrder() async {
    final subtotal = _cartService.subtotal;
    if (subtotal < 100.0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Minimum order amount is R100 excluding delivery fee'),
        ),
      );
      return;
    }

    if (_selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a delivery address')),
      );
      return;
    }

    setState(() => _isPlacingOrder = true);

    try {
      final order = await _orderService.createFoodOrder(
        deliveryAddress: _selectedAddress!,
        paymentMethod: _selectedPaymentMethod.displayName,
      );

      Payment payment;
      try {
        payment = await _paymentService.createPayment(
          orderId: order.id,
          amount: order.total,
          paymentMethod: _selectedPaymentMethod,
        );
      } catch (e) {
        if (mounted) {
          await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Payment Error'),
              content: const Text(
                'We could not start your payment right now. '
                'Your order has been created and remains pending.\n\n'
                'You can try to pay again from the Orders section.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => OrderTrackingScreen(
                          orderId: order.id,
                          source: OrderTrackingSource.payment,
                        ),
                      ),
                    );
                  },
                  child: const Text('View Order'),
                ),
              ],
            ),
          );
        }
        return;
      }

      if (_selectedPaymentMethod == PaymentMethod.instantEft ||
          _selectedPaymentMethod == PaymentMethod.card) {
        if (!mounted) return;
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PaystackPaymentScreen(
              payment: payment,
              isFoodCart: true,
            ),
          ),
        );
        return;
      }

      if (_selectedPaymentMethod != PaymentMethod.cashOnDelivery &&
          _selectedPaymentMethod != PaymentMethod.instantEft &&
          _selectedPaymentMethod != PaymentMethod.card &&
          mounted) {
        _showPaymentDialog(payment);
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) Navigator.pop(context);
      }

      await _paymentService.processPayment(
        paymentId: payment.id,
        paymentMethod: _selectedPaymentMethod,
      );

      await _cartService.clear();

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => OrderTrackingScreen(orderId: order.id),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(
          context,
          'Something went wrong while placing your order. Please try again.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPlacingOrder = false);
      }
    }
  }

  void _showPaymentDialog(Payment payment) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Processing Payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text('Payment Reference: ${payment.paymentReference}'),
            const SizedBox(height: 8),
            Text(
              'Amount: ${Formatters.formatCurrency(payment.amount)}',
            ),
            const SizedBox(height: 16),
            const Text(
              'Please complete your payment...',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = _cartService.calculateTotal();
    final subtotal = _cartService.subtotal;
    const minOrderAmount = 100.0;
    final hasMinimumSubtotal = subtotal >= minOrderAmount;

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Delivery Address',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_selectedAddress == null)
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.location_on_outlined),
                        title: const Text('No address selected'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AddressManagementScreen(),
                            ),
                          );
                          setState(() {
                            final user = _authService.currentUser;
                            if (user != null && user.addresses.isNotEmpty) {
                              _selectedAddress = user.addresses.firstWhere(
                                (a) => a.isDefault,
                                orElse: () => user.addresses.first,
                              );
                            }
                          });
                        },
                      ),
                    )
                  else
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.location_on),
                        title: Text(_selectedAddress!.label),
                        subtitle: Text(_selectedAddress!.fullAddress),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AddressManagementScreen(),
                            ),
                          );
                          setState(() {
                            final user = _authService.currentUser;
                            if (user != null && user.addresses.isNotEmpty) {
                              _selectedAddress = user.addresses.firstWhere(
                                (a) => a.isDefault,
                                orElse: () => user.addresses.first,
                              );
                            }
                          });
                        },
                      ),
                    ),
                  const SizedBox(height: 32),
                  Text(
                    'Payment Method',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: RadioListTile<PaymentMethod>(
                      value: PaymentMethod.instantEft,
                      groupValue: _selectedPaymentMethod,
                      onChanged: (value) => setState(
                        () => _selectedPaymentMethod = value!,
                      ),
                      title: Text(
                        PaymentMethod.instantEft.displayName,
                      ),
                      secondary: const Icon(Icons.account_balance),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              children: [
                if (!hasMinimumSubtotal)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer
                          .withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.error.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: theme.colorScheme.error,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Minimum order amount is R100 excluding delivery fee',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Amount',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      Formatters.formatCurrency(total),
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isPlacingOrder || !hasMinimumSubtotal
                        ? null
                        : _placeOrder,
                    child: _isPlacingOrder
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Place Order'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
