// lib/auth/screens/register_screen.dart
import 'package:flutter/material.dart';
import 'package:apna_thekedar_specialist/api/api_service.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:apna_thekedar_specialist/splash_screen.dart';
import 'package:iconsax/iconsax.dart';

class RegisterScreen extends StatefulWidget {
  final String phoneNumber;
  final String registrationCode;

  const RegisterScreen({
    super.key,
    required this.phoneNumber,
    required this.registrationCode,
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _occupationController = TextEditingController();
  DateTime? _selectedDate;

  bool _isLoading = false;
  final ApiService _apiService = ApiService();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _occupationController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _registerUser() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() { _isLoading = true; });

    try {
      final response = await _apiService.post('/auth/create-user/', {
        'phone_number': widget.phoneNumber,
        'registration_code': widget.registrationCode,
        'name': _nameController.text,
        'email': _emailController.text,
        'user_type': 'HOME_IMPROVEMENT_SPECIALIST',
        'occupation': _occupationController.text,
        'date_of_birth': _selectedDate?.toIso8601String().split('T').first,
      });
      
      if (mounted) {
        final responseData = json.decode(response.body);
        if (response.statusCode == 201) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('accessToken', responseData['access']);
          await prefs.setString('refreshToken', responseData['refresh']);

          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const SplashScreen()),
            (route) => false,
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${responseData.toString()}')),
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
      appBar: AppBar(
        title: const Text('Create Your Account'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Welcome! Just a few more details to get you started on +91 ${widget.phoneNumber}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 30),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Full Name'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email Address'),
                validator: (value) {
                  if (value == null || !value.contains('@') || !value.contains('.')) {
                    return 'Please enter a valid email address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _occupationController,
                decoration: const InputDecoration(labelText: 'Occupation (e.g., Painter, Plumber)'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your occupation';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Date of Birth',
                  hintText: _selectedDate == null 
                      ? 'Select your date of birth' 
                      : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                  prefixIcon: const Icon(Iconsax.calendar_1),
                ),
                onTap: () => _selectDate(context),
                validator: (value){
                  if(_selectedDate == null){
                    return 'Please select your date of birth';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _isLoading ? null : _registerUser,
                child: _isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3,))
                    : const Text('Create Account'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
