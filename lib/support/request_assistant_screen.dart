import 'package:flutter/material.dart';
import 'package:apna_thekedar_specialist/api/api_service.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import 'thank_you_screen.dart'; // Hum yeh screen agle step mein banayenge

class RequestAssistantScreen extends StatefulWidget {
  final int projectId;
  const RequestAssistantScreen({super.key, required this.projectId});

  @override
  State<RequestAssistantScreen> createState() => _RequestAssistantScreenState();
}

class _RequestAssistantScreenState extends State<RequestAssistantScreen> {
  final _problemController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _isLoading = true);
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final response = await apiService.createSupportRequest(widget.projectId, _problemController.text);
      
      if (mounted) {
        if (response.statusCode == 201) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const ThankYouScreen())
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${response.body}')));
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('An error occurred: $e')));
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _problemController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Request Assistance')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Iconsax.headphone, size: 60, color: Colors.blue),
              const SizedBox(height: 20),
              const Text('Describe Your Problem', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              const SizedBox(height: 10),
              const Text('Please provide details about the issue you are facing. Our team will call you.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 30),
              TextFormField(
                controller: _problemController,
                decoration: const InputDecoration(
                  labelText: 'Your Problem',
                  hintText: 'e.g., Customer is not responding, payment issue...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please describe your problem.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                icon: const Icon(Iconsax.call_calling),
                label: const Text('Call Assistant'),
                onPressed: _isLoading ? null : _submitRequest,
              ),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.only(top: 16.0),
                  child: Center(child: CircularProgressIndicator()),
                ),
            ],
          ),
        ),
      ),
    );
  }
}