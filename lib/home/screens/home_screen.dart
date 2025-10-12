import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:apna_thekedar_specialist/home/widgets/home_drawer.dart';
import 'package:apna_thekedar_specialist/projects/screens/requirement_list_screen.dart';
import 'package:apna_thekedar_specialist/projects/screens/my_jobs_screen.dart';
import 'package:apna_thekedar_specialist/projects/screens/project_details_screen.dart';
import 'package:apna_thekedar_specialist/api/api_service.dart';
import 'dart:convert';
import 'package:apna_thekedar_specialist/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:apna_thekedar_specialist/notifications/notification_screen.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  final NotificationService _notificationService = NotificationService();
  
  Map<String, dynamic>? _dashboardData;
  List<dynamic> _notifications = [];
  bool _isLoading = true;
  String? _error;
  WebSocketChannel? _channel;

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  @override
  void dispose() {
    _channel?.sink.close();
    super.dispose();
  }

  Future<void> _initializeScreen() async {
    if (!mounted) return;
    setState(() { _isLoading = true; });
    await _fetchDashboardData();
    await _fetchInitialNotifications();
    _connectToNotificationSocket();
    if (mounted) setState(() { _isLoading = false; });
  }

  Future<void> _fetchDashboardData() async {
    try {
      final response = await _apiService.get('/specialist/dashboard/');
      if (mounted && response.statusCode == 200) {
        setState(() => _dashboardData = json.decode(response.body));
      }
    } catch (e) {
      if (mounted) setState(() => _error = "Could not load dashboard.");
    }
  }

  Future<void> _fetchInitialNotifications() async {
    try {
      final response = await _apiService.get('/notifications/');
      if (mounted && response.statusCode == 200) {
        setState(() {
          _notifications = json.decode(response.body);
        });
      }
    } catch (e) {
       print("Could not fetch initial notifications: $e");
    }
  }

  Future<void> _connectToNotificationSocket() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('accessToken');
      if (accessToken == null) return;

      final wsUrl = 'wss://apna-thekedar-backend.onrender.com/ws/notifications/?token=$accessToken';
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      _channel!.stream.listen((data) {
        final message = json.decode(data);
        if (!mounted) return;

        if (message['type'] == 'new_notification') {
          final notificationData = message['notification'];
          
          setState(() {
            _notifications.insert(0, notificationData);
          });
          
          _notificationService.showWebSocketNotification(
            id: notificationData['id'],
            title: notificationData['title'],
            body: notificationData['message'],
            notificationType: notificationData['notification_type'],
            projectId: notificationData['related_project_id']?.toString(),
          );

        } else if (message['type'] == 'remove_notification') {
          final notificationId = message['notification_id'];
          setState(() {
            _notifications.removeWhere((notif) => notif['id'] == notificationId);
          });
        }
      },
      onDone: () {
        print("Notification socket closed. Reconnecting in 5 seconds...");
        if(mounted) {
          Future.delayed(const Duration(seconds: 5), () => _connectToNotificationSocket());
        }
      },
      onError: (error) {
        print("Notification socket error: $error. Will attempt to reconnect.");
        if(mounted) {
           Future.delayed(const Duration(seconds: 5), () => _connectToNotificationSocket());
        }
      });
    } catch (e) {
      print("Could not connect to notification socket: $e");
    }
  }
  
// lib/home/screens/home_screen.dart

  void _handleRunningProjectTap() {
    final project = _dashboardData?['latest_running_project'];
    if (project == null) return;
    
    final projectId = project['id'];

    // Ab har active project ke liye seedha ProjectDetailScreen par jaayenge
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ProjectDetailScreen(projectId: projectId),
    ));
  }


  @override
  Widget build(BuildContext context) {
    // ==================== YAHAN PAR HAI ASLI FIX ====================
    // Hum yahan par job counts ko safe tareeke se nikaal rahe hain.
    // Agar 'job_counts' ya uske andar ki koi value null hogi, toh yeh 0 maan lega.
    final jobCounts = _dashboardData?['job_counts'] as Map<String, dynamic>? ?? {};
    final int runningJobs = jobCounts['running'] ?? 0;
    final int pendingJobs = jobCounts['pending'] ?? 0;
    final int completedJobs = jobCounts['completed'] ?? 0;
    final int totalJobs = runningJobs + pendingJobs + completedJobs;
    // ===============================================================

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
              ).then((_){
                 // Wapas aane par notifications refresh karein
                 _fetchInitialNotifications();
              });
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
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
                        
                        ..._notifications.take(2).map((notification) {
                          return _buildNotificationCard(notification['title']);
                        }).toList(),
                        
                        if (_notifications.length > 2)
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
                              count: totalJobs, // Yahan par naya safe variable istemaal hoga
                              onTap: () {
                                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MyJobsScreen()));
                              },
                            ),
                            _buildGridCard(
                              context,
                              icon: Iconsax.wallet_money,
                              label: "My Earnings",
                              onTap: () {},
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

  Widget _buildNotificationCard(String text) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: Colors.blue.shade50,
      child: ListTile(
        leading: Icon(Iconsax.info_circle, color: Colors.blue.shade800),
        title: Text(text, style: const TextStyle(fontSize: 14)),
      ),
    );
  }

  Widget _buildLatestRunningProject() {
    final project = _dashboardData?['latest_running_project'];
    
    if (project == null) {
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
            title: Text(project['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("Status: ${project['status'].replaceAll('_', ' ')}"),
            trailing: const Icon(Iconsax.arrow_right_3),
            onTap: _handleRunningProjectTap,
          ),
        ),
      ],
    );
  }

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

