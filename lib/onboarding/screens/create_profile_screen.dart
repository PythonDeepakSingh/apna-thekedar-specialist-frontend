// lib/onboarding/screens/create_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:apna_thekedar_specialist/onboarding/screens/set_operating_address.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CreateProfileScreen extends StatefulWidget {
  const CreateProfileScreen({super.key});

  @override
  State<CreateProfileScreen> createState() => _CreateProfileScreenState();
}

class _CreateProfileScreenState extends State<CreateProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _bioController = TextEditingController();
  final _experienceController = TextEditingController();
  final _addressController = TextEditingController();
  final _pincodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Screen khulte hi phone mein save kiya hua data load karein
    _loadDraftData();
  }

  @override
  void dispose() {
    _bioController.dispose();
    _experienceController.dispose();
    _addressController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  // Agar user ne aadha form bhar kar chhod diya tha, to use load karein
  Future<void> _loadDraftData() async {
    final prefs = await SharedPreferences.getInstance();
    _bioController.text = prefs.getString('draft_bio') ?? '';
    _experienceController.text = prefs.getString('draft_experience') ?? '';
    _addressController.text = prefs.getString('draft_permanent_address') ?? '';
    _pincodeController.text = prefs.getString('draft_pincode') ?? '';
  }

  // Agle step par jaane ke liye
  Future<void> _navigateToNextStep() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Step 1: Data ko phone mein temporarily save karein
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('draft_bio', _bioController.text);
    await prefs.setString('draft_experience', _experienceController.text);
    await prefs.setString('draft_permanent_address', _addressController.text);
    await prefs.setString('draft_pincode', _pincodeController.text);

    // Step 2: Ab is data ko agle screen (map waali screen) par bhejein
    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => SetOperatingAddressScreen(
            // Hum saara data agle screen ko de rahe hain
            profileData: {
              'bio': _bioController.text,
              'experience_years': int.tryParse(_experienceController.text) ?? 0,
              'permanent_address': _addressController.text,
              'permanent_pincode': _pincodeController.text,
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Your Professional Profile (1/2)'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Iconsax.user_edit, size: 60, color: Color(0xFF4B2E1E)),
              const SizedBox(height: 20),
              const Text(
                'Tell us about yourself',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              
              TextFormField(
                controller: _bioController,
                decoration: const InputDecoration(labelText: 'About You / Your Work (Bio)'),
                maxLines: 3,
                validator: (value) => value == null || value.trim().length < 10 ? 'Please write at least 10 characters.' : null,
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _experienceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Years of Experience', prefixIcon: Icon(Iconsax.briefcase)),
                validator: (value) => value == null || value.isEmpty || int.tryParse(value) == null ? 'Please enter a valid number.' : null,
              ),
              const Divider(height: 40),

              const Text('Permanent Address', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Full Address'),
                maxLines: 2,
                 validator: (value) => value == null || value.trim().isEmpty ? 'Please enter your address.' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _pincodeController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: const InputDecoration(labelText: 'Pincode', counterText: ""),
                 validator: (value) => value == null || value.trim().length != 6 ? 'Please enter a valid 6-digit pincode.' : null,
              ),
              const SizedBox(height: 30),

              ElevatedButton(
                onPressed: _navigateToNextStep,
                child: const Text('Save & Set Operating Address'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}