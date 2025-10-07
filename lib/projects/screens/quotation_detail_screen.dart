// lib/projects/screens/quotation_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:apna_thekedar_specialist/api/api_service.dart';
import 'package:provider/provider.dart';

class QuotationDetailScreen extends StatelessWidget {
  final Map<String, dynamic> quotation;

  const QuotationDetailScreen({super.key, required this.quotation});

    Future<void> _showDeleteConfirmationDialog(BuildContext context, int quotationId) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Delete Quotation?'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Are you sure you want to delete this quotation? This action cannot be undone.'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('No'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: const Text('Yes, Delete'),
              onPressed: () async {
                try {
                  // Yahan API call hogi
                  final apiService = Provider.of<ApiService>(context, listen: false);
                  await apiService.delete('/projects/quotations/$quotationId/delete/');
                  
                  // NOTE: Upar wali lines ko apne project ke structure ke hisaab se adjust karein
                  // Abhi ke liye, hum sirf pop karenge
                  
                  Navigator.of(dialogContext).pop(); // Dialog band karein
                  Navigator.of(context).pop(); // Detail screen se wapas jaayein

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Quotation deleted successfully')),
                  );
                } catch (e) {
                   Navigator.of(dialogContext).pop();
                   ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: ${e.toString()}')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    final items = (quotation['items'] as List?) ?? [];
    final status = quotation['status'] ?? 'N/A';
    final double calculatedTotalAmount = items.fold(0.0, (sum, item) {
      // Make sure 'charge' is parsed correctly from whatever type it is
      final charge = double.tryParse(item['charge'].toString()) ?? 0.0;
      return sum + charge;
    });
    final createdAt = quotation['created_at'] != null 
        ? DateFormat('dd MMM, yyyy').format(DateTime.parse(quotation['created_at']))
        : 'N/A';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quotation Details'),
        actions: [
          if (quotation['status'] == 'SENT')
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () {
                _showDeleteConfirmationDialog(context, quotation['id']);
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Quotation #${quotation['id']}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildInfoRow('Status:', status),
            _buildInfoRow('Sent On:', createdAt),
            _buildInfoRow('Total Amount:', '₹ ${calculatedTotalAmount.toStringAsFixed(2)}'),
            const Divider(height: 30),
            const Text('Items', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ...items.map((item) => Card(
              child: ListTile(
                title: Text(item['item_name']),
                subtitle: Text('Quantity: ${item['value']} • Time: ${item['time_in_days']} days'),
                trailing: Text('₹ ${item['charge']}'),
              ),
            )).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }
}