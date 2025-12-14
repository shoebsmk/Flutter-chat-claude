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
        title: const Text('Edit Profile'),
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
            TextButton(
              onPressed: _saveProfile,
              child: const Text(
                'Save',
                style: TextStyle(
                  color: AppTheme.primaryLight,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: _currentUser == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.spacingXL),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AppTheme.spacingL),
                    _buildImagePicker(),
                    const SizedBox(height: AppTheme.spacingXXL),
                    if (_errorMessage != null) _buildErrorMessage(),
                    _buildUsernameField(),
                    const SizedBox(height: AppTheme.spacingL),
                    _buildBioField(),
                    const SizedBox(height: AppTheme.spacingXL),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildImagePicker() {
    return ImagePickerWidget(
      currentImageUrl: _originalAvatarUrl,
      size: 120,
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
    );
  }

  Widget _buildUsernameField() {
    return TextFormField(
      controller: _usernameController,
      textInputAction: TextInputAction.next,
      enabled: !_isLoading,
      decoration: InputDecoration(
        labelText: 'Username',
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
    );
  }

  Widget _buildBioField() {
    return TextFormField(
      controller: _bioController,
      maxLines: 4,
      maxLength: AppConstants.maxBioLength,
      enabled: !_isLoading,
      textInputAction: TextInputAction.done,
      decoration: const InputDecoration(
        labelText: 'Bio (optional)',
        prefixIcon: Icon(Icons.description_outlined),
        alignLabelWithHint: true,
      ),
      validator: _validateBio,
    );
  }
}

