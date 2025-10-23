// lib/profile/screens/identity_proof_view_screen.dart (FINAL CODE with Error Handling)
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'dart:convert';
import 'package:apna_thekedar_specialist/api/api_service.dart';
import 'package:apna_thekedar_specialist/profile/screens/identity_proof_screen.dart';

// === Naye Imports ===
import 'dart:io';
import 'package:apna_thekedar_specialist/core/widgets/attractive_error_widget.dart';

class IdentityProofViewScreen extends StatefulWidget {
  const IdentityProofViewScreen({super.key});

  @override
  State<IdentityProofViewScreen> createState() =>
      _IdentityProofViewScreenState();
}

class _IdentityProofViewScreenState extends State<IdentityProofViewScreen> {
  final ApiService _apiService = ApiService();
  late Future<Map<String, dynamic>> _documentFuture;

  @override
  void initState() {
    super.initState();
    _documentFuture = _fetchIdentityProof();
  }

  // === Is function me Internet Check add kiya gaya hai ===
  Future<Map<String, dynamic>> _fetchIdentityProof() async {
    // Internet Check
    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isEmpty || result[0].rawAddress.isEmpty) {
        throw const SocketException("No Internet");
      }
    } on SocketException catch (_) {
      throw const SocketException("No Internet");
    }

    final response =
        await _apiService.get('/specialist/documents/identity/');
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      if (response.statusCode == 404) {
        return {}; // Khaali data matlab "Not uploaded yet"
      }
      // Server se error aane par
      throw Exception('Failed to load identity details');
    }
  }
  
  void _refreshData() {
    setState(() {
      _documentFuture = _fetchIdentityProof();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Identity Proof"),
        actions: [
          IconButton(
            icon: const Icon(Iconsax.refresh),
            onPressed: _refreshData,
          ),
        ],
      ),
      // === body me FutureBuilder ko update kiya gaya hai ===
      body: FutureBuilder<Map<String, dynamic>>(
        future: _documentFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Error Handling
          if (snapshot.hasError) {
            bool isInternetError = snapshot.error is SocketException;
            return AttractiveErrorWidget(
              imagePath: isInternetError ? 'assets/no_internet.png' : 'assets/server_error.png',
              title: isInternetError ? "No Internet" : "Server Error",
              message: isInternetError 
                  ? "Please check your connection and try again."
                  : "Could not load your identity details.",
              buttonText: "Retry",
              onRetry: _refreshData,
            );
          }
          
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState();
          }

          final data = snapshot.data!;
          final status = data['status'];
          final bool canEdit = status != 'APPROVED';

          // Aapka purana UI
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('PAN Number:', data['pan_number'] ?? 'Not provided'),
                _buildDetailRow('Aadhaar Number:', data['aadhaar_number'] ?? 'Not provided'),
                _buildDetailRow('Status:', status ?? 'Not Uploaded'),
                const Divider(height: 32),
                _buildPhotoViewer('PAN Card', data['pan_document_image_url']),
                const SizedBox(height: 16),
                _buildPhotoViewer('Aadhaar (Front)', data['aadhaar_front_image_url']),
                const SizedBox(height: 16),
                _buildPhotoViewer('Aadhaar (Back)', data['aadhaar_back_image_url']),
                const SizedBox(height: 32),
                if (canEdit)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const IdentityProofScreen()),
                        );
                        if (result == true) {
                          _refreshData();
                        }
                      },
                      child: const Text("Upload / Edit Details"),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Baaki ke helper functions waise hi rahenge
  Widget _buildPhotoViewer(String title, String? imageUrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: imageUrl != null && imageUrl.isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(child: CircularProgressIndicator());
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(child: Icon(Iconsax.gallery_slash, color: Colors.red));
                    },
                  ),
                )
              : const Center(
                  child: Text('No Image Uploaded', style: TextStyle(color: Colors.grey)),
                ),
        ),
      ],
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Iconsax.document_upload, size: 60, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No identity documents have been uploaded yet.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const IdentityProofScreen()),
                );
                if (result == true) {
                   _refreshData();
                }
              },
              child: const Text('Upload Documents'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Text(value, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}