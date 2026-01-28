import 'package:flutter/material.dart';
import 'package:queless/models/user.dart';
import 'package:queless/auth/supabase_auth_manager.dart';

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
      final user = await _authManager.createAccountWithEmail(context, email, password);
      debugPrint('   Auth account result: ${user != null ? "Success (userId: ${user.id})" : "Failed or needs confirmation"}');

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
