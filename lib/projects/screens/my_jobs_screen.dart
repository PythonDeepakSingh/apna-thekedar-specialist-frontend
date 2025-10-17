// lib/projects/screens/my_jobs_screen.dart (Naya, 2-Tab Version)
import 'package:flutter/material.dart';
import 'package:apna_thekedar_specialist/api/api_service.dart';
import 'dart:convert';
import 'package:iconsax/iconsax.dart';
import 'package:apna_thekedar_specialist/projects/screens/project_details_screen.dart';

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
    // Ab humare paas sirf 2 tabs hain
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
        // TabBar ko naye tabs ke saath update kiya gaya hai
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'Historical'),
          ],
        ),
      ),
      // TabBarView ko bhi naye tabs ke anusaar update kiya gaya hai
      body: TabBarView(
        controller: _tabController,
        children: const [
          JobList(category: 'active'), // 'running' aur 'pending' ki jagah 'active'
          JobList(category: 'historical'),
        ],
      ),
    );
  }
}

// JobList widget mein koi badlaav nahi karna hai, woh waisa hi rahega
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
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchJobs();
  }

  Future<void> _fetchJobs() async {
    setState(() { _isLoading = true; });
    try {
      final response = await _apiService.get('/projects/my-jobs/?category=${widget.category}');
      if (mounted) {
        if (response.statusCode == 200) {
          setState(() {
            _projects = json.decode(response.body);
            _isLoading = false;
          });
        } else {
          _error = "Failed to load jobs.";
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
       if (mounted) {
         _error = "An error occurred: $e";
         setState(() => _isLoading = false);
       }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text(_error!));
    if (_projects.isEmpty) return const Center(child: Text("No projects found in this category."));

    return RefreshIndicator(
      onRefresh: _fetchJobs,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _projects.length,
        itemBuilder: (context, index) {
          final project = _projects[index];
          final status = project['status'];

          // === YAHAN BADLAAV KIYA GAYA HAI ===
          Color cardColor = Colors.white; // Default color
          
          if (status == 'WORK_COMPLETED') {
            cardColor = Colors.green.shade50;
          } else if (status == 'WORK_CANCELLED') {
            cardColor = Colors.red.shade50;
          } else if (status == 'WORK_PAUSED') {
            // Rule 1: Paused project ke liye light yellow color
            cardColor = Colors.yellow.shade50;
          }
          // ===================================

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
                _fetchJobs(); // Wapas aane par list refresh karein
              },
            ),
          );
        },
      ),
    );
  }
}