// lib/support/support_screen.dart
import 'package:flutter/material.dart';
import 'package:apna_thekedar_specialist/api/api_service.dart';
import 'package:apna_thekedar_specialist/core/widgets/attractive_error_widget.dart';
import 'package:iconsax/iconsax.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'dart:io';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<dynamic>> _supportRulesFuture;

  @override
  void initState() {
    super.initState();
    _supportRulesFuture = _fetchSupportRules();
  }

  Future<List<dynamic>> _fetchSupportRules() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isEmpty || result[0].rawAddress.isEmpty) {
        throw const SocketException("No Internet");
      }
      final response = await _apiService.get('/operations/support-rules/');
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load support rules');
      }
    } catch (e) {
      // Re-throw the error to be caught by FutureBuilder
      rethrow;
    }
  }

  Future<void> _handleCardTap(Map<String, dynamic> rule) async {
    final type = rule['support_type'];
    Uri? uri;

    if (type == 'PHONE') {
      // Country code na lagayein, jaisa backend se aaya hai waisa hi use karein
      uri = Uri(scheme: 'tel', path: rule['phone_number']);
    } else if (type == 'EMAIL') {
      uri = Uri(scheme: 'mailto', path: rule['email']);
    } else if (type == 'URL') {
      uri = Uri.parse(rule['web_url']);
    }

    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch ${uri?.toString() ?? 'the link'}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _supportRulesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            bool isInternetError = snapshot.error is SocketException;
            return AttractiveErrorWidget(
              imagePath: isInternetError ? 'assets/no_internet.png' : 'assets/server_error.png',
              title: isInternetError ? "No Internet" : "Server Error",
              message: "We couldn't load support options. Please check your connection.",
              buttonText: "Retry",
              onRetry: () {
                setState(() {
                  _supportRulesFuture = _fetchSupportRules();
                });
              },
            );
          }

          final rules = snapshot.data ?? [];

          if (rules.isEmpty) {
            return const Center(child: Text('No support options available right now.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: rules.length,
            itemBuilder: (context, index) {
              final rule = rules[index];
              return _buildSupportCard(
                title: rule['title'],
                description: rule['description'],
                type: rule['support_type'],
                onTap: () => _handleCardTap(rule),
              );
            },
          );
        },
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'PHONE':
        return Iconsax.call;
      case 'EMAIL':
        return Iconsax.direct;
      case 'URL':
        return Iconsax.global;
      default:
        return Iconsax.message_question;
    }
  }

  Widget _buildSupportCard({
    required String title,
    required String description,
    required String type,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(_getIconForType(type), size: 30, color: Theme.of(context).primaryColor),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    if (description.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(description, style: const TextStyle(color: Colors.grey)),
                      ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}