import 'package:flutter/material.dart';
import 'package:queless/services/auth_service.dart';
import 'package:queless/screens/auth/welcome_screen.dart';
import 'package:queless/screens/profile/address_management_screen.dart';
import 'package:queless/screens/profile/faq_screen.dart';
import 'package:queless/services/theme_service.dart';
import 'package:queless/utils/compliance_helper.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authService = AuthService();

  Future<void> _handleSignOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await _authService.signOut();
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const WelcomeScreen()),
          (route) => false);
    }
  }

  Future<void> _handleDeleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title:
            const Text('Delete Account', style: TextStyle(color: Colors.red)),
        content: const Text(
          'Are you sure you want to delete your account? This action is permanent and all your data will be removed.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete Account'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await _authService.deleteAccount(context);
        if (mounted) {
          Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const WelcomeScreen()),
              (route) => false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Account deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete account: $e')),
          );
        }
      }
    }
  }

  void _showLicenseInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('License Information'),
        content: const SingleChildScrollView(
          child: Text(ComplianceHelper.licenseInfo),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close')),
        ],
      ),
    );
  }

  void _showLegalDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Text(content),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = _authService.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: theme.colorScheme.primary,
                    child: Text(
                      user?.fullName.substring(0, 1).toUpperCase() ?? 'U',
                      style: theme.textTheme.headlineMedium?.copyWith(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user?.fullName ?? 'User',
                            style: theme.textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(user?.email ?? '',
                            style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.7))),
                        const SizedBox(height: 8),
                        if (user?.ageVerified == true)
                          Row(
                            children: [
                              const Icon(Icons.verified,
                                  size: 16, color: Colors.green),
                              const SizedBox(width: 6),
                              Text('Age Verified',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            ProfileMenuItem(
              icon: Icons.location_on_outlined,
              title: 'My Addresses',
              subtitle: '${user?.addresses.length ?? 0} saved addresses',
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const AddressManagementScreen())),
            ),
            AnimatedBuilder(
              animation: ThemeService(),
              builder: (context, _) {
                final themeService = ThemeService();
                return ProfileMenuItem(
                  icon: themeService.isDarkMode
                      ? Icons.dark_mode
                      : Icons.light_mode,
                  title: 'App Theme',
                  subtitle: themeService.themeMode == ThemeMode.system
                      ? 'System Default'
                      : themeService.isDarkMode
                          ? 'Dark Mode'
                          : 'Light Mode',
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: const Text('Select Theme'),
                          content: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                RadioListTile<ThemeMode>(
                                  title: const Text('System Default'),
                                  value: ThemeMode.system,
                                  groupValue: themeService.themeMode,
                                  onChanged: (mode) {
                                    if (mode != null) {
                                      themeService.setThemeMode(mode);
                                    }
                                    Navigator.pop(context);
                                  },
                                ),
                                RadioListTile<ThemeMode>(
                                  title: const Text('Light Mode'),
                                  value: ThemeMode.light,
                                  groupValue: themeService.themeMode,
                                  onChanged: (mode) {
                                    if (mode != null) {
                                      themeService.setThemeMode(mode);
                                    }
                                    Navigator.pop(context);
                                  },
                                ),
                                RadioListTile<ThemeMode>(
                                  title: const Text('Dark Mode'),
                                  value: ThemeMode.dark,
                                  groupValue: themeService.themeMode,
                                  onChanged: (mode) {
                                    if (mode != null) {
                                      themeService.setThemeMode(mode);
                                    }
                                    Navigator.pop(context);
                                  },
                                ),
                              ],
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                );
              },
            ),
            ProfileMenuItem(
              icon: Icons.phone_outlined,
              title: 'Phone Number',
              subtitle: user?.phone ?? '',
            ),
            const ProfileMenuItem(
              icon: Icons.info_outlined,
              title: 'About Queless',
              subtitle: 'Version 1.0.0',
            ),
            ProfileMenuItem(
              icon: Icons.privacy_tip_outlined,
              title: 'Privacy Policy',
              subtitle: 'Read our privacy policy',
              onTap: () => _showLegalDialog(
                  'Privacy Policy', ComplianceHelper.privacyPolicy),
            ),
            ProfileMenuItem(
              icon: Icons.description_outlined,
              title: 'Terms of Service',
              subtitle: 'Read our terms of service',
              onTap: () => _showLegalDialog(
                  'Terms of Service', ComplianceHelper.termsOfService),
            ),
            ProfileMenuItem(
              icon: Icons.gavel_outlined,
              title: 'License Information',
              subtitle: 'View our liquor licenses',
              onTap: _showLicenseInfo,
            ),
            ProfileMenuItem(
              icon: Icons.policy_outlined,
              title: 'Trading Hours',
              subtitle: 'View provincial restrictions',
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Provincial Trading Hours'),
                    content: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: ComplianceHelper.provinceRules.entries
                            .map((entry) => Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(entry.key,
                                          style: theme.textTheme.titleSmall
                                              ?.copyWith(
                                                  fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 4),
                                      Text(
                                          entry.value['restrictions'] as String,
                                          style: theme.textTheme.bodySmall),
                                    ],
                                  ),
                                ))
                            .toList(),
                      ),
                    ),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Close')),
                    ],
                  ),
                );
              },
            ),
            ProfileMenuItem(
              icon: Icons.help_outline,
              title: 'Help & Support',
              subtitle: 'Get help with your orders',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FAQScreen()),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _handleSignOut,
                icon: const Icon(Icons.logout),
                label: const Text('Sign Out'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                  side: BorderSide(color: theme.colorScheme.error, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: _handleDeleteAccount,
                icon: const Icon(Icons.delete_forever),
                label: const Text('Delete Account'),
                style: TextButton.styleFrom(
                  foregroundColor:
                      theme.colorScheme.error.withValues(alpha: 0.7),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  const ProfileMenuItem({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: subtitle != null ? Text(subtitle!) : null,
        trailing: onTap != null
            ? const Icon(Icons.arrow_forward_ios, size: 16)
            : null,
        onTap: onTap,
      ),
    );
  }
}
