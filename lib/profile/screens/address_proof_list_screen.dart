// lib/profile/screens/address_proof_list_screen.dart (FINAL & COMPLETE CODE)
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'dart:convert';
import 'package:apna_thekedar_specialist/api/api_service.dart';
import 'package:apna_thekedar_specialist/profile/screens/address_proof_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class AddressProofListScreen extends StatefulWidget {
  final String addressType; // 'Permanent' ya 'Current'
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
    final response = await _apiService.get('/specialist/documents/address-proofs/');
    if (response.statusCode == 200) {
      final allDocs = json.decode(response.body) as List;
      // Sirf is page ke type (Permanent/Current) ke documents filter karo
      String apiAddressType = widget.addressType == 'Permanent' ? 'PERMANENT' : 'CURRENT';
      // Hum dono tarah ke documents (uploaded + Aadhaar/PAN + "Other") ko filter karenge
      return allDocs.where((doc) {
        // 'document_for' miscellaneous docs ke liye hai, 'address_type' baaki sabke liye
        return doc['address_type'] == apiAddressType || doc['document_for'] == ("${apiAddressType}_ADDRESS");
      }).toList();
    } else {
      throw Exception('Failed to load address proofs');
    }
  }

  Future<void> _deleteProof(dynamic doc) async {
    String endpoint;
    // Check karo ki yeh normal document hai, miscellaneous, ya identity
    if (doc.containsKey('document_for')) { // Yeh 'MiscellaneousDocument' hai
      endpoint = '/specialist/documents/misc/${doc['id']}/';
    } else if (!doc['id'].toString().startsWith('identity')) { // Yeh 'AddressProof' hai
      endpoint = '/specialist/documents/address-proofs/${doc['id']}/';
    } else { // Yeh Aadhaar/PAN hai, ise delete nahi kar sakte
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('This can only be changed from the address upload screen.')));
      return;
    }

    try {
      final response = await _apiService.delete(endpoint);
      if (mounted) {
        if (response.statusCode == 204) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Document deleted successfully!')));
          setState(() { _documentsFuture = _fetchAddressProofs(); });
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
  
  Future<void> _viewDocument(String? url) async {
    if (url == null || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No file available to view.')));
      return;
    }
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open the document.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.addressType} Address Proofs'),
        actions: [
          IconButton(
            icon: const Icon(Iconsax.refresh),
            onPressed: () => setState(() { _documentsFuture = _fetchAddressProofs(); }),
          ),
        ],
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _documentsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
             return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text("No documents uploaded for ${widget.addressType.toLowerCase()} address."));
          }

          final documents = snapshot.data!;

          return ListView.builder(
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
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddressProofScreen(addressType: widget.addressType)),
          );
          if (result == true) {
            setState(() { _documentsFuture = _fetchAddressProofs(); });
          }
        },
        label: const Text('Add New Proof'),
        icon: const Icon(Iconsax.add),
      ),
    );
  }
}