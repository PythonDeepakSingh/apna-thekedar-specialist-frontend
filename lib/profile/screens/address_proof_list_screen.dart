// lib/profile/screens/address_proof_list_screen.dart (FINAL CORRECTED CODE)
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'dart:convert';
import 'package:apna_thekedar_specialist/api/api_service.dart';
import 'package:apna_thekedar_specialist/profile/screens/address_proof_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:apna_thekedar_specialist/core/widgets/full_screen_image_viewer.dart';
import 'dart:io';
import 'package:apna_thekedar_specialist/core/widgets/attractive_error_widget.dart';

class AddressProofListScreen extends StatefulWidget {
  final String addressType;
  const AddressProofListScreen({super.key, required this.addressType});

  @override
  State<AddressProofListScreen> createState() => _AddressProofListScreenState();
}

class _AddressProofListScreenState extends State<AddressProofListScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<dynamic>> _documentsFuture;

  @override
  void initState() {
    super.initState();
    _documentsFuture = _fetchAddressProofs();
  }

  Future<List<dynamic>> _fetchAddressProofs() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isEmpty || result[0].rawAddress.isEmpty) {
        throw const SocketException("No Internet");
      }
    } on SocketException catch (_) {
      throw const SocketException("No Internet");
    }

    final response = await _apiService.get('/specialist/documents/address-proofs/');
    if (response.statusCode == 200) {
      final allDocs = json.decode(response.body) as List;
      String apiAddressType = widget.addressType == 'Permanent' ? 'PERMANENT' : 'CURRENT';
      return allDocs.where((doc) {
        return doc['address_type'] == apiAddressType || doc['document_for'] == ("${apiAddressType}_ADDRESS");
      }).toList();
    } else {
      throw Exception('Failed to load address proofs');
    }
  }
  
  void _refreshData() {
    setState(() {
      _documentsFuture = _fetchAddressProofs();
    });
  }

  // ... (_deleteProof aur _viewDocument functions waise hi rahenge) ...
  Future<void> _deleteProof(dynamic doc) async {
    String endpoint;
    if (doc.containsKey('document_for')) {
      endpoint = '/specialist/documents/misc/${doc['id']}/';
    } else if (!doc['id'].toString().startsWith('identity')) {
      endpoint = '/specialist/documents/address-proofs/${doc['id']}/';
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('This can only be changed from the address upload screen.')));
      return;
    }

    try {
      final response = await _apiService.delete(endpoint);
      if (mounted) {
        if (response.statusCode == 204) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Document deleted successfully!')));
          _refreshData();
        } else {
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${response.body}')));
        }
      }
    } catch (e) {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('An error occurred: $e')));
      }
    }
  }
  
  Future<void> _viewDocument(dynamic doc) async {

    final docId = doc['id'].toString();
    final fileUrl = doc['document_file_url']; // fileUrl ko yahan define karein

    if (docId.startsWith('identity')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This uses your Aadhaar/PAN card image. View it in the Identity Proof section.'),
        ),
      );
      return; // Aage kuch na karein
    }

    if (fileUrl == null || fileUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No file available to view.')));
      return;
    }
  
    final isPdf = fileUrl.toLowerCase().endsWith('.pdf');
    final isImage = fileUrl.toLowerCase().endsWith('.jpg') || fileUrl.toLowerCase().endsWith('.jpeg') || fileUrl.toLowerCase().endsWith('.png');
  
    if (isPdf) {
      final uri = Uri.parse(fileUrl);
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
          builder: (context) => FullScreenImageViewer(imageUrl: fileUrl),
        ),
      );
    } else {
      final uri = Uri.parse(fileUrl);
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
            message: "Could not load your address proofs.",
            buttonText: "Retry",
            onRetry: _refreshData,
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          body = Center(child: Text("No documents uploaded for ${widget.addressType.toLowerCase()} address."));
        } else {
          final documents = snapshot.data!;
          body = ListView.builder(
            itemCount: documents.length,
            itemBuilder: (context, index) {
              final doc = documents[index];
              final status = doc['status'] ?? 'PENDING';
              final isIdentityProof = doc['id'].toString().startsWith('identity');
              bool canDelete = status == 'PENDING' && !isIdentityProof;
              final fileUrl = doc['document_file_url'];
              final isPdf = fileUrl?.toString().toLowerCase().endsWith('.pdf') ?? false;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: SizedBox(
                    width: 50,
                    height: 50,
                    child: (fileUrl != null && fileUrl.isNotEmpty)
                      ? (isPdf ? const Icon(Iconsax.document_1, size: 40) : Image.network(fileUrl, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Iconsax.gallery_slash)))
                      : const Icon(Iconsax.card, size: 40),
                  ),
                  title: Text(doc['document_type_name'] ?? doc['document_name'] ?? 'Document'),
                  subtitle: Text('Status: $status'),
                  onTap: () => _viewDocument(doc),
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
            title: Text('${widget.addressType} Address Proofs'),
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
                      MaterialPageRoute(builder: (context) => AddressProofScreen(addressType: widget.addressType)),
                    );
                    if (result == true) {
                      _refreshData();
                    }
                  },
                  label: const Text('Add New Proof'),
                  icon: const Icon(Iconsax.add),
                ),
        );
      },
    );
  }
}