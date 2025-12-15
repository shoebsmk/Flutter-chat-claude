import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user.dart' as models;
import '../services/user_service.dart';
import '../services/profile_service.dart';
import '../services/auth_service.dart';
import '../widgets/image_picker_widget.dart';
import '../theme/app_theme.dart';
import '../utils/constants.dart';
import '../exceptions/app_exceptions.dart';

/// Screen for editing user profile (username, bio, profile picture).
class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();
  final _userService = UserService();
  final _profileService = ProfileService();
  final _authService = AuthService();

  models.User? _currentUser;
  XFile? _selectedImage;
  String? _originalAvatarUrl;
  bool _isLoading = false;
  bool _isCheckingUsername = false;
  bool _isUsernameAvailable = true;
  String? _errorMessage;
  String? _usernameError;

  @override
  void initState() {
    super.initState();
    _loadCurrentProfile();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentProfile() async {
    try {
      final user = await _userService.getCurrentUser();
      if (user != null && mounted) {
        setState(() {
          _currentUser = user;
          _usernameController.text = user.username;
          _bioController.text = user.bio ?? '';
          _originalAvatarUrl = user.avatarUrl;
        });
      }
    } catch (e) {
      if (mounted) {
        _showError('Failed to load profile: ${ExceptionHandler.getMessage(e)}');
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_isLoading) return; // Prevent multiple saves

    final userId = _authService.currentUserId;
    if (userId == null) {
      _showError(AuthException.notAuthenticated().message);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _usernameError = null;
    });

    try {
      String? newAvatarUrl;
      String? oldAvatarUrl = _originalAvatarUrl;

      // Step 1: Upload image if selected
      if (_selectedImage != null) {
        try {
          newAvatarUrl = await _profileService.uploadProfileImage(
            _selectedImage!,
            userId,
          );
        } catch (e) {
          // Image upload failed - rollback not needed, just show error
          setState(() {
            _isLoading = false;
            _errorMessage = ExceptionHandler.getMessage(e);
          });
          return;
        }
      }

      // Step 2: Check username availability if changed
      final newUsername = _usernameController.text.trim();
      final usernameChanged = newUsername != _currentUser?.username;
      
      if (usernameChanged) {
        final isAvailable = await _userService.checkUsernameAvailability(
          newUsername,
        );
        if (!isAvailable) {
          setState(() {
            _isLoading = false;
            _usernameError = 'Username is already taken';
            _errorMessage = ProfileException.usernameTaken().message;
          });
          // Rollback: Delete uploaded image if any
          if (newAvatarUrl != null) {
            await _profileService.deleteProfileImage(newAvatarUrl);
          }
          return;
        }
      }

      // Step 3: Update database
      try {
        final updatedUser = await _userService.updateProfile(
          username: usernameChanged ? newUsername : null,
          bio: _bioController.text.trim(),
          avatarUrl: newAvatarUrl,
        );

        // Step 4: Delete old image if replaced
        if (oldAvatarUrl != null && 
            newAvatarUrl != null && 
            oldAvatarUrl != newAvatarUrl) {
          // Non-critical - don't throw if deletion fails
          await _profileService.deleteProfileImage(oldAvatarUrl);
        }

        // Success
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully'),
              backgroundColor: AppTheme.successLight,
            ),
          );
          Navigator.of(context).pop(updatedUser);
        }
      } catch (e) {
        // Database update failed - rollback image upload
        if (newAvatarUrl != null) {
          await _profileService.deleteProfileImage(newAvatarUrl);
        }
        rethrow;
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = ExceptionHandler.getMessage(e);
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _checkUsernameAvailability(String username) async {
    if (username.isEmpty || username == _currentUser?.username) {
      setState(() {
        _isUsernameAvailable = true;
        _usernameError = null;
      });
      return;
    }

    if (!_profileService.validateUsername(username)) {
      setState(() {
        _isUsernameAvailable = false;
        _usernameError = 'Invalid username format';
      });
      return;
    }

    setState(() {
      _isCheckingUsername = true;
      _usernameError = null;
    });

    try {
      final isAvailable = await _userService.checkUsernameAvailability(username);
      if (mounted) {
        setState(() {
          _isCheckingUsername = false;
          _isUsernameAvailable = isAvailable;
          _usernameError = isAvailable ? null : 'Username is already taken';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCheckingUsername = false;
          _isUsernameAvailable = false;
          _usernameError = 'Error checking availability';
        });
      }
    }
  }

  void _showError(String message) {
    setState(() {
      _errorMessage = message;
    });
  }

  String? _validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'Username is required';
    }

    final trimmed = value.trim();
    if (trimmed.length < AppConstants.minUsernameLength) {
      return 'Username must be at least ${AppConstants.minUsernameLength} characters';
    }
    if (trimmed.length > AppConstants.maxUsernameLength) {
      return 'Username must be at most ${AppConstants.maxUsernameLength} characters';
    }
    if (!AppRegex.username.hasMatch(trimmed)) {
      return 'Username can only contain letters, numbers, underscores, and hyphens';
    }
    if (_usernameError != null) {
      return _usernameError;
    }
    return null;
  }

  String? _validateBio(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    if (trimmed.length > AppConstants.maxBioLength) {
      return 'Bio must be at most ${AppConstants.maxBioLength} characters';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(
          'Edit Profile',
          style: AppTheme.headingSmall.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: AppTheme.spacingS),
              child: TextButton(
                onPressed: _saveProfile,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingL,
                    vertical: AppTheme.spacingS,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusM),
                  ),
                ),
                child: Text(
                  'Save',
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.primaryLight,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _currentUser == null
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                final keyboardPadding = MediaQuery.of(context).viewInsets.bottom;
                return SingleChildScrollView(
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.only(
                    left: AppTheme.spacingXL,
                    right: AppTheme.spacingXL,
                    top: AppTheme.spacingXL,
                    bottom: AppTheme.spacingXL + keyboardPadding,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: AppTheme.spacingXL),
                        _buildImagePicker(),
                        const SizedBox(height: AppTheme.spacingXXL),
                        if (_errorMessage != null) ...[
                          _buildErrorMessage(),
                          const SizedBox(height: AppTheme.spacingL),
                        ],
                        _buildFormCard(
                          children: [
                            _buildUsernameField(),
                            const SizedBox(height: AppTheme.spacingXL),
                            _buildBioField(),
                          ],
                        ),
                        SizedBox(height: AppTheme.spacingXXL + keyboardPadding),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildImagePicker() {
    return ImagePickerWidget(
      currentImageUrl: _originalAvatarUrl,
      size: 220,
      onImageSelected: (image) {
        setState(() {
          _selectedImage = image;
          if (image == null) {
            // User wants to remove image
            _originalAvatarUrl = null;
          }
        });
      },
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: AppTheme.errorLight.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        border: Border.all(color: AppTheme.errorLight.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.errorLight.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppTheme.errorLight, size: 22),
          const SizedBox(width: AppTheme.spacingS),
          Expanded(
            child: Text(
              _errorMessage!,
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.errorLight,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingXL),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  Widget _buildUsernameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Username',
          style: AppTheme.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: AppTheme.spacingS),
        TextFormField(
          controller: _usernameController,
          textInputAction: TextInputAction.next,
          enabled: !_isLoading,
          style: AppTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: 'Enter your username',
            prefixIcon: const Icon(Icons.person_outlined),
            suffixIcon: _isCheckingUsername
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: Padding(
                      padding: EdgeInsets.all(12.0),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : _isUsernameAvailable && _usernameController.text.isNotEmpty
                    ? const Icon(Icons.check_circle, color: AppTheme.successLight)
                    : null,
            helperText: '${_usernameController.text.length}/${AppConstants.maxUsernameLength}',
            helperStyle: AppTheme.bodySmall.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          validator: _validateUsername,
          onChanged: (value) {
            // Debounce username check
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted && _usernameController.text == value) {
                _checkUsernameAvailability(value);
              }
            });
          },
          inputFormatters: [
            LengthLimitingTextInputFormatter(AppConstants.maxUsernameLength),
          ],
        ),
      ],
    );
  }

  Widget _buildBioField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bio',
          style: AppTheme.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: AppTheme.spacingXS),
        Text(
          'Optional',
          style: AppTheme.bodySmall.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: AppTheme.spacingS),
        TextFormField(
          controller: _bioController,
          maxLines: 5,
          maxLength: AppConstants.maxBioLength,
          enabled: !_isLoading,
          textInputAction: TextInputAction.done,
          style: AppTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: 'Tell us about yourself...',
            prefixIcon: const Icon(Icons.description_outlined),
          ),
          validator: _validateBio,
        ),
      ],
    );
  }
}

