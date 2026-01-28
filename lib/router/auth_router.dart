import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:queless/screens/auth/welcome_screen.dart';
import 'package:queless/screens/auth/age_verification_screen.dart';
import 'package:queless/screens/main_screen.dart';
import 'package:queless/screens/onboarding/onboarding_screen.dart';
import 'package:queless/services/auth_service.dart';

class AuthRouter extends StatefulWidget {
  const AuthRouter({super.key});

  @override
  State<AuthRouter> createState() => _AuthRouterState();
}

class _AuthRouterState extends State<AuthRouter> {
  bool _isLoading = true;
  Widget? _initialRoute;
  final _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _determineInitialRoute();
  }

  Future<void> _determineInitialRoute() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Check if user is authenticated via Supabase/AuthService
      final isLoggedIn = _authService.isLoggedIn;
      debugPrint('🔀 Auth Router - isLoggedIn: $isLoggedIn');

      if (!isLoggedIn) {
        // Not authenticated: always show welcome screen
        _initialRoute = const WelcomeScreen();
        return;
      }

      final user = _authService.currentUser;

      // Authenticated: decide between onboarding and main app
      final onboardingComplete = prefs.getBool('onboarding_complete') ?? false;
      debugPrint('🔀 Auth Router - onboardingComplete: $onboardingComplete');

      if (!onboardingComplete) {
        _initialRoute = const OnboardingScreen();
      } else if (user != null && !user.ageVerified) {
        _initialRoute = const AgeVerificationScreen();
      } else {
        _initialRoute = const MainScreen();
      }
    } catch (e) {
      debugPrint('Error determining initial route: $e');
      _initialRoute = const MainScreen();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return _initialRoute ?? const MainScreen();
  }
}
