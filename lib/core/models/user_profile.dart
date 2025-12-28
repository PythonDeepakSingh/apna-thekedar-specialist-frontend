// lib/core/models/user_profile.dart
import 'dart:convert';
import 'package:apna_thekedar_specialist/api/api_service.dart';

class UserProfile {
  final String name;
  final String email;
  final String phoneNumber;
  final String? profilePhotoUrl;
  final String? bio;
  final int? experienceYears;
  // >>> NAYI PROPERTY YAHAN ADD KAREIN <<<
  final List<dynamic> addresses; // Yeh addresses ki list store karega
  final double workRating;
  final double behaviorRating;
  final bool isAvailable;

  UserProfile({
    required this.name,
    required this.email,
    required this.phoneNumber,
    this.profilePhotoUrl,
    this.bio,
    this.experienceYears,
    this.addresses = const [], // Default value ek khaali list hai
    this.workRating = 0.0,
    this.behaviorRating = 0.0,
    required this.isAvailable,
  });

  // Factory constructor ko update karein
  factory UserProfile.fromApis(Map<String, dynamic> userData, Map<String, dynamic> specialistData) {
    return UserProfile(
      name: userData['name'] ?? 'Specialist',
      email: userData['email'] ?? '',
      phoneNumber: userData['phone_number'] ?? '',
      profilePhotoUrl: userData['profile_photo'],
      bio: specialistData['bio'] ?? '',
      experienceYears: specialistData['experience_years'] ?? 0,
      // >>> ADDRESSES KO YAHAN EXTRACT KAREIN <<<
      addresses: specialistData['addresses'] as List? ?? [], // API se aane waale addresses
      workRating: double.tryParse(specialistData['work_rating'].toString()) ?? 0.0,
      behaviorRating: double.tryParse(specialistData['behavior_rating'].toString()) ?? 0.0,
      isAvailable: specialistData['is_available'] ?? false,
    );
  }

  // API se poori profile load karne ke liye static function
  static Future<UserProfile?> loadFromApi() async {
    try {
      final apiService = ApiService();
      // Dono API calls ko ek saath parallel mein execute karein
      final responses = await Future.wait([
        apiService.get('/auth/profile/'),
        apiService.get('/specialist/profile/'),
      ]);

      final userResponse = responses[0];
      final specialistResponse = responses[1];

      if (userResponse.statusCode == 200 && specialistResponse.statusCode == 200) {
        final userData = json.decode(userResponse.body);
        final specialistData = json.decode(specialistResponse.body);
        return UserProfile.fromApis(userData, specialistData);
      }
    } catch (e) {
      print("Could not load user profile: $e");
    }
    return null;
  }
}