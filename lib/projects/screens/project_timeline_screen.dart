import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

class ProjectTimelineScreen extends StatelessWidget {
  final Map<String, dynamic> projectDetails;

  const ProjectTimelineScreen({super.key, required this.projectDetails});

  String _formatDate(String? dateString) {
    if (dateString == null) {
      return 'Not yet';
    }
    try {
      final date = DateTime.parse(dateString).toLocal();
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
    final List phases = projectDetails['phases'] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Project Timeline'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildTimelineTile(
            Iconsax.calendar_add,
            'Project Created',
            _formatDate(projectDetails['created_at']),
            Colors.blue,
          ),
          _buildTimelineTile(
            Iconsax.user_tick,
            'Specialist Connected',
            _formatDate(projectDetails['specialist_connected_at']),
            Colors.orange,
          ),
          _buildTimelineTile(
            Iconsax.document_upload,
            'Phase Plan Submitted',
            _formatDate(projectDetails['phase_plan_created_at']),
            Colors.purple,
          ),
          _buildTimelineTile(
            Iconsax.like_1,
            'Phase Plan Approved',
            _formatDate(projectDetails['phase_plan_approved_at']),
            Colors.teal,
          ),
          
          const Divider(height: 20),

          _buildTimelineTile(
            Iconsax.play_circle,
            'Work Started',
            _formatDate(projectDetails['work_started_at']),
            Colors.green,
          ),
          
          // === YAHAN SE GALAT IF CONDITION HATA DI GAYI HAI ===
          ...phases.map((phase) {
            final phaseNumber = phase['phase_number'];
            
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 16, top: 16, bottom: 8),
                  child: Text(
                    "Phase $phaseNumber Events",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black54),
                  ),
                ),
                _buildTimelineTile(
                  Iconsax.send_2,
                  'Completion Requested (Phase $phaseNumber)',
                  _formatDate(phase['completion_request_at']),
                  Colors.blueGrey,
                ),
                _buildTimelineTile(
                  Iconsax.task_square,
                  'Completion Approved (Phase $phaseNumber)',
                  _formatDate(phase['completion_approved_at']),
                  Colors.indigo,
                ),
              ],
            );
          }).toList(),
          // =======================================================

          const Divider(height: 20),

          if(projectDetails['completed_at'] != null)
            _buildTimelineTile(
              Iconsax.verify,
              'Project Completed',
              _formatDate(projectDetails['completed_at']),
              Colors.green,
            ),
          if(projectDetails['cancelled_at'] != null)
            _buildTimelineTile(
              Iconsax.close_circle,
              'Project Cancelled',
              _formatDate(projectDetails['cancelled_at']),
              Colors.red,
            ),
        ],
      ),
    );
  }
}