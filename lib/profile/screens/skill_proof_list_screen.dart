// lib/profile/screens/skill_proof_list_screen.dart (FINAL CORRECTED CODE)
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'dart:convert';
import 'package:apna_thekedar_specialist/api/api_service.dart';
import 'package:apna_thekedar_specialist/profile/screens/skill_proof_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:apna_thekedar_specialist/core/widgets/full_screen_image_viewer.dart';
import 'dart:io';
import 'package:apna_thekedar_specialist/core/widgets/attractive_error_widget.dart';

class SkillProofListScreen extends StatefulWidget {
  const SkillProofListScreen({super.key});

  @override
  State<SkillProofListScreen> createState() => _SkillProofListScreenState();
}

class _SkillProofListScreenState extends State<SkillProofListScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<dynamic>> _documentsFuture;

  @override
  void initState() {
    super.initState();
    _documentsFuture = _fetchSkillProofs();
  }

  Future<List<dynamic>> _fetchSkillProofs() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isEmpty || result[0].rawAddress.isEmpty) {
        throw const SocketException("No Internet");
      }
    } on SocketException catch (_) {
      throw const SocketException("No Internet");
    }

    final response = await _apiService.get('/specialist/documents/skill-proofs/');
    if (response.statusCode == 200) {
      return json.decode(response.body) as List;
    } else {
      throw Exception('Failed to load skill documents');
    }
  }

  void _refreshData() {
    setState(() {
      _documentsFuture = _fetchSkillProofs();
    });
  }

  // ... (_deleteProof aur _viewDocument functions waise hi rahenge) ...
  Future<void> _deleteProof(dynamic doc) async {
    String endpoint;
    if (doc.containsKey('document_for')) {
      endpoint = '/specialist/documents/misc/${doc['id']}/';
    } else {
      endpoint = '/specialist/documents/skill-proofs/${doc['id']}/';
    }

    try {
      final response = await _apiService.delete(endpoint);
      if (mounted) {
        if (response.statusCode == 204) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Document deleted successfully!')),
          );
          _refreshData();
        } else {
           final error = json.decode(response.body);
           ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${error['detail'] ?? 'Failed to delete'}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An error occurred: $e')),
        );
      }
    }
  }
  
  Future<void> _viewDocument(String? url) async {
    if (url == null || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No file available to view.')));
      return;
    }
  
    final isPdf = url.toLowerCase().endsWith('.pdf');
    final isImage = url.toLowerCase().endsWith('.jpg') || url.toLowerCase().endsWith('.jpeg') || url.toLowerCase().endsWith('.png');
  
    if (isPdf) {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the document.')),
        );
      }
    } else if (isImage) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FullScreenImageViewer(imageUrl: url),
        ),
      );
    } else {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cannot open this file type.')),
        );
      }
    }
  }


@override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: _documentsFuture,
      builder: (context, snapshot) {
        bool showLoading = snapshot.connectionState == ConnectionState.waiting;
        bool showError = snapshot.hasError;

        Widget body;

        if (showLoading) {
          body = const Center(child: CircularProgressIndicator());
        } else if (showError) {
          bool isInternetError = snapshot.error is SocketException;
          body = AttractiveErrorWidget(
            imagePath: isInternetError ? 'assets/no_internet.png' : 'assets/server_error.png',
            title: isInternetError ? "No Internet" : "Server Error",
            message: "Could not load your skill proofs.",
            buttonText: "Retry",
            onRetry: _refreshData,
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          body = const Center(child: Text("No skill documents uploaded yet."));
        } else {
          final documents = snapshot.data!;
          body = ListView.builder(
            itemCount: documents.length,
            itemBuilder: (context, index) {
              final doc = documents[index];
              final status = doc['status'] ?? 'PENDING';
              bool canDelete = status == 'PENDING';
              final fileUrl = doc['document_file_url'] ?? '';
              final isPdf = fileUrl.toLowerCase().endsWith('.pdf');

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: SizedBox(
                    width: 50,
                    height: 50,
                    child: isPdf
                      ? const Icon(Iconsax.document_1, size: 40)
                      : Image.network(fileUrl, fit: BoxFit.cover,
                          errorBuilder: (c, e, s) => const Icon(Iconsax.gallery_slash),
                        ),
                  ),
                  title: Text(doc['document_type_name'] ?? doc['document_name'] ?? 'Document'),
                  subtitle: Text('Status: $status'),
                  onTap: () => _viewDocument(fileUrl),
                  trailing: canDelete
                      ? IconButton(
                          icon: const Icon(Iconsax.trash, color: Colors.red),
                          onPressed: () => _deleteProof(doc),
                        )
                      : null,
                ),
              );
            },
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Uploaded Skill Proofs'),
            actions: [
              IconButton(
                icon: const Icon(Iconsax.refresh),
                onPressed: _refreshData,
              )
            ],
          ),
          body: body,
          floatingActionButton: (showLoading || showError)
              ? null
              : FloatingActionButton.extended(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SkillProofScreen()),
                    );
                    if (result == true) {
                      _refreshData();
                    }
                  },
                  label: const Text('Add New Skill Proof'),
                  icon: const Icon(Iconsax.add),
                ),
        );
      },
    );
  }
}