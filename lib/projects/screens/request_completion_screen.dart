// lib/projects/screens/request_completion_screen.dart
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:slide_to_act/slide_to_act.dart';
import 'package:apna_thekedar_specialist/api/api_service.dart';
import 'package:http/http.dart' as http; // HTTP ko import karein

class RequestCompletionScreen extends StatefulWidget {
  final int projectId;
  // ==================== YAHAN BADLAAV KIYA GAYA HAI ====================
  final int? phaseId;
  final bool isLastPhase;

  const RequestCompletionScreen({
    super.key,
    required this.projectId,
    this.phaseId,
    this.isLastPhase = false, // Default value false hai
  });
  // =====================================================================

  @override
  State<RequestCompletionScreen> createState() => _RequestCompletionScreenState();
}

class _RequestCompletionScreenState extends State<RequestCompletionScreen> {
  final ApiService _apiService = ApiService();
  final GlobalKey<SlideActionState> _slideKey = GlobalKey();

  // ==================== YEH FUNCTION POORA BADAL GAYA HAI ====================
  Future<void> _sendRequest() async {
    try {
      http.Response response;

      if (widget.isLastPhase) {
        // Aakhri phase hai, to purana project completion API call karo
        response = await _apiService.post('/projects/${widget.projectId}/request-completion/', {});
      } else {
        // Beech ka phase hai, to naya phase completion API call karo
        response = await _apiService.post('/projects/phases/${widget.phaseId}/request-completion/', {});
      }

      if (mounted) {
        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Completion request sent successfully!'), backgroundColor: Colors.green),
          );
          // Sirf ek screen piche jaakar refresh karega
          Navigator.of(context).pop(true);
        } else {
          _slideKey.currentState?.reset(); // Agar fail ho toh slider reset karein
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${response.body}')));
        }
      }
    } catch (e) {
      if (mounted) {
        _slideKey.currentState?.reset();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("An error occurred: $e")));
      }
    }
  }
  // =========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Title ko dynamic banaya gaya hai
        title: Text(widget.isLastPhase ? 'Request Project Completion' : 'Request Phase Completion'),
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
                Text('• Ensure all work for this phase is completed.', style: TextStyle(fontSize: 16)),
                SizedBox(height: 8),
                Text('• Make sure the site is clean.', style: TextStyle(fontSize: 16)),
                SizedBox(height: 8),
                Text('• Upload all relevant photos before sending this request.', style: TextStyle(fontSize: 16)),
                
                SizedBox(height: 24),
                Text('निर्देश', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                SizedBox(height: 16),
                Text('• सुनिश्चित करें कि इस चरण के सभी काम पूरे हो गए हैं।', style: TextStyle(fontSize: 16)),
                SizedBox(height: 8),
                Text('• सुनिश्चित करें कि साइट साफ है।', style: TextStyle(fontSize: 16)),
                SizedBox(height: 8),
                Text('• यह अनुरोध भेजने से पहले सभी संबंधित तस्वीरें अपलोड करें।', style: TextStyle(fontSize: 16)),

                Divider(height: 40),
                
                ListTile(
                  leading: Icon(Iconsax.warning_2, color: Colors.red),
                  title: Text('Warning: Do not send this request if the work is not 100% complete. The customer will reject it.', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),

SlideAction(
              key: _slideKey,
              // 'text' property ko hata kar ab 'child' ka istemaal karenge
              // isse humein text par zyada control milta hai.
              child: Text(
                widget.isLastPhase ? 'Slide to Complete Project' : 'Slide to Complete Phase',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                ),
              ),
              
              // Baaki ki styling properties
              sliderButtonIcon: const Icon(
                Iconsax.arrow_right_3,
                color: Colors.green,
              ),
              innerColor: Colors.white,
              outerColor: Colors.green,
              elevation: 0, // Shadow hata di for a cleaner look
              onSubmit: () {
                _sendRequest();
                // API response aane tak slider ko reset nahi karenge
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }
}