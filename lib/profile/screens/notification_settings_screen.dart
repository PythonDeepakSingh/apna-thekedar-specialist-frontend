// lib/profile/screens/notification_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum RingtonePreference { special, defaultTone }

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  RingtonePreference _preference = RingtonePreference.special; // Default ringtone hi rahega

  @override
  void initState() {
    super.initState();
    _loadPreference();
  }

  Future<void> _loadPreference() async {
    final prefs = await SharedPreferences.getInstance();
    // Phone mein save ki hui setting ko load karo
    final isSpecial = prefs.getBool('useSpecialRingtone') ?? true; // Default true hai
    setState(() {
      _preference = isSpecial ? RingtonePreference.special : RingtonePreference.defaultTone;
    });
  }

  Future<void> _savePreference(RingtonePreference? value) async {
    if (value == null) return;

    setState(() {
      _preference = value;
    });

    final prefs = await SharedPreferences.getInstance();
    // User ki choice ko phone mein save karo
    await prefs.setBool('useSpecialRingtone', value == RingtonePreference.special);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings saved successfully!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'New Requirement Tone',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          RadioListTile<RingtonePreference>(
            title: const Text('Long Ringtone (Recommended)'),
            value: RingtonePreference.special,
            groupValue: _preference,
            onChanged: _savePreference,
          ),
          RadioListTile<RingtonePreference>(
            title: const Text('Default Notification Tone (message tone)'),
            value: RingtonePreference.defaultTone,
            groupValue: _preference,
            onChanged: _savePreference,
          ),
        ],
      ),
    );
  }
}