import 'package:flutter_test/flutter_test.dart';
import 'package:chat_app/utils/constants.dart';

void main() {
  group('Profile Validation - Constants and Regex', () {
    test('Username length constraints', () {
      expect(AppConstants.minUsernameLength, 3);
      expect(AppConstants.maxUsernameLength, 50);
    });

    test('Bio length constraints', () {
      expect(AppConstants.maxBioLength, 500);
    });

    test('Image size constraints', () {
      expect(AppConstants.maxImageSizeBytes, 5 * 1024 * 1024); // 5MB
      expect(AppConstants.maxImageDimension, 2000);
    });

    test('Username regex - valid patterns', () {
      expect(AppRegex.username.hasMatch('user123'), true);
      expect(AppRegex.username.hasMatch('test_user'), true);
      expect(AppRegex.username.hasMatch('user-name'), true);
      expect(AppRegex.username.hasMatch('abc'), true); // min length
      expect(AppRegex.username.hasMatch('a' * 50), true); // max length
    });

    test('Username regex - invalid patterns', () {
      expect(AppRegex.username.hasMatch('ab'), false); // too short
      expect(AppRegex.username.hasMatch('a' * 51), false); // too long
      expect(AppRegex.username.hasMatch('user name'), false); // spaces
      expect(AppRegex.username.hasMatch('user@name'), false); // special chars
      expect(AppRegex.username.hasMatch(''), false); // empty
    });
  });
}
