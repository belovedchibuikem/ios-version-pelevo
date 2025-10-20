import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';

class StorageService {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';
  static const String _expiryKey = 'token_expiry';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<void> saveToken(String token) async {
    try {
      debugPrint('💾 STORAGE SERVICE: Saving token to secure storage');
      debugPrint('💾 STORAGE SERVICE: Token length: ${token.length}');
      debugPrint(
          '💾 STORAGE SERVICE: Token preview: ${token.substring(0, 10)}...');

      await _storage.write(key: _tokenKey, value: token);

      // Verify the token was saved
      final savedToken = await _storage.read(key: _tokenKey);
      if (savedToken == token) {
        debugPrint('💾 STORAGE SERVICE: Token saved and verified successfully');
      } else {
        debugPrint('💾 STORAGE SERVICE: WARNING - Token verification failed!');
        debugPrint(
            '💾 STORAGE SERVICE: Expected: ${token.substring(0, 10)}...');
        debugPrint(
            '💾 STORAGE SERVICE: Saved: ${savedToken?.substring(0, 10)}...');
      }
    } catch (e) {
      debugPrint('💾 STORAGE SERVICE ERROR: Failed to save token: $e');
      rethrow;
    }
  }

  Future<String?> getToken() async {
    try {
      debugPrint('💾 STORAGE SERVICE: Retrieving token from secure storage');
      final token = await _storage.read(key: _tokenKey);

      if (token != null) {
        debugPrint('💾 STORAGE SERVICE: Token retrieved successfully');
        debugPrint('💾 STORAGE SERVICE: Token length: ${token.length}');
        debugPrint(
            '💾 STORAGE SERVICE: Token preview: ${token.substring(0, 10)}...');
      } else {
        debugPrint('💾 STORAGE SERVICE: No token found in storage');
      }

      return token;
    } catch (e) {
      debugPrint('💾 STORAGE SERVICE ERROR: Failed to retrieve token: $e');
      return null;
    }
  }

  Future<void> saveTokenExpiry(String expiry) async {
    debugPrint('💾 STORAGE SERVICE: Saving token expiry: $expiry');
    await _storage.write(key: _expiryKey, value: expiry);
    debugPrint('💾 STORAGE SERVICE: Token expiry saved successfully');
  }

  Future<String?> getTokenExpiry() async {
    debugPrint(
        '💾 STORAGE SERVICE: Retrieving token expiry from secure storage');
    final expiry = await _storage.read(key: _expiryKey);
    debugPrint('💾 STORAGE SERVICE: Token expiry retrieved: $expiry');
    return expiry;
  }

  Future<void> saveUserData(Map<String, dynamic> userData) async {
    debugPrint('💾 STORAGE SERVICE: Saving user data to secure storage');
    // Convert the user data to a JSON string
    final jsonString = jsonEncode(userData);
    await _storage.write(key: _userKey, value: jsonString);
    debugPrint('💾 STORAGE SERVICE: User data saved successfully');
  }

  Future<Map<String, dynamic>?> getUserData() async {
    debugPrint('💾 STORAGE SERVICE: Retrieving user data from secure storage');
    final jsonString = await _storage.read(key: _userKey);
    if (jsonString != null) {
      try {
        // Parse the JSON string back to a Map
        final userData = jsonDecode(jsonString) as Map<String, dynamic>;
        debugPrint('💾 STORAGE SERVICE: User data retrieved successfully');
        return userData;
      } catch (e) {
        debugPrint('💾 STORAGE SERVICE ERROR: Error parsing user data: $e');
        return null;
      }
    }
    debugPrint('💾 STORAGE SERVICE: No user data found');
    return null;
  }

  Future<void> clearAll() async {
    debugPrint('💾 STORAGE SERVICE: Clearing all secure storage');
    await _storage.deleteAll();
    debugPrint('💾 STORAGE SERVICE: All storage cleared successfully');
  }

  // Test method to verify storage is working
  Future<bool> testStorage() async {
    try {
      debugPrint('💾 STORAGE SERVICE: Testing secure storage...');

      // Test writing
      await _storage.write(key: 'test_key', value: 'test_value');
      debugPrint('💾 STORAGE SERVICE: Test write successful');

      // Test reading
      final value = await _storage.read(key: 'test_key');
      debugPrint('💾 STORAGE SERVICE: Test read result: $value');

      // Test deleting
      await _storage.delete(key: 'test_key');
      debugPrint('💾 STORAGE SERVICE: Test delete successful');

      final afterDelete = await _storage.read(key: 'test_key');
      debugPrint('💾 STORAGE SERVICE: After delete: $afterDelete');

      return value == 'test_value' && afterDelete == null;
    } catch (e) {
      debugPrint('💾 STORAGE SERVICE ERROR: Storage test failed: $e');
      return false;
    }
  }

  // Removed testAuthFlow in production to avoid test tokens contaminating auth

  // Debug method to check current stored data
  Future<void> debugCurrentStorage() async {
    try {
      debugPrint('💾 STORAGE SERVICE: === DEBUG CURRENT STORAGE ===');
      final token = await getToken();
      final user = await getUserData();
      final expiry = await getTokenExpiry();

      debugPrint(
          '💾 STORAGE SERVICE: Current token: ${token != null ? "Present (${token.substring(0, 10)}...)" : "Missing"}');
      debugPrint(
          '💾 STORAGE SERVICE: Current user: ${user != null ? "Present" : "Missing"}');
      debugPrint('💾 STORAGE SERVICE: Current expiry: $expiry');
      debugPrint('💾 STORAGE SERVICE: === END DEBUG ===');
    } catch (e) {
      debugPrint('💾 STORAGE SERVICE ERROR: Failed to debug storage: $e');
    }
  }
}
