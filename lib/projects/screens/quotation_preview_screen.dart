// lib/projects/screens/quotation_preview_screen.dart
import 'package:flutter/material.dart';
import 'package:apna_thekedar_specialist/api/api_service.dart';
import 'package:apna_thekedar_specialist/projects/screens/waiting_quotation_screen.dart';

class QuotationPreviewScreen extends StatefulWidget {
  final Map<String, dynamic> quotationData;
  final int projectId;

  const QuotationPreviewScreen({
    super.key,
    required this.quotationData,
    required this.projectId,
  });

  @override
  State<QuotationPreviewScreen> createState() => _QuotationPreviewScreenState();
}

class _QuotationPreviewScreenState extends State<QuotationPreviewScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = false;

  Future<void> _sendQuotation() async {
    setState(() { _isLoading = true; });
    try {
      final response = await _apiService.post(
        '/projects/${widget.projectId}/quotations/create/',
        widget.quotationData,
      );
      if (mounted) {
        if (response.statusCode == 201) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (_) => WaitingQuotationConfirmationScreen(projectId: widget.projectId),
            ),
            (route) => false,
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${response.body}')));
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('An error occurred: $e')));
    }
    if (mounted) setState(() { _isLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final List<dynamic> items = widget.quotationData['items'];
    final totalAmount = widget.quotationData['amount'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Quotation'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Excel jaisi table
            DataTable(
              columnSpacing: 20,
              columns: const [
                DataColumn(label: Text('Item')),
                DataColumn(label: Text('Details')),
                DataColumn(label: Text('Charge'), numeric: true),
              ],
              rows: items.map((item) => DataRow(
                cells: [
                  DataCell(Text(item['item_name'])),
                  DataCell(Text("${item['value']} (${item['time_in_days']} days)")),
                  DataCell(Text("₹${item['charge']}")),
                ]
              )).toList(),
            ),
            const Divider(),
            ListTile(
              title: const Text("Total Amount", style: TextStyle(fontWeight: FontWeight.bold)),
              trailing: Text("₹$totalAmount", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            )
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: _isLoading ? null : _sendQuotation,
          child: _isLoading 
            ? const CircularProgressIndicator(color: Colors.white) 
            : const Text('Confirm & Send Quotation'),
        ),
      ),
    );
  }
}