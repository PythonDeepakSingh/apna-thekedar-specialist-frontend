// lib/reviews_feedback_progress/screens/create_update_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:apna_thekedar_specialist/api/api_service.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import '../models/update_image.dart';
import 'update_message_screen.dart';

class CreateUpdateScreen extends StatefulWidget {
  final int projectId;
  const CreateUpdateScreen({super.key, required this.projectId});

  @override
  State<CreateUpdateScreen> createState() => _CreateUpdateScreenState();
}

class _CreateUpdateScreenState extends State<CreateUpdateScreen> {
  String _updateMessage = '';
  // === Progress Percentage se judi lines hata di gayi hain ===
  final List<UpdateImage> _images = [];
  final ApiService _apiService = ApiService();
  bool _isLoading = false;

  @override
  void dispose() {
    for (var img in _images) {
      img.nameController.dispose();
    }
    super.dispose();
  }

  Future<void> _navigateToMessageScreen() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => UpdateMessageScreen(initialText: _updateMessage),
      ),
    );
    if (result != null) {
      setState(() {
        _updateMessage = result;
      });
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 80);
    if (pickedFile != null) {
      setState(() {
        _images.add(UpdateImage(imageFile: File(pickedFile.path), initialName: ''));
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
    });
  }

  Future<void> _sendUpdate() async {
    if (_updateMessage.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please write an update message.')));
      return;
    }
    if (_images.any((img) => img.nameController.text.trim().isEmpty)) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please provide an item name for all photos.')));
      return;
    }
    setState(() => _isLoading = true);

    try {
      final Map<String, String> fields = {
        'update_text': _updateMessage,
        // === Progress Percentage yahan se bhi hata diya gaya hai ===
      };
      final Map<String, List<File>> files = {
        'images': _images.map((e) => e.imageFile).toList(),
      };
      final Map<String, List<String>> fieldLists = {
        'item_names': _images.map((e) => e.nameController.text).toList(),
      };
      
      final response = await _apiService.postMultipart(
        '/feedback/projects/${widget.projectId}/updates/create/',
        fields: fields,
        files: files,
        fieldLists: fieldLists,
      );
      
      if (mounted) {
        if (response.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Update sent successfully!')));
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${response.body}')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('An error occurred: $e')));
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Send Project Update')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Update Message", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            InkWell(
              onTap: _navigateToMessageScreen,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _updateMessage.isEmpty ? 'Tap to write a message...' : _updateMessage,
                  style: TextStyle(color: _updateMessage.isEmpty ? Colors.grey.shade600 : Colors.black, fontSize: 16),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const Divider(height: 30),
            
            // === Progress Percentage wala poora section yahan se delete ho gaya hai ===

            const Text('Add Photos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ..._images.asMap().entries.map((entry) => _buildImageTile(entry.key, entry.value)),
            OutlinedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Iconsax.camera),
              label: const Text('Add Photo with Item Name'),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: _isLoading ? null : _sendUpdate,
          child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Send Update'),
        ),
      ),
    );
  }

  Widget _buildImageTile(int index, UpdateImage image) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => showDialog(
                context: context,
                builder: (_) => Dialog(child: Image.file(image.imageFile)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Image.file(image.imageFile, width: 60, height: 60, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: image.nameController,
                decoration: const InputDecoration(
                  labelText: 'Item Name',
                  hintText: 'e.g., Almirah, Kitchen Wall'
                ),
                // === BADLAAV 2: Item name ab do line ka ho sakta hai ===
                maxLines: 2,
              ),
            ),
            IconButton(
              icon: const Icon(Iconsax.trash, color: Colors.red),
              onPressed: () => _removeImage(index),
            ),
          ],
        ),
      ),
    );
  }
}