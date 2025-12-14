# Profile Editing Feature - Implementation Plan

## Overview
This document outlines the complete implementation plan for adding profile editing functionality that allows users to:
- Edit their username
- Upload/change their profile picture (stored in Supabase Storage)
- Add/edit a bio

---

## 1. Database Schema Changes

### 1.1 SQL Migration Script
Create a new migration file: `supabase_profile_migration.sql`

```sql
-- Add avatar_url column to users table
ALTER TABLE public.users 
ADD COLUMN IF NOT EXISTS avatar_url TEXT;

-- Add bio column to users table
ALTER TABLE public.users 
ADD COLUMN IF NOT EXISTS bio TEXT;

-- Add updated_at column for tracking profile updates
ALTER TABLE public.users 
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now());

-- Create index for avatar_url queries (if needed for search/filtering)
CREATE INDEX IF NOT EXISTS idx_users_avatar_url 
ON public.users(avatar_url) 
WHERE avatar_url IS NOT NULL;

-- Add constraint for bio length (max 500 characters)
ALTER TABLE public.users 
ADD CONSTRAINT check_bio_length CHECK (bio IS NULL OR LENGTH(bio) <= 500);

-- Add constraint for username length (max 50 characters, min 3)
ALTER TABLE public.users 
ADD CONSTRAINT check_username_length CHECK (LENGTH(username) >= 3 AND LENGTH(username) <= 50);

-- Create function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_users_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = timezone('utc'::text, now());
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to update updated_at on user updates
DROP TRIGGER IF EXISTS trigger_update_users_updated_at ON public.users;
CREATE TRIGGER trigger_update_users_updated_at
  BEFORE UPDATE ON public.users
  FOR EACH ROW
  EXECUTE FUNCTION update_users_updated_at();
```

### 1.2 Supabase Storage Bucket Setup
Create a storage bucket for profile pictures:

```sql
-- Create storage bucket for profile pictures
INSERT INTO storage.buckets (id, name, public)
VALUES ('profile-pictures', 'profile-pictures', true)
ON CONFLICT (id) DO NOTHING;

-- Storage policy: Users can upload their own profile picture
CREATE POLICY "Users can upload own profile picture"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'profile-pictures' AND
  (storage.foldername(name))[1] = auth.uid()::text
);

-- Storage policy: Users can update their own profile picture
CREATE POLICY "Users can update own profile picture"
ON storage.objects FOR UPDATE
TO authenticated
USING (
  bucket_id = 'profile-pictures' AND
  (storage.foldername(name))[1] = auth.uid()::text
);

-- Storage policy: Users can delete their own profile picture
CREATE POLICY "Users can delete own profile picture"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'profile-pictures' AND
  (storage.foldername(name))[1] = auth.uid()::text
);

-- Storage policy: Anyone can view profile pictures (public bucket)
CREATE POLICY "Anyone can view profile pictures"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'profile-pictures');
```

---

## 2. Dependencies/Packages Required

### 2.1 New Packages to Add
Add to `pubspec.yaml`:

```yaml
dependencies:
  # Image picking and manipulation
  image_picker: ^1.0.7          # For selecting images from gallery/camera
  image: ^4.1.7                  # For image compression and manipulation
  
  # File handling
  path_provider: ^2.1.2          # For getting temporary file paths
  path: ^1.9.0                   # For path manipulation
  
  # Permissions (platform-specific)
  permission_handler: ^11.3.0    # For requesting camera/storage permissions
```

### 2.2 Existing Packages (Already in Use)
- `supabase_flutter: ^2.0.0` - Already includes storage support
- `flutter` - Core framework

### 2.3 Platform-Specific Configuration

#### iOS (`ios/Runner/Info.plist`)
Add permissions:
```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>We need access to your photo library to upload profile pictures</string>
<key>NSCameraUsageDescription</key>
<string>We need access to your camera to take profile pictures</string>
<key>NSPhotoLibraryAddUsageDescription</key>
<string>We need access to save photos to your library</string>
```

#### Android (`android/app/src/main/AndroidManifest.xml`)
Add permissions:
```xml
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" android:maxSdkVersion="32" />
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
```

---

## 3. Validation Rules

### 3.1 Username Validation
- **Min Length**: 3 characters (existing: `AppConstants.minUsernameLength`)
- **Max Length**: 50 characters (new constant needed)
- **Allowed Characters**: Alphanumeric, underscore, hyphen (no spaces)
- **Uniqueness**: Must be unique across all users
- **Trim**: Leading/trailing whitespace removed

### 3.2 Bio Validation
- **Min Length**: None (optional field)
- **Max Length**: 500 characters
- **Trim**: Leading/trailing whitespace removed
- **Empty String Handling**: Convert empty strings to null

### 3.3 Profile Picture Validation
- **File Size**: Max 5MB
- **File Types**: JPEG, PNG, WebP
- **Dimensions**: Recommended max 2000x2000px (will be compressed)
- **Aspect Ratio**: No restrictions (will be cropped to circle/square)

### 3.4 Update Constants
Add to `lib/utils/constants.dart`:
```dart
// Profile validation
static const int maxUsernameLength = 50;
static const int maxBioLength = 500;
static const int maxImageSizeBytes = 5 * 1024 * 1024; // 5MB
static const int maxImageDimension = 2000;
```

---

## 4. Implementation Steps

### Step 1: Update User Model
**File**: `lib/models/user.dart`

Add fields:
- `avatarUrl` (String?)
- `bio` (String?)
- `updatedAt` (DateTime?)

Update:
- `fromJson()` factory constructor
- `toJson()` method
- `copyWith()` method

### Step 2: Create Profile Service
**File**: `lib/services/profile_service.dart` (NEW)

Responsibilities:
- Upload profile picture to Supabase Storage
- Delete old profile picture when replacing
- Update user profile (username, bio, avatar_url)
- Validate profile data
- Handle rollback scenarios

### Step 3: Extend User Service
**File**: `lib/services/user_service.dart`

Add methods:
- `updateProfile()` - Update username, bio, avatar_url
- `checkUsernameAvailability()` - Check if username is available
- `updateAvatarUrl()` - Update only avatar URL in database

### Step 4: Create Profile Edit Screen
**File**: `lib/screens/profile_edit_screen.dart` (NEW)

Features:
- Form with username, bio text fields
- Profile picture picker/uploader
- Image preview with crop/edit option
- Save/Cancel buttons
- Loading states
- Error handling UI

### Step 5: Create Image Picker Widget
**File**: `lib/widgets/image_picker_widget.dart` (NEW)

Features:
- Camera/gallery selection
- Image preview
- Image compression
- Circular crop preview
- Upload progress indicator

### Step 6: Update User Avatar Widget
**File**: `lib/widgets/user_avatar.dart`

Update to:
- Use `avatarUrl` from User model
- Handle image loading errors gracefully
- Show loading state during image fetch

### Step 7: Add Navigation to Profile Edit
**File**: `lib/screens/chat_list_screen.dart` or create settings screen

Add:
- Profile button/icon in app bar
- Navigation to profile edit screen

### Step 8: Add Exception Types
**File**: `lib/exceptions/app_exceptions.dart`

Add:
- `StorageException` - For storage-related errors
- `ProfileException` - For profile update errors

---

## 5. Detailed Data Flow

### 5.1 Success Flow: Update Profile with New Picture

```
1. User opens Profile Edit Screen
   └─> Load current user data
   └─> Display current username, bio, avatar

2. User selects new image
   └─> Request permissions (camera/storage)
   └─> Open image picker (camera/gallery)
   └─> User selects image
   └─> Validate image (size, type, dimensions)
   └─> Compress image (reduce size, max 2000x2000)
   └─> Show preview with circular crop

3. User edits username/bio
   └─> Real-time validation
   └─> Check username availability (if changed)

4. User clicks Save
   └─> Validate all fields
   └─> Show loading indicator
   
5. Upload new image to Supabase Storage
   └─> Generate unique filename: {userId}/{timestamp}.jpg
   └─> Upload to bucket: profile-pictures/{userId}/{timestamp}.jpg
   └─> Get public URL from Supabase
   └─> Store old avatar URL for rollback

6. Update database
   └─> Begin transaction (if supported)
   └─> Update users table:
       - username (if changed)
       - bio (if changed)
       - avatar_url (new URL)
       - updated_at (auto-updated by trigger)
   └─> Commit transaction

7. Delete old image (if exists and different)
   └─> Extract file path from old avatar_url
   └─> Delete from storage bucket
   └─> Handle deletion errors gracefully (non-critical)

8. Success
   └─> Update local user state
   └─> Show success message
   └─> Navigate back
   └─> Refresh user streams
```

### 5.2 Error Flow: Image Upload Fails

```
1. User clicks Save
   └─> Validation passes
   └─> Show loading indicator

2. Upload new image to Supabase Storage
   └─> Network error / Storage quota exceeded / Invalid file
   └─> Catch StorageException

3. Error Handling
   └─> Show error message to user
   └─> Keep old image displayed
   └─> Allow retry
   └─> Do NOT update database
   └─> Do NOT delete old image

4. User can retry or cancel
```

### 5.3 Error Flow: Database Update Fails After Image Upload

```
1. Image upload succeeds
   └─> New avatar URL obtained
   └─> Old avatar URL stored for rollback

2. Database update fails
   └─> Username conflict / Network error / Permission denied
   └─> Catch DatabaseException

3. Rollback Strategy
   └─> Delete newly uploaded image from storage
   └─> Show error message to user
   └─> Keep old data displayed
   └─> Allow user to retry

4. User can retry or cancel
```

### 5.4 Error Flow: Partial Update (Username Changed, Bio Failed)

```
1. User updates username and bio
   └─> Username validation passes
   └─> Bio validation passes

2. Database update
   └─> Username update succeeds
   └─> Bio update fails (e.g., constraint violation)

3. Error Handling
   └─> If transaction supported: Rollback entire update
   └─> If no transaction: 
       - Keep username change (already committed)
       - Show error for bio
       - Allow user to retry bio update
```

### 5.5 Error Flow: Username Already Taken

```
1. User changes username
   └─> Real-time validation (client-side format check)
   └─> User clicks Save

2. Check username availability
   └─> Query database for existing username
   └─> Username already exists

3. Error Handling
   └─> Show validation error: "Username already taken"
   └─> Highlight username field
   └─> Prevent save
   └─> Suggest alternatives (if implemented)
```

---

## 6. Edge Cases & Error Handling

### 6.1 Image Upload Edge Cases

#### 6.1.1 Image Upload Failure
**Scenario**: Network error, storage quota exceeded, invalid file type
**Handling**:
- Catch `StorageException`
- Show user-friendly error message
- Keep old image displayed
- Allow retry
- Do NOT update database

**Code Pattern**:
```dart
try {
  final imageUrl = await _uploadImage(imageFile);
  // Continue with database update
} on StorageException catch (e) {
  // Rollback: Don't update database
  // Show error to user
  // Allow retry
}
```

#### 6.1.2 Image Upload Timeout
**Scenario**: Upload takes too long (>30 seconds)
**Handling**:
- Set upload timeout (30 seconds)
- Show progress indicator
- Allow cancellation
- Retry with exponential backoff

#### 6.1.3 Image Too Large
**Scenario**: User selects 10MB image
**Handling**:
- Validate file size before upload
- Compress image if needed
- Show error if compression fails
- Suggest resizing

#### 6.1.4 Invalid Image Format
**Scenario**: User selects non-image file or corrupted image
**Handling**:
- Validate file type before processing
- Show error: "Please select a valid image (JPEG, PNG, WebP)"
- Allow user to select different image

#### 6.1.5 Image Upload Succeeds but URL Generation Fails
**Scenario**: File uploaded but public URL cannot be generated
**Handling**:
- Retry URL generation
- If fails, delete uploaded file
- Show error to user
- Allow retry

### 6.2 Database Update Edge Cases

#### 6.2.1 Database Update Fails After Image Upload
**Scenario**: Image uploaded successfully, but database update fails
**Handling**:
- Delete newly uploaded image (rollback)
- Keep old avatar URL in database
- Show error message
- Allow retry

**Code Pattern**:
```dart
String? newImageUrl;
String? oldImageUrl;

try {
  // Upload image
  newImageUrl = await _uploadImage(imageFile);
  oldImageUrl = currentUser.avatarUrl;
  
  // Update database
  await _updateDatabase(username, bio, newImageUrl);
  
  // Delete old image if exists
  if (oldImageUrl != null) {
    await _deleteOldImage(oldImageUrl);
  }
} on DatabaseException catch (e) {
  // Rollback: Delete new image
  if (newImageUrl != null) {
    await _deleteImage(newImageUrl);
  }
  // Show error
  throw e;
}
```

#### 6.2.2 Username Already Taken
**Scenario**: Another user took the username between check and update
**Handling**:
- Check username availability before update
- If changed, verify again right before update
- Use database constraint (unique index) as final check
- Show error: "Username already taken. Please choose another."

#### 6.2.3 Concurrent Updates
**Scenario**: User updates profile from multiple devices simultaneously
**Handling**:
- Use `updated_at` timestamp for optimistic locking (optional)
- Last write wins (acceptable for profile updates)
- Show conflict warning if needed

#### 6.2.4 Database Connection Lost
**Scenario**: Network disconnects during database update
**Handling**:
- Catch `NetworkException`
- Show error: "Connection lost. Please check your internet and try again."
- Allow retry
- Do NOT delete uploaded image (will be orphaned, but can be cleaned up later)

### 6.3 Input Validation Edge Cases

#### 6.3.1 Username with Special Characters
**Scenario**: User enters "user@name" or "user name"
**Handling**:
- Validate format: alphanumeric, underscore, hyphen only
- Show error: "Username can only contain letters, numbers, underscores, and hyphens"
- Prevent save

#### 6.3.2 Username Too Short/Long
**Scenario**: User enters "ab" or 60-character username
**Handling**:
- Real-time validation
- Show character count
- Disable save button if invalid
- Show error message

#### 6.3.3 Bio with Only Whitespace
**Scenario**: User enters "   " (spaces only)
**Handling**:
- Trim whitespace
- Convert to null if empty after trim
- Treat as "no bio"

#### 6.3.4 Bio Exceeds Max Length
**Scenario**: User pastes 600-character bio
**Handling**:
- Real-time character counter
- Disable save if exceeds limit
- Show error: "Bio must be 500 characters or less"
- Highlight excess characters (optional)

#### 6.3.5 Empty Username
**Scenario**: User clears username field
**Handling**:
- Username is required
- Show error: "Username is required"
- Prevent save

### 6.4 State Management Edge Cases

#### 6.4.1 User Logs Out During Edit
**Scenario**: User starts editing, then logs out
**Handling**:
- Check authentication before save
- If logged out, show error and navigate to auth screen
- Discard changes

#### 6.4.2 User Navigates Away During Upload
**Scenario**: User starts upload, then presses back button
**Handling**:
- Show confirmation dialog: "Upload in progress. Cancel and discard changes?"
- If confirmed, cancel upload (if possible)
- Navigate away
- Clean up temporary files

#### 6.4.3 App Backgrounded During Update
**Scenario**: User saves, app goes to background
**Handling**:
- Upload/update continues in background
- Show notification when complete (optional)
- Update UI when app returns to foreground

#### 6.4.4 Multiple Rapid Saves
**Scenario**: User clicks Save button multiple times quickly
**Handling**:
- Disable save button during operation
- Show loading indicator
- Ignore duplicate requests
- Use debouncing if needed

### 6.5 Platform-Specific Edge Cases

#### 6.5.1 Camera Permission Denied (iOS/Android)
**Scenario**: User denies camera permission
**Handling**:
- Show permission explanation
- Provide link to settings
- Fallback to gallery only
- Show error if gallery also denied

#### 6.5.2 Storage Permission Denied (Android)
**Scenario**: Android user denies storage permission
**Handling**:
- Request permission with explanation
- Use scoped storage (Android 10+)
- Fallback to app-specific directory
- Show error if all options fail

#### 6.5.3 No Camera Available (Web/Desktop)
**Scenario**: User on web/desktop tries to use camera
**Handling**:
- Check platform capabilities
- Hide camera option on unsupported platforms
- Show gallery/file picker only

#### 6.5.4 Image Picker Cancelled
**Scenario**: User opens picker but cancels without selecting
**Handling**:
- Return to profile edit screen
- Keep existing image
- No error shown (normal behavior)

#### 6.5.5 File System Access Issues (Desktop)
**Scenario**: Desktop app cannot access file system
**Handling**:
- Request file system permissions
- Show error if denied
- Provide alternative (URL input, drag-drop)

### 6.6 Storage Edge Cases

#### 6.6.1 Old Image Deletion Fails
**Scenario**: New image uploaded, database updated, but old image deletion fails
**Handling**:
- Log error (non-critical)
- Continue (old image is orphaned)
- Schedule cleanup job (optional)
- Show success to user (deletion is not critical)

#### 6.6.2 Storage Quota Exceeded
**Scenario**: User has uploaded too many images
**Handling**:
- Catch storage quota error
- Show error: "Storage quota exceeded. Please contact support."
- Prevent upload
- Suggest deleting old images (if feature exists)

#### 6.6.3 Orphaned Images
**Scenario**: Image uploaded but database update fails, then app crashes
**Handling**:
- Implement cleanup job (optional)
- Delete images older than 24 hours without associated user
- Or: Keep images, allow manual cleanup

### 6.7 Network Edge Cases

#### 6.7.1 Slow Network
**Scenario**: Upload takes very long on slow connection
**Handling**:
- Show progress indicator
- Allow cancellation
- Set reasonable timeout (30-60 seconds)
- Show estimated time remaining

#### 6.7.2 Network Interruption During Upload
**Scenario**: Network drops mid-upload
**Handling**:
- Detect network loss
- Pause upload (if resumable)
- Show error: "Connection lost. Retry?"
- Allow retry from beginning

#### 6.7.3 Offline Mode
**Scenario**: User tries to save while offline
**Handling**:
- Check network connectivity
- Show error: "No internet connection. Please connect and try again."
- Prevent save
- Queue update for when online (optional)

---

## 7. Error Recovery Strategies

### 7.1 Image Upload Failure Recovery
1. **Retry with Exponential Backoff**
   - First retry: 1 second
   - Second retry: 2 seconds
   - Third retry: 4 seconds
   - Max 3 retries

2. **Compression Retry**
   - If upload fails due to size, compress more aggressively
   - Retry with smaller image

3. **Alternative Upload Method**
   - If direct upload fails, try chunked upload (for large files)

### 7.2 Database Update Failure Recovery
1. **Transaction Rollback** (if supported)
   - Rollback entire update on any failure
   - Retry from beginning

2. **Partial Update Recovery** (if no transactions)
   - Identify which fields updated successfully
   - Retry only failed fields
   - Show partial success message

3. **Optimistic Locking**
   - Check `updated_at` before update
   - If changed, refresh data and show conflict warning

### 7.3 State Recovery
1. **Auto-save Draft** (optional)
   - Save form state locally
   - Restore on app restart
   - Clear on successful save

2. **Session Recovery**
   - If app crashes during update, check for pending updates
   - Resume or discard based on user preference

---

## 8. Testing Considerations

### 8.1 Unit Tests

#### Profile Service Tests
- `testProfileUpdateSuccess()` - Successful profile update
- `testImageUploadSuccess()` - Successful image upload
- `testImageUploadFailure()` - Image upload failure handling
- `testDatabaseUpdateFailureAfterUpload()` - Rollback scenario
- `testUsernameValidation()` - Username format validation
- `testBioValidation()` - Bio length validation
- `testUsernameAvailabilityCheck()` - Username uniqueness check
- `testImageCompression()` - Image compression logic
- `testOldImageDeletion()` - Old image cleanup

#### User Service Tests
- `testUpdateProfile()` - Profile update method
- `testCheckUsernameAvailability()` - Username availability check
- `testUpdateAvatarUrl()` - Avatar URL update

### 8.2 Widget Tests

#### Profile Edit Screen Tests
- `testProfileEditScreenRenders()` - Screen renders correctly
- `testFormValidation()` - Form validation works
- `testImagePickerOpens()` - Image picker opens
- `testSaveButtonDisabled()` - Save button disabled when invalid
- `testLoadingState()` - Loading state displayed
- `testErrorDisplay()` - Errors displayed correctly

#### Image Picker Widget Tests
- `testImageSelection()` - Image selection works
- `testImagePreview()` - Preview displays correctly
- `testCompressionIndicator()` - Compression progress shown

### 8.3 Integration Tests

#### Profile Update Flow
- `testCompleteProfileUpdate()` - Full flow: select image, edit fields, save
- `testProfileUpdateWithImageUploadFailure()` - Image upload fails, rollback works
- `testProfileUpdateWithDatabaseFailure()` - Database fails, image deleted
- `testConcurrentUpdates()` - Multiple devices updating simultaneously

#### Permission Tests
- `testCameraPermissionDenied()` - Camera permission denied handling
- `testStoragePermissionDenied()` - Storage permission denied handling
- `testPermissionGranted()` - Permissions granted flow

### 8.4 Edge Case Tests

#### Network Tests
- `testSlowNetworkUpload()` - Upload on slow network
- `testNetworkInterruption()` - Network drops during upload
- `testOfflineMode()` - Offline mode handling

#### Platform Tests
- `testWebImagePicker()` - Web platform image picker
- `testDesktopImagePicker()` - Desktop platform image picker
- `testMobileImagePicker()` - Mobile platform image picker

#### Error Recovery Tests
- `testRetryAfterFailure()` - Retry mechanism works
- `testPartialUpdateRecovery()` - Partial update recovery
- `testStateRecovery()` - State recovery after crash

### 8.5 Manual Testing Checklist

#### Happy Path
- [ ] User can edit username successfully
- [ ] User can edit bio successfully
- [ ] User can upload new profile picture
- [ ] User can change profile picture
- [ ] User can remove profile picture (set to null)
- [ ] Changes are reflected immediately in UI
- [ ] Changes persist after app restart

#### Error Scenarios
- [ ] Image upload failure shows error
- [ ] Database update failure shows error
- [ ] Username taken shows error
- [ ] Invalid username format shows error
- [ ] Bio too long shows error
- [ ] Network error shows appropriate message
- [ ] Permission denied shows appropriate message

#### Edge Cases
- [ ] Rapid save clicks don't cause duplicate updates
- [ ] Navigation away during upload shows confirmation
- [ ] App backgrounding doesn't break upload
- [ ] Large images are compressed properly
- [ ] Old images are deleted when replaced
- [ ] Orphaned images don't cause errors

---

## 9. Implementation Checklist (Todos)

### Phase 1: Database & Storage Setup
- [ ] Create database migration SQL script
- [ ] Run migration in Supabase SQL editor
- [ ] Create storage bucket for profile pictures
- [ ] Set up storage policies (upload, update, delete, view)
- [ ] Test storage bucket access

### Phase 2: Dependencies & Configuration
- [ ] Add `image_picker` package to `pubspec.yaml`
- [ ] Add `image` package for compression
- [ ] Add `path_provider` package
- [ ] Add `path` package
- [ ] Add `permission_handler` package
- [ ] Run `flutter pub get`
- [ ] Update iOS `Info.plist` with permissions
- [ ] Update Android `AndroidManifest.xml` with permissions
- [ ] Test permissions on iOS device
- [ ] Test permissions on Android device

### Phase 3: Model & Constants Updates
- [ ] Update `User` model with `avatarUrl`, `bio`, `updatedAt`
- [ ] Update `User.fromJson()` to parse new fields
- [ ] Update `User.toJson()` to include new fields
- [ ] Update `User.copyWith()` to include new fields
- [ ] Add profile validation constants to `AppConstants`
- [ ] Add username regex pattern to `AppRegex`

### Phase 4: Exception Handling
- [ ] Create `StorageException` class
- [ ] Create `ProfileException` class
- [ ] Update `ExceptionHandler` to handle storage errors
- [ ] Update `ExceptionHandler` to handle profile errors

### Phase 5: Service Layer
- [ ] Create `ProfileService` class
- [ ] Implement image upload method with error handling
- [ ] Implement image deletion method
- [ ] Implement image compression method
- [ ] Implement profile update method with rollback
- [ ] Add username availability check to `UserService`
- [ ] Add profile update method to `UserService`
- [ ] Test all service methods

### Phase 6: UI Components
- [ ] Create `ImagePickerWidget` component
- [ ] Implement image selection (camera/gallery)
- [ ] Implement image preview with circular crop
- [ ] Implement image compression UI feedback
- [ ] Implement upload progress indicator
- [ ] Update `UserAvatar` widget to use `avatarUrl`
- [ ] Test image picker on all platforms

### Phase 7: Profile Edit Screen
- [ ] Create `ProfileEditScreen` widget
- [ ] Implement form with username field
- [ ] Implement form with bio field (multiline)
- [ ] Implement profile picture picker integration
- [ ] Implement save button with loading state
- [ ] Implement cancel button
- [ ] Implement real-time validation
- [ ] Implement error display
- [ ] Implement success feedback
- [ ] Add navigation from chat list/settings

### Phase 8: Integration & State Management
- [ ] Integrate profile edit screen into app navigation
- [ ] Update user streams to reflect profile changes
- [ ] Test real-time updates across screens
- [ ] Test state persistence

### Phase 9: Error Handling & Edge Cases
- [ ] Implement image upload failure handling
- [ ] Implement database update failure rollback
- [ ] Implement username conflict handling
- [ ] Implement network error handling
- [ ] Implement permission denial handling
- [ ] Implement concurrent update handling
- [ ] Implement offline mode handling
- [ ] Test all error scenarios

### Phase 10: Testing
- [ ] Write unit tests for `ProfileService`
- [ ] Write unit tests for `UserService` updates
- [ ] Write widget tests for `ProfileEditScreen`
- [ ] Write widget tests for `ImagePickerWidget`
- [ ] Write integration tests for complete flow
- [ ] Test on iOS device
- [ ] Test on Android device
- [ ] Test on Web (if applicable)
- [ ] Test on Desktop (if applicable)
- [ ] Perform manual testing checklist

### Phase 11: Documentation & Cleanup
- [ ] Update `ARCHITECTURE.md` with profile editing
- [ ] Update `README.md` with new feature
- [ ] Add code comments
- [ ] Review and refactor code
- [ ] Remove debug prints
- [ ] Optimize image compression settings

---

## 10. Code Structure Preview

### 10.1 ProfileService Structure
```dart
class ProfileService {
  // Image operations
  Future<String> uploadProfileImage(File imageFile, String userId)
  Future<void> deleteProfileImage(String imageUrl)
  Future<File> compressImage(File imageFile)
  
  // Profile operations
  Future<void> updateProfile({
    String? username,
    String? bio,
    File? imageFile,
  })
  
  // Validation
  bool validateUsername(String username)
  bool validateBio(String? bio)
  Future<bool> isUsernameAvailable(String username)
}
```

### 10.2 ProfileEditScreen Structure
```dart
class ProfileEditScreen extends StatefulWidget {
  // Form state
  // Image state
  // Loading state
  // Error state
  
  // Methods
  _loadCurrentProfile()
  _selectImage()
  _compressAndPreviewImage()
  _validateForm()
  _saveProfile()
  _handleError()
}
```

---

## 11. Security Considerations

### 11.1 Storage Security
- Users can only upload to their own folder: `profile-pictures/{userId}/`
- Storage policies enforce user ownership
- Public read access for profile pictures (acceptable for social features)

### 11.2 Database Security
- RLS policies should allow users to update only their own profile
- Username uniqueness enforced at database level (unique constraint)
- Input sanitization to prevent SQL injection (handled by Supabase)

### 11.3 Image Security
- Validate file types server-side (storage policies)
- Scan for malicious content (optional, use Supabase edge functions)
- Limit file size to prevent DoS

### 11.4 Input Validation
- Client-side validation for UX
- Server-side validation for security
- Sanitize user inputs (trim, escape special characters)

---

## 12. Performance Considerations

### 12.1 Image Optimization
- Compress images before upload (reduce bandwidth)
- Use appropriate image format (JPEG for photos, PNG for transparency)
- Limit dimensions (max 2000x2000px)
- Lazy load images in UI

### 12.2 Database Optimization
- Index on `username` for fast uniqueness checks
- Index on `avatar_url` if needed for queries
- Use transactions for atomic updates (if supported)

### 12.3 Network Optimization
- Show upload progress
- Allow cancellation
- Retry with exponential backoff
- Cache profile images locally

---

## 13. Rollback Plan

If issues arise during implementation:

1. **Database Rollback**
   - Run reverse migration to remove new columns
   - Keep existing data intact

2. **Code Rollback**
   - Revert to previous git commit
   - Remove new packages if needed

3. **Storage Rollback**
   - Keep storage bucket (no harm)
   - Or delete bucket if not needed

---

## 14. Future Enhancements

Potential improvements after initial implementation:

- [ ] Image cropping/editing UI
- [ ] Multiple image formats support
- [ ] Image optimization on server
- [ ] Profile picture history/versioning
- [ ] Batch profile updates
- [ ] Profile picture from URL
- [ ] Avatar generation from username (fallback)
- [ ] Profile visibility settings
- [ ] Profile completion percentage

---

## Conclusion

This plan provides a comprehensive roadmap for implementing profile editing functionality with robust error handling, edge case coverage, and rollback mechanisms. Follow the phases sequentially, test thoroughly at each step, and ensure all edge cases are handled before moving to the next phase.

