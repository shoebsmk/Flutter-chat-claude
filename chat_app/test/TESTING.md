# Testing Guide

This document explains how to run tests for the chat application.

## Running Tests

### Run All Tests

To run all tests in the project:

```bash
flutter test
```

### Run Specific Test Files

To run a specific test file:

```bash
flutter test test/models/message_test.dart
flutter test test/models/user_test.dart
flutter test test/exceptions/app_exceptions_test.dart
flutter test test/services/chat_service_test.dart
```

### Run Tests with Coverage

To generate a coverage report:

```bash
flutter test --coverage
```

Then view the coverage report:

```bash
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

### Run Tests in Watch Mode

To run tests automatically when files change:

```bash
flutter test --watch
```

## Test Structure

The test suite is organized as follows:

```
test/
├── models/
│   ├── message_test.dart      # Tests for Message model
│   └── user_test.dart         # Tests for User model
├── exceptions/
│   └── app_exceptions_test.dart  # Tests for exception classes
├── services/
│   ├── chat_service_test.dart    # Tests for ChatService logic
│   ├── profile_service_test.dart # Tests for ProfileService
│   └── user_service_test.dart    # Tests for UserService
├── screens/
│   └── profile_edit_screen_test.dart  # Widget tests
└── widget_test.dart           # Critical functionality smoke tests
```

## Test Coverage

### Models (25 tests)
- **Message Model**: JSON serialization, equality, helper methods, deletion status
- **User Model**: JSON serialization, equality, online status calculation

### Exceptions (71 tests)
- **AppException**: Base exception functionality
- **AuthException**: Authentication error handling
- **NetworkException**: Network error handling
- **DatabaseException**: Database error handling
- **ChatException**: Chat/message error handling
- **ValidationException**: Input validation errors
- **StorageException**: File storage errors
- **ProfileException**: Profile operation errors
- **AICommandException**: AI command processing errors
- **ExceptionHandler**: Error message parsing and formatting

### Services (8 tests)
- **ChatService**: Message processing, validation, conversation logic
- **ProfileService**: Profile validation constants
- **UserService**: Service structure validation

### Widget Tests (4 tests)
- Critical functionality smoke tests for models

## Total: 85+ tests covering critical functionality

## What's Tested

### Critical Functionality

1. **Model Serialization**: JSON encoding/decoding for Message and User
2. **Model Equality**: Proper comparison based on IDs
3. **Helper Methods**: Message direction, user online status, etc.
4. **Exception Handling**: All exception types and error messages
5. **Message Validation**: Content validation, sender/receiver checks
6. **Conversation Logic**: Message filtering, unread counts, deletion handling

## Running Tests in CI/CD

For continuous integration, use:

```bash
flutter test --reporter expanded
```

Or with coverage:

```bash
flutter test --coverage --reporter json > test_results.json
```

## Troubleshooting

### Tests Fail with Supabase Initialization Error

Some tests require Supabase to be initialized. These tests are designed to work without actual Supabase connections by testing logic only. If you see initialization errors, ensure you're not instantiating services that require Supabase in unit tests.

### Tests Fail with Missing Dependencies

Run:

```bash
flutter pub get
```

### View Test Output Verbosely

```bash
flutter test --reporter expanded
```

## Best Practices

1. **Run tests before committing**: `flutter test`
2. **Write tests for new features**: Add tests alongside new code
3. **Keep tests fast**: Unit tests should run quickly
4. **Test edge cases**: Include tests for null values, empty strings, etc.
5. **Use descriptive test names**: Test names should clearly describe what they test

