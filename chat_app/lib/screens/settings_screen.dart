import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_theme.dart';
import '../main.dart';

/// Screen for app settings, including theme selection.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  ThemeMode _currentThemeMode = ThemeMode.system;
  PackageInfo? _packageInfo;
  bool _isLoadingVersion = true;

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
    // Get current theme mode from MyApp after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentMode = MyApp.themeModeOf(context);
      if (mounted && currentMode != null) {
        setState(() {
          _currentThemeMode = currentMode;
        });
      }
    });
  }

  Future<void> _loadPackageInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _packageInfo = packageInfo;
          _isLoadingVersion = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingVersion = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Update current theme mode if it changed
    final currentThemeMode = MyApp.themeModeOf(context) ?? ThemeMode.system;
    if (_currentThemeMode != currentThemeMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _currentThemeMode = currentThemeMode);
        }
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.spacingM,
              AppTheme.spacingL,
              AppTheme.spacingM,
              AppTheme.spacingS,
            ),
            child: Text(
              'Appearance',
              style: AppTheme.headingSmall.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          Card(
            margin: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingM,
              vertical: AppTheme.spacingS,
            ),
            child: Column(
              children: [
                RadioListTile<ThemeMode>(
                  title: const Text('System'),
                  subtitle: const Text('Follow system theme'),
                  value: ThemeMode.system,
                  groupValue: _currentThemeMode,
                  onChanged: (ThemeMode? value) {
                    if (value != null) {
                      _updateThemeMode(value);
                    }
                  },
                ),
                const Divider(height: 1),
                RadioListTile<ThemeMode>(
                  title: const Text('Light'),
                  subtitle: const Text('Always use light theme'),
                  value: ThemeMode.light,
                  groupValue: _currentThemeMode,
                  onChanged: (ThemeMode? value) {
                    if (value != null) {
                      _updateThemeMode(value);
                    }
                  },
                ),
                const Divider(height: 1),
                RadioListTile<ThemeMode>(
                  title: const Text('Dark'),
                  subtitle: const Text('Always use dark theme'),
                  value: ThemeMode.dark,
                  groupValue: _currentThemeMode,
                  onChanged: (ThemeMode? value) {
                    if (value != null) {
                      _updateThemeMode(value);
                    }
                  },
                ),
              ],
            ),
          ),
          // About & Support Section
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.spacingM,
              AppTheme.spacingXL,
              AppTheme.spacingM,
              AppTheme.spacingS,
            ),
            child: Text(
              'About & Support',
              style: AppTheme.headingSmall.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          Card(
            margin: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingM,
              vertical: AppTheme.spacingS,
            ),
            child: Column(
              children: [
                // App Version
                ListTile(
                  leading: const Icon(LucideIcons.info),
                  title: const Text('App Version'),
                  subtitle: _isLoadingVersion
                      ? const Text('Loading...')
                      : Text(_packageInfo != null
                          ? '${_packageInfo!.version} (Build ${_packageInfo!.buildNumber})'
                          : 'Unknown'),
                ),
                const Divider(height: 1),
                // Designer Credit
                ListTile(
                  leading: const Icon(LucideIcons.user),
                  title: const Text('Designed by'),
                  subtitle: const Text('Shoeb Khan'),
                  trailing: const Icon(LucideIcons.chevronRight),
                  onTap: () => _launchUrl('https://shoebsmk.github.io'),
                ),
                const Divider(height: 1),
                // Privacy Policy
                ListTile(
                  leading: const Icon(LucideIcons.shield),
                  title: const Text('Privacy Policy'),
                  trailing: const Icon(LucideIcons.chevronRight),
                  onTap: () => _launchUrl('https://example.com/privacy-policy'),
                ),
                const Divider(height: 1),
                // Terms of Service
                ListTile(
                  leading: const Icon(LucideIcons.fileText),
                  title: const Text('Terms of Service'),
                  trailing: const Icon(LucideIcons.chevronRight),
                  onTap: () => _launchUrl('https://example.com/terms-of-service'),
                ),
                const Divider(height: 1),
                // Feedback & Support
                ListTile(
                  leading: const Icon(LucideIcons.messageCircle),
                  title: const Text('Feedback & Support'),
                  trailing: const Icon(LucideIcons.chevronRight),
                  onTap: () => _launchUrl('mailto:support@example.com?subject=Chat App Feedback'),
                ),
                const Divider(height: 1),
                // Rate the App
                ListTile(
                  leading: const Icon(LucideIcons.star),
                  title: const Text('Rate the App'),
                  trailing: const Icon(LucideIcons.chevronRight),
                  onTap: _handleRateApp,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _updateThemeMode(ThemeMode mode) {
    MyApp.setThemeModeOf(context, mode);
    setState(() => _currentThemeMode = mode);
  }

  Future<void> _launchUrl(String urlString) async {
    try {
      final uri = Uri.parse(urlString);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open link'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
          ),
        );
      }
    }
  }

  void _handleRateApp() {
    // For now, show a dialog. In production, you'd link to app store/play store
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rate the App'),
        content: const Text(
          'Thank you for using our app! If you enjoy it, please consider rating us on the App Store or Google Play.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Maybe Later'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // In production, replace with actual app store links
              // _launchUrl('https://apps.apple.com/app/your-app-id');
              // or
              // _launchUrl('https://play.google.com/store/apps/details?id=your.package.name');
            },
            child: const Text('Rate Now'),
          ),
        ],
      ),
    );
  }
}

