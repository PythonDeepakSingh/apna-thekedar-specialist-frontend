// lib/services/auth_service.dart

import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:apna_thekedar_specialist/api/api_service.dart';

class AuthService {
  final ApiService _apiService = ApiService();

  Future<String> getUserStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('accessToken');

    if (accessToken == null) {
      return 'LOGGED_OUT';
    }

    try {
      final userResponse = await _apiService.get('/auth/profile/');
      
      if (userResponse.statusCode != 200) {
         await logout();
         return 'LOGGED_OUT';
      }
      
      final userData = json.decode(userResponse.body);

      if (userData['is_email_verified'] == false) {
        return 'NEEDS_EMAIL_VERIFICATION';
      }

      try {
        final profileResponse = await _apiService.get('/specialist/profile/');
        
        if (profileResponse.statusCode == 200) {
          final profileData = json.decode(profileResponse.body);

          // ==================== YAHAN PAR HAI ASLI FIX ====================
          // Check karo ki specialist ka koi address hai ya nahi.
          // Agar address list khaali hai, to matlab profile abhi banani hai.
          final addresses = profileData['addresses'] as List?;
          if (addresses == null || addresses.isEmpty) {
            return 'NEEDS_PROFILE_CREATION';
          }
          // ===============================================================

          final skills = profileData['long_skills'] as List;
          if (skills.isEmpty) {
            return 'NEEDS_SERVICE_SELECTION';
          }
          return 'LOGGED_IN';
        } else {
           // Agar profile hai hi nahi, to bhi profile banani hai
           return 'NEEDS_PROFILE_CREATION';
        }
      } catch (e) {
        // Agar profile fetch karne mein koi error aaye, to bhi profile banani hai
        return 'NEEDS_PROFILE_CREATION';
      }

    } catch (e) {
      print("Error getting user status: $e");
      await logout();
      return 'LOGGED_OUT';
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}