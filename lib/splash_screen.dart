// lib/splash_screen.dart (FINAL & CORRECTED)
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

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AuthService _authService = AuthService();
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }
  
  Future<void> _initializeApp() async {
    await _setupInteractedMessage();
    await _navigateUser();
  }

  Future<void> _setupInteractedMessage() async {
    RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();

    if (initialMessage != null) {
      Future.delayed(const Duration(seconds: 1), () {
        // Ab hum sahi public function ko call kar rahe hain
        _notificationService.handleNotificationTap(initialMessage.data);
      });
    }

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
       // Yahan bhi sahi public function ko call kar rahe hain
       _notificationService.handleNotificationTap(message.data);
    });
  }

  Future<void> _sendDeviceTokenToBackend() async {
    try {
      final String? token = await _notificationService.getFCMToken();
      
      if (token != null) {
        print("FCM Token: $token");
        final apiService = ApiService();
        await apiService.post('/notifications/devices/register/', {
          'registration_id': token,
          'type': 'android'
        });
        print("FCM Token sent to backend successfully.");
      }
    } catch (e) {
      print("Failed to get or send FCM token: $e");
    }
  }

  Future<void> _navigateUser() async {
     await Future.delayed(const Duration(seconds: 2));

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

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => targetScreen),
    );
  }
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4B2E1E),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
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

