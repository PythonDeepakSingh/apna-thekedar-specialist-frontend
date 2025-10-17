// lib/services/auth_service.dart

import 'package:flutter/material.dart'; // YEH NAYI LINE ADD KAREIN
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:apna_thekedar_specialist/api/api_service.dart';

// 'with ChangeNotifier' YAHAN ADD KAREIN
class AuthService with ChangeNotifier {
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
          
          final addresses = profileData['addresses'] as List?;
          if (addresses == null || addresses.isEmpty) {
            return 'NEEDS_PROFILE_CREATION';
          }
          
          final skills = profileData['long_skills'] as List;
          if (skills.isEmpty) {
            return 'NEEDS_SERVICE_SELECTION';
          }
          return 'LOGGED_IN';
        } else {
           return 'NEEDS_PROFILE_CREATION';
        }
      } catch (e) {
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