// lib/projects/screens/my_jobs_screen.dart (Updated with Attractive Error Handling)
import 'package:flutter/material.dart';
import 'package:apna_thekedar_specialist/api/api_service.dart';
import 'dart:convert';
import 'dart:io'; // Internet check karne ke liye
import 'package:iconsax/iconsax.dart';
import 'package:apna_thekedar_specialist/projects/screens/project_details_screen.dart';
import 'package:apna_thekedar_specialist/core/widgets/attractive_error_widget.dart'; // Naya widget import karein

class MyJobsScreen extends StatefulWidget {
  const MyJobsScreen({super.key});

  @override
  State<MyJobsScreen> createState() => _MyJobsScreenState();
}

class _MyJobsScreenState extends State<MyJobsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Jobs'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'Historical'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          JobList(category: 'active'),
          JobList(category: 'historical'),
        ],
      ),
    );
  }
}

// === JobList WIDGET KO NEECHE DIYE GAYE CODE SE REPLACE KAREIN ===

class JobList extends StatefulWidget {
  final String category;
  const JobList({super.key, required this.category});

  @override
  State<JobList> createState() => _JobListState();
}

class _JobListState extends State<JobList> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<dynamic> _projects = [];
  String? _errorType; // Ab hum error ka type store karenge

  @override
  void initState() {
    super.initState();
    _fetchJobs();
  }

  Future<void> _fetchJobs() async {
    setState(() {
      _isLoading = true;
      _errorType = null;
    });

    try {
      // Step 1: Internet check karein
      final result = await InternetAddress.lookup('google.com');
      if (result.isEmpty || result[0].rawAddress.isEmpty) {
        throw 'no_internet';
      }

      // Step 2: API call karein
      final response = await _apiService.get('/projects/my-jobs/?category=${widget.category}');

      if (mounted) {
        if (response.statusCode == 200) {
          setState(() {
            _projects = json.decode(response.body);
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
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorType != null) {
      if (_errorType == 'no_internet') {
        return AttractiveErrorWidget(
          imagePath: 'assets/no_internet.png', // Aapki cartoon image
          title: "Oops! No Internet",
          message: "Lagta hai aapka internet band hai. Please check karke dobara try karein.",
          buttonText: "Dobara Try Karein",
          onRetry: _fetchJobs,
        );
      } else {
        return AttractiveErrorWidget(
          imagePath: 'assets/server_error.png', // Server error ke liye image
          title: "Something Went Wrong",
          message: "Humare server se connect nahi ho pa raha hai. Please thodi der baad try karein.",
          buttonText: "Retry",
          onRetry: _fetchJobs,
        );
      }
    }

    if (_projects.isEmpty) {
      return AttractiveErrorWidget(
        imagePath: 'assets/no_jobs.png', // Khaali list ke liye image
        title: "No Jobs Found",
        message: "Is category mein abhi koi jobs nahi hain. Nayi jobs yahan dikhengi.",
        buttonText: "Refresh",
        onRetry: _fetchJobs,
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchJobs,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _projects.length,
        itemBuilder: (context, index) {
          final project = _projects[index];
          final status = project['status'];

          Color cardColor = Colors.white; 
          
          if (status == 'WORK_COMPLETED') {
            cardColor = Colors.green.shade50;
          } else if (status == 'WORK_CANCELLED') {
            cardColor = Colors.red.shade50;
          } else if (status == 'WORK_PAUSED') {
            cardColor = Colors.yellow.shade50;
          }

          return Card(
            color: cardColor,
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              title: Text(project['title']),
              subtitle: Text("Customer: ${project['customer_name'] ?? 'N/A'}"),
              trailing: const Icon(Iconsax.arrow_right_3),
              onTap: () async {
                await Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => ProjectDetailScreen(projectId: project['id'])
                ));
                _fetchJobs();
              },
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildBody();
  }
}