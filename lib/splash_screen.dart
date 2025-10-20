// lib/splash_screen.dart
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:apna_thekedar_specialist/auth/screens/login_screen.dart';
import 'package:apna_thekedar_specialist/onboarding/screens/email_verify_screen.dart';
import 'package:apna_thekedar_specialist/onboarding/screens/create_profile_screen.dart';
import 'package:apna_thekedar_specialist/onboarding/screens/select_services_screen.dart';
import 'package:apna_thekedar_specialist/services/auth_service.dart';
import 'package:apna_thekedar_specialist/main_nav_screen.dart';
import 'package:apna_thekedar_specialist/api/api_service.dart';
import 'package:apna_thekedar_specialist/services/notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:apna_thekedar_specialist/core/widgets/update_dialog.dart';
import 'dart:convert';
import 'dart:io';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    // Provider ko safely access karne ke liye addPostFrameCallback ka istemaal karein
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApp();
    });
  }
  
  Future<void> _initializeApp() async {
    // Notification service ko Provider se get karein
    final notificationService = Provider.of<NotificationService>(context, listen: false);

    // Yeh function ab app ke band hone par notification tap ko handle karega
    await notificationService.initialize();
    
    // Baaki ka logic (user navigation) waise hi chalega
    await _navigateUser();
  }

  // Is function ko ab `ApiService` ki zaroorat nahi
  Future<void> _sendDeviceTokenToBackend() async {
    try {
      final String? token = await FirebaseMessaging.instance.getToken();
      
      if (token != null && mounted) {
        print("FCM Token: $token");
        // ApiService ko Provider se lein
        final apiService = Provider.of<ApiService>(context, listen: false);
        await apiService.post('/notifications/devices/register/', {
          'registration_id': token,
          'type': 'android' // Aap ise dynamically bhi set kar sakte hain
        });
        print("FCM Token sent to backend successfully.");
      }
    } catch (e) {
      print("Failed to get or send FCM token: $e");
    }
  }

  Future<void> _navigateUser() async {
    // Is delay ki ab zaroorat nahi hai, UI apne aap handle kar lega
    // await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final String status = await _authService.getUserStatus();
    
    if (status == 'LOGGED_IN') {
      await _sendDeviceTokenToBackend();
    }
    
    Widget targetScreen;
    switch (status) {
      case 'LOGGED_OUT':
        targetScreen = const LoginScreen();
        break;
      case 'NEEDS_EMAIL_VERIFICATION':
        targetScreen = const EmailVerifyScreen();
        break;
      case 'NEEDS_PROFILE_CREATION':
        targetScreen = const CreateProfileScreen();
        break;
      case 'NEEDS_SERVICE_SELECTION':
        targetScreen = const SelectServicesScreen();
        break;
      case 'LOGGED_IN':
        targetScreen = const MainNavScreen();
        break;
      default:
        targetScreen = const LoginScreen();
    }

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => targetScreen),
      );
    }
  }

 // === YEH NAYA FUNCTION ADD KAREIN ===
  Future<bool> _checkForUpdate() async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersionCode = packageInfo.buildNumber;
      final deviceType = Platform.isAndroid ? 'ANDROID' : 'IOS';

      final response = await apiService.checkForUpdate(currentVersionCode, deviceType);

      // Agar server ne update ki jaankari bheji hai
      if (response.statusCode == 200 && mounted) {
        final updateInfo = json.decode(response.body);
        
        // Popup dikhayein
        showDialog(
          context: context,
          // Agar restricted hai, toh user popup band nahi kar payega
          barrierDismissible: !(updateInfo['is_restricted'] ?? false), 
          builder: (BuildContext context) {
            return UpdateDialog(updateInfo: updateInfo);
          },
        );
        
        // Agar update restricted hai, toh true return karein
        return updateInfo['is_restricted'] ?? false;
      }
    } catch (e) {
      print("Failed to check for update: $e");
    }
    
    // Agar koi update nahi hai ya error aaya, toh false return karein
    return false;
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4B2E1E),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
                    width: 150,
                    height: 150,
                    child: Image.asset('assets/logo.png'),
                  ),
                  const SizedBox(height: 20),
            const Icon(Icons.engineering, color: Colors.white, size: 80),
            const SizedBox(height: 20),
            const Text(
              'Apna Thekedar\nSpecialist',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 40),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withOpacity(0.8)),
            ),
          ],
        ),
      ),
    );
  }
}