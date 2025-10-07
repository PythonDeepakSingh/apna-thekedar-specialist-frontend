// lib/profile/screens/edit_profile_screen.dart (Photo Picker Updated)
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import 'package:apna_thekedar_specialist/api/api_service.dart';
import 'dart:convert';
import 'package:apna_thekedar_specialist/main_nav_screen.dart'; // Dashboard pe jaane ke liye

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _bioController = TextEditingController();
  final _experienceController = TextEditingController();

  File? _profileImage;
  String? _networkProfileImageUrl;
  bool _isLoading = true;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _bioController.dispose();
    _experienceController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileData() async {
    try {
      final responses = await Future.wait([
        _apiService.get('/auth/profile/'),
        _apiService.get('/specialist/profile/'),
      ]);

      if (mounted) {
        final userResponse = responses[0];
        final specialistResponse = responses[1];
        if (userResponse.statusCode == 200 && specialistResponse.statusCode == 200) {
          final userData = json.decode(userResponse.body);
          final specialistData = json.decode(specialistResponse.body);
          _nameController.text = userData['name'] ?? '';
          _emailController.text = userData['email'] ?? 'Not provided';
          _networkProfileImageUrl = userData['profile_photo'];
          _bioController.text = specialistData['bio'] ?? '';
          _experienceController.text = specialistData['experience_years']?.toString() ?? '0';
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to load profile data.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An error occurred while loading profile: $e')),
        );
      }
    }
    if (mounted) {
      setState(() { _isLoading = false; });
    }
  }

  // ==================== YAHAN PAR HAI ASLI BADLAAV ====================
  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                  leading: const Icon(Iconsax.camera),
                  title: const Text('Take Photo'),
                  onTap: () async {
                    Navigator.pop(context);
                    final pickedFile = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 80);
                    if (pickedFile != null) {
                      setState(() {
                        _profileImage = File(pickedFile.path);
                      });
                    }
                  }),
              ListTile(
                leading: const Icon(Iconsax.gallery),
                title: const Text('Choose from Gallery'),
                onTap: () async {
                  Navigator.pop(context);
                  final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
                   if (pickedFile != null) {
                      setState(() {
                        _profileImage = File(pickedFile.path);
                      });
                    }
                },
              ),
            ],
          ),
        );
      },
    );
  }
  // =====================================================================

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() { _isLoading = true; });

    try {
      final Map<String, String> userFields = { 'name': _nameController.text };
      final Map<String, File> filesToUpload = {};

      if (_profileImage != null) {
        filesToUpload['profile_photo'] = _profileImage!;
      }

      final userResponse = await _apiService.patchWithFiles(
        '/auth/account/update/',
        fields: userFields,
        files: filesToUpload,
      );
      
      if (!mounted) return;
      if (userResponse.statusCode != 200) {
        throw Exception('Failed to update user details: ${userResponse.body}');
      }

      final specialistResponse = await _apiService.patch(
        '/specialist/profile/professional/update/',
        {
          'bio': _bioController.text,
          'experience_years': int.tryParse(_experienceController.text) ?? 0,
        },
      );
      
      if (!mounted) return;
      if (specialistResponse.statusCode != 200) {
        throw Exception('Failed to update professional details: ${specialistResponse.body}');
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );
      
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const MainNavScreen(initialIndex: 2)),
        (route) => false,
      );

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An error occurred: $e')),
        );
      }
    } finally {
       if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundImage: _profileImage != null
                              ? FileImage(_profileImage!)
                              : (_networkProfileImageUrl != null && _networkProfileImageUrl!.isNotEmpty
                                  ? NetworkImage(_networkProfileImageUrl!)
                                  : null) as ImageProvider?,
                          child: _profileImage == null && (_networkProfileImageUrl == null || _networkProfileImageUrl!.isEmpty)
                              ? const Icon(Iconsax.user, size: 60)
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: IconButton(
                            icon: const CircleAvatar(
                              radius: 20,
                              child: Icon(Iconsax.camera, size: 20),
                            ),
                            onPressed: _pickImage,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Full Name'),
                      validator: (value) => value!.isEmpty ? 'Please enter your name' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      enabled: false,
                      decoration: const InputDecoration(
                        labelText: 'Email (Cannot be changed)',
                        filled: true,
                        fillColor: Color.fromARGB(255, 236, 236, 236),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _bioController,
                      decoration: const InputDecoration(
                        labelText: 'Bio / About Me',
                        hintText: 'Aap apne kaam ke baare mein bata sakte hain',
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _experienceController,
                      decoration: const InputDecoration(labelText: 'Years of Experience'),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveChanges,
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('Save Changes'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}