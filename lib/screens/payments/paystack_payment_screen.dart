import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:queless/config/app_config.dart';
import 'package:queless/models/payment.dart';
import 'package:queless/screens/orders/order_tracking_screen.dart';
import 'package:queless/services/auth_service.dart';
import 'package:queless/services/cart_service.dart';
import 'package:queless/services/food_cart_service.dart';
import 'package:queless/services/payment_service.dart';
import 'package:queless/services/order_service.dart';
import 'package:webview_flutter/webview_flutter.dart';

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
  late final WebViewController _controller;
  bool _isLoading = true;
  String? _authorizationUrl;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeTransaction();
  }

  Future<void> _initializeTransaction() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = AuthService();
      final user = authService.currentUser;
      final email = user?.email ?? '';

      // Prepare payload for Paystack API
      final Map<String, dynamic> body = {
        'email': email,
        'amount': (widget.payment.amount * 100).round().toString(),
        'reference': widget.payment.paymentReference ??
            'QUE${DateTime.now().millisecondsSinceEpoch}',
        'currency': PaystackConfig.currency,
        'callback_url': PaystackConfig.callbackUrl,
        'metadata': {
          'payment_id': widget.payment.id,
          'order_id': widget.payment.orderId,
        },
      };

      // Add split payment logic
      final splitDetails =
          await PaymentService().getSplitDetails(widget.payment.orderId);

      if (splitDetails != null && splitDetails['subaccount_code'] != null) {
        final subaccount = splitDetails['subaccount_code'];
        final storeAmount = splitDetails['store_amount'] as double?;

        body['subaccount'] = subaccount;
        body['bearer'] = 'account';

        if (storeAmount != null) {
          final totalAmount = widget.payment.amount;
          final quelessShareInMinorUnits =
              ((totalAmount - storeAmount) * 100).round();
          body['transaction_charge'] = quelessShareInMinorUnits.toString();

          // Add split info to metadata as well
          (body['metadata'] as Map<String, dynamic>).addAll({
            'subaccount_code': subaccount,
            'queless_share': quelessShareInMinorUnits,
            'store_share': (storeAmount * 100).round(),
          });
        }
      }

      final response = await http.post(
        Uri.parse('https://api.paystack.co/transaction/initialize'),
        headers: <String, String>{
          'Authorization': 'Bearer ${PaystackConfig.secretKey}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['status'] == true) {
        _authorizationUrl = responseData['data']['authorization_url'];
        _setupWebViewController();
      } else {
        setState(() {
          _errorMessage =
              responseData['message'] ?? 'Failed to initialize transaction';
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error initializing Paystack transaction: $e');
      setState(() {
        _errorMessage = 'An error occurred. Please check your connection.';
        _isLoading = false;
      });
    }
  }

  void _setupWebViewController() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // Update loading bar.
          },
          onPageStarted: (String url) {
            setState(() => _isLoading = true);
          },
          onPageFinished: (String url) {
            setState(() => _isLoading = false);
            _checkNavigation(url);
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('WebView Error: ${error.description}');
          },
          onNavigationRequest: (NavigationRequest request) {
            return _checkNavigation(request.url);
          },
        ),
      )
      ..loadRequest(Uri.parse(_authorizationUrl!));
  }

  NavigationDecision _checkNavigation(String url) {
    debugPrint('Navigating to: $url');

    // Check if the URL contains our callback URL
    if (url.startsWith(PaystackConfig.callbackUrl)) {
      final uri = Uri.parse(url);
      final reference =
          uri.queryParameters['reference'] ?? uri.queryParameters['trxref'];
      final status = uri.queryParameters['status'] ?? 'success';

      // Usually, if it hits the callback URL, it's successful or at least finished
      _handlePaymentCompletion(reference, status);
      return NavigationDecision.prevent;
    }

    return NavigationDecision.navigate;
  }

  Future<void> _handlePaymentCompletion(
      String? reference, String status) async {
    // Note: You should verify the transaction on your backend here
    debugPrint(
        'Payment completion detected. Reference: $reference, Status: $status');

    await PaymentService().updatePaymentStatusFromPaystack(
      paymentId: widget.payment.id,
      status: status,
      reference: reference,
    );

    if (status.toLowerCase() == 'success') {
      if (widget.clearCartOnComplete) {
        final orderId = widget.payment.orderId;
        final orderService = OrderService();
        final order = await orderService.getOrderById(orderId);
        final storeId = order?.storeId ?? '';

        if (widget.isFoodCart) {
          await FoodCartService().clear(storeId);
        } else {
          await CartService().clear(storeId);
        }
      }

      if (!mounted) return;
      _redirectToTracking(paymentFailed: false);
    } else {
      // If payment failed, go to order tracking but indicate failure
      if (!mounted) return;
      _redirectToTracking(paymentFailed: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _redirectToTracking(paymentFailed: true);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Secure Payment'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => _redirectToTracking(paymentFailed: true),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _initializeTransaction,
            ),
          ],
        ),
        body: Stack(
          children: [
            if (_authorizationUrl != null)
              WebViewWidget(controller: _controller),
            if (_isLoading) const Center(child: CircularProgressIndicator()),
            if (_errorMessage != null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 60, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _initializeTransaction,
                        child: const Text('Try Again'),
                      ),
                      TextButton(
                        onPressed: () =>
                            _redirectToTracking(paymentFailed: true),
                        child: const Text('Cancel'),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _redirectToTracking({required bool paymentFailed}) {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => OrderTrackingScreen(
          orderId: widget.payment.orderId,
          source: OrderTrackingSource.payment,
          paymentFailed: paymentFailed,
        ),
      ),
    );
  }
}
