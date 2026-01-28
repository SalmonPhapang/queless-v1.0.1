import 'package:flutter/material.dart';
import 'package:queless/services/auth_service.dart';
import 'package:queless/screens/main_screen.dart';
import 'package:queless/utils/compliance_helper.dart';

class AgeVerificationScreen extends StatefulWidget {
  const AgeVerificationScreen({super.key});

  @override
  State<AgeVerificationScreen> createState() => _AgeVerificationScreenState();
}

class _AgeVerificationScreenState extends State<AgeVerificationScreen> {
  bool _isLoading = false;
  bool _agreeToTerms = false;
  final _authService = AuthService();

  Future<void> _handleVerification() async {
    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please confirm you are 18 years or older')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.verifyAge('verified_by_declaration');
      
      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainScreen()));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Theme.of(context).colorScheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Age Verification')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.verified_user_outlined, size: 80, color: theme.colorScheme.primary),
              const SizedBox(height: 24),
              Text(
                'Age Verification Required',
                style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                'According to South African law, you must be 18 years or older to purchase alcohol.',
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.colorScheme.error.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    Icon(Icons.warning_amber_rounded, size: 48, color: theme.colorScheme.error),
                    const SizedBox(height: 16),
                    Text(
                      'Important Legal Notice',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.error,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      ComplianceHelper.responsibleDrinkingMessages[0],
                      style: theme.textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              CheckboxListTile(
                value: _agreeToTerms,
                onChanged: (value) => setState(() => _agreeToTerms = value ?? false),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(
                  'I confirm that I am 18 years or older and agree to comply with South African liquor laws',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleVerification,
                  child: _isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Verify Age'),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Note: For your first alcohol purchase, you may be required to present valid South African ID for age verification during delivery.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
