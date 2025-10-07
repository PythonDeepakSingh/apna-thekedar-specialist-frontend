// lib/profile/screens/identity_proof_screen.dart (Nayi File)
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import 'package:apna_thekedar_specialist/api/api_service.dart';

class IdentityProofScreen extends StatefulWidget {
  const IdentityProofScreen({super.key});

  @override
  State<IdentityProofScreen> createState() => _IdentityProofScreenState();
}

class _IdentityProofScreenState extends State<IdentityProofScreen> {
  final _formKey = GlobalKey<FormState>();
  final _panController = TextEditingController();
  final _aadhaarController = TextEditingController();
  
  File? _panImage;
  File? _aadhaarFrontImage;
  File? _aadhaarBackImage;

  bool _isLoading = false;
  final ApiService _apiService = ApiService();

  // Photo khichne ke liye function
  Future<void> _pickImage(ImageSource source, Function(File) onImagePicked) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 80);

    if (pickedFile != null) {
      setState(() {
        onImagePicked(File(pickedFile.path));
      });
    }
  }

  // Data ko save karne ke liye function
  Future<void> _saveIdentityProof() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    // Check karo ki saari photos li gayi hain ya nahi
    if (_panImage == null || _aadhaarFrontImage == null || _aadhaarBackImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload all three document images.')),
      );
      return;
    }

    setState(() { _isLoading = true; });

    try {
      final Map<String, String> fields = {
        'pan_number': _panController.text,
        'aadhaar_number': _aadhaarController.text,
      };

      final Map<String, File> files = {
        'pan_document_image': _panImage!,
        'aadhaar_front_image': _aadhaarFrontImage!,
        'aadhaar_back_image': _aadhaarBackImage!,
      };

      final response = await _apiService.patchWithFiles(
        '/specialist/documents/identity/update/', // URL ko yahan update karein
        fields: fields,
        files: files,
      );

      if (mounted) {
        if (response.statusCode == 200 || response.statusCode == 201) {
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Identity details uploaded successfully!')),
          );
          Navigator.pop(context, true); // Page band karke wapas jao
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${response.body}')),
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
      appBar: AppBar(title: const Text('Identity Proof')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // PAN Card Section
              Text("PAN Card Details", style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextFormField(
                controller: _panController,
                decoration: const InputDecoration(labelText: 'PAN Number'),
                validator: (value) => value!.isEmpty ? 'Please enter PAN number' : null,
              ),
              const SizedBox(height: 16),
              _buildImagePickerBox(
                label: 'PAN Card Photo',
                imageFile: _panImage,
                onTap: () => _pickImage(ImageSource.camera, (file) => _panImage = file),
              ),
              
              const SizedBox(height: 32),

              // Aadhaar Card Section
              Text("Aadhaar Card Details", style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextFormField(
                controller: _aadhaarController,
                decoration: const InputDecoration(labelText: 'Aadhaar Number'),
                 validator: (value) => value!.isEmpty ? 'Please enter Aadhaar number' : null,
              ),
              const SizedBox(height: 16),
              _buildImagePickerBox(
                label: 'Aadhaar Card (Front Side)',
                imageFile: _aadhaarFrontImage,
                onTap: () => _pickImage(ImageSource.camera, (file) => _aadhaarFrontImage = file),
              ),
              const SizedBox(height: 16),
              _buildImagePickerBox(
                label: 'Aadhaar Card (Back Side)',
                imageFile: _aadhaarBackImage,
                onTap: () => _pickImage(ImageSource.camera, (file) => _aadhaarBackImage = file),
              ),

              const SizedBox(height: 40),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveIdentityProof,
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : const Text('Save & Upload'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Image picker box banane ke liye ek reusable widget
  Widget _buildImagePickerBox({
    required String label,
    File? imageFile,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 150,
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(12),
        ),
        child: imageFile != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: Image.file(imageFile, fit: BoxFit.cover),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Iconsax.camera, color: Colors.grey.shade600, size: 40),
                  const SizedBox(height: 8),
                  Text(label, style: TextStyle(color: Colors.grey.shade700)),
                ],
              ),
      ),
    );
  }
}