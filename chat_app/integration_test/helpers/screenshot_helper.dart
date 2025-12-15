import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as path;

/// Helper class for managing screenshot capture during integration tests.
class ScreenshotHelper {
  static final IntegrationTestWidgetsFlutterBinding binding =
      IntegrationTestWidgetsFlutterBinding.instance;
  
  /// Gets the project root directory by finding the directory containing pubspec.yaml
  static String _getProjectRoot() {
    // Method 1: Try to use the current working directory first
    final currentDir = Directory.current.path;
    if (currentDir != '/' && currentDir.isNotEmpty) {
      final pubspecFile = File(path.join(currentDir, 'pubspec.yaml'));
      if (pubspecFile.existsSync()) {
        return currentDir;
      }
    }
    
    // Method 2: Get the directory where this test file is located
    // This is the most reliable method for integration tests
    try {
      final scriptUri = Platform.script;
      String scriptPath;
      
      if (scriptUri.scheme == 'file') {
        scriptPath = scriptUri.toFilePath();
      } else {
        // For package: or other URIs, try to resolve
        scriptPath = scriptUri.path;
        if (!path.isAbsolute(scriptPath)) {
          // If it's a relative path, make it absolute from current dir
          scriptPath = path.absolute(currentDir, scriptPath);
        }
      }
      
      // Get the directory containing this helper file
      final testFileDir = path.dirname(scriptPath);
      // Go up from integration_test/helpers/ to project root
      var projectRoot = path.normalize(path.join(testFileDir, '..', '..'));
      
      // Resolve to absolute path
      if (!path.isAbsolute(projectRoot)) {
        projectRoot = path.absolute(projectRoot);
      }
      
      // Verify it's the project root by checking for pubspec.yaml
      final pubspecFile = File(path.join(projectRoot, 'pubspec.yaml'));
      if (pubspecFile.existsSync()) {
        return projectRoot;
      }
    } catch (e) {
      print('Warning: Could not determine project root from script location: $e');
    }
    
    // Method 3: Walk up from current directory to find pubspec.yaml
    try {
      var dir = Directory(currentDir);
      var lastPath = '';
      while (dir.path != lastPath) {
        final pubspec = File(path.join(dir.path, 'pubspec.yaml'));
        if (pubspec.existsSync()) {
          return dir.path;
        }
        lastPath = dir.path;
        dir = dir.parent;
      }
    } catch (e) {
      print('Warning: Could not walk up directory tree: $e');
    }
    
    // If all else fails, use a fallback writable directory
    print('⚠️  Could not find project root, using fallback directory');
    return _getFallbackDirectory();
  }
  
  /// Gets a fallback writable directory
  static String _getFallbackDirectory() {
    final homeDir = Platform.environment['HOME'] ?? 
                    Platform.environment['USERPROFILE'] ?? 
                    '';
    if (homeDir.isNotEmpty) {
      return path.join(homeDir, 'Desktop', 'screenshots', 'ios', 'automated');
    }
    return path.join('/tmp', 'screenshots', 'ios', 'automated');
  }
  
  static String get screenshotDir {
    try {
      final projectRoot = _getProjectRoot();
      return path.join(projectRoot, 'screenshots', 'ios', 'automated');
    } catch (e) {
      print('⚠️  Error getting project root: $e');
      return _getFallbackDirectory();
    }
  }

  /// Ensures the screenshot directory exists.
  static Future<void> ensureDirectoryExists() async {
    final dir = Directory(screenshotDir);
    if (!await dir.exists()) {
      try {
        await dir.create(recursive: true);
        print('📁 Created screenshot directory: $screenshotDir');
      } catch (e) {
        print('❌ Failed to create directory $screenshotDir: $e');
        // Try to use a fallback directory
        final fallbackDir = _getFallbackDirectory();
        print('📁 Using fallback directory: $fallbackDir');
        throw Exception(
          'Cannot create screenshot directory. Tried: $screenshotDir\n'
          'Error: $e\n'
          'Please ensure you have write permissions or run the test from the project root directory.'
        );
      }
    }
  }

  /// Takes a screenshot and saves it with the specified filename.
  /// 
  /// [filename] should be in format like "01-auth-signup.png"
  /// Returns the full path to the saved screenshot.
  static Future<String> takeScreenshot(String filename) async {
    await ensureDirectoryExists();
    
    // Wait a bit for any animations to complete
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Take the screenshot
    final bytes = await binding.takeScreenshot(filename);
    
    // Save to file
    final filePath = path.join(screenshotDir, filename);
    final file = File(filePath);
    await file.writeAsBytes(bytes);
    
    print('📸 Screenshot saved: $filePath');
    return filePath;
  }

  /// Takes a screenshot with automatic numbering and description.
  /// 
  /// [number] is the step number (01, 02, etc.)
  /// [description] is a short description (e.g., "auth-signup")
  static Future<String> takeScreenshotStep(int number, String description) async {
    final filename = '${number.toString().padLeft(2, '0')}-$description.png';
    return await takeScreenshot(filename);
  }
}

