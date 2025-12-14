import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../exceptions/app_exceptions.dart' as exceptions;
import '../utils/constants.dart';

/// Service for handling profile-related operations including image uploads.
class ProfileService {
  final SupabaseClient _client;
  static const String _bucketName = 'profile-pictures';
  static const int _uploadTimeoutSeconds = 30;

  ProfileService({SupabaseClient? client})
      : _client = client ?? SupabaseConfig.client;

  /// Returns the current user's ID.
  String? get currentUserId => _client.auth.currentUser?.id;

  /// Uploads a profile image to Supabase Storage.
  ///
  /// Returns the public URL of the uploaded image.
  /// Throws [StorageException] if upload fails.
  Future<String> uploadProfileImage(XFile imageFile, String userId) async {
    try {
      // Validate file
      await _validateImageFile(imageFile);

      // Compress image
      final compressedBytes = await compressImage(imageFile);

      // Generate unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '$timestamp.jpg'; // Always use .jpg after compression
      final filePath = '$userId/$fileName';

      // Upload to storage
      // On web, upload bytes directly; on mobile, use File
      Future uploadFuture;
      if (kIsWeb) {
        // Web: upload bytes directly using the storage API
        // Supabase Flutter's upload method accepts Uint8List on web
        uploadFuture = _client.storage
            .from(_bucketName)
            .uploadBinary(
              filePath,
              Uint8List.fromList(compressedBytes),
              fileOptions: const FileOptions(
                upsert: true,
                contentType: 'image/jpeg',
              ),
            );
      } else {
        // Mobile: create temporary file and upload
        final tempDir = await getTemporaryDirectory();
        final tempFile = File(path.join(tempDir.path, fileName));
        await tempFile.writeAsBytes(compressedBytes);
        uploadFuture = _client.storage
            .from(_bucketName)
            .upload(
              filePath,
              tempFile,
              fileOptions: const FileOptions(
                upsert: true,
                contentType: 'image/jpeg',
              ),
            );
      }
      
      await uploadFuture.timeout(
        Duration(seconds: _uploadTimeoutSeconds),
        onTimeout: () {
          throw exceptions.StorageException.uploadFailed('Upload timeout');
        },
      );

      // Get public URL
      final urlResponse = _client.storage
          .from(_bucketName)
          .getPublicUrl(filePath);

      return urlResponse;
    } on TimeoutException {
      throw exceptions.StorageException.uploadFailed('Upload timed out');
    } on exceptions.StorageException {
      rethrow;
    } catch (e) {
      debugPrint('Error uploading profile image: $e');
      throw exceptions.StorageException.uploadFailed('Unexpected error: ${e.toString()}');
    }
  }

  /// Deletes a profile image from Supabase Storage.
  ///
  /// Throws [StorageException] if deletion fails.
  Future<void> deleteProfileImage(String imageUrl) async {
    try {
      // Extract file path from URL
      final filePath = _extractFilePathFromUrl(imageUrl);
      if (filePath == null) {
        debugPrint('Could not extract file path from URL: $imageUrl');
        return; // Non-critical, just log
      }

      await _client.storage.from(_bucketName).remove([filePath]);
    } catch (e) {
      // Non-critical error - log but don't throw
      debugPrint('Error deleting profile image: $e');
      // Don't throw - deletion failure is not critical
    }
  }

  /// Compresses an image file to reduce size.
  ///
  /// Returns compressed image bytes.
  Future<List<int>> compressImage(XFile imageFile) async {
    try {
      // Read image bytes
      final bytes = await imageFile.readAsBytes();
      final originalImage = img.decodeImage(bytes);

      if (originalImage == null) {
        throw exceptions.StorageException.invalidFileType();
      }

      // Calculate new dimensions (max 2000x2000)
      int newWidth = originalImage.width;
      int newHeight = originalImage.height;

      if (newWidth > AppConstants.maxImageDimension ||
          newHeight > AppConstants.maxImageDimension) {
        final ratio = newWidth > newHeight
            ? AppConstants.maxImageDimension / newWidth
            : AppConstants.maxImageDimension / newHeight;
        newWidth = (newWidth * ratio).round();
        newHeight = (newHeight * ratio).round();
      }

      // Resize if needed
      final resizedImage = newWidth != originalImage.width ||
              newHeight != originalImage.height
          ? img.copyResize(
              originalImage,
              width: newWidth,
              height: newHeight,
            )
          : originalImage;

      // Encode as JPEG with quality 85
      final compressedBytes = img.encodeJpg(resizedImage, quality: 85);

      // Check size
      if (compressedBytes.length > AppConstants.maxImageSizeBytes) {
        // Try lower quality
        final lowerQualityBytes = img.encodeJpg(resizedImage, quality: 70);
        if (lowerQualityBytes.length > AppConstants.maxImageSizeBytes) {
          throw exceptions.StorageException.fileTooLarge(5);
        }
        return lowerQualityBytes;
      }

      return compressedBytes;
    } catch (e) {
      if (e is exceptions.StorageException) {
        rethrow;
      }
      debugPrint('Error compressing image: $e');
      throw exceptions.StorageException.uploadFailed('Failed to compress image');
    }
  }

  /// Validates an image file before upload.
  Future<void> _validateImageFile(XFile imageFile) async {
    // Check file size
    final fileSize = await imageFile.length();
    if (fileSize > AppConstants.maxImageSizeBytes) {
      throw exceptions.StorageException.fileTooLarge(5);
    }

    // Check file extension (on web, path might be a data URL, so check name)
    final fileName = imageFile.name.toLowerCase();
    final extension = path.extension(fileName).toLowerCase();
    if (extension.isNotEmpty && !['.jpg', '.jpeg', '.png', '.webp'].contains(extension)) {
      throw exceptions.StorageException.invalidFileType();
    }

    // Try to decode image to verify it's valid
    try {
      final bytes = await imageFile.readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) {
        throw exceptions.StorageException.invalidFileType();
      }
    } catch (e) {
      if (e is exceptions.StorageException) {
        rethrow;
      }
      throw exceptions.StorageException.invalidFileType();
    }
  }

  /// Extracts file path from Supabase Storage URL.
  String? _extractFilePathFromUrl(String url) {
    try {
      // Supabase storage URLs typically look like:
      // https://[project].supabase.co/storage/v1/object/public/profile-pictures/userId/filename.jpg
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;
      
      // Find the bucket name index
      final bucketIndex = pathSegments.indexOf(_bucketName);
      if (bucketIndex == -1 || bucketIndex >= pathSegments.length - 1) {
        return null;
      }

      // Get path after bucket name
      final fileSegments = pathSegments.sublist(bucketIndex + 1);
      return fileSegments.join('/');
    } catch (e) {
      debugPrint('Error extracting file path from URL: $e');
      return null;
    }
  }

  /// Validates username format.
  bool validateUsername(String username) {
    if (username.length < AppConstants.minUsernameLength ||
        username.length > AppConstants.maxUsernameLength) {
      return false;
    }
    return AppRegex.username.hasMatch(username);
  }

  /// Validates bio length.
  bool validateBio(String? bio) {
    if (bio == null) return true; // Bio is optional
    final trimmed = bio.trim();
    return trimmed.length <= AppConstants.maxBioLength;
  }
}

