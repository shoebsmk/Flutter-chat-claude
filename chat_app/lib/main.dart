import 'package:flutter/material.dart';
import 'config/supabase_config.dart';
import 'screens/auth_screen.dart';
import 'screens/chat_list_screen.dart';
import 'services/auth_service.dart';
import 'theme/app_theme.dart';
import 'utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SupabaseConfig.initialize();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.system;
  final _authService = AuthService();

  /// Toggles between light and dark theme.
  /// Can be exposed to UI when theme toggle is implemented.
  // ignore: unused_element
  void toggleTheme() {
    setState(() {
      if (_themeMode == ThemeMode.light) {
        _themeMode = ThemeMode.dark;
      } else if (_themeMode == ThemeMode.dark) {
        _themeMode = ThemeMode.light;
      } else {
        // If system, default to light
        _themeMode = ThemeMode.light;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isAuthenticated = _authService.isAuthenticated;

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
              isAuthenticated ? const ChatListScreen() : const AuthScreen(),
            );
          default:
            return _createRoute(
              isAuthenticated ? const ChatListScreen() : const AuthScreen(),
            );
        }
      },
      home: isAuthenticated ? const ChatListScreen() : const AuthScreen(),
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
