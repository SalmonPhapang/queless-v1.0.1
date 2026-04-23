import 'dart:io';
import 'package:flutter/material.dart';
import 'package:queless/logger.dart';
import 'package:queless/services/connectivity_service.dart';
import 'package:queless/supabase/supabase_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateDialog extends StatelessWidget {
  final AppUpdateInfo updateInfo;
  final VoidCallback onUpdate;
  final VoidCallback onDismiss;

  const UpdateDialog({
    super.key,
    required this.updateInfo,
    required this.onUpdate,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isForceUpdate = updateInfo.isForceUpdate;

    return PopScope(
      canPop: !isForceUpdate,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && isForceUpdate) {
          onDismiss();
        }
      },
      child: AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.system_update,
              color: theme.colorScheme.primary,
              size: 28,
            ),
            const SizedBox(width: 12),
            const Text('App Update Available'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Version ${updateInfo.latestVersion} is now available.',
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              updateInfo.releaseNotes ??
                  'A new version of the app is available. Please update to the latest version for the best experience.',
              style: theme.textTheme.bodyMedium,
            ),
            if (!isForceUpdate) ...[
              const SizedBox(height: 8),
              Text(
                'You can update now or skip this version.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (!isForceUpdate)
            TextButton(
              onPressed: onDismiss,
              child: const Text('Skip'),
            ),
          FilledButton(
            onPressed: onUpdate,
            child: Text(isForceUpdate ? 'Update Now' : 'Update'),
          ),
        ],
      ),
    );
  }
}

class AppUpdateService {
  static final AppUpdateService _instance = AppUpdateService._internal();
  factory AppUpdateService() => _instance;
  AppUpdateService._internal();

  static const String _androidVersionTable = 'app_versions';
  static const String _prefKeyVersion = 'app_version';
  static const String _prefKeyBuildNumber = 'app_build_number';

  Future<void> saveCurrentVersionInfo(String version, int buildNumber) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKeyVersion, version);
      await prefs.setInt(_prefKeyBuildNumber, buildNumber);
      Logger.debug('💾 Saved version info: $version ($buildNumber)');
    } catch (e) {
      Logger.debug('❌ Error saving version info: $e');
    }
  }

  Future<Map<String, dynamic>> _getCurrentPackageInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final version = prefs.getString(_prefKeyVersion);
      final buildNumber = prefs.getInt(_prefKeyBuildNumber);

      if (version != null && buildNumber != null) {
        Logger.debug('📱 Loaded version from prefs: $version ($buildNumber)');
        return {
          'version': version,
          'buildNumber': buildNumber,
        };
      }
    } catch (e) {
      Logger.debug('❌ Error reading version from prefs: $e');
    }

    return {
      'version': '1.0.0',
      'buildNumber': 1,
    };
  }

  Future<AppUpdateInfo?> checkForUpdate() async {
    if (!ConnectivityService().isConnected) {
      Logger.debug('⚠️ No internet connection, skipping update check');
      return null;
    }

    try {
      final packageInfo = await _getCurrentPackageInfo();
      final currentVersion = packageInfo['version'] as String;
      final currentBuildNumber = packageInfo['buildNumber'] as int;

      Logger.debug('📱 Current version: $currentVersion ($currentBuildNumber)');

      final latestVersionInfo = await _fetchLatestVersionFromDb();

      if (latestVersionInfo == null) {
        Logger.debug('ℹ️ No update info found in database');
        return null;
      }

      final latestVersion = latestVersionInfo['version'] as String;
      final latestBuildNumber = latestVersionInfo['build_number'] as int;
      final minBuildNumber = latestVersionInfo['min_build_number'] as int? ?? 0;
      final releaseNotes = latestVersionInfo['release_notes'] as String?;
      final isActive = latestVersionInfo['is_active'] as bool? ?? true;

      if (!isActive) {
        Logger.debug('ℹ️ No active update found');
        return null;
      }

      if (latestBuildNumber > currentBuildNumber) {
        final isForceUpdate = minBuildNumber > currentBuildNumber;
        Logger.debug(
            '📱 Update available: $latestVersion ($latestBuildNumber). Force: $isForceUpdate');

        return AppUpdateInfo(
          currentVersion: currentVersion,
          currentBuildNumber: currentBuildNumber,
          latestVersion: latestVersion,
          latestBuildNumber: latestBuildNumber,
          releaseNotes: releaseNotes,
          isForceUpdate: isForceUpdate,
          downloadUrl: latestVersionInfo['download_url'] as String?,
        );
      }

      Logger.debug('ℹ️ App is up to date');

      await saveCurrentVersionInfo(latestVersion, latestBuildNumber);

      return null;
    } catch (e) {
      Logger.debug('❌ Error checking for update: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> _fetchLatestVersionFromDb() async {
    try {
      final data = await SupabaseService.select(
        _androidVersionTable,
        orderBy: 'build_number',
        ascending: false,
        limit: 1,
      );

      if (data.isNotEmpty) {
        final versionInfo = data.first;
        final version = versionInfo['version'] as String;
        final buildNumber = versionInfo['build_number'] as int;

        await saveCurrentVersionInfo(version, buildNumber);

        return versionInfo;
      }
    } catch (e) {
      Logger.debug('❌ Error fetching version info: $e');
    }
    return null;
  }

  Future<void> showUpdateDialogIfNeeded(BuildContext context) async {
    final updateInfo = await checkForUpdate();
    if (updateInfo == null) return;

    if (!context.mounted) return;

    final result = await showDialog<AppUpdateResult>(
      context: context,
      barrierDismissible: !updateInfo.isForceUpdate,
      builder: (context) => UpdateDialog(
        updateInfo: updateInfo,
        onUpdate: () => Navigator.of(context).pop(AppUpdateResult.update),
        onDismiss: () => Navigator.of(context).pop(AppUpdateResult.skip),
      ),
    );

    if (result == AppUpdateResult.update) {
      await launchAppStore();
    } else if (result == AppUpdateResult.skip) {
      Logger.debug('ℹ️ User skipped update ${updateInfo.latestVersion}');
    }
  }

  Future<void> launchAppStore() async {
    const androidPackageName = 'com.queless.app';
    final androidUrl = Uri.parse(
        'https://play.google.com/store/apps/details?id=$androidPackageName');
    final iosUrl = Uri.parse('https://apps.apple.com/app/idYOUR_IOS_APP_ID');

    try {
      if (Platform.isAndroid) {
        final installed = await canLaunchUrl(androidUrl);
        if (installed) {
          await launchUrl(androidUrl, mode: LaunchMode.externalApplication);
        }
      } else if (Platform.isIOS) {
        final installed = await canLaunchUrl(iosUrl);
        if (installed) {
          await launchUrl(iosUrl, mode: LaunchMode.externalApplication);
        }
      }
    } catch (e) {
      Logger.debug('❌ Error launching app store: $e');
    }
  }
}

class AppUpdateInfo {
  final String currentVersion;
  final int currentBuildNumber;
  final String latestVersion;
  final int latestBuildNumber;
  final String? releaseNotes;
  final bool isForceUpdate;
  final String? downloadUrl;

  AppUpdateInfo({
    required this.currentVersion,
    required this.currentBuildNumber,
    required this.latestVersion,
    required this.latestBuildNumber,
    this.releaseNotes,
    required this.isForceUpdate,
    this.downloadUrl,
  });
}

enum AppUpdateResult {
  update,
  skip,
}
