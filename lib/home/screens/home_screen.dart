import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:apna_thekedar_specialist/home/widgets/home_drawer.dart';
import 'package:apna_thekedar_specialist/projects/screens/requirement_list_screen.dart';
import 'package:apna_thekedar_specialist/projects/screens/my_jobs_screen.dart';
import 'package:apna_thekedar_specialist/projects/screens/project_details_screen.dart';
import 'package:apna_thekedar_specialist/api/api_service.dart';
import 'dart:convert';
import 'package:apna_thekedar_specialist/services/notification_service.dart';
import 'package:apna_thekedar_specialist/notifications/notification_screen.dart';
import 'package:apna_thekedar_specialist/providers/notification_provider.dart';
import 'package:provider/provider.dart';
import 'package:apna_thekedar_specialist/notifications/notification_model.dart';
import 'package:apna_thekedar_specialist/profile/screens/my_earnings_screen.dart';

// === Naye Imports ===
import 'dart:io'; 
import 'package:apna_thekedar_specialist/core/widgets/attractive_error_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? _dashboardData;
  bool _isLoading = true;
  String? _errorType; // === Naya variable ===

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeScreen();
    });
  }

  // === Is function ko poora badal diya gaya hai ===
  Future<void> _initializeScreen() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorType = null;
    });

    try {
      // Step 1: Internet check
      final result = await InternetAddress.lookup('google.com');
      if (result.isEmpty || result[0].rawAddress.isEmpty) {
        throw 'no_internet';
      }
      
      final notificationService = Provider.of<NotificationService>(context, listen: false);
      final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);

      // Step 2: API calls
      await _fetchDashboardData();
      await notificationProvider.fetchNotifications();
      await notificationService.connectWebSocket();

    } on SocketException catch (_) {
      _errorType = 'no_internet';
    } catch (e) {
      if (mounted) {
        _errorType = e.toString() == 'no_internet' ? 'no_internet' : 'server_error';
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // === Is function me thoda badlav hai ===
  Future<void> _fetchDashboardData() async {
    final apiService = Provider.of<ApiService>(context, listen: false);
    final response = await apiService.get('/specialist/dashboard/');
    if (mounted) {
      if (response.statusCode == 200) {
        setState(() => _dashboardData = json.decode(response.body));
      } else {
        // Agar API call fail ho to error throw karein
        throw 'server_error';
      }
    }
  }

  void _handleRunningProjectTap() {
    final project = _dashboardData?['latest_running_project'];
    if (project == null) return;
    
    final projectId = project['id'];

    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ProjectDetailScreen(projectId: projectId),
    )).then((_) => _initializeScreen()); // Wapas aane par screen refresh karein
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const HomeDrawer(),
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Iconsax.notification),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NotificationScreen())
              );
            },
          ),
        ],
      ),
      body: _buildBody(), // Ab body me yeh naya widget call hoga
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
        title: _errorType == 'no_internet' ? "Oops! No Internet" : "Something Went Wrong",
        message: _errorType == 'no_internet'
            ? "Please check your internet connection and try again."
            : "We're having trouble connecting to our servers. Please try again later.",
        buttonText: "Retry",
        onRetry: _initializeScreen,
      );
    }

    // Normal UI jab sab kuch theek ho
    final notificationProvider = Provider.of<NotificationProvider>(context);
    final unreadNotifications = notificationProvider.notifications.where((n) => !n.isRead).toList();

    return RefreshIndicator(
      onRefresh: _initializeScreen,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Welcome, ${_dashboardData?['user_name'] ?? 'Specialist'}!",
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)
            ),
            const SizedBox(height: 16),
            
            ...unreadNotifications.take(2).map((notification) {
              return _buildNotificationCard(notification);
            }).toList(),
            
            if (unreadNotifications.length > 2)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(onPressed: (){
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const NotificationScreen())
                  );
                }, child: const Text("View all notifications"))
              ),
            const SizedBox(height: 16),

            GridView.count(
              crossAxisCount: 3, 
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.9,
              children: [
                _buildGridCard(
                  context,
                  icon: Iconsax.document_download,
                  label: "New Requirements",
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RequirementListScreen()));
                  },
                ),
                _buildGridCard(
                  context,
                  icon: Iconsax.folder_open,
                  label: "My Jobs",
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MyJobsScreen()));
                  },
                ),
                _buildGridCard(
                  context,
                  icon: Iconsax.wallet_money,
                  label: "My Earnings",
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MyEarningsScreen()));
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            _buildLatestRunningProject(),
          ],
        ),
      ),
    );
  }

  // === Baki ke saare functions waise hi rahenge ===
  Widget _buildNotificationCard(NotificationModel notification) {
    // ... (no changes here)
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: Colors.blue.shade50,
      child: ListTile(
        leading: Icon(Iconsax.info_circle, color: Colors.blue.shade800),
        title: Text(notification.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        subtitle: Text(notification.message, maxLines: 1, overflow: TextOverflow.ellipsis),
        onTap: () {
          Provider.of<NotificationService>(context, listen: false).handleNotificationClick(notification);
        },
      ),
    );
  }

  Widget _buildLatestRunningProject() {
    // ... (no changes here)
    if (_dashboardData == null || _dashboardData!['latest_running_project'] == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(Iconsax.play_circle, color: Colors.grey),
              SizedBox(width: 16),
              Text("No active projects currently.", style: TextStyle(fontStyle: FontStyle.italic)),
            ],
          ),
        ),
      );
    }

    final project = _dashboardData!['latest_running_project'];
    
    final statusValue = project['status'];
    String statusText = 'UNKNOWN';

    if (statusValue is String && statusValue.isNotEmpty) {
      statusText = statusValue.replaceAll('_', ' ');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "ACTIVE PROJECT",
          style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Card(
          elevation: 4,
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: const Icon(Iconsax.play_circle, color: Colors.blue, size: 30),
            title: Text(project['title'] ?? 'No Title', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("Status: $statusText"),
            trailing: const Icon(Iconsax.arrow_right_3),
            onTap: _handleRunningProjectTap,
          ),
        ),
      ],
    );
  }

  Widget _buildGridCard(BuildContext context, {required IconData icon, required String label, int? count, required VoidCallback onTap}) {
    // ... (no changes here)
    const Color darkColor = Color(0xFF4B2E1E);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (count != null)
              Text(count.toString(), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: darkColor)),
            Icon(icon, size: count != null ? 30 : 40, color: darkColor),
            const SizedBox(height: 12),
            Text(label, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}