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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? _dashboardData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeScreen();
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

Future<void> _initializeScreen() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    final notificationService = Provider.of<NotificationService>(context, listen: false);
    final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);

    // === YAHAN BADLAAV KIYA GAYA HAI ===
    try {
      // Saare functions ko try block ke andar daal dein
      await _fetchDashboardData();
      await notificationProvider.fetchNotifications();
      await notificationService.connectWebSocket();
    } catch (e) {
      // Catch block khaali rahega. Humein bas error ko pakadna hai.
      // Global system error screen dikha dega.
      print("Error during initialization caught locally: $e");
    } finally {
      // Yeh block hamesha chalega, chahe error aaye ya na aaye
      if (mounted) {
        setState(() {
          _isLoading = false; // Loading ko band kar dega
        });
      }
    }
    // ===================================
  }

  Future<void> _fetchDashboardData() async {
    final apiService = Provider.of<ApiService>(context, listen: false);
    final response = await apiService.get('/specialist/dashboard/');
    if (mounted && response.statusCode == 200) {
      setState(() => _dashboardData = json.decode(response.body));
    }
  }

  void _handleRunningProjectTap() {
    final project = _dashboardData?['latest_running_project'];
    if (project == null) return;
    
    final projectId = project['id'];

    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ProjectDetailScreen(projectId: projectId),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final notificationProvider = Provider.of<NotificationProvider>(context);
    final unreadNotifications = notificationProvider.notifications.where((n) => !n.isRead).toList();

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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
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
                              // === COUNT YAHAN SE HATA DIYA GAYA HAI ===
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
                ),
    );
  }

  Widget _buildNotificationCard(NotificationModel notification) {
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

  // === _buildGridCard ab count ke bina bhi kaam karega ===
  Widget _buildGridCard(BuildContext context, {required IconData icon, required String label, int? count, required VoidCallback onTap}) {
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
            // Count null hone par yeh text nahi banega
            if (count != null)
              Text(count.toString(), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: darkColor)),
            // Icon ka size ab count par depend karega
            Icon(icon, size: count != null ? 30 : 40, color: darkColor),
            const SizedBox(height: 12),
            Text(label, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}  