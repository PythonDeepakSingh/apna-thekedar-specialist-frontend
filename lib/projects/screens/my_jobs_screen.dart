// lib/projects/screens/my_jobs_screen.dart (UPDATED FOR UNIFIED LIST)
import 'package:flutter/material.dart';
import 'package:apna_thekedar_specialist/api/api_service.dart';
import 'dart:convert';
import 'dart:io'; // Internet check karne ke liye
import 'package:iconsax/iconsax.dart';
import 'package:apna_thekedar_specialist/projects/screens/project_details_screen.dart';
import 'package:apna_thekedar_specialist/core/widgets/attractive_error_widget.dart';
// NAYI DETAIL SCREEN KO IMPORT KAREIN (yeh file hum agle step mein banayenge)
import 'short_service_detail_screen.dart'; 

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
  String? _errorType;

  // Historical filter ke liye naya variable
  String? _jobTypeFilter; // null = All, 'PROJECT', 'SHORT_SERVICE'

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
      final result = await InternetAddress.lookup('google.com');
      if (result.isEmpty || result[0].rawAddress.isEmpty) {
        throw 'no_internet';
      }

      // API URL ko naye filter ke saath update karein
      String url = '/projects/my-jobs/?category=${widget.category}';
      if (widget.category == 'historical' && _jobTypeFilter != null) {
        url += '&job_type=$_jobTypeFilter';
      }

      final response = await _apiService.get(url);

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
  
  // Navigation logic
  void _navigateToDetail(dynamic job) async {
    final String jobType = job['job_type'];
    final int jobId = job['id'];

    if (jobType == 'PROJECT') {
      // Long Project: Purani detail screen par bhejein
      await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ProjectDetailScreen(projectId: jobId)
      ));
    } else {
      // Short Service: Nayi detail screen par bhejein
      await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ShortServiceDetailScreen(bookingId: jobId)
      ));
    }
    // Wapas aane par list refresh karein
    _fetchJobs();
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorType != null) {
      // (AttractiveErrorWidget wala logic same rahega)
      return AttractiveErrorWidget(
        imagePath: _errorType == 'no_internet' ? 'assets/no_internet.png' : 'assets/server_error.png',
        title: _errorType == 'no_internet' ? "Oops! No Internet" : "Something Went Wrong",
        message: "We're having trouble fetching your jobs. Please check your connection and try again.",
        buttonText: "Retry",
        onRetry: _fetchJobs,
      );
    }

    if (_projects.isEmpty) {
      // (AttractiveErrorWidget wala logic same rahega)
      return AttractiveErrorWidget(
        imagePath: 'assets/no_jobs.png',
        title: "No Jobs Found",
        message: "This category is empty. New jobs will appear here.",
        buttonText: "Refresh",
        onRetry: _fetchJobs,
      );
    }

    // Main UI
    return Column(
      children: [
        // Agar Historical tab hai, toh filter dikhao
        if (widget.category == 'historical')
          _buildHistoricalFilter(),

        // Jobs ki list
        Expanded(
          child: RefreshIndicator(
            onRefresh: _fetchJobs,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _projects.length,
              itemBuilder: (context, index) {
                final job = _projects[index];
                return _buildJobCard(job); // Card banane ke liye alag function
              },
            ),
          ),
        ),
      ],
    );
  }

  // Naya function: Historical tab ke liye filter buttons
  Widget _buildHistoricalFilter() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SegmentedButton<String?>(
        segments: const [
          ButtonSegment<String?>(value: null, label: Text('All'), icon: Icon(Iconsax.task)),
          ButtonSegment<String?>(value: 'PROJECT', label: Text('Projects'), icon: Icon(Iconsax.folder_open)),
          ButtonSegment<String?>(value: 'SHORT_SERVICE', label: Text('Short Jobs'), icon: Icon(Iconsax.flash_1)),
        ],
        selected: {_jobTypeFilter},
        onSelectionChanged: (Set<String?> newSelection) {
          setState(() {
            _jobTypeFilter = newSelection.first;
          });
          _fetchJobs(); // Filter badalne par jobs dobara fetch karein
        },
      ),
    );
  }

  // Naya function: Job card banane ke liye
  Widget _buildJobCard(Map<String, dynamic> job) {
    final status = job['status'];
    final jobType = job['job_type'];

    // --- Color Logic (Aapke rules ke mutabik) ---
    Color cardColor = Colors.white; // Default
    
    if (widget.category == 'active') {
      // Active tab: Short service ko alag color do
      if (jobType == 'SHORT_SERVICE') {
        cardColor = Colors.blue.shade50;
      }
    } else {
      // Historical tab: Status ke hisaab se color do
      if (status == 'WORK_COMPLETED' || status == 'COMPLETED') {
        cardColor = Colors.green.shade50;
      } else if (status == 'WORK_CANCELLED' || status == 'CANCELLED' || status == 'UNASSIGNED') {
        cardColor = Colors.red.shade50;
      } else if (status == 'WORK_PAUSED') {
        cardColor = Colors.yellow.shade50;
      }
    }
    // --- End of Color Logic ---

    return Card(
      color: cardColor,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(
          jobType == 'PROJECT' ? Iconsax.folder_open : Iconsax.flash_1,
          color: Theme.of(context).primaryColor,
        ),
        title: Text(job['title']),
        subtitle: Text("Customer: ${job['customer_name'] ?? 'N/A'}"),
        trailing: const Icon(Iconsax.arrow_right_3),
        onTap: () => _navigateToDetail(job), // Naya navigation function
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildBody();
  }
}