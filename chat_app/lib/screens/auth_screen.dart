import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'chat_list_screen.dart';
import '../theme/app_theme.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  bool _isSignUp = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  String? _validateUsername(String? value) {
    if (_isSignUp) {
      if (value == null || value.isEmpty) {
        return 'Please enter a username';
      }
      if (value.length < 3) {
        return 'Username must be at least 3 characters';
      }
    }
    return null;
  }

  Future<void> _handleAuth() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_isSignUp) {
        final response = await Supabase.instance.client.auth.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          data: {'username': _usernameController.text.trim()},
        );
        final userId = response.user?.id;
        if (userId != null) {
          await Supabase.instance.client.from('users').insert({
            'id': userId,
            'username': _usernameController.text.trim(),
          });
        }
      } else {
        await Supabase.instance.client.auth.signInWithPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        final userId = Supabase.instance.client.auth.currentUser?.id;
        if (userId != null) {
          final existing = await Supabase.instance.client
              .from('users')
              .select('id')
              .eq('id', userId)
              .limit(1);
          if (existing is List && existing.isEmpty) {
            final email = _emailController.text.trim();
            final username = email.split('@').first;
            await Supabase.instance.client.from('users').insert({
              'id': userId,
              'username': username,
            });
          }
        }
      }

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const ChatListScreen()),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  void _toggleAuthMode() {
    setState(() {
      _isSignUp = !_isSignUp;
      _errorMessage = null;
      _formKey.currentState?.reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.spacingXL),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppTheme.spacingXXL),
                // Logo/Icon
                Icon(
                  Icons.chat_bubble_rounded,
                  size: 80,
                  color: AppTheme.primaryLight,
                )
                    .animate()
                    .scale(delay: 100.ms, duration: 400.ms)
                    .fadeIn(delay: 100.ms),
                const SizedBox(height: AppTheme.spacingL),
                // Title
                Text(
                  _isSignUp ? 'Create Account' : 'Welcome Back',
                  style: AppTheme.headingLarge.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                )
                    .animate()
                    .fadeIn(delay: 200.ms)
                    .slideY(begin: -0.2, end: 0, delay: 200.ms),
                const SizedBox(height: AppTheme.spacingS),
                Text(
                  _isSignUp
                      ? 'Sign up to start chatting'
                      : 'Sign in to continue',
                  style: AppTheme.bodyMedium.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                  textAlign: TextAlign.center,
                )
                    .animate()
                    .fadeIn(delay: 300.ms)
                    .slideY(begin: -0.2, end: 0, delay: 300.ms),
                const SizedBox(height: AppTheme.spacingXXL),
                // Error message
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(AppTheme.spacingM),
                    margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
                    decoration: BoxDecoration(
                      color: AppTheme.errorLight.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusM),
                      border: Border.all(
                        color: AppTheme.errorLight.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: AppTheme.errorLight,
                          size: 20,
                        ),
                        const SizedBox(width: AppTheme.spacingS),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: AppTheme.bodySmall.copyWith(
                              color: AppTheme.errorLight,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn()
                      .shake(),
                // Email field
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: _validateEmail,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: const Icon(Icons.email_outlined),
                  ),
                )
                    .animate()
                    .fadeIn(delay: 400.ms)
                    .slideX(begin: -0.1, end: 0, delay: 400.ms),
                const SizedBox(height: AppTheme.spacingM),
                // Password field
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction:
                      _isSignUp ? TextInputAction.next : TextInputAction.done,
                  validator: _validatePassword,
                  onFieldSubmitted: (_) => _handleAuth(),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(delay: 500.ms)
                    .slideX(begin: -0.1, end: 0, delay: 500.ms),
                // Username field (only for sign up)
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: _isSignUp
                      ? Column(
                          children: [
                            const SizedBox(height: AppTheme.spacingM),
                            TextFormField(
                              controller: _usernameController,
                              textInputAction: TextInputAction.done,
                              validator: _validateUsername,
                              onFieldSubmitted: (_) => _handleAuth(),
                              decoration: const InputDecoration(
                                labelText: 'Username',
                                prefixIcon: Icon(Icons.person_outlined),
                              ),
                            ),
                          ],
                        )
                            .animate()
                            .fadeIn()
                            .slideY(begin: -0.1, end: 0)
                      : const SizedBox.shrink(),
                ),
                const SizedBox(height: AppTheme.spacingXL),
                // Submit button
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleAuth,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            _isSignUp ? 'Sign Up' : 'Sign In',
                            style: AppTheme.bodyLarge.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                )
                    .animate()
                    .fadeIn(delay: 600.ms)
                    .slideY(begin: 0.1, end: 0, delay: 600.ms),
                const SizedBox(height: AppTheme.spacingL),
                // Toggle auth mode
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _isSignUp
                          ? 'Already have an account? '
                          : 'Don\'t have an account? ',
                      style: AppTheme.bodyMedium.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    TextButton(
                      onPressed: _toggleAuthMode,
                      child: Text(
                        _isSignUp ? 'Sign In' : 'Sign Up',
                        style: AppTheme.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryLight,
                        ),
                      ),
                    ),
                  ],
                )
                    .animate()
                    .fadeIn(delay: 700.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
