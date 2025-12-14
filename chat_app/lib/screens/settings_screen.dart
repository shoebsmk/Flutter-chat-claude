import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
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
        ],
      ),
    );
  }

  void _updateThemeMode(ThemeMode mode) {
    MyApp.setThemeModeOf(context, mode);
    setState(() => _currentThemeMode = mode);
  }
}

