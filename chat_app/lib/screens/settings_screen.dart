import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../config/build_info.dart';
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

  /// Formats the UTC ISO 8601 timestamp into a human-readable string.
  String _formatBuildTimestamp(String raw) {
    if (raw == 'not available') return raw;
    try {
      final dt = DateTime.parse(raw).toLocal();
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      final amPm = dt.hour >= 12 ? 'PM' : 'AM';
      final min = dt.minute.toString().padLeft(2, '0');
      return '${months[dt.month - 1]} ${dt.day}, ${dt.year} at $hour:$min $amPm';
    } catch (_) {
      return raw;
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

    final versionString = _packageInfo != null
        ? '${_packageInfo!.version} (Build ${_packageInfo!.buildNumber})'
        : 'Unknown';
    final buildDate = _formatBuildTimestamp(BuildInfo.buildTimestamp);
    final hasBuildInfo = BuildInfo.buildTimestamp != 'not available';

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
                // Deployment Details — expandable
                Theme(
                  data: theme.copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    leading: const Icon(LucideIcons.info),
                    title: _isLoadingVersion
                        ? const Text('Loading...')
                        : Text('Version $versionString'),
                    subtitle: hasBuildInfo
                        ? Text('Built $buildDate')
                        : const Text('Build info not available'),
                    children: [
                      _buildDetailRow(
                        context,
                        icon: LucideIcons.gitBranch,
                        label: 'Branch',
                        value: BuildInfo.gitBranch,
                      ),
                      _buildDetailRow(
                        context,
                        icon: LucideIcons.gitCommit,
                        label: 'Commit',
                        value: BuildInfo.gitCommit,
                        copyable: true,
                      ),
                      _buildDetailRow(
                        context,
                        icon: LucideIcons.monitor,
                        label: 'Built on',
                        value: BuildInfo.buildEnvironment,
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
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
                  onTap: () => _launchUrl('mailto:support@example.com?subject=SmartChat Feedback'),
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

  /// Builds a single detail row for the deployment info expansion tile.
  Widget _buildDetailRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    bool copyable = false,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 13,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
                fontFamily: copyable ? 'monospace' : null,
              ),
            ),
          ),
          if (copyable)
            IconButton(
              icon: Icon(LucideIcons.copy, size: 14, color: theme.colorScheme.onSurfaceVariant),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              tooltip: 'Copy commit hash',
              onPressed: () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Commit hash copied'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
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

