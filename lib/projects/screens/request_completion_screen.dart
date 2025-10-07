// lib/projects/screens/request_completion_screen.dart
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:slide_to_act/slide_to_act.dart';
import 'package:apna_thekedar_specialist/api/api_service.dart';

class RequestCompletionScreen extends StatefulWidget {
  final int projectId;
  const RequestCompletionScreen({super.key, required this.projectId});

  @override
  State<RequestCompletionScreen> createState() => _RequestCompletionScreenState();
}

class _RequestCompletionScreenState extends State<RequestCompletionScreen> {
  final ApiService _apiService = ApiService();
  final GlobalKey<SlideActionState> _slideKey = GlobalKey();

  Future<void> _sendRequest() async {
    try {
      final response = await _apiService.post('/projects/${widget.projectId}/request-completion/', {});
      if (mounted) {
        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Completion request sent successfully!')),
          );
          // 2 screen piche jaayenge (preview screen -> project details)
          int count = 0;
          Navigator.of(context).popUntil((_) => count++ >= 2);
        } else {
          _slideKey.currentState?.reset(); // Agar fail ho toh slider reset karein
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${response.body}')));
        }
      }
    } catch (e) {
      if(mounted) {
        _slideKey.currentState?.reset();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("An error occurred: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirm Completion Request'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Instructions', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                SizedBox(height: 16),
                Text('• Ensure all work is completed as per the quotation.', style: TextStyle(fontSize: 16)),
                SizedBox(height: 8),
                Text('• Make sure the site is clean.', style: TextStyle(fontSize: 16)),
                SizedBox(height: 8),
                Text('• Upload all final project photos before sending this request.', style: TextStyle(fontSize: 16)),
                
                SizedBox(height: 24),
                Text('निर्देश', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                SizedBox(height: 16),
                Text('• सुनिश्चित करें कि सभी काम कोटेशन के अनुसार पूरे हो गए हैं।', style: TextStyle(fontSize: 16)),
                SizedBox(height: 8),
                Text('• सुनिश्चित करें कि साइट साफ है।', style: TextStyle(fontSize: 16)),
                SizedBox(height: 8),
                Text('• यह अनुरोध भेजने से पहले सभी अंतिम प्रोजेक्ट तस्वीरें अपलोड करें।', style: TextStyle(fontSize: 16)),

                Divider(height: 40),
                
                ListTile(
                  leading: Icon(Iconsax.warning_2, color: Colors.red),
                  title: Text('Warning: Do not send this request if the work is not 100% complete. The customer will reject it.', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),

            SlideAction(
              key: _slideKey,
              text: 'Slide to Send Completion Request',
              outerColor: Colors.green,
              onSubmit: () {
                _sendRequest();
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }
}