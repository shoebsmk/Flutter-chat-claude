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

/// Service for handling file uploads for message attachments.
class FileUploadService {
  final SupabaseClient _client;
  static const String _bucketName = AppConstants.messageAttachmentsBucket;
  static const int _uploadTimeoutSeconds = 30;

  FileUploadService({SupabaseClient? client})
      : _client = client ?? SupabaseConfig.client;

  /// Returns the current user's ID.
  String? get currentUserId => _client.auth.currentUser?.id;

  /// Uploads an image file for a message attachment.
  ///
  /// Returns the public URL of the uploaded image.
  /// Throws [StorageException] if upload fails.
  Future<String> uploadMessageImage(
    XFile imageFile,
    String userId,
    String messageId,
  ) async {
    try {
      // Validate file
      await _validateImageFile(imageFile);

      // Compress image
      final compressedBytes = await compressImage(imageFile);

      // Generate unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final originalName = imageFile.name;
      final extension = path.extension(originalName).toLowerCase();
      final fileName = '$timestamp${extension.isEmpty ? '.jpg' : extension}';
      final filePath = '$userId/$messageId/$fileName';

      // Upload to storage
      // On web, upload bytes directly; on mobile, use File
      Future uploadFuture;
      if (kIsWeb) {
        // Web: upload bytes directly using the storage API
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
      debugPrint('Error uploading message image: $e');
      throw exceptions.StorageException.uploadFailed('Unexpected error: ${e.toString()}');
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
      if (compressedBytes.length > AppConstants.maxAttachmentSizeBytes) {
        // Try lower quality
        final lowerQualityBytes = img.encodeJpg(resizedImage, quality: 70);
        if (lowerQualityBytes.length > AppConstants.maxAttachmentSizeBytes) {
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
    if (fileSize > AppConstants.maxAttachmentSizeBytes) {
      throw exceptions.StorageException.fileTooLarge(5);
    }

    // Check file extension (on web, path might be a data URL, so check name)
    final fileName = imageFile.name.toLowerCase();
    final extension = path.extension(fileName).toLowerCase();
    if (extension.isNotEmpty &&
        !['.jpg', '.jpeg', '.png', '.webp'].contains(extension)) {
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
}

