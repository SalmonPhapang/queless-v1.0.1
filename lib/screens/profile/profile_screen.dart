import 'package:flutter/material.dart';
import 'package:queless/services/auth_service.dart';
import 'package:queless/screens/auth/welcome_screen.dart';
import 'package:queless/screens/profile/address_management_screen.dart';
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
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await _authService.signOut();
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const WelcomeScreen()), (route) => false);
    }
  }

  void _showLicenseInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('License Information'),
        content: SingleChildScrollView(
          child: Text(ComplianceHelper.licenseInfo),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
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
                      style: theme.textTheme.headlineMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user?.fullName ?? 'User', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(user?.email ?? '', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.7))),
                        const SizedBox(height: 8),
                        if (user?.ageVerified == true)
                          Row(
                            children: [
                              Icon(Icons.verified, size: 16, color: Colors.green),
                              const SizedBox(width: 6),
                              Text('Age Verified', style: theme.textTheme.bodySmall?.copyWith(color: Colors.green, fontWeight: FontWeight.bold)),
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
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddressManagementScreen())),
            ),
            ProfileMenuItem(
              icon: Icons.phone_outlined,
              title: 'Phone Number',
              subtitle: user?.phone ?? '',
            ),
            ProfileMenuItem(
              icon: Icons.info_outlined,
              title: 'About Queless',
              subtitle: 'Version 1.0.0',
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
                        children: ComplianceHelper.provinceRules.entries.map((entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(entry.key, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(entry.value['restrictions'] as String, style: theme.textTheme.bodySmall),
                            ],
                          ),
                        )).toList(),
                      ),
                    ),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
                    ],
                  ),
                );
              },
            ),
            ProfileMenuItem(
              icon: Icons.help_outline,
              title: 'Help & Support',
              subtitle: 'Get help with your orders',
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
        trailing: onTap != null ? const Icon(Icons.arrow_forward_ios, size: 16) : null,
        onTap: onTap,
      ),
    );
  }
}
