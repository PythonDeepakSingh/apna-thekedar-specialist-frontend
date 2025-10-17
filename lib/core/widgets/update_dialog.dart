import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateDialog extends StatelessWidget {
  final Map<String, dynamic> updateInfo;

  const UpdateDialog({super.key, required this.updateInfo});

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isRestricted = updateInfo['is_restricted'] ?? false;
    final String versionName = updateInfo['version_name'] ?? '';
    final String updateNotes = updateInfo['in_this_update'] ?? '';

    return PopScope(
      canPop: !isRestricted, // Agar restricted hai, toh back button se band nahi hoga
      child: AlertDialog(
        title: const Row(
          children: [
            Icon(Iconsax.arrow_down, color: Colors.blue),
            SizedBox(width: 8),
            Text('Update Available'),
          ],
        ),
        content: SingleChildScrollView(
          child: ListBody(
            children: <Widget>[
              Text('A new version ($versionName) is available. Please update to continue.'),
              if (updateNotes.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('In this update:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(updateNotes),
              ],
            ],
          ),
        ),
        actions: <Widget>[
          if (!isRestricted) // Agar restricted nahi hai, tabhi Skip button dikhao
            TextButton(
              child: const Text('Skip'),
              onPressed: () {
                Navigator.of(context).pop(); // Dialog band kar do
              },
            ),
          ElevatedButton(
            child: const Text('Update Now'),
            onPressed: () {
              _launchURL(updateInfo['url_link']);
            },
          ),
        ],
      ),
    );
  }
}