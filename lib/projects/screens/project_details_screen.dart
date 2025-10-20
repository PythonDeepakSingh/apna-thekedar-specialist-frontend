// lib/projects/screens/project_details_screen.dart (FINAL & CORRECTED)

import 'dart:convert';
import 'package:apna_thekedar_specialist/projects/screens/create_phase_plan_screen.dart';
import 'package:apna_thekedar_specialist/projects/screens/view_phase_plan_screen.dart';
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
import 'package:slide_to_act/slide_to_act.dart';
import 'dart:ui'; // ImageFilter ke liye zaroori hai
import 'package:apna_thekedar_specialist/support/request_assistant_screen.dart'; // YEH NAYA IMPORT ADD KAREIN

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
      }
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Project location is not available.')));
      return;
    }
    final Uri googleMapsUrl = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open Google Maps.')));
    }
  }

  Future<void> _startWork() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.post('/projects/${widget.projectId}/start-work/', {});
      if (mounted) {
        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Work Started! Good luck.'), backgroundColor: Colors.green));
          _fetchProjectDetails();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: ${response.body}")));
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("An error occurred: $e")));
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    // ===== CORRECTION 1: APPBAR SE DYNAMIC TITLE HATA DIYA GAYA HAI =====
    String appBarTitle = _projectDetails?['title'] ?? 'Project Details';
    // Project ka current status nikaalein
    final String? projectStatus = _projectDetails?['status'];

    // Yeh woh statuses hain jinmein chat button nahi dikhna chahiye
    const List<String> hideChatStatuses = [
      'WORK_COMPLETED',
      'WORK_CANCELLED',
      'WORK_PAUSED'
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(appBarTitle),
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
                            const SizedBox(height: 8),
                            _buildActionWidget(),

                            if (projectStatus != null && !hideChatStatuses.contains(projectStatus)) ...[
                              const Divider(height: 40),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  icon: const Icon(Iconsax.message),
                                  label: const Text("Chat with Customer"),
                                  onPressed: () {
                                    if (_myProfile != null) {
                                      Navigator.of(context).push(MaterialPageRoute(
                                          builder: (_) => ChatScreen(
                                                projectId: widget.projectId,
                                                customerName: _projectDetails!['customer']?['name'] ?? 'Customer',
                                                myName: _myProfile!.name,
                                              )));
                                    }
                                  },
                                ),
                              ),
                            ],
                            // =========================================
                          ],
                        ),
                      ),
                    ),
    );
  }


  Widget _buildInfoCard() {
    final customer = _projectDetails!['customer'] ?? {};
    final status = _projectDetails!['status'];
    final phases = (_projectDetails!['phases'] as List<dynamic>? ?? []);
    
    // Yahan current phase dhoondhenge
    final inProgressPhase = (status == 'WORK_IN_PROGRESS') 
        ? phases.firstWhere((p) => p['status'] == 'IN_PROGRESS', orElse: () => null) 
        : null;

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
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
            ),
            if (inProgressPhase != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Chip(
                  label: Text(
                    "Currently in: Phase ${inProgressPhase['phase_number']}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  backgroundColor: Colors.teal.shade50,
                  side: BorderSide(color: Colors.teal.shade200),
                  avatar: Icon(Iconsax.play_circle, color: Colors.teal.shade800, size: 18),
                ),
              ),
            const SizedBox(height: 8),
            Text(
              _projectDetails!['description'] ?? 'No description provided.',
              style: TextStyle(fontSize: 16, color: Colors.grey[700], height: 1.5),
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
                      const Text('Location', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
                      const SizedBox(height: 4),
                      Text(
                        '${_projectDetails!['address'] ?? ''}, ${_projectDetails!['pincode'] ?? ''}',
                        style: const TextStyle(fontSize: 15, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: Icon(
                    Iconsax.direct_right,
                    // Agar project complete ya cancel ho gaya hai to icon ko grey kar do
                    color: (status == 'WORK_COMPLETED' || status == 'WORK_CANCELLED') ? Colors.grey : Colors.blue,
                    size: 28
                  ),
                  // Agar project complete ya cancel ho gaya hai to onPressed ko null kar do (button disable ho jaayega)
                  onPressed: (status == 'WORK_COMPLETED' || status == 'WORK_CANCELLED') ? null : _launchMaps,
                  tooltip: 'Get Directions',
                ),
              ],
            ),
            const Divider(height: 30),
            const Text('Customer Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: Colors.brown.shade100,
                child: Text(customer['name']?[0] ?? 'C', style: TextStyle(color: Colors.brown.shade800, fontWeight: FontWeight.bold)),
              ),
              title: Text(customer['name'] ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.w600)),
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
    } catch (e) { /* ignore */ }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(formattedDate, style: const TextStyle(fontWeight: FontWeight.bold)),
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
              status == 'WORK_COMPLETED' ? 'Project Completion Details' : 'Project Cancellation Details',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(height: 20),
            _buildDateRow('Created On', _projectDetails!['created_at']),
            _buildDateRow('Connected On', _projectDetails!['specialist_connected_at']),
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
    final updates = updatesData.map((data) => ProjectUpdate.fromJson(data)).toList();
    final status = _projectDetails!['status'];
    final phases = (_projectDetails!['phases'] as List<dynamic>? ?? []);
    final bool canSpecialistTakeAction = status == 'WORK_IN_PROGRESS' || status == 'PHASE_PLAN_REJECTED';
    final bool showSecondaryActions = [
      'WORK_IN_PROGRESS',
      'PHASE_COMPLETION_PENDING',
      'PHASE_DONE_WAITING_FOR_NEXT',
      'WORK_COMPLETION_PENDING',
      'WORK_COMPLETED',
      'WORK_CANCELLED'
    ].contains(status);

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Color(0xFF4B2E1E)),
            child: Text('Project Options', style: TextStyle(color: Colors.white, fontSize: 24)),
          ),
          if (phases.isNotEmpty)
            ListTile(
              leading: const Icon(Iconsax.task_square, color: Colors.indigo),
              title: Text((status == 'WAITING_FOR_PHASE_PLAN_APPROVAL' || status == 'PHASE_PLAN_REJECTED')
                  ? 'View / Update Phase Plan'
                  : 'View Phase Plan'),
              onTap: () {
                Navigator.of(context).pop();
                if (status == 'WAITING_FOR_PHASE_PLAN_APPROVAL' || status == 'PHASE_PLAN_REJECTED') {
                  final approvedQuotation = (_projectDetails!['quotations'] as List?)?.firstWhere((q) => q['status'] == 'APPROVED', orElse: () => null);
                  final totalAmount = double.tryParse(approvedQuotation?['amount'].toString() ?? '0.0') ?? 0.0;
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => CreatePhasePlanScreen(
                      projectId: widget.projectId,
                      totalAmount: totalAmount,
                      initialPhases: phases,
                    ),
                  )).then((success) {
                    if (success == true) _fetchProjectDetails();
                  });
                } else {
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => ViewPhasePlanScreen(phases: phases)));
                }
              },
            ),
          ListTile(
            leading: const Icon(Iconsax.document_text_1),
            title: const Text('View Requirement Details'),
            onTap: () {
              Navigator.of(context).pop();
              if (requirement != null) {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => RequirementDetailViewScreen(requirementData: requirement)));
              }
            },
          ),
          ListTile(
            leading: const Icon(Iconsax.receipt_2_1, color: Colors.blue),
            title: const Text('View Update History'),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => UpdateHistoryScreen(updates: updates)));
            },
          ),
          ListTile(
            leading: const Icon(Iconsax.calendar_1, color: Colors.purple),
            title: const Text('View Project Timeline'),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProjectTimelineScreen(projectDetails: _projectDetails!)));
            },
          ),
                   // "Call Assistant" button ko if condition se bahar nikaal diya gaya hai
          const Divider(),
          ListTile(
            leading: const Icon(Iconsax.headphone, color: Colors.blue),
            title: const Text('Call Project Assistant'),
            onTap: () {
              Navigator.of(context).pop(); // Pehle drawer band karein
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => RequestAssistantScreen(projectId: widget.projectId),
              ));
            },
          ),
          const Divider(),
          if (showSecondaryActions) ...[
            const Divider(),
            if (canSpecialistTakeAction)
              ListTile(
                leading: const Icon(Iconsax.document_upload, color: Colors.orange),
                title: const Text('Send New/Updated Quotation'),
                onTap: () {
                  Navigator.of(context).pop();
                  if (requirement != null) {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => CreateQuotationScreen(
                              projectId: widget.projectId,
                              requirementId: requirement['id'],
                            ))).then((_) => _fetchProjectDetails());
                  }
                },
              ),
            ListTile(
              leading: const Icon(Iconsax.task, color: Colors.teal),
              title: const Text('View Quotation History'),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => QuotationHistoryScreen(projectId: _projectDetails!['id'])));
              },
            ),


          ],
          if (canSpecialistTakeAction) ...[
            const Divider(),
            Builder(builder: (context) {
              final inProgressPhase = phases.firstWhere((p) => p['status'] == 'IN_PROGRESS', orElse: () => null);
              if (inProgressPhase == null) return const SizedBox.shrink();
              final bool isLastPhase = inProgressPhase['phase_number'] == phases.length;
              return ListTile(
                leading: const Icon(Iconsax.task_square, color: Colors.green),
                title: Text(isLastPhase ? 'Mark Project as Complete' : 'Mark Phase ${inProgressPhase['phase_number']} as Complete'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => RequestCompletionScreen(
                      projectId: widget.projectId,
                      phaseId: inProgressPhase['id'],
                      isLastPhase: isLastPhase,
                    ),
                  )).then((_) => _fetchProjectDetails());
                },
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildActionWidget() {
    final status = _projectDetails!['status'];
    final phases = (_projectDetails!['phases'] as List<dynamic>? ?? []);
    final requirement = _projectDetails!['requirement'] ?? {}; // <-- ERROR 1 FIX

    switch (status) {
      case 'SPECIALIST_CONNECTED':
      case 'QUOTATION_CANCELLED':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // chatButton() was here, removed to avoid duplication
            const SizedBox(height: 10),
            ElevatedButton.icon(
              icon: const Icon(Iconsax.document_upload),
              label: Text(status == 'QUOTATION_CANCELLED' ? 'Send Quotation Again' : 'Create & Send Quotation'),
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => CreateQuotationScreen(
                    projectId: widget.projectId,
                    requirementId: requirement['id'],
                  ))).then((_) => _fetchProjectDetails());
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
        final approvedQuotation = (_projectDetails!['quotations'] as List?)?.firstWhere((q) => q['status'] == 'APPROVED', orElse: () => null);
        if (approvedQuotation == null) return const Card(child: ListTile(title: Text("Error: Approved quotation not found.")));
        final totalAmount = double.tryParse(approvedQuotation['amount'].toString()) ?? 0.0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Card(
              elevation: 2, color: Color.fromRGBO(224, 242, 241, 1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
              child: ListTile(
                leading: Icon(Iconsax.like_1, color: Colors.teal),
                title: Text("Quotation Approved!", style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("Great! Now create a phase-wise plan for the customer."),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Iconsax.document_upload),
              label: const Text('Create Phase Plan'),
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              onPressed: () async {
                final result = await Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => CreatePhasePlanScreen(projectId: widget.projectId, totalAmount: totalAmount),
                ));
                if (result == true) _fetchProjectDetails();
              },
            ),
          ],
        );
        
      case 'PHASE_PLAN_REJECTED':
        return const Card(
          elevation: 2, color: Color.fromRGBO(255, 235, 238, 1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
          child: ListTile(
            leading: Icon(Iconsax.dislike, color: Colors.red),
            title: Text("Phase Plan Rejected", style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("The customer has rejected the plan. Please review and submit it again from the options menu (⋮)."),
          ),
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

      case 'PHASE_PLAN_APPROVED':
        final currentPhase = phases.firstWhere((phase) => phase['is_payment_done'] == false, orElse: () => null);
        if (currentPhase == null) return const Card(child: ListTile(title: Text("All phases seem to be paid.")));

        if (currentPhase['is_payment_done'] == false) {
          return Card(
            color: const Color.fromRGBO(227, 242, 253, 1),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Iconsax.wallet_check, color: Colors.blue),
                    title: Text("Ready for Phase ${currentPhase['phase_number']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text("Waiting for customer to pay for this phase to start the work."),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    icon: const Icon(Iconsax.refresh),
                    label: const Text("Check Payment Status"),
                    onPressed: _isLoading ? null : _fetchProjectDetails,
                  )
                ],
              ),
            ),
          );
        } else {
          return Column(
            children: [
              Text(
                'Payment for Phase ${currentPhase['phase_number']} received! You can start the work now.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.green, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              SlideAction(
                text: 'Slide to Start Work for Phase ${currentPhase['phase_number']}',
                outerColor: Colors.green,
                onSubmit: () async { await _startWork(); },
              ),
            ],
          );
        }

      case 'PHASE_COMPLETION_PENDING':
        return const Card(
          color: Color(0xFFFFF3CD),
          child: ListTile(
            leading: Icon(Iconsax.clock, color: Color(0xFF664D03)),
            title: Text("Request Sent"),
            subtitle: Text("Please wait while the customer accepts your work for this phase."),
          ),
        );

      case 'PHASE_DONE_WAITING_FOR_NEXT':
        // Step 1: Agla phase dhoondho (jiska status abhi bhi PENDING hai)
        final nextPhase = phases.firstWhere(
            (phase) => phase['status'] == 'PENDING',
            orElse: () => null,
        );

        // Agar koi agla phase nahi hai (matlab project khatam ho gaya hai)
        if (nextPhase == null) {
          return const Card(
            color: Colors.green,
            child: ListTile(
              leading: Icon(Iconsax.verify, color: Colors.green),
              title: Text("All Phases Completed!"),
              subtitle: Text("You can now mark the entire project as complete from the options menu."),
            ),
          );
        }

        // Step 2: Agle phase ka payment status check karo
        final bool isNextPhasePaid = nextPhase['is_payment_done'] == true;

        if (isNextPhasePaid) {
          // AGAR PAYMENT HO GAYI HAI TO: Slider dikhao
          return Column(
            children: [
              Text(
                'Payment for Phase ${nextPhase['phase_number']} received! You can start the work now for this phase.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.green, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              SlideAction(
                text: 'Slide to Start Work',
                outerColor: Colors.green,
                onSubmit: () async { await _startWork(); },
              ),
            ],
          );
        } else {
          // AGAR PAYMENT NAHI HUI HAI TO: Payment ka intezaar karne wala card dikhao
          return Card(
            color: const Color.fromRGBO(227, 242, 253, 1),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Iconsax.wallet_check, color: Colors.blue),
                    title: Text(
                      "Waiting for Payment for Phase ${nextPhase['phase_number']}",
                      style: const TextStyle(fontWeight: FontWeight.bold)
                    ),
                    subtitle: const Text("The previous phase is complete. Waiting for customer to pay for the next phase."),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    icon: const Icon(Iconsax.refresh),
                    label: const Text("Check Payment Status"),
                    onPressed: _isLoading ? null : _fetchProjectDetails,
                  )
                ],
              ),
            ),
          );
        }
      // ============================== NAYA LOGIC YAHAN KHATAM HOTA HAI ==============================


      case 'WORK_IN_PROGRESS':
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: InkWell(
            onTap: () async {
              final result = await Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => CreateUpdateScreen(projectId: widget.projectId),
              ));
              if (result == true) {
                _fetchProjectDetails();
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: const ListTile(
              leading: Icon(Iconsax.message_add, color: Colors.blue),
              title: Text("Send Project Update", style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text("Share photos and progress with the customer."),
              trailing: Icon(Iconsax.arrow_right_3),
            ),
          ),
        );

      case 'WORK_COMPLETION_PENDING':
         return const Card(
          color: Color(0xFFFFF3CD),
          child: ListTile(
            leading: Icon(Iconsax.clock, color: Color(0xFF664D03)),
            title: Text("Completion Request Sent"),
            subtitle: Text("Waiting for customer to confirm project completion."),
          ),
        );

      case 'WORK_COMPLETED':
        return Card(
          color: const Color(0xFFE8F5E9),
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