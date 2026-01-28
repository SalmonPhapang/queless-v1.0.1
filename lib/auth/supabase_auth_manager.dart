import 'package:flutter/material.dart';
import 'package:queless/auth/auth_manager.dart';
import 'package:queless/models/user.dart' as app_models;
import 'package:queless/supabase/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseAuthManager extends AuthManager with EmailSignInManager {
  static final SupabaseAuthManager _instance = SupabaseAuthManager._internal();
  factory SupabaseAuthManager() => _instance;
  SupabaseAuthManager._internal();

  app_models.User? _currentUser;
  app_models.User? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  
  // Store pending user data for profile creation after auth
  Map<String, String>? _pendingUserData;

  Future<void> init() async {
    final session = SupabaseConfig.auth.currentSession;
    if (session != null) {
      await _loadUserData(session.user.id);
    }

    SupabaseConfig.auth.onAuthStateChange.listen((data) async {
      final session = data.session;
      if (session == null) {
        _currentUser = null;
      } else if (_currentUser == null) {
        // User just logged in, try to load their data
        await _loadUserData(session.user.id);
      }
    });
  }

  @override
  Future<app_models.User?> createAccountWithEmail(
    BuildContext context,
    String email,
    String password,
  ) async {
    debugPrint('SupabaseAuthManager.createAccountWithEmail called');
    try {
      debugPrint('Calling SupabaseConfig.auth.signUp...');
      final response = await SupabaseConfig.auth.signUp(
        email: email,
        password: password,
        emailRedirectTo: null,
      );
      debugPrint('SupabaseConfig.auth.signUp response: ${response.user?.id}');

      if (response.user == null) {
        throw Exception('Failed to create account. Please try again.');
      }

      // Check if we have a session (email confirmation disabled)
      if (response.session != null) {
        debugPrint('Session available, user is signed in, userId: ${response.user!.id}');
        // Return the user ID so we can create the profile next
        return app_models.User(
          id: response.user!.id,
          email: email,
          phone: '',
          fullName: '',
          ageVerified: false,
          addresses: [],
          favoriteProducts: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      } else {
        debugPrint('No session - email confirmation required');
        // Email confirmation is enabled - inform user
        return null;
      }
    } catch (e) {
      debugPrint('Error creating account: $e');
      if (e.toString().contains('already registered') || e.toString().contains('already been registered')) {
        throw Exception('This email is already registered. Please sign in instead.');
      }
      rethrow;
    }
  }

  @override
  Future<app_models.User?> signInWithEmail(
    BuildContext context,
    String email,
    String password,
  ) async {
    try {
      debugPrint('SupabaseAuthManager.signInWithEmail - attempting login for: $email');
      final response = await SupabaseConfig.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw Exception('Failed to sign in');
      }

      debugPrint('✅ Auth successful for userId: ${response.user!.id}');
      await _loadUserData(response.user!.id);
      
      if (_currentUser == null) {
        debugPrint('⚠️  No user profile found, but auth succeeded');
        throw Exception('Account found but profile missing. Please contact support.');
      }
      
      debugPrint('✅ User profile loaded: ${_currentUser!.fullName}');
      return _currentUser;
    } catch (e) {
      debugPrint('❌ Error signing in: $e');
      if (e.toString().contains('Invalid login credentials')) {
        throw Exception('Invalid email or password. Please try again.');
      }
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await SupabaseConfig.auth.signOut();
      _currentUser = null;
    } catch (e) {
      debugPrint('Error signing out: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteUser(BuildContext context) async {
    try {
      final user = SupabaseConfig.auth.currentUser;
      if (user == null) return;

      await SupabaseService.delete('users', filters: {'id': user.id});
      _currentUser = null;
    } catch (e) {
      debugPrint('Error deleting user: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateEmail({
    required String email,
    required BuildContext context,
  }) async {
    try {
      await SupabaseConfig.auth.updateUser(UserAttributes(email: email));
      if (_currentUser != null) {
        final updatedUser = _currentUser!.copyWith(
          email: email,
          updatedAt: DateTime.now(),
        );
        await _updateUserData(updatedUser);
      }
    } catch (e) {
      debugPrint('Error updating email: $e');
      rethrow;
    }
  }

  @override
  Future<void> resetPassword({
    required String email,
    required BuildContext context,
  }) async {
    try {
      await SupabaseConfig.auth.resetPasswordForEmail(email);
    } catch (e) {
      debugPrint('Error resetting password: $e');
      rethrow;
    }
  }

  Future<void> createUserProfile({
    required String phone,
    required String fullName,
  }) async {
    try {
      final authUser = SupabaseConfig.auth.currentUser;
      if (authUser == null) {
        debugPrint('No authenticated user found, cannot create profile');
        throw Exception('No authenticated user. Please try signing up again.');
      }

      final now = DateTime.now();
      final userData = {
        'id': authUser.id,
        'email': authUser.email ?? '',
        'phone': phone,
        'full_name': fullName,
        'age_verified': false,
        'addresses': <dynamic>[],
        'favorite_products': <String>[],
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      };

      debugPrint('Creating user profile for: ${authUser.id}');
      await SupabaseService.insert('users', userData);
      debugPrint('User profile created successfully');
      await _loadUserData(authUser.id);
    } catch (e) {
      debugPrint('Error creating user profile: $e');
      if (e.toString().contains('users') && e.toString().contains('does not exist')) {
        throw Exception('Database setup required. Please contact support.');
      }
      rethrow;
    }
  }

  Future<void> _loadUserData(String userId) async {
    try {
      debugPrint('Loading user data for: $userId');
      final data = await SupabaseService.selectSingle(
        'users',
        filters: {'id': userId},
      );

      if (data != null) {
        _currentUser = app_models.User.fromJson(data);
        debugPrint('User data loaded: ${_currentUser?.fullName}');
      } else {
        debugPrint('No user profile found for: $userId');
        _currentUser = null;
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
      _currentUser = null;
    }
  }

  Future<void> _updateUserData(app_models.User user) async {
    try {
      await SupabaseService.update(
        'users',
        user.toJson(),
        filters: {'id': user.id},
      );
      _currentUser = user;
    } catch (e) {
      debugPrint('Error updating user data: $e');
      rethrow;
    }
  }

  Future<void> updateUser(app_models.User user) async {
    await _updateUserData(user);
  }

  Future<void> verifyAge(String idDocumentUrl) async {
    if (_currentUser == null) return;

    final updatedUser = _currentUser!.copyWith(
      ageVerified: true,
      idDocumentUrl: idDocumentUrl,
      updatedAt: DateTime.now(),
    );

    await updateUser(updatedUser);
  }

  Future<void> addAddress(app_models.Address address) async {
    if (_currentUser == null) return;

    final addresses = List<app_models.Address>.from(_currentUser!.addresses);

    if (address.isDefault) {
      for (var i = 0; i < addresses.length; i++) {
        if (addresses[i].isDefault) {
          addresses[i] = addresses[i].copyWith(isDefault: false);
        }
      }
    }

    addresses.add(address);

    final updatedUser = _currentUser!.copyWith(
      addresses: addresses,
      updatedAt: DateTime.now(),
    );

    await updateUser(updatedUser);
  }

  Future<void> updateAddress(app_models.Address address) async {
    if (_currentUser == null) return;

    final addresses = List<app_models.Address>.from(_currentUser!.addresses);
    final index = addresses.indexWhere((a) => a.id == address.id);

    if (index != -1) {
      if (address.isDefault) {
        for (var i = 0; i < addresses.length; i++) {
          if (i != index && addresses[i].isDefault) {
            addresses[i] = addresses[i].copyWith(isDefault: false);
          }
        }
      }

      addresses[index] = address;

      final updatedUser = _currentUser!.copyWith(
        addresses: addresses,
        updatedAt: DateTime.now(),
      );

      await updateUser(updatedUser);
    }
  }

  Future<void> deleteAddress(String addressId) async {
    if (_currentUser == null) return;

    final addresses = _currentUser!.addresses.where((a) => a.id != addressId).toList();

    final updatedUser = _currentUser!.copyWith(
      addresses: addresses,
      updatedAt: DateTime.now(),
    );

    await updateUser(updatedUser);
  }

  Future<void> toggleFavorite(String productId) async {
    if (_currentUser == null) return;

    final favorites = List<String>.from(_currentUser!.favoriteProducts);

    if (favorites.contains(productId)) {
      favorites.remove(productId);
    } else {
      favorites.add(productId);
    }

    final updatedUser = _currentUser!.copyWith(
      favoriteProducts: favorites,
      updatedAt: DateTime.now(),
    );

    await updateUser(updatedUser);
  }
}
