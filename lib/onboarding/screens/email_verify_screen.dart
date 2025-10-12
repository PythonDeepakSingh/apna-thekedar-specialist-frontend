// lib/onboarding/screens/email_verify_screen.dart
import 'package:flutter/material.dart';
import 'package:apna_thekedar_specialist/api/api_service.dart';
import 'package:apna_thekedar_specialist/services/auth_service.dart';
import 'package:apna_thekedar_specialist/splash_screen.dart';
import 'dart:convert';

class EmailVerifyScreen extends StatefulWidget {
  const EmailVerifyScreen({super.key});

  @override
  State<EmailVerifyScreen> createState() => _EmailVerifyScreenState();
}

class _EmailVerifyScreenState extends State<EmailVerifyScreen> {
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();
  final _otpController = TextEditingController();

  String _userEmail = "...";
  bool _isLoading = false;
  bool _otpSent = false;

  @override
  void initState() {
    super.initState();
    _fetchUserEmail();
  }

  // User ka email get karna taaki use screen par dikha sakein
  Future<void> _fetchUserEmail() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.get('/auth/profile/');
      if (mounted && response.statusCode == 200) {
        final userData = json.decode(response.body);
        setState(() {
          _userEmail = userData['email'] ?? 'No email found';
        });
      }
    } catch (e) {
      // Handle error
    }
    setState(() => _isLoading = false);
  }

  // Email par OTP bhejne ke liye
  Future<void> _sendEmailOtp() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.post('/auth/email/generate-otp/', {});
      if (mounted) {
        if (response.statusCode == 200) {
          setState(() => _otpSent = true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Verification OTP has been sent to your email.')),
          );
        } else {
           ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${json.decode(response.body)['detail']}')),
          );
        }
      }
    } catch (e) {
      // Handle error
    }
    setState(() => _isLoading = false);
  }

  // Daale gaye OTP ko verify karne ke liye
  Future<void> _verifyEmailOtp() async {
    if (_otpController.text.length != 6) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the 6-digit OTP')),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
        final response = await _apiService.post('/auth/email/verify-otp/', {'otp': _otpController.text});
         if (mounted) {
            if (response.statusCode == 200) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Email verified successfully!')),
                );
                // Ab wapas splash screen par jao taaki woh agla step (profile creation) check kare
                Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const SplashScreen()),
                    (route) => false,
                );
            } else {
                 ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: ${json.decode(response.body)['detail']}')),
                );
            }
         }
    } catch (e) {
        // Handle error
    }
    setState(() => _isLoading = false);
  }

  // Logout karne ke liye
  void _logout() async {
    await _authService.logout();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const SplashScreen()),
        (route) => false,
      );
    }
  }

  Future<void> _changeEmail(String newEmail) async {
    setState(() => _isLoading = true);
    try {
      // API ENDPOINT KO BADAL KAR NAYA WALA DAALEIN
      final response = await _apiService.patch('/auth/account/change-email/', {'email': newEmail});
      
      if (mounted) {
        if (response.statusCode == 200) {
          final responseData = json.decode(response.body);
          setState(() {
            _userEmail = responseData['email'];
            _otpSent = false;
            _otpController.clear();
          });
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Email updated! Please verify your new email.')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${response.body}')));
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('An error occurred: $e')));
    }
    setState(() => _isLoading = false);
  }

  // FUNCTION 2: POPUP DIALOG DIKHANE KE LIYE
  void _showChangeEmailDialog() {
    final emailController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Change Email Address'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(hintText: "Enter new email"),
              validator: (value) {
                if (value == null || !value.contains('@') || !value.contains('.')) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  _changeEmail(emailController.text);
                }
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Your Email'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.email_outlined, size: 60, color: Color(0xFF4B2E1E)),
              const SizedBox(height: 20),
              const Text(
                'Verification Required',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'To continue, please verify your email address:\n$_userEmail',
                style: const TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              
              TextButton(
                onPressed: _showChangeEmailDialog,
                child: const Text('Change Email Address?'),
              ),
                            
              // OTP input field, jo OTP bhejne ke baad dikhega
              if (_otpSent)
                TextField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 6,
                  decoration: const InputDecoration(labelText: '6-digit OTP'),
                ),

              const SizedBox(height: 20),
              
              // Main button, jo context ke hisaab se badlega
              ElevatedButton(
                onPressed: _isLoading ? null : (_otpSent ? _verifyEmailOtp : _sendEmailOtp),
                child: _isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3,))
                    : Text(_otpSent ? 'Verify Email' : 'Send Verification Code'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}