import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Generic local storage service using SharedPreferences with JSON encoding.
class LocalStorageService {
  static SharedPreferences? _prefs;

  static Future<SharedPreferences> get _instance async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  /// Saves a list of JSON-serializable objects.
  static Future<void> saveList(
    String key,
    List<Map<String, dynamic>> items,
  ) async {
    final prefs = await _instance;
    final jsonString = jsonEncode(items);
    await prefs.setString(key, jsonString);
  }

  /// Loads a list of JSON objects.
  static Future<List<Map<String, dynamic>>> loadList(String key) async {
    final prefs = await _instance;
    final jsonString = prefs.getString(key);
    if (jsonString == null) return [];
    final decoded = jsonDecode(jsonString) as List<dynamic>;
    return decoded.cast<Map<String, dynamic>>();
  }

  /// Removes a key from storage.
  static Future<void> remove(String key) async {
    final prefs = await _instance;
    await prefs.remove(key);
  }
}
