// lib/projects/screens/short_service_detail_screen.dart (UPDATED WITH OTP)
import 'dart:convert';
import 'dart:io';
import 'package:apna_thekedar_specialist/api/api_service.dart';
import 'package:apna_thekedar_specialist/chat/chat_screen.dart';
import 'package:apna_thekedar_specialist/core/models/user_profile.dart';
import 'package:apna_thekedar_specialist/core/widgets/attractive_error_widget.dart';
import 'package:apna_thekedar_specialist/projects/screens/directions_screen.dart';
import 'package:apna_thekedar_specialist/support/request_assistant_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // OTP ke liye
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:slide_to_act/slide_to_act.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';

class ShortServiceDetailScreen extends StatefulWidget {
  final int bookingId;
  const ShortServiceDetailScreen({super.key, required this.bookingId});

  @override
  State<ShortServiceDetailScreen> createState() => _ShortServiceDetailScreenState();
}

class _ShortServiceDetailScreenState extends State<ShortServiceDetailScreen> {
  late Future<Map<String, dynamic>> _detailsFuture;
  ApiService? _apiService;
  UserProfile? _myProfile;
  
  // === OTP ke liye naye variables ===
  final _otpController = TextEditingController();
  final _otpFormKey = GlobalKey<FormState>();
  bool _isOtpLoading = false;
  // ==================================

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _apiService = Provider.of<ApiService>(context, listen: false);
      _refreshDetails();
    });
  }
  
  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  void _refreshDetails() {
    setState(() {
      _detailsFuture = _fetchDetails();
    });
  }

  Future<Map<String, dynamic>> _fetchDetails() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isEmpty || result[0].rawAddress.isEmpty) {
        throw const SocketException("No Internet");
      }

      if (_apiService == null) {
        throw Exception("ApiService not initialized");
      }

      final responses = await Future.wait([
        _apiService!.get('/projects/short-service/${widget.bookingId}/details/'),
        UserProfile.loadFromApi(),
      ]);

      final bookingResponse = responses[0] as http.Response; 
      _myProfile = responses[1] as UserProfile?; 
      
      if (bookingResponse.statusCode == 200) { 
        return json.decode(bookingResponse.body);
      } else {
        throw Exception('Failed to load job details');
      }
    } catch (e) {
      rethrow;
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString).toLocal();
      return DateFormat('dd MMM, yyyy - hh:mm a').format(date);
    } catch (e) {
      return 'Invalid Date';
    }
  }
  
  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: '+91$phoneNumber');
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not place the call.')));
    }
  }
  
  Future<void> _getDirections(Map<String, dynamic> job) async {
    final specialistLat = _myProfile?.addresses.firstWhere((a) => a['address_type'] == 'CURRENT', orElse: () => null)?['latitude'];
    final specialistLng = _myProfile?.addresses.firstWhere((a) => a['address_type'] == 'CURRENT', orElse: () => null)?['longitude'];
    final customerLat = job['latitude'];
    final customerLng = job['longitude'];

    if (specialistLat == null || specialistLng == null || customerLat == null || customerLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location data is incomplete.')));
      return;
    }

    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => DirectionsScreen(
        origin: LatLng(double.parse(specialistLat), double.parse(specialistLng)),
        destination: LatLng(double.parse(customerLat), double.parse(customerLng)),
      ),
    ));
  }

  // === YEH FUNCTION AB OTP KE SAATH API CALL KAREGA ===
  Future<void> _startWork(String otp, BuildContext dialogContext) async {
    // Dialog ke andar loader chalu karo
    (dialogContext as Element).markNeedsBuild();
    setState(() => _isOtpLoading = true);

    try {
      // API call karein aur OTP body mein bhejें
      final response = await _apiService!.post(
        '/projects/short-service/${widget.bookingId}/start-work/', 
        {'otp': otp} // OTP ko body mein bhejein
      );
      
      if (mounted) {
        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Work Started!'), backgroundColor: Colors.green));
          Navigator.of(dialogContext).pop(); // Dialog band karein
          _refreshDetails(); // Screen refresh karein
        } else {
          // Error response (jaise "Invalid OTP") dikhayein
          final error = json.decode(response.body);
          ScaffoldMessenger.of(dialogContext).showSnackBar(SnackBar(
            content: Text('Error: ${error['error'] ?? 'Failed to start'}'), 
            backgroundColor: Colors.red
          ));
        }
      }
    } catch (e) {
       if (mounted) {
         ScaffoldMessenger.of(dialogContext).showSnackBar(SnackBar(content: Text('An error occurred: $e')));
       }
    }
    
    // Loader band karo
    (dialogContext as Element).markNeedsBuild();
    setState(() => _isOtpLoading = false);
  }
  
  // === YEH NAYA FUNCTION HAI OTP DIALOG DIKHANE KE LIYE ===
  Future<void> _showOTPDialog(BuildContext context) async {
    _otpController.clear(); // Har baar dialog kholne par purana OTP clear karein
    
    return showDialog<void>(
      context: context,
      barrierDismissible: !_isOtpLoading, // Jab loading ho rahi ho toh dialog band na ho
      builder: (BuildContext dialogContext) {
        // StatefulBuilder ka istemaal karein taaki dialog ke andar loader update ho sake
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Enter 4-Digit OTP'),
              content: Form(
                key: _otpFormKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Please get the 4-digit OTP from the customer to start the work.'),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _otpController,
                      decoration: const InputDecoration(labelText: 'Enter OTP'),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      maxLength: 4,
                      validator: (value) {
                        if (value == null || value.length != 4) {
                          return 'Please enter a 4-digit OTP';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: _isOtpLoading ? null : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: _isOtpLoading ? null : () {
                    if (_otpFormKey.currentState!.validate()) {
                      // _startWork ko dialogContext pass karein
                      _startWork(_otpController.text, dialogContext);
                    }
                  },
                  child: _isOtpLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Submit & Start'),
                ),
              ],
            );
          },
        );
      },
    );
  }
  // =======================================================
  
  // Kaam khatam karne ke liye (yeh waise hi rahega)
  Future<void> _completeWork(GlobalKey<SlideActionState> slideKey) async {
     try {
      final response = await _apiService!.post('/projects/short-service/${widget.bookingId}/complete/', {});
      if (mounted) {
        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Job Completed!'), backgroundColor: Colors.green));
          _refreshDetails();
        } else {
          slideKey.currentState?.reset();
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${response.body}')));
        }
      }
    } catch (e) {
       if (mounted) {
         slideKey.currentState?.reset();
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('An error occurred: $e')));
       }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Short Service Details'),
        actions: [
          IconButton(
            icon: const Icon(Iconsax.refresh),
            onPressed: _refreshDetails,
          ),
          IconButton(
            icon: const Icon(Iconsax.headphone),
            tooltip: 'Request Assistance (Not available for short jobs yet)',
            onPressed: null,
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _detailsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            bool isInternetError = snapshot.error is SocketException;
            return AttractiveErrorWidget(
              imagePath: isInternetError ? 'assets/no_internet.png' : 'assets/server_error.png',
              title: isInternetError ? "No Internet" : "Server Error",
              message: "Could not load job details. Please try again.",
              buttonText: "Retry",
              onRetry: _refreshDetails,
            );
          }

          final job = snapshot.data!;
          final customer = job['customer'] ?? {};
          final status = job['status'];

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${job['number_of_items']} x ${job['item']}",
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Iconsax.calendar_1, color: Colors.blue),
                        title: Text(_formatDate(job['booking_time'])),
                        subtitle: const Text('Booking Time'),
                      ),
                      const Divider(),
                      
                      const Text('Customer Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black54)),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          child: Text(customer['name']?[0] ?? 'C'),
                        ),
                        title: Text(customer['name'] ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(customer['phone_number'] ?? 'N/A'),
                        trailing: IconButton(
                          icon: const Icon(Iconsax.call, color: Colors.green, size: 30),
                          onPressed: () => _makePhoneCall(customer['phone_number']),
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      Text(job['address'], style: const TextStyle(fontSize: 15)),
                      Text('Pincode: ${job['pincode']}', style: const TextStyle(fontSize: 15, color: Colors.grey)),
                      const SizedBox(height: 16),
                      
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Iconsax.direct_right),
                              label: const Text('Directions'),
                              onPressed: () => _getDirections(job),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Iconsax.message),
                              label: const Text('Chat'),
                              onPressed: null, // Disabled for now
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 32),
                      
                      _buildStatusCard(status),
                    ],
                  ),
                ),
              ),
              // Bottom Slider Action
              if (status == 'ASSIGNED' || status == 'WORK_STARTED')
                _buildActionWidget(status), // Function ka naam badal diya
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatusCard(String status) {
    // ... (yeh function waise hi rahega) ...
    IconData icon;
    Color color;
    String text;

    switch (status) {
      case 'ASSIGNED':
        icon = Iconsax.clock;
        color = Colors.blue;
        text = 'Job Assigned. Please go to the location and enter OTP to start.';
        break;
      case 'WORK_STARTED':
        icon = Iconsax.play_circle;
        color = Colors.orange;
        text = 'Work is in progress. Mark as complete when done.';
        break;
      case 'COMPLETED':
        icon = Iconsax.verify;
        color = Colors.green;
        text = 'This job has been successfully completed.';
        break;
      case 'CANCELLED':
      case 'UNASSIGNED':
        icon = Iconsax.close_circle;
        color = Colors.red;
        text = 'This job was cancelled or unassigned.';
        break;
      default:
        icon = Iconsax.info_circle;
        color = Colors.grey;
        text = 'Status: $status';
    }

    return Card(
      color: color.withOpacity(0.1),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
      ),
    );
  }

  // === YEH FUNCTION AB SLIDER YA BUTTON DIKHAYEGA ===
  Widget _buildActionWidget(String status) {
    final GlobalKey<SlideActionState> _slideKey = GlobalKey();
    
    if (status == 'ASSIGNED') {
      // "Start Work" ke liye OTP button
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton.icon(
          icon: const Icon(Iconsax.key),
          label: const Text('Enter OTP to Start Work'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            backgroundColor: Colors.blue,
          ),
          onPressed: () => _showOTPDialog(context),
        ),
      );
    } 
    
    if (status == 'WORK_STARTED') {
      // "Complete Job" ke liye slider
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: SlideAction(
          key: _slideKey,
          text: 'Slide to Complete Job',
          outerColor: Colors.green,
          onSubmit: () {
            _completeWork(_slideKey);
            return null;
          },
        ),
      );
    }

    // Baaki cases mein kuch nahi dikhana
    return const SizedBox.shrink();
  }
}