import 'dart:convert';
import 'package:apna_thekedar_specialist/projects/screens/create_phase_plan_screen.dart';
import 'package:apna_thekedar_specialist/projects/screens/view_phase_plan_screen.dart'; // Naya import
import 'package:flutter/material.dart';
import 'package:apna_thekedar_specialist/api/api_service.dart';
import 'package:apna_thekedar_specialist/chat/chat_screen.dart';
import 'package:apna_thekedar_specialist/core/models/user_profile.dart';
import 'package:apna_thekedar_specialist/projects/screens/create_quotation_screen.dart';
import 'package:apna_thekedar_specialist/projects/screens/project_timeline_screen.dart';
import 'package:apna_thekedar_specialist/projects/screens/request_completion_screen.dart';
import 'package:apna_thekedar_specialist/projects/screens/requirement_details_view_screen.dart';
import 'package:apna_thekedar_specialist/reviews_feedback_progress/models/project_update.dart';
import 'package:apna_thekedar_specialist/reviews_feedback_progress/screens/create_update_screen.dart';
import 'package:apna_thekedar_specialist/reviews_feedback_progress/screens/update_history_screen.dart';
import 'package:http/http.dart' as http;
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:apna_thekedar_specialist/projects/screens/quotation_history_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class ProjectDetailScreen extends StatefulWidget {
  final int projectId;
  final String? message;

  const ProjectDetailScreen({super.key, required this.projectId, this.message});

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  Map<String, dynamic>? _projectDetails;
  String? _error;
  UserProfile? _myProfile;

  @override
  void initState() {
    super.initState();
    _fetchProjectDetails();

    if (widget.message != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(widget.message!), backgroundColor: Colors.orange),
        );
      });
    }
  }

  Future<void> _fetchProjectDetails() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final responses = await Future.wait([
        _apiService.get('/projects/${widget.projectId}/details/'),
        UserProfile.loadFromApi(),
      ]);

      if (mounted) {
        final projectResponse = responses[0] as http.Response;
        final profile = responses[1] as UserProfile?;

        if (projectResponse.statusCode == 200) {
          setState(() {
            _projectDetails = json.decode(projectResponse.body);
            _myProfile = profile;
          });
        } else {
          setState(() {
            _error = "Failed to load project details.";
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = "An error occurred: $e";
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _launchMaps() async {
    if (_projectDetails == null) return;

    final lat = _projectDetails!['latitude'];
    final lng = _projectDetails!['longitude'];

    if (lat == null || lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Project location is not available.')),
      );
      return;
    }

    final Uri googleMapsUrl =
        Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');

    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open Google Maps.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_projectDetails?['title'] ?? 'Project Details'),
        actions: [
          if (_projectDetails != null)
            Builder(
              builder: (context) => IconButton(
                icon: const Icon(Iconsax.more),
                onPressed: () => Scaffold.of(context).openEndDrawer(),
              ),
            ),
        ],
      ),
      endDrawer: _projectDetails != null ? _buildProjectDrawer() : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _projectDetails == null
                  ? const Center(child: Text("Project not found."))
                  : RefreshIndicator(
                      onRefresh: _fetchProjectDetails,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInfoCard(),
                            _buildTimelineInfo(),
                            const SizedBox(height: 16),
                            Text("Next Steps",
                                style: Theme.of(context).textTheme.titleLarge),
                            const SizedBox(height: 8),
                            _buildActionWidget(),
                          ],
                        ),
                      ),
                    ),
    );
  }

  Widget _buildInfoCard() {
    final customer = _projectDetails!['customer'] ?? {};
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _projectDetails!['title'] ?? 'No Title',
              style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333)),
            ),
            const SizedBox(height: 8),
            Text(
              _projectDetails!['description'] ?? 'No description provided.',
              style:
                  TextStyle(fontSize: 16, color: Colors.grey[700], height: 1.5),
            ),
            const Divider(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Location',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF333333)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_projectDetails!['address'] ?? ''}, ${_projectDetails!['pincode'] ?? ''}',
                        style:
                            const TextStyle(fontSize: 15, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Iconsax.direct_right,
                      color: Colors.blue, size: 28),
                  onPressed: _launchMaps,
                  tooltip: 'Get Directions',
                ),
              ],
            ),
            const Divider(height: 30),
            const Text(
              'Customer Details',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333)),
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: Colors.brown.shade100,
                child: Text(customer['name']?[0] ?? 'C',
                    style: TextStyle(
                        color: Colors.brown.shade800,
                        fontWeight: FontWeight.bold)),
              ),
              title: Text(customer['name'] ?? 'N/A',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(customer['phone_number'] ?? 'N/A'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateRow(String label, String? dateString) {
    if (dateString == null) return const SizedBox.shrink();
    String formattedDate = 'N/A';
    try {
      final date = DateTime.parse(dateString).toLocal();
      formattedDate = DateFormat('dd MMM, yyyy').format(date);
    } catch (e) {
      /* ignore */
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(formattedDate,
              style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildTimelineInfo() {
    final status = _projectDetails!['status'];
    if (status != 'WORK_COMPLETED' && status != 'WORK_CANCELLED') {
      return const SizedBox.shrink();
    }
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              status == 'WORK_COMPLETED'
                  ? 'Project Completion Details'
                  : 'Project Cancellation Details',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(height: 20),
            _buildDateRow('Created On', _projectDetails!['created_at']),
            _buildDateRow(
                'Connected On', _projectDetails!['specialist_connected_at']),
            if (status == 'WORK_COMPLETED')
              _buildDateRow('Completed On', _projectDetails!['completed_at']),
            if (status == 'WORK_CANCELLED')
              _buildDateRow('Cancelled On', _projectDetails!['cancelled_at']),
          ],
        ),
      ),
    );
  }

  Drawer _buildProjectDrawer() {
    final requirement = _projectDetails!['requirement'];
    final updatesData = (_projectDetails?['progress_updates'] as List?) ?? [];
    final updates =
        updatesData.map((data) => ProjectUpdate.fromJson(data)).toList();
    final status = _projectDetails!['status'];
    final bool isWorkInProgress = status == 'WORK_IN_PROGRESS';
    final phases = (_projectDetails!['phases'] as List<dynamic>? ?? []);

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Color(0xFF4B2E1E)),
            child: Text('Project Options',
                style: TextStyle(color: Colors.white, fontSize: 24)),
          ),

          // Naya Button: Phase Plan ke liye
          if (phases.isNotEmpty)
            ListTile(
              leading: const Icon(Iconsax.task_square, color: Colors.indigo),
              title: Text((status == 'WAITING_FOR_PHASE_PLAN_APPROVAL' || status == 'PHASE_PLAN_REJECTED')
                  ? 'View / Update Phase Plan'
                  : 'View Phase Plan'),
              onTap: () {
                Navigator.of(context).pop(); // Drawer band karein

                if (status == 'WAITING_FOR_PHASE_PLAN_APPROVAL' || status == 'PHASE_PLAN_REJECTED') {
                  final approvedQuotation =
                      (_projectDetails!['quotations'] as List?)?.firstWhere(
                          (q) => q['status'] == 'APPROVED',
                          orElse: () => null);
                  
                  // === ERROR FIX YAHAN HAI ===
                  final totalAmount = double.tryParse(
                          approvedQuotation?['amount'].toString() ?? '0.0') ?? 0.0;
                  // ==========================

                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => CreatePhasePlanScreen(
                      projectId: widget.projectId,
                      totalAmount: totalAmount,
                      initialPhases: phases,
                    ),
                  )).then((success) {
                    if (success == true) {
                      _fetchProjectDetails();
                    }
                  });
                } else {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => ViewPhasePlanScreen(phases: phases),
                  ));
                }
              },
            ),

          ListTile(
            leading: const Icon(Iconsax.document_text_1),
            title: const Text('View Requirement Details'),
            onTap: () {
              Navigator.of(context).pop();
              if (requirement != null) {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) =>
                      RequirementDetailViewScreen(requirementData: requirement),
                ));
              }
            },
          ),
          ListTile(
            leading: const Icon(Iconsax.receipt_2_1, color: Colors.blue),
            title: const Text('View Update History'),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => UpdateHistoryScreen(updates: updates),
              ));
            },
          ),
          ListTile(
            leading: const Icon(Iconsax.calendar_1, color: Colors.purple),
            title: const Text('View Project Timeline'),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) =>
                    ProjectTimelineScreen(projectDetails: _projectDetails!),
              ));
            },
          ),
          const Divider(),
          if (isWorkInProgress) ...[
            ListTile(
              leading:
                  const Icon(Iconsax.document_upload, color: Colors.orange),
              title: const Text('Send New/Updated Quotation'),
              onTap: () {
                Navigator.of(context).pop();
                if (requirement != null) {
                  Navigator.of(context)
                      .push(MaterialPageRoute(
                          builder: (_) => CreateQuotationScreen(
                                projectId: widget.projectId,
                                requirementId: requirement['id'],
                              )))
                      .then((_) => _fetchProjectDetails());
                }
              },
            ),
            ListTile(
              leading: const Icon(Iconsax.task, color: Colors.teal),
              title: const Text('View Quotation History'),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => QuotationHistoryScreen(
                    projectId: _projectDetails!['id'],
                  ),
                ));
              },
            ),
            const Divider(),
          ],
          if (isWorkInProgress)
            ListTile(
              leading: const Icon(Iconsax.task_square, color: Colors.green),
              title: const Text('Mark Project as Complete'),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context)
                    .push(MaterialPageRoute(
                  builder: (_) =>
                      RequestCompletionScreen(projectId: widget.projectId),
                ))
                    .then((_) => _fetchProjectDetails());
              },
            ),
        ],
      ),
    );
  }

  Widget _buildActionWidget() {
    final status = _projectDetails!['status'];
    final customerName = _projectDetails!['customer']?['name'] ?? 'Customer';
    final requirement = _projectDetails!['requirement'] ?? {};

    Widget chatButton() {
      return OutlinedButton.icon(
        icon: const Icon(Iconsax.message),
        label: const Text("Chat with Customer"),
        onPressed: () {
          if (_myProfile != null) {
            Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => ChatScreen(
                      projectId: widget.projectId,
                      customerName: customerName,
                      myName: _myProfile!.name,
                    )));
          }
        },
      );
    }

    switch (status) {
      case 'SPECIALIST_CONNECTED':
      case 'QUOTATION_CANCELLED':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            chatButton(),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              icon: const Icon(Iconsax.document_upload),
              label: Text(status == 'QUOTATION_CANCELLED'
                  ? 'Send Quotation Again'
                  : 'Create & Send Quotation'),
              onPressed: () {
                Navigator.of(context)
                    .push(MaterialPageRoute(
                        builder: (_) => CreateQuotationScreen(
                              projectId: widget.projectId,
                              requirementId: requirement['id'],
                            )))
                    .then((_) => _fetchProjectDetails());
              },
            ),
          ],
        );

      case 'WAITING_QUOTATION_CONFIRMATION':
        return const Card(
          color: Color(0xFFFFF3CD),
          child: ListTile(
            leading: Icon(Iconsax.clock, color: Color(0xFF664D03)),
            title: Text("Quotation Sent"),
            subtitle: Text("Waiting for customer to approve."),
          ),
        );

      case 'QUOTATION_APPROVED':
        final approvedQuotation = (_projectDetails!['quotations'] as List?)
            ?.firstWhere((q) => q['status'] == 'APPROVED', orElse: () => null);

        if (approvedQuotation == null) {
          return const Card(
            color: Color.fromRGBO(255, 235, 238, 1),
            child: ListTile(
              leading: Icon(Iconsax.warning_2, color: Colors.red),
              title: Text("Error"),
              subtitle: Text("Approved quotation details not found."),
            ),
          );
        }

        final totalAmount =
            double.tryParse(approvedQuotation['amount'].toString()) ?? 0.0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 2,
              color: Colors.teal.shade50,
              shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12))),
              child: const ListTile(
                leading: Icon(Iconsax.like_1, color: Colors.teal),
                title: Text("Quotation Approved!",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle:
                    Text("Great! Now create a phase-wise plan for the customer."),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Iconsax.document_upload),
              label: const Text('Create Phase Plan'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                final result = await Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => CreatePhasePlanScreen(
                    projectId: widget.projectId,
                    totalAmount: totalAmount,
                  ),
                ));
                if (result == true) {
                  _fetchProjectDetails();
                }
              },
            ),
          ],
        );

      case 'WAITING_FOR_PHASE_PLAN_APPROVAL':
        return const Card(
          color: Color(0xFFFFF3CD),
          child: ListTile(
            leading: Icon(Iconsax.clock, color: Color(0xFF664D03)),
            title: Text("Phase Plan Submitted"),
            subtitle: Text("Waiting for customer to approve the plan."),
          ),
        );

            case 'PHASE_PLAN_REJECTED':
        return Card(
          elevation: 2,
          color: Colors.red.shade50,
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12))),
          child: const ListTile(
            leading: Icon(Iconsax.dislike, color: Colors.red),
            title: Text("Phase Plan Rejected",
                style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle:
                Text("The customer has rejected the plan. Please review and submit it again from the options menu (⋮)."),
          ),
        );  
      
      case 'PHASE_PLAN_APPROVED':
        return const Card(
          color: Color.fromRGBO(227, 242, 253, 1),
          child: ListTile(
            leading: Icon(Iconsax.wallet_check, color: Colors.blue),
            title: Text("Plan Approved, Awaiting Payment"),
            subtitle: Text("Waiting for customer to pay for the first phase."),
          ),
        );

      case 'WORK_IN_PROGRESS':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Iconsax.message_add),
              label: const Text("Send Project Updates"),
              onPressed: () async {
                final result = await Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => CreateUpdateScreen(projectId: widget.projectId),
                ));
                if (result == true) {
                  _fetchProjectDetails();
                }
              },
            ),
            const SizedBox(height: 12),
            chatButton(),
          ],
        );

      case 'WORK_COMPLETION_PENDING':
        return const Card(
          color: Color(0xFFFFF3CD),
          child: ListTile(
            leading: Icon(Iconsax.clock, color: Color(0xFF664D03)),
            title: Text("Completion Request Sent"),
            subtitle:
                Text("Waiting for customer to confirm project completion."),
          ),
        );

      case 'WORK_COMPLETED':
        return Card(
          color: Colors.green.shade50,
          child: const ListTile(
            leading: Icon(Iconsax.verify, color: Colors.green),
            title: Text("Project Completed"),
            subtitle: Text("This project has been successfully completed."),
          ),
        );

      case 'WORK_CANCELLED':
        return Card(
          color: Colors.red.shade50,
          child: const ListTile(
            leading: Icon(Iconsax.close_circle, color: Colors.red),
            title: Text("Project Cancelled"),
            subtitle: Text("This project has been cancelled."),
          ),
        );

      default:
        return Text("Current Status: $status");
    }
  }
}

