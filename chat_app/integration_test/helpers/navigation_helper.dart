import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Helper class for navigation and widget interaction in integration tests.
class NavigationHelper {
  /// Waits for the widget tree to settle (animations complete).
  static Future<void> waitForSettle(WidgetTester tester) async {
    await tester.pumpAndSettle(const Duration(seconds: 2));
  }

  /// Waits for a specific widget to appear.
  static Future<void> waitForWidget(
    WidgetTester tester,
    Finder finder, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final endTime = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(endTime)) {
      await tester.pump();
      if (finder.evaluate().isNotEmpty) {
        await waitForSettle(tester);
        return;
      }
      await Future.delayed(const Duration(milliseconds: 100));
    }
    throw TimeoutException('Widget not found: $finder', timeout);
  }

  /// Taps a widget found by text.
  static Future<void> tapByText(WidgetTester tester, String text) async {
    final finder = find.text(text);
    await waitForWidget(tester, finder);
    await tester.tap(finder);
    await waitForSettle(tester);
  }

  /// Taps a widget found by key.
  static Future<void> tapByKey(WidgetTester tester, Key key) async {
    final finder = find.byKey(key);
    await waitForWidget(tester, finder);
    await tester.tap(finder);
    await waitForSettle(tester);
  }

  /// Taps a widget found by type.
  static Future<void> tapByType<T extends Widget>(WidgetTester tester) async {
    final finder = find.byType(T);
    await waitForWidget(tester, finder);
    await tester.tap(finder);
    await waitForSettle(tester);
  }

  /// Taps a widget found by icon.
  static Future<void> tapByIcon(WidgetTester tester, IconData icon) async {
    final finder = find.byIcon(icon);
    await waitForWidget(tester, finder);
    await tester.tap(finder);
    await waitForSettle(tester);
  }

  /// Enters text into a text field found by key or finder.
  static Future<void> enterText(
    WidgetTester tester,
    Finder finder,
    String text,
  ) async {
    await waitForWidget(tester, finder);
    await tester.tap(finder);
    await waitForSettle(tester);
    await tester.enterText(finder, text);
    await waitForSettle(tester);
  }

  /// Enters text into a text field found by text (label).
  static Future<void> enterTextByLabel(
    WidgetTester tester,
    String label,
    String text,
  ) async {
    final finder = find.text(label);
    await waitForWidget(tester, finder);
    // Find the associated TextField
    final textFieldFinder = find.descendant(
      of: find.ancestor(of: finder, matching: find.byType(TextField)),
      matching: find.byType(TextField),
    );
    if (textFieldFinder.evaluate().isEmpty) {
      // Try finding TextFormField
      final formFieldFinder = find.descendant(
        of: find.ancestor(of: finder, matching: find.byType(TextFormField)),
        matching: find.byType(TextFormField),
      );
      if (formFieldFinder.evaluate().isNotEmpty) {
        await enterText(tester, formFieldFinder, text);
        return;
      }
    } else {
      await enterText(tester, textFieldFinder, text);
      return;
    }
    throw Exception('Could not find text field for label: $label');
  }

  /// Scrolls to make a widget visible.
  static Future<void> scrollToWidget(
    WidgetTester tester,
    Finder finder,
  ) async {
    await tester.scrollUntilVisible(
      finder,
      500.0,
      scrollable: find.byType(Scrollable),
    );
    await waitForSettle(tester);
  }

  /// Navigates back.
  static Future<void> goBack(WidgetTester tester) async {
    final backButton = find.byType(BackButton);
    if (backButton.evaluate().isNotEmpty) {
      await tester.tap(backButton);
    } else {
      final iconButton = find.byIcon(Icons.arrow_back);
      if (iconButton.evaluate().isNotEmpty) {
        await tester.tap(iconButton);
      } else {
        // Try using system back
        await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
          'flutter/navigation',
          null,
          (data) {},
        );
      }
    }
    await waitForSettle(tester);
  }

  /// Waits for a specific text to appear on screen.
  static Future<void> waitForText(
    WidgetTester tester,
    String text, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    await waitForWidget(tester, find.text(text), timeout: timeout);
  }

  /// Checks if a widget exists on screen.
  static bool widgetExists(Finder finder) {
    return finder.evaluate().isNotEmpty;
  }

  /// Finds the first ListTile and taps it.
  static Future<void> tapFirstListTile(WidgetTester tester) async {
    final finder = find.byType(ListTile).first;
    await waitForWidget(tester, finder);
    await tester.tap(finder);
    await waitForSettle(tester);
  }
}

