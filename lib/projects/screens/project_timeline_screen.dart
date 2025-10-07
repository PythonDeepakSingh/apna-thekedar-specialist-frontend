// lib/projects/screens/project_timeline_screen.dart
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

class ProjectTimelineScreen extends StatelessWidget {
  final Map<String, dynamic> projectDetails;

  const ProjectTimelineScreen({super.key, required this.projectDetails});

  // Date ko format karne ke liye helper function
  String _formatDate(String? dateString) {
    if (dateString == null) {
      return 'Not yet';
    }
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd MMM, yyyy - hh:mm a').format(date);
    } catch (e) {
      return 'Invalid Date';
    }
  }

  Widget _buildTimelineTile(IconData icon, String title, String subtitle, Color color) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 14)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Project Timeline'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildTimelineTile(
            Iconsax.calendar_add,
            'Project Created On',
            _formatDate(projectDetails['created_at']),
            Colors.blue,
          ),
          _buildTimelineTile(
            Iconsax.user_tick,
            'Specialist Connected On',
            _formatDate(projectDetails['specialist_connected_at']),
            Colors.orange,
          ),
          _buildTimelineTile(
            Iconsax.play_circle,
            'Work Started On',
            _formatDate(projectDetails['work_started_at']),
            Colors.teal,
          ),
          // Completed aur Cancelled dates yahan bhi dikha sakte hain, agar woh available hon
          if(projectDetails['completed_at'] != null)
            _buildTimelineTile(
              Iconsax.verify,
              'Project Completed On',
              _formatDate(projectDetails['completed_at']),
              Colors.green,
            ),
          if(projectDetails['cancelled_at'] != null)
            _buildTimelineTile(
              Iconsax.close_circle,
              'Project Cancelled On',
              _formatDate(projectDetails['cancelled_at']),
              Colors.red,
            ),
        ],
      ),
    );
  }
}