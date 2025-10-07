// lib/projects/screens/transit_details_screen.dart
import 'package:flutter/material.dart';

class TransitDetailsScreen extends StatelessWidget {
  const TransitDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transit Details'),
      ),
      body: const Center(
        child: Text(
          'Yahan hum transport ki details unique tareeke se design karenge.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}