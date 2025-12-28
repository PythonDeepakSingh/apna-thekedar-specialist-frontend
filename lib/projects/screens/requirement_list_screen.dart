// lib/projects/screens/requirement_list_screen.dart (UPDATED FOR UNIFIED LIST)
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:apna_thekedar_specialist/api/api_service.dart';
import 'package:iconsax/iconsax.dart';
import 'requirement_acceptance_screen.dart'; // Purani screen (Long Project ke liye)
import 'dart:io';
import 'package:apna_thekedar_specialist/core/widgets/attractive_error_widget.dart';
// Nayi file jo hum agle step mein banayenge
import 'short_service_acceptance_screen.dart'; 

class RequirementListScreen extends StatefulWidget {
  const RequirementListScreen({super.key});

  @override
  State<RequirementListScreen> createState() => _RequirementListScreenState();
}

class _RequirementListScreenState extends State<RequirementListScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _requirements = [];
  bool _isLoading = true;
  String? _errorType;

  @override
  void initState() {
    super.initState();
    _fetchRequirements();
  }

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
      
      // API URL wahi rahega, lekin ab naya data aayega
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
  
  // Navigation ko update kiya gaya hai
  void _navigateToDetail(Map<String, dynamic> job) {
    final jobType = job['job_type'];
    final internalId = job['internal_job_id'];

    if (jobType == 'PROJECT') {
      // Long Project ke liye purani screen
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => RequirementAcceptanceScreen(
            requirementId: internalId, // Yeh 'Requirement' ki ID hai
            projectId: 0, // Iski zaroorat ab nahi hai, lekin screen maangti hai
            initialData: job, // Hum naya data bhej rahe hain
          ),
        ),
      ).then((accepted) {
        if (accepted == true) _fetchRequirements();
      });
    } else {
      // Short Service ke liye nayi screen
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ShortServiceAcceptanceScreen(
            bookingId: internalId, // Yeh 'Booking' ki ID hai
            initialData: job, // Naya data
          ),
        ),
      ).then((accepted) {
        if (accepted == true) _fetchRequirements();
      });
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

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorType != null) {
      // (Error widget waise hi rahega)
      return AttractiveErrorWidget(
        imagePath: _errorType == 'no_internet' ? 'assets/no_internet.png' : 'assets/server_error.png',
        title: _errorType == 'no_internet' ? "No Internet Connection" : "Server Error",
        message: "Could not fetch requirements from the server.",
        buttonText: "Retry",
        onRetry: _fetchRequirements,
      );
    }
    
    if (_requirements.isEmpty) {
       // (Empty state waise hi rahega)
       return Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/no_job.png', width: MediaQuery.of(context).size.width * 0.9),
                const SizedBox(height: 24),
                const Text('No new requirements found in your area right now.', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.black54)),
                const SizedBox(height: 16),
                const Text('अभी आपके क्षेत्र में कोई नया काम उपलब्ध नहीं है।', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.black54)),
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
          final job = _requirements[index];
          final jobType = job['job_type'];
          
          // Data ab naye format se aa raha hai
          final title = job['title'] ?? 'No Title';
          final address = job['address'] ?? 'Address not available'; // YEH FIX HO GAYA
          
          // Color logic (Aapke request ke mutabik)
          final cardColor = jobType == 'SHORT_SERVICE' ? Colors.blue.shade50 : Colors.white;
          final icon = jobType == 'PROJECT' ? Iconsax.folder_open : Iconsax.flash_1;

          return Card(
            color: cardColor, // Naya color
            margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title, // Naya title
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Divider(height: 20),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(icon, color: Colors.grey), // Naya icon
                    title: Text(address), // Naya address
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // Naya navigation logic
                        _navigateToDetail(job);
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