// lib/projects/screens/requirement_details_view_screen.dart
import 'package:flutter/material.dart';

class RequirementDetailViewScreen extends StatelessWidget {
  // Hum pichli screen se requirement ka data yahan lenge
  final Map<String, dynamic> requirementData;

  const RequirementDetailViewScreen({super.key, required this.requirementData});

  @override
  Widget build(BuildContext context) {
    // Sub-services aur items ki list banayein
    final List subServices = requirementData['sub_services'] ?? [];
    final List serviceItems = requirementData['service_items'] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Requirement Details'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Section 1: Main Description
          _buildSectionTitle('Full Description'),
          Text(requirementData['description'] ?? 'No description provided.'),
          const Divider(height: 30),

          // Section 2: Sub-Services
          _buildSectionTitle('Selected Sub-Services'),
          if (subServices.isNotEmpty)
            ...subServices.map((id) => ListTile(title: Text('Sub-Service ID: $id')))
          else
            const Text('No specific sub-services selected.'),
          const Divider(height: 30),

          // Section 3: Service Items
          _buildSectionTitle('Selected Items'),
           if (serviceItems.isNotEmpty)
            ...serviceItems.map((id) => ListTile(title: Text('Item ID: $id')))
          else
            const Text('No specific items selected.'),
        ],
      ),
    );
  }

  // Title ke liye ek helper widget
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
      ),
    );
  }
}