import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'chat_list_screen.dart';
import '../exceptions/app_exceptions.dart';
import '../services/auth_service.dart';
import '../services/haptic_service.dart';
import '../theme/app_theme.dart';
import '../utils/constants.dart';

/// Screen for user authentication (sign in / sign up).
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _authService = AuthService();
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
    if (!AppRegex.email.hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    if (value.length < AppConstants.minPasswordLength) {
      return 'Password must be at least ${AppConstants.minPasswordLength} characters';
    }
    return null;
  }

  String? _validateUsername(String? value) {
    if (!_isSignUp) return null;

    if (value == null || value.isEmpty) {
      return 'Please enter a username';
    }
    if (value.length < AppConstants.minUsernameLength) {
      return 'Username must be at least ${AppConstants.minUsernameLength} characters';
    }
    return null;
  }

  Future<void> _handleAuth() async {
    if (_formKey.currentState?.validate() != true) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_isSignUp) {
        await _authService.signUp(
          email: _emailController.text,
          password: _passwordController.text,
          username: _usernameController.text,
        );
      } else {
        await _authService.signIn(
          email: _emailController.text,
          password: _passwordController.text,
        );
      }

      if (mounted) {
        // Success haptic feedback
        HapticService.instance.selectionClick();
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const ChatListScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = ExceptionHandler.getMessage(e);
        });
      }
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
                _buildLogo(),
                const SizedBox(height: AppTheme.spacingL),
                _buildTitle(theme),
                const SizedBox(height: AppTheme.spacingS),
                _buildSubtitle(theme),
                const SizedBox(height: AppTheme.spacingXXL),
                if (_errorMessage != null) _buildErrorMessage(),
                _buildEmailField(),
                const SizedBox(height: AppTheme.spacingM),
                _buildPasswordField(),
                _buildUsernameField(),
                const SizedBox(height: AppTheme.spacingXL),
                _buildSubmitButton(),
                const SizedBox(height: AppTheme.spacingL),
                _buildAuthModeToggle(theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return const Icon(
      Icons.chat_bubble_rounded,
      size: 80,
      color: AppTheme.primaryLight,
    ).animate().scale(delay: 100.ms, duration: 400.ms).fadeIn(delay: 100.ms);
  }

  Widget _buildTitle(ThemeData theme) {
    return Text(
          _isSignUp ? 'Create Account' : 'Welcome Back',
          style: AppTheme.headingLarge.copyWith(
            color: theme.colorScheme.onSurface,
          ),
          textAlign: TextAlign.center,
        )
        .animate()
        .fadeIn(delay: 200.ms)
        .slideY(begin: -0.2, end: 0, delay: 200.ms);
  }

  Widget _buildSubtitle(ThemeData theme) {
    return Text(
          _isSignUp ? 'Sign up to start chatting' : 'Sign in to continue',
          style: AppTheme.bodyMedium.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
          textAlign: TextAlign.center,
        )
        .animate()
        .fadeIn(delay: 300.ms)
        .slideY(begin: -0.2, end: 0, delay: 300.ms);
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
      decoration: BoxDecoration(
        color: AppTheme.errorLight.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(color: AppTheme.errorLight.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppTheme.errorLight, size: 20),
          const SizedBox(width: AppTheme.spacingS),
          Expanded(
            child: Text(
              _errorMessage!,
              style: AppTheme.bodySmall.copyWith(color: AppTheme.errorLight),
            ),
          ),
        ],
      ),
    ).animate().fadeIn().shake();
  }

  Widget _buildEmailField() {
    return TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          validator: _validateEmail,
          decoration: const InputDecoration(
            labelText: 'Email',
            prefixIcon: Icon(Icons.email_outlined),
          ),
        )
        .animate()
        .fadeIn(delay: 400.ms)
        .slideX(begin: -0.1, end: 0, delay: 400.ms);
  }

  Widget _buildPasswordField() {
    return TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          textInputAction: _isSignUp
              ? TextInputAction.next
              : TextInputAction.done,
          validator: _validatePassword,
          onFieldSubmitted: _isSignUp ? null : (_) => _handleAuth(),
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
        .slideX(begin: -0.1, end: 0, delay: 500.ms);
  }

  Widget _buildUsernameField() {
    return AnimatedSize(
      duration: AppConstants.animationSlow,
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
            ).animate().fadeIn().slideY(begin: -0.1, end: 0)
          : const SizedBox.shrink(),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleAuth,
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                _isSignUp ? 'Sign Up' : 'Sign In',
                style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.w600),
              ),
      ),
    ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1, end: 0, delay: 600.ms);
  }

  Widget _buildAuthModeToggle(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _isSignUp ? 'Already have an account? ' : "Don't have an account? ",
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
    ).animate().fadeIn(delay: 700.ms);
  }
}
