import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:queless/theme.dart';
import 'package:queless/supabase/supabase_config.dart';
import 'package:queless/services/auth_service.dart';
import 'package:queless/services/product_service.dart';
import 'package:queless/services/cart_service.dart';
import 'package:queless/services/food_cart_service.dart';
import 'package:queless/services/store_service.dart';
import 'package:queless/services/order_service.dart';
import 'package:queless/router/auth_router.dart';
import 'package:queless/utils/database_test.dart';
import 'package:queless/config/app_config.dart';
import 'package:queless/screens/orders/order_tracking_screen.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}

/// Helper to save FCM token to Supabase for the current user
Future<void> _saveFcmToken(String token) async {
  final user = AuthService().currentUser;
  if (user != null) {
    try {
      debugPrint('📝 Saving FCM token for user ${user.id}...');
      await SupabaseService.upsert(
        'user_fcm_tokens',
        {
          'user_id': user.id,
          'token': token,
          'updated_at': DateTime.now().toIso8601String(),
        },
      );
      debugPrint('✅ FCM Token saved to Supabase');
    } catch (e) {
      debugPrint('❌ Failed to save FCM token: $e');
    }
  } else {
    debugPrint('⚠️ User not logged in, skipping FCM token save');
  }
}

final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  debugPrint('🚀 Initializing Queless app...');

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await SupabaseConfig.initialize();
  debugPrint('✅ Supabase initialized');

  try {
    await DatabaseTest().runAllTests();
  } catch (e) {
    debugPrint('⚠️  Database test failed: $e');
  }

  await AuthService().init();
  await ProductService().init();
  await StoreService().init();
  await CartService().init();
  await FoodCartService().init();
  await OrderService().init();

  if (AppConfig.enableNotifications) {
    debugPrint('🔔 Initializing Notifications...');
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission();

    // Get and save FCM token
    final token = await messaging.getToken();
    if (token != null) {
      debugPrint('FCM Token: $token');
      await _saveFcmToken(token);
    }

    // Listen for token refresh
    messaging.onTokenRefresh.listen((newToken) async {
      debugPrint('FCM Token Refreshed: $newToken');
      await _saveFcmToken(newToken);
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final context = _navigatorKey.currentContext;
      if (context == null) return;

      final data = message.data;
      final orderId = data['order_id'];
      final status = data['status'];

      if (orderId is String && status is String) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order $orderId status updated to $status'),
          ),
        );
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      final data = message.data;
      final orderId = data['order_id'];
      final source = data['source'] ?? 'orders';

      if (orderId is String && _navigatorKey.currentState != null) {
        _navigatorKey.currentState!.push(
          MaterialPageRoute(
            builder: (_) => OrderTrackingScreen(
              orderId: orderId,
              source: source == 'home'
                  ? OrderTrackingSource.home
                  : OrderTrackingSource.orders,
            ),
          ),
        );
      }
    });
  } else {
    debugPrint('🔕 Notifications are disabled in this environment');
  }

  debugPrint('✅ All services initialized');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'Queless',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.system,
      home: const AuthRouter(),
    );
  }
}
