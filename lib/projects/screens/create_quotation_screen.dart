// lib/projects/screens/create_quotation_screen.dart

import 'package:flutter/material.dart';
import 'package:apna_thekedar_specialist/api/api_service.dart';
import 'dart:convert';
import 'package:iconsax/iconsax.dart';
import 'package:apna_thekedar_specialist/projects/screens/quotation_preview_screen.dart';

// Quotation ke har item ko manage karne ke liye
class QuotationItem {
  TextEditingController nameController = TextEditingController();
  TextEditingController valueController = TextEditingController();
  TextEditingController timeController = TextEditingController();
  TextEditingController chargeController = TextEditingController();
}

class CreateQuotationScreen extends StatefulWidget {
  final int projectId;
  final int requirementId;
  const CreateQuotationScreen({super.key, required this.projectId, required this.requirementId});

  @override
  State<CreateQuotationScreen> createState() => _CreateQuotationScreenState();
}

class _CreateQuotationScreenState extends State<CreateQuotationScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String? _error;

  final _estimationDetailsController = TextEditingController();
  // ==================== CHANGE 1: Variable ka naam badla gaya ====================
  DateTime? _expectedCompletionDate; // Purana naam _validUntil tha
  final List<QuotationItem> _items = [QuotationItem()]; // Start with one item

  List<dynamic> _itemTemplates = [];

  @override
  void initState() {
    super.initState();
    _fetchItemTemplates();
  }

  Future<void> _fetchItemTemplates() async {
    try {
      final response = await _apiService.get('/services/service-items/?requirement_id=${widget.requirementId}');
      if (mounted) {
        if (response.statusCode == 200) {
          setState(() {
            _itemTemplates = json.decode(response.body);
            if (_items.isEmpty) _items.add(QuotationItem());
          });
        } else {
          _error = "Could not load item suggestions.";
        }
      }
    } catch (e) {
      if (mounted) _error = "An error occurred: $e";
    }
    if (mounted) setState(() { _isLoading = false; });
  }

  double _calculateTotal() {
    double total = 0;
    for (var item in _items) {
      total += double.tryParse(item.chargeController.text) ?? 0;
    }
    return total;
  }
  
  void _addNewItem() {
    setState(() {
      _items.add(QuotationItem());
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    // ==================== CHANGE 2: DatePicker mein naye variable ka istemaal ====================
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _expectedCompletionDate ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)), // 2 saal tak ka time de diya
    );
    if (picked != null && picked != _expectedCompletionDate) {
      setState(() { _expectedCompletionDate = picked; });
    }
  }

  Future<void> _sendQuotation() async {
    // ==================== CHANGE 3: Check aur error message ko naye logic ke hisaab se badla gaya ====================
    if (_expectedCompletionDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select an expected completion date.')));
      return;
    }
    
    final List<Map<String, dynamic>> itemsData = _items
        .where((item) => item.nameController.text.isNotEmpty && item.chargeController.text.isNotEmpty)
        .map((item) => {
              'item_name': item.nameController.text,
              'value': item.valueController.text,
              'time_in_days': int.tryParse(item.timeController.text), // Empty hone par null jayega
              'charge': double.tryParse(item.chargeController.text) ?? 0,
            })
        .toList();
    
    if (itemsData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please add at least one valid item.')));
      return;
    }
    
    final quotationData = {
      'requirement': widget.requirementId,
      'amount': _calculateTotal(),
      'estimation_details': _estimationDetailsController.text,
      // ==================== CHANGE 4: Backend ko bhejne ke liye sahi key aur variable ka istemaal ====================
      'expected_completion_date': _expectedCompletionDate!.toIso8601String().split('T').first, // Sirf YYYY-MM-DD format mein bhejega
      'items': itemsData,
    };

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => QuotationPreviewScreen(
          projectId: widget.projectId,
          quotationData: quotationData,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Quotation')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ..._items.asMap().entries.map((entry) {
                        int idx = entry.key;
                        QuotationItem item = entry.value;
                        return _buildItemCard(item, idx);
                      }).toList(),
                      const SizedBox(height: 8),
                      Center(child: TextButton.icon(icon: const Icon(Iconsax.add), label: const Text("Add Another Item"), onPressed: _addNewItem)),
                      
                      const Divider(height: 30),
                      
                      const Text("Other Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      TextFormField(controller: _estimationDetailsController, decoration: const InputDecoration(labelText: 'Estimation Details (Optional)'), maxLines: 3),
                      const SizedBox(height: 20),
                      // ==================== CHANGE 5: Date field ke UI text aur logic ko update kiya gaya ====================
                      TextFormField(
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'Expected Completion Date',
                          hintText: _expectedCompletionDate == null 
                              ? 'Select Date' 
                              : '${_expectedCompletionDate!.day}/${_expectedCompletionDate!.month}/${_expectedCompletionDate!.year}', // Format badal diya
                          prefixIcon: const Icon(Iconsax.calendar_1),
                        ),
                        onTap: () => _selectDate(context),
                      ),
                    ],
                  ),
                ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text("Total Amount: ₹${_calculateTotal().toStringAsFixed(2)}", textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _sendQuotation, // Loading state yahan se hata diya kyunki hum next screen par ja rahe hain
              child: const Text('Preview & Send Quotation'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemCard(QuotationItem item, int index) {
    // Is widget mein koi badlaav nahi hai, yeh waisa hi rahega
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: Text("Item ${index + 1}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                PopupMenuButton<dynamic>(
                  icon: const Icon(Iconsax.magicpen, size: 20),
                  tooltip: "Suggestions",
                  onSelected: (selectedValue) {
                    setState(() {
                      item.nameController.text = selectedValue['name'];
                    });
                  },
                  itemBuilder: (BuildContext context) {
                    return _itemTemplates.map((template) {
                      return PopupMenuItem<dynamic>(
                        value: template,
                        child: Text(template['name']),
                      );
                    }).toList();
                  },
                ),
                if (_items.length > 1)
                  IconButton(icon: const Icon(Iconsax.trash, color: Colors.red, size: 20), onPressed: () => _removeItem(index)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: TextFormField(controller: item.nameController, decoration: const InputDecoration(labelText: 'Item Name*'))),
                const SizedBox(width: 12),
                Expanded(child: TextFormField(controller: item.valueController, decoration: const InputDecoration(labelText: 'Value/Qty'))),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: TextFormField(controller: item.timeController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Time (Days)'))),
                const SizedBox(width: 12),
                Expanded(child: TextFormField(controller: item.chargeController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Charge (₹)*'), onChanged: (_) => setState(() {}))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}