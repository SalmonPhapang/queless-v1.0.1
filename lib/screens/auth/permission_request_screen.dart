import 'package:flutter/material.dart';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:queless/screens/main_screen.dart';
import 'package:queless/services/auth_service.dart';
import 'package:queless/services/location_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PermissionRequestScreen extends StatefulWidget {
  const PermissionRequestScreen({super.key});

  @override
  State<PermissionRequestScreen> createState() =>
      _PermissionRequestScreenState();
}

class _PermissionRequestScreenState extends State<PermissionRequestScreen> {
  bool _isLocationGranted = false;
  bool _isNotificationsGranted = false;
  bool _isLoading = true;
  final _authService = AuthService();
  final _locationService = LocationService();

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final locationGranted = await _locationService.hasPermission();
    final notificationSettings =
        await FirebaseMessaging.instance.getNotificationSettings();

    if (mounted) {
      setState(() {
        _isLocationGranted = locationGranted;
        _isNotificationsGranted = notificationSettings.authorizationStatus ==
            AuthorizationStatus.authorized;
        _isLoading = false;
      });

      // If both are already granted, proceed automatically
      if (_isLocationGranted && _isNotificationsGranted) {
        _proceedToMain();
      }
    }
  }

  Future<void> _requestLocation() async {
    final granted = await _locationService.requestPermission();
    if (granted) {
      setState(() => _isLocationGranted = true);
    }
    _checkAndProceed();
  }

  Future<void> _requestNotifications() async {
    // Request FCM permission
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Also request local notifications permission for Android 13+
    if (Platform.isAndroid) {
      final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      setState(() => _isNotificationsGranted = true);
      // Sync token if permission granted
      await _authService.syncFcmToken();
    }
    _checkAndProceed();
  }

  void _checkAndProceed() {
    if (_isLocationGranted && _isNotificationsGranted) {
      _proceedToMain();
    }
  }

  Future<void> _proceedToMain() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('permissions_requested', true);

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              Text(
                'Help us serve you better',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'To provide the best delivery experience, we need a few permissions.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 48),

              // Location Permission
              _PermissionTile(
                icon: Icons.location_on_outlined,
                title: 'Location Access',
                description:
                    'We use your location to find nearby stores and track your delivery in real-time.',
                isGranted: _isLocationGranted,
                onPressed: _requestLocation,
              ),

              const SizedBox(height: 24),

              // Notifications Permission
              _PermissionTile(
                icon: Icons.notifications_none_outlined,
                title: 'Notifications',
                description:
                    'Stay updated on your order status, driver arrival, and exclusive local deals.',
                isGranted: _isNotificationsGranted,
                onPressed: _requestNotifications,
              ),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: (_isLocationGranted && _isNotificationsGranted)
                      ? _proceedToMain
                      : null,
                  child: const Text('Continue'),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _PermissionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool isGranted;
  final VoidCallback onPressed;

  const _PermissionTile({
    required this.icon,
    required this.title,
    required this.description,
    required this.isGranted,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isGranted
              ? Colors.green.withValues(alpha: 0.5)
              : theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isGranted
                  ? Colors.green.withValues(alpha: 0.1)
                  : theme.colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isGranted ? Icons.check : icon,
              color: isGranted ? Colors.green : theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                if (!isGranted) ...[
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: onPressed,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Allow Access'),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
