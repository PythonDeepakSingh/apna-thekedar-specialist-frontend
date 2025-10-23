// lib/profile/screens/edit_profile_screen.dart (Updated with Non-Editable Fields & Error Handling)
import 'dart:convert';
import 'dart:io'; // Image File aur InternetAddress ke liye
import 'package:apna_thekedar_specialist/api/api_service.dart';
import 'package:apna_thekedar_specialist/core/models/user_profile.dart'; // UserProfile ke liye
import 'package:apna_thekedar_specialist/core/widgets/attractive_error_widget.dart'; // Error handling ke liye
import 'package:apna_thekedar_specialist/main_nav_screen.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart'; // ApiService access ke liye
import 'package:http/http.dart' as http;

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController(); // Email abhi bhi non-editable rahega
  final _bioController = TextEditingController();
  // Experience ke liye controller abhi bhi rakhenge data display ke liye
  final _experienceController = TextEditingController(text: "Loading...");

  File? _profileImage;
  String? _networkProfileImageUrl;
  bool _isLoading = true;
  ApiService? _apiService; // ApiService ko state mein rakhenge
  String? _errorType;

  // Address display ke liye state variables
  UserProfile? _userProfile;
  String _permanentAddress = "Loading...";
  String _currentAddress = "Loading...";

  @override
  void initState() {
    super.initState();
    // initState mein context use nahi kar sakte, isliye addPostFrameCallback
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _apiService = Provider.of<ApiService>(context, listen: false);
      _loadProfileData();
    });
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
    if (_apiService == null || !mounted) return;
    setState(() {
      _isLoading = true;
      _errorType = null;
    });

    try {
      // Internet Check
      final result = await InternetAddress.lookup('google.com');
      if (result.isEmpty || result[0].rawAddress.isEmpty) {
        throw 'no_internet';
      }

      // API Calls
      final responses = await Future.wait([
        _apiService!.get('/auth/profile/'),
        UserProfile.loadFromApi(), // UserProfile model se fetch karein
      ]);

      if (mounted) {
        final userResponse = responses[0] as http.Response;
        _userProfile = responses[1] as UserProfile?; // Profile ko save karein

        if (userResponse.statusCode == 200 && _userProfile != null) {
          final userData = json.decode(userResponse.body);

          // Update controllers and state variables
          _nameController.text = userData['name'] ?? '';
          _emailController.text = userData['email'] ?? 'Not provided';
          _networkProfileImageUrl = userData['profile_photo'];
          _bioController.text = _userProfile!.bio ?? '';
          _experienceController.text = _userProfile!.experienceYears?.toString() ?? '0';

          // Addresses ko find karke set karein
          _permanentAddress = _userProfile!.addresses.firstWhere(
              (addr) => addr['address_type'] == 'PERMANENT',
              orElse: () => {'address': 'Not set'})['address'];
          _currentAddress = _userProfile!.addresses.firstWhere(
              (addr) => addr['address_type'] == 'CURRENT',
              orElse: () => {'address': 'Not set'})['address'];

        } else {
          // Agar koi response fail hota hai
          throw 'server_error';
        }
      }
    } on SocketException catch (_) {
      _errorType = 'no_internet';
    } catch (e) {
      if (mounted) {
        _errorType = e.toString() == 'server_error' ? 'server_error' : 'unknown';
      }
      print("Error loading profile data: $e"); // Debugging ke liye error print karein
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

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
                    if (pickedFile != null && mounted) {
                      setState(() { _profileImage = File(pickedFile.path); });
                    }
                  }),
              ListTile(
                leading: const Icon(Iconsax.gallery),
                title: const Text('Choose from Gallery'),
                onTap: () async {
                  Navigator.pop(context);
                  final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
                   if (pickedFile != null && mounted) {
                      setState(() { _profileImage = File(pickedFile.path); });
                    }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate() || _apiService == null) {
      return;
    }
    setState(() { _isLoading = true; });

    try {
      // User details update (Name and Photo)
      final Map<String, String> userFields = { 'name': _nameController.text };
      final Map<String, File> filesToUpload = {};
      if (_profileImage != null) {
        filesToUpload['profile_photo'] = _profileImage!;
      }
      final userResponse = await _apiService!.patchWithFiles(
        '/auth/account/update/',
        fields: userFields,
        files: filesToUpload,
      );
      if (!mounted || userResponse.statusCode != 200) {
        throw Exception('Failed to update user details: ${userResponse.body}');
      }

      // Specialist details update (Sirf Bio)
      final specialistResponse = await _apiService!.patch(
        '/specialist/profile/professional/update/',
        {'bio': _bioController.text}, // Sirf bio bhej rahe hain
      );
      if (!mounted || specialistResponse.statusCode != 200) {
        throw Exception('Failed to update professional details: ${specialistResponse.body}');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );

      // MainNavScreen ke Profile tab (index 2) par navigate karein
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

  // Read-only field banane ke liye helper widget
  Widget _buildReadOnlyField({required String label, required String value, required IconData icon}) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.grey.shade200, // Background color
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300), // Border color
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300), // Border color
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      ),
      child: Text(
        value.isEmpty ? "Not set" : value, // Agar value khaali hai to "Not set" dikhayein
        style: TextStyle(fontSize: 16, color: value.isEmpty ? Colors.grey.shade600 : Colors.black),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorType != null
              ? AttractiveErrorWidget(
                  imagePath: _errorType == 'no_internet' ? 'assets/no_internet.png' : 'assets/server_error.png',
                  title: _errorType == 'no_internet' ? "No Internet" : "Server Error",
                  message: "We couldn't load your profile data. Please check your connection and try again.",
                  buttonText: "Retry",
                  onRetry: _loadProfileData,
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Profile Picture
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
                                  ? Icon(Iconsax.user, size: 60, color: Colors.grey.shade400)
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector( // IconButton ke bajaye GestureDetector
                                onTap: _pickImage,
                                child: CircleAvatar(
                                  radius: 20,
                                  backgroundColor: Theme.of(context).primaryColor,
                                  child: const Icon(Iconsax.camera, size: 20, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // Editable Fields
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(labelText: 'Full Name'),
                          validator: (value) => value!.isEmpty ? 'Please enter your name' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField( // Email non-editable
                          controller: _emailController,
                          enabled: false,
                          decoration: InputDecoration(
                            labelText: 'Email (Cannot be changed)',
                            filled: true,
                            fillColor: Colors.grey.shade200,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Read-Only Fields
                        _buildReadOnlyField(
                          label: 'Permanent Address',
                          value: _permanentAddress,
                          icon: Iconsax.home_2,
                        ),
                        const SizedBox(height: 16),
                        _buildReadOnlyField(
                          label: 'Current (Operating) Address',
                          value: _currentAddress,
                          icon: Iconsax.location,
                        ),
                        const SizedBox(height: 16),
                        _buildReadOnlyField( // Experience non-editable
                          label: 'Years of Experience',
                          value: _experienceController.text,
                          icon: Iconsax.briefcase,
                        ),
                        const SizedBox(height: 16),

                        // Editable Bio
                        TextFormField(
                          controller: _bioController,
                          decoration: const InputDecoration(
                            labelText: 'Bio / About Me',
                            hintText: 'Aap apne kaam ke baare mein bata sakte hain',
                          ),
                          maxLines: 3,
                           validator: (value) => value == null || value.trim().length < 10 ? 'Please write at least 10 characters.' : null,
                        ),
                        const SizedBox(height: 32),

                        // Save Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _saveChanges, // Loading state ko yahan handle karein
                            child: const Text('Save Changes'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}