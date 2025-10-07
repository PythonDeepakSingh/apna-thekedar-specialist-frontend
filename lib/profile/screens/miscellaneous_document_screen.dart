// lib/profile/screens/miscellaneous_document_screen.dart (Final Code)
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:apna_thekedar_specialist/api/api_service.dart';

class MiscellaneousDocumentScreen extends StatefulWidget {
  final String documentFor; // 'SKILL', 'PERMANENT_ADDRESS', ya 'CURRENT_ADDRESS'
  const MiscellaneousDocumentScreen({super.key, required this.documentFor});

  @override
  State<MiscellaneousDocumentScreen> createState() =>
      _MiscellaneousDocumentScreenState();
}

class _MiscellaneousDocumentScreenState
    extends State<MiscellaneousDocumentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _docNameController = TextEditingController();
  File? _pickedFile;
  String _fileLabel = 'Tap to select Image/PDF';
  bool _isLoading = false;
  final ApiService _apiService = ApiService();

  Future<void> _pickFile() async {
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
                    final picked = await ImagePicker()
                        .pickImage(source: ImageSource.camera, imageQuality: 80);
                    if (picked != null) {
                      setState(() {
                        _pickedFile = File(picked.path);
                        _fileLabel = picked.path.split('/').last;
                      });
                    }
                  }),
              ListTile(
                leading: const Icon(Iconsax.gallery),
                title: const Text('Choose from Gallery'),
                onTap: () async {
                  Navigator.pop(context);
                  final picked = await ImagePicker()
                      .pickImage(source: ImageSource.gallery, imageQuality: 80);
                  if (picked != null) {
                    setState(() {
                      _pickedFile = File(picked.path);
                      _fileLabel = picked.path.split('/').last;
                    });
                  }
                },
              ),
              ListTile(
                leading: const Icon(Iconsax.document),
                title: const Text('Choose PDF Document'),
                onTap: () async {
                  Navigator.pop(context);
                  final result = await FilePicker.platform.pickFiles(
                    type: FileType.custom,
                    allowedExtensions: ['pdf'],
                  );
                  if (result != null) {
                    setState(() {
                      _pickedFile = File(result.files.single.path!);
                      _fileLabel = result.files.single.name;
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

  Future<void> _saveMiscDocument() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_pickedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload a document file.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final Map<String, String> fields = {
        'document_name': _docNameController.text,
        'document_for': widget.documentFor,
      };

      final Map<String, File> files = {
        'document_file': _pickedFile!,
      };

      final response = await _apiService.postWithFiles(
        '/specialist/documents/misc/upload/',
        fields: fields,
        files: files,
      );

      if (mounted) {
        if (response.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Document uploaded successfully!')),
          );
          // Dono pichli screens (address proof aur misc doc) ko band karke KYC screen par jao
          Navigator.of(context).popUntil((route) => route.isFirst);
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

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Other Document'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Upload a custom document",
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextFormField(
                controller: _docNameController,
                decoration: const InputDecoration(
                    labelText: 'Document Name',
                    hintText: 'e.g., Rent Agreement'),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter a document name' : null,
              ),
              const SizedBox(height: 24),
              _buildFilePickerBox(),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveMiscDocument,
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

  Widget _buildFilePickerBox() {
    return InkWell(
      onTap: _pickFile,
      child: Container(
        height: 150,
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(12),
        ),
        child: _pickedFile != null
            ? Center(
                child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Iconsax.document_1,
                      color: Theme.of(context).primaryColor, size: 40),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(_fileLabel,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade700)),
                  ),
                ],
              ))
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Iconsax.document_upload,
                      color: Colors.grey.shade600, size: 40),
                  const SizedBox(height: 8),
                  Text(_fileLabel,
                      style: TextStyle(color: Colors.grey.shade700)),
                ],
              ),
      ),
    );
  }
}