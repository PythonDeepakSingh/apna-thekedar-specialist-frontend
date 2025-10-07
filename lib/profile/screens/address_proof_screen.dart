// lib/profile/screens/address_proof_screen.dart (Final Code)
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:apna_thekedar_specialist/api/api_service.dart';
import 'dart:convert';
// Miscellaneous document screen ko import karein
import 'miscellaneous_document_screen.dart';

class DocumentType {
  final int id;
  final String name;
  DocumentType({required this.id, required this.name});
}

class AddressProofScreen extends StatefulWidget {
  final String addressType; // 'Permanent' ya 'Current'

  const AddressProofScreen({super.key, required this.addressType});

  @override
  State<AddressProofScreen> createState() => _AddressProofScreenState();
}

class _AddressProofScreenState extends State<AddressProofScreen> {
  bool _useIdentityProof = false;
  File? _pickedFile;
  DocumentType? _selectedDocType;
  
  List<DocumentType> _documentTypes = [];
  bool _isLoading = false;
  final ApiService _apiService = ApiService();
  String _fileLabel = 'Tap to select Image/PDF';

  @override
  void initState() {
    super.initState();
    _fetchDocumentTypes();
  }

  Future<void> _fetchDocumentTypes() async {
    setState(() { _isLoading = true; });
    try {
      final response = await _apiService.get('/specialist/documents/address-types/');
      if (mounted && response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _documentTypes = data.map((item) => DocumentType(id: item['id'], name: item['name'])).toList();
          // "Other" option ko list mein jod dein
          _documentTypes.add(DocumentType(id: -1, name: 'Other'));
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error fetching document types: $e')));
      }
    }
    if (mounted) {
      setState(() { _isLoading = false; });
    }
  }

  // File ya photo pick karne ke liye function
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
                    final picked = await ImagePicker().pickImage(source: ImageSource.camera);
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
                  final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
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

  Future<void> _saveAddressProof() async {
    setState(() { _isLoading = true; });

    try {
      if (_useIdentityProof) {
        // Agar checkbox tick hai, toh nayi API call karein
        final response = await _apiService.post('/specialist/documents/identity/use-as-address-proof/', {
          'address_type': widget.addressType == 'Permanent' ? 'PERMANENT' : 'CURRENT',
        });
        if (mounted) {
          if (response.statusCode == 200) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Successfully updated!')));
            Navigator.pop(context, true);
          } else {
             ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${response.body}')));
          }
        }
      } else {
        // Agar checkbox tick nahi hai, toh file upload karein
        if (_selectedDocType == null || _pickedFile == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select a document type and upload a file.')),
          );
          setState(() => _isLoading = false);
          return;
        }

        final Map<String, String> fields = {
          'address_type': widget.addressType == 'Permanent' ? 'PERMANENT' : 'CURRENT',
          'document_type': _selectedDocType!.id.toString(),
        };

        final Map<String, File> files = {
          'document_file': _pickedFile!,
        };

        final response = await _apiService.postWithFiles(
          '/specialist/documents/address-proof/upload/',
          fields: fields,
          files: files,
        );

        if (mounted) {
          if (response.statusCode == 201) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Address proof uploaded successfully!')));
            Navigator.pop(context, true);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${response.body}')));
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('An error occurred: $e')));
      }
    }

    if (mounted) {
      setState(() { _isLoading = false; });
    }
  }
  // =========================================================================


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.addressType} Address Proof')),
      body: _isLoading && _documentTypes.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CheckboxListTile(
                    title: const Text("Use Aadhaar/PAN as Address Proof"),
                    value: _useIdentityProof,
                    onChanged: (value) {
                      setState(() => _useIdentityProof = value!);
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    activeColor: Theme.of(context).primaryColor,
                  ),
                  const Divider(height: 40),
                  Opacity(
                    opacity: _useIdentityProof ? 0.5 : 1.0,
                    child: AbsorbPointer(
                      absorbing: _useIdentityProof,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Or, Upload a different document", style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<DocumentType>(
                            value: _selectedDocType,
                            hint: const Text('Select Document Type'),
                            items: _documentTypes.map((DocumentType doc) {
                              return DropdownMenuItem<DocumentType>(
                                value: doc,
                                child: Text(doc.name),
                              );
                            }).toList(),
                            onChanged: (DocumentType? newValue) {
                              if (newValue != null && newValue.id == -1) {
                                // Agar "Other" select hua hai
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => MiscellaneousDocumentScreen(
                                      // Hum address type ko yahan se bhejenge
                                      documentFor: widget.addressType == 'Permanent' 
                                          ? 'PERMANENT_ADDRESS' 
                                          : 'CURRENT_ADDRESS',
                                    ),
                                  ),
                                );
                              } else {
                                setState(() {
                                  _selectedDocType = newValue;
                                });
                              }
                            },
                            decoration: const InputDecoration(border: OutlineInputBorder()),
                          ),
                          const SizedBox(height: 16),
                          _buildFilePickerBox(),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveAddressProof,
                      child: _isLoading 
                        ? const CircularProgressIndicator(color: Colors.white) 
                        : const Text('Save'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildFilePickerBox() {
    return InkWell(
      onTap: _useIdentityProof ? null : _pickFile,
      child: Container(
        height: 150,
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(12),
        ),
        child: _pickedFile != null
            ? Center(child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Iconsax.document_1, color: Theme.of(context).primaryColor, size: 40),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(_fileLabel, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade700)),
                  ),
                ],
              ))
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Iconsax.document_upload, color: Colors.grey.shade600, size: 40),
                  const SizedBox(height: 8),
                  Text(_fileLabel, style: TextStyle(color: Colors.grey.shade700)),
                ],
              ),
      ),
    );
  }
}