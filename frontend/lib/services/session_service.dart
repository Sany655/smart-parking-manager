import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class SessionService {
  static const String _userKey = 'user_data';
  static const String _userIdKey = 'user_id';
  static const String _emailKey = 'email';
  static const String _usernameKey = 'username';
  static const String _vehicleNumberKey = 'vehicle_number';
  static const String _isLoggedInKey = 'is_logged_in';

  /// Save user data after login
  static Future<void> saveUserData(Map<String, dynamic> userData) async {
    print('Saving user data: $userData');
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Handle different possible user_id key names
      int? userId;
      if (userData.containsKey('user_id')) {
        userId = userData['user_id'] as int?;
      } else if (userData.containsKey('id')) {
        userId = userData['id'] as int?;
      }
      
      if (userId != null) {
        await prefs.setInt(_userIdKey, userId);
      }
      
      if (userData.containsKey('email')) {
        await prefs.setString(_emailKey, userData['email']);
      }
      if (userData.containsKey('username')) {
        await prefs.setString(_usernameKey, userData['username']);
      }
      if (userData.containsKey('vehicle_number')) {
        await prefs.setString(_vehicleNumberKey, userData['vehicle_number'] ?? '');
      }
      
      // Save entire user object as JSON
      await prefs.setString(_userKey, jsonEncode(userData));
      await prefs.setBool(_isLoggedInKey, true);
      
      print('User data saved successfully');
    } catch (e) {
      print('Error saving user data: $e');
      rethrow;
    }
  }

  /// Get user ID
  static Future<int?> getUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_userIdKey);
    } catch (e) {
      print('Error getting user ID: $e');
      return null;
    }
  }

  /// Get email
  static Future<String?> getEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_emailKey);
    } catch (e) {
      print('Error getting email: $e');
      return null;
    }
  }

  /// Get username
  static Future<String?> getUsername() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_usernameKey);
    } catch (e) {
      print('Error getting username: $e');
      return null;
    }
  }

  /// Get vehicle number
  static Future<String?> getVehicleNumber() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_vehicleNumberKey);
    } catch (e) {
      print('Error getting vehicle number: $e');
      return null;
    }
  }

  /// Get entire user data
  static Future<Map<String, dynamic>?> getUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_userKey);
      if (userJson != null) {
        return jsonDecode(userJson) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  /// Check if user is logged in
  static Future<bool> isLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_isLoggedInKey) ?? false;
    } catch (e) {
      print('Error checking login status: $e');
      return false;
    }
  }

  /// Clear user data (logout)
  static Future<void> clearUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userKey);
      await prefs.remove(_userIdKey);
      await prefs.remove(_emailKey);
      await prefs.remove(_usernameKey);
      await prefs.remove(_vehicleNumberKey);
      await prefs.setBool(_isLoggedInKey, false);
      print('User data cleared successfully');
    } catch (e) {
      print('Error clearing user data: $e');
      rethrow;
    }
  }

  /// Update specific user field
  static Future<void> updateUserField(String key, dynamic value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (value is String) {
        await prefs.setString(key, value);
      } else if (value is int) {
        await prefs.setInt(key, value);
      } else if (value is bool) {
        await prefs.setBool(key, value);
      }
      print('User field updated successfully');
    } catch (e) {
      print('Error updating user field: $e');
      rethrow;
    }
  }
}
