import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:apna_thekedar_specialist/api/api_service.dart';
import 'package:apna_thekedar_specialist/projects/screens/project_details_screen.dart';
import 'package:iconsax/iconsax.dart';

class RequirementListScreen extends StatefulWidget {
  const RequirementListScreen({super.key});

  @override
  State<RequirementListScreen> createState() => _RequirementListScreenState();
}

class _RequirementListScreenState extends State<RequirementListScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _requirements = [];
  bool _isLoading = true;


  @override
  void initState() {
    super.initState();
    _fetchRequirements();
  }

Future<void> _fetchRequirements() async {
  setState(() { _isLoading = true; }); // Error variable yahan se hata dein

  final response = await _apiService.get('/projects/requirements/available/');
  if (mounted) {
    if (response.statusCode == 200) {
      setState(() {
        _requirements = json.decode(response.body);
      });
    }
    // else wala part hata dein
  }

  if(mounted) {
    setState(() { _isLoading = false; });
  }
}

  Future<void> _acceptRequirement(int requirementId) async {
    try {
      final response = await _apiService.post('/projects/requirements/$requirementId/accept/', {});
      if(mounted) {
        if(response.statusCode == 200) {
           final data = json.decode(response.body);
           final int newProjectId = data['project_id'];

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Requirement accepted!'), backgroundColor: Colors.green),
            );

            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => ProjectDetailScreen(projectId: newProjectId))
            );
        } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to accept: ${json.decode(response.body)['detail'] ?? 'Unknown error'}'), backgroundColor: Colors.red),
            );
        }
      }
    } catch(e) {
      if(mounted){
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An error occurred: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Job Requirements'),
        centerTitle: true,
      ),
      // === YAHAN BADLAAV KIYA GAYA HAI (Background Color) ===
      backgroundColor: Colors.white,
      // =======================================================
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
              : _requirements.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // === YAHAN BADLAAV KIYA GAYA HAI (Image Size) ===
                            Image.asset(
                              'assets/no_job.png', // Apni image ka naam yahan daalein
                              width: MediaQuery.of(context).size.width * 0.9, // 90% width
                            ),
                            // ===============================================
                            const SizedBox(height: 24),
                            const Text(
                              'No new requirements found in your area right now. We will notify you when a new job is available.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 16, color: Colors.black54),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'अभी आपके क्षेत्र में कोई नया काम उपलब्ध नहीं है। नया काम आने पर आपको सूचित किया जाएगा।',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 16, color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchRequirements,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(8.0),
                        itemCount: _requirements.length,
                        itemBuilder: (context, index) {
                          final req = _requirements[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    req['project']?['service_category']?['name'] ?? 'Service',
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                  const Divider(height: 20),
                                  ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: const Icon(Iconsax.location, color: Colors.grey),
                                    title: Text(req['project']?['address'] ?? 'Address not available'),
                                  ),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: () => _acceptRequirement(req['id']),
                                      child: const Text('View & Accept'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}