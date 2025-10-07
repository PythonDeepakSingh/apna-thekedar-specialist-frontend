import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:apna_thekedar_specialist/api/api_service.dart';
import 'package:apna_thekedar_specialist/projects/screens/phase_item_edit_screen.dart';
import 'package:iconsax/iconsax.dart';

// Data model waisa hi rahega
class Phase {
  TextEditingController amountController = TextEditingController();
  TextEditingController daysController = TextEditingController();
  List<String> checklistItems = [];

  // Naya constructor data pre-fill karne ke liye
  Phase.fromData(Map<String, dynamic> data) {
    amountController.text = data['payment_amount']?.toString() ?? '';
    daysController.text = data['expected_days']?.toString() ?? '';
    checklistItems = (data['checklist_items'] as List<dynamic>? ?? [])
        .map((item) => item['task_name'].toString())
        .toList();
  }

  Phase(); // Default constructor
}

class CreatePhasePlanScreen extends StatefulWidget {
  final int projectId;
  final double totalAmount;
  final List<dynamic>? initialPhases; // Naya parameter purana data lene ke liye

  const CreatePhasePlanScreen({
    super.key,
    required this.projectId,
    required this.totalAmount,
    this.initialPhases,
  });

  @override
  _CreatePhasePlanScreenState createState() => _CreatePhasePlanScreenState();
}

class _CreatePhasePlanScreenState extends State<CreatePhasePlanScreen> {
  final List<Phase> _phases = [];
  double _remainingAmount = 0.0;
  bool _isLoading = false;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    // === YAHAN BADLAV KIYA GAYA HAI ===
    if (widget.initialPhases != null && widget.initialPhases!.isNotEmpty) {
      // Agar purana data hai, toh use form mein bharein
      for (var phaseData in widget.initialPhases!) {
        final phase = Phase.fromData(phaseData);
        _phases.add(phase);
      }
    } else {
      // Varna, ek naya khaali phase banayein
      _phases.add(Phase());
    }
    
    _calculateRemainingAmount();
    for (var phase in _phases) {
      phase.amountController.addListener(_calculateRemainingAmount);
    }
  }

  @override
  void dispose() {
    for (var phase in _phases) {
      phase.amountController.dispose();
      phase.daysController.dispose();
    }
    super.dispose();
  }

  void _calculateRemainingAmount() {
    double spentAmount = 0.0;
    for (var phase in _phases) {
      spentAmount += double.tryParse(phase.amountController.text) ?? 0.0;
    }
    setState(() {
      _remainingAmount = widget.totalAmount - spentAmount;
    });
  }

  void _addPhase() {
    setState(() {
      final newPhase = Phase();
      newPhase.amountController.addListener(_calculateRemainingAmount);
      _phases.add(newPhase);
    });
    _calculateRemainingAmount();
  }

  void _removePhase(int index) {
    setState(() {
      _phases[index].amountController.removeListener(_calculateRemainingAmount);
      _phases.removeAt(index);
    });
    _calculateRemainingAmount();
  }

  Future<void> _editChecklist(int phaseIndex) async {
    final updatedItems = await Navigator.push<List<String>>(
      context,
      MaterialPageRoute(
        builder: (context) => PhaseItemEditScreen(
          initialItems: _phases[phaseIndex].checklistItems,
          phaseNumber: phaseIndex + 1,
        ),
      ),
    );

    if (updatedItems != null) {
      setState(() {
        _phases[phaseIndex].checklistItems = updatedItems;
      });
    }
  }

  Future<void> _submitPhasePlan() async {
    if (_remainingAmount != 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Remaining amount must be zero to submit.'),
            backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    List<Map<String, dynamic>> phasesData = [];
    for (int i = 0; i < _phases.length; i++) {
      final phase = _phases[i];
      if (phase.amountController.text.isEmpty ||
          phase.daysController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please fill amount and days for all phases.'),
              backgroundColor: Colors.red),
        );
        setState(() => _isLoading = false);
        return;
      }

      phasesData.add({
        'phase_number': i + 1,
        'payment_amount': phase.amountController.text,
        'expected_days': int.tryParse(phase.daysController.text) ?? 0,
        'checklist_items':
            phase.checklistItems.map((task) => {'task_name': task}).toList(),
      });
    }

    final Map<String, dynamic> body = {'phases': phasesData};

    try {
      final response = await _apiService.post(
        '/projects/${widget.projectId}/phase-plan/',
        body,
      );

      if (response.statusCode == 201 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Phase plan submitted successfully!'),
              backgroundColor: Colors.green),
        );
        Navigator.of(context).pop(true);
      } else if (mounted) {
        final error = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: ${error['error'] ?? 'Failed to submit.'}'),
              backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('An error occurred: $e'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Phase Plan'),
      ),
      body: Column(
        children: [
          _buildAmountHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children:
                    List.generate(_phases.length, (index) => _buildPhaseRow(index)),
              ),
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildAmountHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.grey[200],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Total Amount',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14)),
              Text('₹ ${widget.totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Remaining',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14)),
              Text('₹ ${_remainingAmount.toStringAsFixed(2)}',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _remainingAmount == 0
                          ? Colors.green
                          : (_remainingAmount < 0
                              ? Colors.red
                              : Colors.orange))),
            ],
          ),
        ],
      ),
    );
  }

  // === YEH NAYA "EXCEL STYLE" WIDGET HAI ===
  Widget _buildPhaseRow(int index) {
    final phase = _phases[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Phase Title and Delete Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Phase ${index + 1}',
                    style:
                        const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                if (_phases.length > 1)
                  IconButton(
                    icon: const Icon(Iconsax.trash, color: Colors.red),
                    onPressed: () => _removePhase(index),
                  ),
              ],
            ),
          ),
          
          // Row 2: Amount and Days
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: phase.amountController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Amount (₹)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: phase.daysController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Days',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Row 3: Checklist Table (agar items hain toh)
          if (phase.checklistItems.isNotEmpty)
            _buildChecklistTable(phase.checklistItems),
          
          // Row 4: Edit/Add Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${phase.checklistItems.length} tasks added',
                  style: const TextStyle(color: Colors.grey),
                ),
                TextButton.icon(
                  icon: Icon(phase.checklistItems.isEmpty ? Iconsax.add : Iconsax.edit),
                  label: Text(phase.checklistItems.isEmpty ? 'Add Checklist' : 'Edit Checklist'),
                  onPressed: () => _editChecklist(index),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // === YEH RAHA AAPKE DESIGN JAISA NAYA TABLE WIDGET ===
  Widget _buildChecklistTable(List<String> items) {
    return Table(
      border: TableBorder(
        horizontalInside: BorderSide(color: Colors.grey.shade200, width: 1),
        verticalInside: BorderSide(color: Colors.grey.shade300, width: 1),
      ),
      columnWidths: const {
        0: IntrinsicColumnWidth(flex: 0.15), // Column for numbers
        1: FlexColumnWidth(),             // Column for task names
      },
      children: items.asMap().entries.map((entry) {
        int idx = entry.key;
        String task = entry.value;
        return TableRow(
          children: [
            // Cell 1: Number
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
              child: Text('${idx + 1}', style: TextStyle(color: Colors.grey.shade700)),
            ),
            // Cell 2: Task Name
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10.0),
              child: Text(task, style: const TextStyle(fontSize: 15)),
            ),
          ],
        );
      }).toList(),
    );
  }


  Widget _buildBottomBar() {
     return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OutlinedButton.icon(
            icon: const Icon(Iconsax.additem),
            label: const Text('Add New Phase'),
            onPressed: _addPhase,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _isLoading ? null : _submitPhasePlan,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Text('Submit Phase Plan'),
          ),
        ],
      ),
    );
  }
}

