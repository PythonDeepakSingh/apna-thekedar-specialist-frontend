// lib/profile/screens/kyc_screen.dart (FINAL & COMPLETE CODE)
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'dart:convert';
import 'package:apna_thekedar_specialist/api/api_service.dart';
import 'package:apna_thekedar_specialist/profile/screens/identity_proof_view_screen.dart';
import 'package:apna_thekedar_specialist/profile/screens/address_proof_list_screen.dart';
// Naya import Skill List Screen ke liye
import 'package:apna_thekedar_specialist/profile/screens/skill_proof_list_screen.dart';

class KycScreen extends StatefulWidget {
  const KycScreen({super.key});

  @override
  State<KycScreen> createState() => _KycScreenState();
}

class _KycScreenState extends State<KycScreen> {
  final ApiService _apiService = ApiService();
  // Hum status fetch karte rahenge, bas use UI mein nahi dikhayenge
  Map<String, String?> _kycStatus = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchKycStatus();
  }

  Future<void> _fetchKycStatus() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }
    try {
      final response = await _apiService.get('/specialist/documents/kyc-status/');
      if (mounted && response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _kycStatus = {
            'identity': data['identity_status'],
            'permanent_address': data['permanent_address_status'],
            'current_address': data['current_address_status'],
            'skill': data['skill_proof_status'],
          };
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to load KYC status: $e')));
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
        title: const Text('KYC & Documentation'),
        actions: [
          IconButton(
            icon: const Icon(Iconsax.refresh),
            onPressed: _fetchKycStatus,
            tooltip: 'Refresh Status',
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchKycStatus,
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  const Text(
                    'Complete your profile by uploading the required documents.',
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                  const SizedBox(height: 24),
                  
                  // Section 1: Identity Proof
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
                        _fetchKycStatus();
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  // Section 2: Permanent Address
                  _buildKycSectionCard(
                    icon: Iconsax.home_2,
                    title: 'Permanent Address Proof',
                    subtitle: 'Upload permanent address documents',
                    onTap: () async {
                      final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => 
                        const AddressProofListScreen(addressType: 'Permanent')
                      ));
                      if (result == true) {
                        _fetchKycStatus();
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  // Section 3: Current Address
                  _buildKycSectionCard(
                    icon: Iconsax.location,
                    title: 'Current/Operating Address Proof',
                    subtitle: 'Upload current address documents',
                    onTap: () async {
                      final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => 
                        const AddressProofListScreen(addressType: 'Current')
                      ));
                       if (result == true) {
                        _fetchKycStatus();
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  // Section 4: Skill Proof
                  _buildKycSectionCard(
                    icon: Iconsax.rulerpen, // Sahi icon 'ruler_pen' hai
                    title: 'Skill Proof',
                    subtitle: 'Upload your skill certificates',
                    onTap: () async {
                      // ==================== YAHAN BADLAAV KIYA GAYA HAI ====================
                      // Ab yeh Skill List Screen par jaayega
                      final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const SkillProofListScreen()));
                      if (result == true) {
                        _fetchKycStatus();
                      }
                      // =====================================================================
                    },
                  ),
                ],
              ),
            ),
    );
  }

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
              // ==================== YAHAN SE STATUS WALA HISSA HATA DIYA GAYA HAI ====================
              // Ab yahan sirf arrow dikhega
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
              // =======================================================================================
            ],
          ),
        ),
      ),
    );
  }
}