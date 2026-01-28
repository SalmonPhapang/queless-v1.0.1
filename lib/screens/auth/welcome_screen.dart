import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:queless/screens/auth/login_screen.dart';
import 'package:queless/screens/auth/signup_screen.dart';
import 'package:queless/services/auth_service.dart';
import 'package:queless/services/cart_service.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  int _tapCount = 0;

  Future<void> _clearAllData() async {
    try {
      debugPrint('🗑️  Clearing all app data for testing...');
      
      // Clear SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      debugPrint('✅ SharedPreferences cleared');
      
      // Clear cart
      await CartService().clearCart();
      debugPrint('✅ Cart cleared');
      
      // Sign out
      await AuthService().signOut();
      debugPrint('✅ User signed out');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All data cleared! App reset for testing.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error clearing data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const Spacer(),
              GestureDetector(
                onTap: () {
                  _tapCount++;
                  if (_tapCount >= 5) {
                    _tapCount = 0;
                    _clearAllData();
                  }
                },
                child: Icon(Icons.local_bar, size: 80, color: theme.colorScheme.primary),
              ),
              const SizedBox(height: 24),
              Text(
                'Queless',
                style: theme.textTheme.displaySmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Your Premium Delivery Partner',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Fast, legal, and reliable food & beverage delivery across South Africa',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SignupScreen())),
                  child: const Text('Create Account'),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
                  child: const Text('Sign In'),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                '18+ Only • Drink Responsibly',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
