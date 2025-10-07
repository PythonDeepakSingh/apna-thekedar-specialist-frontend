// lib/projects/screens/waiting_quotation_screen.dart (Chat Button ke Saath Naya Version)
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:apna_thekedar_specialist/main_nav_screen.dart';
import 'package:apna_thekedar_specialist/api/api_service.dart';
import 'package:apna_thekedar_specialist/core/models/user_profile.dart';
import 'package:apna_thekedar_specialist/chat/chat_screen.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;


class WaitingQuotationConfirmationScreen extends StatefulWidget {
  final int projectId;
  const WaitingQuotationConfirmationScreen({super.key, required this.projectId});

  @override
  State<WaitingQuotationConfirmationScreen> createState() => _WaitingQuotationConfirmationScreenState();
}

class _WaitingQuotationConfirmationScreenState extends State<WaitingQuotationConfirmationScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String _customerName = "Customer";
  String _myName = "Me";

  @override
  void initState() {
    super.initState();
    _fetchRequiredDetails();
  }

  // Naya function: Chat ke liye zaroori details fetch karega
  Future<void> _fetchRequiredDetails() async {
    try {
      // Hum project details aur specialist ki profile, dono ek saath fetch karenge
      final responses = await Future.wait([
        _apiService.get('/projects/${widget.projectId}/details/'),
        UserProfile.loadFromApi(),
      ]);

      if (mounted) {
        final projectResponse = responses[0] as http.Response;
        final profile = responses[1] as UserProfile?;

        if (projectResponse.statusCode == 200 && profile != null) {
          final projectData = json.decode(projectResponse.body);
          setState(() {
            _customerName = projectData['customer']?['name'] ?? 'Customer';
            _myName = profile.name;
            _isLoading = false;
          });
        } else {
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      print("Error fetching details for chat: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    const Color darkColor = Color(0xFF4B2E1E);

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Iconsax.clock, size: 60, color: Colors.orange),
              const SizedBox(height: 20),
              const Text(
                'Quotation Sent!',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                'We have notified the customer. Please wait for their confirmation.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              
              // Buttons ka naya layout
              _isLoading
                ? const CircularProgressIndicator()
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Chat ka button
                      ElevatedButton.icon(
                        icon: const Icon(Iconsax.message),
                        label: const Text('Chat with Customer'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: darkColor,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => ChatScreen(
                              projectId: widget.projectId,
                              customerName: _customerName,
                              myName: _myName,
                            ))
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      // Dashboard ka button
                      OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (_) => const MainNavScreen()),
                            (route) => false,
                          );
                        },
                        child: const Text('Back to Dashboard'),
                      ),
                    ],
                  )
            ],
          ),
        ),
      ),
    );
  }
}