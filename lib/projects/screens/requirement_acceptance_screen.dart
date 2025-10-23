// lib/projects/screens/requirement_acceptance_screen.dart
import 'package:flutter/material.dart';
import 'package:apna_thekedar_specialist/api/api_service.dart';
import 'package:apna_thekedar_specialist/projects/screens/project_details_screen.dart';
import 'package:apna_thekedar_specialist/core/widgets/attractive_error_widget.dart'; // Agar error aaye to
import 'package:iconsax/iconsax.dart';
import 'dart:convert';
import 'dart:io'; // Agar error aaye to
import 'requirement_unavailable_screen.dart';

class RequirementAcceptanceScreen extends StatefulWidget {
  final int requirementId;
  final int projectId;
  final Map<String, dynamic> initialData; // List se mila initial data

  const RequirementAcceptanceScreen({
    super.key,
    required this.requirementId,
    required this.projectId,
    required this.initialData,
  });

  @override
  State<RequirementAcceptanceScreen> createState() => _RequirementAcceptanceScreenState();
}

class _RequirementAcceptanceScreenState extends State<RequirementAcceptanceScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  String? _error; // Agar accept karne mein error aaye

  // Function to accept the requirement
  Future<void> _acceptRequirement() async {
    setState(() => _isLoading = true);
    _error = null;

    try {
      final response = await _apiService.post(
          '/projects/requirements/${widget.requirementId}/accept/', {});

      if (mounted) {
        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Requirement accepted!'),
                backgroundColor: Colors.green),
          );
          // Wapas list screen par 'true' bhejein taaki woh refresh ho sake
          // Navigator.of(context).pop(true); // Iski zaroorat nahi, seedha project detail pe jayenge

          // Seedha project detail screen par le jayein
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
                builder: (_) => ProjectDetailScreen(projectId: widget.projectId)),
          );
        } else {
          final responseData = json.decode(response.body);
          // Agar error 'You are not yet eligible...' hai to RequirementUnavailableScreen dikhayein
          if (responseData['error'] != null && responseData['error'].toString().contains('not yet eligible')) {
             Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const RequirementUnavailableScreen()), // Error screen
             );
          } else {
            // Doosre errors ke liye SnackBar dikhayein
            setState(() => _error = responseData['error'] ?? 'Failed to accept.');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text('Error: ${_error!}'), backgroundColor: Colors.red),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'An error occurred: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_error!), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Initial data ka istemaal karein
    final project = widget.initialData['project'];
    final description = widget.initialData['description'] ?? 'No description provided.';
    final customerName = project?['customer']?['name'] ?? 'Customer';
    final address = project?['address'] ?? 'Address not available';
    final pincode = project?['pincode'] ?? '';
    // --- NAYI LINES ---
    final projectTitle = project?['title'] ?? 'Requirement Details';
    final propertyType = project?['property_type'] ?? 'N/A';
    // --- -------- ---

    return Scaffold(
      appBar: AppBar(
        title: Text(projectTitle), // AppBar ka title update kiya
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // === YEH NAYA SECTION ADD KIYA GAYA HAI ===
            _buildSectionTitle('Project Info'),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Iconsax.folder_open),
              title: Text(projectTitle),
              subtitle: Text("Property: $propertyType"), // Property type
            ),
            const Divider(height: 20),
            // ==========================================

            // Customer Details
            _buildSectionTitle('Customer'),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                child: Text(customerName.isNotEmpty ? customerName[0] : 'C'),
              ),
              title: Text(customerName),
            ),
            const Divider(height: 20),

            // Location
            _buildSectionTitle('Location'),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Iconsax.location),
              title: Text(address),
              subtitle: Text('Pincode: $pincode'),
            ),
            const Divider(height: 20),

            // Description
            _buildSectionTitle('Work Description'),
            Text(description, style: const TextStyle(fontSize: 15, height: 1.5)),
            const SizedBox(height: 20),

            // Agar accept karne mein error aaya ho to dikhayein
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Text('Error: $_error', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              ),
          ],
        ),
      ),
      // Bottom Navigation Bar for the Accept Button
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton.icon(
          icon: _isLoading ? Container(width: 24, height: 24, padding: const EdgeInsets.all(2.0), child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 3)) : const Icon(Iconsax.tick_circle),
          label: Text(_isLoading ? 'Accepting...' : 'Accept Requirement'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          onPressed: _isLoading ? null : _acceptRequirement,
        ),
      ),
    );
  }

  // Helper widget for section titles
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade700),
      ),
    );
  }
}