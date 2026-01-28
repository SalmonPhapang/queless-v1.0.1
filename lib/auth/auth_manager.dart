// Authentication Manager - Base interface for auth implementations
//
// This abstract class and mixins define the contract for authentication systems.
// Implement this with concrete classes for Firebase, Supabase, or local auth.
//
// Usage:
// 1. Create a concrete class extending AuthManager
// 2. Mix in the required authentication provider mixins
// 3. Implement all abstract methods with your auth provider logic

import 'package:flutter/material.dart';
import 'package:queless/models/user.dart' as app_models;

// Core authentication operations that all auth implementations must provide
abstract class AuthManager {
  Future signOut();
  Future deleteUser(BuildContext context);
  Future updateEmail({required String email, required BuildContext context});
  Future resetPassword({required String email, required BuildContext context});
  Future sendEmailVerification({required app_models.User user}) async {}
  Future refreshUser({required app_models.User user}) async {}
}

// Email/password authentication mixin
mixin EmailSignInManager on AuthManager {
  Future<app_models.User?> signInWithEmail(
    BuildContext context,
    String email,
    String password,
  );

  Future<app_models.User?> createAccountWithEmail(
    BuildContext context,
    String email,
    String password,
  );
}

// Anonymous authentication for guest users
mixin AnonymousSignInManager on AuthManager {
  Future<app_models.User?> signInAnonymously(BuildContext context);
}

// Apple Sign-In authentication (iOS/web)
mixin AppleSignInManager on AuthManager {
  Future<app_models.User?> signInWithApple(BuildContext context);
}

// Google Sign-In authentication (all platforms)
mixin GoogleSignInManager on AuthManager {
  Future<app_models.User?> signInWithGoogle(BuildContext context);
}

// JWT token authentication for custom backends
mixin JwtSignInManager on AuthManager {
  Future<app_models.User?> signInWithJwtToken(
    BuildContext context,
    String jwtToken,
  );
}

// Phone number authentication with SMS verification
mixin PhoneSignInManager on AuthManager {
  Future beginPhoneAuth({
    required BuildContext context,
    required String phoneNumber,
    required void Function(BuildContext) onCodeSent,
  });

  Future verifySmsCode({
    required BuildContext context,
    required String smsCode,
  });
}

// Facebook Sign-In authentication
mixin FacebookSignInManager on AuthManager {
  Future<app_models.User?> signInWithFacebook(BuildContext context);
}

// Microsoft Sign-In authentication (Azure AD)
mixin MicrosoftSignInManager on AuthManager {
  Future<app_models.User?> signInWithMicrosoft(
    BuildContext context,
    List<String> scopes,
    String tenantId,
  );
}

// GitHub Sign-In authentication (OAuth)
mixin GithubSignInManager on AuthManager {
  Future<app_models.User?> signInWithGithub(BuildContext context);
}
