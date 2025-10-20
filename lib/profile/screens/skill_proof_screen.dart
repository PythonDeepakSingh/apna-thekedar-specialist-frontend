// lib/profile/screens/skill_proof_screen.dart (Final and Complete Code)
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:apna_thekedar_specialist/api/api_service.dart';
import 'dart:convert';
import 'miscellaneous_document_screen.dart';

class SkillDocumentType {
  final int id;
  final String name;
  SkillDocumentType({required this.id, required this.name});
}

class SkillProofScreen extends StatefulWidget {
  const SkillProofScreen({super.key});

  @override
  State<SkillProofScreen> createState() => _SkillProofScreenState();
}

class _SkillProofScreenState extends State<SkillProofScreen> {
  File? _pickedFile;
  SkillDocumentType? _selectedDocType;

  List<SkillDocumentType> _documentTypes = [];
  bool _isLoading = false;
  final ApiService _apiService = ApiService();
  String _fileLabel = 'Tap to select Image/PDF';

  @override
  void initState() {
    super.initState();
    _fetchSkillDocumentTypes();
  }

  Future<void> _fetchSkillDocumentTypes() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final response =
          await _apiService.get('/specialist/documents/skill-types/');
      if (mounted && response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _documentTypes = data
              .map((item) =>
                  SkillDocumentType(id: item['id'], name: item['name']))
              .toList();
          _documentTypes.add(SkillDocumentType(id: -1, name: 'Other'));
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error fetching document types: $e')));
      }
    }
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

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

  Future<void> _saveSkillProof() async {
    if (_selectedDocType == null || _pickedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select a document type and upload a file.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final Map<String, String> fields = {
        'document_type': _selectedDocType!.id.toString(),
      };
      final Map<String, File> files = {'document_file': _pickedFile!};

      // Yahan hum 'Create' API ka istemaal kar rahe hain
      final response = await _apiService.patchWithFiles(
        '/specialist/documents/skill-proof/upload/',
        fields: fields,
        files: files,
      );

      if (mounted) {
        if (response.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Skill proof uploaded successfully!')),
          );
          Navigator.pop(context, true);
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
      appBar: AppBar(title: const Text('Skill Proof')),
      body: _isLoading && _documentTypes.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Upload Skill Certificate",
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<SkillDocumentType>(
                    value: _selectedDocType,
                    hint: const Text('Select Certificate Type'),
                    items: _documentTypes.map((SkillDocumentType doc) {
                      return DropdownMenuItem<SkillDocumentType>(
                        value: doc,
                        child: Text(doc.name),
                      );
                    }).toList(),
                    onChanged: (SkillDocumentType? newValue) async {
                      if (newValue != null && newValue.id == -1) {
                          // === YAHAN BADLAAV KIYA GAYA HAI ===
                          final result = await Navigator.push( // 'await' karke result ka intezaar karein
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const MiscellaneousDocumentScreen(
                                          documentFor: 'SKILL')));

                          // Agar miscellaneous screen se 'true' wapas aaya, to is screen ko bhi band kar do
                        if (result == true && mounted) {
                          Future.delayed(Duration.zero, () {
                            Navigator.of(context).pop(true);
                          });
                        }
                       
                      } else {
                        setState(() {
                          _selectedDocType = newValue;
                        });
                      }
                    },
                    decoration:
                        const InputDecoration(border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 16),
                  _buildFilePickerBox(),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveSkillProof,
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Save & Upload'),
                    ),
                  ),
                ],
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