import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:queless/theme.dart';
import 'package:queless/supabase/supabase_config.dart';
import 'package:queless/services/auth_service.dart';
import 'package:queless/services/product_service.dart';
import 'package:queless/services/cart_service.dart';
import 'package:queless/services/food_cart_service.dart';
import 'package:queless/services/store_service.dart';
import 'package:queless/services/order_service.dart';
import 'package:queless/services/theme_service.dart';
import 'package:queless/router/auth_router.dart';
import 'package:queless/utils/database_test.dart';
import 'package:queless/config/app_config.dart';
import 'package:queless/screens/orders/order_tracking_screen.dart';

final FlutterLocalNotificationsPlugin _localNotifications =
    FlutterLocalNotificationsPlugin();

const String _androidNotificationChannelId = 'high_importance_channel';
const String _androidNotificationChannelName = 'High Importance Notifications';
const String _androidNotificationChannelDescription =
    'Used for important notifications.';

const AndroidNotificationChannel _androidNotificationChannel =
    AndroidNotificationChannel(
  _androidNotificationChannelId,
  _androidNotificationChannelName,
  description: _androidNotificationChannelDescription,
  importance: Importance.high,
  playSound: true,
  enableVibration: true,
  showBadge: true,
);

@pragma('vm:entry-point')
Future<void> _initLocalNotifications() async {
  const initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const initializationSettingsIOS = DarwinInitializationSettings();
  const initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS,
  );

  await _localNotifications.initialize(initializationSettings);

  final androidImplementation =
      _localNotifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
  await androidImplementation?.createNotificationChannel(
    _androidNotificationChannel,
  );
}

@pragma('vm:entry-point')
Future<void> _showLocalNotification(RemoteMessage message) async {
  final notification = message.notification;
  final data = message.data;

  String? title = notification?.title ?? data['title']?.toString();
  String? body = notification?.body ?? data['body']?.toString();

  // If title/body are missing but we have order data, generate a default message
  if (title == null || title.isEmpty) {
    if (data.containsKey('order_id')) {
      title = 'Order Update';
    } else {
      title = 'Queless';
    }
  }

  if (body == null || body.isEmpty) {
    if (data.containsKey('status') && data.containsKey('order_id')) {
      switch (data['status']) {
        case 'assigned':
          body = 'Order has been assigned to a driver';
          break;
        case 'picked_up':
          body = 'Order has been picked up, and driver is on the way';
          break;
        case 'delivered':
          body = 'Order has been delivered, enjoy!';
          break;
        case 'cancelled':
          body = 'Order has been cancelled';
          break;
        default:
          body = 'Order is now in ${data['status']} status';
      }
    } else if (data.containsKey('message')) {
      body = data['message'].toString();
    } else {
      // Don't show empty notifications
      if (notification == null && data.isEmpty) return;
      body = 'You have a new update';
    }
  }

  await _localNotifications.show(
    message.hashCode,
    title ?? 'Queless',
    body ?? '',
    const NotificationDetails(
      android: AndroidNotificationDetails(
        _androidNotificationChannelId,
        _androidNotificationChannelName,
        channelDescription: _androidNotificationChannelDescription,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        channelShowBadge: true,
        enableVibration: true,
        playSound: true,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    ),
    payload: jsonEncode(data),
  );
}

Future<void> _fetchAndSaveFcmTokenWithRetry({
  required FirebaseMessaging messaging,
  int maxAttempts = 5,
}) async {
  for (var attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      await messaging.setAutoInitEnabled(true);
      final token = await messaging.getToken();
      if (token != null && token.isNotEmpty) {
        debugPrint('FCM Token: $token');
        await _saveFcmToken(token);
      }
      return;
    } catch (e) {
      debugPrint(
          '⚠️ Failed to get FCM token (attempt $attempt/$maxAttempts): $e');
      if (attempt == maxAttempts) return;
      final delaySeconds = attempt * attempt;
      await Future.delayed(Duration(seconds: delaySeconds));
    }
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await _initLocalNotifications();
  await _showLocalNotification(message);
}

/// Helper to save FCM token to Supabase for the current user
Future<void> _saveFcmToken(String token) async {
  final user = AuthService().currentUser;
  if (user != null) {
    try {
      debugPrint('📝 Saving FCM token for user ${user.id}...');
      final existingRows = await SupabaseService.select(
        'user_fcm_tokens',
        filters: {'user_id': user.id},
        orderBy: 'updated_at',
        ascending: false,
        limit: 1,
      );

      final now = DateTime.now().toIso8601String();

      if (existingRows.isEmpty) {
        await SupabaseService.insert(
          'user_fcm_tokens',
          {
            'user_id': user.id,
            'token': token,
            'updated_at': now,
          },
        );
      } else {
        final existingToken = existingRows.first['token']?.toString() ?? '';

        if (existingToken == token) {
          await SupabaseService.update(
            'user_fcm_tokens',
            {'updated_at': now},
            filters: {'user_id': user.id, 'token': token},
          );
        } else {
          try {
            await SupabaseService.update(
              'user_fcm_tokens',
              {'token': token, 'updated_at': now},
              filters: {'user_id': user.id, 'token': existingToken},
            );
          } catch (_) {
            await SupabaseService.update(
              'user_fcm_tokens',
              {'updated_at': now},
              filters: {'user_id': user.id, 'token': token},
            );
          }
        }
      }
      debugPrint('✅ FCM Token saved to Supabase');
    } catch (e) {
      debugPrint('❌ Failed to save FCM token: $e');
    }
  } else {
    debugPrint('⚠️ User not logged in, skipping FCM token save');
  }
}

final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

Future<void> _applyFullscreenSystemUi() async {
  if (kIsWeb) return;
  try {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
    );
  } catch (e) {
    debugPrint('Failed to apply fullscreen system UI: $e');
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  debugPrint('🚀 Initializing Queless app...');

  await _applyFullscreenSystemUi();

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
  await ThemeService().init();

  if (AppConfig.enableNotifications) {
    debugPrint('🔔 Initializing Notifications...');
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    final messaging = FirebaseMessaging.instance;
    await _initLocalNotifications();

    // Enable foreground notifications for iOS
    await messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Check if we already have permission before fetching token
    final settings = await messaging.getNotificationSettings();
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      await _fetchAndSaveFcmTokenWithRetry(messaging: messaging);
    }

    // Listen for token refresh
    messaging.onTokenRefresh.listen((newToken) async {
      debugPrint('FCM Token Refreshed: $newToken');
      await _saveFcmToken(newToken);
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showLocalNotification(message);
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

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _applyFullscreenSystemUi();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _applyFullscreenSystemUi();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeService(),
      builder: (context, _) {
        return MaterialApp(
          navigatorKey: _navigatorKey,
          title: 'Queless',
          debugShowCheckedModeBanner: false,
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: ThemeService().themeMode,
          home: const AuthRouter(),
        );
      },
    );
  }
}
