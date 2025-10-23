import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:apna_thekedar_specialist/api/api_service.dart';
import 'package:apna_thekedar_specialist/projects/screens/project_details_screen.dart';
import 'package:iconsax/iconsax.dart';
import 'requirement_acceptance_screen.dart';

// === Naye Imports ===
import 'dart:io';
import 'package:apna_thekedar_specialist/core/widgets/attractive_error_widget.dart';

class RequirementListScreen extends StatefulWidget {
  const RequirementListScreen({super.key});

  @override
  State<RequirementListScreen> createState() => _RequirementListScreenState();
}

class _RequirementListScreenState extends State<RequirementListScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _requirements = [];
  bool _isLoading = true;
  String? _errorType; // === Naya variable ===

  @override
  void initState() {
    super.initState();
    _fetchRequirements();
  }

  // === Is function ko poora badal diya gaya hai ===
  Future<void> _fetchRequirements() async {
    setState(() {
      _isLoading = true;
      _errorType = null;
    });

    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isEmpty || result[0].rawAddress.isEmpty) {
        throw 'no_internet';
      }
      
      final response = await _apiService.get('/projects/requirements/available/');
      if (mounted) {
        if (response.statusCode == 200) {
          setState(() {
            _requirements = json.decode(response.body);
          });
        } else {
          throw 'server_error';
        }
      }
    } on SocketException catch (_) {
      _errorType = 'no_internet';
    } catch (e) {
      if (mounted) {
         _errorType = e.toString() == 'server_error' ? 'server_error' : 'unknown';
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _acceptRequirement(int requirementId, int projectId) async {
    try {
      final response = await _apiService.post('/projects/requirements/$requirementId/accept/', {});
      if(mounted) {
        if(response.statusCode == 200) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Requirement accepted!'), backgroundColor: Colors.green),
            );

            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => ProjectDetailScreen(projectId: projectId))
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
      backgroundColor: Colors.white,
      body: _buildBody(),
    );
  }

  // === Yeh poora naya function hai UI ko manage karne ke liye ===
  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorType != null) {
      return AttractiveErrorWidget(
        imagePath: _errorType == 'no_internet' ? 'assets/no_internet.png' : 'assets/server_error.png',
        title: _errorType == 'no_internet' ? "No Internet Connection" : "Server Error",
        message: _errorType == 'no_internet' 
            ? "You are not connected to the internet."
            : "Could not fetch requirements from the server.",
        buttonText: "Retry",
        onRetry: _fetchRequirements,
      );
    }
    
    if (_requirements.isEmpty) {
       return Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/no_job.png',
                  width: MediaQuery.of(context).size.width * 0.9,
                ),
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
        );
    }

    return RefreshIndicator(
      onRefresh: _fetchRequirements,
      child: ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: _requirements.length,
        itemBuilder: (context, index) {
          final req = _requirements[index];
          final project = req['project'];
          // Yahan service_category ko safely access karein
          final serviceCategory = project != null && project['service_category'] is Map ? project['service_category']['name'] : 'Service';
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    serviceCategory ?? 'Service',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Divider(height: 20),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Iconsax.location, color: Colors.grey),
                    title: Text(project?['address'] ?? 'Address not available'),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      // Ab yeh nayi screen kholega
                      onPressed: () {
                        final req = _requirements[index];
                        final project = req['project'] as Map<String, dynamic>?; // Type cast karein
                        final projectId = project?['id']; // Safely access ID
                    
                        if (project != null && projectId != null) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => RequirementAcceptanceScreen(
                                requirementId: req['id'],
                                projectId: projectId, // Ab safe variable use karein
                                initialData: req,
                              ),
                            ),
                          ).then((accepted) {
                            if (accepted == true) {
                              _fetchRequirements();
                            }
                          });
                        } else {
                          // Agar data mein gadbad hai to user ko batayein
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Error: Could not load requirement details. Data might be incomplete.')),
                          );
                          print("Error: Project data is null or missing ID for requirement ID: ${req['id']}"); // Debugging ke liye
                        }
                        // ===========================================
                      },
                      child: const Text('View Details'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}