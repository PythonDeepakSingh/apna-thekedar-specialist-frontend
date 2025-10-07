import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class ViewPhasePlanScreen extends StatelessWidget {
  final List<dynamic> phases;

  const ViewPhasePlanScreen({super.key, required this.phases});

  @override
  Widget build(BuildContext context) {
    double totalAmount = 0;
    for (var phase in phases) {
      totalAmount += double.tryParse(phase['payment_amount'].toString()) ?? 0;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Phase Plan Details'),
      ),
      body: Column(
        children: [
          _buildAmountHeader(totalAmount),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: List.generate(
                    phases.length, (index) => _buildPhaseRow(phases[index], index)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountHeader(double totalAmount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.grey[200],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Total Project Amount',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Text('₹ ${totalAmount.toStringAsFixed(2)}',
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildPhaseRow(Map<String, dynamic> phase, int index) {
    final checklistItems = phase['checklist_items'] as List<dynamic>? ?? [];
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Phase ${index + 1}',
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildInfoChip(
                  icon: Iconsax.money_2,
                  label: 'Amount',
                  value: '₹ ${phase['payment_amount']}'),
              _buildInfoChip(
                  icon: Iconsax.calendar_1,
                  label: 'Days',
                  value: '${phase['expected_days']} days'),
            ],
          ),
          if (checklistItems.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text('Checklist', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildChecklistTable(checklistItems),
          ]
        ],
      ),
    );
  }
  
  Widget _buildInfoChip({required IconData icon, required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey.shade700),
            const SizedBox(width: 6),
            Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ],
        )
      ],
    );
  }

  Widget _buildChecklistTable(List<dynamic> items) {
    return Table(
      border: TableBorder(
        horizontalInside: BorderSide(color: Colors.grey.shade200, width: 1),
        verticalInside: BorderSide(color: Colors.grey.shade300, width: 1),
        top: BorderSide(color: Colors.grey.shade300, width: 1),
        bottom: BorderSide(color: Colors.grey.shade300, width: 1),
        left: BorderSide(color: Colors.grey.shade300, width: 1),
        right: BorderSide(color: Colors.grey.shade300, width: 1),
      ),
      columnWidths: const {
        0: IntrinsicColumnWidth(flex: 0.15),
        1: FlexColumnWidth(),
      },
      children: items.asMap().entries.map((entry) {
        int idx = entry.key;
        String task = entry.value['task_name'];
        return TableRow(
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
              child: Text('${idx + 1}',
                  style: TextStyle(color: Colors.grey.shade700)),
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 10.0, horizontal: 8.0),
              child: Text(task, style: const TextStyle(fontSize: 15)),
            ),
          ],
        );
      }).toList(),
    );
  }
}
