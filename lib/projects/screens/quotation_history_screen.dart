// lib/projects/screens/quotation_history_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../api/api_service.dart';
import 'quotation_detail_screen.dart';

// Step 1: Hum screen ko ab project ID denge, quotations ki list nahi.
class QuotationHistoryScreen extends StatefulWidget {
  final int projectId;

  const QuotationHistoryScreen({super.key, required this.projectId});

  @override
  State<QuotationHistoryScreen> createState() => _QuotationHistoryScreenState();
}

class _QuotationHistoryScreenState extends State<QuotationHistoryScreen> {
  // Step 2: API se aa rahe data ko manage karne ke liye ek Future variable banayein.
  late Future<List<dynamic>> _quotationsFuture;

  @override
  void initState() {
    super.initState();
    // Step 3: Screen shuru hote hi data fetch karein.
    _refreshQuotations();
  }

  // Step 4: Data fetch karne ke liye ek alag function banayein.
  // Isse hum ise kahin se bhi call kar sakte hain.
  void _refreshQuotations() {
    setState(() {
      final apiService = Provider.of<ApiService>(context, listen: false);
      // API call karke project details fetch karein aur usse quotations nikalein.
      _quotationsFuture = apiService
          .get('/projects/${widget.projectId}/details/')
          .then((response) {
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          // quotations ki list return karein
          return data['quotations'] as List<dynamic>;
        } else {
          throw Exception('Failed to load quotations');
        }
      });
    });
  }

  // Step 5: Navigation ke liye ek alag function banayein jismein refresh logic ho.
  void _navigateToDetailAndRefresh(Map<String, dynamic> quotation) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => QuotationDetailScreen(quotation: quotation),
      ),
    ).then((_) {
      // Jab user detail screen se wapas aaye, toh yeh code chalega.
      print("Returned to history screen. Refreshing quotations...");
      _refreshQuotations();
    });
  }
  
  // Aapka purana total sum calculate karne wala function.
  // Hum ise ab quotations ki list ke saath istemaal karenge.
  double _calculateTotalSum(List<dynamic> quotations) {
    if (quotations.isEmpty) return 0.0;
    // Note: Aapke purane code mein 'total_amount' tha, lekin data 'amount' se aa raha hai.
    return quotations.fold(0.0, (sum, item) => sum + (double.tryParse(item['amount'].toString()) ?? 0.0));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Step 6: UI ko ab FutureBuilder mein banayein.
      // Yeh data aane tak loading dikhayega.
      body: FutureBuilder<List<dynamic>>(
        future: _quotationsFuture,
        builder: (context, snapshot) {
          // Case 1: Data abhi aa raha hai
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(
              appBar: AppBar(title: const Text('Loading...')),
              body: const Center(child: CircularProgressIndicator()),
            );
          }

          // Case 2: Data laane mein koi error aa gayi
          if (snapshot.hasError) {
            return Scaffold(
              appBar: AppBar(title: const Text('Error')),
              body: const Center(child: Text('Could not load quotations. Please try again.')),
            );
          }

          // Case 3: Data safalta se aa gaya hai
          final quotations = snapshot.data ?? [];
          final totalSum = _calculateTotalSum(quotations);

          // Aapka purana UI ab yahan se shuru hoga
          return Scaffold(
            appBar: AppBar(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Quotation History'),
                  Text(
                    'Total Sum: ₹ ${totalSum.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 14, color: Colors.white70),
                  )
                ],
              ),
            ),
            body: quotations.isEmpty
                ? const Center(child: Text('No quotations have been sent for this project yet.'))
                : ListView.builder(
                    padding: const EdgeInsets.all(8.0),
                    itemCount: quotations.length,
                    itemBuilder: (context, index) {
                      final quotation = quotations[index];
                      final createdAt = quotation['created_at'] != null
                          ? DateFormat('dd MMM, yyyy').format(DateTime.parse(quotation['created_at']))
                          : 'N/A';

                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(child: Text('${index + 1}')),
                          title: Text('Total Amount: ₹ ${quotation['amount']}'),
                          subtitle: Text('Status: ${quotation['status']} • Sent on: $createdAt'),
                          trailing: const Icon(Icons.arrow_forward_ios),
                          onTap: () {
                            // Step 7: Detail screen par jaane ke liye naya function call karein.
                            _navigateToDetailAndRefresh(quotation);
                          },
                        ),
                      );
                    },
                  ),
          );
        },
      ),
    );
  }
}