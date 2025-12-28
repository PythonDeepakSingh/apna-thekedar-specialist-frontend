// lib/projects/screens/short_service_acceptance_screen.dart (NAYI FILE)
import 'package:flutter/material.dart';
import 'package:apna_thekedar_specialist/api/api_service.dart';
import 'package:apna_thekedar_specialist/projects/screens/project_details_screen.dart';
import 'package:iconsax/iconsax.dart';
import 'dart:convert';
import 'requirement_unavailable_screen.dart';
import 'package:apna_thekedar_specialist/projects/screens/short_service_detail_screen.dart';

class ShortServiceAcceptanceScreen extends StatefulWidget {
  final int bookingId;
  final Map<String, dynamic> initialData; // List se mila initial data

  const ShortServiceAcceptanceScreen({
    super.key,
    required this.bookingId,
    required this.initialData,
  });

  @override
  State<ShortServiceAcceptanceScreen> createState() => _ShortServiceAcceptanceScreenState();
}

class _ShortServiceAcceptanceScreenState extends State<ShortServiceAcceptanceScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  String? _error;

  // Function to accept the requirement
  Future<void> _acceptShortService() async {
    setState(() => _isLoading = true);
    _error = null;

    try {
      // NAYI API CALL (YEH HUMEIN ABHI BANANI HAI)
      final response = await _apiService.post(
          '/projects/short-service/${widget.bookingId}/accept/', {});

      if (mounted) {
        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Job accepted!'),
                backgroundColor: Colors.green),
          );
          
          // Seedha "Short Service Detail" screen par le jayein
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
                builder: (_) => ShortServiceDetailScreen(bookingId: widget.bookingId)),
          );
        } else {
          final responseData = json.decode(response.body);
          // Agar error 'not yet eligible' ya 'no longer available' hai
          if (responseData['error'] != null) {
             Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const RequirementUnavailableScreen()),
             );
          } else {
            setState(() => _error = responseData['error'] ?? 'Failed to accept.');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'An error occurred: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Initial data ka istemaal karein
    final title = widget.initialData['title'] ?? 'Short Service';
    final address = widget.initialData['address'] ?? 'Address not available';
    final pincode = widget.initialData['pincode'] ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Job Title'),
            Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const Divider(height: 20),
            
            _buildSectionTitle('Location'),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Iconsax.location),
              title: Text(address),
              subtitle: Text('Pincode: $pincode'),
            ),
            const Divider(height: 20),

            _buildSectionTitle('Description'),
            const Text("Details for this short service job will be available after acceptance.", style: TextStyle(fontSize: 15, height: 1.5)),
            const SizedBox(height: 20),

            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Text('Error: $_error', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton.icon(
          icon: _isLoading ? Container(width: 24, height: 24, padding: const EdgeInsets.all(2.0), child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 3)) : const Icon(Iconsax.tick_circle),
          label: Text(_isLoading ? 'Accepting...' : 'Accept Short Job'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: Colors.blue.shade700 // Alag color
          ),
          onPressed: _isLoading ? null : _acceptShortService,
        ),
      ),
    );
  }

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