// lib/auth/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:apna_thekedar_specialist/api/api_service.dart';
import 'package:apna_thekedar_specialist/auth/screens/register_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:apna_thekedar_specialist/splash_screen.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final ApiService _apiService = ApiService();

  bool _isLoading = false;
  bool _otpSent = false;
  String? _registrationCode;

  Future<void> _generateOtp() async {
    if (_phoneController.text.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid 10-digit phone number')),
      );
      return;
    }
    setState(() { _isLoading = true; });

    try {
      // ==================== YAHAN BADLAAV KIYA GAYA HAI ====================
      // Ab hum 'publicPost' ka istemaal kar rahe hain
      final response = await _apiService.publicPost('/auth/generate-otp/', {
        'phone_number': _phoneController.text,
      });
      // ===================================================================

      if (mounted) {
        if (response.statusCode == 200) {
          setState(() {
            _otpSent = true;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('OTP sent successfully!')),
          );
        } else {
          final error = json.decode(response.body);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${error['error'] ?? 'Failed to send OTP'}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An error occurred: $e')),
        );
      }
    }
    if (mounted) setState(() { _isLoading = false; });
  }

  Future<void> _verifyOtp() async {
    if (_otpController.text.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the 6-digit OTP')),
      );
      return;
    }
    setState(() { _isLoading = true; });

    try {
      // OTP verify karne ke liye bhi publicPost ka istemaal hoga
      final response = await _apiService.publicPost('/auth/verify-otp/', {
        'phone_number': _phoneController.text,
        'otp': _otpController.text,
      });

      if (mounted) {
        final responseData = json.decode(response.body);
        if (response.statusCode == 200) {
          
          if (responseData.containsKey('access')) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('accessToken', responseData['access']);
            await prefs.setString('refreshToken', responseData['refresh']);
            
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const SplashScreen()),
            );

          } else if (responseData.containsKey('registration_code')) {
            _registrationCode = responseData['registration_code'];
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => RegisterScreen(
                phoneNumber: _phoneController.text,
                registrationCode: _registrationCode!,
              )),
            );
          }
        } else {
           ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${responseData['error'] ?? 'Invalid OTP'}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An error occurred: $e')),
        );
      }
    }
     if (mounted) setState(() { _isLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.engineering, size: 60, color: Color(0xFF4B2E1E)),
              const SizedBox(height: 20),
              const Text(
                'Welcome, Specialist!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                _otpSent 
                  ? 'Enter the OTP sent to +91 ${_phoneController.text}' 
                  : 'Enter your phone number to login or register',
                style: const TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              if (!_otpSent)
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: '10-digit Phone Number',
                    prefixText: '+91 ',
                  ),
                ),
              
              if (_otpSent)
                TextField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 6,
                  decoration: const InputDecoration(
                    labelText: '6-digit OTP',
                  ),
                ),
              
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : (_otpSent ? _verifyOtp : _generateOtp),
                child: _isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3,))
                    : Text(_otpSent ? 'Verify & Continue' : 'Get OTP'),
              ),
              if (_otpSent)
                TextButton(
                  onPressed: () => setState(() => _otpSent = false),
                  child: const Text('Change Number?'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}