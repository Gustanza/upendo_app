import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'dart:convert';

class UserPreferences {
  static const String _userKey = 'user_data';

  // Save user data to SharedPreferences
  Future<void> saveUserData(UserModel user) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String userJson = jsonEncode({
      'id': user.id,
      'fullName': user.fullName,
      'email': user
          .id, // Using id as fallback for email since it's not in the model but we usually have it
      'region': user.region,
      'country': user.country,
      'phone': user.phone,
    });
    await prefs.setString(_userKey, userJson);
  }

  // Get user data from SharedPreferences
  Future<UserModel?> getUserData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? userJson = prefs.getString(_userKey);
    if (userJson == null) return null;

    final Map<String, dynamic> userData = jsonDecode(userJson);
    return UserModel(
      id: userData['id'] ?? '',
      fullName: userData['fullName'] ?? '',
      region: userData['region'] ?? '',
      country: userData['country'] ?? '',
      phone: userData['phone'] ?? '',
    );
  }

  // Clear user data from SharedPreferences
  Future<void> clearUserData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
  }
}
