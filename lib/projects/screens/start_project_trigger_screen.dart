import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:apna_thekedar_specialist/projects/screens/project_details_screen.dart';
import 'package:apna_thekedar_specialist/api/api_service.dart';
import 'package:apna_thekedar_specialist/core/models/user_profile.dart';
import 'package:apna_thekedar_specialist/chat/chat_screen.dart';
import 'package:apna_thekedar_specialist/main_nav_screen.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class StartProjectTriggerScreen extends StatefulWidget {
  final int projectId;
  const StartProjectTriggerScreen({super.key, required this.projectId});

  @override
  State<StartProjectTriggerScreen> createState() => _StartProjectTriggerScreenState();
}

class _StartProjectTriggerScreenState extends State<StartProjectTriggerScreen> {
  bool _isLoading = true;
  final ApiService _apiService = ApiService();
  String _customerName = "Customer";
  String _myName = "Me";

  @override
  void initState() {
    super.initState();
    _fetchRequiredDetails();
  }

  Future<void> _fetchRequiredDetails() async {
    try {
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _startWork() async {
    setState(() => _isLoading = true);
    try {
      // API endpoint wahi rahega, backend isko handle kar lega
      final response = await _apiService.post('/projects/${widget.projectId}/start-work/', {});
      if(mounted) {
        if (response.statusCode == 200) {
          // Kaam shuru hone ke baad seedha project details par jao
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => ProjectDetailScreen(projectId: widget.projectId)),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: ${response.body}")));
        }
      }
    } catch(e) {
       if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("An error occurred: $e")));
    }
     if(mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: _isLoading
              ? const CircularProgressIndicator()
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Iconsax.wallet_check, size: 60, color: Colors.blue),
                    const SizedBox(height: 20),
                    const Text(
                      'Plan Approved & Payment Done!', // Naya text
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'The customer has approved the phase plan and paid for the first phase. You can start the work now.', // Naya text
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 30),
                    
                    ElevatedButton.icon(
                      icon: const Icon(Iconsax.play_circle),
                      label: const Text('Start The Project'),
                      onPressed: _startWork,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    ),
                    const SizedBox(height: 12),

                    ElevatedButton.icon(
                      icon: const Icon(Iconsax.message),
                      label: const Text('Chat with Customer'),
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
                ),
        ),
      ),
    );
  }
}
