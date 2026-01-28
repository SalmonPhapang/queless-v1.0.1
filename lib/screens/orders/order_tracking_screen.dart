import 'package:flutter/material.dart';
import 'package:queless/models/order.dart';
import 'package:queless/models/payment.dart';
import 'package:queless/models/store.dart';
import 'package:queless/screens/main_screen.dart';
import 'package:queless/screens/payments/paystack_payment_screen.dart';
import 'package:queless/services/order_service.dart';
import 'package:queless/services/payment_service.dart';
import 'package:queless/services/store_service.dart';
import 'package:queless/utils/formatters.dart';
import 'package:cached_network_image/cached_network_image.dart';

enum OrderTrackingSource {
  payment,
  orders,
  home,
}

class OrderTrackingScreen extends StatefulWidget {
  final String orderId;
  final OrderTrackingSource source;

  const OrderTrackingScreen({
    super.key,
    required this.orderId,
    this.source = OrderTrackingSource.payment,
  });

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  final _orderService = OrderService();
  final _paymentService = PaymentService();
  final _storeService = StoreService();
  Order? _order;
  Store? _store;
  bool _isLoading = true;
  bool _isPaying = false;

  void _handleBack(BuildContext context) {
    switch (widget.source) {
      case OrderTrackingSource.home:
      case OrderTrackingSource.orders:
        Navigator.pop(context);
        break;
      case OrderTrackingSource.payment:
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => const MainScreen(initialIndex: 3),
          ),
          (route) => false,
        );
        break;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    setState(() => _isLoading = true);
    try {
      final order = await _orderService.getOrderById(widget.orderId);
      Store? store;
      if (order?.storeId != null) {
        store = await _storeService.getStoreById(order!.storeId!);
      }

      setState(() {
        _order = order;
        _store = store;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  PaymentMethod? _mapPaymentMethod(String label) {
    for (final method in PaymentMethod.values) {
      if (method.displayName == label) return method;
    }
    return null;
  }

  Future<void> _handlePayNow() async {
    if (_order == null) return;

    final method = _mapPaymentMethod(_order!.paymentMethod);
    if (method == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Unsupported payment method for this order.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    setState(() => _isPaying = true);

    try {
      Payment? existingPayment =
          await _paymentService.getPaymentByOrderId(_order!.id);

      final payment = existingPayment ??
          await _paymentService.createPayment(
            orderId: _order!.id,
            amount: _order!.total,
            paymentMethod: method,
          );

      if (method == PaymentMethod.instantEft || method == PaymentMethod.card) {
        if (!mounted) return;
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PaystackPaymentScreen(
              payment: payment,
              isFoodCart: false,
              clearCartOnComplete: false,
            ),
          ),
        );

        if (mounted) {
          await _loadOrder();
        }
        return;
      }

      if (mounted) {
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
                  'Please wait while we confirm your payment...',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }

      await _paymentService.processPayment(
        paymentId: payment.id,
        paymentMethod: method,
      );

      if (mounted) {
        Navigator.pop(context);
      }

      await _loadOrder();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Something went wrong while processing your payment. '
              'Please try again.',
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPaying = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Order Tracking')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_order == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Order Tracking')),
        body: const Center(child: Text('Order not found')),
      );
    }

    final scaffold = Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => _handleBack(context),
        ),
        title: Text('Order #${_order!.id.substring(0, 8)}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_order!.status == OrderStatus.delivered)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: Colors.green.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle,
                        color: Colors.green, size: 48),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Order Delivered!',
                              style: theme.textTheme.titleLarge?.copyWith(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          const Text('Thank you for ordering with Queless'),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color:
                      theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(Icons.delivery_dining,
                        size: 64, color: theme.colorScheme.primary),
                    const SizedBox(height: 16),
                    Text(
                      _order!.status.displayName,
                      style: theme.textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    if (_order!.estimatedDeliveryTime != null)
                      Text(
                        'Estimated delivery: ${Formatters.formatTime(_order!.estimatedDeliveryTime!)}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.7)),
                        textAlign: TextAlign.center,
                      )
                    else
                      Text(
                        'Estimated delivery: 30-45 minutes',
                        style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.7)),
                        textAlign: TextAlign.center,
                      ),
                  ],
                ),
              ),
            const SizedBox(height: 24),
            if (_order!.driverName != null &&
                _order!.status == OrderStatus.outForDelivery)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Your Driver',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: theme.colorScheme.primaryContainer,
                            child: Text(_order!.driverName![0].toUpperCase(),
                                style: TextStyle(
                                    color: theme.colorScheme.onPrimaryContainer,
                                    fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_order!.driverName!,
                                    style: theme.textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.bold)),
                                if (_order!.driverPhone != null)
                                  Text(_order!.driverPhone!,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                              color: theme.colorScheme.onSurface
                                                  .withValues(alpha: 0.6))),
                              ],
                            ),
                          ),
                          if (_order!.driverPhone != null)
                            IconButton(
                              onPressed: () {},
                              icon: const Icon(Icons.phone),
                              style: IconButton.styleFrom(
                                backgroundColor:
                                    theme.colorScheme.primaryContainer,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            if (_store != null) ...[
              const SizedBox(height: 32),
              Text('Restaurant',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Card(
                child: ListTile(
                  leading: _store!.imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: _store!.imageUrl,
                          imageBuilder: (context, imageProvider) => Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(8),
                              image: DecorationImage(
                                image: imageProvider,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          placeholder: (context, url) => Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: theme.colorScheme.primary
                                    .withValues(alpha: 0.3),
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.store,
                                color: theme.colorScheme.primary
                                    .withValues(alpha: 0.5)),
                          ),
                        )
                      : const Icon(Icons.store),
                  title: Text(_store!.name),
                  subtitle: Text(_store!.address),
                  trailing: _store!.phone.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.phone),
                          onPressed: () {
                            // TODO: Implement phone call
                          },
                        )
                      : null,
                ),
              ),
            ],
            const SizedBox(height: 32),
            Text('Order Timeline',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ..._order!.trackingUpdates.reversed.map((update) => TrackingTile(
                update: update,
                isLast: update == _order!.trackingUpdates.first)),
            const SizedBox(height: 32),
            Text('Delivery Address',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.location_on),
                title: Text(_order!.deliveryAddress.label),
                subtitle: Text(_order!.deliveryAddress.fullAddress),
              ),
            ),
            const SizedBox(height: 24),
            Text('Order Items',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ..._order!.items.map((item) => Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: item.productImageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: item.productImageUrl,
                            imageBuilder: (context, imageProvider) => Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color:
                                    theme.colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(8),
                                image: DecorationImage(
                                  image: imageProvider,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                            placeholder: (context, url) => Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color:
                                    theme.colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: theme.colorScheme.primary
                                      .withValues(alpha: 0.3),
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color:
                                    theme.colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.local_bar,
                                  color: theme.colorScheme.primary
                                      .withValues(alpha: 0.5)),
                            ),
                          )
                        : Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.local_bar,
                                color: theme.colorScheme.primary
                                    .withValues(alpha: 0.5)),
                          ),
                    title: Text(item.productName),
                    subtitle: Text('Qty: ${item.quantity}'),
                    trailing: Text(Formatters.formatCurrency(item.totalPrice),
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.bold)),
                  ),
                )),
            const SizedBox(height: 24),
            Text('Payment Summary',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    SummaryRow(
                        label: 'Subtotal',
                        value: Formatters.formatCurrency(_order!.subtotal)),
                    const SizedBox(height: 8),
                    SummaryRow(
                        label: 'Delivery Fee',
                        value: Formatters.formatCurrency(_order!.deliveryFee)),
                    if (_order!.discount > 0) ...[
                      const SizedBox(height: 8),
                      SummaryRow(
                          label: 'Discount',
                          value:
                              '-${Formatters.formatCurrency(_order!.discount)}',
                          valueColor: theme.colorScheme.secondary),
                    ],
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total',
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        Text(Formatters.formatCurrency(_order!.total),
                            style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            if (_canPayNow())
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isPaying ? null : _handlePayNow,
                      child: _isPaying
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Pay now'),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            if (widget.source == OrderTrackingSource.payment)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _handleBack(context),
                  child: const Text('View in Orders'),
                ),
              ),
          ],
        ),
      ),
    );

    return PopScope(
      canPop: widget.source != OrderTrackingSource.payment,
      onPopInvoked: (didPop) {
        if (didPop) return;
        _handleBack(context);
      },
      child: scaffold,
    );
  }

  bool _canPayNow() {
    if (_order == null) return false;

    if (_order!.paymentStatus != PaymentStatus.pending) {
      return false;
    }

    if (_order!.paymentMethod == PaymentMethod.cashOnDelivery.displayName) {
      return false;
    }

    if (_order!.status != OrderStatus.pending) {
      return false;
    }

    final age = DateTime.now().difference(_order!.createdAt);
    return age <= const Duration(hours: 24);
  }
}

class TrackingTile extends StatelessWidget {
  final TrackingUpdate update;
  final bool isLast;

  const TrackingTile({super.key, required this.update, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 18),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 60,
                color: theme.colorScheme.primary.withValues(alpha: 0.3),
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(update.message,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(Formatters.formatDateTime(update.timestamp),
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.6))),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const SummaryRow(
      {super.key, required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: theme.textTheme.bodyMedium),
        Text(value,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: valueColor, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
