import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:queless/config/app_config.dart';
import 'package:queless/models/user.dart';
import 'package:queless/auth/supabase_auth_manager.dart';
import 'package:queless/supabase/supabase_config.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final _authManager = SupabaseAuthManager();

  User? get currentUser => _authManager.currentUser;
  bool get isLoggedIn => _authManager.isLoggedIn;

  Future<void> init() async {
    await _authManager.init();
  }

  Future<void> syncFcmToken() async {
    final user = currentUser;
    if (user != null) {
      await _syncFcmTokenForUserId(user.id);
    }
  }

  Future<void> _syncFcmTokenForUserId(
    String userId, {
    int maxAttempts = 5,
  }) async {
    if (!AppConfig.enableNotifications) return;
    try {
      await FirebaseMessaging.instance.setAutoInitEnabled(true);

      String? token;
      Object? lastError;

      for (var attempt = 1; attempt <= maxAttempts; attempt++) {
        try {
          token = await FirebaseMessaging.instance.getToken();
          if (token != null && token.isNotEmpty) break;
        } catch (e) {
          lastError = e;
        }

        if (attempt < maxAttempts) {
          final delaySeconds = attempt * attempt;
          await Future.delayed(Duration(seconds: delaySeconds));
        }
      }

      if (token == null || token.isEmpty) {
        if (lastError != null) {
          debugPrint('Failed to sync FCM token after auth: $lastError');
        }
        return;
      }

      final existingRows = await SupabaseService.select(
        'user_fcm_tokens',
        filters: {'user_id': userId},
        orderBy: 'updated_at',
        ascending: false,
        limit: 1,
      );

      final now = DateTime.now().toIso8601String();

      if (existingRows.isEmpty) {
        await SupabaseService.insert(
          'user_fcm_tokens',
          {
            'user_id': userId,
            'token': token,
            'updated_at': now,
          },
        );
        return;
      }

      final existingToken = existingRows.first['token']?.toString() ?? '';

      if (existingToken == token) {
        await SupabaseService.update(
          'user_fcm_tokens',
          {'updated_at': now},
          filters: {'user_id': userId, 'token': token},
        );
        return;
      }

      try {
        await SupabaseService.update(
          'user_fcm_tokens',
          {'token': token, 'updated_at': now},
          filters: {'user_id': userId, 'token': existingToken},
        );
      } catch (_) {
        await SupabaseService.update(
          'user_fcm_tokens',
          {'updated_at': now},
          filters: {'user_id': userId, 'token': token},
        );
      }
    } catch (e) {
      debugPrint('Failed to sync FCM token after auth: $e');
    }
  }

  Future<User?> signUp({
    required BuildContext context,
    required String email,
    required String password,
    required String phone,
    required String fullName,
  }) async {
    try {
      debugPrint('\n🔐 AuthService.signUp START');
      debugPrint('   Email: $email');
      debugPrint('   Full Name: $fullName');

      // Step 1: Create auth account
      debugPrint('\n📝 Step 1: Creating auth account...');
      final user =
          await _authManager.createAccountWithEmail(context, email, password);
      debugPrint(
          '   Auth account result: ${user != null ? "Success (userId: ${user.id})" : "Failed or needs confirmation"}');

      // If user is returned, session is available (email confirmation disabled)
      if (user != null) {
        debugPrint('\n📝 Step 2: Creating user profile in database...');
        debugPrint('   Phone: $phone');
        debugPrint('   Full Name: $fullName');

        // Step 2: Create user profile in database
        await _authManager.createUserProfile(
          phone: phone,
          fullName: fullName,
        );

        final createdUser = _authManager.currentUser;
        if (createdUser != null) {
          debugPrint('\n✅ SIGNUP SUCCESS!');
          debugPrint('   User ID: ${createdUser.id}');
          debugPrint('   Full Name: ${createdUser.fullName}');
          debugPrint('   Email: ${createdUser.email}');
          await _syncFcmTokenForUserId(createdUser.id);
          return createdUser;
        } else {
          debugPrint('\n❌ Profile creation failed - currentUser is null');
          throw Exception('Failed to create user profile. Please try again.');
        }
      }

      // If null, email confirmation is required
      debugPrint('\n📧 Email confirmation required');
      return null;
    } catch (e) {
      debugPrint('\n❌ AuthService.signUp ERROR: $e');
      rethrow;
    }
  }

  Map<String, String>? _pendingSignupData;

  Future<User> signIn({
    required BuildContext context,
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('AuthService.signIn - email: $email');
      final user = await _authManager.signInWithEmail(context, email, password);

      if (user == null) {
        throw Exception('Login failed - no user data returned');
      }

      await _syncFcmTokenForUserId(user.id);
      debugPrint('✅ AuthService.signIn successful: ${user.fullName}');
      return user;
    } catch (e) {
      debugPrint('❌ AuthService.signIn error: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _authManager.signOut();
  }

  Future<void> deleteAccount(BuildContext context) async {
    await _authManager.deleteUser(context);
    await signOut();
  }

  Future<void> updateUser(User user) async {
    await _authManager.updateUser(user);
  }

  Future<void> verifyAge(String idDocumentUrl) async {
    await _authManager.verifyAge(idDocumentUrl);
  }

  Future<void> addAddress(Address address) async {
    await _authManager.addAddress(address);
  }

  Future<void> updateAddress(Address address) async {
    await _authManager.updateAddress(address);
  }

  Future<void> deleteAddress(String addressId) async {
    await _authManager.deleteAddress(addressId);
  }

  Future<void> toggleFavorite(String productId) async {
    await _authManager.toggleFavorite(productId);
  }
}
