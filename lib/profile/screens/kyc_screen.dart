// lib/profile/screens/kyc_screen.dart (FINAL & COMPLETE CODE with Error Handling)
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'dart:convert';
import 'package:apna_thekedar_specialist/api/api_service.dart';
import 'package:apna_thekedar_specialist/profile/screens/identity_proof_view_screen.dart';
import 'package:apna_thekedar_specialist/profile/screens/address_proof_list_screen.dart';
import 'package:apna_thekedar_specialist/profile/screens/skill_proof_list_screen.dart';

// === Naye Imports ===
import 'dart:io';
import 'package:apna_thekedar_specialist/core/widgets/attractive_error_widget.dart';

class KycScreen extends StatefulWidget {
  const KycScreen({super.key});

  @override
  State<KycScreen> createState() => _KycScreenState();
}

class _KycScreenState extends State<KycScreen> {
  final ApiService _apiService = ApiService();
  // === Future variable banayenge ===
  late Future<Map<String, dynamic>> _kycStatusFuture;

  @override
  void initState() {
    super.initState();
    _kycStatusFuture = _fetchKycStatus();
  }
  
  // === Is function ko update kiya gaya hai ===
  Future<Map<String, dynamic>> _fetchKycStatus() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isEmpty || result[0].rawAddress.isEmpty) {
        throw const SocketException("No Internet");
      }
    } on SocketException catch (_) {
      throw const SocketException("No Internet");
    }

    final response = await _apiService.get('/specialist/documents/kyc-status/');
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load KYC status');
    }
  }

  void _refreshData() {
    setState(() {
      _kycStatusFuture = _fetchKycStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('KYC & Documentation'),
        actions: [
          IconButton(
            icon: const Icon(Iconsax.refresh),
            onPressed: _refreshData,
            tooltip: 'Refresh Status',
          )
        ],
      ),
      // === body ko FutureBuilder se banayenge ===
      body: FutureBuilder<Map<String, dynamic>>(
        future: _kycStatusFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            bool isInternetError = snapshot.error is SocketException;
            return AttractiveErrorWidget(
              imagePath: isInternetError ? 'assets/no_internet.png' : 'assets/server_error.png',
              title: isInternetError ? "No Internet" : "Server Error",
              message: isInternetError
                  ? "Please check your connection and try again."
                  : "Could not load your KYC status.",
              buttonText: "Retry",
              onRetry: _refreshData,
            );
          }

          // Jab data aa jaye, to UI banayein
          return RefreshIndicator(
            onRefresh: () async => _refreshData(),
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                const Text(
                  'Complete your profile by uploading the required documents.',
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                ),
                const SizedBox(height: 24),
                
                _buildKycSectionCard(
                  icon: Iconsax.card,
                  title: 'Identity Proof',
                  subtitle: 'Aadhaar Card & PAN Card details',
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const IdentityProofViewScreen()),
                    );
                    if (result == true) {
                      _refreshData();
                    }
                  },
                ),
                const SizedBox(height: 16),

                _buildKycSectionCard(
                  icon: Iconsax.home_2,
                  title: 'Permanent Address Proof',
                  subtitle: 'Upload permanent address documents',
                  onTap: () async {
                    final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => 
                      const AddressProofListScreen(addressType: 'Permanent')
                    ));
                    if (result == true) {
                      _refreshData();
                    }
                  },
                ),
                const SizedBox(height: 16),

                _buildKycSectionCard(
                  icon: Iconsax.location,
                  title: 'Current/Operating Address Proof',
                  subtitle: 'Upload current address documents',
                  onTap: () async {
                    final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => 
                      const AddressProofListScreen(addressType: 'Current')
                    ));
                     if (result == true) {
                      _refreshData();
                    }
                  },
                ),
                const SizedBox(height: 16),

                _buildKycSectionCard(
                  icon: Iconsax.rulerpen,
                  title: 'Skill Proof',
                  subtitle: 'Upload your skill certificates',
                  onTap: () async {
                    final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const SkillProofListScreen()));
                    if (result == true) {
                      _refreshData();
                    }
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Is helper function me koi badlav nahi hai
  Widget _buildKycSectionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(icon, size: 40, color: Theme.of(context).primaryColor),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(subtitle,
                        style:
                            const TextStyle(fontSize: 14, color: Colors.grey)),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}