import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';
import 'screens/auth_screen.dart';
import 'screens/main_screen.dart';
import 'services/auth_service.dart';
import 'services/theme_service.dart';
import 'theme/app_theme.dart';
import 'utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SupabaseConfig.initialize();

  // Load saved theme
  final themeMode = await ThemeService.loadThemeMode();

  runApp(MyApp(initialThemeMode: themeMode));
}

class MyApp extends StatefulWidget {
  final ThemeMode initialThemeMode;

  const MyApp({
    super.key,
    required this.initialThemeMode,
  });

  @override
  State<MyApp> createState() => _MyAppState();

  /// Returns the current theme mode.
  /// Returns null if no instance is available.
  static ThemeMode? themeModeOf(BuildContext context) {
    return _MyAppState._instance?.themeMode;
  }

  /// Sets the theme mode and persists it to SharedPreferences.
  static Future<void> setThemeModeOf(BuildContext context, ThemeMode mode) async {
    await _MyAppState._instance?.setThemeMode(mode);
  }
}

class _MyAppState extends State<MyApp> {
  late ThemeMode _themeMode;
  final _authService = AuthService();
  StreamSubscription<AuthState>? _authStateSubscription;
  bool _isAuthenticated = false;
  
  static _MyAppState? _instance;

  /// Returns the current theme mode.
  ThemeMode get themeMode => _themeMode;

  @override
  void initState() {
    super.initState();
    _themeMode = widget.initialThemeMode;
    _instance = this;
    
    // Initialize auth state
    _isAuthenticated = _authService.isAuthenticated;
    
    // Listen to auth state changes to handle session restoration
    // This is critical for first launch when Supabase restores the session asynchronously
    _authStateSubscription = Supabase.instance.client.auth.onAuthStateChange.listen(
      (AuthState state) {
        final newAuthState = state.session != null;
        if (newAuthState != _isAuthenticated && mounted) {
          setState(() {
            _isAuthenticated = newAuthState;
          });
        }
      },
    );
    
    // Also check auth state after a microtask to catch any session restoration
    // that might happen right after initialization
    Future.microtask(() {
      if (mounted) {
        final currentAuthState = _authService.isAuthenticated;
        if (currentAuthState != _isAuthenticated) {
          setState(() {
            _isAuthenticated = currentAuthState;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    _instance = null;
    super.dispose();
  }

  /// Sets the theme mode and persists it to SharedPreferences.
  Future<void> setThemeMode(ThemeMode mode) async {
    await ThemeService.saveThemeMode(mode);
    if (mounted) {
      setState(() => _themeMode = mode);
    }
  }

  /// Toggles between light and dark theme.
  /// Can be exposed to UI when theme toggle is implemented.
  // ignore: unused_element
  Future<void> toggleTheme() async {
    ThemeMode newMode;
    if (_themeMode == ThemeMode.light) {
      newMode = ThemeMode.dark;
    } else if (_themeMode == ThemeMode.dark) {
      newMode = ThemeMode.light;
    } else {
      // If system, default to light
      newMode = ThemeMode.light;
    }
    await setThemeMode(newMode);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chat App',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeMode,
      debugShowCheckedModeBanner: false,
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/':
            return _createRoute(
              _isAuthenticated ? const MainScreen() : const AuthScreen(),
            );
          default:
            return _createRoute(
              _isAuthenticated ? const MainScreen() : const AuthScreen(),
            );
        }
      },
      home: _isAuthenticated ? const MainScreen() : const AuthScreen(),
    );
  }

  PageRouteBuilder _createRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 0.1);
        const end = Offset.zero;
        const curve = Curves.easeOut;

        var tween = Tween(
          begin: begin,
          end: end,
        ).chain(CurveTween(curve: curve));

        return SlideTransition(
          position: animation.drive(tween),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      transitionDuration: AppConstants.animationSlow,
    );
  }
}
