import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../theme/app_theme.dart';

/// Widget for picking and previewing profile images.
class ImagePickerWidget extends StatefulWidget {
  final String? currentImageUrl;
  final Function(XFile?) onImageSelected;
  final double size;

  const ImagePickerWidget({
    super.key,
    this.currentImageUrl,
    required this.onImageSelected,
    this.size = 120,
  });

  @override
  State<ImagePickerWidget> createState() => _ImagePickerWidgetState();
}

class _ImagePickerWidgetState extends State<ImagePickerWidget> {
  XFile? _selectedImage;
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          _buildAvatar(),
          _buildEditButton(),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppTheme.primaryLight.withOpacity(0.1),
        border: Border.all(
          color: AppTheme.primaryLight.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _selectedImage != null
              ? ClipOval(
                  child: kIsWeb
                      ? Image.network(
                          _selectedImage!.path,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildPlaceholder();
                          },
                        )
                      : Image.file(
                          File(_selectedImage!.path),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildPlaceholder();
                          },
                        ),
                )
              : widget.currentImageUrl != null && widget.currentImageUrl!.isNotEmpty
                  ? ClipOval(
                      child: Image.network(
                        widget.currentImageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildPlaceholder();
                        },
                      ),
                    )
                  : _buildPlaceholder(),
    );
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Icon(
        Icons.person,
        size: widget.size * 0.5,
        color: AppTheme.primaryLight,
      ),
    );
  }

  Widget _buildEditButton() {
    return Positioned(
      right: 0,
      bottom: 0,
      child: Container(
        width: widget.size * 0.35,
        height: widget.size * 0.35,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppTheme.primaryLight,
          border: Border.all(
            color: Theme.of(context).scaffoldBackgroundColor,
            width: 3,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(widget.size * 0.35),
            onTap: _isLoading ? null : _showImageSourceDialog,
            child: Icon(
              _selectedImage != null ? Icons.edit : Icons.camera_alt,
              size: widget.size * 0.2,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showImageSourceDialog() async {
    if (!mounted) return;

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            // Camera option not available on web
            if (!kIsWeb)
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take Photo'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
            if (_selectedImage != null || widget.currentImageUrl != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Remove Photo', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _removeImage();
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (source != null) {
      await _pickImage(source);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      // Request permissions (skip on web - image_picker handles it differently)
      if (!kIsWeb) {
        if (source == ImageSource.camera) {
          final cameraStatus = await Permission.camera.request();
          if (!cameraStatus.isGranted) {
            if (mounted) {
              _showPermissionDeniedDialog('Camera');
            }
            return;
          }
        } else {
          final photosStatus = await Permission.photos.request();
          if (!photosStatus.isGranted) {
            if (mounted) {
              _showPermissionDeniedDialog('Photos');
            }
            return;
          }
        }
      }

      setState(() => _isLoading = true);

      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 90,
        maxWidth: 2000,
        maxHeight: 2000,
      );

      if (image != null) {
        setState(() {
          _selectedImage = image;
          _isLoading = false;
        });
        widget.onImageSelected(_selectedImage);
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: ${e.toString()}'),
            backgroundColor: AppTheme.errorLight,
          ),
        );
      }
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
    });
    widget.onImageSelected(null);
  }

  void _showPermissionDeniedDialog(String permission) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permission Required'),
        content: Text(
          'Please grant $permission permission in your device settings to select an image.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }
}

